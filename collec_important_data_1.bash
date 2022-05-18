#!/bin/bash
#################################################################
# Author : Carlos Gamboa <carlos.gamboa@ibm.com>
# Purpose : This script is to capture important data of a HV Server
###############################################################
## 7 Jun, 2021 : Created 
##
##
################################################################
##
#

echo "Collecting Data ..."
server_name=$(uname -a |awk '{print $2}' | tr 'A-Z' 'a-z')
echo "hostname:,$server_name" > /tmp/data.txt
#echo '===================================' >> /tmp/data.txt
manufactured=$(dmidecode -t system|egrep "Manufacturer"|cut -d ':' -f2)
product_name=$(dmidecode -t system|egrep "Product Name"|cut -d ':' -f2)
serial_number=$(dmidecode -t system|egrep "Serial Number"|cut -d ':' -f2)
echo "System information:" >> /tmp/data.txt
echo "Manufactured:,$manufactured,Product Name:,$product_name" >> /tmp/data.txt
echo "Serial Number:,$serial_number" >> /tmp/data.txt
#echo '===================================' >> /tmp/data.txt
echo "Memory information:" >> /tmp/data.txt
dmidecode -t memory >> /tmp/data.txt
echo '===================================' >> /tmp/data.txt
echo "CPU information:" >> /tmp/data.txt
dmidecode -t processor >> /tmp/data.txt
echo '===================================' >> /tmp/data.txt
echo "Uptime: " >> /tmp/data.txt
uptime >> /tmp/data.txt
echo '===================================' >> /tmp/data.txt
echo "Kernel version: " >> /tmp/data.txt
uname -r  >> /tmp/data.txt
echo '===================================' >> /tmp/data.txt
echo "OVM Version:" >> /tmp/data.txt
cat /etc/ovs-release >> /tmp/data.txt
echo '===================================' >> /tmp/data.txt
echo "XM info: " >> /tmp/data.txt
xm info >> /tmp/data.txt
echo '===================================' >> /tmp/data.txt
echo "OVS Status" >> /tmp/data.txt
service ovs-agent status >> /tmp/data.txt
echo '===================================' >> /tmp/data.txt
mv /tmp/data.txt /tmp/$HOSTNAME.data.txt
echo "[OK] Data collected in: /tmp/$HOSTNAME.data.txt"
