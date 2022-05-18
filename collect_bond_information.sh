#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : This script used to the bond information in several server in MHAS
###############################################################
## 27 May, 2021 : Created 
##
##
################################################################
##
#

#Variables
Change=$1
input_file=$2
user=$3
log_file=log_collect_bond_information.txt
output_file=bond_information.txt




##This fucntion is used to create the temporary directory
createtempfolder(){
	mkdir -p tmp_dir_luns
}

##This function is used to create a temporary file to be used to collect the data:
create_server_file(){
	echo 'name' > tmp_dir_luns/temp_server_file.csv
	echo $1 >> tmp_dir_luns/temp_server_file.csv
}

##This fucntion is used to collect the bond information:
collect_bond(){
	create_server_file $1
	java -jar /bin/tools/icmd/icmd-1.1.1.jar -e -cmd "sudo ls /proc/net/bonding/" -u $user -s tmp_dir_luns/temp_server_file.csv -t $Change -cwd /usr/bin/ -sync -fq -n demo-exec1 |grep -v INFO > tmp_dir_luns/$1.bonds.txt
	for i in $(cat tmp_dir_luns/$1.bonds.txt)
	do
		java -jar /bin/tools/icmd/icmd-1.1.1.jar -e -cmd "sudo cat /proc/net/bonding/$i" -u $user -s tmp_dir_luns/temp_server_file.csv -t $Change -cwd /usr/bin/ -sync -fq -n demo-exec1 |grep -v INFO > tmp_dir_luns/$1.$i.bondinfo.txt
	done
}

print_bond_information(){
	status=()
	h=$(cat tmp_dir_luns/$1.$2.bondinfo.txt|egrep 'Slave Interface'|cut -d ' ' -f3)
	for g in $(cat tmp_dir_luns/$1.$2.bondinfo.txt|egrep 'Slave Interface' -A 1|egrep 'II Status'|cut -d ' ' -f3)
	do
			status+=("$g")
	done
	m=0
	for i in $(echo $h)
	do
			echo "|		Device: 	$i		Status:	${status[$m]}		|" |tee -a $output_file
			echo "|		Device: 	$i		Status:	${status[$m]}		|" >> $log_file
			((m++))
	done
}

#function to collect the required data.
collecting_data(){
	clear
	echo "Collecting data ...."|tee -a $log_file
	echo |tee -a $log_file
	echo |tee -a $log_file
	echo "Collecting Servers information"|tee -a $log_file
	echo |tee -a $log_file
	
	for i in $(cat $input_file|grep -v name)
	do
		echo "  Collecting information for server: $i"|tee -a $log_file
		collect_bond $i
	done
	echo |tee -a $log_file
	echo "[OK] All data collected."|tee -a $log_file
	echo |tee -a $log_file
}



##function to check the collected data:
checking_data(){
	echo > $output_file
	echo "Checking Data ..." |tee -a $log_file
	echo |tee -a $log_file
	echo "|-----------------------------------------------------------------------|" |tee -a $output_file
	echo "|-----------------------------------------------------------------------|" >> $log_file
	for i in `cat $input_file|grep -v name`
	do
		echo "|  Server: $i						|" >> $log_file
		echo "|  Server: $i						|" |tee -a $output_file
		for j in $(cat tmp_dir_luns/$i.bonds.txt)
		do
			echo "|	Bond: $j							|" |tee -a $output_file
			echo "|	Bond: $j							|" >> $log_file
			print_bond_information $i $j
		done
		echo "|-----------------------------------------------------------------------|" |tee -a $output_file
		echo "|-----------------------------------------------------------------------|" >> $log_file
	done
	echo	
	echo
}

##delete temporary file
delete_working_folder(){
	rm -rf tmp_dir_luns
	echo "[OK] All data deleted."
	echo
	echo "-----------------------------------------------------------------------" >> $log_file
}

print_example(){
	echo "[Error] Some parameters are missing."
	echo
	echo "The script should be ran link this:"
	echo "bash collect_bond_information.sh <change> <list_of_servers> <user>"
	echo ""
	echo "Where <change> is a valid change to connect to the Hypervisors."
	echo "Where <list_of_servers> is the list of servers in a file."
	echo "Where <user> is the user used to login into the HV Server (iuxu or ovmadm)."
	echo "Example:"
	echo "bash collect_bond_information.sh CHGXXXXX /tmp/list_of_luns.csv iuxu"
	echo
}

run_script(){
	echo > $log_file
	createtempfolder
	collecting_data
	checking_data
	delete_working_folder
	echo
	echo "Check all the data into $log_file and $output_file"
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
		if [ -z "$Change" ]
		then
			clear
			print_example
		else
			run_script
		fi
	fi
fi