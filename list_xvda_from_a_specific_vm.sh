#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : This script list xvda of an specific VM
###############################################################
## 03 May, 2022 : Created 
##
##
################################################################
##
#

show_help=0
real_id=''

#function to check if the VM exist:
test_if_VM_exist(){
	vm_exist=0
	vm_exist=$(ovmcli "list vm"|grep -i $vm_name|wc -l)
	if [ $vm_exist == "1" ]
	then
		return 1
	else
		return 0
	fi
}

#Set the real name of the VM:
Set_real_VM_Id(){
	consult_name=$1
	real_id=$(ovmcli "list vm"|grep -i $consult_name|tr -s " " |cut -d " " -f 2|cut -d ":" -f 2)
}

#Function to print example of how use the script
print_example(){
	echo "[Error] Some parameters are missing."
	echo
	echo "The script should be ran link this:"
	echo "bash list_xvda_from_a_specific_vm.sh -v <name_of_the_vm>"
	echo
	echo "Example:"
	echo "bash list_xvda_from_a_specific_vm.sh -v a0680o3odbsp490"
	echo "bash list_xvda_from_a_specific_vm.sh -a all"
	echo
}

print_double_line(){
	echo "|===========================================================================================================================|"
}

print_simple_line(){
	echo "|----------------------|----------------------------------|-----------------|-------------------------------------|---------|"
}

print_head(){
	print_double_line
	printf "%-1s %-20s %-1s %-32s %-1s %-15s %-1s %-35s %-1s %-7s %-1s\n" "|" "VM_Name" "|" "VM_ID" "|" "HV_Name" "|" "Root_disk_Name" "|" "Size" "|"
	print_simple_line
}

print_line(){
	printf "%-1s %-20.20s %-1s %-32s %-1s %-15s %-1s %-35.35s %-1s %-7s %-1s\n" "|" $1 "|" $2 "|" $3 "|" $4 "|" $5 "|"
}

print_vm_information(){
	internal_vm_id=$1
	ovmcli "show vm id=$internal_vm_id" > vm_profile.txt
	internal_vm_name=$(grep Name vm_profile.txt|tr -s " " |cut -d " " -f 4)
	vm_status=$(cat vm_profile.txt|egrep 'Status ='|tr -s " " |cut -d " " -f 4)
	if [ $vm_status == 'Running' ]
	then
		Running_Server=$(egrep 'Server =' vm_profile.txt|cut -d "[" -f 2|cut -d "]" -f 1)
	else
		Running_Server="VM_Not_Running"
	fi
	
	for i in $(grep VmDiskMapping vm_profile.txt |tr -s " " |cut -d " " -f 5)
		do ovmcli "show VmDiskMapping id=$i"> vdisk_information.txt
		slot=$(grep Slot vdisk_information.txt|tr -s " " |cut -d " " -f 4)
		if [ $slot == '0' ]
		then
			vd='0'
			vd=$(egrep 'Virtual Disk' vdisk_information.txt|wc -l)
			if [ $vd == '0' ]
			then
				ph_disk_id=$(grep Physical vdisk_information.txt|tr -s " " |cut -d " " -f 5)
				vdisk_size=$(ovmcli "show physicalDisk id=$ph_disk_id"|grep Size|tr -s " " |cut -d " " -f 5)
				vdisk_name_no_spaces=$(ovmcli "show physicalDisk id=$ph_disk_id"|grep Page83|tr -s " " |cut -d " " -f 5)
			else
				vdisk_name=$(egrep 'Virtual Disk' vdisk_information.txt|tr -s " " |cut -d " " -f 5)
				vdisk_name_no_spaces=$(egrep 'Virtual Disk' vdisk_information.txt|cut -d "[" -f 2|cut -d "]" -f 1|sed 's/ /_/g')
				vdisk_img=
				ovmcli "show virtualdisk name=$vdisk_name" > virtualdisk.txt
				vdisk_size=$(egrep 'Max' virtualdisk.txt|tr -s " " |cut -d " " -f 5)
			fi
			print_line $internal_vm_name $internal_vm_id $Running_Server $vdisk_name_no_spaces $vdisk_size
			break
		fi
	done
}

#function to show all the VMs in the Manager
list_all_the_vms(){
	clear
	print_head
	for i in $(ovmcli "list vm"|grep name|tr -s " " |cut -d " " -f 2|cut -d ':' -f2)
	do
		print_vm_information $i
		#echo $i
	done
	print_double_line
}

#Function to show just a single VM in the Manager
individual_vm(){
	continue_program=0
	test_if_VM_exist
	continue_program=$(echo $?)
	if [ $continue_program -eq 1 ]
	then
		Set_real_VM_Id $vm_name
		clear
		print_head
		print_vm_information $real_id
		print_double_line
	else
		clear
		echo "[Error]		VM name: $vm_name does not exist in this manager."
	fi
}



while getopts "v:a:h:" option; do
	case $option in
		v) vm_name=$OPTARG;;
		a) all_vms=1;;
		h) show_help=1;;
		?) echo "I do not recognize: $OPTARG as a valid argument";;
	esac
done

if [ $show_help -eq 1 ]
then
	print_example
fi

if [ -z "$vm_name" ]
then
	if [ -z "$all_vms" ]
	then
		clear
		print_example
	else
		list_all_the_vms
	fi
else
	individual_vm
fi