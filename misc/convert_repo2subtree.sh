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
# 160818: init first version by dw

source /etc/bash.bashrc
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
export LC_CTYPE=C
export LC_ALL=C
export SEED=$RANDOM
export PWD=$(pwd)

echo -e "$0 <LOCAL_REPO> <LOCAL_GIT>"
echo -e '-----------------------------\n'
export LOCAL_REPO=$1
[[ ! $(ls $LOCAL_REPO/.repo | grep manifests) ]] && exit 1
export LOCAL_GIT=$2
[[ ! $(ls $LOCAL_GIT/.git | grep config) ]] && exit 1

export GERRIT_SRV=$(cat $LOCAL_REPO/.repo/manifest.xml | grep review= | awk -F'="https://' {'print $2'} | awk -F'"' {'print $1'})
export REMOTE_NAME=$(cat $LOCAL_REPO/.repo/manifest.xml | grep remote= | awk -F'remote="' {'print $2'} | awk -F'"' {'print $1'} | sort -u | head -n1)

pushd $LOCAL_REPO
repo manifest -r -o snapshot.xml
repo list >project.list

pushd $LOCAL_REPO/.repo/manifests/.git
export BRANCH_NAME=$(basename $(grep 'merge =' $LOCAL_REPO/.repo/manifests/.git/config | awk -F'=' {'print $2'}))
[[ -z $BRANCH_NAME ]] && export BRANCH_NAME=subtree
popd

pushd $LOCAL_GIT
git checkout master
git branch $BRANCH_NAME
git checkout $BRANCH_NAME
popd

for PROJECT in $(cat project.list | awk -F':' {'print $1'} | sort -u)
do
    export PROJECT_REV=$(cat snapshot.xml | grep '"'$PROJECT'"' | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
    export PROJECT_NAME=$(basename $PROJECT)
    export PROJECT_PATH=$(dirname $PROJECT)
    echo -e "----------------------------- $PROJECT $PROJECT_REV"

    pushd /tmp
    rm -fr /tmp/$PROJECT_NAME
    echo "--- git clone ssh://$GERRIT_SRV:29418/$REMOTE_NAME/$PROJECT"
    git clone ssh://$GERRIT_SRV:29418/$REMOTE_NAME/$PROJECT
    pushd /tmp/$PROJECT_NAME
    echo "--- git checkout -b $BRANCH_NAME $PROJECT_REV"
    git checkout -b $BRANCH_NAME $PROJECT_REV
    [[ ! $(git branch -a | grep 'remotes/' | grep -v '/archive/' | grep "/$BRANCH_NAME$") ]] && git push -u origin $BRANCH_NAME
    popd
    rm -fr /tmp/$PROJECT_NAME
    popd

    pushd $LOCAL_GIT
    mkdir -p $LOCAL_GIT/$PROJECT_PATH
    if [[ -d $PROJECT ]] ; then
        rm -fr $PROJECT
        echo -e "\n>>>>>>>>>> Duplicate $PROJECT\n"
    fi
    echo "--- git subtree add --prefix=$PROJECT ssh://$GERRIT_SRV:29418/$REMOTE_NAME/$PROJECT $BRANCH_NAME"
    git subtree add --prefix=$PROJECT ssh://$GERRIT_SRV:29418/$REMOTE_NAME/$PROJECT $BRANCH_NAME
    popd
    echo -e '-----------------------------\n'
done
popd

mv $LOCAL_REPO/{snapshot.xml,project.list} /tmp/
rsync -a --exclude ".git" --exclude ".repo" $LOCAL_REPO/ $LOCAL_GIT/




