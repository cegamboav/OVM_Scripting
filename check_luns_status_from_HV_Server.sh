#!/bin/bash

#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : This script is to list all the LUNs attached to a running VM from the HV perspective.
###############################################################
## 30 Jun, 2021 : Created 
##
##
################################################################
##
##Version 1.0
##

line=0

##Empty lines
add_empty_line(){
		echo "|							|" 
}

##Lines with ====
add_line(){
	echo '|=======================================================|' 
}

##Lines with ---
add_simple_line(){
	echo '|-------------------------------------------------------|' 
}


## 1 Value:
add_one_value_line(){
	printf "%-1s %-36s %-16s %-1s\n" "|" $1 $2 "|" 
}

add_head_line(){
	printf "%-1s %-3s %-49s %-1s\n" "|" $1 $2 "|"
}


extract_information(){
	
	phy=0
	vm_file=$1/vm.cfg
	VM_name=$(grep OVM_simple_name $vm_file|cut -d "'" -f2|cut -d "'" -f1)
	disks=$(grep disk $vm_file)
	phy=$(echo $disks|grep phy|wc -l)
	if [ $phy -gt 0 ]
	then
		if [ $line -eq 0 ]
		then
			line=1
		else
			add_simple_line
		fi
		add_head_line "VM:" $VM_name
		add_empty_line
		add_one_value_line "LUN" "Paths"
		info=$(echo $disks|cut -d '[' -f2-|cut -d ']' -f 1)
		devices=$info
		i=0
		while [ $i -eq 0 ]
		do
			more_info=$(echo $devices|grep ','|wc -l)
			if [ $more_info -gt 0 ]
			then
				device=$(echo $devices|cut -d "'" -f 2)
				phy=$(echo $device|grep phy|wc -l)
				if [ $phy -gt 0 ]
				then
					path=$(echo $device|cut -d ':' -f2-|cut -d ',' -f1|cut -d '/' -f4)
					#count all the luns with "active ready running" Paths only!
					lun_status=$(multipath -ll $path |egrep 'active ready running'|wc -l)
					add_one_value_line $path $lun_status
				fi
				temp=$(echo $devices|cut -d "'" -f3-)
				devices=$temp
			else
				i=1
			fi
		done
	else
		echo "|VM: $VM_name, Do not Have Physical Disks.!! 	|"
		add_simple_line
	fi
}

run (){
	for i in $(xm li|awk '{print $1}'|egrep -v 'Name|Domain')
	do
		multipathd show maps status > /tmp/mpstatus
		a=$(find /OVS/ -name $i)
		extract_information $a
		rm -f /tmp/mpstatus
	done
}

clear
add_line
run
add_line