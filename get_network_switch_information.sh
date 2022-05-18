#!/usr/bin/env bash

# Name          : 
# Author        : carlos.gamboa@ibm.com
# Version       : 1.0
# Copyright     : GPLv2
# Description   : This script is used to get the Network informaiton of a server in MHAS
# Usage         : ./get_network_switch_information.sh
#
# Disclaimer           :
#
#Keep in mind that this is not part of an Oracle solution, hence its customization is not supported.
#Oracle support is not responsible for maintaining, troubleshooting, nor supporting this script.
#
#If you consider this sample script suitable to be used as a solution but require customization, we rather recommend that you engage with Oracle ACS.
#
#Oracle Consulting Services, http://www.oracle.com/us/products/consulting/overview/index.html
#
############################################################
bonds=()
option=0

fill_bonds_information(){
	for i in $(ls /proc/net/bonding/)
	do 
		bonds+=("$i")
	done
}

get_bond_information(){
	clear
	echo "Starting lldpad service ..."
	/etc/init.d/lldpad start
	echo
	echo "Waiting 40 secs to collect the data ..."
	sleep 40
	p=0
	echo "===================================================================================="
	for j in "${!bonds[@]}"
	do
		if [ $p -eq 0 ]
		then
			p=1
		else
			echo "===================================================================================="
		fi
		echo 
		echo ${bonds[$j]}
		interfaces=$(cat /proc/net/bonding/${bonds[$j]} |egrep 'Slave Interface'|cut -d ':' -f 2)
		o=0
		for i in $(echo $interfaces)
		do
			echo
			if [ $o -eq 0 ]
			then
				o=1
			else
				echo "----------------------------"
			fi
			echo "    $i:"
			lldptool -tni $i > /tmp/$i.output.txt
			swname=$(cat /tmp/$i.output.txt|egrep 'System Name TLV' -A 1|egrep -v 'System Name TLV')
			PortID=$(cat /tmp/$i.output.txt|egrep 'Port ID TLV' -A 1|egrep -v 'Port ID TLV'|cut -d ':' -f 2)
			PortDescription=$(cat /tmp/$i.output.txt|egrep 'Port Description TLV' -A 1|egrep -v 'Port Description TLV')
			echo "	Switch name: 	$swname"
			echo "	Port ID: 		$PortID"
			echo "	Port Description: $PortDescription"
			#rm -f /tmp/$i.output.txt
		done
	done
	echo "===================================================================================="
	echo
	echo "Stopping lldpad service ..."
	/etc/init.d/lldpad stop
}


fill_bonds_information
get_bond_information