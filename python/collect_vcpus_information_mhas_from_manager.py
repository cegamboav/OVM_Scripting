#################################################################
# Author : Carlos Gamboa <carlos.gamboa@kyndryl.com>
# Purpose : This script is to display the vm name and OS asociated to this VM From the manager Server
###############################################################
## 3 Mar, 2022 : Created 
##
##
################################################################

import os
import sys
import subprocess

continue_program=0
input_file=""

## Function to create temp directory
def createtempfolder():
	os.system('mkdir -p tmp_dir')

def get_server_names():
    os.system('ovmcli "list server"|grep name|cut -d \' \' -f 5|cut -d \':\' -f2 > tmp_dir/server_names.csv')
    

##Function to check the server:
def check_servers():
    #Variable to set the print format:
    format_="%-1s %-32s %-1s %06s %-1s %7s %-1s %7s %-1s\n"
    format_2="%-1s %-7s %-24s %-1s %-5s %-20s %-1s\n"
    #Now display information in the screen
    os.system('clear')
    print('Collecting data ....')
    print('')
    print('  Collecting xm list and vcpu information ...')
    print('')

    input_file="tmp_dir/server_names.csv"
    #Collect the xmlist of all the VMs in the input_file:
    with open(input_file) as the_input_file:
        #We proceed to navegate the lines one by one:
        for input_line in the_input_file:
            print ('    {}:'.format(input_line.rstrip()))
            print ('      Creating file {}.xmlist.txt'.format(input_line.rstrip()))
            
            #now we call the function to run the script in the servers:
            cmd='ssh ovmadm@{} "sudo xm list|sort -nrk4;sudo xm info|grep nr_cpus" > tmp_dir/{}.xmlist.txt'.format(input_line.rstrip(),input_line.rstrip())
            os.system(cmd)
            print ('      Creating file {}.xmvcpu.txt'.format(input_line.rstrip()))
            cmd='ssh ovmadm@{} "sudo xm vcpu-list" > tmp_dir/{}.xmvcpu.txt'.format(input_line.rstrip(),input_line.rstrip())
            os.system(cmd)
            print('')
    print("------------------------------------")
    print("  Creating {}.vcpus.txt ...".format(output_name))
    print('')
    os.system('echo "|===============================================================|" > {}.vcpus.txt'.format(output_name))
    os.system('echo "" > {}.csv'.format(output_name))
    print('    [OK] File {}.vcpus.txt correctly created.'.format(output_name))
    print("------------------------------------")
    print("Analizing data ...")
    print('')
    with open(input_file) as the_input_file:
        #We proceed to navegate the lines one by one:
        for input_line in the_input_file:
            if input_line.rstrip() != "name":
                #Collect the number of running vms:
                cmd='egrep -v \'Name|Domain-0\' tmp_dir/{}.xmlist.txt|wc -l'.format(input_line.rstrip())
                number_of_vms = subprocess.check_output(cmd, shell=True)
                
                if number_of_vms != 0:
                    #Collect the amount of the CPUs in the server:
                    cmd='cat tmp_dir/{}.xmlist.txt|grep nr_cpus| cut -d \':\' -f2'.format(input_line.rstrip())
                    CPUs_Server= subprocess.check_output(cmd, shell=True)
                    
                    #Insert the information in the file:
                    os.system('printf "{}" "|" "Server:" {} "|" "CPUS:" {} "|" >> {}.vcpus.txt'.format(format_2,input_line.rstrip(),CPUs_Server.rstrip(),output_name))
                    os.system('echo "{},{}" >> {}.csv'.format(input_line.rstrip(),CPUs_Server.rstrip(),output_name))
                    os.system('echo "| VM ID                            | VCPUS  | From    |  TO     |" >> {}.vcpus.txt'.format(output_name))
                    os.system('echo "VM ID,VCPUS,From,To" >> {}.csv'.format(output_name))
                    os.system('echo "|----------------------------------|--------|---------|---------|" >> {}.vcpus.txt'.format(output_name))
                    
                    #collect the end CPU information: 
                    cmd='cat tmp_dir/{}.xmvcpu.txt|grep Domain-0|tail -n 1|tr -s " " |cut -d " " -f 7'.format(input_line.rstrip())
                    p = subprocess.check_output(cmd, shell=True)
                    
                    #collect the total amount of vcpus set to dom0:
                    cmd='cat tmp_dir/{}.xmlist.txt|grep Domain-0|tr -s " " |cut -d " " -f 4'.format(input_line.rstrip())
                    q = subprocess.check_output(cmd, shell=True)
                    
                    #Inserting information in the file:
                    os.system('printf "{}" "|" "Domain-0" "|" {} "|" "0" "|" {} "|" >> {}.vcpus.txt'.format(format_,q.rstrip(),p.rstrip(),output_name))
                    os.system('echo "Domain-0,{},0,{}" >> {}.csv'.format(q.rstrip(),p.rstrip(),output_name))
                    os.system('egrep -v \'Name|Domain-0|nr_cpus\' tmp_dir/{}.xmlist.txt|tr -s " " |cut -d " " -f 1 > tmp_dir/{}.vm_ids.txt'.format(input_line.rstrip(),input_line.rstrip()))
                    
                    #Now collecting VMs information:
                    vms_ids_file='tmp_dir/{}.vm_ids.txt'.format(input_line.rstrip())
                    with open(vms_ids_file) as the_vms_ids_file:
                        #We proceed to navegate the lines one by one:
                        for vms_ids_line in the_vms_ids_file:
                            
                            if vms_ids_line.rstrip()!="":
                                #collect the amount of vcpus of the VM
                                cmd='grep {} tmp_dir/{}.xmlist.txt|tr -s " " |cut -d " " -f 4'.format(vms_ids_line.rstrip(),input_line.rstrip())
                                m= subprocess.check_output(cmd, shell=True)
                                
                                #collect the pinning vcpus of the VM:
                                cmd='grep {} tmp_dir/{}.xmvcpu.txt|tr -s " " |cut -d " " -f 7|uniq'.format(vms_ids_line.rstrip(),input_line.rstrip())
                                v=subprocess.check_output(cmd, shell=True)
                                
                                #collect the start of the vcpu pinning:
                                cmd='echo {}|cut -d \'-\' -f1'.format(v.rstrip())
                                o=subprocess.check_output(cmd, shell=True)
                                
                                #collect the end of the vcpu pinning:
                                cmd='echo {}|cut -d \'-\' -f2'.format(v.rstrip())
                                r=subprocess.check_output(cmd, shell=True)
                                
                                #Insert the values in the file:
                                os.system('printf "{}" "|" {} "|" {} "|" {} "|" {} "|" >> {}.vcpus.txt'.format(format_,vms_ids_line.rstrip(),m.rstrip(),o.rstrip(),r.rstrip(),output_name))
                                os.system('echo "{},{},{},{}" >> {}.csv'.format(vms_ids_line.rstrip(),m.rstrip(),o.rstrip(),r.rstrip(),output_name))
                        os.system('echo "|===============================================================|" >> {}.vcpus.txt'.format(output_name))
                        os.system('echo "================,================" >> {}.csv'.format(output_name))
                print('    {} Completed'.format(input_line.rstrip()))
    print("------------------------------------")
    print('')
    print("[OK] All the data has been proceeded, check the file {}.vcpus.txt".format(output_name))
    print('')


