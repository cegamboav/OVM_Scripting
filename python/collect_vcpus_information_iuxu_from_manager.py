#!/usr/bin/env python2.7
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
import argparse


specify_user=False
continue_program=0
input_file=""

## Function to create temp directory
def createtempfolder():
	os.system('mkdir -p tmp_dir')

def get_server_names():
    os.system('clear')
    print('Collecting Servers names ...')
    os.system('ovmcli "list server"|grep name|cut -d \' \' -f 5|cut -d \':\' -f2 > tmp_dir/server_names.csv')
    print('[OK] Server list collected.')
    
def count_vcpus(server_name):
    #print(''+server_name)
    
    cmd='cat tmp_dir/{}.xmlist.txt |egrep -v \'Name|nr_cpus\' |tr -s " " |cut -d " " -f 4 > tmp_dir/vcpus.txt'.format(server_name)
    #print(cmd)
    os.system(cmd)
    
    vcpus_total=0
    
    input_file="tmp_dir/vcpus.txt"
    
    #Collect the xmlist of all the VMs in the input_file:
    with open(input_file) as the_input_file:
        #We proceed to navegate the lines one by one:
        for input_line in the_input_file:
            if input_line.rstrip() != 'Name':
                if input_line.rstrip() != 'nr_cpus':
                    #count_vcpus(input_line.rstrip())
                    #print(input_line.rstrip())
                    vcpus_total=vcpus_total+int(input_line.rstrip())
    return vcpus_total

##Function to check the server:
def check_servers():
    #Variable to set the print format:
    format_="%-1s %-32s %-1s %06s %-1s %7s %-1s %7s %-1s\n"
    format_2="%-1s %-7s %-24s %-1s %-5s %-20s %-1s\n"
    #Now display information in the screen
    print('')
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
            cmd='ssh {}@{} "sudo xm list|sort -nrk4;sudo xm info|grep nr_cpus" > tmp_dir/{}.xmlist.txt'.format(args.user,input_line.rstrip(),input_line.rstrip())
            os.system(cmd)
            print ('      Creating file {}.xmvcpu.txt'.format(input_line.rstrip()))
            cmd='ssh {}@{} "sudo xm vcpu-list" > tmp_dir/{}.xmvcpu.txt'.format(args.user,input_line.rstrip(),input_line.rstrip())
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
                    
                    #Collect the amount of running VMs:
                    cmd='cat tmp_dir/{}.xmlist.txt|egrep -v \'Name|Domain-0|nr_cpus\'| wc -l'.format(input_line.rstrip())
                    Running_VMs= subprocess.check_output(cmd, shell=True)
                    
                    #count the amount of vcpus assigned to the VMs running in the server
                    used_vcpus=count_vcpus(input_line.rstrip())
                    
                    
                    if int(CPUs_Server.rstrip()) >= int(used_vcpus):
                        vcpu_status=1
                    else:
                        vcpu_status=0
                    
                    #Insert the information in the file:
                    os.system('printf "{}" "|" "Server:" {} "|" "CPUS:" {} "|" >> {}.vcpus.txt'.format(format_2,input_line.rstrip(),CPUs_Server.rstrip(),output_name))
                    os.system('echo "{},{},{},{},{}" >> {}.csv'.format(input_line.rstrip(),CPUs_Server.rstrip(),Running_VMs.rstrip(),used_vcpus,vcpu_status,output_name))
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

def print_sort_file():
    print('')
    print('')
    print('Table of the results:')
    csv_file="{}.sort.csv".format(output_name)
    with open(csv_file) as the_VCPU_file:
        #We proceed to navegate the lines one by one:
        for VCPU_line in the_VCPU_file:
            #Splitting the line to obtain the head of the line:
            split_string = VCPU_line.rstrip().split(",", 1)
            substring = split_string[0]
            
            #now we get the lengh of the string
            var_lenght=len(substring)

            #If the lenght is 32, is a VM ID
            if var_lenght == 32:
                split_string_vm_vcpus = VCPU_line.rstrip().split(",", 5)
                vm_vcpus = split_string_vm_vcpus[1]
                vm_prev_start_vcpu=split_string_vm_vcpus[2]
                vm_prev_end_vcpu=split_string_vm_vcpus[3]
                vm_new_start_vcpu=split_string_vm_vcpus[4]
                vm_new_end_vcpu=split_string_vm_vcpus[5]
                print('| {0:32} | {1:5} | {2:10} | {3:10} | {4:10} | {5:10} |'.format(substring, vm_vcpus, vm_prev_start_vcpu, vm_prev_end_vcpu,vm_new_start_vcpu,vm_new_end_vcpu)) 
            else:
                if var_lenght > 0:
                    print('|'+'='*94+'|')
                    print('| {0:92} |'.format(substring))
                    #print('|'+'-'*94+'|')
                    print('| {0:32} | {1:5} | {2:10} | {3:10} | {4:10} | {5:10} |'.format('VM_ID', 'VCPUs', 'Prev_Start', 'Prev_End','New_Start','New_End')) 
    print('|'+'='*94+'|')


