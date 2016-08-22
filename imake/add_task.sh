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
# 150123 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=$(whoami)
export SEED=$RANDOM
export BUILD_TIME=$(date +%y%m%d%H%M%S)
export BUILD_SEC_TIME=$(date +%s)
export TASK_SPACE=/dev/shm
export SPEC_URL=$1
export SPEC_NAME=$(basename $SPEC_URL)

export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=$(dirname $0 | awk -F'/ibuild' {'print $1'})'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

export LOCK_SPACE=/dev/shm/lock
mkdir -p $LOCK_SPACE >/dev/null 2>&1

if [[ -d $TASK_SPACE/$USER.tasks.lock.$SEED ]] ; then
	echo -e "$TASK_SPACE/$USER.tasks.lock.$SEED"
	exit
fi

export IBUILD_SVN_SRV=$(grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'})
export IBUILD_SVN_OPTION=$(grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'})
export ITASK_SVN_OPTION=$(grep '^ITASK_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'ITASK_SVN_OPTION=' {'print $2'})
    [[ -z $ITASK_SVN_OPTION ]] && export ITASK_SVN_OPTION=$IBUILD_SVN_SRV

if [[ ! -f $SPEC_URL ]] ; then
	echo -e "cat not find $SPEC_URL"
	exit
fi

svn co -q $IBUILD_SVN_OPTION svn://$ITASK_SVN_SRV/itask/itask/tasks $TASK_SPACE/$USER.tasks.lock.$SEED

cp $SPEC_URL $TASK_SPACE/$USER.tasks.lock.$SEED/$BUILD_TIME$RADOM.$SPEC_NAME
svn add $TASK_SPACE/$USER.tasks.lock.$SEED/$BUILD_TIME$RADOM.$SPEC_NAME >/dev/null 2>&1
svn ci $IBUILD_SVN_OPTION -m "auto: submit $SPEC_NAME" $TASK_SPACE/$USER.tasks.lock.$SEED/$BUILD_TIME$RADOM.$SPEC_NAME >/tmp/add_task.log 2>&1
[[ $? = 0 ]] && rm -fr $TASK_SPACE/$USER.tasks.lock.$SEED
grep 'Committed revision' /tmp/add_task.log
sleep 1

