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

export EMAIL_PM=`grep '^EMAIL_PM=' $TASK_SPACE/icase.lock/$BUILD_INFO | awk -F'EMAIL_PM=' {'print $2'}`
export EMAIL_REL=`grep '^EMAIL_REL=' $TASK_SPACE/icase.lock/$BUILD_INFO | awk -F'EMAIL_REL=' {'print $2'}`
export GERRIT_CHANGE_OWNER_EMAIL=`grep '^GERRIT_CHANGE_OWNER_EMAIL=' $TASK_SPACE/icase.lock/$BUILD_INFO | awk -F'GERRIT_CHANGE_OWNER_EMAIL=' {'print $2'}`
export GERRIT_CHANGE_OWNER_NAME=`grep '^GERRIT_CHANGE_OWNER_NAME=' $TASK_SPACE/icase.lock/$BUILD_INFO | awk -F'GERRIT_CHANGE_OWNER_NAME=' {'print $2'}`

export MAIL_LIST=$IBUILD_FOUNDER_EMAIL
[[ ! -z $EMAIL_PM ]] && export MAIL_LIST="$MAIL_LIST,$EMAIL_PM"
[[ ! -z $EMAIL_REL ]] && export MAIL_LIST="$MAIL_LIST,$EMAIL_REL"
[[ ! -z $GERRIT_CHANGE_OWNER_EMAIL ]] && export MAIL_LIST="$MAIL_LIST,$GERRIT_CHANGE_OWNER_EMAIL"

echo -e "
Hi, $GERRIT_CHANGE_OWNER_NAME

build info:
`cat $TASK_SPACE/icase.lock/$BUILD_INFO`

-dw
from ibuild system
[Daedalus]
" | mail -s "[ibuild] build info" $MAIL_LIST


