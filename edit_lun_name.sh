#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : Script to get the fiendly name of a LUN from it UUID
###############################################################
## 03 Oct, 2021 : Created 
##
##
################################################################
##

lun_name=$1

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

collect_data(){
	echo
	echo $1
	read answer
}

yes_or_no(){
	ok_y_n=0
	while [ $ok_y_n -eq 0 ]
	do
		echo $1
		read y_n
		if [ $y_n == "y" ] || [ $y_n == "Y" ] || [ $y_n == "n" ] || [ $y_n == "N" ]
		then
			ok_y_n=1
		else
			clear
			echo "[Error] Need insert y/n"
			echo
		fi
	done
}

Collect_new_lun_name(){
	ok=0
	while [ $ok -eq 0 ]
	do
		echo
		collect_data "Insert the new Name of the LUN:"
		echo
		yes_or_no "Is '$answer' the correct name for the LUN $lname ?   Y/N"
		if [ $y_n = "y" ] || [ $y_n = "Y" ]
		then
			echo
			new_name=$answer
			collect_data "Insert the new Description of the LUN:"
			echo
			yes_or_no "Is '$answer' the correct description for the LUN $lname ?   Y/N"
			if [ $y_n = "y" ] || [ $y_n = "Y" ]
			then
				new_description=$answer
				echo
				yes_or_no "Do you want to set the LUN as shareable?   Y/N"
				if [ $y_n = "y" ] || [ $y_n = "Y" ]
				then
					lun_shra="yes"
				else
					lun_shra="no"
				fi
				echo '-------------------------------'
				yes_or_no "We are going to proceed to change the name to '$new_name', the description to '$new_description' and the Shareable to '$lun_shra', for the LUN $lname ?   Y/N"
				if [ $y_n = "y" ] || [ $y_n = "Y" ]
				then
					echo "Changing LUN name ..."
					ovmcli "edit PhysicalDisk id=$id_lun name=$new_name"
					echo "Changing LUN description ..."
					ovmcli "edit PhysicalDisk id=$id_lun description=$new_description"
					echo "Set the shareable parameter ..."
					ovmcli "edit PhysicalDisk id=$id_lun shareable=$lun_shra"
					ok=1
				else
					ok=1
				fi
			else
				ok=0
			fi
		else
			ok=0
		fi
	done
}

collect_info(){
	echo
	echo "Collecting information"
	Collect_new_lun_name
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
		echo "ID: 		$id_lun"
		echo '---------------------------------'
		echo "Do you want to edit it? Y/N"
		read edit
		if [ "$edit" = "y" ] || [ "$edit" = "Y" ]
		then
			collect_info
		fi
	fi
}

#Function to print example of how use the script
print_example(){
	clear
	echo "[Error] The LUN ID parameter is missing."
	echo
	echo "The script should be ran link this:"
	echo "bash edit_LUN_name.sh -l <36XXXXXXXXX>"
	echo
	echo "Example:"
	echo "bash edit_LUN_name.sh -l 3600507680c8183c660000000000006f2"
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