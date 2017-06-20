#!/bin/bash

# Name        : ovmDBCheck.sh
# Author      : carlos.gamboa
# Version     : 1
# Copyright   : GPLv2
# Description : Oracle OVM Manager/OVS script to check the OVM Manager DB for known inconsistencies


adminLog=`find /u01 -name AdminServer.log`
echo $adminLog
	printf "Checking the backups:\n----------------------\n"
	printf "Last good backups:\n"
	grep backup $adminLog|grep complete|tail -5
	printf "\n----------------------\n"
	printf "Inconsistencies:\n"
	grep backup $adminLog|egrep inconsistencies|tail -5
	printf "\n\nDB issues:\n"
	printf "First messages:\n"
	grep 'odof.exception.ObjectNotFoundException' -B 1 $adminLog|head -6
	printf "\n\n"
	printf "Last messages:"
	egrep 'odof.exception.ObjectNotFoundException' -B 1 $adminLog|tail -6
	printf "\n----------------------\n"
