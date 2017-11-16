#!/bin/bash
# Copyright (C) <2014>  <Ding Wei>
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
# 160603 Create by Ding Wei

export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`
export TASK_SPACE=/dev/shm
export TOWEEK=`date +%yw%V`
export LOCK_SPACE=/dev/shm/lock
mkdir -p $LOCK_SPACE >/dev/null 2>&1

[[ ! -e ~/ibuild/imake/function || ! -e ~/spec ]] && exit

cd ~/spec

grep export ~/ibuild/imake/function |egrep -v '#'|egrep '\$IBUILD_SPEC '|awk -F'=' {'print $1'}|awk -F'export ' {'print $2'} >/tmp/tmp.spec.entry

for SPEC in `ls ~/spec/ | grep spec.build`
do
    for FUNCTION_ENTRY in `cat /tmp/tmp.spec.entry`
    do
        [[ ! $(grep "^$FUNCTION_ENTRY=" $SPEC) ]] && echo "$FUNCTION_ENTRY=" >>$SPEC
    done
    for SPEC_ENTRY in `cat $SPEC | awk -F'=' {'print $1'} | sort -u`
    do
        if [[ ! $(grep "export $SPEC_ENTRY=" ~/ibuild/imake/function) ]] ; then
            echo "No $SPEC_ENTRY in function"
            cat $SPEC | grep -v "^$SPEC_ENTRY=" >/tmp/tmp.spec
            mv /tmp/tmp.spec $SPEC
        fi
    done
    cat $SPEC | egrep -v '^GERRIT_|BAD_PATCH_ENTRY|EMAIL_TMP|ITASK_ORDER|NEW_IBUILD_SPEC_NAME|IBUILD_SPEC|IBUILD_MODE=$' | sort -u >/tmp/tmp.spec
    mv /tmp/tmp.spec $SPEC
done

rm -f /tmp/tmp.spec*



