#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@kyndryl.com>
# Purpose : This script is to capture important data of a HV Server
###############################################################
## 30 Jun, 2021 : Created 
##
##
################################################################
##
##Version 1.2
##
#Variables:
#To display total memory information:
mem_info=0

#to display total CPU information:
cpu_info=0

#to display ovm information
ovm_info=0

#to display network information
network_info=1

#File to save the collected data.
log_file=/tmp/$HOSTNAME.data.txt

mem_dimm_slots=()

##Empty lines
add_empty_line(){
		echo "|																|" | tee -a /tmp/$HOSTNAME.data.txt
}

##Lines with ====
add_line(){
	echo '|===============================================================================================================================|' | tee -a /tmp/$HOSTNAME.data.txt
}

##Lines with ---
add_simple_line(){
	echo '|-------------------------------------------------------------------------------------------------------------------------------|' | tee -a /tmp/$HOSTNAME.data.txt
}

##0 Values:
add_zero_value_line(){
	printf "%-1s %-125s %-1s\n" "|" $1 "|" | tee -a /tmp/$HOSTNAME.data.txt
}


## 1 Value:
add_one_value_line(){
	printf "%-1s %-34s %-90s %-1s\n" "|" $1 $2 "|" | tee -a /tmp/$HOSTNAME.data.txt
}

add_one_value_3_line(){
	printf "%-1s %-30s %-5s %-88s %-1s\n" "|" $1 $2 $3 "|" | tee -a /tmp/$HOSTNAME.data.txt
}


## 2 Values:
add_two_values_line(){
	printf "%-1s %-20s %-40s  %-20s %-41s %-1s\n" "|" $1 $2 $3 $4 "|" | tee -a /tmp/$HOSTNAME.data.txt
}

add_two_values_5_line(){
	printf "%-1s %-20s %-4s %-36s %-20s %-41s %-1s\n" "|" $1 $2 $3 $4 $5 "|" | tee -a /tmp/$HOSTNAME.data.txt
}

## 3 Values:
add_three_values_line(){
	printf "%-1s %-15s %-25s %-15s %-25s %-15s %-25s %-1s\n" "|" $1 $2 $3 $4 $5 $6 "|" | tee -a /tmp/$HOSTNAME.data.txt
}

add_three_values_7_line(){
	printf "%-1s %-15s %-5s %-19s %-15s %-25s %-15s %-25s %-1s\n" "|" $1 $2 $3 $4 $5 $6 $7 "|" | tee -a /tmp/$HOSTNAME.data.txt
}

##4 Values:

add_four_values_line(){
	printf "%-1s %-5s %-20s %-5s %-30s %-5s %-23s %-5s %-25s %-1s\n" "|" $1 $2 $3 $4 $5 $6 $7 $8 "|" | tee -a /tmp/$HOSTNAME.data.txt
}

##Special lines:
add_title_line(){
	printf "%-1s %-6s %-118s %-1s\n" "|" $1 $2 "|" | tee -a /tmp/$HOSTNAME.data.txt
}

add_memory_line(){
	printf "%-1s %-5s %-13s %-5s %-3s %-14s %-5s %-23s %-14s %-35s %-1s\n" "|" $1 $2 $3 $4 $5 $6 $7 $8 $9 "|" | tee -a /tmp/$HOSTNAME.data.txt
}

add_bridge_lines(){
	printf "%-1s %-7s %-20s %-5s %-36s %-10s %-15s %-5s %-20s %-1s\n" "|" $1 $2 $3 $4 $5 $6 $7 $8 "|" | tee -a /tmp/$HOSTNAME.data.txt
}

add_VMs_lines(){
	printf "%-1s %-33s %-58s %-10s %-10s %-10s %-1s\n" "|" $1 $2 $3 $4 $5 $6 $7 $8 "|" | tee -a /tmp/$HOSTNAME.data.txt
}


