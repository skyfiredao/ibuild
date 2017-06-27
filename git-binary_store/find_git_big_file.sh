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
# 170619 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export TASK_SPACE=/dev/shm

[[ -d $1 ]] && cd $1
export TOP_NUM=30

IFS=$'\n';
 
export GIT_TOP=$(git rev-parse --show-toplevel)

if [[ -d $GIT_TOP/.git/objects/pack ]] ; then
    export OBJ_PACK_PATH=$GIT_TOP/.git/objects/pack
elif [[ -d $(pwd)/objects/pack ]] ; then
    export OBJ_PACK_PATH=$(pwd)/objects/pack
else
    echo "Cannot find objects/pack path"
    exit 1
fi
 
OUTPUT="Size(KB),Git(KB),SHA1,URL"
git verify-pack -v $OBJ_PACK_PATH/pack-*.idx >/tmp/verify-pack.list

for OBJ in $(cat /tmp/verify-pack.list | grep -v chain | sort -k3nr | head -n$TOP_NUM)
do
    SIZE=$(($(echo $OBJ | cut -f 5 -d ' ')/1024))
    COMPRESSED_SIZE=$(($(echo $OBJ | cut -f 6 -d ' ')/1024))
    SHA=$(echo $OBJ | cut -f 1 -d ' ')
    OTHER=$(git rev-list --all --objects | grep $SHA)
    OUTPUT="${OUTPUT}\n${SIZE},${COMPRESSED_SIZE},${OTHER}"
done
 
echo -e $OUTPUT | column -t -s ', '
