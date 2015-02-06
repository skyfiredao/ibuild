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

if [[ ! -z $IBUILD_ADD_STEP_1 ]] ; then
	SPLIT_LINE "$IBUILD_ADD_STEP_1"
	time $IBUILD_ADD_STEP_1 -j$JOBS >$LOG_PATH/$IBUILD_ADD_STEP_1_LOG_NAME.log 2>&1
#	LOG_STATUS $? $IBUILD_ADD_STEP_1 $LOG_PATH/$IBUILD_ADD_STEP_1_LOG_NAME.log
fi

cd $BUILD_PATH_TOP
SPLIT_LINE envsetup
time source build/envsetup.sh >$LOG_PATH/envsetup.log 2>&1
LOG_STATUS $? envsetup.sh $LOG_PATH/envsetup.log

if [[ ! -z $IBUILD_ADD_STEP_2 ]] ; then
	SPLIT_LINE "$IBUILD_ADD_STEP_2"
	time $IBUILD_ADD_STEP_2 >$LOG_PATH/$IBUILD_ADD_STEP_2_LOG_NAME.log 2>&1
	LOG_STATUS $? $IBUILD_ADD_STEP_2 $LOG_PATH/$IBUILD_ADD_STEP_2_LOG_NAME.log
fi

SPLIT_LINE lunch
time lunch $IBUILD_TARGET_PRODUCT-$IBUILD_TARGET_BUILD_VARIANT >$LOG_PATH/lunch.log 2>&1
LOG_STATUS $? lunch $LOG_PATH/lunch.log

rm -fr out/* >/dev/null 2>&1

SPLIT_LINE "make -j$JOBS"
time make -j$JOBS >$LOG_PATH/full_build.log 2>&1
LOG_STATUS $? make_j$JOBS $LOG_PATH/full_build.log

SPLIT_LINE make_release
time make -j$JOBS release >$LOG_PATH/release.log 2>&1
LOG_STATUS $? make_release $LOG_PATH/release.log


