#!/bin/bash
# Copyright (C) <2014>  <Ding Wei>
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
# 170109 Create by Ding Wei

export LC_CTYPE=C
export LC_ALL=C
export USER=$(whoami)
export CMD=$1
export CMD_LIST=~/cmd.list
[[ -z $CMD && ! -f $CMD_LIST ]] && exit 1
[[ -f $CMD ]] && export DIST_FILE=$CMD

if [[ ! -d /dev/shm/inode.svn ]] ; then
    echo "Can NOT find /dev/shm/inode.svn"
    exit 1
fi

pushd /dev/shm/inode.svn
for DIST_HOST in $(grep IP= *)
do
    export DIST_HOSTNAME=$(echo $DIST_HOST | awk -F':' {'print $1'})
    export DIST_IP=$(echo $DIST_HOST | awk -F'IP=' {'print $2'})
    echo -e "-------------------- $DIST_HOSTNAME"
    if [[ ! -z $DIST_FILE ]] ; then
        export DIST_PATH=$(dirname $DIST_FILE)
        export DIST_FILENAME=$(basename $DIST_FILE)
        scp $DIST_FILE $DIST_IP:/tmp/
        ssh $DIST_IP "sudo cp /tmp/$DIST_FILENAME $DIST_FILE"
    fi
    [[ ! -z $CMD && -z $DIST_PATH ]] && ssh $DIST_IP "$CMD"
    if [[ -z $CMD && -f $CMD_LIST ]] ; then
         scp $CMD_LIST $DIST_IP:/tmp/cmd.list
         ssh $DIST_IP "bash /tmp/cmd.list && rm /tmp/cmd.list"
    fi
done
popd


