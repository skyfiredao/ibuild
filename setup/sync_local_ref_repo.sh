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
# 141216: Ding Wei init
# 160322: support btrfs by Ding Wei

export LC_CTYPE=C
export JOBS=$(cat /proc/cpuinfo | grep CPU | wc -l)
export TASK_SPACE=/run/shm
export TOHOUR=$(date +%H)
export LOC_REF_REPO=/local/ref_repo
export CMD_REPO=$(which repo)
if [[ -z $CMD_REPO ]] ; then
    echo "Can NOT find repo command"
    exit
fi

export LOCK_SPACE=/dev/shm/lock
mkdir -p $LOCK_SPACE >/dev/null 2>&1

if [[ `cat $LOCK_SPACE/repo_sync.lock` != $TOHOUR && `ps aux | grep rsync | grep -v grep` ]] ; then
    exit
fi

echo $TOHOUR >$LOCK_SPACE/repo_sync.lock

REPO_SYNC()
{
 cd $1
 $CMD_REPO sync -j$JOBS >/tmp/repo_sync.log 2>&1
 export SYNC_STATUS=$?
}

BTRFS_SYNC()
{
 [[ ! -d $LOC_REF_REPO/tmp.$SRV_NAME ]] && btrfs subvolume snapshot $LOC_REF_REPO/$SRV_NAME $LOC_REF_REPO/tmp.$SRV_NAME
 REPO_SYNC $LOC_REF_REPO/tmp.$SRV_NAME
 if [[ $SYNC_STATUS = 0 && -d $LOC_REF_REPO/tmp.$SRV_NAME ]] ; then
    [[ ! -d $LOC_REF_REPO/old.$SRV_NAME ]] && mv $LOC_REF_REPO/$SRV_NAME $LOC_REF_REPO/old.$SRV_NAME
    [[ ! -d $LOC_REF_REPO/$SRV_NAME ]] && mv $LOC_REF_REPO/tmp.$SRV_NAME $LOC_REF_REPO/$SRV_NAME
 else
    echo "sync issue: $SRV_NAME"
 fi
 [[ -d $LOC_REF_REPO/$SRV_NAME/.repo ]] && sudo btrfs subvolume delete $LOC_REF_REPO/old.$SRV_NAME $LOC_REF_REPO/tmp.$SRV_NAME >/dev/null 2>&1
}

for SRV_NAME in `ls $LOC_REF_REPO/*/.repo | grep ":" | awk -F'/.repo' {'print $1'} | awk -F"$LOC_REF_REPO/" {'print $2'}`
do
    if [[ `sudo btrfs subvolume list $LOC_REF_REPO | grep $SRV_NAME` ]] ; then
        BTRFS_SYNC
    else
        REPO_SYNC $LOC_REF_REPO/$SRV_NAME
        [[ $SYNC_STATUS != 0 ]] && echo "sync issue: $SRV_NAME"
    fi
done


