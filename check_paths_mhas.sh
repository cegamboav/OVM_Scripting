#!/bin/bash

Change=$1
input_file=$2

## create folders
createtempfolder(){
	mkdir -p tmp_dir
}

create_server_file(){
	
	echo 'name' > tmp_dir/temp_server_file.csv
	echo $1 >> tmp_dir/temp_server_file.csv
}

check_servers(){
	clear
	echo "Collecting data ...."
	echo
	echo "Collecting Multipath information ..."
	echo
	for i in `cat $input_file|grep -v name`
	do
		echo "Creating file $i.mpl.txt"
		create_server_file $i
		java -jar /bin/tools/icmd/icmd-1.1.1.jar -e -cmd "sudo multipath -ll" -u iuxu -s tmp_dir/temp_server_file.csv -t $Change -cwd /usr/bin/ -sync -fq -n demo-exec1 |grep -v INFO > tmp_dir/$i.mpl.txt
	done
	echo "------------------------------------"
	echo "Collecting show maps status information ..."
	echo
	for i in `cat $input_file|grep -v name`
	do
		echo "Creating file $i.msps.txt"
		create_server_file $i
		java -jar /bin/tools/icmd/icmd-1.1.1.jar -e -cmd "sudo multipathd show maps status" -u iuxu -s tmp_dir/temp_server_file.csv -t $Change -cwd /usr/bin/ -sync -fq -n demo-exec1 |grep -v INFO > tmp_dir/$i.msps.txt
	done
	echo "------------------------------------"
	echo "Checking data ..."
	echo
	echo "=================================================" > data.txt
	for i in `cat $input_file|grep -v name`
	do
		has_ibm_luns=0
		has_ibm_luns=$(grep IBM tmp_dir/$i.mpl.txt|wc -l)
		if [ $has_ibm_luns -eq 0 ]
		then
			has_ibm_luns=0
		else
			echo $i >> data.txt
			echo '----------------------------------|------|------|' >> data.txt
			echo ' IBM LUNs                         | PATHS| SIZE' >> data.txt
			echo '----------------------------------|------|------|' >> data.txt
			egrep 'IBM' tmp_dir/$i.mpl.txt|awk '{print $1}' > tmp_dir/$i.mtp_luns.txt
			for j in `cat tmp_dir/$i.mtp_luns.txt`
			do	
				n=$(grep $j tmp_dir/$i.msps.txt|awk '{print $5}')
				m=$(grep $j tmp_dir/$i.mpl.txt -A 1|grep -v $j|awk '{print $1}'|cut -d '=' -f2)
				echo "$j |  $n   | $m" >> data.txt
			done
			echo "=================================================" >> data.txt
			echo "$i Contains IBM Luns information attached."
			
		fi
	done
	echo 
	echo '[OK] All the data has been proceeded, check the file data.txt'
	echo
}

##delete temporary file
delete_working_folder(){
	echo "Dumping data ..."
	echo > dump_data.txt
	for i in `ls tmp_dir/*.mpl.txt`
	do
		echo $i >> dump_data.txt
		echo "+++++++++" >> dump_data.txt
		cat $i >> dump_data.txt
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_data.txt
	done
	for i in `ls tmp_dir/*.msps.txt`
	do
		echo $i >> dump_data.txt
		echo "+++++++++" >> dump_data.txt
		cat $i >> dump_data.txt
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> dump_data.txt
	done
	rm -rf tmp_dir
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
		createtempfolder
		check_servers
		delete_working_folder
	fi
fi