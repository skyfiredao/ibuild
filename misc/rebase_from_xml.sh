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
# 170518: init first version by dw

source /etc/bash.bashrc
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
export LC_CTYPE=C
export LC_ALL=C
export NOW=$(date +%y%m%d%H%M%S)
export PWD=$(pwd)

echo -e "$0 <snapshot_manifest.xml> <rebase_project_list.branch>"

export LOCAL_REPO=$(pwd)
  [[ ! $(ls $LOCAL_REPO/.repo | grep manifests) ]] && exit 1
export MANIFEST=$1
  [[ ! -e $MANIFEST ]] && exit 1
export REBASE_PROJ_LIST=$2
  [[ ! -e $REBASE_PROJ_LIST ]] && exit 1
export BRANCH=$(echo $REBASE_PROJ_LIST | awk -F'.' {'print $2'})
  [[ -z $BRANCH ]] && exit 1
export BRANCH_NAME=$(basename $BRANCH)
export REMOTE_NAME=$(cat $MANIFEST | grep remote= | awk -F'remote="' {'print $2'} | awk -F'"' {'print $1'} | sort -u | head -n1)
[[ $3 = debug ]] && export DEBUG=echo || export DEBUG=''

SPLIT_LINE()
{
 if [[ -z $1 ]] ; then
    echo -e "=============================================================\n"
 else
    echo -e "\n============== $1"
 fi
}

RUN_CMD()
{
 local RUN_CMD=$1
 if [[ ! -z $RUN_CMD ]] ; then
    SPLIT_LINE "$RUN_CMD"
    time $GM_C_DEBUG_CMD $1
    local RUN_STATUS=$?
    CHECK_STATUS $RUN_STATUS "$RUN_CMD"
 else
    SPLIT_LINE "Empty Command"
 fi
}

CHECK_STATUS()
{
 if [[ $1 != 0 ]] ; then
    ddecho -e "FAILED: $2"
    SPLIT_LINE
    echo -e "EXIT $1"
    exit 1
 else
    echo -e "PASSED: $2"
 fi
}

for PROJ_NAME in $(cat $REBASE_PROJ_LIST)
do
    for PROJ_PATH in $(repo list | egrep ": $PROJ_NAME$" | awk -F':' {'print $1'})
    do
        SPLIT_LINE "$PROJ_PATH"
        export PROJ_REV=$(cat $MANIFEST | egrep '"'$PROJ_PATH'"' | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
        pushd $PROJ_PATH >/dev/null 2>&1
        RUN_CMD "git remote update --prune"
        export REMOTE_BRANCH=$(git branch -a | grep remotes | egrep "/$BRANCH$" | awk -F' ' {'print $2'} | sort -u)
        RUN_CMD "git reset --hard HEAD"
        RUN_CMD "git checkout -b $BRANCH_NAME $REMOTE_BRANCH"
        RUN_CMD "git rebase $PROJ_REV || git rebase --abort"
        RUN_CMD "$DEBUG git push $REMOTE_NAME $BRANCH_NAME-$NOW"
        echo $PROJ_NAME >>$REBASE_PROJ_LIST.done
        cat $REBASE_PROJ_LIST | grep -v "^$PROJ_NAME$" >$REBASE_PROJ_LIST.tmp
        cp $REBASE_PROJ_LIST.tmp $REBASE_PROJ_LIST
        popd >/dev/null 2>&1
    done
done

for REPO_BRANCH in $(repo branch | grep '|' |awk -F'|' {'print $1'} | sed 's/*//g')
do
    echo -e ": repo abandon $REPO_BRANCH"
done


