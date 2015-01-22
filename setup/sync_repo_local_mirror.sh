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
# 141216: Ding Wei init

export LC_CTYPE=C
export JOBS=`cat /proc/cpuinfo | grep CPU | wc -l`
export TASK_SPACE=/run/shm
export TOHOUR=`date +%H`
export IBUILD_ROOT=$HOME/ibuild
	[[ ! -d $HOME/ibuild ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

export LOC_REPO_MIRROR_PATH=`grep '^LOC_REPO_MIRROR_PATH=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'LOC_REPO_MIRROR_PATH=' {'print $2'}`

if [[ -L $LOC_REPO_MIRROR_PATH ]] ; then
	export LOC_REPO_MIRROR_PATH=`readlink $LOC_REPO_MIRROR_PATH`
	cd $LOC_REPO_MIRROR_PATH
else
	cd $LOC_REPO_MIRROR_PATH
fi

if [[ `cat $TASK_SPACE/repo_sync.lock` != $TOHOUR ]] ; then
	$IBUILD_ROOT/bin/repo sync -j$JOBS
	echo $TOHOUR >$TASK_SPACE/repo_sync.lock
fi

date

