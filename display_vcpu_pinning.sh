#!/bin/bash

clear

print_doble_line(){
	echo "|====================================================================================================|"
}

print_simple_line(){
	echo "|------------------------------------------|------------------------------------------|--------------|"
}

print_server_info(){
	printf "%-1s %-20s %-77s %-1s\n" "|" "Server_Name:" $1 "|"
}

print_info(){
	printf "%-1s %-40s %-1s %-40s %-1s %-12s %-1s\n" "|" $1 "|" $2 "|" $3 "|"
}

print_doble_line
print_server_info $(hostname)
print_simple_line
print_info "VM_ID" "VM_Name" "CPU_Pinning"
print_simple_line
dom0_pinning=$(xm vcpu-list|grep Domain|awk '{print $7}'|tail -n 1)
print_info "Domain-0" "Domain-0" "0-$dom0_pinning"
for i in $(xm vcpu-list|sort -k 7|awk '{print $1}'|egrep -v 'Domain|Name'|uniq)
do
	Id=$i
	cpu_pinning=$(xm vcpu-list $i|grep -v Name|awk '{print $7}'|uniq)
	path=$(find /OVS/Repositories/ -name $i|grep -v snap|head -n 1)
	name=$(cat $path/vm.cfg |grep OVM_simple_name|cut -d "'" -f2)
	#echo "$Id 		$name		$cpu_pinning"
	print_info  $Id  $name  $cpu_pinning 
done

print_doble_line