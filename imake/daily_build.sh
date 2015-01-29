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
# 150128 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`
export TASK_SPACE=/dev/shm
export TOHOUR=`date +%H`

export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi
export IBUILD_SVN_SRV=`grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'}`
export IBUILD_SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`

if [[ `cat $TASK_SPACE/daily_build.lock` != $TOHOUR ]] ; then
	echo $TOHOUR >$TASK_SPACE/daily_build.lock
else
	exit
fi

if [[ -d $TASK_SPACE/ispec.lock ]] ; then
	svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/ispec.lock
else
	rm -fr $TASK_SPACE/ispec.lock
	svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/ispec $TASK_SPACE/ispec.lock
fi

if [[ -f $TASK_SPACE/ispec.lock/cron/$TOHOUR.spec ]] ; then
	for SPEC_FILTER in `cat $TASK_SPACE/ispec.lock/cron/$TOHOUR.spec | sort -u`
	do
		for SPEC_NAME in `ls $TASK_SPACE/ispec.lock/spec | grep $SPEC_FILTER`
		do
			$IBUILD_ROOT/imake/add_task.sh $TASK_SPACE/ispec.lock/spec/$SPEC_NAME
		done
	done
fi


