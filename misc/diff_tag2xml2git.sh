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
# 161207  Create by Ding Wei

export LC_CTYPE=C
export LC_ALL=C
export USER=$(whoami)
export SEED=$RANDOM
export NOW=$(date +%y%m%d%H%M%S)
export TASK_SPACE=/dev/shm
export REPO_CMD=$(which repo)
export RUN_PATH=$(dirname $0)
export TAG_LEFT=$1
export TAG_RIGHT=$2
export LOC_REPO_WS=$3
[[ -z $LOC_REPO_WS ]] && export LOC_REPO_WS=$(pwd)
export P_LOC_REPO_WS=$(dirname $LOC_REPO_WS)
[[ ! $(ls $LOC_REPO_WS/.repo | grep manifest) && $(ls $P_LOC_REPO_WS/.repo | grep manifest) ]] && export LOC_REPO_WS=$P_LOC_REPO_WS

pushd $LOC_REPO_WS/.repo/manifests
echo
git checkout default
echo

if [[ $(git tag | grep $TAG_LEFT) ]] ; then
    [[ $(git branch -a | grep " $TAG_LEFT$") ]] && git branch -D $TAG_LEFT
    git checkout -b $TAG_LEFT $TAG_LEFT
    cp default.xml /tmp/MANIFEST_LEFT.xml
    export MANIFEST_LEFT=/tmp/MANIFEST_LEFT.xml
else
    echo "cannot find $TAG_LEFT"
    exit 1
fi

echo

if [[ $(git tag | grep $TAG_RIGHT) ]] ; then
    [[ $(git branch -a | grep " $TAG_RIGHT$") ]] && git branch -D $TAG_RIGHT
    git checkout -b $TAG_RIGHT $TAG_RIGHT
    cp default.xml /tmp/MANIFEST_RIGHT.xml
    export MANIFEST_RIGHT=/tmp/MANIFEST_RIGHT.xml
else
    echo "cannot find $TAG_RIGHT"
    exit 1
fi

git checkout default
echo
popd

echo

$RUN_PATH/diff_xml2git.sh /tmp/MANIFEST_LEFT.xml /tmp/MANIFEST_RIGHT.xml $LOC_REPO_WS


