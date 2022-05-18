#!/usr/bin/env python2.7
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@kyndryl.com>
# Purpose : This script is to display the total free memory in a HV
###############################################################
## 26 Apr, 2022 : Created 
##
##
################################################################
import os
import sys
import subprocess
import argparse

#Variables:
continue_program=0
show_help=0
real_name=''

#function to check if the VM exist:
def test_if_VM_exist(vm_name):
    vm_exist=0
    cmd='ovmcli "list vm"|grep -i {}|wc -l'.format(vm_name)
    vm_exist=subprocess.check_output(cmd, shell=True)
    if vm_exist.rstrip() == "1":
        return 1
    else:
        return 0
    
#Set the real name of the VM:
def Set_real_VM_ID(consult_name):
    cmd='ovmcli "list vm"|grep -i {}|tr -s " " |cut -d " " -f 2|cut -d ":" -f 2'.format(consult_name)
    real_id=subprocess.check_output(cmd, shell=True)
    return real_name
    
def print_double_line():
    print("|"+"="*123+"|")

def print_simple_line():
    print('|'+'-'*22+'|'+'-'*34+'|'+'-'*17+'|'+'-'*37+'|'+'-'*9+'|')

def print_head():
    print_double_line()
    print('| {:20} | {:32} | {:15} | {:35} | {:7} |'.format("VM_Name","VM_ID","HV_Name","Root_disk_Name","Size"))
    print_simple_line()
    
def print_vm_information(internal_vm_id):
    cmd='ovmcli "show vm name={}" > vm_profile.txt'.format(internal_vm_id)
    os.system(cmd)

    cmd='grep Name vm_profile.txt|tr -s " " |cut -d " " -f 4'
    internal_vm_name=subprocess.check_output(cmd, shell=True)

    cmd='cat vm_profile.txt|egrep \'Status =\'|tr -s " " |cut -d " " -f 4'
    vm_status=subprocess.check_output(cmd, shell=True)

    if vm_status.rstrip() == 'Running':
        cmd='egrep \'Server =\' vm_profile.txt|cut -d "[" -f 2|cut -d "]" -f 1'
        Running_Server=subprocess.check_output(cmd, shell=True)
    else:
        Running_Server="VM_Not_Running"

    cmd='grep VmDiskMapping vm_profile.txt |tr -s " " |cut -d " " -f 5 > VmDiskMapping.txt'
    os.system(cmd)

    #Get the server list
    input_file="VmDiskMapping.txt"

    #read the server file:
    with open(input_file) as the_input_file:
        #We proceed to navegate the lines one by one:
        for input_line in the_input_file:

            cmd='ovmcli "show VmDiskMapping id=$i"> vdisk_information.txt'.format(input_line.rstrip())
            os.system(cmd)

            cmd='grep Slot vdisk_information.txt|tr -s " " |cut -d " " -f 4'
            slot=subprocess.check_output(cmd, shell=True)

            if slot == '0':
                vd='0'
                cmd='egrep \'Virtual Disk\' vdisk_information.txt|wc -l'
                vd=subprocess.check_output(cmd, shell=True)

                if vd == '0':
                    cmd='grep Physical vdisk_information.txt|tr -s " " |cut -d " " -f 5'
                    ph_disk_id=subprocess.check_output(cmd, shell=True)

                    cmd='ovmcli "show physicalDisk id={}"|grep Size|tr -s " " |cut -d " " -f 5'.format(ph_disk_id)
                    vdisk_size=subprocess.check_output(cmd, shell=True)

                    cmd='ovmcli "show physicalDisk id={}"|grep Page83|tr -s " " |cut -d " " -f 5'.format(ph_disk_id)
                    vdisk_name_no_spaces=subprocess.check_output(cmd, shell=True)
                else:
                    cmd='egrep \'Virtual Disk\' vdisk_information.txt|tr -s " " |cut -d " " -f 5'
                    vdisk_name=subprocess.check_output(cmd, shell=True)

                    cmd='egrep \'Virtual Disk\' vdisk_information.txt|cut -d "[" -f 2|cut -d "]" -f 1|sed \'s/ /_/g\''
                    vdisk_name_no_spaces=subprocess.check_output(cmd, shell=True)

                    #vdisk_img=

                    cmd='ovmcli "show virtualdisk name=$vdisk_name" > virtualdisk.txt'
                    os.system(cmd)

                    cmd='egrep Max virtualdisk.txt|tr -s " " |cut -d " " -f 5'
                    vdisk_size=subprocess.check_output(cmd, shell=True)

    print_line (internal_vm_name.rstrip(),internal_vm_id.rstrip(),Running_Server.rstrip(),vdisk_name_no_spaces.rstrip(),vdisk_size.rstrip())
    break
    
#Function to show just a single VM in the Manager
def individual_vm():
    continue_program=test_if_VM_exist(args.vm)
    if continue_program == 1:
        real_name=Set_real_VM_Name(args.vm)
        #print('Name: {}'.format(real_name))
        os.system('clear')
        print_head()
        #print_vm_information $real_name
        print_double_line()
    else:
        os.system('clear')
        print('[Error]		VM name: {} does not exist in this manager!!!'.format(args.vm))
        print('')


#function to show all the VMs in the Manager
def list_all_the_vms():
	os.system('clear')
	print_head
	#for i in $(ovmcli "list vm"|grep name|cut -d ' ' -f 5|cut -d ':' -f2)
	#do
	#	print_vm_information $i
		#echo $i
	#done
	print_double_line

#Function to print example of how use the script
def print_example():
    os.system('clear')
    print("[Error] Provide the VM name as a parameter:")
    print('')
    print("Example:")
    print("python2.7 {} -v <vm_name>".format(sys.argv[0]))
    print('')
    print('Where -v is the name of the VM')
    print('-'*30)
    print("Example:")
    print("python2.7 {} -a all".format(sys.argv[0]))
    print('')
    print('Where -a all specify that you want to see all the VMs')
    print('')


#function to handle the different parameters:
parser = argparse.ArgumentParser()

parser.add_argument("-v", "--vm", help="VM name to search")
parser.add_argument("-a", "--all", help="Show all the VMs in the Manager")

args = parser.parse_args()

if args.vm:
    individual_vm()
else:
    if args.all:
        list_all_the_vms()
    else:
        print_example()