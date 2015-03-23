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
export IBUILD_FOUNDER_EMAIL=$(grep '^IBUILD_FOUNDER_EMAIL=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_FOUNDER_EMAIL=' {'print $2'})

export ITASK_JOBS_REV=$1
mkdir -p $TASK_SPACE/tmp.itask.$SEED
svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask $TASK_SPACE/tmp.itask.$SEED/svn
svn blame $IBUILD_SVN_OPTION $TASK_SPACE/tmp.itask.$SEED/svn/jobs.txt >$TASK_SPACE/tmp.itask.$SEED/jobs.txt-$ITASK_JOBS_REV
export ITASK_REV=$(cat $TASK_SPACE/tmp.itask.$SEED/jobs.txt-$ITASK_JOBS_REV | grep " $ITASK_JOBS_REV " | awk -F' ' {'print $3'} | awk -F'|' {'print $1'})

if [[ -z $ITASK_REV ]] ; then
    echo Can NOT find $ITASK_JOBS_REV !!! 
fi

export ITASK_URL=$(svn log -v -r $ITASK_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask | egrep 'A |M ' | awk -F' ' {'print $2'} | head -n1)
export BUILD_SPEC_NAME=$(basename $ITASK_URL)
export SLAVE_HOST=$(cat $TASK_SPACE/tmp.itask.$SEED/jobs.txt-$ITASK_JOBS_REV | grep " $ITASK_JOBS_REV " | awk -F' ' {'print $3'} | awk -F'|' {'print $2'})
export SLAVE_IP=$(cat $TASK_SPACE/tmp.itask.$SEED/jobs.txt-$ITASK_JOBS_REV | grep " $ITASK_JOBS_REV " | awk -F' ' {'print $3'} | awk -F'|' {'print $3'})

export BUILD_SPEC="$TASK_SPACE/tmp.itask.$SEED/svn/tasks/$BUILD_SPEC_NAME"
export EMAIL_PM=$(grep '^EMAIL_PM=' $BUILD_SPEC | awk -F'EMAIL_PM=' {'print $2'})
export EMAIL_REL=$(grep '^EMAIL_REL=' $BUILD_SPEC | awk -F'EMAIL_REL=' {'print $2'})
export IBUILD_MODE=$(grep '^IBUILD_MODE=' $BUILD_SPEC | awk -F'IBUILD_MODE=' {'print $2'})
export ITASK_ORDER=$(grep '^ITASK_ORDER=' $BUILD_SPEC | awk -F'ITASK_ORDER=' {'print $2'} | tail -n1)
export IBUILD_GRTSRV=$(grep '^IBUILD_GRTSRV=' $BUILD_SPEC | awk -F'IBUILD_GRTSRV=' {'print $2'})
export IBUILD_GRTSRV_BRANCH=$(grep '^IBUILD_GRTSRV_BRANCH=' $BUILD_SPEC | awk -F'IBUILD_GRTSRV_BRANCH=' {'print $2'})
export IBUILD_GRTSRV_MANIFEST=$(grep '^IBUILD_GRTSRV_MANIFEST=' $BUILD_SPEC | awk -F'IBUILD_GRTSRV_MANIFEST=' {'print $2'})
export IBUILD_GRTSRV_URL=$(grep '^IBUILD_GRTSRV_URL=' $BUILD_SPEC | awk -F'IBUILD_GRTSRV_URL=' {'print $2'})
export IBUILD_TARGET_BUILD_VARIANT=$(grep '^IBUILD_TARGET_BUILD_VARIANT=' $BUILD_SPEC | awk -F'IBUILD_TARGET_BUILD_VARIANT=' {'print $2'})
export IBUILD_TARGET_PRODUCT=$(grep '^IBUILD_TARGET_PRODUCT=' $BUILD_SPEC | awk -F'IBUILD_TARGET_PRODUCT=' {'print $2'})

