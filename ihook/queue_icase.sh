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
export HOME=/root

export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=$(dirname $0 | awk -F'/ibuild' {'print $1'})'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

export IBUILD_SVN_SRV=$(grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'})
export IBUILD_SVN_OPTION=$(grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'})

export QUEUE_SPACE=$TASK_SPACE/queue_icase
mkdir -p $QUEUE_SPACE >/dev/null 2>&1
chmod 777 -R $QUEUE_SPACE

export ICASE_REV=$1
export ICASE_URL=$(svn log -v -r $ICASE_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/icase/icase | egrep 'A |M ' | awk -F' ' {'print $2'} | head -n1)

if [[ ! `echo $ICASE_URL | grep '^/icase/'` ]] ; then
	exit
fi

mkdir -p $TASK_SPACE/tmp.icase.$SEED
svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/icase/icase/$TOYEAR/$TOWEEK $TASK_SPACE/tmp.icase.$SEED/icase
svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/ispec $TASK_SPACE/tmp.icase.$SEED/ispec

export BUILD_INFO_NAME=$(basename $ICASE_URL | head -n1)
export BUILD_INFO=$TASK_SPACE/tmp.icase.$SEED/icase/$BUILD_INFO_NAME

export RESULT=$(grep '^RESULT=' $BUILD_INFO | awk -F'RESULT=' {'print $2'} | head -n1)
export MAKE_STATUS=$(grep '^MAKE_STATUS=' $BUILD_INFO | awk -F'MAKE_STATUS=' {'print $2'} | head -n1)
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

if [[ $RESULT = PASSED && -z $MAKE_STATUS && ! -z $DOWNLOAD_PKG_NAME && ! -z $IVERIFY ]] ; then
	if [[ $IBUILD_MODE = bundle ]] ; then
		touch $QUEUE_SPACE/$IVERIFY_PRIORITY.$ICASE_REV.$IBUILD_TARGET_PRODUCT
		echo $IVERIFY_PRIORITY.$ICASE_REV.$IBUILD_TARGET_PRODUCT >>$TASK_SPACE/icase-$TODAY.list
	fi
	chmod 777 -R $QUEUE_SPACE
else
	exit
fi

[[ -f $TASK_SPACE/queue_icase.lock ]] && exit

while [[ `ls $QUEUE_SPACE` || -f /tmp/EXIT ]] ;
do
	$DEBUG $IBUILD_ROOT/ihook/device_matching.sh $QUEUE_SPACE $TASK_SPACE/tmp.icase.$SEED $BUILD_INFO >/tmp/device_matching.log 2>&1
	sleep `expr $RANDOM % 7 + 3`
done

rm -f $TASK_SPACE/queue_icase.lock
$DEBUG rm -fr $TASK_SPACE/tmp.icase.$SEED

