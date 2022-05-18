#!/bin/bash

#Script to identify if a LUN is used by any running VM in MHAS environment.
prt_hd=0

print_head(){
	if [ $prt_hd -eq 0 ]
	then
		echo "|---------------------------------------|---------------|"
		echo "|VM Name:	$1"
		echo "|	IBM LUN ID			|  Status	|"
		echo "|---------------------------------------|---------------|"
		prt_hd=1
	fi
}


collect_multipath_data(){
	multipath -ll > /tmp/mltp.txt
	multipathd show maps status > /tmp/status.txt
}

collect_vms(){

	for i in `xm list|egrep -v 'Domain-0|Name'|awk '{print $1}'`
	do 
		tot_disks=$(grep disk /OVS/Repositories/*/*/VirtualMachines/$i/vm.cfg)
		vm_name=$(grep OVM_simple_name /OVS/Repositories/*/*/VirtualMachines/$i/vm.cfg|cut -d "'" -f2)
		COUNT=0
		disks=$tot_disks
		while [ $COUNT -eq 0 ]
		do
			dev=$(echo $disks|cut -d "'" -f2)
			dsk=$(echo $dev|cut -d "/" -f4|cut -d ',' -f1)
			phy=$(echo $dev|grep phy|wc -l)
			if [ $phy -eq 1 ]
			then
				lun=$(grep $dsk /tmp/mltp.txt|awk '{print $1}')
				is_ibm=$(grep $lun /tmp/mltp.txt|grep IBM|wc -l)
				if [ $is_ibm -eq 1 ]
				then
					print_head $vm_name
					status=$(grep $lun /tmp/status.txt|awk '{print $5}')
					echo "|$lun	|	$status	|"
				fi
				otra=$(echo $disks|cut -d "'" -f3-)
				disks=$otra
				cont=$(echo $otra|grep phy|wc -l)
				if [ $cont -eq 0 ]
				then
					COUNT=1
				fi
			else
				otra=$(echo $disks|cut -d "'" -f3-)
				disks=$otra
				cont=$(echo $otra|grep phy|wc -l)
				if [ $cont -eq 0 ]
				then
					COUNT=1
				fi
			fi
		done
		prt_hd=0
	done
}

print_end(){
	echo "|---------------------------------------|---------------|"
	echo 
	echo "=================================================================="
	echo "=================================================================="
}

delete_tmp_data(){
	rm -f /tmp/mltp.txt
	rm -f /tmp/status.txt
}

echo
echo
echo "Checking Server: "`hostname`
echo
collect_multipath_data
collect_vms
print_end
delete_tmp_data