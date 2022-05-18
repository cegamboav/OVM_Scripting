#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : This script used to get lsscsi output
###############################################################
## 20 May, 2021 : Created 
##
##
################################################################
##
#

#Variables
user=$1
input_file=$2
log_file=collected_messages_files.txt
output_file=queue_depth.txt

##This fucntion is used to create the temporary directory
createtempfolder(){
	mkdir -p tmp_dir_luns
}

##This fucntion is used to collect the multipath information:
collect_command(){
	ssh $user@$1 "sudo lsscsi -l" > tmp_dir_luns/$1.lsscsi.txt
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
		collect_command $i
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
	echo > $output_file
	for i in `ls tmp_dir_luns/*.lsscsi.txt`
	do
		echo $i >> dump_data.txt
		echo "+++++++++" >> dump_data.txt
		cat $i >> dump_data.txt
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_data.txt
		echo "Checking $i" |tee -a $log_file
		echo "Checking $i" >> $output_file
		cat $i|grep queue_depth|uniq|awk '{print $2}'|tee -a $log_file
		cat $i|grep queue_depth|uniq|awk '{print $2}' >> $output_file
	done
	#rm -rf tmp_dir_luns
	echo "[OK] All data dumped and deleted."
	echo
	echo "-----------------------------------------------------------------------" |tee -a $log_file
}


run_script(){
	echo > $log_file
	createtempfolder
	collecting_data
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
		run_script
	fi
fi