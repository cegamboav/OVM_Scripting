#! /bin/sh
#################################################################
# Author : Kaushal Mishra <kmishra2@in.ibm.com>
# Purpose : This script generate capacity data of HVs 
###############################################################
## 28 Oct, 2020 : Created 
## 22 Sep, 2021 : Modified by Carlos Gamboa
##
################################################################
##
#

find /monitor/ovmm_script/cpupindata/ -mtime +90 -name '*repoutilization*.txt' -exec rm {} \;

ovmclicmd="/usr/local/sbin/ovmcli"
HOSTNAmE=`uname -a |awk '{print $2}' | tr 'A-Z' 'a-z'`
Outfile=/monitor/ovmm_script/cpupindata/"${HOSTNAmE}_cpupin_`date +"%Y-%m-%d-%T"`.txt"

insert_head_server(){
	#Insert title:
	echo "HV_Name;CPUs_on_HV;CPU_PIN;Nr_CPUs_Used;CPU_Ends" >> ${Outfile}
}

insert_head_vm() {
	#Insert title:
	echo "VM_Name;Configured_CPUs;CPU_Start;CPU_Ends" >> ${Outfile}
}


get_information_server(){
	server_name=$1
	#spol=$($ovmclicmd "show server name=${server_name}" |grep -i pool |awk -F '[' '{print $2}'|sed -e 's/]//g')
	Tot_cpu=$(ssh -o PasswordAuthentication=no iuxu@${server_name} "sudo xm info" |grep -i nr_cpus |awk -F ':' '{print $2}')
	nm_cpus_pinned=$(ssh -o PasswordAuthentication=no iuxu@${server_name} "sudo xm vcpu-list" |grep Domain|wc -l)
	last_cpu=$(ssh -o PasswordAuthentication=no iuxu@${server_name} "sudo xm vcpu-list" |grep Domain|tail -n 1|awk '{print $7}')
	usedcpu1=$(ssh -o PasswordAuthentication=no iuxu@${xx} "sudo xm list |grep -v -E 'Name|Domain'" |awk '{ sum+=$4} END {print sum}')
	insert_head_server
	echo "${server_name};${Tot_cpu};$nm_cpus_pinned;$usedcpu1;$last_cpu" >> ${Outfile}
	echo "-----------------;-----------------;-----------------;-----------------;-----------------" >> ${Outfile}
}

for xx in $($ovmclicmd "list server" |grep -i id |awk -F 'name:' '{print $2}' |sort)
#for xx in a0001p5hovsp103
do
	get_information_server $xx
	insert_head_vm
	for xy in $(ssh -o PasswordAuthentication=no iuxu@${xx} "sudo xm vcpu-list" |grep -v -E 'Name|Domain'|sort -k 7|awk '{print $1}'|uniq)
	do
		vmcpu=$(ssh -o PasswordAuthentication=no iuxu@${xx} "sudo xm list ${xy}" |grep -v -E 'Name' |awk '{print $4}')
		vmpin_start=$(ssh -o PasswordAuthentication=no iuxu@${xx} "sudo xm vcpu-list ${xy}" |grep -v Name |awk '{print $7}' |uniq|cut -d '-' -f1)
		vmpin_ends=$(ssh -o PasswordAuthentication=no iuxu@${xx} "sudo xm vcpu-list ${xy}" |grep -v Name |awk '{print $7}' |uniq|cut -d '-' -f2)
		vmnm=$($ovmclicmd "show vm id=${xy}" |grep -i name |awk -F '=' '{print $2}')
		Tot_thrd=$(ssh -o PasswordAuthentication=no iuxu@${xx} "sudo xm info" |grep -i threads_per_core |awk -F ':' '{print $2}')
		if [[ ${Tot_thrd} -eq 1 ]]
		  then
			if [[ ${Tot_cpu} -eq 16 ]]
				then
				 dom0cpu=2
		#         echo "$dom0cpu"
			else if [[ ${Tot_cpu} -eq 28 ]]
				then
				 dom0cpu=3
		 #        echo "$dom0cpu"
			else if [[ ${Tot_cpu} -gt 32 ]]
				then
				 dom0cpu=4
		#         echo "$dom0cpu"
				 fi
			  fi
			fi
		else 
			if [[ ${Tot_cpu} -eq 32 ]]
				then
				 dom0cpu=4
		#         echo "$dom0cpu"
			else if [[ ${Tot_cpu} -eq 56 ]]
				then
				 dom0cpu=6
		#         echo "$dom0cpu"
			else if [[ ${Tot_cpu} -gt 56 ]]
				then
				 dom0cpu=8
		 #        echo "$dom0cpu"
				 fi
			  fi
			fi
		fi
		usedcpu=$(expr $usedcpu1 + $dom0cpu)
		echo "${vmnm};${vmcpu};${vmpin_start};${vmpin_ends};" >> ${Outfile}
	done
	echo "=================;=================;=================;=================;=================" >> ${Outfile}
done
#echo -e  "Hello Team\n\nPlease find attached CPU pinning Report from SL DAL  guest vms. \n \n\nThanks & Regards \n\nCapacity Admin" | mailx -a ${Outfile} -r no-reply@in.ibm.com -s "OVM CPU Pin Report for SL DAL"  kmishra2@in.ibm.com yogthapa@in.ibm.com

Insert_DC_name(){
	if [[ ${HOSTNAmE} = a0001p5oovme101 ]];then
			DC="WDC04 (EAST)"
	elif [[ ${HOSTNAmE} = a0001p5oovmw101 ]];then
			DC="DAL10 (WEST)"
	elif [[ ${HOSTNAmE} = a0001p5oovml101 ]];then
			DC="London"
	elif [[ ${HOSTNAmE} = a0001p5oovmf101 ]];then
			DC="FRA04"
	elif [[ ${HOSTNAmE} = a0001p5oovmt101 ]];then
			DC="Tokyo"
	elif [[ ${HOSTNAmE} = a0001p5oovmm101 ]];then
			DC="MEL01"
	elif [[ ${HOSTNAmE} = a0001p5oovmt201 ]];then
			DC="Tokyo 05"
	elif [[ ${HOSTNAmE} = a0001o5oovmec01 ]];then
			DC="WDC04-VDC"
	elif [[ ${HOSTNAmE} = a0001o5oovmwc01 ]];then
			DC="DAL-VDC"
	elif [[ ${HOSTNAmE} = a0001o5oovmfc01 ]];then
			DC="FRA04-VDC"
	elif [[ ${HOSTNAmE} = a0001o5oovmlc01 ]];then
			DC="LON06"
	fi
}

Insert_DC_name

#echo -e  "Hello Team\n\nPlease find attached CPU Pining Report for ${DC}  guest vms. \n \n\nThanks & Regards \n OVM Admin" | mailx -a ${Outfile} -r no-reply@in.ibm.com -s "CPU Pinning Report for ${DC}"  kaushal.mishra@kyndryl.com,DG-ADAI-OracleFND-OVM@Kyndryl.com
echo -e  "Hello Team\n\nPlease find attached CPU Pining Report for ${DC}  guest vms. \n \n\nThanks & Regards \n OVM Admin" | mailx -a ${Outfile} -r no-reply@in.ibm.com -s "CPU Pinning Report for ${DC}"  carlos.gamboa@kyndryl.com