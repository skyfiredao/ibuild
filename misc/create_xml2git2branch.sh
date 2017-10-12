#!/bin/bash
# Copyright (C) <2017>  <Ding Wei>
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
# 171012 Create by Ding Wei
export LC_CTYPE=C
export LC_ALL=C
export SEED=$RANDOM
export NOW=$(date +%y%m%d%H%M%S)
export TASK_SPACE=/dev/shm
export TOP_PATH=$(pwd)
export REPO_REMOTE_NAME=$1
export REPO_REMOTE_BRANCH=$2
if [[ -z $REPO_REMOTE_NAME || -z $REPO_REMOTE_BRANCH ]] ; then
    echo "$0 <REPO_REMOTE_NAME> <REPO_REMOTE_BRANCH>"
    exit 1
fi

pushd $TOP_PATH/.repo/manifests >/dev/null 2>&1
git diff | grep ^- | grep '<project' | while read PROJECT_ENTRY
do
    export PROJECT_NAME=$(echo $PROJECT_ENTRY | awk -F'name="' {'print $2'} | awk -F'"' {'print $1'})
    export PROJECT_PATH=$(echo $PROJECT_ENTRY | awk -F'path="' {'print $2'} | awk -F'"' {'print $1'})
    [[ -z $PROJECT_PATH ]] && export PROJECT_PATH=$PROJECT_NAME
    export PROJECT_REVISION=$(echo $PROJECT_ENTRY | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})

    pushd $TOP_PATH/$PROJECT_PATH >/dev/null 2>&1
    git checkout -b $NOW $PROJECT_REVISION >/dev/null 2>&1
    if [[ $? = 0 ]] ; then
        echo "pushd $TOP_PATH/$PROJECT_PATH" >>$TOP_PATH/git_push_${REPO_REMOTE_NAME}_${NOW}.sh
        echo "git push $REPO_REMOTE_NAME $NOW:$REPO_REMOTE_BRANCH" >>$TOP_PATH/git_push_${REPO_REMOTE_NAME}_${NOW}.sh
        echo "popd" >>$TOP_PATH/git_push_${REPO_REMOTE_NAME}_${NOW}.sh
    else
        echo '>>>>>>>>>' $TOP_PATH/$PROJECT_PATH has issue!!!!
    fi
    popd >/dev/null 2>&1
done

echo "Run git_push_${REPO_REMOTE_NAME}_${NOW}.sh when no issue"