##delete temporary file
def delete_working_folder():
    print("Dumping data ...")
    os.system('echo > dump_{}.vcpus.txt'.format(output_name))
    os.system('ls tmp_dir/*xmlist.txt > tmp_dir/list_files.txt')
    list_file='tmp_dir/list_files.txt'
    with open(list_file) as the_list_files:
        #We proceed to navegate the lines one by one:
        for list_file_line in the_list_files:
            print(list_file_line.rstrip())
            os.system('echo {} >> dump_{}.vcpus.txt'.format(list_file_line.rstrip(),output_name))
            os.system('echo "+++++++++" >> dump_{}.vcpus.txt'.format(output_name))
            cmd='cat {} >> dump_{}.vcpus.txt'.format(list_file_line.rstrip(),output_name)
            os.system(cmd)
            os.system('echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_{}.vcpus.txt'.format(output_name))
    
    os.system('ls tmp_dir/*.xmvcpu.txt > tmp_dir/vcpu_files.txt')
    vcpu_file='tmp_dir/list_files.txt'
    with open(vcpu_file) as the_vcpu_files:
        #We proceed to navegate the lines one by one:
        for vcpu_file_line in the_vcpu_files:
            os.system('echo {} >> dump_{}.vcpus.txt'.format(list_file_line.rstrip(),output_name))
            os.system('echo "+++++++++" >> dump_{}.vcpus.txt'.format(output_name))
            cmd='cat {} >> dump_{}.vcpus.txt'.format(list_file_line.rstrip(),output_name)
            os.system(cmd)
            os.system('echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_${}.vcpus.txt'.format(output_name))
    os.system('rm -rf tmp_dir')
    print("[OK] All data dumped and deleted.")


def run_program():
    createtempfolder()
    get_server_names()
    check_servers()
    delete_working_folder()


try:
    output_name=sys.argv[1]
except:
    output_name="information"
    run_program()