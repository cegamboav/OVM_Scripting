#!/bin/bash

#Script to list all the disks attached to a VM

#Variables
vmnm=$1

printf_fn(){
	if [ $1 -eq 0 ]
	then
		printf "%-1s %-5d %-1s %-5s %-1s %-50s %-1s %-20s\n" "|" $2 "|" $3 "|" $4 "|" $5
	else
		printf "%-1s %-5d %-1s %-5s %-1s %-33s %-1s %-6s %-1s %-5s %-1s %-15s\n" "|" $2 "|" $3 "|" $4 "|" $5 "|" $6 "|" $7
	fi
}

list_disks(){
	clear
	for i in `cat $vmnm`
	do
		for xx in $(ovmcli "list vm"|grep $i|awk '{print $2}'|awk -F id: '{print $2}')
		do 
			vmnm_=$(ovmcli "show vm id=$xx"|grep -i name|awk -F '=' '{print $2}'|sed -e "s/ //")
			echo "|===============================================================================================|"
			echo "| VM: $vmnm_										|"
			echo "|-----------------------------------------------------------------------------------------------|"
			echo "| Slot	| Type	| 		ID		    | Size   | Shrbl | Name			|"
			echo "|-----------------------------------------------------------------------------------------------|"
			for xy in $(ovmcli "show vm id=$xx"|grep -i VMDiskMapping|awk -F '=' '{print $2}'|awk '{print $1}')
			do 
				SLT=$(ovmcli "show VMDiskMapping id=${xy}"|grep -i slot|awk -F '=' '{print $2}'|sed -e "s/ //")
				phy=0
				phy=$(ovmcli "show VMDiskMapping id=${xy}"|grep -i 'Physical Disk'|wc -l)
				if [ $phy -eq 0 ]
				then
					vdsk=0
					vdsk=$(ovmcli "show VMDiskMapping id=${xy}"|grep -i 'Virtual Disk'|wc -l)
					if [ $vdsk -eq 0 ]
					then
						cdID=$(ovmcli "show VMDiskMapping id=${xy}"|grep -i 'Virtual Cd')
						cdname=$(echo $cdID|cut -d '=' -f 2|cut -d ' ' -f2)
						cdname_=$(echo $cdID|cut -d '[' -f 2|cut -d ']' -f1)
						printf_fn 0 $SLT "CDROM" $cdname_ $cdname
						
					else
						vDiskID=$(ovmcli "show VMDiskMapping id=${xy}"|grep -i 'Virtual Disk')
						vid=$(echo $vDiskID|cut -d '=' -f 2|cut -d ' ' -f2)
						vdiskname=$(echo $vDiskID|cut -d '[' -f 2|cut -d ']' -f1)
						printf_fn 0 $SLT "vDisk" $vid $vdiskname
					fi
				else
					PhtDiskID=$(ovmcli "show VMDiskMapping id=${xy}"|grep -i 'Physical Disk'|awk -F '=' '{print $2}'|awk '{print $1}')
					diskuid=$(ovmcli "show physicaldisk id=${PhtDiskID}"|grep -i 'Page83 ID'|awk -F '=' '{print $2}'|awk '{print $1}')
					shrabl=$(ovmcli "show physicaldisk id=${PhtDiskID}"|grep -i Shareable|awk -F '=' '{print $2}'|awk '{print $1}')
					sz=$(ovmcli "show physicaldisk id=${PhtDiskID}"|grep -i Size|awk -F '=' '{print $2}'|awk '{print $1}')
					Disknm=$(ovmcli "show physicaldisk id=${PhtDiskID}"|grep -i Name|grep -v -i -E 'Device|User-Friendly'|awk -F '=' '{print $2}'|awk '{print $1}')
					printf_fn 1 $SLT "PHY" $diskuid $sz $shrabl $Disknm
				fi
			done
		done
	done
	echo "|===============================================================================================|"
}

if [ -z $vmnm ]
then
	echo "Please insert the vm name"
else
	list_disks
fi