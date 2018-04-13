#!/bin/bash

# Name        : queryOVMTable.sh
# Author      : david.cerdas  
# Version     : 0.1
# Copyright   : GPLv2
# Description : This script check the current status of the OVM_STATISTIC table,
#				and produces 3 output files: 1 with the OVM_STATISTIC characteristics,
# 				and 2 queries to this table, with 30 seconds of difference.
# Usage		: ./queryOVM_STATISTIC.sh <Password of the OVM Manager>


password=$1

# if there is not valid password given, request the customer to provide one
function case_null(){
	clear
	echo -e "Please run queryOVM_STATISTIC.sh again, but provide a valid password\n"
	echo "./queryOVM_STATISTIC.sh <Password of the OVM Manager>"
    exit 1
}


if [ "${password:-null}" != "null" ];then
	
	rm -fr /tmp/dataOVM_STATISTIC*.csv
	clear
	echo "Start collecting the data, this might take few minutes please wait ..."
	mysql -u root -p$password -S /u01/app/oracle/mysql/data/mysqld.sock -e "
	USE ovs;
	SHOW TABLES IN ovs LIKE 'OVM_STATISTIC';
	DESCRIBE OVM_STATISTIC;SHOW TABLE STATUS IN ovs LIKE 'OVM_STATISTIC';
	SELECT * FROM OVM_STATISTIC INTO OUTFILE '/tmp/dataOVM_STATISTIC1.csv' CHARACTER SET utf8  FIELDS TERMINATED BY ',' ENCLOSED BY '|' LINES TERMINATED BY '\r\n';
	SELECT NOW();
	SELECT COUNT(*) FROM OVM_STATISTIC;
	SELECT SLEEP(30);
	SELECT * FROM OVM_STATISTIC INTO OUTFILE '/tmp/dataOVM_STATISTIC2.csv' CHARACTER SET utf8 FIELDS TERMINATED BY ',' ENCLOSED BY '|' LINES TERMINATED BY '\r\n';
	SELECT NOW();
	SELECT COUNT(*) FROM OVM_STATISTIC;
	QUIT" &>/tmp/dataOVM_STATISTIC.status
    
	if [ "$?" -eq "0" ];then
		clear;echo "Done, thanks. Please provide the below files:"
		ls -1 /tmp/*OVM_STATISTIC*
	else
		echo "It was not possible to get the data"
	fi
	
else
	case_null
fi
