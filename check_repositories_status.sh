#! /bin/sh
#################################################################
# Author : Carlos Gamboa <carlos.gamboa.ibm.com>
# Purpose : This script generate a list of the repositories over 89%
###############################################################
## 18 Mar, 2021 : Created
##
##
################################################################
##
#

print_head=0
ovmclicmd="/usr/local/sbin/ovmcli"
alerted_repos=0
list_repos=()
list_servers=()
repo_names=()

printf_fn(){
	if [ $print_head -eq 0 ]
	then
		clear
		printf "%-1s %-70s %-1s %-5s %-1s %-20s %-1s %-32s %-1s\n" "|" "----------------------------------------------------------------------" "|" "-----" "|" "--------------------" "|" "--------------------------------" "|"
		printf "%-1s %-70s %-1s %-5s %-1s %-20s %-1s %-32s %-1s\n" "|" "Repository" "|" "%" "|" "Presented" "|" "ID" "|"
		printf "%-1s %-70s %-1s %-5s %-1s %-20s %-1s %-32s %-1s\n" "|" "----------------------------------------------------------------------" "|" "-----" "|" "--------------------" "|" "--------------------------------" "|"
		print_head=1
	fi
	printf "%-1s %-70s %-1s %-5s %-1s %-20s %-1s %-32s %-1s\n" "|" $1 "|" $2 "|" $3 "|" $4 "|"
}

print_foot(){
	if [ $print_head -eq 1 ]
	then
		printf "%-1s %-70s %-1s %-5s %-1s %-20s %-1s %-32s %-1s\n" "|" "----------------------------------------------------------------------" "|" "-----" "|" "--------------------" "|" "--------------------------------" "|"
	else
		clear
		echo "[OK] No repositories over 89% in the environment..."
	fi
}

print_head_disks(){
	printf "%-1s %-50s %-1s %-20s %-1s\n" "|" "--------------------------------------------------" "|" "--------------------" "|"
	printf "%-1s %-9s %-63s %-1s\n" "|" $1 $2 "|"
	printf "%-1s %-50s %-1s %-20s %-1s\n" "|" "VDISK NAME" "|" "IS USED?" "|"
}

print_disks(){
	printf "%-1s %-50s %-1s %-20s %-1s\n" "|" $1 "|" $2 "|"
}

check_repositories(){
	for xx in $($ovmclicmd "list repository" |grep -i id |grep -v "OVM_SYS_REPO_PART" |awk -F 'id:' '{print $2}' |awk '{print $1}')
	do
		reponame=$($ovmclicmd "show repository id=${xx}" |grep -i name |awk -F '=' '{print $2}' |sed 's/^ //g' |sed 's/ /_/g')
		repoid=$($ovmclicmd "show repository id=${xx}" |grep Id  |grep -v Manager |awk '{print $4}')
		presented=$($ovmclicmd "show repository id=${xx}" |grep -i "Presented Server" |awk -F '[' '{print $2}' |sed -e 's/]//g')

		for xy in $presented
		do
			ssh -q iuxu@${xy} exit
			if [[ $? == 0 ]]
			then
				utiper=$(ssh iuxu@$xy "sudo df -hP |grep -i ${repoid}" |awk '{print $5}'|cut -d '%' -f 1)
				if [ $utiper -gt 89 ]
				then
					alerted_repos=1
					printf_fn $reponame "$utiper%" $xy $repoid
					list_repos+=("$repoid")
					list_servers+=("$xy")
					repo_names+=("$reponame")
				fi
				break
			fi
		done
	done
	print_foot
	if [ $alerted_repos -eq 1 ]
	then
		check_repositories_contents
	fi
}

check_repositories_contents(){
	echo 
	echo
	echo "Checking Data into the repositories.."
	echo 
	for i in "${!list_repos[@]}"
	do
		print_head_disks "Checking:" ${repo_names[$i]}
		vdisks=$(ssh iuxu@${list_servers[$i]} "sudo ls /OVS/Repositories/${list_repos[$i]}/VirtualDisks/")
		isos=$(ssh iuxu@${list_servers[$i]} "sudo ls /OVS/Repositories/${list_repos[$i]}/ISOs/")
		for h in `echo $vdisks`
		do
			mapping=0
			mapping=$($ovmclicmd "show VirtualDisk id=$h"|grep VmDiskMapping|wc -l)
			
			if [ $mapping -eq 0 ]
			then
				print_disks $h "**Not_Used**"
			else
				print_disks $h "Used"
			fi
		done
		if [ ! -z "$isos" ]
		then
			print_disks " " " "
			printf "%-1s %-50s %-1s %-20s %-1s\n" "|" "CDROM NAME" "|" "IS USED?" "|"
			for h in `echo $isos`
			do
				mapping=0
				mapping=$($ovmclicmd "show VirtualCdrom name=$h"|grep VmDiskMapping|wc -l)
				
				if [ $mapping -eq 0 ]
				then
					print_disks $h "**Not_Used**"
				else
					print_disks $h "Used"
				fi
			done
		fi
		
	done
	printf "%-1s %-50s %-1s %-20s %-1s\n" "|" "--------------------------------------------------" "|" "--------------------" "|"
}

check_repositories

