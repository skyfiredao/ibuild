#!/bin/bash -x
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
# 160607 Create by Ding Wei
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
REPO_INFO
SETUP_BUILD_REPO

[[ ! -z $IBUILD_ADD_STEP_1 ]] && IBUILD_ADD_STEPS "$IBUILD_ADD_STEP_1"

cd $BUILD_PATH_TOP/build
for TAG_DAILY in $(git tag -l | grep $(date +%Y%m%d))
do
    export TAG_DAILY_NAME=$(basename $TAG_DAILY)
    if [[ ! -z $TAG_DAILY ]] ; then
        cd $BUILD_PATH_TOP
        SPLIT_LINE git_checkout_$TAG_DAILY
        time $REPO_CMD forall -j$JOBS -c git checkout $TAG_DAILY >$LOG_PATH/$TAG_DAILY_NAME.log 2>&1
        rm -f $TAG_DAILY_NAME.xml
        time $REPO_CMD manifest -r -o $BUILD_PATH_TOP/$TAG_DAILY_NAME.xml
        SETUP_IVERSION $BUILD_PATH_TOP/$TAG_DAILY_NAME.xml $TAG_DAILY_NAME
        export IVERSION=$(svn info $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/iversion/iversion/$TOYEAR/$TOWEEK/$TAG_DAILY_NAME.xml | grep Last | grep Rev | awk -F': ' {'print $2'})
        [[ ! -z $IBUILD_ADD_STEP_2 ]] && IBUILD_ADD_STEPS "$IBUILD_ADD_STEP_2"
    fi
done

rm -fr $AUTOUT_PATH/*tag2rev*

