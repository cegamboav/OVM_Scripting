#!/bin/bash

# Name        : ovmDBCheck.sh
# Author      : carlos.gamboa , david.cerdas  
# Version     : 1
# Copyright   : GPLv2
# Description : Oracle OVM Manager/OVS script to check the OVM Manager DB for known inconsistencies


adminLog=`find /u01 -name AdminServer.log`
echo $adminLog
printf "\nChecking the backups:\n----------------------\n"
printf "Last complete backups:\n"
grep backup $adminLog|grep complete|tail -5
printf "\n----------------------\n"
printf "Inconsistencies:\n"
grep backup $adminLog|egrep inconsistencies|tail -5
printf "\n----------------------\n"
printf "DB issues:\n"
printf "\nFirst messages:\n"
grep 'odof.exception.ObjectNotFoundException' -B 1 $adminLog|head -6
printf "\n--------------\n"
printf "\nLast messages:\n"
egrep 'odof.exception.ObjectNotFoundException' -B 1 $adminLog|tail -6
printf "\n----------------------\n"
egrep "Not enough disk space" $adminLog|head -n2
