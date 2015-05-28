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
# 150306 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=$(whoami)
export TASK_SPACE=/run/shm
export HOSTNAME=$(hostname)
export TOWEEK=$(date +%yw%V)
export TOYEAR=$(date +%Y)

export IVERIFY_ROOT=$HOME/iverify
export IVERIFY_CONF=$HOME/iverify/conf/iverify.conf
export IVERIFY_IGNORE_CONF=$HOME/iverify/script/ignore.conf
export IVERIFY_SVN_SRV=$(grep '^IVERIFY_SVN_SRV=' $IVERIFY_CONF | awk -F'IVERIFY_SVN_SRV=' {'print $2'})
export IVERIFY_SVN_OPTION=$(grep '^IVERIFY_SVN_OPTION=' $IVERIFY_CONF | awk -F'IVERIFY_SVN_OPTION=' {'print $2'})

if [[ ! -f $HOME/iverify/conf/iverify.conf ]] ; then
    echo -e "Please put iverify in your $HOME"
    exit 0
fi

echo ------------------------- `date`

EXIT()
{
 svn cleanup ~/iverify >/dev/null 2>&1
 svn up -q ~/iverify >/dev/null 2>&1
 rm -f $IVERIFY_SPACE/build_info.$SEED
 exit
}

LOCAL_QUEUE()
{
 export NETCAT=$(which nc)
     [[ -z $NETCAT ]] && export NETCAT="$IVERIFY_ROOT/bin/netcat.openbsd-u14.04"
 export HOST_MD5=$(echo $HOSTNAME | md5sum | awk -F' ' {'print $1'})
 export NOW=$(date +%y%m%d%H%M%S)
 export SEED=$NOW.$RANDOM

# alias ncstop='nc 127.0.0.1 4444;nc 127.0.0.1 5555'
 $NETCAT -l 4444 >$IVERIFY_SPACE/build_info.$SEED
 export IVER=$(grep '^IVER=' $IVERIFY_SPACE/build_info.$SEED | awk -F'IVER=' {'print $2'})
     [[ -z $IVER ]] && EXIT

 mv $IVERIFY_SPACE/build_info.$SEED $IVERIFY_SPACE/$IVER.build_info >/dev/null 2>&1 
 export IBUILD_TARGET_PRODUCT=$(grep '^IBUILD_TARGET_PRODUCT=' $IVERIFY_SPACE/$IVER.build_info | awk -F'IBUILD_TARGET_PRODUCT=' {'print $2'})
 export ITASK_REV=$(grep '^ITASK_REV=' $IVERIFY_SPACE/$IVER.build_info | awk -F'ITASK_REV=' {'print $2'})
 export ITASK_ORDER=$(grep '^ITASK_ORDER=' $IVERIFY_SPACE/$IVER.build_info | awk -F'ITASK_ORDER=' {'print $2'} | head -n1)
 [[ ! -z $ITASK_ORDER ]] && export ITASK_TMP=$ITASK_ORDER || export ITASK_TMP=$ITASK_REV
 export NEW_BUILD_INFO_NAME=$IVER.$ITASK_TMP.$IBUILD_TARGET_PRODUCT.build_info

 $NETCAT 127.0.0.1 5555
 echo "$NOW|$IVER|$HOSTNAME" | $NETCAT -l 5555
 cat $IVERIFY_CONF | egrep 'EMAIL' >>$IVERIFY_SPACE/$IVER.build_info
 /bin/mv $IVERIFY_SPACE/$IVER.build_info $LOCAL_IVERIFY_QUEUE/$NEW_BUILD_INFO_NAME
 SETUP_ISTATUS "iverify local queue: $HOSTNAME:$LOCAL_IVERIFY_QUEUE/$NEW_BUILD_INFO_NAME"
 if [[ `cat $IVERIFY_IGNORE_CONF | egrep "^$ITASK_TMP$"` ]] ; then
    rm -f $LOCAL_IVERIFY_QUEUE/$NEW_BUILD_INFO_NAME
    SETUP_ISTATUS "iverify ignore: $NEW_BUILD_INFO_NAME"
 else 
    echo $LOCAL_IVERIFY_QUEUE/$NEW_BUILD_INFO_NAME
    $IVERIFY_ROOT/bin/iverify_node_run >/tmp/iverify_node_run.log 2>&1 &
 fi
}

SETUP_ISTATUS()
{
 export ISTATUS_ENTRY=$1

 if [[ ! -d $TASK_SPACE/istatus-$TOWEEK ]] ; then
     rm -fr $TASK_SPACE/istatus-* >/dev/null 2>&1
     svn co -q $IVERIFY_SVN_OPTION svn://$IVERIFY_SVN_SRV/istatus/$TOYEAR/$TOWEEK $TASK_SPACE/istatus-$TOWEEK
     if [[ $? != 0 ]] ; then
         svn mkdir -q $IVERIFY_SVN_OPTION -m "auto: add istatus/$TOYEAR/$TOWEEK" svn://$IVERIFY_SVN_SRV/istatus/$TOYEAR/$TOWEEK >/dev/null 2>&1
         svn co -q $IVERIFY_SVN_OPTION svn://$IVERIFY_SVN_SRV/istatus/$TOYEAR/$TOWEEK $TASK_SPACE/istatus-$TOWEEK
     fi
 else
     svn up -q $IVERIFY_SVN_OPTION $TASK_SPACE/istatus-$TOWEEK
 fi

 touch $TASK_SPACE/istatus-$TOWEEK/$ITASK_REV
 touch $TASK_SPACE/istatus-$TOWEEK/$ITASK_ORDER
 if [[ $ITASK_REV = $ITASK_ORDER && -f $TASK_SPACE/istatus-$TOWEEK/$ITASK_REV ]] ; then
     echo `date +%y%m%d-%H%M%S`"|$HOSTNAME|$ISTATUS_ENTRY" >>$TASK_SPACE/istatus-$TOWEEK/$ITASK_REV
 elif [[ ! -z $ITASK_ORDER && -f $TASK_SPACE/istatus-$TOWEEK/$ITASK_REV ]] ; then
     echo `date +%y%m%d-%H%M%S`"|$HOSTNAME|$ISTATUS_ENTRY" >>$TASK_SPACE/istatus-$TOWEEK/$ITASK_ORDER
 fi

 svn add $TASK_SPACE/istatus-$TOWEEK/$ITASK_REV >/dev/null 2>&1
 svn add $TASK_SPACE/istatus-$TOWEEK/$ITASK_ORDER >/dev/null 2>&1
 svn ci -q $IVERIFY_SVN_OPTION -m "auto: add $ITASK_REV" $TASK_SPACE/istatus-$TOWEEK/*
}

export IVERIFY_SPACE=$TASK_SPACE/iverify
export ADB=$IVERIFY_ROOT/bin/adb
export LOCAL_IVERIFY_QUEUE=$HOME/iverify.queue.local
mkdir -p $LOCAL_IVERIFY_QUEUE >/dev/null 2>&1

while [[ ! `ps aux | grep -v grep | grep nc | grep 4444` ]] ;
do
    if [[ -f $IVERIFY_SPACE/EXIT  ]] ; then
        EXIT
    fi
    LOCAL_QUEUE
done

EXIT