###Function to collect the server information:
collect_server_name_details(){
	#Collect the data:
	machine_type=$(dmidecode -t system|grep SKU|cut -d ':' -f 2|sed 's/ /_/g')
	server_name=$(uname -n)
	server_kernel=$(uname -r)
	date_=$(date|sed 's/ /_/g')
	uptime_=$(uptime|sed 's/ /_/g')
	console_ip=$(ipmitool lan print 1 | egrep 'IP Address'|grep -v Source|cut -d ':' -f 2)
	serial_number=$(dmidecode -t system|egrep 'Serial Number'|cut -d ':' -f 2)
	manufactured=$(dmidecode -t system|grep Manufacturer|awk '{print $2}')
	micro=$(rpm -qa |grep -i micro)
	
	#Create empty file to store all the infromation
	echo > /tmp/$HOSTNAME.data.txt
	echo "Collecting Data ..."
	
	#Now show the collected information:
	add_line
	add_title_line "Server" "Information:"
	add_two_values_line "Server_Name:" $server_name "Server_Kernel:" $server_kernel
	add_two_values_line "Machine_Type:" $machine_type "Serial_Number:" $serial_number "Console_IP:" $console_ip
	add_two_values_line "Manufactured:" $manufactured "Console_IP:" $console_ip 
	add_one_value_line "Micro_code:" $micro
	add_empty_line
	add_one_value_line "Date_and_Time:" $date_
	add_one_value_line "Uptime:" $uptime_
	add_line
}

###Function to show more memory information:
display_total_memory_information(){
	#Collect the data:
	dmidecode -t memory|egrep 'Manufacturer|Locator'|grep -v Bank|egrep -v 'NO DIMM'|grep Manufacturer -A 1|egrep 'Manufacturer|Locator'>/tmp/meminfo.txt
	for h in $(cat /tmp/meminfo.txt|grep Locator|cut -d ':' -f2-|sed 's/ /_/g')
	do
		mem_dimm_slots+=("$h")
	done
	
	#Now show the collected information:
	add_two_values_line "Total_DIMM_Slots:" $num_devices "Installed_Devices:" $num_installed_devices
	add_empty_line
	add_title_line "DIMM" "Information:"
	add_empty_line
	j=0
	for i in $(cat /tmp/meminfo.txt|grep Manufacturer|awk '{print $2}')
	do
		add_memory_line "Dimm:" ${mem_dimm_slots[$j]} "Size:" $1 "GB" "Type:" $2 "Manufacturer:" $i
		((j++))
	done
	add_empty_line
	add_title_line "Swap" "Information:"
	add_zero_value_line "Devices:"
	for i in $(swapon -s|grep -v Filename|awk '{print $1}')
	do
		devsize=$(lsblk $i|grep -v NAME|awk '{print $4}')
		add_two_values_line "Partition:" $i "Size:" $devsize
	done
	#remove temporary file:
	rm -f /tmp/meminfo.txt
}

###Collect and display memory information
Collecting_memory_information(){
	#Collect the data:
	dom0_mem=$(free -h|grep Mem|awk '{print $2}')
	dom0_swap=$(free -h|grep Swap|awk '{print $2}')
	tot_mem_meg=$(xm info|grep total_memory|awk '{print $3}')
	tot_mem_g=$(( $tot_mem_meg/1024 ))
	nod=$(dmidecode -t memory|egrep 'Number Of Devices:'|awk '{print $4}'|wc -l)
	if [ $nod -eq 1 ]
	then
		num_devices=$(dmidecode -t memory|egrep 'Number Of Devices:'|awk '{print $4}')
	else
		a=$(dmidecode -t memory|egrep 'Number Of Devices:'|awk '{print $4}'|uniq)
		num_devices=$(( $a*$nod ))
	fi
	
	num_installed_devices=$(dmidecode -t memory|egrep 'Size'|egrep -v "No Module Installed"|wc -l)
	mem_dimm_size=$(dmidecode -t memory|egrep 'Size'|egrep -v "No Module Installed"|uniq|awk '{print $2}')
	mem_dimm_type=$(dmidecode -t memory|egrep 'Type'|egrep -v "Synchronous|Unknown|Error"|uniq|awk '{print $2}')
	
	#Now show the collected information:
	add_title_line "Memory" "Information:"
	add_empty_line
	add_two_values_line "Dom0_Memory:" $dom0_mem "Dom0_Swap:" $dom0_swap
	add_empty_line
	add_one_value_3_line "Server_Memory:" $tot_mem_g "GB"
	
	#If the memory flag is set.
	if [ $mem_info -eq 1 ]
	then
		display_total_memory_information $mem_dimm_size $mem_dimm_type
	fi
	add_line
}

