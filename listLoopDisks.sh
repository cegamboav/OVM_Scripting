#!/bin/bash

# Name        	: listLoopDisks.sh
# Author      	: carlos.gamboa and david.cerdas
# Version     	: 1
# Copyright   	: GPLv2
# Description	: This script lists the disks and its correspond loop , 
# 		   based on the vm.cfg file of the running VMs in Dom0, OVM.	
# Usage		: ./listLoopDisks.sh 	

clear
echo "Server Name:"
hostname
echo "----------------------------------------------------------------------------------------"

for i in `xm list|awk '{print $1}'|egrep -v 'Name|Domain-0'`;
        do
        for j in `find /OVS/Repositories/ -name $i`;
                do
                echo VM "ID and Name:"
                echo $i
                cat $j/vm.cfg|egrep 'OVM_simple_name'
                echo
                cat $j/vm.cfg|egrep 'disk' > /tmp/disk.tmp
                echo "Loops:"
                echo
                echo > /tmp/disk2.tmp
                awk -F"'" '/disk/ { for (i = 2; i <= NF; i=i+2) print $i }' /tmp/disk.tmp|cut -d':' -f2|cut -d"," -f1 >> /tmp/disk2.tmp
                for h in `cat /tmp/disk2.tmp|grep -v cdrom`
                        do
                        echo "device:  "$h
                        echo "Loop:    "`losetup -j $h`
                        echo "--------------------"
                done
        done
done
echo "----------------------------------------------------------------------------------------"
