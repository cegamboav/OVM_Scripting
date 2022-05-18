#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : This script used to check the IBM LUNs of a list of servers and check if they are used by a VM and the amount of paths it have, from the manager.
###############################################################
## 30 April, 2021 : Created 
##
##
################################################################
##
#

#Variables
user=$1
input_file=$2
log_file=check_paths_mhas.txt




##This fucntion is used to create the temporary directory
createtempfolder(){
	mkdir -p tmp_dir_luns
}

##This fucntion is used to collect the multipath information:
collect_mulipath(){
	ssh $user@$1 "sudo multipath -ll" > tmp_dir_luns/$1.mltp.txt
	ssh $user@$1 "sudo multipathd show maps status" > tmp_dir_luns/$1.status.txt
}

##This function is used to collect the vm.cfg file of the running vms:
collect_vms_conf_file(){
	vmFile=$(ssh $user@$1 "sudo find /OVS/Repositories/ -name $2 2>/dev/null|head -1")
	ssh $user@$1 "sudo cat $vmFile/vm.cfg" > tmp_dir_luns/$2.vms.txt
}

##This function is used to collect the xm list output of the servers:
collect_xm_list(){
	echo "      Creating file $1.xmli.txt  ..."|tee -a $log_file
	ssh $user@$1 "sudo xm list" > tmp_dir_luns/$1.xmli.txt
}

#function to collect the required data.
collecting_data(){
	clear
	echo "Collecting data ...."|tee -a $log_file
	echo |tee -a $log_file
	echo |tee -a $log_file
	echo "Collecting Servers information"|tee -a $log_file
	echo |tee -a $log_file
	echo > tmp_dir_luns/servers_with_vms.txt
	
	for i in `cat $input_file|grep -v name`
	do
		#First we are going to verify if the server have IBM LUNs, if not we discart the server and continue with the next one
		echo "  Checking if $i have IBM LUNs ..."|tee -a $log_file
		collect_mulipath $i
		ibm_luns=$(cat tmp_dir_luns/$i.mltp.txt|grep IBM|wc -l)
		if [ $ibm_luns -gt 0 ]
		then
			#Now if the Server contain at least 1 IBM lun, we are going to proceed to verify if the server have running vms:
			echo "    Server contains IBM LUNs, then collecting more data:"|tee -a $log_file
			collect_xm_list $i
			VMs_running=0
			VMs_running=$(cat tmp_dir_luns/$i.xmli.txt|egrep -v 'Domain-0|Name'|wc -l)
			if [ $VMs_running -eq 0 ]
			then
				echo "      $i no vms running."|tee -a $log_file
				echo "  ---------"|tee -a $log_file
			else
				#Now if the server have running vms, then we collect the vm.cfg files
				echo "      Collecting vms.cfg files ..."|tee -a $log_file
				for j in `cat tmp_dir_luns/$i.xmli.txt|egrep -v 'Domain-0|Name'|awk '{print $1}'`
				do
					collect_vms_conf_file $i $j
				done
				#add this server as a server to be evaluated
				echo $i >> tmp_dir_luns/servers_with_vms.txt|tee -a $log_file
				echo "  ---------"|tee -a $log_file
			fi
		else
			echo "    Sever does not contains IBM LUNs."|tee -a $log_file
			echo "  ---------"|tee -a $log_file
		fi
	done
	echo |tee -a $log_file
	echo "[OK] All data collected."|tee -a $log_file
	echo |tee -a $log_file
	echo "-----------------------------------------------------------------------" |tee -a $log_file
}

