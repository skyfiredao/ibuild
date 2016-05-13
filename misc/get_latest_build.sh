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
# 160509 Create by Ding Wei

echo '--------------------'
export TOOLS_PATH=$(dirname $0)
svn up -q $TOOLS_PATH >/dev/null 2>&1
export TARGET_FILTER=$1
if [[ -z $TARGET_FILTER ]] ; then
    echo -e "$0 <download_keyword>
\nPlease define download target keyword as filter
"
    exit 0
fi
export IBUILD_SRV=ibuild-03
export LOCAL_STORE=/tmp/build
export TMP=/tmp/tmp.download.build
export RUN_PWD=$(pwd)

rm -fr $TMP >/dev/null 2>&1
mkdir $TMP $LOCAL_STORE >/dev/null 2>&1
cd $TMP

if [[ -z $DATA_FILTER ]] ; then
    wget --no-proxy -q http://$IBUILD_SRV/build
    export BUILD_TIME=$(cat build | grep href | grep -v README | tail -n1 | awk -F'href="' {'print $2'} | awk -F'/"' {'print $1'})
    rm -f $BUILD_TIME >/dev/null 2>&1
else
    export BUILD_TIME=$DATA_FILTER
fi
echo "Get $BUILD_TIME build:"

wget --no-proxy -q http://$IBUILD_SRV/build/$BUILD_TIME
export BUILD_OUT=$(cat $BUILD_TIME | grep href | egrep -v 'BUILD_ERROR' | egrep "$TARGET_FILTER|dw_filter" | tail -n1 | awk -F'href="' {'print $2'} | awk -F'/"' {'print $1'})
[[ -z $BUILD_OUT ]] && echo "Can NOT find $TARGET_FILTER build" && exit 0
rm -f $BUILD_OUT >/dev/null 2>&1

wget --no-proxy -q http://$IBUILD_SRV/build/$BUILD_TIME/$BUILD_OUT
export BUILD_PKG=$(cat $BUILD_OUT | grep -v ERROR | grep tar | grep release | egrep href | tail -n1 | awk -F'href="' {'print $2'} | awk -F'"' {'print $1'})

echo "wget --no-proxy http://$IBUILD_SRV/build/$BUILD_TIME/$BUILD_OUT/$BUILD_PKG"
echo -e '--------------------\n'
cd $LOCAL_STORE/
rm -f $BUILD_PKG
time wget --no-proxy http://$IBUILD_SRV/build/$BUILD_TIME/$BUILD_OUT/$BUILD_PKG

if [[ $? = 0 ]] ; then
    rm -fr $TMP
    echo $LOCAL_STORE/$BUILD_PKG
else
    echo "download issue..."
fi

