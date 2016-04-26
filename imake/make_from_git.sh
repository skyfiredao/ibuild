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
# 160401 Create by Ding Wei

export LC_CTYPE=C
export SHELL=/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export JOBS=$(cat /proc/cpuinfo | grep CPU | wc -l)
export TASK_SPACE=/run/shm
export TOHOUR=$(date +%H)
export SEED=$RANDOM
export LOCK_SPACE=/dev/shm/lock
export SUBV_REPO=/local/workspace/subv_repo
export BUILD_REPO=/local/workspace/build
export AUTOUT=/local/workspace/autout
export TODAY=$(date +%y%m%d)
export SHARE_PATH=/local/share/build
export BRANCH_NAME=branch_name
export GIR_REPO=git_repo
export TARGET_PRODUCT=aosp
export TARGET_BUILD_VARIANT=userdebug
export CCACHE_DIR=/local/ccache
export CCACHE_UMASK=0000
export CCACHE_BASEDIR=/media
export USE_CCACHE=1
export WITH_DEXPREOPT=false
export DISABLE_DEXPREOPT=true


mkdir -p $LOCK_SPACE >/dev/null 2>&1
[[ -f $LOCK_SPACE/build.lock ]] && exit

if [[ `cat $LOCK_SPACE/build.$GIR_REPO.lock` = $TOHOUR || `ps aux | grep rsync | grep -v grep` ]] ; then
    exit
fi

touch $LOCK_SPACE/build.lock
echo $TOHOUR >$LOCK_SPACE/build.$GIR_REPO.lock
rm -f $AUTOUT/log/*

cd $SUBV_REPO/$GIR_REPO
git checkout master
git pull
git fetch

if [[ -d $BUILD_REPO/$GIR_REPO ]] ; then
    mv $BUILD_REPO/$GIR_REPO $BUILD_REPO/bad.$SEED.$GIR_REPO
    sudo btrfs subvolume delete $BUILD_REPO/bad.$SEED.$GIR_REPO
fi

/sbin/btrfs subvolume snapshot $SUBV_REPO/$GIR_REPO $BUILD_REPO/$GIR_REPO

cd $BUILD_REPO/$GIR_REPO
git branch -D $BRANCH_NAME
git branch $BRANCH_NAME origin/$BRANCH_NAME
git checkout $BRANCH_NAME >$AUTOUT/log/checkout.log 2>&1
git pull >>$AUTOUT/log/checkout.log 2>&1
#export GIT_VER=$(git log HEAD | head -n1 | awk -F' ' {'print $2'} | cut -c34-40)
export GIT_VER=$(git describe --always)
if [[ -f $LOCK_SPACE/ver.$GIT_VER ]] ; then
    rm -f $LOCK_SPACE/build.lock $AUTOUT/log/checkout.log
    exit
fi

rm -f $LOCK_SPACE/ver.*
touch $LOCK_SPACE/ver.$GIT_VER
. build/envsetup.sh >/dev/null 2>&1
lunch $TARGET_PRODUCT-$TARGET_BUILD_VARIANT >>$AUTOUT/log/build.log 2>&1
make clean >/dev/null 2>&1
time make -j12 >>$AUTOUT/log/build.log 2>&1
export STATUS_BUILD=$?
if [[ $STATUS_BUILD != 0 ]] ; then
    export STATUS=.BUILD_ERROR
fi

export BUILD_OUT_FOLDER=$TOHOUR.$GIT_VER$STATUS.$BRANCH_NAME.$TARGET_PRODUCT-$TARGET_BUILD_VARIANT

mkdir -p $AUTOUT/$BUILD_OUT_FOLDER/log
cd $OUT
[[ $STATUS_BUILD = 0 ]] && tar cf $AUTOUT/$BUILD_OUT_FOLDER/release.$GIT_VER.tar *.{img,txt}

[[ -d $SHARE_PATH/$TODAY ]] || mkdir -p $SHARE_PATH/$TODAY
cp -Ra $AUTOUT/$BUILD_OUT_FOLDER $SHARE_PATH/$TODAY/ && rm -fr $AUTOUT/$BUILD_OUT_FOLDER

for LOG in `ls $AUTOUT/log`
do
    txt2html $AUTOUT/log/$LOG --outfile $SHARE_PATH/$TODAY/$BUILD_OUT_FOLDER/log/$LOG.html
done

rm -f $LOCK_SPACE/build.lock



