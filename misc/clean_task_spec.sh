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
export USER=`whoami`
export BUILD_SEC_TIME=`date +%s`
export SEED=$BUILD_SEC_TIME.$RANDOM
export BUILD_TIME=`date +%y%m%d%H%M%S`
export TASK_SPACE=/dev/shm

export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -e $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

if [[ -e $TASK_SPACE/$USER.tasks.lock.$SEED ]] ; then
	echo -e "$TASK_SPACE/$USER.tasks.lock.$SEED"
	exit
fi

export IBUILD_SVN_SRV=`grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'}`
export IBUILD_SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`
export KEEP_SPEC=300

svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask/tasks $TASK_SPACE/$USER.tasks.lock.$SEED
while [ `ls $TASK_SPACE/$USER.tasks.lock.$SEED | grep spec.build | wc -l` -ge $KEEP_SPEC ] ;
do
	export OLD_TASK_SPEC=`ls $TASK_SPACE/$USER.tasks.lock.$SEED | grep spec.build | head -n1`
	svn rm -q $TASK_SPACE/$USER.tasks.lock.$SEED/$OLD_TASK_SPEC
done
svn ci $IBUILD_SVN_OPTION -m "auto: clean more than $KEEP_SPEC" $TASK_SPACE/$USER.tasks.lock.$SEED/ >/tmp/clean_task.log 2>&1

rm -fr $TASK_SPACE/$USER.tasks.lock.$SEED


