#!/bin/bash
# Name        	: monitorPidIo.sh
# Author      	: david.cerdas
# Version     	: 1.0
# Copyright   	: GPLv2
# Description	  : Monitor read and writes per second made by a process(PID) during 
# 				        specific time in seconds.
# Usage		      : ./monitorPidIo.sh <PID> <time in second>

pid=$1
time=$2
counter_w=$time
counter=0


clear
if [ "${pid:-null}" != "null" ]&&[ "${time:-null}" != "null" ];then
	if [ -d /proc/$pid ];then
		for i in `seq 1 $time`; do 
			[ -d /proc/$pid ]||exit 1
			clear
			echo "------------------------------------------------------"
			echo "-  Monitoring I/O of PID:$pid for $counter_w Seconds ..."
			echo "------------------------------------------------------"
			# fill up old_* and now_* variables to help to determine the total average write/read
			echo "=====Monitoring $(date)====" >>/tmp/$pid.io.txt
			old_write_bytes=$(tail -5 /tmp/$pid.io.txt|egrep -v cancelled| awk '/write_bytes/ { print $2;exit}' ) 
			old_read_bytes=$(tail -5 /tmp/$pid.io.txt| awk '/read_bytes/ { print $2;exit}' ) 
			cat  /proc/$pid/io >> /tmp/$pid.io.txt
			now_write_bytes=$(tail -5 /tmp/$pid.io.txt|egrep -v cancelled| awk '/write_bytes/ { print $2;exit}' ) 
			now_read_bytes=$(tail -5 /tmp/$pid.io.txt| awk '/read_bytes/ { print $2;exit}' ) 
			# average_write taken from the difference from old write_bytes minus current write_bytes
			average_write=$((now_write_bytes-old_write_bytes))
			# average_read taken from the difference from old read_bytes minus current read_bytes
			average_read=$((now_read_bytes-old_read_bytes))
			if [ "${old_write_bytes:-null}" != "null" ]&&[ "${old_read_bytes:-null}" != "null" ];then
				echo "average_write: $average_write" >> /tmp/$pid.io.txt
				echo "average_read: $average_read" >> /tmp/$pid.io.txt
				let "counter++"
			fi
			sleep 1
			let "counter_w--"
		done
		clear
		echo "------------------------------------------------------"
		echo "-Done: More details are in the /tmp/$pid.io.txt file.-"
		echo "------------------------------------------------------"
		# print the total average read 
		awk -vtotaltest=${counter} '/average_read/ {sum+= $2} END {print "On average read :"(((sum/(totaltest))/1024)/1024)"MB/s"}'  /tmp/$pid.io.txt
		# print the total average write 
		awk -vtotaltest=${counter} '/average_write/ {sum+= $2} END {print "On average write :"(((sum/(totaltest))/1024)/1024)"MB/s"}'  /tmp/$pid.io.txt
	else
		clear
		echo 'Please verify the syntax of the command, in special the PID'
		echo './monitorPidIo.sh <PID> <time in second>'
		exit 1
	fi
else
	clear
	echo 'Please verify the syntax of the command'
	echo './monitorPidIo.sh <PID> <time in second>'
	exit 1
fi
