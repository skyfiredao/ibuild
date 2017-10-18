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
# 171012: Ding Wei created it
export LC_ALL=C
export LC_CTYPE=C
export TODAY=$(date +%y%m%d)
export NOW=$(date +%y%m%d%H%M%S)
export LOCK_SPACE=/dev/shm/lock
export HOSTNAME_A=$(hostname -A)
export PWD=$(pwd)
[[ ! -d $PWD/conf ]] && exit 1
[[ $(whoami) != root ]] && exit 1

export SHN_CONF=$(dirname $0)/conf/shn.conf
export SHN_REMOTE_LOGIN=$(grep 'SHN_REMOTE_LOGIN=' $SHN_CONF | awk -F'SHN_REMOTE_LOGIN=' {'print $2'})
export SHN_NETWORK=$(grep 'SHN_NETWORK=' $SHN_CONF | awk -F'SHN_NETWORK=' {'print $2'})
export SHN_COOLDOWN_SEC=$(grep 'SHN_COOLDOWN_SEC=' $SHN_CONF | awk -F'SHN_COOLDOWN_SEC=' {'print $2'})

export HOST_TOKEN=$(find /globe/*/token | egrep 'token/key' | awk -F'/' {'print $3'})

for NODE_PATH in $(df | grep local | grep globe | awk -F'/globe/' {'print $2'} | grep -v $HOST_TOKEN)
do
    mkdir -p /globe/$NODE_PATH/srv/svn/dump >/dev/null 2>&1
    rsync -a /globe/$HOST_TOKEN/srv/svn/dump/ /globe/$NODE_PATH/srv/svn/dump/
done
