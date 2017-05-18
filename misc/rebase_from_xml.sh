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
export SEED=$RANDOM
export PWD=$(pwd)

echo -e "$0 <snapshot_manifest.xml> <rebase_project_list.branch>"
export LOCAL_REPO=$(pwd)
[[ ! $(ls $LOCAL_REPO/.repo | grep manifests) ]] && exit 1
export MANIFEST=$1
[[ ! -f $MANIFEST ]] && exit 1
export REBASE_PROJ_LIST=$2
[[ ! -f $REBASE_PROJ_LIST ]] && exit 1
export BRANCH=$(echo $REBASE_PROJ_LIST | awk -F'.' {'print $2'})
[[ -z $BRANCH ]] && exit 1
export BRANCH_NAME=$(basename $BRANCH)

export REMOTE_NAME=$(cat $MANIFEST | grep remote= | awk -F'remote="' {'print $2'} | awk -F'"' {'print $1'} | sort -u | head -n1)

for PROJ_NAME in $(cat $REBASE_PROJ_LIST)
do
    for PROJ_PATH in $(repo list | egrep ": $PROJ_NAME$" | awk -F':' {'print $1'})
    do
        echo -e "\n------------------------------ $PROJ_PATH"
        export PROJ_REV=$(cat $MANIFEST | egrep '"'$PROJ_PATH'"' | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
        pushd $PROJ_PATH >/dev/null 2>&1
        echo -e ": git remote update --prune"
        git remote update --prune >/dev/null 2>&1
        export REMOTE_BRANCH=$(git branch -a | grep remotes | egrep "/$BRANCH$" | awk -F' ' {'print $2'} | sort -u)
        echo -e ": git reset --hard HEAD"
        git reset --hard HEAD
        echo -e ": git checkout -b rebase-$SEED $PROJ_REV"
        git checkout -b rebase-$SEED $PROJ_REV
        echo -e ": git checkout -b $BRANCH_NAME $REMOTE_BRANCH"
        git checkout -b $BRANCH_NAME $REMOTE_BRANCH
        echo -e ": git rebase rebase-$SEED"
        git rebase rebase-$SEED
        if [[ $? != 0 ]] ; then
            echo -e "\n>>>>>>> issue project: $PROJ_PATH\n"
            echo -e ": git rebase --abort"
            git rebase --abort
        fi
        echo -e "git push -f $REMOTE_NAME $BRANCH_NAME"
        git push -f $REMOTE_NAME $BRANCH_NAME
        [[ $? != 0 ]] && echo -e "\n>>>>>>> issue project: $PROJ_PATH\n"
        popd >/dev/null 2>&1
    done
done

echo -e ": repo abandon $REMOTE_NAME"
repo abandon $REMOTE_NAME
echo -e ": repo abandon rebase-$SEED"
repo abandon rebase-$SEED

for REPO_BRANCH in $(repo branch | grep '|' |awk -F'|' {'print $1'} | sed 's/*//g')
do
    echo -e ": repo abandon $REPO_BRANCH"
done


