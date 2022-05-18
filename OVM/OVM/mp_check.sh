for i in $( cat ./hvlist);
do

scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ./multipath_script_v2.sh iuxu@${i}:/tmp
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -n iuxu@${i} "sh /tmp/multipath_script_v2.sh;rm /tmp/multipath_script_v2.sh"

done
