#!/bin/bash

lun_name=$1

get_name(){
	file=$(ls -l /u01/app/oracle/mysql/dbbackup/OVMModelExport*|awk '{print $9}'|tail -n 1)
	lun_exist=""
	lun_exist=$(grep -i $lun_name $file|grep Page83Id)
	echo $lun_exist
	if [ -z "$lun_exist" ]
	then
		clear
		echo "[Error] The LUN $lun_name does not exist in the manager DB"
	else
		lun_name=$(grep $lun_name $file -B 14 |grep Page83Id -B 14|grep Name|egrep -v 'DeviceNames|DisplayName|Unmanaged'|cut -d '>' -f2|cut -d '<' -f1)
		clear
		echo '---------------------------------'
		echo "Friendly name:"
		echo "$lun_name"
		echo '---------------------------------'
	fi
}

if [ -z "$lun_name" ]
then
	clear
	echo "[Error] Insert the Lun ID."
	echo
	echo "Example:"
	echo "bash get_LUN_name.sh 36XXXXXXXXX"
	echo
else
	get_name
fi
