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
# 160511 Ding Wei init and reference from web

export LC_CTYPE=C
export SEED=$RANDOM
export TODAY=$(date +%y%m%d)
[[ ! `echo $* | grep debug` ]] && export DEBUG=echo
export USER=$(whoami)
export USER_UID=$(id -u $USER)
export USER_GID=$(id -g $USER)
export SHELL=/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export IP=$(hostname -I | awk -F' ' {'print $2'})
export MONKEY_SRV_PATH=/local/docker/monkey_srv
export TAG_NAME=monkey_srv
export PORT_MAP_HTTPS=443:443
export PORT_MAP_HTTP=80:80
export VOLUME_localtime=/etc/localtime:/etc/localtime:ro
export VOLUME_local=/local:/local
export VOLUME_monkey_srv=$MONKEY_SRV_PATH/www:/var/www/html
export VOLUME_mysql=$MONKEY_SRV_PATH/mysql:/var/lib/mysql
export VOLUME_data=$MONKEY_SRV_PATH/data:/var/lib/data
export VOLUME_php_ini=$MONKEY_SRV_PATH/php.ini:/etc/php5/apache2/php.ini:ro
export DOCKER_NAMES=$TAG_NAME-$TODAY
export IMAGE_TAG=$TAG_NAME

mkdir -p $MONKEY_SRV_PATH/{www,data}
chmod 777 -R $MONKEY_SRV_PATH/data

if [[ `docker ps | grep $IMAGE_TAG | awk -F' ' {'print $1'}` ]] ; then
    docker ps | grep $IMAGE_TAG
    exit
fi

export CONTAINER_ID=$(docker run \
-d \
-p $PORT_MAP_HTTPS \
-p $PORT_MAP_HTTP \
-v $VOLUME_localtime \
-v $VOLUME_data \
-v $VOLUME_mysql \
-v $VOLUME_monkey_srv \
-v $VOLUME_php_ini \
-e MONKEY_SRV_PATH=$MONKEY_SRV_PATH \
--name=$DOCKER_NAMES \
-t $IMAGE_TAG)

docker exec -t $DOCKER_NAMES bash -l -c "/etc/init.d/apache2 restart"
DOCKER_IP=$(docker exec -t $DOCKER_NAMES bash -l -c "hostname -I" | awk -F' ' {'print $1'})
docker exec -t $DOCKER_NAMES bash -l -c "cat /etc/mysql/my.cnf | sed s/127.0.0.1/$DOCKER_IP/g >/tmp/my.cnf ; cp /tmp/my.cnf /etc/mysql/my.cnf"
cat $MONKEY_SRV_PATH/www/Clat_Server-V2/clat/smartyapp/myapp/config.php.orig | sed s/10.100.24.4:9090/$IP:80/g >$MONKEY_SRV_PATH/www/Clat_Server-V2/clat/smartyapp/myapp/config.php
docker exec -t $DOCKER_NAMES bash -l -c "/etc/init.d/mysql restart"

echo CONTAINER_ID=$CONTAINER_ID
docker ps | egrep "CONTAINER|$IMAGE_TAG"

$DEBUG docker exec -i -t $DOCKER_NAMES bash

