#!/bin/bash

VM=$1

Show_initial_data(){
		clear
        server_total_memory=$(xm info |egrep total_memory|cut -d ':' -f2-|cut -d ' ' -f2)
        server_total_memory_gb=$(expr $server_total_memory / 1024)
        echo "Server Name: "
        hostname
 		echo
        echo "Server Total Memory in GB: $server_total_memory_gb"
        echo
        echo "VMs in the server:"
        vm_list=$(xm list|awk '{print $1}'|egrep -v 'Name|Domain-0')
        total_memory=0
        for i in ${vm_list[@]}
		do
			vm_memory_mb=$(xm list $i|grep -v Name|awk '{print $3}')
			vm_memory_gb=$(expr $vm_memory_mb / 1024)
			mem=$total_memory
			total_memory=$(expr $mem + $vm_memory_mb)
			vm_file=$(find /OVS/ -name $i|grep -v snapshot)
			vm_name=$(egrep OVM_simple_name $vm_file/vm.cfg|cut -d '=' -f2-|cut -d ' ' -f2-)
			echo "$vm_name				$vm_memory_gb GB"
		done
		total_memory_gb=$(expr $total_memory / 1024)
		echo "						--------"
		echo "Total Memory:					$total_memory_gb GB"
		remaining_memory=$(expr $server_total_memory - $total_memory)
		remaining_memory_gb=$(expr $remaining_memory / 1024)
		echo "						--------"
		echo "Free Memory:					$remaining_memory_gb GB"
}

Show_initial_data
