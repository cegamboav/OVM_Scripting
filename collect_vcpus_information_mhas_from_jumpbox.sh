#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@kyndryl.com>
# Purpose : This script is to display the vm name and OS asociated to this VM From the manager Server
###############################################################
## 3 Mar, 2022 : Created 
##
##
################################################################

Change=$1
input_file=$2
output_name=$3

## Function to create temp directory
createtempfolder(){
	mkdir -p tmp_dir
}

##Function to create the server files:
create_server_file(){
	echo 'name' > tmp_dir/temp_server_file.csv
	echo $1 >> tmp_dir/temp_server_file.csv
}

##Function to check the server:
check_servers(){
	#Variable to set the print format:
	format="%-1s %-32s %-1s %06s %-1s %7s %-1s %7s %-1s\n"
	#Now display information in the screen
	clear
	echo "Collecting data ...."
	echo
	echo "  Collecting xm list ..."
	echo
	
	#Collect the xmlist of all the VMs in the input_file:
	for i in $(cat $input_file|grep -v name)
	do
		echo "    Creating file $i.xmlist.txt"
		#Call the fucntion to create the server file:
		create_server_file $i
		#now we call the function to run the script in the servers:
		icmd -e -cmd "sudo xm list;sudo xm info|grep nr_cpus" -u iuxu -s tmp_dir/temp_server_file.csv -t $Change -cwd /usr/bin/ -sync -fq -n demo-exec1 |grep -v INFO > tmp_dir/$i.xmlist.txt
	done
	echo "------------------------------------"
	#Now we start to collect the vcpu-list information:
	echo "  Collecting vcpu-list information ..."
	echo
	for i in $(cat $input_file|grep -v name)
	do
		echo "    Creating file $i.xmvcpu.txt"
		create_server_file $i
		icmd -e -cmd "sudo xm vcpu-list" -u iuxu -s tmp_dir/temp_server_file.csv -t $Change -cwd /usr/bin/ -sync -fq -n demo-exec1 |grep -v INFO > tmp_dir/$i.xmvcpu.txt
	done
	echo "------------------------------------"
	echo "  Creating $output_name.vcpus.txt ..."
	echo
	echo "|===============================================================|" > $output_name.vcpus.txt
	echo "" > $output_name.csv
	for i in $(cat $input_file|grep -v name)
	do
		#check how many vms are running in the server:
		number_of_vms=$(egrep -v 'Name|Domain-0' tmp_dir/$i.xmlist.txt|wc -l)
		#If there is no VMs running:
		if [ $number_of_vms -eq 0 ]
		then
			#Just set the VMs number in 0
			number_of_vms=0
		#If running VMs then:
		else
			#Collect the amount of the CPUs in the server:
			CPUs_Server=$(cat tmp_dir/$i.xmlist.txt|grep nr_cpus| cut -d ':' -f2)
			#echo '|----------------------------------|--------|---------|---------|' >> $output_name.vcpus.txt
			#Insert the information in the file:
			printf "%-1s %-7s %-24s %-1s %-5s %-20s %-1s\n" "|" "Server:" $i "|" "CPUS:" $CPUs_Server "|" >> $output_name.vcpus.txt
			#echo "| Server : $i     CPUS: $CPUs_Server" >> $output_name.vcpus.txt
			echo "$i,$CPUs_Server" >> $output_name.csv
			echo '| VM ID                            | VCPUS  | From    |  TO     |' >> $output_name.vcpus.txt
			echo 'VM ID,VCPUS,From,To' >> $output_name.csv
			echo '|----------------------------------|--------|---------|---------|' >> $output_name.vcpus.txt
			p=$(cat tmp_dir/$i.xmvcpu.txt|grep Domain-0|tail -n 1|awk '{print $7}')
			q=$(cat tmp_dir/$i.xmlist.txt|grep Domain-0|awk '{print $4}')
			printf "$format" "|" "Domain-0" "|" $q "|" "0" "|" $p "|" >> $output_name.vcpus.txt
			echo "Domain-0,$q,0,$p" >> $output_name.csv
			egrep -v 'Name|Domain-0|nr_cpus' tmp_dir/$i.xmlist.txt|awk '{print $1}' > tmp_dir/$i.vm_ids.txt
			for j in `cat tmp_dir/$i.vm_ids.txt`
			do	
				m=$(grep $j tmp_dir/$i.xmlist.txt|awk '{print $4}')
				n=$(grep $j tmp_dir/$i.xmvcpu.txt|awk '{print $7}'|uniq)
				o=$(echo $n|cut -d '-' -f1)
				r=$(echo $n|cut -d '-' -f2)
				printf "$format" "|" $j "|" $m "|" $o "|" $r "|" >> $output_name.vcpus.txt
				echo "$j,$m,$o,$r" >> $output_name.csv
			done
			echo "|===============================================================|" >> $output_name.vcpus.txt
			echo "================,================" >> $output_name.csv
			echo "$i Completed"
		fi
	done
	echo 
	echo "[OK] All the data has been proceeded, check the file $output_name.vcpus.txt"
	echo
}

##delete temporary file
delete_working_folder(){
	echo "Dumping data ..."
	echo > dump_$output_name.vcpus.txt
	for i in `ls tmp_dir/*.xmlist.txt`
	do
		echo $i >> dump_$output_name.vcpus.txt
		echo "+++++++++" >> dump_$output_name.vcpus.txt
		cat $i >> dump_$output_name.vcpus.txt
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_$output_name.vcpus.txt
	done
	for i in `ls tmp_dir/*.xmvcpu.txt`
	do
		echo $i >> dump_$output_name.vcpus.txt
		echo "+++++++++" >> dump_$output_name.vcpus.txt
		cat $i >> dump_$output_name.vcpus.txt
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_$output_name.vcpus.txt
	done
	rm -rf tmp_dir
	echo "[OK] All data dumped and deleted."
}


if [ -z "$Change" ]
then
	clear
	echo "[Error] Insert the Change ID."
	echo
	echo "Example:"
	echo "bash check_paths_mhas.sh CHXXXXXXXXX hostp1.csv"
	echo
else
	if [ -z "$input_file" ]
	then
		clear
		echo "[Error] Insert the input file path"
		echo
		echo "Example:"
		echo "bash check_paths_mhas.sh CHXXXXXXXXX hostp1.csv"
		echo
	else
		if [ -z "output_name" ]
		then
			output_name="information.txt"
		fi
		createtempfolder
		check_servers
		delete_working_folder
	fi
fi