#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@kyndryl.com>
# Purpose : This script used to apply a configuration file
# to allign the vcpus of the entire manager
###############################################################
## 22 March, 2022 : Created 
##
##
################################################################
##
#Variables:
#Variable to store the configuration .csv file
VCPU_file=$1
proceed=0
pass=0

get_an_answer(){
	vm_id=$1
	vcpu_start=$2
	vcpu_ends=$3
	answer=0
	
	while [ $answer -eq 0 ]
	do
		echo "Do you want to apply the following change?:"
		echo "VM_ID: $vm_id    From: $vcpu_start  to  $vcpu_ends"
		echo "Insert Y to proceed, N to not proceed and check the other VM or C to cancel!"
		read option
		case $option in
			"y"|"Y")
				proceed=1
				answer=1
				echo "==============================";;
			"n"|"N")
				proceed=0
				answer=1
				echo "==============================";;
			"c"|"C")
				proceed=-1
				answer=1;;
			*)
				echo "[Error] Insert Y, N or C!!!";;
		esac
	done
}


#Function to get the vcpu information of the vm:
collect_cpu(){
	start_cpu=$(cat $VCPU_file|grep $1|cut -d ',' -f3)
	end_cpu=$(cat $VCPU_file|grep $1|cut -d ',' -f4)
}

apply_change(){
	echo "Cambio aplicado"
}

do_the_tests(){
	pass=0
	clear
	echo "Start testing..."
	if [ -f "/home/iuxu/ovm-utils_2.1/ovm_vmcontrol" ]
		echo "  [OK] The ovm_vmcontrol file exist in the /home/iuxu/ovm-utils_2.1 directory."
		pass=1
	fi
}


read_file(){
	do_the_tests
	if [ pass -eq 1 ]
	then
		for i in $(cat $VCPU_file|cut -d ',' -f1)
		do
			var_lenght=${#i}
			if [ $var_lenght -eq 32 ]
			then
				collect_cpu $i
				proceed=0
				get_an_answer $i $start_cpu $end_cpu
				if [ $proceed -eq 1 ]
				then
					apply_change
				elif [ $proceed -eq -1 ]
				then
					exit 0
				fi
			fi
		done
	fi
}



if [ -z "$VCPU_file" ]
then
	clear
	echo "[Error] Insert the Change ID."
	echo
	echo "Example:"
	echo "bash check_paths_mhas.sh CHXXXXXXXXX hostp1.csv"
	echo
else
	if [ -f "$VCPU_file" ]; then
		clear
		read_file
	else
		echo "$VCPU_file No existe"
	fi
fi