#!/bin/bash

#Script to list all the disks attached to a VM

#Variables

list_vms=$1
target_server=$2

create_tem_dir(){
	mkdir tmp_dir
	echo > tmp_dir/vnets.txt
	ovmcli "list VlanInterface" > tmp_dir/VlanInterface
}

remove_tmp_dir(){
	rm -rf tmp_dir
}

check_information(){
	clear
	echo "|=======================================================|"
	create_tem_dir
	for i in `cat $list_vms`
	do
		exist=0
		echo "| VM Name						|"
		echo "| $i				|"
		echo "|-----------------------|-------------------------------|"
		echo "|	Network		| Target Server $target_server	|"
		ovmcli "show vm name=$i" > tmp_dir/$i.vm_info
		for j in `cat tmp_dir/$i.vm_info|grep Vnic|cut -d '=' -f2|cut -d ' ' -f2`
		do
			ntwk=$(ovmcli "show Vnic id=$j"|grep Network|cut -d '=' -f 2|cut -d '[' -f 2|cut -d ']' -f1)
			ntwk_id=$(ovmcli "show Vnic id=$j"|grep Network|cut -d '=' -f 2|cut -d ' ' -f 2)
			status=$(ovmcli "show network id=$ntwk_id"|wc -l)
			if [ $status -gt 0 ]
			then
				server_status="OK"
			else
				server_status="NO"
			fi
			exist=$(cat tmp_dir/vnets.txt|grep $ntwk_id|wc -l)
			if [ $exist -eq 0 ]
			then
				echo $ntwk_id >> tmp_dir/vnets.txt
			fi
 			echo "|$ntwk	|		$server_status		|"
		done
		echo "|-----------------------|-------------------------------|"
	done
	echo "|=======================================================|" 
}

if [ -z "$list_vms" ]
then
	echo "Please point to the vms file"
else
	if [ -z "$target_server" ]
	then
		echo "Please point the Target Server"
	else

		check_information
		remove_tmp_dir
	fi
fi