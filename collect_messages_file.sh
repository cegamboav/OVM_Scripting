#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : This script used to get messages files
###############################################################
## 19 May, 2021 : Created 
##
##
################################################################
##
#

#Variables
user=$1
input_file=$2
log_file=collected_messages_files.txt

##This fucntion is used to create the temporary directory
createtempfolder(){
	mkdir -p tmp_dir_luns
}

##This fucntion is used to collect the multipath information:
collect_messages(){
	ssh $user@$1 "sudo cat /var/log/messages" > tmp_dir_luns/$1.messages.txt
}

#function to collect the required data.
collecting_data(){
	clear
	echo "Collecting data ...."|tee -a $log_file
	echo |tee -a $log_file
	echo |tee -a $log_file
	echo "Collecting Servers information"|tee -a $log_file
	echo |tee -a $log_file
	
	for i in `cat $input_file|grep -v name`
	do
		echo "Collecting $i" |tee -a $log_file
		collect_messages $i
	done
	echo |tee -a $log_file
	echo "[OK] All data collected."|tee -a $log_file
	echo |tee -a $log_file
	echo "-----------------------------------------------------------------------" |tee -a $log_file
}


##delete temporary file
delete_working_folder(){
	echo "Dumping data ..."
	echo > dump_data.txt
	echo > checked_servers.txt
	for i in `ls tmp_dir_luns/*.messages.txt`
	do
		echo $i >> dump_data.txt
		echo "+++++++++" >> dump_data.txt
		cat $i >> dump_data.txt
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_data.txt
		echo "Checking $i" |tee -a $log_file
		messages=$(egrep "FC_HOST_EVENT" $i|wc -l)
		if [ $messages -gt 0 ]
		then
			echo "Checking $i" |tee -a checked_servers.txt
			egrep "FC_HOST_EVENT" $i >> checked_servers.txt
			echo "--------------------------------" >> checked_servers.txt
		fi
	done
	rm -rf tmp_dir_luns
	echo "[OK] All data dumped and deleted."
	echo
	echo "-----------------------------------------------------------------------" |tee -a $log_file
}


run_script(){
	echo > $log_file
	createtempfolder
	collecting_data
	analyze_data
	delete_working_folder
	echo
	echo "Check all the data into $log_file and checked_servers.txt"
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