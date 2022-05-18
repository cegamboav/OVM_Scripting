#!/bin/bash

input_file=$1
output_file=$2


check_servers(){
	clear;java -jar /bin/tools/icmd/icmd-1.1.1.jar -e -cmd "echo 'Server name:';hostname;echo;echo VM List;sudo xm vcpu-list;echo;echo Dom0:;lscpu|grep 'CPU(s):'|grep -v NUMA;echo;echo 'Total CPUs:';sudo xm info|grep nr_cpus|cut -d ':' -f2;echo '==================================='" -u iuxu -s $input_file -t CHG0185741 -cwd /usr/bin/ -sync -fq -n demo-exec1 |grep -v INFO > ~/$input_file.txt
	cat ~/$input_file.txt|egrep -v Domain-0|awk '{print $1,$2,$7}'|uniq|tee $output_file
}

if [ -z "$input_file" ]
then
	clear
	echo "[Error] You need to specify an input file."
	echo
	echo "Example: bash get_vcpu_infor.sh servers.csv output_file.txt"
else
	if [ -z "$output_file" ]
	then
		clear
		echo "[Error] You need to specify an output file."
		echo
		echo "Example: bash get_vcpu_infor.sh servers.csv output_file.txt"
	else
		check_servers
	fi
fi
