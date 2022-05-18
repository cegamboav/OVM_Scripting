#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@kyndryl.com>
# Purpose : This script is to display the vm name and OS asociated to this VM From the manager Server
###############################################################
## 3 Mar, 2022 : Created 
##
##
################################################################
printf_fn(){
	case $2 in
		_Oracle_Linux_7) OSV="OracleLinux_7";;
		_None) OSV="NONE";;
		_Oracle_Linux_6) OSV="OracleLinux_6";;
		_Oracle_Linux_5) OSV="OracleLinux_5";;
		_Microsoft_Windows_Server_2012) OSV="Windows_Server_2012";;
		_Microsoft_Windows_Server_2016) OSV="Windows_Server_2016";;
		_Microsoft_Windows_Server_2008) OSV="Windows_Server_2008";;
		"") OSV="NONE";;
		*) OSV=$2;;
	esac
	printf "%-1s %-70s %-1s %-20s %-1s\n" "|" $1 "|" $OSV "|"
}

clear
ovmcli "list vm"|grep name|cut -d ' ' -f 5|cut -d ':' -f2 > vm_list.xls
echo "|===============================================================================================|"
printf_fn "VM_NAME" "OS_Version"
echo "|-----------------------------------------------------------------------------------------------|"
for i in $(cat vm_list.xls);do ovmcli "show vm name=$i">vm_info;VM_OS=$(cat vm_info|egrep 'Operating System'|cut -d '=' -f2-|sed 's/ /_/g');printf_fn $i $VM_OS;done
echo "|===============================================================================================|"