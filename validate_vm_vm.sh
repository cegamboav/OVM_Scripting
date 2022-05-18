#!/bin/bash

#Script to validate a target server to acept a VM.
#
#
VM=$1
TServer=$2

Collect_info(){
	#collecting target server information:
	ssh admin@localhost -p 10000 "show server name=$TServer" > /tmp/mv_vm_info/tserver_info.txt
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
	echo "----------------------"
	echo "Target server information"
	egrep 'Host Name' /tmp/mv_vm_info/tserver_info.txt
	egrep 'Status =' /tmp/mv_vm_info/tserver_info.txt
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

verify_networks(){
	echo
	echo "VM Networks:"
	string=$(grep vif /tmp/mv_vm_info/vm.cfg_file|cut -d '[' -f2|cut -d ']' -f1)
	IFS=', ' read -r -a array <<< "$string"
	for element in "${array[@]}"
	do
	    brdg=$(echo $element|grep bridge|wc -l)
	    if [[ $brdg -eq 1 ]]
	    then
	    	data=$(echo $element|cut -d '=' -f2)
	    	ARRAY+=("${data%?}")
	    fi
	done
	i=0
	for element in "${ARRAY[@]}"
	do
		vnic=$(grep $element /tmp/mv_vm_info/networks.txt|cut -d ':' -f3)
	    echo "eth$i = "$element"	"$vnic 
	    ((i++))
	    ssh -l admin localhost -p 10000 "show network name=$vnic" > /tmp/mv_vm_info/networks_datails.txt
	    exist=$(grep $TServer /tmp/mv_vm_info/networks_datails.txt|wc -l)
	    if [[ $exist -eq 1 ]]
	    then
	    	echo "[OK] The network exist in the target server"
	    	echo "--------"
	    else
	    	echo "[Error] The network DON'T exist in the target server"
	    	echo "--------"
	    fi
	done
}

check_disks(){
	echo "VM Disks:"
	string=$(grep disk /tmp/mv_vm_info/vm.cfg_file|cut -d '[' -f2|cut -d ']' -f1)
	IFS=', ' read -r -a darray <<< "$string"
	for element in "${darray[@]}"
	do
		status=0
		status=$(echo $element|egrep 'file|phy'|wc -l)
		if [ $status -eq 1 ]
		then
    		data=$(echo $element|cut -d ':' -f2)
    		dARRAY+=("${data}")
    		vdisk=$(echo $element|egrep 'file'|wc -l)
    		if [ $vdisk -eq 1 ]
    		then
    			repository=$(echo $element|cut -d '/' -f4)
    			echo $repository
    			if [[ ! " ${rep_array[@]} " =~ " ${repository} " ]]
    			then
    				rep_array+=("${repository}")
    			fi
    		fi
    	fi
	done
	i=0
	for element in "${dARRAY[@]}"
	do
	    echo "disk$i = "$element 
	    ((i++))
	done
	echo 
	i=0
	if [ ${#rep_array[@]} -gt 0 ]
	then
		echo "The vdisks are allocated in the following repositories:"
		echo
		for element in "${rep_array[@]}"
		do
		    echo "Repository$i = "$element 
		    ((i++))
		    mounted=$(ssh -l admin localhost -p 10000 "show repository id=$element"|grep $TServer|wc -l)
		    if [ $mounted -eq 1 ]
		    then
		    	echo "[OK] The repository is mounted in the Target Server"
		    else
		    	echo "[Error] The repository is NOT mounted in the Target Server"
		    fi
		    echo "---------------"
		done
	fi
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
	echo "Verifying Network:"
	verify_networks
	echo "================================="
	echo "Checking Disks status"
	check_disks
}

start_proces(){
	#Collect_info
	Display_info
	Comparing_data
	Verification_VM
	echo "--------------------"
	echo "End of Verification"
	echo "--------------------"
}

check_VM_exist(){
	status=$(ssh -l admin localhost -p 10000 "list vm"|grep $VM|wc -l )
	if [ $status -eq 1 ]
	then
		continue=1
	else
		echo "[Error] VM DON'T Exist in the manager"
	fi
}

check_Server_exist(){
	status=$(ssh -l admin localhost -p 10000 "list server"|grep $TServer|wc -l )
	if [ $status -eq 1 ]
	then
		continue=1
	else
		echo "[Error] Target Server DON'T Exist in the manager"
	fi
}

if [[ $VM == "" ]]
then
	echo "[Error] Please follow this format: "
	echo "./validate_mv_vm.sh <VM_name> <Target_Server_name>"
else
	continue=0
	check_VM_exist
	if [ $continue -eq 1 ]
	then
		if [[ $TServer == "" ]]
		then
			echo "[Error] Please follow this format: "
			echo "./validate_mv_vm.sh <VM_name> <Target_Server_name>"
		else
			continue=0
			check_Server_exist
			if [ $continue -eq 1 ]
			then
				start_proces
			fi
		fi
	fi
fi