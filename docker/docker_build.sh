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
# 050303 Ding Wei init and reference from web

export LC_CTYPE=C
export SEED=$RANDOM
export TODAY=$(date +%y%m%d)
[[ `echo $* | grep debug` ]] && export DEBUG=echo
export USER=$(whoami)
export USER_UID=$(id -u $USER)
export USER_GID=$(id -g $USER)
export IMAGE_TAG=image/node
export PATH_BUILD=.
[[ -f $1 ]] && export Dockerfile=$1
[[ -z $Dockerfile ]] && export Dockerfile=Dockerfile.node

cat $Dockerfile | sed "s/USER_UID/$USER_UID/g" | sed "s/USER_GID/$USER_GID/g" >$Dockerfile.$SEED

docker build \
-f $Dockerfile.$SEED \
-t $IMAGE_TAG \
$PATH_BUILD

$DEBUG rm -f $Dockerfile.$SEED


