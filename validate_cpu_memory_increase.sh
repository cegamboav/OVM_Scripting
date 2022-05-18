#!/bin/bash

#Script to validate a target server to acept a VM.
#
#
VM=$1
TServer=$2

Collect_info(){
	#collecting information:
	mkdir /tmp/mv_vm_info/
	ssh admin@localhost -p 10000 "show VM name=$VM" > /tmp/mv_vm_info/vm_info.txt
	cserver=$(egrep 'Server =' /tmp/mv_vm_info/vm_info.txt|cut -d '[' -f2|cut -d ']' -f1)
	ssh admin@localhost -p 10000 "show server name=$cserver" > /tmp/mv_vm_info/cserver_info.txt
	path_vmcfg=$(egrep "Mounted Path" /tmp/mv_vm_info/vm_info.txt |cut -d "=" -f2)
	ssh -l iuxu $cserver "sudo cat $path_vmcfg" > /tmp/mv_vm_info/vm.cfg_file
	ssh admin@localhost -p 10000 "list network" > /tmp/mv_vm_info/networks.txt
}

Display_info(){
	clear
	echo "Current information"
	date
	echo "----------------------"
	echo "VM info:"
	grep Name /tmp/mv_vm_info/vm_info.txt
	egrep 'Operating System' /tmp/mv_vm_info/vm_info.txt
	grep Memory /tmp/mv_vm_info/vm_info.txt|grep -v Max
	grep Processors /tmp/mv_vm_info/vm_info.txt|grep -v Max
	echo "----------------------"
	echo "Current server information"
	egrep 'Host Name' /tmp/mv_vm_info/cserver_info.txt
	egrep 'Status =' /tmp/mv_vm_info/cserver_info.txt
	
	echo "================================="
}

Comparing_data(){
	echo "Comparing Servers:"
	echo "OVM Verison:"
	cserver_data=$(egrep "OVM Version" /tmp/mv_vm_info/cserver_info.txt|cut -d "=" -f2)
	tserver_data=$(egrep "OVM Version" /tmp/mv_vm_info/tserver_info.txt|cut -d "=" -f2)
	echo $cserver_data"   <<--- Current Server"
	echo $tserver_data"   <<--- Target Server"
	echo "--------"
	echo "Cpu Compatibility Group:"
	cserver_data=$(egrep "Cpu Compatibility Group" /tmp/mv_vm_info/cserver_info.txt|cut -d "=" -f2)
	tserver_data=$(egrep "Cpu Compatibility Group" /tmp/mv_vm_info/tserver_info.txt|cut -d "=" -f2)
	echo "$cserver_data   <<--- Current Server"
	echo "$tserver_data   <<--- Target Server"
	echo "================================="
}


Verification_VM(){
	echo "Verifying Target server disponibility to allocate VM"
	echo
	echo "Verifying Memory:"
	vm_data=$(egrep Memory /tmp/mv_vm_info/vm_info.txt|grep -v Max|cut -d "=" -f2)
	tserver_data=$(egrep "Memory" /tmp/mv_vm_info/tserver_info.txt|egrep -v 'Usable|Ability'|cut -d "=" -f2)
	echo "$vm_data   <<--- VM Memory (MB)"
	echo "$tserver_data  <<--- Target Server Memory (MB)"
	tserver_data=$(egrep "Usable Memory" /tmp/mv_vm_info/tserver_info.txt|cut -d "=" -f2)
	echo "$tserver_data  <<--- Target Server Usable Memory (MB)"
	echo "--------"
}

start_proces(){
	Collect_info
	Display_info
	#Comparing_data
	#Verification_VM
	echo "--------------------"
	echo "End of Verification"
	echo "--------------------"
}

check_VM_exist(){
	status=$(ssh -l admin localhost -p 10000 "list vm"|grep $VM|wc -l )
	echo "Status: $status"
	if [ $status -eq 1 ]
	then
		continue=1
	else
		echo "[Error] VM DON'T Exist in the manager"
	fi
}


if [[ $VM == "" ]]
then
	echo "[Error] Please follow this format: "
	echo "./validate_mv_vm.sh <VM_name>"
else
	continue=0
	check_VM_exist
	if [ $continue -eq 1 ]
	then
		echo "Start process ..."
		start_proces
	fi
fi