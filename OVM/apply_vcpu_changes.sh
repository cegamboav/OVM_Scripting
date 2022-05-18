#!/bin/bash

#Script to identify if a LUN is used by any running VM in CMS environment.

#Variables
servers=$1
start=$2
end=$3
password=$4
mngr=$5

vcpu_start=()
vcpu_end=()

for i in `cat $start`
do
	vcpu_start+=($i)
done

for i in `cat $end`
do
	vcpu_end+=($i)
done

echo
echo
echo
j=0
for i in `cat $servers`
do 
	echo $i
	echo "Checking VM status server:"
	./ovm_vmcontrol -u Admin -p $password -h $mngr -U $i -c getvcpu|grep Current
	echo "-----------------"
	echo "Applying pinning:"
	echo "./ovm_vmcontrol -u Admin -p $password -h $mngr -U $i -c setvcpu -s "${vcpu_start[j]}"-"${vcpu_end[j]}""
	./ovm_vmcontrol -u Admin -p $password -h $mngr -U $i -c setvcpu -s "${vcpu_start[j]}"-"${vcpu_end[j]}"|grep vCPU
	echo "-----------------"
	echo "Checking VM status server:"
	./ovm_vmcontrol -u Admin -p $password -h $mngr -U $i -c getvcpu|grep Current
	j=$((j+1))
	echo "+++++++++++++++++++++++++++++++++++"
done
echo "======================================================"
echo
echo
echo
