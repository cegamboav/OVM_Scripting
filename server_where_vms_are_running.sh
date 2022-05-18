#!/bin/bash
vms=$1

for i in `cat $vms`
do 
	h=$(ovmcli "list vm"|grep -i $i|cut -d ':' -f 3)
	if [ -z $h ]
	then
		echo "No esta en el manager"
	else
		vm_id=$(ovmcli "show vm name=$h"|grep Id|grep -v VmDiskMapping|cut -d ' ' -f 5)
		server=$(ovmcli "show vm name=$h"|grep Server|egrep -v 'Operating System|Start Policy|Server Pool'|cut -d '[' -f2|cut -d ']' -f1)
		CPUs=$( ssh iuxu@$server "sudo xm info|grep nr_cpus|cut -d ":" -f2")
		echo "$i		$server		$CPUs		$vm_id"
	fi
done
