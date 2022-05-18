#!/bin/bash
#Script to get the fiendly name of a LUN from it UUID
#Script made by Carlos Gamboa
#carlos.gamboa@ibm.com

LUN=$1

check_lun(){
	for i in `xm li|egrep -v 'Name|Domain'|awk '{print $1}'`
	do
		echo "Checking VM $i"
		a=$(find /OVS/ -name $i)
		exist=$(grep -i $LUN $a/vm.cfg|wc -l)
		if [ $exist -eq 0 ]
		then
			echo "  [OK]  LUN does't exist in the VM"
		else
			echo "  [Warning]  LUN exist in the VM"
		fi
	done
}


if [ -z $LUN ] 
then
	echo "[Error] Insert the list of vms as a file like vms.csv"
else
	check_lun
fi