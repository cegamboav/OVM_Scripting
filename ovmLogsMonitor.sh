#!/bin/bash

# Name        	: ovmLogsMonitor.sh
# Author      	: david.cerdas@oracle.com
# Version     	: 1.0
# Copyright   	: GPLv2
# Description	: Oracle OVM Manager/OVS script to replicate an issue
#                This script is going to monitor with tail command the OVM Manager/OVS 
#                logs and insert start and stop statement between tests
#                Finally there is an option for collecting and compress the new logs generated

desire=$1

# Find the OVM type
if [ -e /etc/ovs-release ];then
	type="ovs"
elif [ -e `find /u01 -name .config 2>/dev/null` ];then 
	type="ovmm"
else
    echo "This is not an OVM Manager or OVS Server"
fi

case_null(){
    clear
	echo -e "\n Please run again the script using a valid option\n\n" 
    echo -e " .ovmLogsMonitor.sh <desire> <options/parameters> \n\n"
	echo -e "desire:"	
    echo "  m : For Monitoring"
    echo -e "\t./ovmLogsMonitor.sh monitor\n"
    echo "  c : For Collecting data"             
    echo -e "\t./ovmLogsMonitor.sh c \n"
    echo "  r : Run a manual test" 	
	echo "      ovmLogsMonitor.sh must be monitoring first" 	
	echo "      Use the same name for the test for start and stop" 		
    echo -e "\t./ovmLogsMonitor.sh runtest <testName> <start/stop> \n"
    echo "  o : Extract logs to output files" 
    echo -e "\t./ovmLogsMonitor.sh o <path where is the uncompressed .tar.gz> \n"	     
	echo ""
	exit 1
}

