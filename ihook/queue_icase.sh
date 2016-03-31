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
# 150312 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export TASK_SPACE=/dev/shm
export SEED=$RANDOM
export TODAY=$(date +%y%m%d)
export TOWEEK=$(date +%yw%V)
export TOYEAR=$(date +%Y)
[[ `echo $* | grep debug` ]] && export DEBUG=echo
[[ ! -d $HOME/ibuild ]] && export HOME=/local

export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=$(dirname $0 | awk -F'/ibuild' {'print $1'})'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

export IBUILD_SVN_SRV=$(grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'})
export IBUILD_SVN_OPTION=$(grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'})

export QUEUE_SPACE=/local/queue/icase
export QUEUE_SPACE_TOP=$(dirname $QUEUE_SPACE)
if [[ ! -d $QUEUE_SPACE_TOP ]] ; then
    svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/istatus/queue $QUEUE_SPACE_TOP
    chmod 777 -R $QUEUE_SPACE_TOP
else
    svn cleanup $QUEUE_SPACE_TOP
    svn ci -q $IBUILD_SVN_OPTION -m "auto: cleanup" $QUEUE_SPACE_TOP
    svn up -q $IBUILD_SVN_OPTION $QUEUE_SPACE_TOP
fi

export ICASE_REV=$1
export ICASE_URL=$(svn log -v -r $ICASE_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/icase/icase | egrep 'A |M ' | awk -F' ' {'print $2'} | head -n1)

if [[ ! `echo $ICASE_URL | grep '^/icase/'` ]] ; then
    exit
fi

mkdir -p $TASK_SPACE/tmp/icase.$SEED
svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/icase/icase/$TOYEAR/$TOWEEK $TASK_SPACE/tmp/icase.$SEED/icase

export BUILD_INFO_NAME=$(basename $ICASE_URL | head -n1)
export BUILD_INFO=$TASK_SPACE/tmp/icase.$SEED/icase/$BUILD_INFO_NAME

export RESULT=$(grep '^RESULT=' $BUILD_INFO | awk -F'RESULT=' {'print $2'} | head -n1)
export STATUS_MAKE=$(grep '^STATUS_MAKE=' $BUILD_INFO | awk -F'STATUS_MAKE=' {'print $2'} | head -n1)
export BUILD_SPEC=$(grep spec.build $BUILD_INFO | awk -F'#' {'print $2'} | head -n1)
export IBUILD_MODE=$(grep '^IBUILD_MODE=' $BUILD_INFO | awk -F'IBUILD_MODE=' {'print $2'})
export IBUILD_TARGET_BUILD_VARIANT=$(grep '^IBUILD_TARGET_BUILD_VARIANT=' $BUILD_INFO | awk -F'IBUILD_TARGET_BUILD_VARIANT=' {'print $2'})
export IBUILD_TARGET_PRODUCT=$(grep '^IBUILD_TARGET_PRODUCT=' $BUILD_INFO | awk -F'IBUILD_TARGET_PRODUCT=' {'print $2'})
export DOWNLOAD_PKG_NAME=$(grep '^DOWNLOAD_PKG_NAME=' $BUILD_INFO | awk -F'DOWNLOAD_PKG_NAME=' {'print $2'} | head -n1)
export ITASK_REV=$(grep '^ITASK_REV=' $BUILD_INFO | awk -F'ITASK_REV=' {'print $2'} | tail -n1)
export IVER=$(grep '^IVER=' $BUILD_INFO | awk -F'IVER=' {'print $2'})
export IVERIFY=$(grep '^IVERIFY=' $BUILD_INFO | awk -F'IVERIFY=' {'print $2'} | tail -n1)
export IVERIFY_PRIORITY=$(grep '^IVERIFY_PRIORITY=' $BUILD_INFO | awk -F'IVERIFY_PRIORITY=' {'print $2'} | tail -n1)
    [[ -z $IVERIFY_PRIORITY ]] && export IVERIFY_PRIORITY=x

if [[ $RESULT = PASSED && -z $STATUS_MAKE && ! -z $DOWNLOAD_PKG_NAME && ! -z $IVERIFY ]] ; then
    if [[ $IBUILD_MODE = bundle ]] ; then
        touch $QUEUE_SPACE/$IVERIFY_PRIORITY.$ICASE_REV.$IBUILD_TARGET_PRODUCT
        svn add -q $QUEUE_SPACE/$IVERIFY_PRIORITY.$ICASE_REV.$IBUILD_TARGET_PRODUCT
        svn ci -q $IBUILD_SVN_OPTION -m "auto: add $IVERIFY_PRIORITY.$ICASE_REV.$IBUILD_TARGET_PRODUCT" $QUEUE_SPACE/$IVERIFY_PRIORITY.$ICASE_REV.$IBUILD_TARGET_PRODUCT
        echo icase: `ls $QUEUE_SPACE | wc -l`

        if [[ -d $TASK_SPACE/ispec.svn/.svn ]] ; then
            svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/ispec.svn
        else
            rm -fr $TASK_SPACE/ispec.svn >/dev/null 2>&1
            svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/ispec/ispec $TASK_SPACE/ispec.svn
        fi
        if [[ ! `grep "# $TODAY$" $TASK_SPACE/ispec.svn/queue/icase-$TOWEEK.list` ]] ; then
            echo "# $TODAY" >>$TASK_SPACE/ispec.svn/queue/icase-$TOWEEK.list
            svn add $TASK_SPACE/ispec.svn/queue/icase-$TOWEEK.list >/dev/null 2>&1
            chmod 777 -R $TASK_SPACE/ispec.svn
            svn ci -q $IBUILD_SVN_OPTION -m 'auto add queue history' $TASK_SPACE/ispec.svn/queue
        fi
        echo $IVERIFY_PRIORITY.$ICASE_REV.$IBUILD_TARGET_PRODUCT >>$TASK_SPACE/ispec.svn/queue/icase-$TOWEEK.list
    fi
    chmod 777 -R $QUEUE_SPACE
else
    rm -fr $TASK_SPACE/tmp/icase.$SEED
    exit
fi

if [[ -f $LOCK_SPACE/queue_icase.lock ]] ; then
    rm -fr $TASK_SPACE/tmp/icase.$SEED
    exit
fi

while [[ `ls $QUEUE_SPACE` ]] ;
do
    if [[ -f /tmp/EXIT ]] ; then
        rm -f $LOCK_SPACE/queue_icase.lock
        exit
    fi
    $DEBUG $IBUILD_ROOT/ihook/device_matching.sh $QUEUE_SPACE >/tmp/device_matching.log 2>&1
    sleep `expr $RANDOM % 7 + 1`
done

rm -f $LOCK_SPACE/queue_icase.lock
$DEBUG rm -fr $TASK_SPACE/tmp/icase.$SEED


