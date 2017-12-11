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
# 150126 Create by Ding Wei

export LC_CTYPE=C
export LC_ALL=C
export USER=$(whoami)
export TASK_SPACE=/dev/shm
export TOWEEK=$(date +%yw%V)
export LOCK_SPACE=/dev/shm/lock
mkdir -p $LOCK_SPACE >/dev/null 2>&1
export IBUILD_FOUNDER_EMAIL=$(grep '^IBUILD_FOUNDER_EMAIL=' $(dirname $0)/../conf/ibuild.conf | awk -F'IBUILD_FOUNDER_EMAIL=' {'print $2'})
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:

REBOOT_STEP()
{
 nc 127.0.0.1 1234
 sync
 if [[ ! -z $IBUILD_FOUNDER_EMAIL && $(which mail) ]] ; then
    last >~/last_reboot
    ls -la /dev/shm/ >>~/last_reboot
    cat ~/last_reboot | mail -s "[ibuild][reboot]$(hostname)" $IBUILD_FOUNDER_EMAIL
    sleep 5
 fi
 sudo reboot -f
}

touch $LOCK_SPACE/count

if [[ $(date +%u) = 1 && ! -e $LOCK_SPACE/update-$TOWEEK ]] ; then
    sudo aptitude update
    sudo aptitude -y full-upgrade
    rm -f $LOCK_SPACE/update-*
    touch $LOCK_SPACE/update-$TOWEEK
    echo "full-upgrade: "$(date) >>$LOCK_SPACE/count
fi

if [[ $(cat $LOCK_SPACE/count | wc -l) -ge 100 && ! $(hostname | grep ibuild) ]] ; then
    touch $TASK_SPACE/reboot
fi

if [[ $(w | grep days | awk -F' ' {'print $3'}) -ge 2 ]] ; then
    touch $TASK_SPACE/reboot
fi

if [[ -e $TASK_SPACE/reboot && ! -e $TASK_SPACE/spec.build && ! $(hostname | grep ibuild) ]] ; then
    REBOOT_STEP
fi

if [[ -e /dev/shm/spec.build ]] ; then
    export SPEC_TIME=$(stat /dev/shm/spec.build | grep Modify | awk -F' ' {'print $2" "$3'})
    export SPEC_TIME_SEC=$(date -d"$SPEC_TIME" +%s)
#    export LOAD_NOW=$(w | grep average | awk -F'average: ' {'print $2'} | awk -F'.' {'print $1'})
    if [[ $(echo $(date +%s) - $SPEC_TIME_SEC | bc) -gt 7200 ]] ; then
        pkill -9 java
        pkill -9 aapt
        rm -f /dev/shm/spec.build
        REBOOT_STEP
    fi
fi