def sort_vcpus():
    prev_vcpu=0
    print('sorting vcpus')
    csv_file="{}.csv".format(output_name)
    #initializate configuration file:
    cmd='echo > {}.sort.csv'.format(output_name)
    os.system(cmd)
    cmd='echo > {}.output.csv'.format(output_name)
    os.system(cmd)
                                            
    with open(csv_file) as the_VCPU_file:
        #We proceed to navegate the lines one by one:
        for VCPU_line in the_VCPU_file:
            #Splitting the line to obtain the head of the line:
            split_string = VCPU_line.rstrip().split(",", 1)
            substring = split_string[0]
            
            #Filter the file to obtain the correct information
            if substring != "================":
                if substring != "VM ID":
                    if substring != "":
                        if substring == "Domain-0":
                            #If the ingnore is in True, means the Server do not have VMs running
                            if ignore == False:
                                split_string_dom0 = VCPU_line.rstrip().split(",", 4)
                                prev_vcpu = split_string_dom0[3]
                                dom0vcpus = split_string_dom0[1]
                                #print('    Dom-0     from 0 to '+prev_vcpu)
                                cmd='echo Dom-0 VCPUS:{} From:0 To:{}>>{}.output.csv'.format(dom0vcpus,prev_vcpu,output_name)
                                os.system(cmd)
                        else:
                            #now we get the lengh of the string
                            var_lenght=len(substring)

                            #If the lenght is 32, is a VM ID
                            if var_lenght == 32:
                                #If the ingnore is in True, means the Server do not have VMs running, or no have enough space to re-allocate the vcpus
                                if ignore == False:
                                    split_string_vm_vcpus = VCPU_line.rstrip().split(",", 4)
                                    vm_vcpus = split_string_vm_vcpus[1]
                                    vm_prev_start_vcpu=split_string_vm_vcpus[2]
                                    vm_prev_end_vcpu=split_string_vm_vcpus[3]
                                    starting=int(prev_vcpu)+1
                                    ending=int(prev_vcpu)+int(vm_vcpus)
                                    if int(vm_prev_start_vcpu) == starting and int(vm_prev_end_vcpu) == ending:
                                        print('    [OK] VM {} Correctly pinned, Skipping ...'.format(substring))
                                    else:
                                        #print('    VM: '+substring+' VCPUS='+vm_vcpus+' PS='+vm_prev_start_vcpu+'   NS='+str(starting)+'    PE='+vm_prev_end_vcpu+'   NE='+str(ending))
                                        cmd='echo {},{},{},{},{},{}>>{}.sort.csv'.format(substring,vm_vcpus,vm_prev_start_vcpu,vm_prev_end_vcpu,starting,ending,output_name)
                                        os.system(cmd)
                                        cmd='echo ID: {} VCPUS:{} From:{} To:{}>>{}.output.csv'.format(substring,vm_vcpus,starting,ending,output_name)
                                        os.system(cmd)
                                    prev_vcpu=str(ending)
                                    
                            else:
                                split_string_2 = VCPU_line.rstrip().split(",", 3)
                                running_vms = split_string_2[2]
                                
                                if running_vms == '0':
                                    print('-'*30)
                                    print('  [OK] Server: '+substring+' does not have running VMs, Ignoring')
                                    ignore=True
                                else:
                                    split_string_vcpu_status = VCPU_line.rstrip().split(",", 5)
                                    vcpu_status = split_string_vcpu_status[4]
                                    
                                    #if vcpu_status is 1, means the amount of usev vcpus is less or equals to the amount of vcpus of the server
                                    if vcpu_status == '1':
                                        print('-'*30)
                                        print('  [OK] Checking Server: '+substring)
                                        cmd='echo "===============================" >> {}.output.csv;echo "Server: "{} >> {}.output.csv'.format(output_name,substring,output_name)
                                        os.system(cmd)
                                        cmd='echo {}>>{}.sort.csv'.format(substring,output_name)
                                        os.system(cmd)
                                        ignore=False
                                    else:
                                        print('-'*30)
                                        print('  [Error] Server {} is vcpu over allocated, we are not able to re-allocate the vcpus.'.format(substring))
                                        ignore=True
    print_sort_file()
                
def run_program():
    createtempfolder()
    get_server_names()
    check_servers()
    if args.sort:
        sort_vcpus()
    delete_working_folder()

def print_message():
    os.system('clear')
    print("[Error] Provide the user as a parameter:")
    print('')
    print("Example:")
    print("python2.7 {} -u <iuxu or ovmadm> -s true".format(sys.argv[0]))
    print('')
    print('Where -u is the user used to connect to the servers, it can be iuxu or ovmadm')
    print('Where "-s true" is the option to automatically sort all the VCPUs of the VMs.')
    print('')

#function to handle the different parameters:
parser = argparse.ArgumentParser()

parser.add_argument("-u", "--user", help="iuxu or admovm user, please specify")
parser.add_argument("-o", "--output", help="Define output name file")
parser.add_argument("-s", "--sort", help="Automatically sort the vcpus of the VMs")

args = parser.parse_args()

if args.user:
    specify_user=True
else:
    print_message()

if args.output:
    output_name=args.output
else:
    output_name="information"
    

if specify_user == True:
    run_program()
else:
    print_message()
    