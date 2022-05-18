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

output_name="information"
ignore=False

cmd='echo > {}.sort.csv'.format(output_name)
os.system(cmd)

cmd='echo > {}.output.csv'.format(output_name)
os.system(cmd)

csv_file="{}.csv".format(output_name)
with open(csv_file) as the_VCPU_file:
        #We proceed to navegate the lines one by one:
        for VCPU_line in the_VCPU_file:
            #Splitting the line to obtain the head of the line:
            split_string = VCPU_line.rstrip().split(",", 1)
            substring = split_string[0]

            if substring != "================":
                if substring != "VM ID":
                    if substring != "":
                        if substring == "Domain-0":
                            #If the ingnore is in True, means the Server do not have VMs running
                            if ignore == False:
                                split_string_dom0 = VCPU_line.rstrip().split(",", 4)
                                prev_vcpu = split_string_dom0[3]
                                dom0vcpus = split_string_dom0[1]
                                print('    Dom-0     from 0 to '+prev_vcpu)
                                cmd='echo Dom-0 VCPUS:{} From:0 To:{}>>{}.output.csv'.format(dom0vcpus,prev_vcpu,output_name)
                                os.system(cmd)
                        else:
                            #now we get the lengh of the string
                            var_lenght=len(substring)

                            #If the lenght is 32, is a VM ID
                            if var_lenght == 32:
                                split_string_vm_vcpus = VCPU_line.rstrip().split(",", 4)
                                vm_vcpus = split_string_vm_vcpus[1]
                                starting=int(prev_vcpu)+1
                                ending=int(prev_vcpu)+int(vm_vcpus)
                                prev_vcpu=str(ending)
                                print('    VM: '+substring+' VCPUS='+vm_vcpus+' starting='+str(starting)+' ending='+str(ending))
                                cmd='echo {},{},{},{}>>{}.sort.csv'.format(substring,vm_vcpus,starting,ending,output_name)
                                os.system(cmd)
                                cmd='echo ID: {} VCPUS:{} From:{} To:{}>>{}.output.csv'.format(substring,vm_vcpus,starting,ending,output_name)
                                os.system(cmd)
                            else:
                                split_string_2 = VCPU_line.rstrip().split(",", 3)
                                running_vms = split_string_2[2]
                                
                                if running_vms == '0':
                                    print('-'*30)
                                    print('  Server: '+substring+' does not have running VMs, Ignoring')
                                    ignore=True
                                else:
                                    print('-'*30)
                                    print('  Checking Server: '+substring)
                                    cmd='echo "===============================" >> {}.output.csv;echo "Server: "{} >> {}.output.csv'.format(output_name,substring,output_name)
                                    os.system(cmd)
                                    ignore=False