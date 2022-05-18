#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : This script used to collect ServerPool Name | HV Name | HV IP | Serial Number | Product Model from a list of server
###############################################################
## 23 April, 2021 : Created 
##
##
################################################################
##
#


#Variables
Change=$1
input_file=$2
sysdata_log=$3
log_file=$sysdata_log.txt
log_file_csv=$sysdata_log.csv
echo > $sysdata_log.txt
echo > $sysdata_log.csv


##This fucntion is used to create the temporary directory
createtempfolder(){
	mkdir -p tmp_dir
}

##This function is used to create a temporary file to be used to collect the data:
create_server_file(){
	echo 'name' > tmp_dir/temp_server_file.csv
	echo $1 >> tmp_dir/temp_server_file.csv
}

##This fucntion is used to collect the multipath information:
collect_information(){
	create_server_file $1
	java -jar /bin/tools/icmd/icmd-1.1.1.jar -e -cmd "sudo ovs-agent-db dump_db server" -u iuxu -s tmp_dir/temp_server_file.csv -t $Change -cwd /usr/bin/ -sync -fq -n demo-exec1 |grep -v INFO > tmp_dir/$1.agent.txt
	java -jar /bin/tools/icmd/icmd-1.1.1.jar -e -cmd "sudo dmidecode -t system" -u iuxu -s tmp_dir/temp_server_file.csv -t $Change -cwd /usr/bin/ -sync -fq -n demo-exec1 |grep -v INFO > tmp_dir/$1.system.txt
}

#function to collect the required data.
collecting_data(){
	clear
	echo "Collecting data ...."|tee -a $log_file
	echo |tee -a $log_file
	echo |tee -a $log_file
	echo "Collecting Servers information"|tee -a $log_file
	echo |tee -a $log_file
	echo > tmp_dir/servers_with_vms.txt
	
	for i in `cat $input_file|grep -v name`
	do
		#First we are going to verify if the server have IBM LUNs, if not we discart the server and continue with the next one
		echo "  Collecting data for $i ..."|tee -a $log_file
		collect_information $i
	done
	echo |tee -a $log_file
	echo "[OK] All data collected."|tee -a $log_file
	echo |tee -a $log_file
}

print_head(){
	echo "|=======================================================================================================================|"|tee -a $log_file
	printf "%-1s %-15s %-1s %-15s %-1s %-20s %-1s %-15s %-1s %-40s %-1s\n" "|" "Name" "|" "IP_Address" "|" "ServerPool_Name" "|" "Serial_Number" "|" "Product_Model" "|"|tee -a $log_file
	echo "Name,IP_Address,ServerPool_Name,Serial_Number,Product_Model" >> $log_file_csv
	echo "|-----------------|-----------------|----------------------|-----------------|------------------------------------------|"|tee -a $log_file
}

print_foot(){
	echo "|=======================================================================================================================|"|tee -a $log_file
}

print_line(){
	printf "%-1s %-15s %-1s %-15s %-1s %-20s %-1s %-15s %-1s %-40s %-1s\n" "|" $1 "|" $2 "|" $3 "|" $4 "|" $5 "|"|tee -a $log_file
	echo "$1,$2,$3,$4,$5" >> $log_file_csv
}

##function to check the collected data:
checking_data(){
	echo "Checking Data ..." |tee -a $log_file
	echo |tee -a $log_file
	##Start to evaluate all the servers:
	print_head
	for i in `cat $input_file|grep -v name`
	do
		pool_name=$(grep pool_alias tmp_dir/$i.agent.txt|cut -d "'" -f4|cut -d "'" -f1|sed 's/  */_/g')
		server_ip=$(grep registered_ip tmp_dir/$i.agent.txt|cut -d "'" -f4|cut -d "'" -f1)
		server_sn=$(grep Serial tmp_dir/$i.system.txt|cut -d ":" -f2)
		server_pn=$(egrep 'Product Name' tmp_dir/$i.system.txt|cut -d ":" -f2|sed 's/  */_/g')
		print_line $i $server_ip "$pool_name" "$server_sn" "$server_pn"
	done
	print_foot
}

##delete temporary file
delete_working_folder(){
	echo "Dumping data ..."
	echo > sysdata_log.dmp
	for i in `ls tmp_dir/*.agent.txt`
	do
		echo $i >> sysdata_log.dmp
		echo "+++++++++" >> $sysdata_log.dmp
		cat $i >> sysdata_log.dmp
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> sysdata_log.dmp
	done
	for i in `ls tmp_dir/*.system.txt`
	do
		echo $i >> sysdata_log.dmp
		echo "+++++++++" >> $sysdata_log.dmp
		cat $i >> sysdata_log.dmp
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> sysdata_log.dmp
	done
	rm -rf tmp_dir
	echo "[OK] All data dumped and deleted."
}

if [ -z $Change ]
then
	echo "[Error] Please provide a change number"
else
	if [ -z $input_file ]
	then
		echo "[Error] Please provide the file with the list of servers."
	else
		if [ -z $sysdata_log ]
		then
			echo "[Error] Please provide the file name to send the information of the script."
		else
			createtempfolder
			collecting_data
			checking_data
			delete_working_folder
		fi
	fi
fi