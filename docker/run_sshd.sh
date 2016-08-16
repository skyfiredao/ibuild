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
# 160316 Ding Wei init and reference from web

export LC_CTYPE=C
export SEED=$RANDOM
export TODAY=$(date +%y%m%d)
[[ ! `echo $* | grep debug` ]] && export DEBUG=echo
export USER=$(whoami)
export USER_UID=$(id -u $USER)
export USER_GID=$(id -g $USER)
export SHELL=/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

export TAG_NAME=sshd
export PORT_MAP=2222:22
export VOLUME_localtime=/etc/localtime:/etc/localtime:ro
export VOLUME_local=/local/ref_repo:/local/ref_repo:ro
export VOLUME_local_share_build=/local/share/build:/local/share/build
export VOLUME_etc_ssh=/etc/ssh:/etc/ssh:ro
export DOCKER_NAMES=$TAG_NAME-$TODAY
export IMAGE_TAG=ibuild/$TAG_NAME

if [[ `docker ps | grep $IMAGE_TAG | awk -F' ' {'print $1'}` ]] ; then
    docker ps | grep $IMAGE_TAG
    exit
fi

export CONTAINER_ID=$(docker run \
-d \
-p $PORT_MAP \
-v $VOLUME_localtime \
-v $VOLUME_local \
-v $VOLUME_local_share_build \
-v $VOLUME_etc_ssh \
--name=$DOCKER_NAMES \
-t $IMAGE_TAG)

docker exec -t $DOCKER_NAMES bash -l -c "service ssh start" >/tmp/docker.tmp 2>&1
cat /tmp/docker.tmp

if [[ $(cat /tmp/docker.tmp |grep running | grep Error) ]] ; then
    ERROR_DOCKER_ID=$(cat /tmp/docker.tmp |grep running | grep Error | awk -F' ' {'print $6'})
    docker rm $ERROR_DOCKER_ID
    docker exec -t $DOCKER_NAMES bash -l -c "service ssh start"
fi

echo CONTAINER_ID=$CONTAINER_ID
docker ps | egrep "CONTAINER|$IMAGE_TAG"

$DEBUG docker exec -i -t $DOCKER_NAMES bash

