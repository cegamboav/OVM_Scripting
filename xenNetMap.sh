#!/bin/bash
# Name        	: xenNetMap.sh
# Author      	: @djcerdas
# Version     	: 1.0
# Copyright   	: GPLv2
# Description	: This script helps to map the interfaces in xen bridge - OVM
# Usage		: ./xenNetMap.sh "<Path to the sosreport>"

sosreport=$1

# Array for each type of interface
eth=()
bond=()
vif=()
bridge=()
bondj=()

	
if [ -d $sosreport/sos_commands ];then
	[ -f $sosreport/sos_commands/ovm3/xm.list ]&&clear&&cat $sosreport/sos_commands/ovm3/xm.list 
	cd 	$sosreport/sos_commands/networking/

	# Create an Array for each type of interface
	for interface in $(egrep -v "link|inet|lo" ip_address|awk '{print $2}'|tr -d :);do 
		if	[[ ${interface} == *eth* ]]; then
				eth+=($interface)
		elif [[ ${interface} == *bond* ]]; then
				bond+=($interface)
		elif [[ ${interface} == *vif* ]]; then
				vif+=($interface)
		else 
				bridge+=($interface)
		fi
	done
	echo ----------------------------------------------------------------------------
	echo ----------------------------------------------------------------------------
	for bridgej in "${bridge[@]}";do
		# Obtain physical interfaces of a bridge 
		for bondj in "${bond[@]}"; do
			if [ $(egrep "$bondj.*$bridgej" ip_address|wc -l) -gt 0 ];then
			# array for the interfaces of the bond
				for subint in $(egrep "master $bondj" ip_address|awk '{ print $2}'|tr -d \: );do 
				bondjA+=($subint)
				done
			fi
			if [ $(egrep $bridgej  ip_address|grep $bondj|wc -l) -eq 1 ];then 
				# now check which vif are part of the bridge
				cont=0
				for vifj in "${vif[@]}";do
					if [ ${cont} -eq 0 ]&&[ $(egrep "$vifj.*$bridgej" ip_address|wc -l) -gt 0 ];then 
						echo "${bondjA[$cont]}	----	$bondj	----	$bridgej	----	$vifj"
						let "cont++"
					elif  [ ${cont} -gt 0 ]&&[ ${#bondjA[@]} -gt $cont ]&&[ $(egrep "$vifj.*$bridgej" ip_address|wc -l) -gt 0 ];then  
						echo "${bondjA[$cont]}	--|					|--	$vifj"
						let "cont++"							
					elif  [ ${cont} -gt 0 ]&&[ ${#bondjA[@]} -gt $cont ];then  
						echo "${bondjA[$cont]}	--|					"
						let "cont++"
					elif  [ ${cont} -gt 0 ]&&[ ${#bondjA[@]} -le $cont ]&& [ $(egrep "$vifj.*$bridgej" ip_address|wc -l) -gt 0 ];then                                    					
						echo "						|--	$vifj"
						let "cont++"
					fi
				done
				cont=0
				echo ----------------------------------------------------------------------------
			fi
		bondjA=()
		done
	done
else
	clear
   echo "Please specify a valid path to the sosreport"
   echo "Usage			: 						"
   echo ' ./xenNetMap.sh "<Path to the sosreport>"  '
fi
