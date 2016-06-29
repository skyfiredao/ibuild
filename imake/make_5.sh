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
# 150120 Create by Ding Wei
source /etc/bash.bashrc >/dev/null 2>&1
export LC_CTYPE=C
export LC_ALL=C
export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

source $IBUILD_ROOT/imake/function >/dev/null 2>&1
EXPORT_IBUILD_CONF >/dev/null 2>&1
EXPORT_IBUILD_SPEC >/dev/null 2>&1

if [[ -d $JDK_PATH ]] ; then
	sudo rm -f /usr/local/jdk
	sudo ln -sf $JDK_PATH /usr/local/jdk
	export PATH=$JDK_PATH/bin:$PATH:
	export CLASSPATH=$JDK_PATH/lib:.
	export JAVA_HOME=$JDK_PATH
fi

REPO_INFO
SETUP_BUILD_REPO

[[ $IBUILD_MODE = bundle ]] && BUNDLE_BUILD
[[ ! -z $IBUILD_ADD_STEP_1 ]] && IBUILD_ADD_STEPS "$IBUILD_ADD_STEP_1"
[[ ! -z $GERRIT_CHANGE_NUMBER ]] && REPO_DOWNLOAD
[[ $(echo $IBUILD_NOTE | egrep "itest") ]] && DIFF_MANIFEST
[[ -f $LOG_PATH/nobuild ]] && exit 0

cd $BUILD_PATH_TOP
SPLIT_LINE envsetup
time source build/envsetup.sh >$LOG_PATH/envsetup.log 2>&1
LOG_STATUS $? envsetup.sh $LOG_PATH/envsetup.log

SPLIT_LINE "lunch $IBUILD_TARGET_PRODUCT-$IBUILD_TARGET_BUILD_VARIANT"
time lunch $IBUILD_TARGET_PRODUCT-$IBUILD_TARGET_BUILD_VARIANT >$LOG_PATH/lunch.log 2>&1
LOG_STATUS $? lunch $LOG_PATH/lunch.log

rm -fr out/* >/dev/null 2>&1
rm -fr $BUILD_PATH_TOP/out/* >/dev/null 2>&1

SPLIT_LINE "make -j$JOBS"
echo "make -j$JOBS $IBUILD_MAKE_OPTION" >$LOG_PATH/full_build.log
time make -j$JOBS $IBUILD_MAKE_OPTION >>$LOG_PATH/full_build.log 2>&1
export STATUS_MAKE=$?
LOG_STATUS $STATUS_MAKE make_j$JOBS $LOG_PATH/full_build.log

[[ ! -z $IBUILD_ADD_STEP_2 ]] && IBUILD_ADD_STEPS "$IBUILD_ADD_STEP_2"
cp $OUT/system/build.prop $BUILD_PATH_TOP/autout/ >/dev/null 2>&1
cp $OUT/system/build.prop $BUILD_PATH_TOP/release/ >/dev/null 2>&1

