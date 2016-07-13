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
# 10613 Create by Ding Wei

export LC_CTYPE=C
export LC_ALL=C
export USER=$(whoami)
export SEED=$RANDOM
export NOW=$(date +%y%m%d%H%M%S)
export TASK_SPACE=/dev/shm
export REPO_CMD=$(which repo)
export MANIFEST_A=$1
export MANIFEST_B=$2
export LOC_REPO_WS=$3
[[ -z $LOC_REPO_WS ]] && export LOC_REPO_WS=$(pwd)

[[ ! -f $MANIFEST_A && ! -f $MANIFEST_B ]] && exit
[[ ! -d $LOC_REPO_WS/.repo || -z $REPO_CMD ]] && exit

diff $MANIFEST_A $MANIFEST_B >/tmp/manifest.diff

echo -e "\n------------------------------ manifest info" >>/tmp/manifest2git_diff-$NOW.txt
md5sum $MANIFEST_A $MANIFEST_B >>/tmp/manifest2git_diff-$NOW.txt

echo -e "\n------------------------------ Change Project List" >>/tmp/manifest2git_diff-$NOW.txt
cat /tmp/manifest.diff | awk -F'name="' {'print $2'} | awk -F'"' {'print $1'} | sort -u >>/tmp/manifest2git_diff-$NOW.txt

echo -e "\n------------------------------ Change File List" >>/tmp/manifest2git_diff-$NOW.txt
for PROJECT_PATH in `cat /tmp/manifest.diff | awk -F'name="' {'print $2'} | awk -F'"' {'print $1'} | sort -u`
do
    cd $LOC_REPO_WS
    export REVISION_A=$(grep 'name="'$PROJECT_PATH'"' /tmp/manifest.diff | grep '^<' | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
    export REVISION_B=$(grep 'name="'$PROJECT_PATH'"' /tmp/manifest.diff | grep '^>' | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
    cd $LOC_REPO_WS/$($REPO_CMD list | egrep ": $PROJECT_PATH$" | awk -F':' {'print $1'} | head -n1)
    echo ">>>>>>>>>> $PROJECT_PATH" >>/tmp/manifest2git_diff-$NOW.txt
    git diff --name-status $REVISION_A $REVISION_B >>/tmp/manifest2git_diff-$NOW.txt 2>&1
    [[ $? != 0 ]] && echo issue in $PROJECT_PATH
    echo >>/tmp/manifest2git_diff-$NOW.txt
done

echo -e "\n------------------------------ DIff" >>/tmp/manifest2git_diff-$NOW.txt
for PROJECT_PATH in `cat /tmp/manifest.diff | awk -F'name="' {'print $2'} | awk -F'"' {'print $1'} | sort -u`
do
    cd $LOC_REPO_WS
    export REVISION_A=$(grep 'name="'$PROJECT_PATH'"' /tmp/manifest.diff | grep '^>' | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
    export REVISION_B=$(grep 'name="'$PROJECT_PATH'"' /tmp/manifest.diff | grep '^<' | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
    cd $LOC_REPO_WS/$($REPO_CMD list | egrep ": $PROJECT_PATH$" | awk -F':' {'print $1'} | head -n1)
    echo ">>>>>>>>>> $PROJECT_PATH" >>/tmp/manifest2git_diff-$NOW.txt
    git show $REVISION_A $REVISION_B >>/tmp/manifest2git_diff-$NOW.txt 2>&1
    [[ $? != 0 ]] && echo issue in $PROJECT_PATH
    echo >>/tmp/manifest2git_diff-$NOW.txt
done

echo -e "\n/tmp/manifest2git_diff-$NOW.txt"

