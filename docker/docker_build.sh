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
# 150303 Ding Wei init and reference from web
# 160316 Ding Wei change for multi-Dockerfile

export LC_CTYPE=C
export SEED=$RANDOM
export TODAY=$(date +%y%m%d)
[[ `echo $* | grep debug` ]] && export DEBUG=echo
export USER=$(whoami)
export USER_UID=$(id -u $USER)
export USER_GID=$(id -g $USER)
export PATH_BUILD=.

if [[ ! -d conf ]] ; then
    echo -e "Please goto docker_build.sh folder run it"
    exit
fi

for Dockerfile in `ls conf`
do
    export IMAGE_TAG=ibuild$(echo $Dockerfile | awk -F'.Dockerfile' {'print $1'})
    rm -f Dockerfile
    cat conf/$Dockerfile | sed "s/USER_UID/$USER_UID/g" | sed "s/USER_GID/$USER_GID/g" >Dockerfile

    time docker build -f Dockerfile -t $IMAGE_TAG $PATH_BUILD
done

$DEBUG rm -f Dockerfile