###Function to show more CPU information:
display_total_cpu_information(){
	#Collect the data:
	nr_nodes=$(xm info|grep nr_nodes|awk '{print $3}')
	cores_per_socket=$(xm info|grep cores_per_socket|awk '{print $3}')
	threads_per_core=$(xm info|grep threads_per_core|awk '{print $3}')
	cpu_mhz=$(xm info|grep cpu_mhz|awk '{print $3}')
	cpu_manu=$(dmidecode -t processor|grep Manufacturer|uniq|awk '{print $2}')
	cpu_sig=$(dmidecode -t processor|grep Signature|uniq|cut -d ':' -f2-)
	family=$(dmidecode -t processor|grep Family|grep -v Signature|awk '{print $2}'|uniq)
	
	#Now show the collected information:
	add_empty_line
	add_three_values_line "Physical_CPUs:" $nr_nodes "Cores_per_CPU:" $cores_per_socket "Threads:" $threads_per_core
	add_three_values_7_line "CPU_Speed:" $cpu_mhz "MHz" "Family:" $family "Manufactured:" $cpu_manu
	echo "| Signature: 	$cpu_sig										|"| tee -a /tmp/$HOSTNAME.data.txt
}

###Collect and display CPU information:
collect_CPU_information(){
	dom0_cpu_status=0
	#get the total of CPUs
	cpu_qty=$(xm info|grep nr_cpus|awk '{print $3}')
	#get the dom0 total of CPUs
	for i in $(xm info|grep xen_commandline|cut -d ':' -f2-)
	do
		a=$(echo $i|grep dom0_max_vcpus|wc -l)
		if [ $a -eq 1 ]
		then
			dom0_cpus=$(echo $i|cut -d '=' -f2)
		fi
	done
	#Validate if the total of CPUs of dom0 is correct
	if [ $cpu_qty -lt 56 ]
	then
		if [ $dom0_cpus -eq 4 ]
		then
			dom0_cpu_status=1
		else
			dom0_cpu_configured=4
		fi
	else
		if [ $cpu_qty -eq 56 ]
		then
			if [ $dom0_cpus -eq 6 ]
			then
				dom0_cpu_status=1
			else
				dom0_cpu_configured=6
			fi
		else
			if [ $cpu_qty -lt 100 ]
			then
				if [ $dom0_cpus -eq 8 ]
				then
					dom0_cpu_status=1
				else
					dom0_cpu_configured=8
				fi
			else
				if [ $dom0_cpus -eq 16 ]
				then
					dom0_cpu_status=1
				else
					dom0_cpu_configured=16
				fi
			fi
		fi
	fi
	#Sowing the collected information:
	add_title_line "CPU" "Information:"
	add_empty_line
	if [ $dom0_cpu_status -eq 1 ]
	then
		add_two_values_5_line "Dom0_CPUs:" $dom0_cpus "[OK]" "Server_CPUs:" $cpu_qty
	else
		add_two_values_5_line "Dom0_CPUs:" $dom0_cpus "($dom0_cpu_configured)" "Server_CPUs:" $cpu_qty
	fi
	##If the CPU flag is set.
	if [ $cpu_info -eq 1 ]
	then
		display_total_cpu_information
	fi
	add_line
}

