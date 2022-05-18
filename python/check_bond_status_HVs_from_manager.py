#!/usr/bin/env python2.7
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@kyndryl.com>
# Purpose : This script is to display the vm name and OS asociated to this VM From the manager Server
###############################################################
## 13 Apr, 2022 : Created 
##
##
################################################################

import os
import sys
import subprocess
import argparse

## Function to create temp directory
def createtempfolder():
	os.system('mkdir -p tmp_dir')

## Function to delete the temporary directory
def deletetempfolder():
    os.system('rm -rf tmp_dir')

##Function to collect the list of the servers attached to the manager:
def collect_server_list():
    cmd='ovmcli "list server"|grep name|tr -s " " |cut -d " " -f 3|cut -d \':\' -f2 > tmp_dir/servers.txt'
    os.system(cmd)
    
##Function to print a simple line in the report
def print_simple_line():
    print('|'+'-'*63+'|')

##Function to print a double line in the report    
def print_double_line():
    print('|'+'='*63+'|')

##Fucntion to check the bond status in the servers:
def check_servers():
    #Get the server list
    input_file="tmp_dir/servers.txt"
    
    #read the server file:
    with open(input_file) as the_input_file:
        #We proceed to navegate the lines one by one:
        for input_line in the_input_file:
            print_double_line()
            #print the name of the server:
            print('| {:61} |'.format(input_line.rstrip()))
            
            #collect the Bonds configured in the particular server:
            cmd='ssh {}@{} "sudo ls /proc/net/bonding/" > tmp_dir/bonds.txt'.format(args.user,input_line.rstrip())
            os.system(cmd)
            
            #Then read the bonds file:
            bonds_file="tmp_dir/bonds.txt"
            #Now we read the bonds file:
            with open(bonds_file) as the_bonds_file:
                number_of_bonds=0
                #We proceed to navegate the lines one by one:
                for bond_line in the_bonds_file:
                    #print a simple line if this is a differente bond as 0
                    if number_of_bonds > 0:
                        print_simple_line()
                    
                    #print the bond name:
                    print('| {:61} |'.format(bond_line.rstrip()))
                    
                    #print the header:
                    print('| {:9} | {:31} | {:15} |'.format('Interface','Link Status','Bond Status'))
                    
                    #collect the eths configured in this particular bond:
                    cmd='ssh {}@{} "sudo cat /proc/net/bonding/{}|grep Interface|cut -d \':\' -f2" > tmp_dir/eths.txt'.format(args.user,input_line.rstrip(),bond_line.rstrip())
                    os.system(cmd)
                    
                    #read the eth file:
                    eths_file="tmp_dir/eths.txt"
                    #Now we read the interfeces of the configured bond:
                    with open(eths_file) as the_eths_file:
                        #We proceed to navegate the lines one by one:
                        for eth_line in the_eths_file:
                            #Collect the required information as link status and bond status:
                            cmd='ssh {}@{} "sudo ethtool eth0|egrep \'Link detected\'"'.format(args.user,input_line.rstrip())
                            eth_link = subprocess.check_output(cmd, shell=True)
                            cmd='ssh {}@{} "sudo cat /proc/net/bonding/bond0|grep {} -A 1|tail -n 1"'.format(args.user,input_line.rstrip(),eth_line.rstrip())
                            eth_status = subprocess.check_output(cmd, shell=True)
                            #Now print the information to create the report:
                            print('|{:10} | {:30} | {:15} |'.format(eth_line.rstrip(),eth_link.rstrip(),eth_status.rstrip()))
                    #increase the number of bonds analyzed to this Server:
                    number_of_bonds += 1
    print_double_line()
    
def run_program():
    createtempfolder()
    collect_server_list()
    check_servers()
    deletetempfolder()
    
def print_message():
    os.system('clear')
    print("[Error] Provide the user as a parameter:")
    print('')
    print("Example:")
    print("python2.7 {} -u <iuxu or ovmadm>".format(sys.argv[0]))
    print('')
    print('Where -u is the user used to connect to the servers, it can be iuxu or ovmadm')
    print('')
    

#function to handle the different parameters:
parser = argparse.ArgumentParser()

parser.add_argument("-u", "--user", help="iuxu or admovm user, please specify")

args = parser.parse_args()

if args.user:
    run_program()
else:
    print_message()