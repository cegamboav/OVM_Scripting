#!/bin/bash

## create folders
createtempfolder(){
working_folder=$( mktemp -d )
}


##multipath list
multipath_details(){
sudo multipath -ll >> ${working_folder}/lunst.txt ; sudo echo "3600" >> ${working_folder}/lunst.txt
}

##multipath report
report_generate(){
for xx in `sudo cat ${working_folder}/lunst.txt | grep -i ibm | awk '{print $1}'`; do lp=$( sudo cat ${working_folder}/lunst.txt | sed -n "/${xx}/,/3600/p" | grep 'active ready running' | wc -l );hvname=$( hostname ) ; echo ${hvname},${xx},${lp};done
}


##delete temporary file
delete_working_folder(){
sudo rm -rf ${working_folder}
}


createtempfolder
multipath_details
report_generate
delete_working_folder