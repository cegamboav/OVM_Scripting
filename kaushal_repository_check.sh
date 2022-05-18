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

need_send_email=0


find /monitor/ovmm_script/ -mtime +90 -name '*repoutilization*.txt' -exec rm {} \;
ovmclicmd="/usr/local/sbin/ovmcli"
HOSTNAmE=`uname -a |awk '{print $2}' | tr 'A-Z' 'a-z'`
opfile=/monitor/ovmm_script/repoutilization_data/"${HOSTNAmE}_repoutilization_`date +"%Y-%m-%d-%T"`.txt"
emailifle=/monitor/ovmm_script/repoutilization_data/"${HOSTNAmE}_email.html"
> $emailifle

collect_information(){
	for xx in $($ovmclicmd "list repository" |grep -i id |grep -v "OVM_SYS_REPO_PART" |awk -F 'id:' '{print $2}' |awk '{print $1}')
	do
		reponame=$($ovmclicmd "show repository id=${xx}" |grep -i name |awk -F '=' '{print $2}' |sed 's/^ //g' |sed 's/ /_/g')
		repoid=$($ovmclicmd "show repository id=${xx}" |grep Id  |grep -v Manager |awk '{print $4}')
		presented=$($ovmclicmd "show repository id=${xx}" |grep -i "Presented Server" |awk -F '[' '{print $2}' |sed -e 's/]//g')


		for xy in $presented
		do 
			ssh -q iuxu@${xy} exit
			if [[ $? == 0 ]]
			then
				utiper=$(ssh iuxu@$xy "sudo df -hP |grep -i ${repoid}" |awk '{print $5}'|cut -d '%' -f 1)
				#echo "$reponame $utiper" >> $opfile
				if [ $utiper -gt 89 ]
				then
					need_send_email=1
					echo "$reponame $utiper" >> $opfile
				fi
				break
			fi
		done
	done
}


set_data_center_name(){
	if [[ ${HOSTNAmE} = a0001p5oovme101 ]];then
			DC="WDC04-SL (EAST)"
	elif [[ ${HOSTNAmE} = a0001p5oovmw101 ]];then
			DC="DAL10-SL (WEST)"
	elif [[ ${HOSTNAmE} = a0001p5oovml101 ]];then
			DC="London-SL"
	elif [[ ${HOSTNAmE} = a0001p5oovmf101 ]];then
			DC="FRA04-SL"
	elif [[ ${HOSTNAmE} = a0001p5oovmt101 ]];then
			DC="Tokyo-SL"
	elif [[ ${HOSTNAmE} = a0001o5oovmec01 ]];then
			DC="WDC04-VDC"
	elif [[ ${HOSTNAmE} = a0001o5oovmep01 ]];then
			DC="WDC04-PVT-VDC"
	elif [[ ${HOSTNAmE} = a0001o5oovmwc01 ]];then
			DC="DAL10-VDC"
	elif [[ ${HOSTNAmE} = a0001o5oovmfc01 ]];then
			DC="FRA04-VDC"
	elif [[ ${HOSTNAmE} = a0001o5oovmlc01 ]];then
			DC="LON06-VDC"
	elif [[ ${HOSTNAmE} = a0001p5oovms101 ]];then
			DC="SYD-SL"
	elif [[ ${HOSTNAmE} = a0001o5oovmp101 ]];then
			DC="POK-SO-P1"
	elif [[ ${HOSTNAmE} = a0001o5oovmp301 ]];then
			DC="POK-SO-P3"
	elif [[ ${HOSTNAmE} = a0001o5oovmp401 ]];then
			DC="POK-SO-P4"
	elif [[ ${HOSTNAmE} = a0001o5oovmd101 ]];then
			DC="DAL-SO-D1"
	elif [[ ${HOSTNAmE} = a0001o5oovmd301 ]];then
			DC="DAL-SO-D3"
	elif [[ ${HOSTNAmE} = a0001o5oovmd401 ]];then
			DC="DAL-SO-D4"
	fi
	send_email
}

send_email(){
	echo 'Content-Type: text/html; charset="us-ascii" ' >> $emailifle
	echo "<html>" >> $emailifle
	echo "<Body>" >> $emailifle
	echo "<h1>"OVM Repository Utilization Report For ${DC}"</h1>" >>  $emailifle
	awk 'BEGIN{print "<table>"} {print "<tr>";for(i=1;i<=NF;i++)print "<td  style=\"border: 1px solid black; padding: 3px;\">" "\n" $i "\n" "</td>";print "</tr>"} END{print "</table>"}' $opfile  >> $emailifle

	echo "</Body>" >> $emailifle
	echo "</html>" >> $emailifle

	number=(`grep -E -n "^[9][0-9]|^[1][0][0]" $emailifle | awk -F ':' '{a=$1-1;print a}'`)
	for i in ${number[@]} 
	do
	  sed -i "$i s/.*/<td bgcolor=\"red\">/"  $emailifle
	done
	sed -i "s/<table>/<table align=\"center\" style=\"border: 1px solid black;border-collapse: collapse;width: 50%\">/" $emailifle
	(
	echo "From: noreply@ibm.com"
	echo "To: kmishra2@in.ibm.com, infra-ovm-alerts@wwpdl.vnet.ibm.com"
	echo "MIME-Version: 1.0"
	echo "Subject: OVM Repository Utilization Report For ${DC}" 
	echo "Content-Type: text/html" 
	cat $emailifle
	) | /usr/sbin/sendmail -t
	chmod 755 $opfile
	#/bin/cp $emailifle /OVMM_Data/repoutilization_data/
	#rm -rf $emailifle
}

collect_information
if [ $need_send_email -eq 1 ]
then
	set_data_center_name
fi