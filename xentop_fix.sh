#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@kyndryl.com>
# Purpose : This script generate fixed xentop output
###############################################################
## 17 Nov, 2021 : Created 
##
################################################################
##
#
##Variables declared before start the program:
hour=$(date '+%H')
day=$(date '+%d')
output_doc=/var/log/oswatcher/archive/oswxentop_fix/a0001p5hovswc12_fixed_oswxentop_`date '+%y.%m.%d.%H'`00.dat

#function to insert the date in the file
insert_date(){
	echo "zzz ***"$(date) >> $output_doc
}

#function to count the amount of vms running in the server
get_RunningVMs(){
	RunningVMs=$(xm li|wc -l)
}

#function to obtain the data in the server
Obtain_xentop_information(){
	xentop -d 0.5 -i 2 -f -b > /var/log/oswatcher/archive/oswxentop_fix/xentop.out
}

#function to remove old data in the directory
remove_old_data(){
	#Get the total of data files in the directory
	totl_docs=$(ls /var/log/oswatcher/archive/oswxentop_fix/*.dat|wc -l)
	
	#if the server has more than 48 files
	if [ $totl_docs -gt 48 ]
	then
		#check how many files over 48 are there
		let old_files=$totl_docs-48
		#Then it start a loop to go through the files:
		for i in $(ls /var/log/oswatcher/archive/oswxentop_fix/*.dat|head -n $old_files)
		do
			#Then it remove the oldest files
			rm -f $i
		done
	fi
}

#function used to redefine the parameters of the script
redefine_parameters(){
	#set the new hour
	hour=$(date '+%H')
	#set the output file
	output_doc=/var/log/oswatcher/archive/oswxentop_fix/a0001p5hovswc12_fixed_oswxentop_`date '+%y.%m.%d.%H'`00.dat
	#Set the actual day
	actual_day=$(date '+%d')
	#if the actual parameter is different to the previous date day
	if [ $actual_day -ne $day ]
	then
		#clean the vm_names.txt file, to avoid contain information not required in that file
		echo > /var/log/oswatcher/archive/oswxentop_fix/vm_names.txt
	fi
	#Call the function to remove old data
	remove_old_data
}

find_vm_name(){
	#The script is going to find the name with the vm.cfg file
	vm_path=$(find /OVS/Repositories/ -name $1|grep -v snap)
	vm_name=$(cat $vm_path/vm.cfg|grep OVM_simple_name|cut -d "'" -f2)
	#and insert it in the vm_names.txt to future querys
	echo "$1 = $vm_name" >> /var/log/oswatcher/archive/oswxentop_fix/vm_names.txt
}

#function to obtain the name of a running vm:
get_VM_name(){
	#If the script is asking for the Domain-0 VM, it just define the same name
	if [[ $1 == "Domain-0" ]]
	then
		vm_name="Domain-0"
	else
		#Check if the file exists
		if [ -f /var/log/oswatcher/archive/oswxentop_fix/vm_names.txt ]
		then
			#Check if the vm name exist in the file
			vm_name_exist=$(grep $1 /var/log/oswatcher/archive/oswxentop_fix/vm_names.txt|wc -l)
			#if the value is 1, it exists
			if [ $vm_name_exist -eq 1 ]
			then
				#just takes the name from the file
				vm_name=$(grep $1 /var/log/oswatcher/archive/oswxentop_fix/vm_names.txt|cut -d "=" -f2) 
			#if not
			else
				#call find name function
				find_vm_name $1
			fi
		# if does not exist
		else
			#The script is going to create the file
			echo > /var/log/oswatcher/archive/oswxentop_fix/vm_names.txt
			#call find name function
			find_vm_name $1
		fi
	fi
}

#function used to print the data into the file
print_data(){
	get_VM_name $1
	printf "%-40s %-40s %-5s %-5s %-10s %-10s\n" $1 $vm_name $2 "%" $3 $4 >> $output_doc
}

#function used to print the header into the file
print_header(){
	printf "%-40s %-40s %-11s %-10s %-10s\n" $1 $2 $3 $4 $5 >> $output_doc
}

#function used to get the data obtain from xentop command
Analize_data(){
	#get the current hour
	actual_hour=$(date '+%H')
	
	# if actual_hour and hour are different
	if [ $actual_hour -ne $hour ]
	then
		#call redefine_parameters function
		redefine_parameters
	fi
	
	#Call the insert date function
	insert_date
	
	#call the print_header function
	print_header "VM_ID" "VM_Name" "CPU(%)" "VCPU" "Mem(%)"
	
	#Obtain the data from xentop command
	Obtain_xentop_information
	
	j=0
	
	#Get the amount of running VMs in the server
	get_RunningVMs

	#Get and print the data from the xentop.out file
	for i in $(cat /var/log/oswatcher/archive/oswxentop_fix/xentop.out|tail -n $RunningVMs|awk '{print $1,$4,$6,$9}'|grep -v NAME)
	do case $j in

			0)
				vm_id=$i
				((j++))
				;;

			1)
				cpu_average=$i
				((j++))
				;;

			2)
				mem=$i
				((j++))
				;;
			3)
				vcpu=$i
				j=0
				print_data $vm_id $cpu_average $vcpu $mem
				;;
		esac
	done
	echo "====================================" >> $output_doc
}

#function to check if the directory exist
check_directory(){
	#if the directory exist
	if [ -d /var/log/oswatcher/archive/oswxentop_fix ]
	then
		#Then clean the vm_names.txt file
		echo > /var/log/oswatcher/archive/oswxentop_fix/vm_names.txt
	else
		#If not it crates the directory and clean the vm_names.txt file
		mkdir -p /var/log/oswatcher/archive/oswxentop_fix
		echo > /var/log/oswatcher/archive/oswxentop_fix/vm_names.txt
	fi
}

#function to run as default
use_default_values(){
	interactions=20
	wait_time=180
	check_directory 
	start_program 24
}

#function to check if the parameters are numbers
test_parameter(){
	re='^[0-9]+$'
	if ! [[ $1 =~ $re ]] ; then
	   echo "Error: $1 Is not a number!!!" >&2; exit 1
	else
		continue_=1
	fi
}

#function to start the program
start_program(){
	Hours=$1
	
	#h is for the amount of hours to be running
	for h in $(eval echo {1..$Hours})
	do
		#and m for the amount of interactions 
		for m in $(eval echo {1..$interactions})
		do
			#call the Analize_data function
			Analize_data
			#Then sleep
			sleep $wait_time
		done
	done
}

#function to set the amount of interaction and sleep secs from the parameters
set_time(){
	option=$1
	case $option in
		#If option is 1, we are going to do 60 interaction and wait for 60 sec between interactions
		1) 
			interactions=60
			wait_time=60
		;;
		#If option is 2, we are going to do 30 interaction and wait for 120 sec between interactions
		2) 
			interactions=30
			wait_time=120
		;;
		#If option is 3, we are going to do 20 interaction and wait for 180 sec between interactions
		3) 
			interactions=20
			wait_time=180
		;;
		#If option is any other value, we are going to do 20 interaction and wait for 180 sec between interactions
		*) 
			interactions=20
			wait_time=180
		;;
	esac
}


#body of the script
#if the script does not have any parameter
if [ -z $1 ]
then
	#It is going to run for 24 hours, every 3 minutes
	use_default_values
else
	continue_=0
	#call the test_parameter function to see if the value inserted is a number
	test_parameter $1
	
	#If the value is a number
	if [ $continue_ -eq 1 ]
	then
		#checks if it have a second parameter
		if [ -z $2 ]
		then
			#If it does not have it use the default values:
			interactions=20
			wait_time=180
			check_directory 
			start_program $1
		else
			#If it caontains a second paramenter
			continue_=0
			#test if this is a number
			test_parameter $2
			
			#If the second paramenter is a number
			if [ $continue_ -eq 1 ]
			then
				#call the function to set the intervals
				set_time $2
				check_directory
				start_program $1
			else
				#If is not a number, it use the default parameters:
				interactions=20
				wait_time=180
				check_directory 
				start_program $1
			fi
		fi
	fi
fi