###Function to show the OVM information:
display_total_ovm_information(){
	crash=0
	oswatcher=0
	gnttab=0
	gnttab_max=0
	#collect the information
	xen_version=$(rpm -qa|grep xen-|egrep -v 'libvirt|tools')
	xen_tools_version=$(rpm -qa|grep xen-|egrep 'tools')
	oswatcher=$(service oswatcher status|grep running|wc -l)
	for i in $(xm info|grep xen_commandline|cut -d ':' -f2-)
	do
		a=$(echo $i|grep gnttab_max_maptrack_frames|wc -l)
		if [ $a -eq 1 ]
		then
			gnttab=$(echo $i|cut -d '=' -f2)
		fi
		a=$(echo $i|grep gnttab_max_frames|wc -l)
		if [ $a -eq 1 ]
		then
			gnttab_max=$(echo $i|cut -d '=' -f2)
		fi
		a=$(echo $i|grep crashkernel|wc -l)
		if [ $a -eq 1 ]
		then
			crash=1
		fi
	done
	
	#Show the collected data:
	add_empty_line
	add_two_values_line "Xen_Version:" $xen_version	"Xen_Tools:" $xen_tools_version
	if [ $oswatcher -eq 1 ]
	then
		if [ $crash -eq 1 ]
		then
			add_two_values_line "OSWatcher_Running:" "OK" "Crash_configured:" "OK"
		else
			add_two_values_line "OSWatcher_Running:" "OK" "Crash_configured:" "NO"
		fi
	else
		if [ $crash -eq 1 ]
		then
			add_two_values_line "OSWatcher_Running:" "NO" "Crash_configured:" "OK"
		else
			add_two_values_line "OSWatcher_Running:" "NO" "Crash_configured:" "NO"
		fi
	fi
	add_two_values_line "maptrack_frames:" $gnttab "gnttab_max_frames:" $gnttab_max
	add_empty_line
	
	#Now we show the Running VMs:
	running_vms=$(xm li|egrep -v 'Name|Domain-0'|wc -l)
	
	#If the server have Running VMs:
	if [ $running_vms -gt 0 ]
	then
		add_one_value_line "Running_VMs:" $running_vms
		add_VMs_lines "VM_ID" "VM_Name" "Memory" "CPUs"	"CPU_PIN"
		for i in $(xm li|egrep -v 'Name|Domain-0'|awk '{print $1}')
		do
			#Collect the VMs information
			vm_mem=$(xm li $i|egrep -v Name|awk '{print $3}')
			vm_cpu=$(xm li $i|egrep -v Name|awk '{print $4}')
			vm_cpu_pin=$(xm vcpu-list $i|grep -v CPU|awk '{print $7}'|uniq)
			vm_path=$(find /OVS/ -name $i|grep -v snapshot)
			vm_name=$(grep OVM_simple_name $vm_path/vm.cfg|cut -d "'" -f2)
			
			#show the line
			add_VMs_lines $i $vm_name $vm_mem $vm_cpu $vm_cpu_pin
		done
		
		#now we Show the uptimes:
		add_empty_line
		add_one_value_line "VM_ID" "Uptime:"
		for i in $(xm li|egrep -v 'Name|Domain-0'|awk '{print $1}')
		do
			vm_uptime=$(xm uptime|grep -v Domain|grep -v Name|sed 's/  */ /g'|cut -d ' ' -f3-|sed 's/ /_/g')
			add_one_value_line $i $vm_uptime
		done
	#If don't have just show message:
	else
		echo "|No running VMs in this Server.													|"| tee -a /tmp/$HOSTNAME.data.txt
	fi
}

