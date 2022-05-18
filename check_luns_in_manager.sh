#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : This script used check in a list of LUNs, if they are part of the manager environment.
###############################################################
## 14 Jun, 2021 : Created 
##
##
################################################################
##
#
Found_Luns=()
Names_of_found_LUNs=()
qty_of_LUNs=0

List_of_luns=$1


check_total_of_luns(){
	echo "Checking All the Luns in the manager."
	echo
	for i in $(ovmcli "list physicalDisk"|grep name|grep -v OVM_SYS_REPO_PART|cut -d ':' -f2- |cut -d ' ' -f1)
	do 
		lun_id=$(ovmcli "show physicalDisk id=$i"|grep Page83|cut -d '=' -f2)
		#echo "  Checking $lun_id ..."
		lun_exist=$(grep -i $lun_id $List_of_luns|wc -l)
		if [ $lun_exist -gt 0 ]
		then
			((qty_of_LUNs++))
			Found_Luns+="$lun_id"
			Names_of_found_LUNs+="$(ovmcli "show physicalDisk id=$i"|grep Name|egrep -v 'User-Friendly|mapper'|cut -d '=' -f2-)"
		fi
	done
	list_discovered_luns
}

list_discovered_luns(){
	echo
	if [ $qty_of_LUNs -gt 0 ]
	then
		echo "[Warning] I found $qty_of_LUNs LUNs from the list in the manager:" > result_lun.txt
		echo >> result_lun.txt
		j=0
		for i in ${Found_Luns[@]}
		do
			echo "  LUN: $i " >> result_lun.txt
			echo "    Name: ${Names_of_found_LUNs[j]}" >> result_lun.txt
			((j++))
			echo "  -----------" >> result_lun.txt
		done
	else
		echo
		echo "[OK] We do not found any of the LUNs of the list in the manager!" > result_lun.txt
	fi
	echo
	echo "Check result_lun.txt to see the results!"
}

if [ -z $List_of_luns ]
then
	clear
	echo "[Error] Provide the lis of lunst to check."
	echo 
	echo "For example: "
	echo "# bash check_luns_in_manager.sh list_of_luns.csv"
else
	clear
	check_total_of_luns
fi