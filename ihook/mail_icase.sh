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
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export TASK_SPACE=/dev/shm
export TODAY=`date +%y%m%d`
export TOWEEK=`date +%yw%V`
export TOYEAR=`date +%Y`

export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

export IBUILD_SVN_SRV=`grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'}`
export IBUILD_SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`
export IBUILD_FOUNDER_EMAIL=`grep '^IBUILD_FOUNDER_EMAIL=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_FOUNDER_EMAIL=' {'print $2'}`

export ICASE_REV=$1
export ICASE_URL=`svn log -v -r $ICASE_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/icase/icase | egrep 'A |M ' | awk -F' ' {'print $2'} | head -n1`
export BUILD_INFO=`basename $ICASE_URL`

if [[ ! `echo $ICASE_URL | grep '^/icase/'` ]] ; then
	exit
fi

svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/icase/icase/$TOYEAR/$TOWEEK $TASK_SPACE/icase.lock

export BUILD_INFO_URL="$TASK_SPACE/icase.lock/$BUILD_INFO"
export BUILD_SPEC=`head -n1 $BUILD_INFO_URL`
export EMAIL_PM=`grep '^EMAIL_PM=' $BUILD_INFO | awk -F'EMAIL_PM=' {'print $2'}`
export EMAIL_REL=`grep '^EMAIL_REL=' $BUILD_INFO | awk -F'EMAIL_REL=' {'print $2'}`
export BUILD_TIME=`grep '^BUILD_TIME=' $BUILD_INFO | awk -F'BUILD_TIME=' {'print $2'}`
export BUILD_TIME_MIN=`echo $BUILD_TIME / 60 | bc`
export START_TIME=`grep '^START_TIME=' $BUILD_INFO | awk -F'START_TIME=' {'print $2'}`
export END_TIME=`grep '^END_TIME=' $BUILD_INFO | awk -F'END_TIME=' {'print $2'}`
export IBUILD_GRTSRV=`grep '^IBUILD_GRTSRV=' $BUILD_INFO | awk -F'IBUILD_GRTSRV=' {'print $2'}`
export IBUILD_GRTSRV_BRANCH=`grep '^IBUILD_GRTSRV_BRANCH=' $BUILD_INFO | awk -F'IBUILD_GRTSRV_BRANCH=' {'print $2'}`
export IBUILD_GRTSRV_URL=`grep '^IBUILD_GRTSRV_URL=' $BUILD_INFO | awk -F'IBUILD_GRTSRV_URL=' {'print $2'}`
export IBUILD_TARGET_BUILD_VARIANT=`grep '^IBUILD_TARGET_BUILD_VARIANT=' $BUILD_INFO | awk -F'IBUILD_TARGET_BUILD_VARIANT=' {'print $2'}`
export IBUILD_TARGET_PRODUCT=`grep '^IBUILD_TARGET_PRODUCT=' $BUILD_INFO | awk -F'IBUILD_TARGET_PRODUCT=' {'print $2'}`
export IVER=`grep '^IVER=' $BUILD_INFO | awk -F'IVER=' {'print $2'}`
export RESULT=`grep '^RESULT=' $BUILD_INFO | awk -F'RESULT=' {'print $2'}`
export SLAVE_HOST=`grep '^SLAVE_HOST=' $BUILD_INFO | awk -F'SLAVE_HOST=' {'print $2'}`
export DOWNLOAD_URL=`grep '^DOWNLOAD_URL=' $BUILD_INFO | awk -F'DOWNLOAD_URL=' {'print $2'}`

export GERRIT_CHANGE_ID=`grep '^GERRIT_CHANGE_ID=' $BUILD_INFO | awk -F'GERRIT_CHANGE_ID=' {'print $2'}`
export GERRIT_CHANGE_NUMBER=`grep '^GERRIT_CHANGE_NUMBER=' $BUILD_INFO | awk -F'GERRIT_CHANGE_NUMBER=' {'print $2'}`
export GERRIT_CHANGE_OWNER_EMAIL=`grep '^GERRIT_CHANGE_OWNER_EMAIL=' $BUILD_INFO | awk -F'GERRIT_CHANGE_OWNER_EMAIL=' {'print $2'}`
export GERRIT_CHANGE_OWNER_NAME=`grep '^GERRIT_CHANGE_OWNER_NAME=' $BUILD_INFO | awk -F'GERRIT_CHANGE_OWNER_NAME=' {'print $2'}`
export GERRIT_CHANGE_URL=`grep '^GERRIT_CHANGE_URL=' $BUILD_INFO | awk -F'GERRIT_CHANGE_URL=' {'print $2'}`
export GERRIT_PATCHSET_NUMBER=`grep '^GERRIT_PATCHSET_NUMBER=' $BUILD_INFO | awk -F'GERRIT_PATCHSET_NUMBER=' {'print $2'}`
export GERRIT_PATCHSET_REVISION=`grep '^GERRIT_PATCHSET_REVISION=' $BUILD_INFO | awk -F'GERRIT_PATCHSET_REVISION=' {'print $2'}`
export GERRIT_PROJECT=`grep '^GERRIT_PROJECT=' $BUILD_INFO | awk -F'GERRIT_PROJECT=' {'print $2'}`

export MAIL_LIST=$IBUILD_FOUNDER_EMAIL
[[ ! -z $EMAIL_PM ]] && export MAIL_LIST="$MAIL_LIST,$EMAIL_PM"
[[ ! -z $EMAIL_REL ]] && export MAIL_LIST="$MAIL_LIST,$EMAIL_REL"
[[ ! -z $GERRIT_CHANGE_OWNER_EMAIL ]] && export MAIL_LIST="$MAIL_LIST,$GERRIT_CHANGE_OWNER_EMAIL"

echo -e "
Hi, $GERRIT_CHANGE_OWNER_NAME

After ${BUILD_TIME}min, node $SLAVE_HOST build $IBUILD_TARGET_PRODUCT-$IBUILD_TARGET_BUILD_VARIANT $RESULT
All of log and packages download URL:
$DOWNLOAD_URL

It based on $IBUILD_GRTSRV/$IBUILD_GRTSRV_URL -b $IBUILD_GRTSRV_BRANCH

Other info:
$BUILD_SPEC
$GERRIT_PROJECT
$GERRIT_CHANGE_ID
$GERRIT_PATCHSET_NUMBER
$GERRIT_PATCHSET_REVISION
$GERRIT_CHANGE_URL

-dw
from ibuild system
[Daedalus]
" | mail -s "[ibuild][$RESULT] $IBUILD_TARGET_PRODUCT-$IBUILD_TARGET_BUILD_VARIANT in $SLAVE_HOST" $MAIL_LIST