# Finish the script and terminates all subprocesses
XstopMonitoring(){
continue=wait
	while [ "$continue" = "wait" ];do
	    clear                             
		echo -e "-------------------------\n- Stop monitoring now ? -\n-------------------------------------------------------"
		echo -en "- Please write yes and enter when all tests were made -\n-------------------------------------------------------\n"
		read continue
		if [ "$continue" = "yes" ]||[ "$continue" = "y" ]||[ "$continue" = "YES" ]||[ "$continue" = "Y" ];then
			[ "$type" = "ovs" ]&&for log in $(ls -1 /tmp/logsOvsServer/*|egrep -v xFiles);do echo "Xstop_$monID" >> $log;done
			[ "$type" = "ovmm" ]&&for log in $(ls -1 /tmp/logsOvmManager/*|egrep -v xFiles);do echo "Xstop_$monID" >> $log;done			
		else
			 echo "$continue is not valid, please try with yes if you want to end the monitoring"  
			 continue="wait"
		fi
	done
 	clear
	# collect all the logs
	collectData
	# Terminante monitoring processes
    pkill -TERM -P $mypid 2>/dev/null
	clear                                                                      
	echo -e "\n`clear`\n--------------------------------------------------------------\n"
	echo -e "- Done, please attach the /tmp/logsOv*.tar.gz file to the SR - "
	echo -e "\n--------------------------------------------------------------\n`ls -1 /tmp/logsOv*`\n"
	echo " "
	exit 0	
}

# Initialize the script
XstartMonitoring(){
	# PID of this Script
	mypid=$$
	# initialize test counter 
	[ -e /tmp/testCounter.ovmLockM ]||echo "0" > /tmp/testCounter.ovmLockM
	testCounter=`cat /tmp/testCounter.ovmLockM`
	# Generates a new monitor id number, to differentiate tests at similar time.
	monID=`awk -v min=10 -v max=99 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`
	echo "$monID" > /tmp/monID.ovmLockM
    [ "$type" = "ovs" ]&&for log in $(ls -1 /tmp/logsOvsServer/*|egrep -v xFiles);do echo "Xstart_$monID" >> $log;done
	[ "$type" = "ovmm" ]&&for log in $(ls -1 /tmp/logsOvmManager/*|egrep -v xFiles);do echo "Xstart_$monID" >> $log;done
    
	# If desire is not menu option, then XstopMonitoring to monitor until user decides to stop monitoring
	if [ "$desire" != "menu" ];then
		XstopMonitoring
	fi
}

# run OvmLogTool.py and organize OVM Manager AdminServer logs
adminserver_py(){
	export PATH=$PATH:/usr/local/bin:/share/linuxtools/bin
	[ -d $pwdLogs/done/tmpX/ ]||mkdir `pwd`/done/tmpX/
	cd $pwdLogs/done/
	for adminlog in $(ls -1 *|egrep AdminServer.log);do
		mv $pwdLogs/done/$adminlog $pwdLogs/done/tmpX/AdminServer.log
		cd $pwdLogs/done/tmpX
		OvmLogTool.py -o $adminlog.filtered
		mv $pwdLogs/done/tmpX/$adminlog.filtered ../../$adminlog.filtered
		cd 	../
	done
	cd ..
	mv $pwdLogs/done/tmpX $pwdLogs/xFiles/.garbage/
}

# Puts each test in its correspond directory, or move to the garbage
finalClean(){
	for testidName in `cat $pwdLogs/idName.ovmLockM`;do
		mkdir $pwdLogs/done/$testidName
		for file in ` ls -1 $pwdLogs/| egrep $testidName`;do
			if [ `wc -l $pwdLogs/$file|cut -d' ' -f1` -le 2 ];then
				# if the wasn't logs collected then move the file to the garbage
				mv $pwdLogs/$file $pwdLogs/xFiles/.garbage/
			else
				mv $pwdLogs/$file $pwdLogs/done/$testidName/
			fi
		done
	done
	mv $pwdLogs/idName.ovmLockM $pwdLogs/xFiles/.garbage/
	mv $pwdLogs/*.$monID $pwdLogs/xFiles/.garbage/
	mv $pwdLogs/xFiles/.garbage/*.log  $pwdLogs/xFiles/
	mv $pwdLogs/done/* $pwdLogs/
}

# This function if for organize the extracted logs
organizer(){
	monID=`cat $pwdLogs/monID.ovmLockM`
	# cd to the directory that has the uncompressed OVM logs
	cd $pwdLogs
	# try to avoid running this script in a directory other than logsOv* 
	if [ -e $pwdLogs/testCounter.ovmLockM ];then
	    # make a hidden garbage directory
		mkdir $pwdLogs/xFiles/.garbage/
	    mv $pwdLogs/*.ovmLockM $pwdLogs/xFiles/.garbage/
		# make a working directory called done and idName.ovmLockM for finalClean()
		mkdir $pwdLogs/done
		touch $pwdLogs/done/idName.ovmLockM
		# Exception step in case someone puts a directory inside the collected file
		for dir in $(ls -d1 $pwdLogs/*|egrep -v "done|xFiles" );do [ -d $dir ]&& echo $dir&&mv $dir $pwdLogs/xFiles/;done
		# organize all log files filtered by tests
		if [ `ls -1 |egrep -v "done|xFiles"|wc -l` -gt 0 ];then
			for file in `ls -1|egrep -v "done|xFiles"`;do 
				for testStart in `egrep "Xstart_" $pwdLogs/$file|cut -d":" -f2|uniq`;do
					nameFile=`echo $testStart|sed 's/Xstart_//g'`
					testStop=`egrep "Xstop_.*$nameFile" $pwdLogs/$file|cut -d":" -f2|uniq`
					## If there isn't $testStop ( Xstop line) for the test, no action is taken
					[ -z "$testStop" ]||awk -vtestStart=$testStart -vtestStop=$testStop '$0==testStart { flag=1 } flag;$0==testStop  { flag=0 }' $pwdLogs/$file 2>/dev/null >> $pwdLogs/done/$file.$nameFile 
					# idName.ovmLockM fillup idName.ovmLockM for finalClean
					if [ "$nameFile" != "$monID" ];then
						idName=`echo $nameFile|awk -F"-" '{ print $2"-"$3}' 2>/dev/null `
						[ `egrep "$idName" $pwdLogs/done/idName.ovmLockM|wc -l` -eq 0 ]&&echo "$idName" >> $pwdLogs/done/idName.ovmLockM
					fi
				done
			done
			# move old logs to the garbage
			mv $pwdLogs/*.log  $pwdLogs/xFiles/.garbage/
		fi
		
		# In case of OVM Manager AdminServer.logs we need to run OvmLogTool.py
		if [ `ls -1 $pwdLogs/done/*|egrep AdminServer.log|wc -l` -gt 0 ];then
		   adminserver_py
		fi
		mv $pwdLogs/done/* $pwdLogs/
		finalClean
		mv  $pwdLogs/done $pwdLogs/xFiles/.garbage/
		clear
		echo -e "\n Check for the logs in: \n"
		echo "# cd $pwdLogs"
    else
	    echo -e "Error: Ensure to use the right path to the logs\n"
		case_null
	fi
	}

# For collecting the data after the tests are over
collectData(){
	# installation logs
		[ "$type" = "ovs" ]&&[ `ls -1tr /root/install.log* 2>/dev/null|tail -1|wc -l` -gt 0  ]&&cp -p `ls -1tr /root/install.log*|tail -1` /tmp/logsOvsServer/xFiles/ 
		[ "$type" = "ovmm" ]&&[ `ls -1tr /var/log/ovmm/* 2>/dev/null|tail -1|wc -l` -gt 0  ]&&cp -p `ls -1tr /var/log/ovmm/*|tail -1` /tmp/logsOvmManager/xFiles/  2>/dev/null
	if [ -d /tmp/logsOvmManager/ ];then
	    clear
		echo "Collecting the logs, then terminate the monitoring processes(tails)"
		cd /tmp/
		mv /tmp/*.ovmLockM /tmp/logsOvmManager/
		tar zcf logsOvmManager.`uname -n`.`date +"%d-%m-%Y"`.$monID.tar.gz  --remove-files logsOvmManager/
	elif [ -d /tmp/logsOvsServer/ ];then 
		echo "Collecting the logs, then terminate the monitoring processes(tails)"
		cd /tmp/
		mv /tmp/*.ovmLockM /tmp/logsOvsServer/
		tar zcf logsOvsServer.`uname -n`.`date +"%d-%m-%Y"`.$monID.tar.gz --remove-files logsOvsServer/  
	else
		echo "/tmp/logs_OV* does not exist, there is no logs to collect"
	fi
	
	
}
# For Monitoring the logs
monitorLogs(){
# Create the DC folder and start the monitoring of the files, also copy some known useful files into xFiles
	if [ "$type" = "ovmm" ];then
		[ -d /tmp/logsOvmManager/ ]||mkdir /tmp/logsOvmManager/
		[ -d /tmp/logsOvmManager/xFiles ]||mkdir /tmp/logsOvmManager/xFiles	
		tail -f /var/log/messages >> /tmp/logsOvmManager/messages.log &
		tail -f /var/log/dmesg >> /tmp/logsOvmManager/dmesg.log &
		tail -f /var/log/yum.log >> /tmp/logsOvmManager/yum.log &
		tail -f `find /u01 -name CLI.log` >> /tmp/logsOvmManager/CLI.log &
		tail -f `find /u01 -name AdminServer.log` >> /tmp/logsOvmManager/AdminServer.log &
		tail -f `find /u01 -name AdminServer-diagnostic.log` >> /tmp/logsOvmManager/AdminServer-diagnostic.log &
		tail -f `find /u01 -name AdminServer.out` >> /tmp/logsOvmManager/AdminServer.out.log &
		tail -f `find /u01 -name access.log` >> /tmp/logsOvmManager/access.log &
		elif [ "$type" = "ovs" ];then 
		[ -d /tmp/logsOvsServer/ ]||mkdir /tmp/logsOvsServer/
		[ -d /tmp/logsOvsServer/xFiles ]||mkdir /tmp/logsOvsServer/xFiles	
		tail -f /var/log/xen/xend.log >> /tmp/logsOvsServer/xend.log &
		tail -f /var/log/xen/xend-debug.log >> /tmp/logsOvsServer/xend-debug.log &
		tail -f /var/log/osc.log >> /tmp/logsOvsServer/osc.log &		
		tail -f /var/log/ovm-consoled.log >> /tmp/logsOvsServer/ovm-consoled.log &	
		tail -f /var/log/ovs-agent.log >> /tmp/logsOvsServer/ovs-agent.log &
		tail -f /var/log/ovmwatch.log >> /tmp/logsOvsServer/ovmwatch.log &
		tail -f /var/log/messages >> /tmp/logsOvsServer/messages.log &
		tail -f /var/log/dmesg >> /tmp/logsOvsServer/dmesg.log &		
		[ -e /var/log/yum.log ] && tail -f /var/log/yum.log >> /tmp/logsOvsServer/yum.log &
		[ -e /var/log/audit/audit.log ] && tail -f /var/log/audit/audit.log >> /tmp/logsOvsServer/audit.log &	
		[ -e /var/log/ovs-agent/ovs_root.log ]&&tail -f /var/log/ovs-agent/ovs_root.log >> /tmp/logsOvsServer/ovs_root.log &
		[ -e /root/upgrade.log ]&&cp /root/upgrade.log /tmp/logsOvsServer/xFiles/upgrade.log
	else 
	     echo "Error: Not able to start the monitoring"
		 case_null
	fi
	echo "-----------------------------------------------------------------------"

}

runningTest(){
	if [ "$trigger" = "start" ];then
        testCounter=`cat /tmp/testCounter.ovmLockM`
		# start run a test start
	    [ "$type" = "ovs" ]&&for log in $(ls -1 /tmp/logsOvsServer/*|egrep -v xFiles);do echo "Xstart_$monID-$testCounter-$testName" >> $log;done
		[ "$type" = "ovmm" ]&&for log in $(ls -1 /tmp/logsOvmManager/*|egrep -v xFiles);do echo "Xstart_$monID-$testCounter-$testName" >> $log;done
	elif [ "$trigger" = "stop" ];then 
		# check the last counter and then run a test stop
		testCounter=`cat /tmp/testCounter.ovmLockM`	
		[ "$type" = "ovs" ]&&for log in $(ls -1 /tmp/logsOvsServer/*|egrep -v xFiles);do echo "Xstop_$monID-$testCounter-$testName" >> $log;done
		[ "$type" = "ovmm" ]&&for log in $(ls -1 /tmp/logsOvmManager/*|egrep -v xFiles);do echo "Xstop_$monID-$testCounter-$testName" >> $log;done
		let "testCounter++"
		echo $testCounter >/tmp/testCounter.ovmLockM
	else
	    echo "Error: Please use a valid trigger, whether: start or stop"
	    case_null
    fi
}

menu(){
	echo "------------------------------------------------------------------"
	echo " OVM Logs Monitor with PID: $mypid and MonitorID: $monID			"
	echo "------------------------------------------------------------------"
	echo " Please write one of the below options and enter:					"
	echo "																	"
	echo "	s: Start new test												"
	echo "	p: stoP the test												"
	echo "	l: add a Line in the collected logs								"
	echo "	c: stop monitoring, and collect all the logs					"
	echo "------------------------------------------------------------------"
	read alternative
	clear
}	

# in case desire is Menu
desireMenu(){
	monitorLogs
	# call XstartMonitoring funtion for monitoring the test
	XstartMonitoring
	clear
	echo "------------------------------------------------------------------"
	echo "- Welcome 											   			"
	echo "------------------------------------------------------------------"
	menu
	while [ "$alternative" != "c" ]	;do
		case $alternative in 
			s|S|start|START)
				testName="test"
				trigger="start"
				runningTest
				clear
				echo "------------------------------------------------------------------"
				echo "- Test $testCounter 											   "
				echo "- Run the test, and next write p to stoP this test			   "
				echo "------------------------------------------------------------------"
				menu
				;;
			p|stop|STOP)
				testName="test"
				trigger="stop"
				runningTest
				clear
				echo "------------------------------------------------------------------"
				echo "- Test is done									                "
				echo "------------------------------------------------------------------"
				menu
				;;
			l|line|LINE)
				clear
				for logX in $(ls -1 /tmp/logsOv*/*|egrep -v xFiles);do 
					echo "-----------------------------------------------------" >> $logX
				done
				echo "------------------------------------------------------------------"
				echo "- Done, line was added in the collected logs					    "
				echo "------------------------------------------------------------------"
				menu
				;;
			*)
				clear
				echo "------------------------------------------------------------------"
				echo "- Value no valid: $alternative									"
				echo "- Please select a valid option from the menu						"
				echo "------------------------------------------------------------------"
				menu
				;;
		esac 
	done
	# Stop and collect the logs
	[ "$type" = "ovs" ]&&for log in $(ls -1 /tmp/logsOvsServer/*|egrep -v xFiles);do echo "Xstop_$monID" >> $log;done
	[ "$type" = "ovmm" ]&&for log in $(ls -1 /tmp/logsOvmManager/*|egrep -v xFiles);do echo "Xstop_$monID" >> $log;done	
	# collect all the logs
	collectData
	# Terminante monitoring processes
	pkill -TERM -P $mypid 2>/dev/null
	clear                                                                      
	echo -e "\n`clear`\n--------------------------------------------------------------\n"
	echo -e "- Done, please attach the /tmp/logsOv*.tar.gz file to the SR - "
	echo -e "\n--------------------------------------------------------------\n`ls -1 /tmp/logsOv*`\n"
	echo " "
	exit 0	
}


case $desire in
	menu)
		desireMenu
		;;
	monitor|m|M)
		clear
		monitorLogs
		# call XstartMonitoring funtion for monitoring the test
		XstartMonitoring	
		;;
	c|C)
		clear
		collectData
		;;
	runtest|r|R)
		# Take the test counter number from /tmp/testCounter.ovmLockM
		testCounter=`cat /tmp/testCounter.ovmLockM`
		testName=$2
		trigger=$3
		monID=`cat /tmp/monID.ovmLockM`

		runningTest
		;;
	organize|o|O)
		pwdLogs=$2
		clear
		# Organize the logs
		organizer
		
		if [ "$type" = "ovs" ];then
			hideGarbage
			echo -e "Check for the OVM Manager logs in: \n# cd `pwd`"
		fi
		;;
	*)
      case_null
	;;
esac
