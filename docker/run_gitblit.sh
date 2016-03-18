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

export TAG_NAME=gitblit
export PORT_MAP_HTTPS=8443:8443
export PORT_MAP_GIT=29418:22
export VOLUME_localtime=/etc/localtime:/etc/localtime:ro
export VOLUME_local=/local/srv/gitblit:/local/srv/gitblit
export VOLUME_etc_ssh=/etc/ssh:/etc/ssh:ro
export DOCKER_NAMES=$TAG_NAME-$TODAY.$SEED
export IMAGE_TAG=ibuild/$TAG_NAME

mkdir -p /local/srv/gitblit/.ssh >/dev/null 2>&1
cat /local/srv/gitblit/data/ssh/* | sed 's/^RW //g'>/local/srv/gitblit/.ssh/authorized_keys
chmod 600 /local/srv/gitblit/.ssh/authorized_keys

if [[ `docker ps | grep $IMAGE_TAG | awk -F' ' {'print $1'}` ]] ; then
    echo ">>>>>>>>>>>>>>>>>>> $IMAGE_TAG is running"
    docker ps | grep $IMAGE_TAG
    exit
fi

export CONTAINER_ID=$(docker run \
-d \
-p $PORT_MAP_HTTPS \
-p $PORT_MAP_GIT \
-v $VOLUME_localtime \
-v $VOLUME_local \
-v $VOLUME_etc_ssh \
--name=$DOCKER_NAMES \
-t $IMAGE_TAG)

docker exec -t $DOCKER_NAMES bash -l -c "cp /local/srv/gitblit/service-ubuntu.sh /etc/init.d/gitblit"
docker exec -t $DOCKER_NAMES bash -l -c "update-rc.d gitblit defaults"
docker exec -t $DOCKER_NAMES bash -l -c "service gitblit start"
docker exec -t $DOCKER_NAMES bash -l -c "service ssh start"
docker exec -t $DOCKER_NAMES bash -l -c "/local/srv/gitblit/data/gitblit_fake.sh"

echo CONTAINER_ID=$CONTAINER_ID
docker ps | egrep "CONTAINER|$IMAGE_TAG"

$DEBUG docker exec -i -t $DOCKER_NAMES bash
