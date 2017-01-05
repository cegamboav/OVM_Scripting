#!/bin/bash

# Oracle OVM Manager/OVS script to replicate an issue
# This script is going to monitor with tail command the OVM Manager/OVS logs and insert start and stop statement between tests
# Finally there is an option for collecting and compress the new logs generated
# Made by @DJCerdas

desire=$1
type=$2
test_name=$3
// PID of this Script
mypid=$$
// Generate a random number, to differentiate tests with the same name at similar time
randA=`awk -v min=10 -v max=99 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`

case_null(){
    clear
	echo "Please run again the script using a valid option" 
	echo ""
    echo -e " ./OVMManager_log.sh <desire> <OVM Type> <test_name> \n\n"
	echo "desire:"
    echo "       m : For Monitoring"
    echo "       c : For Collecting data" 
	echo "OVM Type:"
    echo "       ovmm : If you want to Monitor the OVM Manager"
    echo "       ovs  : If you want to Monitor the OVS Server - Dom0" 
	echo ""
	exit 1
}
stop_monitoring(){
continue="wait"

while [ "$continue" = "wait" ];do
    echo "Stop monitoring $test_name now ? yes/no"
    read continue
	if [ "$continue" = "yes" ]||[ "$continue" = "y" ]||[ "$continue" = "YES" ]||[ "$continue" = "Y" ];then
	    [ "$type" = "ovs" ]&&for log in $(ls -1 /tmp/logs_OVS_Server.`uname -n`/*);do echo "stop_$test_name.$randA" >> $log;done
		[ "$type" = "ovmm" ]&&for log in $(ls -1 /tmp/logs_OVM_Manager.`uname -n`/*);do echo "stop_$test_name.$randA" >> $log;done
		clear
    elif [ "$continue" = "no" ]||[ "$continue" = "n" ]||[ "$continue" = "NO" ]||[ "$continue" = "N" ] ;then
	     clear
	     echo "Ok, then wait until you hit yes to stop monitoring"
		 continue="wait"
	else
         echo "$continue is not valid, please try with yes or no, next press enter"  
		 continue="wait"
	fi
	
done
}

start_monitoring(){
continue="wait"

while [ "$continue" = "wait" ];do
    echo "Start monitoring $test_name now ? yes/no"
    read continue
	if [ "$continue" = "yes" ]||[ "$continue" = "y" ]||[ "$continue" = "YES" ]||[ "$continue" = "Y" ];then
	    [ "$type" = "ovs" ]&&for log in $(ls -1 /tmp/logs_OVS_Server.`uname -n`/*);do echo "start_$test_name.$randA" >> $log;done
		[ "$type" = "ovmm" ]&&for log in $(ls -1 /tmp/logs_OVM_Manager.`uname -n`/*);do echo "start_$test_name.$randA" >> $log;done
		clear
		stop_monitoring		
    elif [ "$continue" = "no" ]||[ "$continue" = "n" ]||[ "$continue" = "NO" ]||[ "$continue" = "N" ] ;then
	     echo "Exit because no monitoring is needed, if there was no data collected in /tmp/logs_OV* you might consider to remove the folder"
	else
	     clear
         echo "$continue is not valid, please try with yes or no, next press enter"  
		 continue="wait"
	fi
	
done
	
	echo "Terminanting monitoring processes"
    pkill -TERM -P $mypid 2>/dev/null
}

case $desire in
m|M)
    clear
	if [ "$type" = "ovmm" ];then
		echo "Creating the monitoring files in /tmp/logs_OVM_Manager.`uname -n`/"
		[ -d /tmp/logs_OVM_Manager.`uname -n`/ ]||mkdir /tmp/logs_OVM_Manager.`uname -n`/
		tail -f `find /u01 -name AdminServer.log` >> /tmp/logs_OVM_Manager.`uname -n`/AdminServer.log &
		tail -f `find /u01 -name AdminServer-diagnostic.log` >> /tmp/logs_OVM_Manager.`uname -n`/AdminServer-diagnostic.log &
		tail -f /var/log/messages >> /tmp/logs_OVM_Manager.`uname -n`/messages.log &
	elif [ "$type" = "ovs" ];then 
		[ -d /tmp/logs_OVS_Server.`uname -n`/ ]||mkdir /tmp/logs_OVS_Server.`uname -n`/
        tail -f /var/log/xen/xend.log >> /tmp/logs_OVS_Server.`uname -n`/xend.log &
        tail -f /var/log/xen/xend-debug.log >> /tmp/logs_OVS_Server.`uname -n`/xend-debug.log &
        tail -f /var/log/ovs-agent.log >> /tmp/logs_OVS_Server.`uname -n`/ovs-agent.log &
        tail -f /var/log/messages >> /tmp/logs_OVS_Server.`uname -n`/messages.log &
	else 
	     echo "OVM Type was not properly specified"
		 case_null
	fi
	echo "-----------------------------------------------------------------------"
	echo "-------------------------------------"
	// call start_monitoring funtion for monitoring the test
	start_monitoring	
	;;
c|C)
    clear
	if [ -d /tmp/logs_OVM_Manager.`uname -n`/ ];then
		echo "Collecting the content of /tmp/logs_OVM_Manager.`uname -n`/ ..."
		cd /tmp/
		tar zcf logs_OVM_Manager.tar.gz  ./logs_OVM_Manager.`uname -n`/
		rm -fr /tmp/logs_OVM_Manager.`uname -n`
		echo "Done, please attach the /tmp/logs_OVM_Manager.tar.gz file to the SR"
	elif [ -d /tmp/logs_OVS_Server.`uname -n`/ ];then 
		echo "Collecting the content of /tmp/logs_OVS_Server.`uname -n`/ ..."
		cd /tmp/
		tar zcf logs_OVS_Server.`uname -n`.tar.gz  ./logs_OVS_Server.`uname -n`/
		rm -fr /tmp/logs_OVS_Server.`uname -n`
		echo "Done, please attach the logs_OVS_Server.`uname -n`.tar.gz file to the SR"
	else
		echo "/tmp/logs_OV* does not exist, there is no logs to collect"
	fi
	;;
*)
    case_null
	;;
esac


// Just to manually check the OVM_Manager logs
# egrep "stop_$test_name" /tmp/logs_OVM_Manager.`uname -n`/*
# egrep "start_$test_name" /tmp/logs_OVM_Manager.`uname -n`/*
// Just to manually check the OVM_Manager logs
# egrep "stop_$test_name" /tmp/logs_OVS_Server.`uname -n`/*
# egrep "start_$test_name" /tmp/logs_OVS_Server.`uname -n`/*
