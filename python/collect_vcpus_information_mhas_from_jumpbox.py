#!/bin/bash
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

#Variables of the script
have_file=False
have_change=False
have_user=False
continue_program=0

## Function to create temp directory
def createtempfolder():
	os.system('mkdir -p tmp_dir')

##Function to create the server files:
def create_server_file(ServerName):
    os.system('echo "name" > tmp_dir/temp_server_file.csv')
    cmd='echo {} >> tmp_dir/temp_server_file.csv'.format(ServerName)
    os.system(cmd)

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

    #Collect the xmlist of all the VMs in the input_file:
    with open(input_file) as the_input_file:
        #We proceed to navegate the lines one by one:
        for input_line in the_input_file:
            if input_line.rstrip() != "name":
                print ('    {}:'.format(input_line.rstrip()))
                print ('      Creating file {}.xmlist.txt'.format(input_line.rstrip()))
                #Call the fucntion to create the server file:
                create_server_file(input_line.rstrip())
                #now we call the function to run the script in the servers:
                cmd='icmd -e -cmd "sudo xm list;sudo xm info|grep nr_cpus" -u {} -s tmp_dir/temp_server_file.csv -t {} -cwd /usr/bin/ -sync -fq -n demo-exec1 |grep -v INFO > tmp_dir/{}.xmlist.txt'.format(args.user,args.change,input_line.rstrip())
                os.system(cmd)
                print ('      Creating file {}.xmvcpu.txt'.format(input_line.rstrip()))
                cmd='icmd -e -cmd "sudo xm vcpu-list" -u {} -s tmp_dir/temp_server_file.csv -t {} -cwd /usr/bin/ -sync -fq -n demo-exec1 |grep -v INFO > tmp_dir/{}.xmvcpu.txt'.format(args.user,args.change,input_line.rstrip())
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

def show_message():
    os.system('clear')
    print("[Error] Insert the Change ID, .csv file or user to continue")
    print('')
    print("Example:")
    print("python2.7 collect_vcpus_information.py -c CHXXXXXXXXX -f hostp1.csv -u iuxu -o information")
    print('')


#function to handle the different parameters:
parser = argparse.ArgumentParser()

parser.add_argument("-c", "--change", help="Add the SNOW change number.")
parser.add_argument("-f", "--file", help="File with the list of hosts to check.")
parser.add_argument("-u", "--user", help="iuxu or ovmadm user to connect to the server.")
parser.add_argument("-o", "--output", help="Optional output file name.")

args = parser.parse_args()

if args.file:
    have_file=True
    input_file=args.file

if args.change:
    have_change=True
    
if args.user:
    have_user=True
    
if args.output:
    output_name=args.output
else:
    output_name="information"
    
if have_change == True and have_file == True and have_user == True:
    createtempfolder()
    check_servers()
    delete_working_folder()
else:
    show_message()