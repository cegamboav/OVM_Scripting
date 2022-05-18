#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : This script used to List all the virtual and Physical disks attached to a VM from the manager perspective
###############################################################
## 14 May, 2021 : Created 
##
##
################################################################
##
#

#Vm name provided
vm_name_provided=$1
#Array to store the VM device name
vm_devices=()
int_mappings=()
maps_devices=()

#to get the VM name
vm_name=$(ovmcli "list vm"|grep -i $1|awk -F 'name:' '{print $2}')
#To obtain the list of mappins of the VM
mappings=$(ovmcli "show vm name=$vm_name"|grep VmDiskMapping|cut -d '[' -f2 |cut -d ']' -f1)
internal_mappings=$(ovmcli "show vm name=$vm_name"|grep VmDiskMapping|cut -d '=' -f2|awk '{print $1}')
#To know the server where the vm is running
running_server=$(ovmcli "show vm name=$vm_name"|egrep 'Server ='|cut -d '[' -f2|cut -d ']' -f1)
#to storage the list of devices from the vm.cfg file
disks=$(ovmcli "getVmCfgFileContent vm name=$vm_name"|grep disk)
#device to have the file to be imported
output_file=$vm_name_provided.disks_devices.csv
#To store the VM ID
VM_ID=$(ovmcli "show vm name=$vm_name"|egrep 'Id ='|cut -d '=' -f2 |awk '{print $1}')

#function to fill the internal mappings
fill_internal_mappings(){
	for i in `echo $internal_mappings`
	do	
		int_mappings+=("$i")
	done
}

##This function is to fill the maps_devices array
fix_map_devices(){
	for i in `echo $mappings`
	do
		if [ ! $i == "Mapping" ] && [ ! $i == "for" ] && [ ! $i == "disk" ] && [ ! $i == "Id" ]
		then
			entry=$(echo $i|grep '(' |wc -l)
			if [ $entry -gt 0 ]
			then
				entry_=$(echo $i|cut -d '(' -f2|cut -d ')' -f1)
			else
				entry_=$i
			fi
			maps_devices+=("$entry_")
		fi
	done
}

#Function to add a line into the head
add_info_to_head(){
	printf "%-1s %-15s %-15s %-1s %-7s %-32s %-1s %-20s %-28s %-1s\n" "|" $1 $2 "|" $3 $4 "|" $5 $6 "|"
}


#Function to print the head of the table
head_of_file(){
	clear
	echo "|--------------------------------------------------------------------------------------------------------------------------------|"
	add_info_to_head "VM_Name:" $vm_name "VM_ID:" $VM_ID "Server_Runing:" $running_server
	echo "VM_Name:,$vm_name,VM_ID:,$VM_ID,Server_Runing:,$running_server" > $output_file
	echo "|--------------------------------------------------------------------------------------------------------------------------------|"
	echo "|--------------------------------------------------------------------------------------------------------------------------------|"
	echo "| Device				| Slot  | Size	 | Share | VMdevice | Device Name					 |"
	echo "Device,Slot,Size,Share,VMdevice,Device Name" >> $output_file
	echo "|--------------------------------------------------------------------------------------------------------------------------------|"
}

#Function to add a line into the table
add_info_to_file(){
	printf "%-1s %-37s %-1s %-5s %-1s %-6s %-1s %-5s %-1s %-8s %-1s %-50s %-1s\n" "|" $1 "|" $2 "|" $3 "|" $4 "|" $5 "|" $6 "|"
	echo "$1,$2,$3,$4,$5,$6" >> $output_file
}

#Function to print the foot of the table
foot_of_file(){
	echo "|--------------------------------------------------------------------------------------------------------------------------------|"
	echo
	echo "Please check file: $output_file, to be imported in Excel!!!"
	echo
}

run_script(){
	#we call the function to fill the internal mappings
	fill_internal_mappings

	#Then we obtain the VM device names:
	info=$(echo $disks|cut -d '[' -f2-|cut -d ']' -f 1)
	devices=$info
	i=0
	j=0
	while [ $i -eq 0 ]
	do
		more_info=$(echo $devices|grep ','|wc -l)
		if [ $more_info -gt 0 ]
		then
			vmdevice=$(echo $devices|cut -d ':' -f2-|cut -d ',' -f2)
			vm_devices+=("$vmdevice")
			((j++))
			temp=$(echo $devices|cut -d "," -f4-)
			devices=$temp
		else
			i=1
		fi
	done

	fix_map_devices
	#Then we start to collect data and show it in the screen
	head_of_file
	h=0
	for i in "${!maps_devices[@]}"
	do
		vdisk=$(echo $i|egrep '.img' |wc -l)
		if [ $vdisk -eq 1 ]
		then
			vdiks_size=$(ovmcli "show virtualdisk id=${maps_devices[$i]}"|egrep 'Max '|cut -d '=' -f2)
			vdiks_sherable=$(ovmcli "show virtualdisk id=${maps_devices[$i]}"|egrep 'Shareable '|cut -d '=' -f2)
			vdiks_name=$(ovmcli "show virtualdisk id=${maps_devices[$i]}"|egrep 'Name '|cut -d '=' -f2)
			s_lot="${int_mappings[$h]}"
			vdiks_slot=$(ovmcli "show vmdiskMapping id=$s_lot"|egrep 'Slot '|cut -d '=' -f2)
			add_info_to_file $i $vdiks_slot $vdiks_size $vdiks_sherable "${vm_devices[$h]}" $vdiks_name
			
		else
			pdiks_size=$(ovmcli "show physicalDisk id=${maps_devices[$i]}"|egrep 'Size '|cut -d '=' -f2)
			pdiks_id=$(ovmcli "show physicalDisk id=${maps_devices[$i]}"|egrep 'Page83 ID'|cut -d '=' -f2)
			pdiks_sherable=$(ovmcli "show physicalDisk id=${maps_devices[$i]}"|egrep 'Shareable '|cut -d '=' -f2)
			s_lot="${int_mappings[$h]}"
			pdiks_slot=$(ovmcli "show vmdiskMapping id=$s_lot"|egrep 'Slot '|cut -d '=' -f2)
			pdisk_name=$(ovmcli "show physicalDisk id=${maps_devices[$i]}"|egrep 'Name ='|egrep -v 'Device|User-Friendly'|cut -d '=' -f2)
			add_info_to_file $pdiks_id $pdiks_slot $pdiks_size $pdiks_sherable "${vm_devices[$h]}" $pdisk_name
		fi
		((h++))
	done
	foot_of_file
}

#Function to print example of how use the script
print_example(){
	echo "[Error] Some parameters are missing."
	echo
	echo "The script should be ran link this:"
	echo "bash list_disks_from_vm.sh <name_of_the_vm>"
	echo
	echo "Example:"
	echo "bash list_disks_from_vm.sh a0680o3odbsp490"
	echo
}

if [ -z "$vm_name_provided" ]
then
	clear
	print_example
else
	run_script
fi