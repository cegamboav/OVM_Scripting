#!/usr/bin/env python3
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@kyndryl.com>
# Purpose : This script is to display the vm name and OS asociated to this VM From the manager Server
###############################################################
## 3 Mar, 2022 : Created 
##
##
################################################################
import os
import subprocess

#Variables:
#variable to obtain the OS name
OSV=""

#Function to put a pretty name in the OS side:
def print_fn(VM_Name,OS_VM):
    #We are going to evaluate the name of the Os and put it fine:
    if OS_VM == "_Oracle_Linux_7":
        OSV="Oracle Linux 7"
    elif OS_VM == "_None":
        OSV="NONE"
    elif OS_VM == "_Oracle_Linux_6":
        OSV="Oracle Linux 6"
    elif OS_VM == "_Oracle_Linux_5":
        OSV="Oracle Linux 5"
    elif OS_VM == "_Microsoft_Windows_Server_2012":
        OSV="Windows Server 2012"
    elif OS_VM == "_Microsoft_Windows_Server_2016":
        OSV="Windows Server 2016"
    elif OS_VM == "_Microsoft_Windows_Server_2008":
        OSV="Windows Server 2008"
    elif OS_VM == "":
        OSV="NONE"
    else:
        OSV=OS_VM
        
    #then we are going to proceed to print the line in the screen
    print('| {0:55} | {1:20} |'.format(VM_Name, OSV))

def print_header():
    print('|'+'='*80+'|')
    print('| {0:55} | {1:20} |'.format('VM_NAME', 'OS_Version'))
    print('|'+'-'*80+'|')

#This function is going to run the program
def run_program():
    #First we are going to clear the screen
    os.system('clear')
    #Then we are going to collect the complete listo of the VMs in the environment
    os.system('ovmcli "list vm"|grep name|cut -d \' \' -f 5|cut -d \':\' -f2 > vm_list.xls')
    
    #we proceed to print the header of the table:
    print_header()

    #The we are going to proceed to open the file with the name of the VMs:
    with open('vm_list.xls') as the_vms_file:
        #We proceed to navegate the lines one by one:
        for VM_line in the_vms_file:
            #We prepare the centense to obtain the information of the VM
            cmd = 'ovmcli "show vm name={}">vm_info'.format(VM_line.rstrip())
            #Now run the command
            os.system(cmd)
            #We obtain the OS Name of the VM
            output = subprocess.check_output("cat vm_info|egrep \'Operating System\'|cut -d \'=\' -f2-|sed \'s/ /_/g\'", shell=True)
            #Now we call the print_fn function:
            print_fn(VM_line.rstrip(),output.rstrip())
    #Now print the botton line of the table:
    print('|'+'='*80+'|')

#Here start the program
run_program()