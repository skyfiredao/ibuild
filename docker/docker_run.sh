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
export NODE_USER=builder
export DNS_SRV=$(grep ^nameserver /etc/resolv.conf | awk -F' ' {'print $2'} | head -n1)
export VOLUME_local=/local:/local
export VOLUME_localtime=/etc/localtime:/etc/localtime:ro
export VOLUME_HOME_ssh=$HOME/.ssh:/home/builder/.ssh
export IMAGE_TAG=image/node

export CONTAINER_ID=$(docker run \
--privileged=true \
-e USER_UID=$USER_UID \
-e USER_GID=$USER_GID \
-e NODE_USER=$NODE_USER \
--dns $DNS_SRV \
-d \
-v $VOLUME_localtime \
-v $VOLUME_local \
-v $VOLUME_HOME_ssh \
--name=node-$TODAY.$SEED \
-t $IMAGE_TAG)

echo CONTAINER_ID=$CONTAINER_ID
docker ps | egrep "CONTAINER|node-$TODAY.$SEED"

$DEBUG docker exec -i -t node-$TODAY.$SEED bash -l -c "su - $NODE_USER"

