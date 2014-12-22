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
# 140317: Ding Wei created it NCIC
# 141217: Ding Wei change for pek12

export RUN_PATH=`dirname $0`
[[ `echo $RUN_PATH | grep '^./'` ]] && export RUN_PATH=`pwd`/`echo $RUN_PATH | sed 's/^.\///g'`
export IBUILD_ROOT=`echo $RUN_PATH | awk -F'/ibuild' {'print $1'}`/ibuild
#export TASK_SPACE=`df | grep shm | grep none | tail -n1 | awk -F' ' {'print $6'}`
export TASK_SPACE=/run/shm
export GERRIT_SRV_LIST="TBD_gerrit"
export DOMAIN_NAME="TBD.com"
export GERRIT_SRV_PORT="TBD_port"
export GERRIT_ROBOT="TBD_robot"

STREAM_EVENTS()
{
 local GERRIT_SRV=$1
 local GERRIT_SERVER=$GERRIT_ROBOT@$GERRIT_SRV.$DOMAIN_NAME

 if [[ ! `ps aux | grep ssh | grep $GERRIT_SRV` ]] ; then
        ssh $GERRIT_SERVER -p $GERRIT_SRV_PORT gerrit stream-events | while read -r
        do
                export ORDER=`date +%y%m%d%H%M%S`.$RANDOM
                echo $REPLY >$TASK_SPACE/itrack/$GERRIT_SRV.json/$ORDER.json
                $RUN_PATH/json2svn.sh $TASK_SPACE/itrack/$GERRIT_SRV.json $GERRIT_SRV >/tmp/json2svn.log 2>&1 &
        done
 fi
 $RUN_PATH/json2svn.sh $TASK_SPACE/itrack/$GERRIT_SRV.json $GERRIT_SRV >/tmp/json2svn.log 2>&1 &
}

for GERRIT_SRV in $GERRIT_SRV_LIST
do
        export GERRIT_SERVER=$GERRIT_ROBOT@$GERRIT_SRV.$DOMAIN_NAME
        mkdir -p $TASK_SPACE/itrack/$GERRIT_SRV.json >/dev/null
        cd $TASK_SPACE/itrack/$GERRIT_SRV.json

        STREAM_EVENTS $GERRIT_SRV &
done

ps aux | grep ssh | grep gerrit