export GERRIT_CHANGE_ID=$(grep '^GERRIT_CHANGE_ID=' $BUILD_SPEC | awk -F'GERRIT_CHANGE_ID=' {'print $2'})
export GERRIT_CHANGE_NUMBER=$(grep '^GERRIT_CHANGE_NUMBER=' $BUILD_SPEC | awk -F'GERRIT_CHANGE_NUMBER=' {'print $2'})
export GERRIT_CHANGE_OWNER_EMAIL=$(grep '^GERRIT_CHANGE_OWNER_EMAIL=' $BUILD_SPEC | awk -F'GERRIT_CHANGE_OWNER_EMAIL=' {'print $2'})
export GERRIT_CHANGE_OWNER_NAME=$(grep '^GERRIT_CHANGE_OWNER_NAME=' $BUILD_SPEC | awk -F'GERRIT_CHANGE_OWNER_NAME=' {'print $2'})
export GERRIT_CHANGE_URL=$(grep '^GERRIT_CHANGE_URL=' $BUILD_SPEC | awk -F'GERRIT_CHANGE_URL=' {'print $2'})
export GERRIT_PATCHSET_NUMBER=$(grep '^GERRIT_PATCHSET_NUMBER=' $BUILD_SPEC | awk -F'GERRIT_PATCHSET_NUMBER=' {'print $2'})
export GERRIT_PATCHSET_REVISION=$(grep '^GERRIT_PATCHSET_REVISION=' $BUILD_SPEC | awk -F'GERRIT_PATCHSET_REVISION=' {'print $2'})
export GERRIT_PROJECT=$(grep '^GERRIT_PROJECT=' $BUILD_SPEC | awk -F'GERRIT_PROJECT=' {'print $2'})

export MAIL_LIST=$IBUILD_FOUNDER_EMAIL

if [[ ! -z $EMAIL_TMP && ! `echo $EMAIL_TMP | egrep 'root|ubuntu|builder'` ]] ; then
    export MAIL_LIST="$MAIL_LIST,$EMAIL_TMP"
fi

#if [[ ! -z $GERRIT_CHANGE_OWNER_EMAIL ]] ; then
#	export MAIL_LIST="$MAIL_LIST,$GERRIT_CHANGE_OWNER_EMAIL"
#else
#	[[ ! -z $EMAIL_PM ]] && export MAIL_LIST="$MAIL_LIST,$EMAIL_PM"
#	[[ ! -z $EMAIL_REL ]] && export MAIL_LIST="$MAIL_LIST,$EMAIL_REL"
#fi

echo -e "
Hi, $GERRIT_CHANGE_OWNER_NAME

node $SLAVE_HOST ($SLAVE_IP) assign build $IBUILD_TARGET_PRODUCT-$IBUILD_TARGET_BUILD_VARIANT
`date`

It based on $IBUILD_GRTSRV/$IBUILD_GRTSRV_URL -b $IBUILD_GRTSRV_BRANCH -m $IBUILD_GRTSRV_MANIFEST

Other info:
$BUILD_SPEC_NAME
" >$TASK_SPACE/tmp.itask.$SEED/$ITASK_REV.mail

if [[ ! -z $GERRIT_PATCHSET_REVISION ]] ; then
    echo "GERRIT_CHANGE_ID: $GERRIT_CHANGE_ID" >>$TASK_SPACE/tmp.itask.$SEED/$ITASK_REV.mail
    echo "repo download $GERRIT_PROJECT $GERRIT_CHANGE_NUMBER/$GERRIT_PATCHSET_NUMBER" >>$TASK_SPACE/tmp.itask.$SEED/$ITASK_REV.mail
fi

echo "

-dw
from ibuild system
[Daedalus]
" >>$TASK_SPACE/tmp.itask.$SEED/$ITASK_REV.mail

[[ $IBUILD_MODE = bundle ]] && export SUB_IBUILD_MODE="[$IBUILD_MODE]"
[[ ! -z $GERRIT_PATCHSET_REVISION ]] && export SUB_IBUILD_MODE="[$GERRIT_CHANGE_NUMBER/$GERRIT_PATCHSET_NUMBER]"
[[ ! -z $ITASK_REV ]] && export SUB_ITASK_REV="[$ITASK_REV]"
if [[ ! -z $ITASK_ORDER && $ITASK_ORDER != $ITASK_REV ]] ; then
    export SUB_ITASK_REV="[$ITASK_ORDER]"
    export SUB_IBUILD_MODE="[re$IBUILD_MODE]"
    echo "[$ITASK_ORDER][$ITASK_REV][re$IBUILD_MODE]" >>$TASK_SPACE/tmp.itask.$SEED/$ITASK_REV.mail
fi

cat $TASK_SPACE/tmp.itask.$SEED/$ITASK_REV.mail | mail -s "[ibuild][assign]$SUB_ITASK_REV$SUB_IBUILD_MODE $IBUILD_TARGET_PRODUCT-$IBUILD_TARGET_BUILD_VARIANT in $SLAVE_HOST" $MAIL_LIST

$DEBUG rm -fr $TASK_SPACE/tmp.itask.$SEED


