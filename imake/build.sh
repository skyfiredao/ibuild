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
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
export LC_CTYPE=C
export LC_ALL=C
export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi
export ITASK_REV=$1

source $IBUILD_ROOT/imake/function
touch $TASK_SPACE/itask.lock
EXPORT_IBUILD_CONF
EXPORT_IBUILD_SPEC $ITASK_REV

rm -f $LOG_PATH/* >/dev/null 2>&1

hostname
echo $IP
date
echo itask:$ITASK_REV

REPO_INFO
SETUP_BUILD_REPO

[[ ! -z $GERRIT_CHANGE_NUMBER ]] && REPO_DOWNLOAD

$IBUILD_ROOT/imake/$IBUILD_MAKE_TOOL
 
SETUP_BUILD_OUT
SPLIT_LINE DONE

REPO_SYNC $LOC_REF_REPO 2
CLEAN_EXIT


