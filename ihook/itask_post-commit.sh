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
export IHOOK_TXN_NAME="$3"
[[ -z $IHOOK_REV ]] && exit 0

source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export TASK_SPACE=/run/shm

export IBUILD_ROOT=$HOME/ibuild
	[[ ! -d $HOME/ibuild ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
        echo -e "Please put ibuild in your $HOME"
        exit 0
fi

$IBUILD_ROOT/imake/queue.sh $IHOOK_REV >/tmp/ihook-r$IHOOK_REV.log 2>&1 &

