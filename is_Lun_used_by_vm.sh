#!/bin/bash

option=$1
LUN=$2

is_lun_used(){
	#Check if a lun is used for a running VM in this server
	lun_id=$1
	used=false
	list_vms=$(grep $lun_id /OVS/Repositories/*/VirtualMachines/*/vm.cfg|cut -d ':' -f 1)
	for i in `echo $list_vms`
	do
		id=$(grep name $i|grep -v OVM_simple_name|cut -d "=" -f2)
		is_running=0
		is_running=$(xm list|grep -i $id|wc -l)
		if [ $is_running -eq 1 ]
		then
			vm_name=$(grep name $i|grep OVM_simple_name|cut -d "=" -f2)
			echo "A VM with that LUN is running in this server: $vm_name"
			used=true
		fi
	done
	if [ $used == 'false' ]
	then
		echo "The LUN $lun_id is not used in this Server."
	fi
}

vms_lun_used(){
	#Check if a lun is assigned to a VM

	echo "Checking a VM have the LUN assigned:"
	list_vms=$(grep $LUN /OVS/Repositories/*/VirtualMachines/*/vm.cfg|cut -d ':' -f 1)
	used=false
	for i in `echo $list_vms`
	do
		vm_name=$(grep name $i|grep OVM_simple_name|cut -d "=" -f2)
		used=true
		echo "Used in $vm_name"
	done
	if [ $used == 'false' ]
	then
		echo "The LUN $LUN is not used in any VM."
	fi
}

verifying_luns(){
	for i in `cat $LUN`
	do
		is_lun_used $i
	done
}

run_script(){
	if [ $option -eq 1 ]
	then
		is_lun_used $LUN
	else
		if [ $option -eq 2 ]
		then
			vms_lun_used
		else
			if [ $option -eq 3 ]
			then
				verifying_luns
			else
				echo "The option is not correct, check how to run this script"
			fi
			
		fi
	fi
}

if [ -z "$option" ]
then
	clear
	echo "[Error] Insert the option between:"
	echo "1- To check if the LUN is used by any running VM in the Server."
	echo "2- List the VMs using this LUN"
	echo
	echo "Example:"
	echo "bash lun_script.sh 1 3600507680c8083b9280000000000060d"
	echo
else
	if [ -z "$LUN" ]
	then
		clear
		echo "[Error] Insert the input file path"
		echo
		echo "Example:"
		echo "bash check_paths_mhas.sh CHXXXXXXXXX hostp1.csv"
		echo
	else
		run_script
	fi
fi