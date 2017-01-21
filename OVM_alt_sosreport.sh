#!/bin/bash

# Find the OVM type
if [ -f /etc/ovs-release ];then
        type="ovs"
elif [ -f `find /u01 -name .config 2>/dev/null` ];then 
        type="ovmm"
else
    echo "This is not an OVM Manager or OVS Server"
        exit 1
fi

[ ! -d /tmp/testscript/OVM_alt_sosreport ]&&mkdir /tmp/testscript/OVM_alt_sosreport

# Fill an array with the OVS commands
function prepare_ovs(){
commands=(
    "uname -a"
    "uptime"
    "cat /etc/*-release"
    "dmidecode -t 1"
    "df -Th"
    "mount"
    "mounted.ocfs2 -d"
    "ifconfig -a"
    "service o2cb status"
    "service ovs-agent status"
    "brctl show"
)
collect_extra_data_ovm
}

# Fill an array with the OVMM commands
function prepare_ovmm(){
commands=(
    "uname -a"
    "cat /etc/sysconfig/ovmm"
    "cat /etc/*-release"
    "dmidecode -t 1"
    "uptime"
    "date"
    "uname -a"
)
}


collect_extra_data_ovm(){
	echo "">> /tmp/data.txt;echo "Ethtool -k:">> /tmp/data.txt;for i in `cd /etc/sysconfig/network-scripts;ls ifcfg-*|grep -v lo|cut -d '-' -f 2`;do echo $i;ethtool -k $i;echo "------------";done>> /tmp/data.txt
	echo "">> /tmp/data.txt;echo "Ethtool -i:">> /tmp/data.txt;for i in `cd /etc/sysconfig/network-scripts;ls ifcfg-*|grep -v lo|cut -d '-' -f 2`;do echo $i;ethtool -i $i;echo "------------";done>> /tmp/data.txt
	rpm -qa > /tmp/datarpm.txt
	tar -cf /tmp/messages.tar /var/log/messages*
	tar -cf /tmp/ovs-agent.tar /var/log/ovs-agent.log*
	tar -cf /tmp/xen.tar /var/log/xen/
	tar -cf /tmp/oswatcher /var/log/oswatcher/
	tar -cf /tmp/etc.tar /etc/
	tar -zcf /tmp/logs.tar.z /tmp/messages.tar /tmp/ovs-agent.tar /tmp/xen.tar /tmp/oswatcher /tmp/etc.tar /tmp/data.txt /tmp/datarpm.txt
	rm -f /tmp/etc.tar /tmp/messages.tar /tmp/ovs-agent.tar /tmp/xen.tar /tmp/oswatcher /tmp/datarpm.txt /tmp/data.txt
}

# Run alt_sosreport_omm
function alt_sosreport(){
for c in "${commands[@]}";do
        echo "# "$c
        $c
done
}

clear
echo "Collecting data..."
prepare_$type&&alt_sosreport > /tmp/data.txt

clear
echo "Please attach the below file to the SR"
ls -1 /tmp/logs.tar.z
