
#!/bin/bash

# Oracle OVM Manager/OVS script to replicate an issue
# This script is going to monitor with tail command the OVM Manager/OVS logs and insert start and stop statement between tests
# Finally there is an option for collecting and compress the new logs generated
# Made by @DJCerdas

desire=$1
test_name=$2
trigger=$3
# PID of this Script
mypid=$$
# Generates a random number, to differentiate tests with the same name at similar time
randA=`awk -v min=10 -v max=99 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`

# Find the OVM type
if [ -f /etc/ovs-release ];then
	type="ovs"
elif [ -f `find /u01 -name .config 2>/dev/null` ];then 
	type="ovmm"
else
    echo "This is not an OVM Manager or OVS Server"
fi

case_null(){
    clear
	echo -e "\n Please run again the script using a valid option\n\n" 
    echo -e " .OVM_logsMonitor.sh <desire> <options/parameters> \n\n"
	echo -e "desire:"	
    echo "  m : For Monitoring"
    echo -e "\t./OVM_logsMonitor.sh m <test_name>  \n"
    echo "  c : For Collecting data"             
    echo -e "\t./OVM_logsMonitor.sh c \n"
    echo "  r : Run a manual test" 	
	echo "      OVM_logsMonitor.sh must be monitoring first" 	
	echo "      Use the same name for the test for start and stop" 		
    echo -e "\t./OVM_logsMonitor.sh r <test_name> <start/stop> \n"
    echo "  o : Extract logs to output files" 
    echo -e "\t./OVM_logsMonitor.sh o <path where is the .tar.gz> \n"	     
	echo ""
	exit 1
}

