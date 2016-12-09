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
export TODAY=$(date +%y%m%d)
export TOWEEK=$(date +%yw%V)

export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=$(dirname $0 | awk -F'/ibuild' {'print $1'})'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

export IBUILD_SVN_SRV=$(grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'})
export IBUILD_SVN_OPTION=$(grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'})
export LOCK_SPACE=/dev/shm/lock
mkdir -p $LOCK_SPACE >/dev/null 2>&1
chmod 777 -R $LOCK_SPACE >/dev/null 2>&1

export QUEUE_SPACE=/local/queue/itask
export QUEUE_SPACE_TOP=$(dirname $QUEUE_SPACE)
#if [[ ! -d $QUEUE_SPACE_TOP ]] ; then
#    svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/queue $QUEUE_SPACE_TOP 
#    chmod 777 -R $QUEUE_SPACE_TOP
#else
#    svn cleanup $QUEUE_SPACE_TOP
#    svn up -q $IBUILD_SVN_OPTION $QUEUE_SPACE_TOP
#fi

export ITASK_REV=$1
export ITASK_SPEC_URL=$(svn log -v -r $ITASK_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask | egrep 'A |M ' | awk -F' ' {'print $2'} | head -n1)
echo itask: `ls $QUEUE_SPACE | wc -l`
echo inode: `ls $LOCK_SPACE/inode | wc -l`

if [[ `echo $ITASK_SPEC_URL | grep '^/itask/tasks'` ]] ; then
    export ITASK_SPEC_NAME=$(basename $ITASK_SPEC_URL)
    export IBUILD_PRIORITY=$(svn cat -r $ITASK_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask/tasks/$ITASK_SPEC_NAME | grep '^IBUILD_PRIORITY=' | awk -F'IBUILD_PRIORITY=' {'print $2'} | tail -n1)
    [[ -z $IBUILD_PRIORITY ]] && export IBUILD_PRIORITY=x

    svn cp -q $IBUILD_SVN_OPTION -m "auto: add $IBUILD_PRIORITY.$ITASK_REV" \
    svn://$IBUILD_SVN_SRV/itask/queue/.zero \
    svn://$IBUILD_SVN_SRV/itask/queue/itask/$IBUILD_PRIORITY.$ITASK_REV
    svn up -q $IBUILD_SVN_OPTION $QUEUE_SPACE
    [[ ! -f $QUEUE_SPACE/$IBUILD_PRIORITY.$ITASK_REV ]] && touch $QUEUE_SPACE/$IBUILD_PRIORITY.$ITASK_REV

    if [[ -d $TASK_SPACE/ispec.svn/.svn ]] ; then
	svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/ispec.svn
    else
        rm -fr $TASK_SPACE/ispec.svn >/dev/null 2>&1
        svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/ispec/ispec $TASK_SPACE/ispec.svn
    fi
    if [[ ! `grep "# $TODAY$" $TASK_SPACE/ispec.svn/queue/itask-$TOWEEK.list` ]] ; then
        echo "# $TODAY" >>$TASK_SPACE/ispec.svn/queue/itask-$TOWEEK.list
        svn add $TASK_SPACE/ispec.svn/queue/itask-$TOWEEK.list >/dev/null 2>&1
        chmod 777 -R $TASK_SPACE/ispec.svn
        svn ci -q $IBUILD_SVN_OPTION -m 'auto add queue history' $TASK_SPACE/ispec.svn/queue
    fi
    echo $IBUILD_PRIORITY.$ITASK_REV >>$TASK_SPACE/ispec.svn/queue/itask-$TOWEEK.list

    chmod 755 -R $QUEUE_SPACE
elif [[ `echo $ITASK_SPEC_URL | grep 'jobs.txt$'` ]] ; then
    $IBUILD_ROOT/ihook/mail_itask.sh $ITASK_REV
else
    exit
fi

if [[ -f $LOCK_SPACE/queue_itask.lock ]] ; then
    echo $LOCK_SPACE/queue_itask.lock
    exit
fi

while [[ `ls $QUEUE_SPACE` ]] ;
do
    if [[ -f /tmp/EXIT ]] ; then
        rm -f $LOCK_SPACE/queue_itask.lock
        exit
    fi
    svn cleanup $QUEUE_SPACE_TOP
    $IBUILD_ROOT/ihook/node_matching.sh $QUEUE_SPACE >/tmp/node_matching.log 2>&1
    sleep `expr $RANDOM % 3 + 1`
done

if [[ -d $TASK_SPACE/inode.svn/.svn ]] ; then
    svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/inode.svn
    mkdir -p $LOCK_SPACE/inode >/dev/null 2>&1
fi

rm -f $LOCK_SPACE/queue_itask.lock

