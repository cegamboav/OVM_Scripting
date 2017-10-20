#!/bin/bash

# Name        	: lvmCreateRepoAndServerPool.sh
# Author      	: david.cerdas
# Version     	: 1.0
# Copyright   	: GPLv2
# Description   : This script helps to create 2 NFS shares using a single disk
# Usage         : lvmCreateRepoAndServerPool.sh "/dev/disk"



if [ -z != $1 ];then
	pvcreate $1
	vgcreate vgStorage $1
	vgs
	lvcreate   -l 50%FREE -n repository vgStorage
	lvcreate   -l 100%FREE -n serverPool vgStorage

	mkfs.ext4 /dev/vgStorage/repository
	mkfs.ext4 /dev/vgStorage/serverPool

	e2label /dev/vgStorage/repository RepoNFS
	e2label /dev/vgStorage/serverPool serverPoolNFS

	mkdir /storage
	mkdir /storage/repository
	mkdir /storage/serverPool

	echo "/dev/mapper/vgStorage-repository /storage/repository  ext4 defaults        0 0" >> /etc/fstab
	echo "/dev/mapper/vgStorage-serverPool /storage/serverPool  ext4 defaults        0 0" >> /etc/fstab


	mount /storage/repository 
	mount /storage/serverPool
	clear
	df |egrep "repository|serverPool"
else
	echo "Please specify the disk to use"
	echo "lvmCreateRepoAndServerPool.sh '/dev/sdb' "
fi
