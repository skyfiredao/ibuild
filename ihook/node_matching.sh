#!/bin/bash -x
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
# 150122 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export SEED=$RANDOM
export TASK_SPACE=/dev/shm
export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=$(dirname $0 | awk -F'/ibuild' {'print $1'})'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi
export LOCK_SPACE=/dev/shm/lock
mkdir -p $LOCK_SPACE >/dev/null 2>&1
chmod 777 -R $LOCK_SPACE >/dev/null 2>&1

source $IBUILD_ROOT/imake/function node_matching
EXPORT_IBUILD_CONF

EXIT()
{
 rm -f $LOCK_SPACE/itask-r$ITASK_REV.lock
 rm -f $LOCK_SPACE/itask-r$ITASK_REV.jobs
 exit
}

MATCHING()
{
 export LEVEL_NUMBER=$1
 export FREE_NODE=''

 if [[ ! -d $TASK_SPACE/inode.svn ]] ; then
     svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask/inode $TASK_SPACE/inode.svn
     chmod 777 -R $TASK_SPACE/inode.svn >/dev/null 2>&1
 else
    svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/inode.svn 
 fi

 if [[ ! -d $LOCK_SPACE/inode ]] ; then
     mkdir -p $LOCK_SPACE/inode >/dev/null 2>&1
     rsync -r --delete --exclude ".svn" $TASK_SPACE/inode.svn/ $LOCK_SPACE/inode/
 fi

 for NODE in `cat $IBUILD_ROOT/conf/priority/[$LEVEL_NUMBER]-floor.conf`
 do
     if [[ -f $TASK_SPACE/inode.svn/$NODE && -f $LOCK_SPACE/inode/$NODE ]] ; then
         /bin/cp $TASK_SPACE/inode.svn/$NODE $LOCK_SPACE/inode/ >/dev/null 2>&1
     elif [[ ! -f $TASK_SPACE/inode.svn/$NODE ]] ; then
        rm -f $LOCK_SPACE/inode/$NODE
     fi
 done

 for NODE in `cat $IBUILD_ROOT/conf/priority/[$IBUILD_PRIORITY]-floor.conf`
 do
     if [[ -f $TASK_SPACE/inode.svn/$NODE && -f $LOCK_SPACE/inode/$NODE ]] ; then
         export FREE_NODE=true
         /bin/cp $TASK_SPACE/inode.svn/$NODE $LOCK_SPACE/inode/ >/dev/null 2>&1
         break
     fi
 done

 if [[ -z $FREE_NODE ]] ; then
     svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/inode.svn
     chmod 777 -R $TASK_SPACE/inode.svn >/dev/null 2>&1
     mkdir -p $LOCK_SPACE/inode >/dev/null 2>&1
     rsync -r --delete --exclude ".svn" $TASK_SPACE/inode.svn/ $LOCK_SPACE/inode/
 fi

 for NODE in `cat $IBUILD_ROOT/conf/priority/[$LEVEL_NUMBER]-floor.conf`
 do
     if [[ -f $LOCK_SPACE/inode/$NODE ]] ; then
         export NODE_IP=$(grep '^IP=' $LOCK_SPACE/inode/$NODE | awk -F'IP=' {'print $2'}) 
         export NODE_MD5=$(echo $NODE | md5sum | awk -F' ' {'print $1'})

         echo $ITASK_REV | $NETCAT $NODE_IP 1234 >/dev/null 2>&1
         sleep 1

         $NETCAT $NODE_IP 4321 >$LOCK_SPACE/itask-r$ITASK_REV.jobs
         [[ `grep $ITASK_REV_MD5 $LOCK_SPACE/itask-r$ITASK_REV.jobs` ]] && ASSIGN_JOB
     fi
 done
}

