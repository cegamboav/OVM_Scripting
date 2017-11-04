#!/bin/bash
# Name        	: xenNetMap.sh
# Author      	: @djcerdas
# Version     	: 0.2
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
	for interface in $(egrep -v "link|inet|lo|forever" ip_address|awk '{print $2}'|tr -d :);do 
		if	[[ ${interface} == *eth* ]]; then
				eth+=($interface)
		elif [[ ${interface} == *bond* ]]; then
			if [ $(echo ${interface}|egrep '@'|wc -l) -eq 1 ];then
				bondV+=($interface)	
			else
				bond+=($interface)				
			fi	
		elif [[ ${interface} == *vif* ]]; then
				vif+=($interface)
		else 
				bridge+=($interface)
		fi
	done
	echo -----------------------------------------------------------------------------------------------
	echo -----------------------------------------------------------------------------------------------
	cont=0
	for bridgej in "${bridge[@]}";do
		# Obtain physical interfaces of a bridge 
		for bondj in "${bond[@]}"; do
			if [ $(egrep "$bondj.*$bridgej" ip_address|wc -l) -gt 0 ];then
				# array for the interfaces of the bond
				for subint in $(egrep "master $bondj" ip_address|awk '{ print $2}'|tr -d \: );do 
					bondjA+=($subint)
				done
			fi
				for vlan in  "${bondV[@]}";do				 
					# now check which vif are part of the bridge
					for vifj in "${vif[@]}";do
						# prints whole line that was mapped
						if [ ${cont} -eq 0 ]&&[ $(egrep "$vifj.*$bridgej" ip_address|wc -l) -gt 0 ]&&[ $(echo $vlan|egrep ${bondj[$cont]}|wc -l) -gt 0 ]&&[ $(egrep "$vlan.*$bridgej" ip_address|wc -l) -gt 0 ];then 
							echo -----------------------------------------------------------------------------------------------
							echo "${bondjA[$cont]}	----	$bondj	----	$vlan	----	$bridgej	----	$vifj"
							let "cont++"				
						elif  [ ${cont} -gt 0 ]&&[ ${#bondjA[@]} -gt $cont ]&&[ $(egrep "$vifj.*$bridgej" ip_address|wc -l) -gt 0 ];then  
							echo "${bondjA[$cont]}	--|								|--	$vifj"
							let "cont++"							
						elif  [ ${cont} -gt 0 ]&&[ ${#bondjA[@]} -gt $cont ];then  
							echo "${bondjA[$cont]}	--|					"
							let "cont++"
						elif  [ ${cont} -gt 0 ]&&[ ${#bondjA[@]} -le $cont ]&& [ $(egrep "$vifj.*$bridgej" ip_address|wc -l) -gt 0 ]&&[ $(egrep "$vlan.*$bridgej" ip_address|wc -l) -gt 0 ];then                                    					
							echo "						|--	$vifj"
							let "cont++"
						# If the bridge has no vif associated
						elif [ ${cont} -eq 0 ]&&[ $(echo $vlan|egrep ${bondj[$cont]}|wc -l) -gt 0 ]&&[ $(egrep "$vlan.*$bridgej" ip_address|wc -l) -gt 0 ]&&[ $(egrep "$bridgej" ip_address|egrep vif|wc -l) -eq 0 ];then   
							echo -----------------------------------------------------------------------------------------------
							echo "${bondjA[$cont]}	----	$bondj	----	$vlan	----	$bridgej	----"
							let "cont++"	
						elif [ ${cont} -gt 0 ]&&[ ${#bondjA[@]} -gt $cont ]&&[ $(egrep "$bridgej" ip_address|egrep vif|wc -l) -eq 0 ];then
							echo "${bondjA[$cont]}	--|					"
							let "cont++"
						# If the bond has vif but not VLAN associated
						elif [ ${cont} -eq 0 ]&&[ $(egrep "${bondj[$cont]}" ip_address|egrep '@'|wc -l) -eq 0 ]&&[ $(egrep "${bondj[$cont]}.*$bridgej" ip_address|wc -l) -eq 1 ]&&[ $(egrep "$vifj.*$bridgej" ip_address|wc -l) -gt 0 ];then   
							echo -----------------------------------------------------------------------------------------------
							echo "${bondjA[$cont]}	----	$bondj	----	----	$bridgej	----	$vifj"
							let "cont++"	
						elif [ ${cont} -gt 0 ]&&[ ${#bondjA[@]} -gt $cont ]&&[ $(egrep "${bondj[$cont]}" ip_address|egrep '@'|wc -l) -eq 0 ]&&[ $(egrep "${bondj[$cont]}.*$bridgej" ip_address|wc -l) -eq 1 ]&&[ $(egrep "$vifj.*$bridgej" ip_address|wc -l) -gt 0 ];then   
							echo "${bondjA[$cont]}	--|					|--	$vifj"
							let "cont++"
						elif  [ ${cont} -gt 0 ]&&[ ${#bondjA[@]} -gt $cont ]&&[ $(egrep "${bondj[$cont]}" ip_address|egrep '@'|wc -l) -eq 0 ]&&[ $(egrep "${bondj[$cont]}.*$bridgej" ip_address|wc -l) -eq 1 ];then 
							echo "${bondjA[$cont]}	--|					"
							let "cont++"
						elif  [ ${cont} -gt 0 ]&&[ ${#bondjA[@]} -le $cont ]&&[ $(egrep "${bondj[$cont]}" ip_address|egrep '@'|wc -l) -eq 0 ]&&[ $(egrep "${bondj[$cont]}.*$bridgej" ip_address|wc -l) -eq 1 ]&& [ $(egrep "$vifj.*$bridgej" ip_address|wc -l) -gt 0 ];then
							echo "						|--	$vifj"
							let "cont++"
						fi
					done
				done
				# If the bond doesn't have vif nor VLAN associated							
				if [ $(egrep "${bondj[$cont]}" ip_address|egrep '@'|wc -l) -eq 0 ]&&[ $(egrep "${bondj[$cont]}.*$bridgej" ip_address|wc -l) -eq 1 ]&&[ $(egrep "$bridgej" ip_address|egrep vif|wc -l) -eq 0 ];then   
					echo -----------------------------------------------------------------------------------------------
					echo "${bondjA[$cont]}	----	$bondj	----	$bridgej	----"
					let "cont++"	
				elif  [ ${cont} -gt 0 ]&&[ ${#bondjA[@]} -gt $cont ]&&[ $(egrep "${bondj[$cont]}" ip_address|egrep '@'|wc -l) -eq 0 ]&&[ $(egrep "${bondj[$cont]}.*$bridgej" ip_address|wc -l) -eq 1 ]&&[ $(egrep "$bridgej" ip_address|egrep vif|wc -l) -eq 0 ];then 
					echo "${bondjA[$cont]}	--|					"
					let "cont++"
				fi				
		bondjA=()
		cont=0
		done
	done
else
	clear
   echo "Please specify a valid path to the sosreport"
   echo "Usage			: 						"
   echo ' ./xenNetMap.sh "<Path to the sosreport>"  '
fi