Xstop_monitoring(){
continue="wait"

while [ "$continue" = "wait" ];do
    echo "Stop monitoring now ? yes/no"
    read continue
	if [ "$continue" = "yes" ]||[ "$continue" = "y" ]||[ "$continue" = "YES" ]||[ "$continue" = "Y" ];then
	    [ "$type" = "ovs" ]&&for log in $(ls -1 /tmp/logs_OVS_Server.`uname -n`/*);do echo "Xstop_$test_name.$randA" >> $log;done
	    [ "$type" = "ovmm" ]&&[ -f `ls -1tr /var/log/ovmm/*|tail -1` ]&&cp -p `ls -1tr /var/log/ovmm/*|tail -1`/tmp/logs_OVS_Server.`uname -n`/
	    [ "$type" = "ovmm" ]&&for log in $(ls -1 /tmp/logs_OVM_Manager.`uname -n`/*);do echo "Xstop_$test_name.$randA" >> $log;done
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

Xstart_monitoring(){
continue="wait"

while [ "$continue" = "wait" ];do
    echo "Start monitoring now ? yes/no"
    read continue
	if [ "$continue" = "yes" ]||[ "$continue" = "y" ]||[ "$continue" = "YES" ]||[ "$continue" = "Y" ];then
	    [ "$type" = "ovs" ]&&for log in $(ls -1 /tmp/logs_OVS_Server.`uname -n`/*);do echo "Xstart_$test_name.$randA" >> $log;done
		[ "$type" = "ovmm" ]&&for log in $(ls -1 /tmp/logs_OVM_Manager.`uname -n`/*);do echo "Xstart_$test_name.$randA" >> $log;done
		clear
		Xstop_monitoring
    elif [ "$continue" = "no" ]||[ "$continue" = "n" ]||[ "$continue" = "NO" ]||[ "$continue" = "N" ] ;then
	     echo "Exit because no monitoring is needed, if there was no data collected in /tmp/logs_OV* you might consider to remove the folder"
	else
	     clear
         echo "$continue is not valid, please try with yes or no, next press enter"  
		 continue="wait"
	fi
	
done
	
	echo "Terminanting monitoring processes"
    pkill -TERM -P $mypid &>/dev/null
	clear
	exit 0
}
## This function if for organize the extracted logs
organizer(){
pwd
mkdir ./done
for file in `ls -1|egrep -v done`;do 
	for test_start in `egrep "Xstart_" ./$file|cut -d":" -f2|uniq`;do
		name_file=`echo $test_start|sed 's/Xstart_//g'`
		test_stop=`tac ./$file|egrep "Xstop_.*$name_file"|cut -d":" -f2|uniq`
		## If there isn't end file will not be generated
		[ -z "$test_stop" ]||awk -vtest_start=$test_start -vtest_stop=$test_stop '$0==test_start { flag=1 } flag;$0==test_stop  { flag=0 }' ./$file >> `pwd`/done/$file.$name_file
	done
done
mkdir ./.old_logs/
mv ./*.log  ./.old_logs/
}

## confirm test_name is not empty
# [ -z $test_name ]&&case_null

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
		tail -f /var/log/dmesg >> /tmp/logs_OVS_Server.`uname -n`/dmesg.log &
		[ -f /var/log/ovs-agent/ovs_root.log ]&&tail -f /var/log/ovs-agent/ovs_root.log >> /tmp/logs_OVS_Server.`uname -n`/ovs_root.log &
	else 
	     echo "OVM Type was not properly specified"
		 case_null
	fi
	echo "-----------------------------------------------------------------------"
	echo "-------------------------------------"
	# call Xstart_monitoring funtion for monitoring the test
	Xstart_monitoring	
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
		echo "Done, please attach the /tmp/logs_OVS_Server.`uname -n`.tar.gz file to the SR"
	else
		echo "/tmp/logs_OV* does not exist, there is no logs to collect"
	fi
	;;
r|R)
	if [ "$trigger" = "start" ];then
	    [ "$type" = "ovs" ]&&for log in $(ls -1 /tmp/logs_OVS_Server.`uname -n`/*);do echo "Xstart_$test_name" >> $log;done
		[ "$type" = "ovmm" ]&&for log in $(ls -1 /tmp/logs_OVM_Manager.`uname -n`/*);do echo "Xstart_$test_name" >> $log;done
	elif [ "$trigger" = "stop" ];then 
	    [ "$type" = "ovs" ]&&for log in $(ls -1 /tmp/logs_OVS_Server.`uname -n`/*);do echo "Xstop_$test_name" >> $log;done
		[ "$type" = "ovmm" ]&&for log in $(ls -1 /tmp/logs_OVM_Manager.`uname -n`/*);do echo "Xstop_$test_name" >> $log;done
	else
	    case_null
    fi
	;;
o|O)
    clear
	cd $2
	if [ -f logs_OVM_Manager.tar.gz ];then
		echo "Decompressing logs_OVM_Manager.tar.gz ..."
		tar xf logs_OVM_Manager.tar.gz
		cd logs_OVM_Manager*
		organizer
		export PATH=$PATH:/usr/local/bin:/share/linuxtools/bin
		mkdir `pwd`/done/tmp
		cd `pwd`/done/
		## To filter AdminServer.log
		for adminlog in $(ls -1 *|egrep AdminServer.log);do
			mv ./$adminlog ./tmp/
			cd ./tmp
			OvmLogTool.py -o $adminlog.filtered
            mv ./$adminlog.filtered ../../$adminlog.filtered
            cd 	../
		done
		rm -fr ./tmp
		cd ..&&mv ./done/* .
		rm ./done -fr

		echo "Done, files are decompressed"
		pwd
	elif [ -f logs_OVS_Server.* ];then 
		echo "Decompressing /tmp/logs_OVS_Server.* ..."
		tar xf logs_OVS_Server.*
		cd logs_OVS_Server.*
		organizer
		mv ./done/* .
		rm ./done -fr
		echo "Done, files are decompressed"
        pwd		
	else
	    case_null
	fi
	;;
*)
      case_null
	;;
esac


# Just to manually check the OVM_Manager logs
# egrep "Xstop_$test_name" /tmp/logs_OVM_Manager.`uname -n`/*
# egrep "Xstart_$test_name" /tmp/logs_OVM_Manager.`uname -n`/*
# Just to manually check the OVM_Manager logs
# egrep "Xstop_$test_name" /tmp/logs_OVS_Server.`uname -n`/*
# egrep "Xstart_$test_name" /tmp/logs_OVS_Server.`uname -n`/*

# + Example of its use:
# [root@server3 ~]# mkdir /tmp/delete_me
# [root@server3 ~]# cd /tmp/delete_me
# [root@server3 delete_me]# vi OVM_logsMonitor.sh
# [root@server3 delete_me]# chmod +x OVM_logsMonitor.sh
# [root@server3 delete_me]# ./OVM_logsMonitor.sh
# Please run again the script using a valid option

# .OVM_logsMonitor.sh <desire> <OVM Type> <test_name>
# desire:
       # m : For Monitoring
       # c : For Collecting data
# OVM Type:
       # ovmm : If you want to Monitor the OVM Manager
# ovs  : If you want to Monitor the OVS Server - Dom0

# [root@server3 delete_me]# ./OVM_logsMonitor.sh m  ovs test1
# -----------------------------------------------------------------------
# -------------------------------------
# Start monitoring test1 now ? yes/no
# yes
# <Here your replicate the issue>
# Stop monitoring test1 now ? yes/no
# yes
# Terminanting monitoring processes
# ./OVM_logsMonitor.sh: line 52:  4174 Terminated              tail -f /var/log/xen/xend.log >> /tmp/logs_OVS_Server.`uname -n`/xend.log
# [root@server3 delete_me]# ./OVM_logsMonitor.sh c
# Collecting the content of /tmp/logs_OVS_Server.server3.cr.oracle.com/ ...
# Done, please attach the /tmp/logs_OVS_Server.server3.cr.oracle.com.tar.gz file to the SR
