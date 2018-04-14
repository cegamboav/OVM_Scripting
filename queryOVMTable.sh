#!/bin/bash

# Name        : queryOVMTable.sh
# Author      : david.cerdas  
# Version     : 1.0
# Copyright   : GPLv2
# Description : This script checks the current status of a
#				table in the OVM Manager MySQL DataBase.
# Usage		: ./queryOVMTable.sh <Password of the OVM Manager>

dir="/tmp"
password=$1

function mysql_files(){
	if [ -d /var/lib/mysql-files ];then
		chmod 750 /var/lib/mysql-files/
	fi
}

# if there is not valid password given, request the customer to provide one
function case_null(){
	clear
	echo -e "Please run queryOVMTable.sh again, but provide a valid password\n"
	echo "./queryOVMTable.sh <Password of the OVM Manager>"
    exit 1
}

if [ "${password:-null}" != "null" ];then

	# use /var/lib/mysql-files/ to save the output files if this dir exists
	if [ -d /var/lib/mysql-files ];then
		dir="/var/lib/mysql-files"
		chmod 757 /var/lib/mysql-files/
	fi

	rm -fr $dir/OVM_STATISTIC_QUERY*
	clear&&echo -e "Start collecting the data, this might take few minutes please wait ...\n\n"
	# describe the table and export the queries to OVM_STATISTIC_QUERY*.csv files
	mysql -u root -p$password -S /u01/app/oracle/mysql/data/mysqld.sock -e "
	USE ovs;
	SHOW TABLES IN ovs LIKE 'OVM_STATISTIC';
	DESCRIBE OVM_STATISTIC;
	SHOW TABLE STATUS IN ovs LIKE 'OVM_STATISTIC';
	SELECT * FROM OVM_STATISTIC INTO OUTFILE '$dir/OVM_STATISTIC_QUERY1.csv' CHARACTER SET utf8  FIELDS TERMINATED BY ',' ENCLOSED BY '|' LINES TERMINATED BY '\r\n';
	SELECT NOW();
	SELECT COUNT(*) FROM OVM_STATISTIC;
	SELECT SLEEP(15);
	SELECT * FROM OVM_STATISTIC INTO OUTFILE '$dir/OVM_STATISTIC_QUERY2.csv' CHARACTER SET utf8 FIELDS TERMINATED BY ',' ENCLOSED BY '|' LINES TERMINATED BY '\r\n';
	SELECT NOW();
	SELECT COUNT(*) FROM OVM_STATISTIC;
	QUIT"
	# Export the schema of the OVM_STATISTIC table, without any data.
	mysqldump -u root -p$password -S /u01/app/oracle/mysql/data/mysqld.sock --no-data ovs OVM_STATISTIC 2>/dev/null|egrep -v "40*|--|^$" > $dir/OVM_STATISTIC_QUERY_TABLE.sql
    # Export the current ovs DB to a compressed .sql file
	mysqldump -u root -p$password ovs 2>/dev/null| gzip > $dir/OVM_STATISTIC_QUERY_OVS_DB.sql.gz
	
	if [ "$?" -eq "0" ];then
		mysql_files
		echo -e "\n-----------------------------------------------------------------------------"
		echo -e "Done, thanks.\nPlease provide the output in this terminal with the below file:"
		echo -e "-----------------------------------------------------------------------------\n"
		tar zcf /tmp/OVM_STATISTIC.`date +"%d-%m-%Y"`.tar.gz $dir/OVM_STATISTIC_QUERY* 2>/dev/null
		rm -fr $dir/OVM_STATISTIC_QUERY*
		ls -1 /tmp/OVM_STATISTIC.`date +"%d-%m-%Y"`.tar.gz
	else
		mysql_files
		echo "It was not possible to collect the data"
	fi
	
else
	case_null
fi
