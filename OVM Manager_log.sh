#!/bin/bash

# OVM Manager script to replicate an issue

desire=$1
test_name=$2
mypid=$$

stop_monitoring(){
continue="wait"

while [ "$continue" = "wait" ];do
    echo "Stop monitoring $test_name now ? yes/no"
    read continue
	if [ "$continue" = "yes" ]||[ "$continue" = "y" ]||[ "$continue" = "YES" ]||[ "$continue" = "Y" ];then
	    for log in $(ls -1 /tmp/logs_OVM_Manager.`uname -n`/*);do echo "stop_$test_name" >> $log;done
		egrep "stop_$test_name" /tmp/logs_OVM_Manager.`uname -n`/*
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
	    for log in $(ls -1 /tmp/logs_OVM_Manager.`uname -n`/*);do echo "start_$test_name" >> $log;done
		egrep "start_$test_name" /tmp/logs_OVM_Manager.`uname -n`/*
		clear
		stop_monitoring		
    elif [ "$continue" = "no" ]||[ "$continue" = "n" ]||[ "$continue" = "NO" ]||[ "$continue" = "N" ] ;then
	     echo "Exit because no monitoring is needed, if there was no data collected in /tmp/logs_OVM_Manager.`uname -n`/ you might consider to remove it"
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
	echo "Creating the monitoring files in /tmp/logs_OVM_Manager.`uname -n`/"
    [ -d /tmp/logs_OVM_Manager.`uname -n`/ ]||mkdir /tmp/logs_OVM_Manager.`uname -n`/
    tail -f `find /u01 -name AdminServer.log` >> /tmp/logs_OVM_Manager.`uname -n`/AdminServer.log &
    tail -f `find /u01 -name AdminServer-diagnostic.log` >> /tmp/logs_OVM_Manager.`uname -n`/AdminServer-diagnostic.log &
    tail -f /var/log/messages >> /tmp/logs_OVM_Manager.`uname -n`/messages.log &
	echo "-----------------------------------------------------------------------"
	echo "-------------------------------------"
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
	else
		echo "/tmp/logs_OVM_Manager.`uname -n` does not exist, there is no logs to collect"
	fi
	;;
*)
    clear
	echo "Please run again the script using a valid option" 
	echo ""
    echo -e " ./OVMManager_log.sh <desire> <test_name> \n\n"
	echo "desire:"
    echo "m : For Monitoring"
    echo "c : For Collecting data" 
	echo ""
	;;
esac






 