#Collect and display OVM information
collect_OVM_information(){
	#collect the information
	ovm_ver=$(cat /etc/ovs-release)
	clustered=$(ovs-agent-db dump_db server|grep cluster_state|cut -d ':' -f2-|cut -d "'" -f 2)
	pool_alias=$(ovs-agent-db dump_db server|grep pool_alias|cut -d ':' -f2-|cut -d "'" -f 2)
	registered_ip=$(ovs-agent-db dump_db server|grep registered_ip|cut -d ':' -f2-|cut -d "'" -f 2)
	is_master=$(ovs-agent-db dump_db server|grep is_master|cut -d ':' -f2-|cut -d "'" -f 2)
	manager_ip=$(ovs-agent-db dump_db server|grep manager_ip|cut -d ':' -f2-|cut -d "'" -f 2)
	for j in $(cat /etc/default/grub|grep GRUB_CMDLINE_LINUX)
	do
		is_swiotble=$(echo $j|grep swiotlb|wc -l)
		if [ $is_swiotble -eq 1 ]
		then
			swiotlb=$(echo $j|cut -d '=' -f 2)
		else
			swiotlb=0
		fi
	done
	
	#Sowing the collected information:
	add_title_line "OVM" "Information:"
	add_empty_line
	echo "| OVM Version: 		$ovm_ver										|"
	add_two_values_line "Clustered:" $clustered "Cluster_name:" $pool_alias
	add_two_values_line "Master:" $is_master "swiotlb:" $swiotlb
	add_two_values_line "Server_IP:" $registered_ip "Manager_IP:" $manager_ip
	
	##If the OVM flag is set.
	if [ $ovm_info -eq 1 ]
	then
		display_total_ovm_information
	fi
	add_line
}

#Function to show the ip address of the bonds:
show_bond_ips(){
	#collect the information:
	bond_device=$1
	have_vlans=$(ifconfig |grep $bond_device|awk '{print $1}'|egrep '\.'|wc -l)
	if [ $have_vlans -gt 0 ]
	then
		#Now show the information:
		add_zero_value_line "Vlans:"
		for i in $(ifconfig |grep $bond_device|awk '{print $1}'|egrep '\.')
		do
			echo $i >> /tmp/nics.txt
			have_ip=$(ifconfig $i|grep inet|wc -l)
			if [ $have_ip -eq 1 ]
			then
				nic_ip=$(ifconfig $i|grep inet|awk '{print $2}'|cut -d ":" -f2)
				add_two_values_line "Vlan:" $i "IP_address:" $nic_ip
			else
				add_two_values_line "Vlan:" $i "IP_address:" "No_IP"
			fi
		done
	fi
}

#Function to show the information of the bridges:
show_bridges(){
	have_bridges=$(brctl show|grep -v bridge|wc -l)
	if [ $have_bridges -gt 0 ]
	then
		add_simple_line
		add_title_line "Bridge" "Devices:"
		add_empty_line
		for i in $(brctl show|grep -v bridge|awk '{print $4}')
		do
			bridge=$(cat /etc/sysconfig/network-scripts/meta-$i|grep METADATA|cut -d ":" -f2-|cut -d '{' -f1)
			bridge_name=$(cat /etc/sysconfig/network-scripts/meta-$i|grep METADATA|cut -d "{" -f2-|cut -d '}' -f1)
			job=$(cat /etc/sysconfig/network-scripts/meta-$i|grep METADATA|cut -d ":" -f3-)
			echo $bridge >> /tmp/nics.txt
			add_bridge_lines "Bridge:" $bridge "Name:" $bridge_name "Interface:" $i "Job:" $job
		done
	fi
}

###Function to show the route table:
show_route(){
	route -n > /tmp/route_n.txt
	have_routes=$(cat /tmp/route_n.txt|egrep -v 'Destination|Kernel'|wc -l)
	if [ $have_routes -gt 0 ]
	then
		r_name=()
		r_gateway=()
		r_mask=()
		r_iface=()
		add_simple_line
		add_title_line "Route" "Table:"
		add_empty_line
		for i in $(cat /tmp/route_n.txt|egrep -v 'Destination|Kernel'|awk '{print $1}')
		do
			r_name+=("$i")
		done
		for i in $(cat /tmp/route_n.txt|egrep -v 'Destination|Kernel'|awk '{print $2}')
		do
			r_gateway+=("$i")
		done
		for i in $(cat /tmp/route_n.txt|egrep -v 'Destination|Kernel'|awk '{print $3}')
		do
			r_mask+=("$i")
		done
		for i in $(cat /tmp/route_n.txt|egrep -v 'Destination|Kernel'|awk '{print $8}')
		do
			r_iface+=("$i")
		done
		add_two_values_line "Destination" "Gateway" "Genmask" "Iface"
		j=0
		for i in "${!r_name[@]}"
		do
			add_two_values_line ${r_name[$i]} ${r_gateway[$j]} ${r_mask[$j]} ${r_iface[$j]}
			((j++))
		done
	fi
	rm -f /tmp/route_n.txt
}

