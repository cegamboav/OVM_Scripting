#! /bin/sh
#################################################################
# Author : Kaushal Mishra <kmishra2@in.ibm.com>
# Purpose : This script generate capacity data of HVs 
###############################################################
## 28 Oct, 2020 : Created 
##
##
################################################################
##
#

find /monitor/ovmm_script/cpupindata/ -mtime +90 -name '*repoutilization*.txt' -exec rm {} \;

ovmclicmd="/usr/local/sbin/ovmcli"
HOSTNAmE=`uname -a |awk '{print $2}' | tr 'A-Z' 'a-z'`
Outfile=/monitor/ovmm_script/cpupindata/"${HOSTNAmE}_cpupin_`date +"%Y-%m-%d-%T"`.txt"
echo "Serverpool|HV Name|CPU on HV|Used cpu on HV|VM Name|VCPU on VM|CPU_Pinning|CPU Oversubscription|Comment" >> ${Outfile}
for xx in $($ovmclicmd "list server" |grep -i id |awk -F 'name:' '{print $2}' |sort)
do
spol=$($ovmclicmd "show server name=${xx}" |grep -i pool |awk -F '[' '{print $2}'|sed -e 's/]//g')
for xy in $(ssh -o PasswordAuthentication=no iuxu@${xx} "sudo xm list" |grep -v -E 'Name|Domain' |awk '{print $1}')
do
vmcpu=$(ssh -o PasswordAuthentication=no iuxu@${xx} "sudo xm list ${xy}" |grep -v -E 'Name' |awk '{print $4}')
vmpin=$(ssh -o PasswordAuthentication=no iuxu@${xx} "sudo xm vcpu-list ${xy}" |grep -v Name |awk '{print $7}' |uniq)
usedcpu1=$(ssh -o PasswordAuthentication=no iuxu@${xx} "sudo xm list |grep -v -E 'Name|Domain'" |awk '{ sum+=$4} END {print sum}')
vmnm=$($ovmclicmd "show vm id=${xy}" |grep -i name |awk -F '=' '{print $2}')
Tot_cpu=$(ssh -o PasswordAuthentication=no iuxu@${xx} "sudo xm info" |grep -i nr_cpus |awk -F ':' '{print $2}')
Tot_thrd=$(ssh -o PasswordAuthentication=no iuxu@${xx} "sudo xm info" |grep -i threads_per_core |awk -F ':' '{print $2}')
if [[ ${Tot_thrd} -eq 1 ]]
  then
    if [[ ${Tot_cpu} -eq 16 ]]
        then
         dom0cpu=2
#         echo "$dom0cpu"
    else if [[ ${Tot_cpu} -eq 28 ]]
        then
         dom0cpu=3
 #        echo "$dom0cpu"
    else if [[ ${Tot_cpu} -gt 32 ]]
        then
         dom0cpu=4
#         echo "$dom0cpu"
         fi
      fi
    fi
else 
    if [[ ${Tot_cpu} -eq 32 ]]
        then
         dom0cpu=4
#         echo "$dom0cpu"
    else if [[ ${Tot_cpu} -eq 56 ]]
        then
         dom0cpu=6
#         echo "$dom0cpu"
    else if [[ ${Tot_cpu} -gt 56 ]]
        then
         dom0cpu=8
 #        echo "$dom0cpu"
         fi
      fi
    fi
fi
usedcpu=$(expr $usedcpu1 + $dom0cpu)
echo "${spol}|${xx}|${Tot_cpu}|${usedcpu}|${vmnm}|${vmcpu}|${vmpin}" >> ${Outfile}
done
done
#echo -e  "Hello Team\n\nPlease find attached CPU pinning Report from SL DAL  guest vms. \n \n\nThanks & Regards \n\nCapacity Admin" | mailx -a ${Outfile} -r no-reply@in.ibm.com -s "OVM CPU Pin Report for SL DAL"  kmishra2@in.ibm.com yogthapa@in.ibm.com


if [[ ${HOSTNAmE} = a0001p5oovme101 ]];then
        DC="WDC04 (EAST)"
elif [[ ${HOSTNAmE} = a0001p5oovmw101 ]];then
        DC="DAL10 (WEST)"
elif [[ ${HOSTNAmE} = a0001p5oovml101 ]];then
        DC="London"
elif [[ ${HOSTNAmE} = a0001p5oovmf101 ]];then
        DC="FRA04"
elif [[ ${HOSTNAmE} = a0001p5oovmt101 ]];then
        DC="Tokyo"
elif [[ ${HOSTNAmE} = a0001p5oovmm101 ]];then
        DC="MEL01"
elif [[ ${HOSTNAmE} = a0001p5oovmt201 ]];then
        DC="Tokyo 05"
elif [[ ${HOSTNAmE} = a0001o5oovmec01 ]];then
        DC="WDC04-VDC"
elif [[ ${HOSTNAmE} = a0001o5oovmwc01 ]];then
        DC="DAL-VDC"
elif [[ ${HOSTNAmE} = a0001o5oovmfc01 ]];then
        DC="FRA04-VDC"
elif [[ ${HOSTNAmE} = a0001o5oovmlc01 ]];then
        DC="LON06"
fi

echo -e  "Hello Team\n\nPlease find attached CPU Pining Report for ${DC}  guest vms. \n \n\nThanks & Regards \n OVM Admin" | mailx -a ${Outfile} -r no-reply@in.ibm.com -s "CPU Piining Report for ${DC}"  kmishra2@in.ibm.com,infra-ovm-alerts@wwpdl.vnet.ibm.com