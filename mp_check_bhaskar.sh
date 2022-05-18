#!/bin/bash

rm -rf /tmp/server_lun_path.csv /tmp/server_lun_path /tmp/lun_vm_name.txt /tmp/lun_vm_name /tmp/lun_vm_name2 /tmp/lun_vm_name.csv /tmp/$(hostname)_lun_vm_name.csv /tmp/$(hostname)_server_lun_path.csv > /dev/null 2>&1


# Executing Yogesh's script
sh mp_check.sh > /tmp/server_lun_path 
cp /tmp/server_lun_path /tmp/$(hostname)_server_lun_path.csv
chmod 777 /tmp/server_lun_path /tmp/$(hostname)_server_lun_path.csv

## Starts the progress bar
while :;do echo -n .;sleep 1;done &
trap "kill $!" EXIT

for i in $( cat ./hvlist);
do

# Generate VM name from LUN
scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ./vm_name_from_lun_TEST.sh /tmp/server_lun_path iuxu@${i}:/home/iuxu > /dev/null 2>&1
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -n iuxu@${i} "sh /home/iuxu/vm_name_from_lun_TEST.sh" > /dev/null 2>&1
scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no iuxu@${i}:/home/iuxu/lun_vm_name /tmp/lun_vm_name > /dev/null 2>&1
cat /tmp/lun_vm_name >> /tmp/lun_vm_name2

#ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -n iuxu@${i} "rm -rf /home/iuxu/vm_name_from_lun_TEST.sh /home/iuxu/lun_vm_name"
done


### Modifying file details
cp /tmp/lun_vm_name2 /tmp/$(hostname)_lun_vm_name.csv 
chmod 777 /tmp/lun_vm_name2 /tmp/$(hostname)_lun_vm_name.csv

## kills the progress bar
#kill $! && trap " " EXIT


#Send Mail now
#mailx -a /tmp/lun_vm_name.csv /tmp/server_lun_path.csv -s "Multipath report DAL 4" -r no-reply@ibm.com yogthapa@in.ibm.com,kmishra2@in.ibm.com,adrian.marin@ibm.com,carlos.gamboa@ibm.com,ajenis04@in.ibm.com,prpanda1@in.ibm.com < /dev/null
#mailx -a /tmp/$(hostname)_lun_vm_name.csv /tmp/$(hostname)_server_lun_path.csv -s "Multipath report for DAL 4" -r no-reply@ibm.com bhacha96@in.ibm.com < /dev/null

#rm -rf /tmp/server 

#### Download /tmp/lun_vm_name.csv & /tmp/server_lun_path.csv ####
echo ""
echo "#### Download /tmp/$(hostname)_lun_vm_name.csv file  ####"
echo ""
