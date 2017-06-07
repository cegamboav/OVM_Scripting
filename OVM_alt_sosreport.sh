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

[ ! -d /tmp/alt_sosreport ]&&mkdir /tmp/alt_sosreport

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
# Run alt_sosreport
function alt_sosreport(){
for c in "${commands[@]}";do
	echo "# "$c
	$c
done
}

echo "Collecting data..."
prepare_$type&&alt_sosreport > /tmp/alt_sosreport/data.txt

clear
echo "Please attach the below file to the SR"
ls -1 /tmp/alt_sosreport/data.txt