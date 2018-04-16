#!/bin/bash

# Name          : compareRpms.sh
# Author        : david.cerdas
# Version       : 1.0
# Copyright     : GPLv2
# Description   : This script compares a list of files(./listFiles.txt), between 2 uncompress Rpms in 
#				the same folder, it uses a word as reference.
# Usage         : ./compareRpms.sh <name of the directory of rpm1> <name of the directory of rpm2> <word>

rpm1="$1"
rpm2="$2"
word="$3"
srcPath="./$rpm1"

for file in $(sort ./listFiles.txt|uniq );do 
	echo "-----------------------"
	echo $file
	number=$(find $srcPath -name $file|wc -l)
	if [ $number -eq 1 ];then
		fileKernelA=$(find $srcPath -name $file)
		fileKernelB=$(echo $fileKernelA|sed "s/${rpm1}/${rpm2}/g")
		diff --suppress-common-lines -y $fileKernelA $fileKernelB
	else
		for fileX in $(egrep -m1 $word $(find $srcPath -name $file)|cut -d":" -f1);do
			fileKernelA=$fileX
			fileKernelB=$(echo $fileKernelA|sed "s/${rpm1}/${rpm2}/g")
			diff --suppress-common-lines -y $fileKernelA $fileKernelB
		done
	fi
done
