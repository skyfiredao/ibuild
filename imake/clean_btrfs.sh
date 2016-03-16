#!/bin/bash
# Copyright (C) <2014,2015>  <Ding Wei>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Change log
# 150120 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export TASK_SPACE=/dev/shm
export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

export LOC_WORKSPACE=`grep '^LOC_WORKSPACE=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'LOC_WORKSPACE=' {'print $2'}`
if [[ -z $1 ]] ; then
	echo ------------------------
	sudo btrfs subvolume list $LOC_WORKSPACE
	echo ------------------------
	echo $0 a
	echo btrfs subvolume delete
	echo ------------------------
	exit 0
fi

CLEAN_SUBV_REPO()
{
 for SUBV_REPO_MD5 in `ls $LOC_WORKSPACE/subv_repo | egrep -v 'info'`
 do
	if [[ ! -f $LOC_WORKSPACE/subv_repo/$SUBV_REPO_MD5/Makefile || `cat $LOC_WORKSPACE/subv_repo/$SUBV_REPO_MD5.info | grep mirror` ]] ; then
		export SEED=$RANDOM
		echo -------------------------
		echo $LOC_WORKSPACE/subv_repo/$SUBV_REPO_MD5
		echo $LOC_WORKSPACE/build/bad.$SEED
		cat $LOC_WORKSPACE/subv_repo/$SUBV_REPO_MD5.info
		echo -------------------------
		mv $LOC_WORKSPACE/subv_repo/$SUBV_REPO_MD5 $LOC_WORKSPACE/build/bad.$SEED
		mv $LOC_WORKSPACE/subv_repo/$SUBV_REPO_MD5.info $LOC_WORKSPACE/build/bad.$SEED/
	fi
 done
}

CLEAN_STEPS()
{
 echo "sudo btrfs subvolume list $LOC_WORKSPACE"

 for BTRFS_SUBVOL in `sudo btrfs subvolume list $LOC_WORKSPACE | egrep -v 'subv_repo' | awk -F'path ' {'print $2'} | awk -F'build/' {'print $2'}`
 do
	sleep 3
	echo "sudo btrfs subvolume delete $LOC_WORKSPACE/$BTRFS_SUBVOL"
	sudo btrfs subvolume delete $LOC_WORKSPACE/build/$BTRFS_SUBVOL &
 done
}

if [[ ! -f $TASK_SPACE/spec.build ]] ; then
	CLEAN_SUBV_REPO
	CLEAN_STEPS
else
	echo $TASK_SPACE/spec.build
	exit
fi