ASSIGN_JOB()
{
 if [[ `cat $LOCK_SPACE/itask-r$ITASK_REV.jobs | grep $ITASK_REV_MD5 | grep $NODE_MD5` ]] ; then
    echo "$ITASK_REV|$NODE|$NODE_IP|$ITASK_SPEC_NAME" >>$ITASK_PATH/jobs.txt
    svn ci -q $IBUILD_SVN_OPTION -m "auto: assign itask-r$ITASK_REV to $NODE" $ITASK_PATH/jobs.txt
#    svn rm -q $IBUILD_SVN_OPTION -m "auto: remove $PRIORITY_ITASK_REV" svn://$IBUILD_SVN_SRV/itask/queue/itask/$PRIORITY_ITASK_REV
    rm -f $QUEUE_SPACE/*.$ITASK_REV
#    svn up -q $IBUILD_SVN_OPTION $QUEUE_SPACE
#    if [[ -f $QUEUE_SPACE/$PRIORITY_ITASK_REV ]] ; then
#        rm -fr $QUEUE_SPACE
#        svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/queue $QUEUE_SPACE
#        chmod 777 -R $QUEUE_SPACE
#    fi
#     export QUEUE_SPACE_C=$(svn st $QUEUE_SPACE | grep '^!' | awk -F' ' {'print $3'} | head -n1)
#     if [[ ! -z $QUEUE_SPACE_C ]] ; then
#         svn revert -q $QUEUE_SPACE_C
#         svn rm --force $QUEUE_SPACE_C
#         sleep 1
#     fi
 fi
 rm -f $LOCK_SPACE/inode/$NODE
 EXIT
}

export QUEUE_SPACE=$1
    [[ -z $QUEUE_SPACE ]] && export QUEUE_SPACE=/local/queue/itask
export TOWEEK=$(date +%yw%V)
export TODAY=$(date +%y%m%d)

for PRIORITY_ITASK_REV in `ls $QUEUE_SPACE`
do
	export IBUILD_PRIORITY=$(echo $PRIORITY_ITASK_REV | awk -F'.' {'print $1'})
	export ITASK_REV=$(echo $PRIORITY_ITASK_REV | awk -F'.' {'print $2'})
	[[ -f /tmp/EXIT ]] && EXIT
	echo $ITASK_REV >$LOCK_SPACE/queue_itask.lock
	chmod 777 $LOCK_SPACE/queue_itask.lock

	if [[ -f $TASK_SPACE/itask/itask.svn.$TODAY.lock && -d $TASK_SPACE/itask/itask.svn/.svn ]] ; then
		svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/itask/itask.lock
	else
		mkdir -p $TASK_SPACE/itask 
		rm -fr $TASK_SPACE/itask/itask.svn*
		touch $TASK_SPACE/itask/itask.svn.$TODAY.lock
		svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask $TASK_SPACE/itask/itask.svn
	fi
	chmod 777 -R $TASK_SPACE/itask
	export ITASK_PATH=$TASK_SPACE/itask/itask.svn

	export ITASK_REV_MD5=$(echo $ITASK_REV | md5sum | awk -F' ' {'print $1'})
	export ITASK_SPEC_URL=$(svn log -v -r $ITASK_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask | egrep 'A |M ' | awk -F' ' {'print $2'} | head -n1)
	export ITASK_SPEC_NAME=$(basename $ITASK_SPEC_URL)

	rm -f $LOCK_SPACE/itask-r$ITASK_REV.lock
	svn export -q -r $ITASK_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/$ITASK_SPEC_URL $LOCK_SPACE/itask-r$ITASK_REV.lock
	[[ -z $IBUILD_PRIORITY ]] && export IBUILD_PRIORITY=$(grep '^IBUILD_PRIORITY=' $LOCK_SPACE/itask-r$ITASK_REV.lock | awk -F'IBUILD_PRIORITY=' {'print $2'})
	if [[ $IBUILD_PRIORITY = x ]] ; then
		export IBUILD_PRIORITY=2-9
	elif [[ -z $IBUILD_PRIORITY ]] ; then
		export IBUILD_PRIORITY=1-9
	fi
	export LEVEL_NUMBER=$IBUILD_PRIORITY

	MATCHING $LEVEL_NUMBER
done

EXIT

