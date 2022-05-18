#!/bin/bash

#Script to list all the disks attached to a VM from vm.cfg file

#Variables

vm_file=$1

extract_information(){
	disks=$(grep disk $vm_file)
	info=$(echo $disks|cut -d '[' -f2-|cut -d ']' -f 1)
	devices=$info
	i=0
	j=0
	echo "| Slot  | Device					| VM Device	| Sherable	|"
	echo "|=======|===============================================|===============|===============|"
	while [ $i -eq 0 ]
	do
		more_info=$(echo $devices|grep ','|wc -l)
		if [ $more_info -gt 0 ]
		then
			device=$(echo $devices|cut -d "'" -f 2)
			path=$(echo $device|cut -d ':' -f2-|cut -d ',' -f1)
			vm_device=$(echo $device|cut -d ':' -f2-|cut -d ',' -f2)
			shrbl=$(echo $device|cut -d ':' -f2-|cut -d ',' -f3)
			if [ $shrbl == 'w!' ]
			then 
				is_sharable="Yes"
			else
				is_sharable="No"
			fi
			echo "| $j	| $path	|	$vm_device	| $is_sharable		|"
			((j++))
			temp=$(echo $devices|cut -d "'" -f3-)
			devices=$temp
		else
			i=1
		fi
	done
	echo "|=======|===============================================|===============|===============|"
}



if [ -z "$vm_file" ]
then
	clear
	echo "[Error] Insert the vm.cfg file Path."
	echo
	echo "Example:"
	echo "bash list_disks_from_vm_cfg_file.sh /tmp/vm.cfg"
	echo
else
	extract_information
fi
