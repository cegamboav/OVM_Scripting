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

find /monitor/ovmm_script/capacity/ -mtime +90 -name '*.txt' -exec rm {} \;
ovmclicmd="/usr/local/sbin/ovmcli"
HOSTNAmE=`uname -a |awk '{print $2}' | tr 'A-Z' 'a-z'`
opfile=/monitor/ovmm_script/capacity/"${HOSTNAmE}_inventory_`date +"%Y-%m-%d-%T"`.txt"
echo "Server Pool|HV Name|HV IP|OVS Version|OVS Kernel|Manufacturer|Product|Serial|HV Memory|HV CPU|VM Name|VM Status|VM Memory|VM CPU|Repo|VM Tag" >> $opfile
for xx in $($ovmclicmd "list server" |grep -i id |awk -F 'name:' '{print $2}' |sort -u )
do
$ovmclicmd "show server name=${xx}" >  /tmp/hvdetail.txt
Serverpool=$(cat /tmp/hvdetail.txt |grep -i pool |awk -F '[' '{print $2}' |sed -e 's/]//g')
hvip=$(cat /tmp/hvdetail.txt |grep -i 'Ip Address' |awk -F '=' '{print $2}')
ovsversion=$(cat /tmp/hvdetail.txt |grep -i "OVM Version" |awk -F '=' '{print $2}')
ssh -q iuxu@${xx} exit
if [[ $? == 0 ]]
then 
ovskernel=$(ssh iuxu@${xx} "sudo uname -r")
ovscpu=$(ssh iuxu@${xx} "sudo xm info"|grep -i nr_cpu |awk -F ':' '{print $2}')
else
ovskernel="NULL"
ovscpu="NULL"
fi
ovsmanf=$(cat /tmp/hvdetail.txt |grep -i "Manufacturer" |awk -F '=' '{print $2}')
ovsproduct=$(cat /tmp/hvdetail.txt |grep -i "Product" |awk -F '=' '{print $2}')
ovsserial=$(cat /tmp/hvdetail.txt |grep -i "Serial Number" |awk -F '=' '{print $2}')
ovsmem=$(cat /tmp/hvdetail.txt |grep -i "Memory (MB)" |grep -v Usable |awk -F '=' '{print $2}')
#for vmnm in $(cat /tmp/hvdetail.txt |grep Vm |grep -v -E 'Ability|OVM_SYS_REPO_PART|Version|Role' |awk -F '[' '{print $2}' |sed -e 's/]//g')
novm=$(cat /tmp/hvdetail.txt |grep Vm |grep -v -E 'Ability|OVM_SYS_REPO_PART|Version|Role' |awk -F '=' '{print $2}'  |awk '{print $1}' |wc -l)
if [[ ${novm} == 0 ]]
then
echo "${Serverpool}|${xx}|${hvip}|${ovsversion}|${ovskernel}|${ovsmanf}|${ovsproduct}|${ovsserial}|${ovsmem}|${ovscpu}|Empty|None|None|None|None|None" >> $opfile
#echo "HV is empty"
else
for vmid in $(cat /tmp/hvdetail.txt |grep Vm |grep -v -E 'Ability|OVM_SYS_REPO_PART|Version|Role' |awk -F '=' '{print $2}'  |awk '{print $1}')
do
$ovmclicmd "show vm id=$vmid" > /tmp/vmdetail.txt
vmname=$(cat /tmp/vmdetail.txt |grep -i Name |awk '{print $4}')
vmmem=$(cat /tmp/vmdetail.txt |grep -i 'Memory (MB)' |grep -v Max |awk -F '=' '{print $2}')
vmcpu=$(cat /tmp/vmdetail.txt |grep -i processors |grep -v Max |awk -F '=' '{print $2}')
vmtag=$(cat /tmp/vmdetail.txt  |grep -i Tag |awk -F '[' '{print $2}' |sed -e 's/]//g')
vmstatus=$(cat /tmp/vmdetail.txt |grep -i "Status =" |awk -F '=' '{print $2}')
vmrepo=$(cat /tmp/vmdetail.txt  |grep -i Repository |awk -F '[' '{print $2}' | sed -e 's/_/ /g' |awk '{print $2}' |sed -e 's/]//g')
echo "${Serverpool}|${xx}|${hvip}|${ovsversion}|${ovskernel}|${ovsmanf}|${ovsproduct}|${ovsserial}|${ovsmem}|${ovscpu}|${vmname}|${vmstatus}|${vmmem}|${vmcpu}|${vmrepo}|${vmtag}" >> $opfile
done
fi
done
rm -rf /tmp/vmdetail.txt  /tmp/hvdetail.txt


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

echo -e  "Hello Team\n\nPlease find attached Capacity Report from ${DC}  guest vms. \n \n\nThanks & Regards \n\nCapacity Admin" | mailx -a ${opfile} -r no-reply@in.ibm.com -s "OVM Capacity Report for ${DC}"  kmishra2@in.ibm.com,infra-ovm-alerts@wwpdl.vnet.ibm.com