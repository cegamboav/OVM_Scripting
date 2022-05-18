for i in $( cat ./hvlist);
do

scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ./multipath_script_v2.sh ovmadm@${i}:/tmp
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -n ovmadm@${i} "sh /tmp/multipath_script_v2.sh;rm /tmp/multipath_script_v2.sh"

done