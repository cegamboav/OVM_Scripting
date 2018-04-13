#!/bin/bash

# Name        : ovmDBCheck.sh
# Author      : carlos.gamboa , david.cerdas  
# Version     : 1.2
# Copyright   : GPLv2
# Description : This script checks the messages for known OVM Manager DB errors

clear&&printf "Starting the analysis...\n\n\n"
adminLog=$(find /u01 -name AdminServer.log)
adminOut=$(find /u01 -name AdminServer.out|egrep -v ovm_wlst)
config=$(find /u01 -name .config)

# Check the logs for known errors
function messagesIdentifier(){
	egrep 'odof.exception.ObjectNotFoundException|MySQLSyntaxErrorException.*Table.*doesn.*exist' -B 1 $1|$2 -2
	egrep 'Not.*enough.*space|inconsistencies' $1|$2 -2
}

# Print the current OVM Manager version
clear&&printf "OVM Version:\n\n$(cat $config) \n\n----------------------\n"

# Check for complete backups of the OVM DB
printf "Last complete backups:\n"
awk '/backup complete/ {print $1" "$18" "$19}' $adminLog|tail -4

# Print the first and last OVM DB errors found
printf "\n----------------------\nDB issues:\n\n"
	for flag in First Last;do
		printf "$flag messages:\n"
		for file in $adminLog $adminOut;do
			if [ "$flag" = "First" ];then 
				messagesIdentifier $file head	
			elif [ "$flag" = "Last" ];then
				messagesIdentifier $file tail
			fi
		done	
		printf "\n--------------------------------------------\n"
	done

printf "Current FS utilization:\n"
df -Th $(awk -F'=' '/^DBBACKUP=/ {print $2}' /etc/sysconfig/ovmm)

exit 0
