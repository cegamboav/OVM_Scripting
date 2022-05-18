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
import subprocess
import sys
import os.path
from os import path
import argparse

#Get the hostname of the Manager:
cmd="hostname"
hn = subprocess.check_output(cmd, shell=True)

#Variables of the script
have_file=False
have_password=False
continue_program=True
sort_vcpus=False

#function to test the ovm_control command status:
def check_ovm_control():
    print('    Checking the status of the ovm_control command...')
    print('-'*10)
    
    #Now open the configuration file to find the first vm:
    with open(args.file) as the_VCPU_file:
        #We proceed to navegate the lines one by one:
        for VCPU_line in the_VCPU_file:
            #Splitting the line to obtain the head of the line:
            split_string = VCPU_line.rstrip().split(",", 1)
            substring = split_string[0]
            
            #now we get the lengh of the string
            var_lenght=len(substring)
            
            #If the lenght is 32, is a VM ID
            if var_lenght == 32:
                #run the command:
                cmd="./ovm_vmcontrol -u Admin -p {} -h {} -U {} -c getvcpu 2;printf \"%d\n\" $? > status.txt".format(args.password,hn.rstrip(),substring)
                os.system(cmd)
                
                #Get the status of the command:
                status=subprocess.check_output('cat status.txt', shell=True)
                
                print(status.rstrip())
                print('-'*10)
                
                #If the status is 0, means it comple correctly
                if status.rstrip() == '0':
                    print('      [OK] The ovm_control command looks fine!')
                    return 0
                    quit()
                else:
                    print('      [Error] The ovm_control command do not return a correct code, please check it!')
                    return 1
                    quit()
                   
                
#function to do the tests:
def do_the_tests():
    status=-1
    os.system('clear')
    print('Doing the Prechecks:')
    print('  Start testing...')
    print('')
    print('    Checking if ovm_vmcontrol file exist...')
    print('')
    
    #check if the ovm_control exist in the current directory:
    if path.isfile('./ovm_vmcontrol') == False:
        print('      [Error] The file ovm_vmcontrol DOES NOT exist!!!')
        print('')
        quit()
    else:
        print('      [OK] The ovm_vmcontrol file exist!')
        status=0
        print('')
        
    #If all is okay, call the function to check the ovm_control command:
    status=check_ovm_control()
    
    print('='*40)
    return status
        

def get_an_answer(vm_id, vcpu_start, vcpu_ends):
    answer=0
    
    while answer == 0:
        print('='*40)
        print('')
        print('Do you want to apply the following change?:')
        print('')
        print('VM_ID: {}    From: {}  to  {}'.format(vm_id,vcpu_start,vcpu_ends))
        print('')
        choose = raw_input("Insert Y to proceed, N to skip this VM or C to cancel! ") 

        if choose=='y' or choose=='Y':
            proceed=1
            answer=1
        elif choose == 'n' or choose == 'N':
            proceed=0
            answer=1
        elif choose == 'c' or choose == 'C':
            proceed=-1
            answer=1
        else:
            print('[Error] Insert Y, N or C!!!')
    return proceed

#function to collect the start vcpu
def collect_start_cpu(vm_id):
    cmd="grep {} {}|cut -d ',' -f5".format(vm_id,args.file)
    cpu = subprocess.check_output(cmd, shell=True)
    return cpu
    
#Function to collect the end vcpu
def collect_end_cpu(vm_id):
    cmd="grep {} {}|cut -d ',' -f6".format(vm_id,args.file)
    cpu = subprocess.check_output(cmd, shell=True)
    return cpu

#function to apply the vcpu change
def apply_change(vm_id, vcpu_start, vcpu_ends):
    print('')
    cmd="./ovm_vmcontrol -u Admin -p {} -h {} -U {} -c setvcpu -s {}-{}".format(args.password,hn.rstrip(),vm_id,vcpu_start,vcpu_ends)
    print(cmd)
    os.system(cmd)


#function to read the file with the information
def read_file():
    #first we run the tests:
    continue_program=do_the_tests()
    
    #If the tests finish correctly
    if continue_program == 0:

        with open(args.file) as the_VCPU_file:
            #We proceed to navegate the lines one by one:
            for VCPU_line in the_VCPU_file:
                #Splitting the line to obtain the head of the line:
                split_string = VCPU_line.rstrip().split(",", 1)
                substring = split_string[0]
                
                #now we get the lengh of the string
                var_lenght=len(substring)
                
                #If the lenght is 32, is a VM ID
                if var_lenght == 32:
                    #Start to collect the information to be applyed
                    start_cpu=collect_start_cpu(substring)
                    end_cpu=collect_end_cpu(substring)
                    
                    #Get an answer from the user to apply the changes:
                    proceed=get_an_answer(substring,start_cpu.rstrip(),end_cpu.rstrip())
                    
                    #If the answer is 1, means it goings to apply the change:
                    if proceed == 1:
                        #call the function to apply the changes:
                        apply_change(substring,start_cpu.rstrip(),end_cpu.rstrip())
                        print('='*40)
                    #If is -1 means cancel the exectution:
                    elif proceed == -1:
                        quit()
                    else:
                        print('='*40)
                        

#function to handle the different parameters:
parser = argparse.ArgumentParser()

parser.add_argument("-p", "--password", help="Add the password of the manager")
parser.add_argument("-f", "--file", help=".csv file used to apply the changes")

args = parser.parse_args()

if args.file:
    have_file=True

if args.password:
    have_password=True

if have_file == False:
    os.system('clear')
    print("[Error] Insert the configuration file as a parameter:")
    print('')
    print("Example:")
    print("python2.7 apply_vcpu_pin_configuration.py -f information.csv -p <MANAGERPASSWD>")
    print('')
    continue_program=False

if have_password == False:
    os.system('clear')
    print("[Error] Provide the manager password as a parameter:")
    print('')
    print("Example:")
    print("python2.7 apply_vcpu_pin_configuration.py -f information.csv -p <MANAGERPASSWD>")
    print('')
    continue_program=False

if continue_program == True:
    read_file()
    
