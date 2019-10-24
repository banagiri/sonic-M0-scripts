#!/bin/bash

# Copyright (c) Marvell, Inc. All rights reservered. Confidential.
# Description: Applying open PRs needed for ARM arch compilation

ver=`docker info --format '{{json .ServerVersion}}'`
if [ ${ver:1:2} -gt 18 ]
then
	echo -e "FATAL: Docker version should be 18.x.y, \nplease execute below commands\n"
	echo "$ sudo apt-get install --allow-downgrades  -y docker-ce=5:18.09.0~3-0~ubuntu-xenial"
	echo "$ sudo apt-get install --allow-downgrades  -y docker-ce-cli=5:18.09.0~3-0~ubuntu-xenial"
	exit
fi


url="https://github.com/Azure"
urlsai="https://patch-diff.githubusercontent.com/raw/opencomputeproject"

declare -a PATCHES=(P1 P2 P5)
declare -A P1=( [NAME]=sonic-buildimage [DIR]=. [PR]="3392 3644" [URL]="$url" )
declare -A P2=( [NAME]=sonic-swss [DIR]=src/sonic-swss [PR]=1015 [URL]="$url" )
#declare -A P3=( [NAME]=sonic-utilities [DIR]=src/sonic-utilities [PR]=619 [URL]="$url" )
#declare -A P4=( [NAME]=SAI [DIR]=src/sonic-sairedis/SAI [PR]="993 969" [URL]="$urlsai" )
declare -A P5=( [NAME]=sonic-linux-kernel [DIR]=src/sonic-linux-kernel [PR]=102 [URL]="$url" )

CWD=`pwd`

#URL_CMD="wget $url/$module/pull/$pr.diff"
for f in ${PATCHES[*]}
do
	P_NAME=${f}[NAME]
	echo "INFO: ${!P_NAME} ... "
	P_DIR=${f}[DIR]
	echo "CMD: cd ${!P_DIR}"
	cd ${!P_DIR}
	P_PRS=${f}[PR]
	P_URL=${f}[URL]
	for p in ${!P_PRS}
	do
		echo "INFO: URL ${!P_URL}/${!P_NAME}/pull/${p}.diff"
		rm -f ${p}.diff || true
		wget "${!P_URL}/${!P_NAME}/pull/${p}.diff"
		if [ -f ${p}.diff ]
		then
			echo "INFO: patch -p1 < ${p}.diff"
			patch -p1 -f --dry-run < ${p}.diff
			if [ $? -eq 0 ]; then
				echo "INFO: Applying patch"
				patch -p1 < ${p}.diff
				else
				echo "ERROR: Patch ${!P_NAME} ${p} has failures, try manually"
				fi
			rm -f ${p}.diff
		else
			echo "ERROR: Could not download patch ${!P_NAME} ${p}.diff"
		fi
			
	done
	cd ${CWD}
done

# Workarounds for Build machine
# Change docker spawn wait time to 4 sec
#cd sonic-buildimage
sed -i 's/sleep 1/sleep 4/g' Makefile.work
