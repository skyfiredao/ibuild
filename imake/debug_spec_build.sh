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
# 160426 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`
export SEED=$RANDOM
export BUILD_TIME=`date +%y%m%d%H%M%S`
export BUILD_SEC_TIME=`date +%s`
export TASK_SPACE=/dev/shm
export SPEC_URL=$1
export SPEC_NAME=`basename $SPEC_URL`

export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

export LOCK_SPACE=/dev/shm/lock
mkdir -p $LOCK_SPACE >/dev/null 2>&1

if [[ -f $SPEC_URL ]] ; then
    export SPEC_NAME=$(basename $SPEC_URL)
    rm -f /dev/shm/spec.build
    cp $SPEC_URL /dev/shm/$SPEC_NAME
    ln -sf /dev/shm/$SPEC_NAME /dev/shm/spec.build
    bash -x $IBUILD_ROOT/imake/build.sh
else
    echo "Can NOT find $SPEC_URL"
fi

