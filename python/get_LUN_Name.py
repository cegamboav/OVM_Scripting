#!/usr/bin/env python2.7
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : Script to get the fiendly name of a LUN from it UUID
###############################################################
## 03 May, 2022 : Created 
##
##
################################################################
##

import os
import sys
import subprocess
import argparse

show_help=0
lname=''
id_lun=''


def exist_lun():
    os.system('clear')
    print('LUN Device: {}'.format(lun_name))
    print('')
    print('Searching ....')
    cmd='ovmcli "list PhysicalDisk"|cut -d ":" -f 2|cut -d " " -f 1 > lun_list.txt'
    os.system(cmd)
    
    #read the eth file:
    lun_list="lun_list.txt"
    #Now we read the interfeces of the configured bond:
    with open(lun_list) as the_lun_list_file:
        #We proceed to navegate the lines one by one:
        for lun_line in the_lun_list_file:
            cmd='ovmcli "show PhysicalDisk id={}"|egrep \'Page83 ID\'|cut -d " " -f6'.format(lun_line.rstrip())
            page_id = subprocess.check_output(cmd, shell=True)
            if page_id.rstrip() == lun_name:
                cmd='ovmcli "show PhysicalDisk id={}"|egrep Name|egrep -v \'Device Name|User-Friendly\'|cut -d "=" -f2'.format(lun_line.rstrip())
                lname = subprocess.check_output(cmd, shell=True)
                id_lun= lun_line
                print('')
                print('---------------------------------')
                print('Friendly name:	{}'.format(lname))
                print('ID: 				{}'.format(id_lun)) 
                print('---------------------------------')
                
                return 1
                break
    
	


def get_name():
    status=0
    status=exist_lun()
    if status != 1:
        print('Lun do not exist in the Manager DB')
    cmd='rm -f lun_list.txt'
    os.system(cmd)


#Function to print example of how use the script
def print_example():
    os.system('clear')
    print('[Error] The LUN ID parameter is missing.')
    print('')
    print('The script should be ran link this:')
    print('python2.7 {} -l <36XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX>'.format(sys.argv[0]))
    print('')
    print('Example:')
    print('python2.7 {} -l 3600507680c8183c660000000000006f2'.format(sys.argv[0]))
    print('')


#function to handle the different parameters:
parser = argparse.ArgumentParser()

parser.add_argument("-l", "--lun", help="LUN ID <36XXXXXXXXX>")

args = parser.parse_args()

if args.lun:
    lun_name=args.lun
    get_name()
else:
    print_example()
