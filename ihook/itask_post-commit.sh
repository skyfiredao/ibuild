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
# 150119: Ding Wei created it
# post-commit
export IHOOK_REPOS="$1"
export IHOOK_REV="$2"
[[ -z $IHOOK_REV ]] && exit 0

source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`
export SEED=$USER.$REV
export TASK_SPACE=/run/shm

[[ -f $TASK_SPACE/ihook.lock ]] && exit 0

if [[ -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	export IBUILD_ROOT=$HOME/ibuild
else
	[[ `echo $0 | grep '^./'` ]] && export IBUILD_ROOT=`pwd`/`echo $0 | sed 's/^.\///g'`
	[[ `echo $0 | grep '^/'` ]] && export IBUILD_ROOT=`pwd``echo $0 | sed 's/^.\///g'`
	export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
fi

export SVN_SRV=`grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'}`
export SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`

touch $TASK_SPACE/ihook.lock
touch /tmp/$IHOOK_REPOS.$IHOOK_REV
rm -f $TASK_SPACE/ihook.lock


