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
export MANIFEST_A=$1
export MANIFEST_B=$2
export LOC_REPO_WS=$3
[[ -z $LOC_REPO_WS ]] && export LOC_REPO_WS='./'

[[ ! -f $MANIFEST_A && ! -f $MANIFEST_B ]] && exit
[[ ! -d $LOC_REPO_WS/.repo ]] && exit

echo "------------------------------ manifest info"
md5sum $MANIFEST_A $MANIFEST_B >>/tmp/manifest2git_diff-$NOW.txt

echo "------------------------------ Change Project List" >>/tmp/manifest2git_diff-$NOW.txt
diff $MANIFEST_A $MANIFEST_B | awk -F'name="' {'print $2'} | awk -F'"' {'print $1'} | sort -u >>/tmp/manifest2git_diff-$NOW.txt

echo "------------------------------ Change File List" >>/tmp/manifest2git_diff-$NOW.txt
for PROJECT_PATH in `diff $MANIFEST_A $MANIFEST_B | awk -F'name="' {'print $2'} | awk -F'"' {'print $1'} | sort -u`
do
    export REVISION_A=$(grep 'name="'$PROJECT_PATH'"' $MANIFEST_A | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
    export REVISION_B=$(grep 'name="'$PROJECT_PATH'"' $MANIFEST_B | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
    cd $LOC_REPO_WS/$PROJECT_PATH
    echo "-------------------- $PROJECT_PATH" >>/tmp/manifest2git_diff-$NOW.txt
    git diff --name-status $REVISION_A $REVISION_B >>/tmp/manifest2git_diff-$NOW.txt
    echo >>/tmp/manifest2git_diff-$NOW.txt
    cd $LOC_REPO_WS
done

for PROJECT_PATH in `diff $MANIFEST_A $MANIFEST_B | awk -F'name="' {'print $2'} | awk -F'"' {'print $1'} | sort -u`
do
    export REVISION_A=$(grep 'name="'$PROJECT_PATH'"' $MANIFEST_A | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
    export REVISION_B=$(grep 'name="'$PROJECT_PATH'"' $MANIFEST_B | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
    cd $LOC_REPO_WS/$PROJECT_PATH
    echo "-------------------- $PROJECT_PATH" >>/tmp/manifest2git_diff-$NOW.txt
    git show $REVISION_A $REVISION_B >>/tmp/manifest2git_diff-$NOW.txt
    echo >>/tmp/manifest2git_diff-$NOW.txt
    cd $LOC_REPO_WS
done


