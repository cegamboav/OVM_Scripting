#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : This script list all the Luns used by VMs
###############################################################
## 04 May, 2022 : Created 
##
##
################################################################
##
#
call_head=0

print_double_line(){
	echo "|========================================================================================================|"
}

print_simple_line(){
	echo "|--------------------------------------------------------------------------------------------------------|"
}

print_lun_name(){
	printf "%-1s %-4s %-57s %-5s %-33s %-1s\n" "|" "LUN:" $1 "UUID:" $2 "|"
}

print_vm_name(){
	printf "%-1s %-15s %-86s %-1s\n" "|" "      VM_Name:" $1 "|"
}

check_luns(){
	var_name=$1
	for i in $(ovmcli "list physicalDisk"|grep -i $var_name|tr -s " "|cut -d " " -f 2|cut -d ":" -f 2) 
		do 
		hd=$(ovmcli "show physicalDisk id=$i" |grep "VmDiskMapping"| wc -l)
		if [ $hd -gt 0 ]
		then
			if [ $call_head -eq 0 ]
			then
				print_double_line
				call_head=1
			else
				print_simple_line
			fi
			Lun_Name=$(ovmcli "show physicalDisk id=$i" | egrep "Id =" | cut -d "[" -f 2 | cut -d "]" -f 1) 
			#echo  "Lun_Name=$Lun_Name" 
			Page83=$(ovmcli "show physicalDisk id=$i" | grep Page83 | tr -s " " | cut -d " " -f 5)
			#echo "  UUID =$Page83"
			print_lun_name $Lun_Name $Page83
			for h in $(ovmcli "show physicalDisk id=$i" | grep VmDiskMapping | tr -s " " | cut -d " " -f 5)
			do 
				vmname=$(ovmcli "show VmDiskMapping id=$h"  | egrep "Vm =" | cut -d "[" -f 2 | cut -d "]" -f 1)	
				print_vm_name $vmname
			done
		fi 
	done 
	if [ $call_head == 1 ]
	then
		print_double_line
	else
		echo "[OK]  No LUNs are used by any VM in this Mamanger."
		echo ""
	fi
}


clear
echo "Checking LUNs..."
echo ""

if [ -z $1 ]
then
	check_luns "name"
else
	check_luns $1
fi