##function to check the collected data:
checking_data(){
	echo "Checking Data ..." |tee -a $log_file
	echo |tee -a $log_file
	total=0
	##Start to evaluate all the servers that contains information:
	for i in `cat tmp_dir_luns/servers_with_vms.txt`
	do
		is_used_head=0
		echo "  Checking $i" |tee -a $log_file
		echo "    Checking IBM LUNs..." |tee -a $log_file
		Luns=$(cat tmp_dir_luns/$i.mltp.txt|grep -i IBM|awk '{print $1}')
		for h in `echo $Luns`
		do
			is_used=0
			echo "      Checking LUN: $h ..." | tee -a $log_file
			for j in `cat tmp_dir_luns/$i.xmli.txt|awk {'print $1'}|egrep -v 'Name|Domain'`
			do
				exist_lun=$(grep $h tmp_dir_luns/$j.vms.txt|wc -l)
				##If the Lun exist in a running vm the information is reported:
				if [ $exist_lun -gt 0 ]
				then
					if [ $is_used_head -eq 0 ]
					then
						echo "|									|">> tmp_dir_luns/output.txt
						echo "| Server: $i                                      	        |" >> tmp_dir_luns/output.txt
						add_info_to_file "LUN_ID" "PATHs" "VM_ID"
						is_used_head=1
					fi
					paths_qty=$(cat tmp_dir_luns/$i.status.txt|grep $h|awk '{print $5}')
					vm_name=$(grep OVM_simple_name tmp_dir_luns/$j.vms.txt|cut -d "'" -f2 |cut -d "'" -f1)
					add_info_to_file $h $paths_qty $vm_name
					total=$((total+1))
					is_used=1
					total=$((total+1))
				fi
			done
		done
		if [ $is_used -eq 0 ]
		then
			echo "        [OK] No IBM LUNs used by any Running VM." | tee -a $log_file
		fi
	done
	echo
	echo "-----------------------------------------------------------------------" |tee -a $log_file
	echo
}

##delete temporary file
delete_working_folder(){
	echo "Dumping data ..."
	echo > dump_data.txt
	for i in `ls tmp_dir_luns/*.mltp.txt`
	do
		echo $i >> dump_data.txt
		echo "+++++++++" >> dump_data.txt
		cat $i >> dump_data.txt
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_data.txt
	done
	for i in `ls tmp_dir_luns/*.vms.txt`
	do
		echo $i >> dump_data.txt
		echo "+++++++++" >> dump_data.txt
		cat $i >> dump_data.txt
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_data.txt
	done
	for i in `ls tmp_dir_luns/*.xmli.txt`
	do
		echo $i >> dump_data.txt
		echo "+++++++++" >> dump_data.txt
		cat $i >> dump_data.txt
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_data.txt
	done
	rm -rf tmp_dir_luns
	echo "[OK] All data dumped and deleted."
	echo
	echo "-----------------------------------------------------------------------" |tee -a $log_file
}

head_of_file(){
	echo "|-----------------------------------------------------------------------|" > tmp_dir_luns/output.txt
	echo "|IBM Path Report							|" >> tmp_dir_luns/output.txt
	echo "|-----------------------------------------------------------------------|" >> tmp_dir_luns/output.txt
	#echo "| Server: $i                                            |" >> tmp_dir_luns/output.txt
}

add_info_to_file(){
	printf "%-1s %-33s %-1s %-5s %-1s %-25s %-1s\n" "|" $1 "|" $2 "|" $3 "|" >> tmp_dir_luns/output.txt
}

foot_of_file(){
	echo "|-----------------------------------------------------------------------|" >> tmp_dir_luns/output.txt
}

print_example(){
	echo "[Error] Some parameters are missing."
	echo
	echo "The script should be ran link this:"
	echo "bash Lun_used_by_vm_mhas_manager.sh ,<user> <list_of_servers>"
	echo ""
	echo "Where <user> is the user used to login into the HV Server (iuxu or ovmadm)."
	echo "Where <list_of_servers> is the list of servers."
	echo "Example:"
	echo "bash Lun_used_by_vm_mhas_manager.sh iuxu /tmp/list_of_luns.csv"
	echo
}

print_status(){
	if [ $total -eq 0 ]
	then
		echo |tee -a $log_file
		echo "[OK] No IBM Luns used for running VMs"|tee -a $log_file
	else
		echo |tee -a $log_file
		echo "[Warning] One o more Luns are been used in running VMs"|tee -a $log_file
	fi
}

run_script(){
	echo > $log_file
	createtempfolder
	collecting_data
	total_servers=$(cat tmp_dir_luns/servers_with_vms.txt|wc -l)
	if [ $total_servers -gt 0 ]
	then
		head_of_file
		checking_data
		foot_of_file
		if [ $total -gt 0 ]
		then
			echo |tee -a $log_file
			echo |tee -a $log_file
			cat tmp_dir_luns/output.txt|tee -a $log_file
			cat tmp_dir_luns/output.txt > just_table.txt
		fi
	fi
	delete_working_folder
	print_status
	echo
	echo "Check all the data into $log_file and just_table.txt"
	echo
}


if [ -z "$user" ]
then
	clear
	print_example
else
	if [ -z "$input_file" ]
	then
		clear
		print_example
	else
		run_script
	fi
fi