#!/bin/bash

# Name          : listLoopDisks.sh
# Author        : carlos.gamboa, david.cerdas and luis.alvarez
# Version       : 1.0
# Copyright     : GPLv2
# Description   : This script lists the disks and its correspond loop ,
#                  based on the vm.cfg file of the running VMs in Dom0, OVM.
# Usage         : ./listLoopDisks.sh -<option> <id>

parameter=$1

case_null(){
        echo "Usage:"
    echo -e " listLoopDisks.sh <desire> <VM_ID> \n\n"
        echo " Desire                                give info:"
    echo " listLoopDisks.sh -a         |         Shows info of all running VMs"
    echo " listLoopDisks.sh -l         |         List info of all running VMs"
    echo " listLoopDisks.sh -i <VM_ID> |         Specify a VM ID"
	echo " listLoopDisks.sh -L <VM_ID> |         List a specific VM ID"
    echo ""
    exit 1
}

header(){
        clear
        echo "Server Name:"
        hostname
        echo "----------------------------------------------------------------------------------------"
}

run_all(){
        if [ $1 -eq 0 ];then
                xmli="$(xm list|egrep -v 'Name|Domain-0'|awk '{print $1}' 2>&1)"
        else
                xmli="$(xm list $2|egrep -v 'Name|Domain-0'|awk '{print $1}' 2>&1)"
        fi

        for i in $(echo "$xmli"); do
                for j in `find /OVS/Repositories/ -name $i`; do
                        echo "VM_Name ID"
                        echo `cat $j/vm.cfg|egrep 'OVM_simple_name'|cut -d"=" -f2|cut -d"'" -f2`"                       "$i
                        echo
                        disk="$(cat $j/vm.cfg|egrep 'disk')"
                        echo "Device Repository Loop"
                        disk2="$(echo $disk|awk -F"'" '/disk/ { for (i = 2; i <= NF; i=i+2) print $i }'|cut -d':' -f2|cut -d"," -f1)"
                        for h in $(echo "$disk2"|grep -v cdrom); do
                                repo="$(echo $h|cut -d'/' -f4)"
                                echo ""`echo $h|cut -d'/' -f6`" "`grep OVS_REPO_ALIAS /OVS/Repositories/$repo/.ovsrepo|cut -d"=" -f2`" "`losetup -j $h|awk '{print $1}'|cut -d':' -f1`
                        done
                        echo "------------"
                done
        done|column -t
}

run_list(){
        if [ $1 -eq 0 ];then
                xmli="$(xm list|egrep -v 'Name|Domain-0'|awk '{print $1}' 2>&1)"
        else
                xmli="$(xm list $2|egrep -v 'Name|Domain-0'|awk '{print $1}' 2>&1)"
        fi
        echo "VM_Name 	Device		 			Repository 	Loop"
		for i in $(echo "$xmli"); do
                for j in `find /OVS/Repositories/ -name $i`; do
                        disk="$(cat $j/vm.cfg|egrep 'disk')"
                        disk2="$(echo $disk|awk -F"'" '/disk/ { for (i = 2; i <= NF; i=i+2) print $i }'|cut -d':' -f2|cut -d"," -f1)"
                        for h in $(echo "$disk2"|grep -v cdrom); do
                                repo="$(echo $h|cut -d'/' -f4)"
                                echo `cat $j/vm.cfg|egrep 'OVM_simple_name'|cut -d"=" -f2|cut -d"'" -f2`" "`echo $h|cut -d'/' -f6`" "`grep OVS_REPO_ALIAS /OVS/Repositories/$repo/.ovsrepo|cut -d"=" -f2`" "`losetup -j $h|awk '{print $1}'|cut -d':' -f1`|column -t
                        done
                done
        done|column -t
}


case $parameter in

        -a|-A)
                header
                run_all 0
                ;;
        -i|-I)
                header
                run_all 1 $2
                ;;
        -l)
                header
                run_list 0
                ;;
		-L)
                header
                run_list 1 $2
                ;;
        *)
                case_null
                ;;
esac
