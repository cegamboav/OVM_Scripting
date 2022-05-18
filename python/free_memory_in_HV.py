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
#import sys
import subprocess
#import argparse

def get_memory_info():
    cmd='xm info |grep total_memory|cut -d : -f2'
    str_mem = subprocess.check_output(cmd, shell=True)
    int_mem = int(str_mem)
    return int_mem
    
    
def get_VM_name(vm_id):
    cmd='xm list {} -l|grep OVS|head -n 1|cut -d "/" -f 4'.format(vm_id)
    repository = subprocess.check_output(cmd, shell=True)
    cmd=' cat /OVS/Repositories/{}/VirtualMachines/{}/vm.cfg |grep OVM_simple_name|cut -d "\'" -f2'.format(repository.rstrip(),vm_id)
    vm_name= subprocess.check_output(cmd, shell=True)
    return vm_name.rstrip()
            
HV_Mem=0
HM_Mem=get_memory_info()
GB_HV_Mem=HM_Mem/1024
cmd='hostname'
Server_Name = subprocess.check_output(cmd, shell=True)
os.system('clear')
print('|'+'='*95+'|')
print('|{:95}|'.format('Server name: '+Server_Name.rstrip()))
#print(' {}'.format(HM_Mem))
print('|{:95}|'.format('Total Memory in MB: '+str(HM_Mem)))
#print(' {}'.format(GB_HV_Mem))
print('|{:95}|'.format('Total Memory in GB: '+str(GB_HV_Mem)))
print('|{:32}|{:15}|{:10}|{:6}|{:10}|{:8}|'.format('-'*33,'-'*17,'-'*12,'-'*8,'-'*12,'-'*8))
print('|{:32} | {:15} |{:10}  |{:6}  |{:10}  |{:8}|'.format('VM_ID','VM_Name','VM_Memory','VM_GB','Free_MB','Free_GB'))
print('|{:32}|{:15}|{:10}|{:6}|{:10}|{:8}|'.format('-'*33,'-'*17,'-'*12,'-'*8,'-'*12,'-'*8))


total_free_mem=HM_Mem
free_HV_GB=0
os.system('xm li|egrep -v \'Name|Domain\'|awk \'{print $1}\' > vms.txt')

#Get the server list
input_file="vms.txt"

cmd='xm li Domain-0|grep -v Name|tr -s " " |cut -d " " -f 3'
VM_Mem = subprocess.check_output(cmd, shell=True)
total_free_mem=total_free_mem-int(VM_Mem.rstrip())
free_HV_GB=total_free_mem/1024
VM_Mem_gb=int(VM_Mem.rstrip())/1024
name_VM='Domain-0'
#print(name_VM)
print('|{:32} | {:15} |{:10}  |{:4}GB  |{:10}  |{:5}GB |'.format('Domain-0',name_VM,str(VM_Mem.rstrip()),str(VM_Mem_gb),str(total_free_mem),str(free_HV_GB)))

#read the server file:
with open(input_file) as the_input_file:
    #We proceed to navegate the lines one by one:
    for input_line in the_input_file:
        #print('{}'.format(input_line.rstrip()))
        cmd='xm li {}|grep -v Name|tr -s " " |cut -d " " -f 3'.format(input_line.rstrip())
        VM_Mem = subprocess.check_output(cmd, shell=True)
        total_free_mem=total_free_mem-int(VM_Mem.rstrip())
        free_HV_GB=total_free_mem/1024
        VM_Mem_gb=int(VM_Mem.rstrip())/1024
        name_VM=get_VM_name(input_line.rstrip())
        #print(name_VM)
        print('|{:32} | {:15} |{:10}  |{:4}GB  |{:10}  |{:5}GB |'.format(input_line.rstrip(),name_VM,str(VM_Mem.rstrip()),str(VM_Mem_gb),str(total_free_mem),str(free_HV_GB)))
print('|{:32}|{:15}|{:10}|{:6}|{:10}|{:8}|'.format('-'*33,'-'*17,'-'*12,'-'*8,'-'*12,'-'*8))
print('|{:95}|'.format('Total Free Memory: '+str(total_free_mem)+' MB       In GB: '+str(free_HV_GB)+' GB'))
print('|'+'='*95+'|')