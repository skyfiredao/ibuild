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
[[ `echo $* | grep debug` ]] && export DEBUG=echo

export IBUILD_ROOT=$HOME/ibuild
	[[ ! -d $HOME/ibuild ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

export ITRACK_PATH=$IBUILD_ROOT/ichange
svn up -q $IBUILD_ROOT

#export TASK_SPACE=`df | grep shm | grep none | tail -n1 | awk -F' ' {'print $6'}`
export TASK_SPACE=/run/shm
export HOSTNAME=`hostname`
if [[ ! -f $ITRACK_PATH/conf/$HOSTNAME.conf ]] ; then
        echo -e "Can NOT find $ITRACK_PATH/conf/$HOSTNAME.conf"
        for KILL_PID in `ps aux | grep ssh | grep gerrit | awk -F' ' {'print $2'}`
        do
                kill -9 $KILL_PID
                echo -e "kill stream-events"
        done
        exit 1
fi

export DOMAIN_NAME=`cat $ITRACK_PATH/conf/$HOSTNAME.conf | grep 'DOMAIN_NAME=' | awk -F'DOMAIN_NAME=' {'print $2'}`
export GERRIT_SRV_LIST=`cat $ITRACK_PATH/conf/$HOSTNAME.conf | grep 'GERRIT_SRV_LIST=' | awk -F'GERRIT_SRV_LIST=' {'print $2'}`
export GERRIT_SRV_PORT=`cat $ITRACK_PATH/conf/$HOSTNAME.conf | grep 'GERRIT_SRV_PORT=' | awk -F'GERRIT_SRV_PORT=' {'print $2'}`
export GERRIT_ROBOT=`cat $ITRACK_PATH/conf/$HOSTNAME.conf | grep 'GERRIT_ROBOT=' | awk -F'GERRIT_ROBOT=' {'print $2'}`

STREAM_EVENTS()
{
 local GERRIT_SRV=$1
 local GERRIT_SERVER=$GERRIT_ROBOT@$GERRIT_SRV.$DOMAIN_NAME

 if [[ ! `ps aux | grep ssh | grep $GERRIT_SRV` ]] ; then
        ssh $GERRIT_SERVER -p $GERRIT_SRV_PORT gerrit stream-events | while read -r
        do
                export ORDER=`date +%y%m%d%H%M%S`.$RANDOM
                echo $REPLY >$TASK_SPACE/itrack/$GERRIT_SRV.json/$ORDER.json
                $ITRACK_PATH/json2svn.sh $TASK_SPACE/itrack/$GERRIT_SRV.json $GERRIT_SRV >/tmp/json2svn.log 2>&1 &
        done
 fi
 $ITRACK_PATH/json2svn.sh $TASK_SPACE/itrack/$GERRIT_SRV.json $GERRIT_SRV >/tmp/json2svn.log 2>&1 &
}

for GERRIT_SRV in $GERRIT_SRV_LIST
do
        export GERRIT_SERVER=$GERRIT_ROBOT@$GERRIT_SRV.$DOMAIN_NAME
        mkdir -p $TASK_SPACE/itrack/$GERRIT_SRV.json >/dev/null
        cd $TASK_SPACE/itrack/$GERRIT_SRV.json

        STREAM_EVENTS $GERRIT_SRV &
done

[[ ! -z $DEBUG ]] && ps aux | grep ssh | grep gerrit
