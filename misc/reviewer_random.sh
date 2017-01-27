#!/bin/bash
# Copyright (C) <2014,2015,2016,2017>  <Ding Wei>
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
# 170127: init first version by dw

export CONFIG_PATH=$1
[[ -z $CONFIG_PATH ]] && export CONFIG_PATH=$(pwd)
export SEED=$RANDOM

export GERRIT_SERVER=gerrit.gm.com
export GERRIT_CHANGE_NUMBER=$GERRIT_CHANGE_NUMBER
export GERRIT_PROJECT=$GERRIT_PROJECT
[[ ! -z $GERRIT_PROJECT ]] && export PROJECT_NAME=$(echo $GERRIT_PROJECT | sed 's/\//./g') || export PROJECT_NAME=''

EXIT()
{
 echo -e "-------------------- "$1
 echo -e "-------------------- NO Action"
 exit 0
}

RANDOM_LIST()
{
 export PROJECT_REVIEWER_CONF=$1
 export MAX_REVIEWER_NUM=$(grep '@' $PROJECT_REVIEWER_CONF | wc -l)
 export MIN_REVIEWER_NUM=$(grep '^REVIEWER_NUM=' $PROJECT_REVIEWER_CONF | awk -F'REVIEWER_NUM=' {'print $2'})
 if [[ -z $MIN_REVIEWER_NUM ]] ; then
    cat $PROJECT_REVIEWER_CONF | grep -v REVIEWER_NUM >/tmp/reviewer.$SEED.tmp
 else
    rm -f /tmp/reviewer.$SEED.tmp
    for ((i=0;i<$MIN_REVIEWER_NUM;i++))
    do
        RANDOM_LINE=$((RANDOM%$MAX_REVIEWER_NUM))
        RANDOM_LINE=$[RANDOM_LINE+1]
        sed -n "$RANDOM_LINE"p $PROJECT_REVIEWER_CONF >>/tmp/reviewer.$SEED.tmp
    done
 fi
}

[[ ! -f $CONFIG_PATH/reviewer.$PROJECT_NAME ]] && EXIT "Can NOT find $CONFIG_PATH/reviewer.$PROJECT_NAME"

for REVIEWER in $(cat /tmp/reviewer.$SEED.tmp)
do
    ssh -p 29418 $GERRIT_SERVER gerrit set-reviewers --project $GERRIT_PROJECT -a $REVIEWER $GERRIT_CHANGE_NUMBER
done

rm -f /tmp/reviewer.$SEED.tmp


