#!/bin/bash

#Script to identify if a LUN is used by any running VM in CMS environment.

#Variables
servers=$1
input_file=$2




## create folders
createtempfolder(){
	mkdir -p tmp_dir
}

#function to collect the required data.
collecting_data(){
	clear
	echo "Collecting data ...."
	echo
	echo
	echo "Collecting Servers information"
	echo 
	echo > tmp_dir/servers_with_vms.txt
	for i in `cat $servers`
	do
		VMs_running=0
		VMs_running=$(ssh $i "xm list|egrep -v 'Domain-0|Name'|wc -l")
		if [ $VMs_running -eq 0 ]
		then
			echo "  $i no vms running."
		else
			echo "  Collecting data from $i"
			ssh $i "multipath -ll" > tmp_dir/$i.mltp.txt
			ssh $i "xm list|egrep -v 'Domain-0|Name'" > tmp_dir/$i.xmli.txt
			echo $i >> tmp_dir/servers_with_vms.txt
			for j in `cat tmp_dir/$i.xmli.txt|awk '{print $1}'`
			do
				ssh $i "egrep 'disk|name' /OVS/Repositories/*/VirtualMachines/$j/vm.cfg" > tmp_dir/$j.vms.txt
			done
		fi
	done
	echo 
	echo "[OK] All data collected."
	echo
}

checking_data(){
	echo "Checking Data ..."
	echo
	total=0
	for i in `cat $input_file`
	do
		echo "  Checking LUN: $i"
		for j in `cat tmp_dir/servers_with_vms.txt`
		do
			presented=0
			presented=$(grep $i tmp_dir/$j.mltp.txt|wc -l)
			if [ $presented -eq 1 ]
			then
				for k in `cat tmp_dir/$j.xmli.txt|awk '{print $1}'`
				do
					exits=0
					exits=$(grep $i tmp_dir/$k.vms.txt|wc -l)
					if [ $exits -eq 1 ]
					then
						echo "    [Warning] The LUN $i is configured in this VM: $k and is running in server $j"
						total=$((total+1))
					fi
				done
			fi
		done
	done
	if [ $total -eq 0 ]
	then
		echo
		echo "[OK] No Luns used for any running VM"
	else
		echo
		echo "[Warning] One o more Luns used in running VMs"
	fi
}

##delete temporary file
delete_working_folder(){
	echo "Dumping data ..."
	echo > dump_data.txt
	for i in `ls tmp_dir/*.mltp.txt`
	do
		echo $i >> dump_data.txt
		echo "+++++++++" >> dump_data.txt
		cat $i >> dump_data.txt
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_data.txt
	done
	for i in `ls tmp_dir/*.vms.txt`
	do
		echo $i >> dump_data.txt
		echo "+++++++++" >> dump_data.txt
		cat $i >> dump_data.txt
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_data.txt
	done
	for i in `ls tmp_dir/*.xmli.txt`
	do
		echo $i >> dump_data.txt
		echo "+++++++++" >> dump_data.txt
		cat $i >> dump_data.txt
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_data.txt
	done
	rm -rf tmp_dir
	echo "[OK] All data dumped and deleted."
}


run_script(){
	createtempfolder
	collecting_data
	checking_data
	delete_working_folder
}

if [ -z "$servers" ]
then
	clear
	echo "[Error] Need to insert the file with the servers list"
	echo
	echo "Example:"
	echo "bash Lun_used_by_vm_CMS.sh 1 /tmp/servers.csv /tmp/list_of_luns.csv"
	echo
else
	if [ -z "$input_file" ]
	then
		clear
		echo "[Error] Insert the Luns file Path."
		echo
		echo "Example:"
		echo "bash Lun_used_by_vm_CMS.sh 1 /tmp/servers.csv /tmp/list_of_luns.csv"
		echo
	else
		run_script
	fi
fi