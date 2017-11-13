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
# 171113 Create by Ding Wei
[[ ! -z $1 ]] && export BUILD_PATH_TOP=$1
export JOBS=$(cat /proc/cpuinfo | grep CPU | wc -l)
export NOW=$(date +%y%m%d%H%M%S)

pushd $BUILD_PATH_TOP
[[ ! -e repo.list ]] && $REPO_CMD list >repo.list
export REMOTE_NAME=$(cat $BUILD_PATH_TOP/.repo/manifests/*.xml | grep remote= | awk -F'="' {'print $2'} | awk -F'"' {'print $1'} | sort -u)
[[ -z $REMOTE_NAME ]] && export REMOTE_NAME=No_Remote_Name
export REAL_GERRIT_PROJECT=$(echo $GERRIT_PROJECT | sed "s/$REMOTE_NAME\///g")
export LOCAL_PROJECT_PATH=$(cat repo.list | egrep ": $REAL_GERRIT_PROJECT$" | awk -F':' {'print $1'} | head -n1)
export MANIFEST_PATCHSET=''

if [[ $(echo $GERRIT_PROJECT | grep manifests$) ]] ; then
    export MANIFEST_PATCHSET=true
    export LOCAL_PROJECT_PATH=.repo/manifests
fi

pushd $BUILD_PATH_TOP/$LOCAL_PROJECT_PATH

if [[ $? != 0 || -z $LOCAL_PROJECT_PATH ]] ; then
    echo "Cannot find $GERRIT_PROJECT local path"
    exit
fi

git pull
git remote update

git fetch ssh://$IBUILD_GRTSRV/$GERRIT_PROJECT $GERRIT_REFSPEC >$LOG_PATH/cherry_pick.log 2>&1
export CHECK_STATUS=$?
LOG_STATUS $CHECK_STATUS git_fetch $LOG_PATH/cherry_pick.log
export COMMIT_SHA1=$(git log FETCH_HEAD | head -n1 | awk -F' ' {'print $2'})

git diff HEAD FETCH_HEAD >/tmp/diff-$NOW.tmp

if [[ ! $(git log HEAD | grep $COMMIT_SHA1) && ! $(md5sum /tmp/diff-$NOW.tmp | grep d41d8cd98f00b204e9800998ecf8427e) ]] ; then
    rm -f /tmp/diff-$NOW.tmp
    git cherry-pick FETCH_HEAD >$LOG_PATH/cherry_pick.log 2>&1
    export CHECK_STATUS=$?
    if [[ $CHECK_STATUS != 0 ]] ; then
        git cherry-pick -m 1 FETCH_HEAD >$LOG_PATH/cherry_pick.log 2>&1
        export CHECK_STATUS=$?
    fi
    [[ $CHECK_STATUS != 0 ]] && git status >$LOG_PATH/cherry_pick.log 2>&1
    LOG_STATUS $CHECK_STATUS cherry_pick $LOG_PATH/cherry_pick.log
else
    echo -e "MERGED: $GERRIT_PROJECT $GERRIT_REFSPEC"
    touch $LOG_PATH/nobuild
    rm -f /tmp/diff-$NOW.tmp
    exit 0
fi
popd

if [[ $MANIFEST_PATCHSET = true ]] ; then
    for RM_ENTRY in $(cat repo.list | awk -F':' {'print $1'} | awk -F'/' {'print $1'} | sort -u)
    do
        rm -fr $BUILD_PATH_TOP/$RM_ENTRY
    done
    $REPO_CMD sync -d -c -q --force-sync -j$JOBS --no-tags
    CHECK_STATUS $?
fi
popd