###Function to check the MTU of a NIC
search_mtu(){
	nic=$1
	for h in $(ifconfig -a $nic|grep MTU)
	do
		exist=$(echo $h|grep MTU|wc -l)
		if [ $exist -eq 1 ]
		then
			mtu=$(echo $h|cut -d ':' -f 2)
		fi
	done
}

###Function to show the additional NICs in the server:
show_aditional_nics(){
	#Collect Information
	add_simple_line
	add_title_line "Nics" "additional:"
	add_empty_line
	
	#Show the collected information:
	for i in $(ifconfig -a|grep Ethernet|awk '{print $1}')
	do
		list_nic=$(grep $i /tmp/nics.txt|wc -l)
		if [ $list_nic -eq 0 ]
		then
			mac=$(ifconfig -a $i|grep Ethernet|awk '{print $5}')
			have_ip=$(ifconfig -a $i|grep inet|wc -l)
			if [ $have_ip -eq 1 ]
			then
				nic_ip=$(ifconfig -a $i|grep inet|awk '{print $2}'|cut -d ':' -f 2)
			elif [ $have_ip -gt 1 ]
			then
				nic_ip="More_than_1_IP"
			else
				nic_ip="No_IP"
			fi
			search_mtu $i
			add_four_values_line "NIC:" $i "MAC:" $mac "IP:" $nic_ip "MTU:" $mtu
		fi
	done
}

###Function to show the NIC information:
collect_network_information(){
	add_title_line "Net" "Information"
	add_empty_line
	
	echo > /tmp/nics.txt
	have_bond_devices=$(ls /proc/net/bonding|wc -l)
	if [ $have_bond_devices -gt 0 ]
	then
		line_needed=0
		add_title_line "Bond" "Devices:"
		add_empty_line
		for i in $(ls /proc/net/bonding)
		do
			echo $i >> /tmp/nics.txt
			if [ $line_needed -eq 0 ]
			then
				line_needed=1
			else
				add_simple_line
			fi
			have_bond_ip=$(ifconfig $i|grep inet|wc -l)
			if [ $have_bond_ip -eq 1 ]
			then
				bond_ip=$(ifconfig $i|grep inet|awk '{print $2}'|cut -d ":" -f2)
				add_two_values_line "Device:" $i "IP_address:" $bond_ip
			else
				add_one_value_line "Device:" $i 
			fi
			add_empty_line
			for j in $(cat /proc/net/bonding/$i|grep Interface|cut -d ':' -f 2)
			do
				echo $j >> /tmp/nics.txt
				link=$(ethtool $j|egrep "Link detected:"|cut -d ':' -f2)
				mtu=$(ifconfig -a $j|grep MTU|cut -d ":" -f2|cut -d " " -f 1)
				add_three_values_line "Interface:" $j "Link_Status:" $link "MTU:" $mtu
			done
			add_empty_line
			if [ $network_info -eq 1 ]
			then
				show_bond_ips $i
			fi
		done
	fi
	if [ $network_info -eq 1 ]
	then
		show_bridges
		show_aditional_nics
		show_route
	fi
	add_line
	rm -f /tmp/nics.txt
}

###Function to collect the flags and activate the functions:
for i in "$@"
do
	if [ $i == "-a" ]
	then
		mem_info=1
		cpu_info=1
		ovm_info=1
		network_info=1
	fi
	if [ $i == "-m" ]
	then
		mem_info=1
	fi
	if [ $i == "-c" ]
	then
		cpu_info=1
	fi
	if [ $i == "-o" ]
	then
		ovm_info=1
	fi
	if [ $i == "-n" ]
	then
		network_info=1
	fi
done

##Run the script:
clear
collect_server_name_details
Collecting_memory_information
collect_CPU_information
collect_OVM_information
collect_network_information
echo "[OK] Data collected in: /tmp/$HOSTNAME.data.txt"
