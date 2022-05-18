#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : Script to get the fiendly name of a LUN from it UUID
###############################################################
## 03 May, 2022 : Created 
##
##
################################################################
##

show_help=0

exist_lun(){
	clear
	echo "LUN Device: $lun_name"
	echo
	echo " Searching ...."
	luns=$(ovmcli "list PhysicalDisk"|cut -d ":" -f 2|cut -d " " -f 1)
	exist=0
	for i in `echo $luns`
	do
		page_id=$(ovmcli "show PhysicalDisk id=$i"|egrep 'Page83 ID'|cut -d " " -f6)
		if [ "$page_id" = "$lun_name" ]
		then
			lname=$(ovmcli "show PhysicalDisk id=$i"|egrep 'Name'|egrep -v 'Device Name|User-Friendly'|cut -d "=" -f2)
			id_lun=$i
			exist=1
			break
		fi
	done
}

get_name(){
	exist_lun
	if [ $exist -eq 0 ]
	then
		echo "Lun do not exist in the Manager DB"
	else
		echo
		echo '---------------------------------'
		echo "Friendly name:	$lname"
		echo "ID: 				$id_lun"
		echo '---------------------------------'
	fi
}


#Function to print example of how use the script
print_example(){
	clear
	echo "[Error] The LUN ID parameter is missing."
	echo
	echo "The script should be ran link this:"
	echo "bash get_LUN_name.sh -l <36XXXXXXXXX>"
	echo
	echo "Example:"
	echo "bash get_LUN_name.sh -l 3600507680c8183c660000000000006f2"
	echo
}


while getopts "l:h:" option; do
	case $option in
		l) lun_name=$OPTARG;;
		h) show_help=1;;
		?) echo "I do not recognize: $OPTARG as a valid argument";;
	esac
done

if [ $show_help -eq 1 ]
then
	print_example
fi

if [ -z "$lun_name" ]
then
	print_example
else
	get_name
fi