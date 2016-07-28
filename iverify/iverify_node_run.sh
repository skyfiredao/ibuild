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
# 150325 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=$(whoami)
export TASK_SPACE=/run/shm
export HOSTNAME=$(hostname)
export TOWEEK=$(date +%yw%V)
export TOYEAR=$(date +%Y)

export IVERIFY_ROOT=$HOME/iverify
export IVERIFY_CONF=$HOME/iverify/conf/iverify.conf
export IVERIFY_SVN_SRV=$(grep '^IVERIFY_SVN_SRV=' $IVERIFY_CONF | awk -F'IVERIFY_SVN_SRV=' {'print $2'})
export IVERIFY_SVN_OPTION=$(grep '^IVERIFY_SVN_OPTION=' $IVERIFY_CONF | awk -F'IVERIFY_SVN_OPTION=' {'print $2'})

if [[ ! -f $HOME/iverify/conf/iverify.conf ]] ; then
    echo -e "Please put iverify in your $HOME"
    exit 0
fi

echo ------------------------- `date`

EXIT()
{
 for SVN_M_URL in `svn st ~/iverify/{bin,conf,inode}/ | grep '^M ' | awk -F' ' {'print $2'}`
 do
     rm -f $SVN_M_URL
 done
 for DOT_SVN in `find $IVERIFY_ROOT/hostrunner/ | grep '.svn$'`
 do
     rm -fr $DOT_SVN >/dev/null 2>&1
 done
 svn up -q ~/iverify/{bin,conf,inode}
 rm -f $IVERIFY_SPACE/build_info.[0-9]*
 rm -f $IVERIFY_SPACE/[0-9]*.build_info
 rm -f $IVERIFY_SPACE/iverify_node_run.sh.lock
 mkdir -p $HOME/.log >/dev/null 2>&1
 cp $HISTORY_IVERIFY_LOG/*.log $HOME/.log/ >/dev/null 2>&1
 exit
}

ASSIGN_DEVICE()
{
 export BUILD_INFO=$1 
 export IVERIFY=$(grep '^IVERIFY=' $BUILD_INFO | awk -F'IVERIFY=' {'print $2'})
 export RESULT=$(grep '^RESULT=' $BUILD_INFO | awk -F'RESULT=' {'print $2'})
 export MAKE_STATUS=$(grep '^MAKE_STATUS=' $BUILD_INFO | awk -F'MAKE_STATUS=' {'print $2'})
 export DOWNLOAD_PKG_NAME=$(grep '^DOWNLOAD_PKG_NAME=' $BUILD_INFO | awk -F'DOWNLOAD_PKG_NAME=' {'print $2'} | head -n1)

 if [[ $RESULT != PASSED || ! -z $MAKE_STATUS || -z $DOWNLOAD_PKG_NAME || -z $IVERIFY ]] ; then
     echo "build status is not matching iverify"
     egrep 'RESULT=|MAKE_STATUS=|IVERIFY=|DOWNLOAD_PKG_NAME=' $BUILD_INFO
     export BUILD_INFO_NAME=$(basename $BUILD_INFO)
     mv $BUILD_INFO $HISTORY_IVERIFY_LOG/$BUILD_INFO_NAME.issue
     EXIT
 fi

 export IBUILD_TARGET_PRODUCT=$(grep '^IBUILD_TARGET_PRODUCT=' $BUILD_INFO | awk -F'IBUILD_TARGET_PRODUCT=' {'print $2'})
 export IBUILD_ID=$(grep '^IBUILD_ID=' $BUILD_INFO | awk -F'IBUILD_ID=' {'print $2'})
 export ITASK_REV=$(grep '^ITASK_REV=' $BUILD_INFO | awk -F'ITASK_REV=' {'print $2'})
 export ITASK_ORDER=$(grep '^ITASK_ORDER=' $BUILD_INFO | awk -F'ITASK_ORDER=' {'print $2'} | head -n1)
 [[ ! -z $ITASK_ORDER ]] && export ITASK_TMP=$ITASK_ORDER || export ITASK_TMP=$ITASK_REV
 export IVERIFY_REVER=$IBUILD_ID.$ITASK_TMP
 export IVERIFY_DEVICE_ID=''

 $ADB devices >$TASK_SPACE/iverify/adb_devices.log

 for DEVICE_ONLINE in `cat $IVERIFY_SPACE/adb_devices.log | egrep -v 'daemon|attached|offline' | grep device$ | awk -F' ' {'print $1'}`
 do
     if [[ `ls $IVERIFY_SPACE/inode.svn | grep $IBUILD_TARGET_PRODUCT | grep $DEVICE_ONLINE` && ! -f $IVERIFY_SPACE/lock.$DEVICE_ONLINE ]] ; then
         if [[ `grep $IBUILD_TARGET_PRODUCT $IVERIFY_SPACE/device.$DEVICE_ONLINE` ]] ; then
             echo "$DEVICE_ONLINE free"
             export IVERIFY_DEVICE_ID=$DEVICE_ONLINE
             break
         else
             echo "$DEVICE_ONLINE is NOT $IBUILD_TARGET_PRODUCT"
         fi
     elif [[ -f $IVERIFY_SPACE/lock.$DEVICE_ONLINE ]] ; then
         echo "$IVERIFY_SPACE/lock.$DEVICE_ONLINE locked"
         export IVERIFY_DEVICE_ID=''
     fi
 done

 if [[ ! -z $IVERIFY_DEVICE_ID ]] ; then
     echo $BUILD_INFO $IVERIFY_DEVICE_ID
     touch $IVERIFY_SPACE/lock.$IVERIFY_DEVICE_ID
     RUN_hostrunner $BUILD_INFO $IVERIFY_DEVICE_ID &
 else
    echo "No free matching device for $BUILD_INFO"
 fi
}

SETUP_ISTATUS()
{
 export ISTATUS_ENTRY=$1

 if [[ ! -d $TASK_SPACE/istatus-$TOWEEK ]] ; then
     rm -fr $TASK_SPACE/istatus-* >/dev/null 2>&1
     svn co -q $IVERIFY_SVN_OPTION svn://$IVERIFY_SVN_SRV/istatus/$TOYEAR/$TOWEEK $TASK_SPACE/istatus-$TOWEEK
     if [[ $? != 0 ]] ; then
         svn mkdir -q $IVERIFY_SVN_OPTION -m "auto: add istatus/$TOYEAR/$TOWEEK" svn://$IVERIFY_SVN_SRV/istatus/$TOYEAR/$TOWEEK >/dev/null 2>&1
         svn co -q $IVERIFY_SVN_OPTION svn://$IVERIFY_SVN_SRV/istatus/$TOYEAR/$TOWEEK $TASK_SPACE/istatus-$TOWEEK
     fi
 else
     svn up -q $IVERIFY_SVN_OPTION $TASK_SPACE/istatus-$TOWEEK
 fi

 touch $TASK_SPACE/istatus-$TOWEEK/$ITASK_REV
 touch $TASK_SPACE/istatus-$TOWEEK/$ITASK_ORDER
 if [[ $ITASK_REV = $ITASK_ORDER && -f $TASK_SPACE/istatus-$TOWEEK/$ITASK_REV ]] ; then
     echo `date +%y%m%d-%H%M%S`"|$HOSTNAME|$ISTATUS_ENTRY" >>$TASK_SPACE/istatus-$TOWEEK/$ITASK_REV
 elif [[ ! -z $ITASK_ORDER && -f $TASK_SPACE/istatus-$TOWEEK/$ITASK_REV ]] ; then
     echo `date +%y%m%d-%H%M%S`"|$HOSTNAME|$ISTATUS_ENTRY" >>$TASK_SPACE/istatus-$TOWEEK/$ITASK_ORDER
 fi

 svn add $TASK_SPACE/istatus-$TOWEEK/$ITASK_REV >/dev/null 2>&1
 svn add $TASK_SPACE/istatus-$TOWEEK/$ITASK_ORDER >/dev/null 2>&1
 svn ci -q $IVERIFY_SVN_OPTION -m "auto: add $ITASK_REV" $TASK_SPACE/istatus-$TOWEEK/*
}

RUN_hostrunner()
{
 export BUILD_INFO=$1
 export IVERIFY_hostrunner_serial=$2

 export IBUILD_GRTSRV_BRANCH=$(grep '^IBUILD_GRTSRV_BRANCH=' $BUILD_INFO | awk -F'IBUILD_GRTSRV_BRANCH=' {'print $2'})
 export IBUILD_TARGET_BUILD_VARIANT=$(grep '^IBUILD_TARGET_BUILD_VARIANT=' $BUILD_INFO | awk -F'IBUILD_TARGET_BUILD_VARIANT=' {'print $2'})
 export IBUILD_TARGET_PRODUCT=$(grep '^IBUILD_TARGET_PRODUCT=' $BUILD_INFO | awk -F'IBUILD_TARGET_PRODUCT=' {'print $2'})
 export DOWNLOAD_URL=$(grep '^DOWNLOAD_URL=' $BUILD_INFO | awk -F'DOWNLOAD_URL=' {'print $2'} | head -n1)
 export DOWNLOAD_PKG_NAME=$(grep '^DOWNLOAD_PKG_NAME=' $BUILD_INFO | awk -F'DOWNLOAD_PKG_NAME=' {'print $2'} | head -n1)
 export IVERIFY_hostrunner_variant=$IBUILD_TARGET_BUILD_VARIANT
 export IBUILD_GRTSRV_BRANCH_TOP=$(echo $IBUILD_GRTSRV_BRANCH | awk -F'/' {'print $1'})
 export IVERIFY_hostrunner_project=${IBUILD_TARGET_PRODUCT}$(echo $IBUILD_GRTSRV_BRANCH | awk -F"$IBUILD_GRTSRV_BRANCH_TOP" {'print $2'} | sed 's/\//_/g')
 export IVERIFY_FOUNDER_EMAIL=$(grep '^IVERIFY_FOUNDER_EMAIL=' $IVERIFY_CONF | awk -F'IVERIFY_FOUNDER_EMAIL=' {'print $2'})
 export EMAIL_TMP=$(grep '^EMAIL_TMP=' $BUILD_INFO | awk -F'EMAIL_TMP=' {'print $2'} | head -n1)

 SETUP_ISTATUS "iverify assign: $IVERIFY_hostrunner_serial $IVERIFY_hostrunner_project $IVERIFY_hostrunner_variant"

 echo "#!/bin/bash -x
# `date`
# auto create script
export PATH=/usr/lib/jvm/java-7-openjdk-amd64/bin:~/iverify/bin:~/bin:$PATH:
export CLASSPATH=/usr/lib/jvm/java-7-openjdk-amd64/lib:.
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64

export ITASK_REV=$ITASK_TMP
export IBUILD_ID=$IBUILD_ID
export IVEREV=$IBUILD_ID.$ITASK_REV
export ITASK_SPEC_URL=$HISTORY_IVERIFY_LOG/$IVERIFY_REVER.build_info
export IVERIFY_hostrunner_project=$IVERIFY_hostrunner_project
export IVERIFY_hostrunner_variant=$IVERIFY_hostrunner_variant
export KBITS_HOST=/tmp/$IVERIFY_REVER.$DOWNLOAD_PKG_NAME
export FASTBOOT_SERIAL=$IVERIFY_hostrunner_serial
export PRE_COMMIT_DSN=$IVERIFY_hostrunner_serial
touch $IVERIFY_SPACE/lock.$IVERIFY_hostrunner_serial

echo ------------------------- START: \`date\`

rm -f /tmp/$IVERIFY_REVER.$DOWNLOAD_PKG_NAME
echo "wget $DOWNLOAD_URL/$DOWNLOAD_PKG_NAME"
time wget -q $DOWNLOAD_URL/$DOWNLOAD_PKG_NAME -O /tmp/$IVERIFY_REVER.$DOWNLOAD_PKG_NAME

echo ------------------------- VERIFY: \`date\`
echo $IVERIFY_ROOT/script/pre_commit.sh
time /bin/bash $IVERIFY_ROOT/script/pre_commit.sh

rm -f $IVERIFY_SPACE/lock.$IVERIFY_hostrunner_serial
rm -f /tmp/$IVERIFY_REVER.$DOWNLOAD_PKG_NAME
echo ------------------------- END: \`date\`
">$HISTORY_IVERIFY_LOG/$IVERIFY_REVER.$IVERIFY_hostrunner_serial.sh

 chmod +x $HISTORY_IVERIFY_LOG/$IVERIFY_REVER.$IVERIFY_hostrunner_serial.sh
 echo $HISTORY_IVERIFY_LOG/$IVERIFY_REVER.$IVERIFY_hostrunner_serial.sh
 /bin/mv $BUILD_INFO $HISTORY_IVERIFY_LOG
 rm -fr $IVERIFY_ROOT/hostrunner/.svn >/dev/null 2>&1

 if [[ ! -z $EMAIL_TMP ]] ; then
     export EMAIL_LIST=$EMAIL_TMP,$IVERIFY_FOUNDER_EMAIL
 else
     export EMAIL_LIST=$IVERIFY_FOUNDER_EMAIL
 fi

 cat $HISTORY_IVERIFY_LOG/$IVERIFY_REVER.$IVERIFY_hostrunner_serial.sh | mail -s "[iverify][assign][$ITASK_TMP] $HOSTNAME.$IBUILD_TARGET_PRODUCT.$DEVICE_ONLINE" $EMAIL_LIST

 source $HISTORY_IVERIFY_LOG/$IVERIFY_REVER.$IVERIFY_hostrunner_serial.sh >>$HISTORY_IVERIFY_LOG/$IVERIFY_REVER.$IVERIFY_hostrunner_serial.log 2>&1

 cat $HISTORY_IVERIFY_LOG/$IVERIFY_REVER.$IVERIFY_hostrunner_serial.log | mail -s "[iverify][end][$ITASK_TMP] $HOSTNAME.$IBUILD_TARGET_PRODUCT.$DEVICE_ONLINE" $EMAIL_LIST

 SETUP_ISTATUS "wget time: `cat $HISTORY_IVERIFY_LOG/$IVERIFY_REVER.$IVERIFY_hostrunner_serial.log | grep real | awk -F' ' {'print $2'} | head -n1`"
 SETUP_ISTATUS "hostrunner time: `cat $HISTORY_IVERIFY_LOG/$IVERIFY_REVER.$IVERIFY_hostrunner_serial.log | grep real | awk -F' ' {'print $2'} | tail -n1`"

 rm -f $IVERIFY_SPACE/lock.$IVERIFY_hostrunner_serial
 rm -fr $IVERIFY_ROOT/hostrunner/.svn >/dev/null 2>&1
}

export IVERIFY_SPACE=$TASK_SPACE/iverify
export ADB=$IVERIFY_ROOT/bin/adb
export LOCAL_IVERIFY_QUEUE=$HOME/iverify.queue.local
export HISTORY_IVERIFY_LOG=$HOME/iverify.history.log
mkdir -p $LOCAL_IVERIFY_QUEUE $IVERIFY_SPACE $HISTORY_IVERIFY_LOG >/dev/null 2>&1

if [[ -f $IVERIFY_SPACE/iverify_node_run.sh.lock ]] ; then
    echo "$IVERIFY_SPACE/iverify_node_run.sh.lock"
    exit 0
else
    touch $IVERIFY_SPACE/iverify_node_run.sh.lock
fi

for DEVICE_ID in `cat $IVERIFY_SPACE/adb_devices.log | egrep -v 'daemon|attached|offline' | grep device$ | awk -F' ' {'print $1'}`
do
    if [[ ! -f $IVERIFY_SPACE/lock.$DEVICE_ID ]] ; then
        break
    fi
done

if [[ -z $DEVICE_ID || -f $TASK_SPACE/EXIT ]] ; then
   EXIT 
fi

for BUILD_INFO_NAME in `ls $LOCAL_IVERIFY_QUEUE | grep build_info$`
do
    ASSIGN_DEVICE $LOCAL_IVERIFY_QUEUE/$BUILD_INFO_NAME
done

EXIT

