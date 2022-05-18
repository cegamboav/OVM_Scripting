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

def sort_vcpus():
    print('')

def read_file():
    input_file="tmp_dir/server_names.csv"
    os.system('echo "" > tmp_dir/servers_to_sort.txt')
    #Collect the xmlist of all the VMs in the input_file:
    with open(input_file) as the_input_file:
        #We proceed to navegate the lines one by one:
        for input_line in the_input_file:
            cmd='cat tmp_dir/{}.xmlist.txt|grep nr_cpus |tr -s " " |cut -d " " -f 3'.format(input_line.rstrip())
            srv_vcpus = subprocess.check_output(cmd, shell=True)            
            tot_vcpus=count_vcpus(input_line.rstrip())
            if tot_vcpus > 0:
                
                if int(srv_vcpus.rstrip()) >= tot_vcpus:
                    print('[OK] El server {} tiene suficientes vcpus'.format(input_line.rstrip()))
                    os.system('echo {} >> tmp_dir/servers_to_sort.txt'.format(input_line.rstrip()))
                    print('-'*30)
                else:
                    print('[Error] El server no tiene suficientes vcpus')
                    print('Cpus del server: '+str(srv_vcpus.rstrip()))
                    print('VCPUS asignados: '+str(tot_vcpus))
                    print('-'*30)
            else:
                print('El server muestra 0 vcpus')
                print('-'*30)
read_file()