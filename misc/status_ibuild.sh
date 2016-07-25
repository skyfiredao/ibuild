#!/bin/bash
# Copyright (C) <2014>  <Ding Wei>
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
# 150407 Create by Ding Wei

export LC_CTYPE=C
export LC_ALL=C
export USER=$(whoami)
export SEED=$RANDOM
export LASTWEEK=$(date +%yw%W)
export TOWEEK=$(date +%yw%V)
if [[ $LASTWEEK = $TOWEEK ]] ; then
    export LASTWEEK=$(date +%yw)$(echo $(date +%V) - 1 | bc)
fi
export TOYEAR=$(date +%Y)
export TASK_SPACE=/dev/shm
export LOCK_SPACE=/dev/shm/lock
mkdir -p $LOCK_SPACE >/dev/null 2>&1
export IBUILD_ROOT=$HOME/ibuild
    [[ ! -d $HOME/ibuild ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
    echo -e "Please put ibuild in your $HOME"
    exit 0
else
    export IBUILD_SVN_SRV=`grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'}`
    export IBUILD_SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`
fi

SPLIT_LINE()
{
 export SPLIT_WORD=''
 [[ ! -z $1 ]] && export SPLIT_WORD=" $1 "
 echo -e "------------------------$SPLIT_WORD------------------------"
}

CHECK_NODE()
{
 SPLIT_LINE server_jobs_status
 grep SLAVE_HOST * | awk -F'=' {'print $2'} | sort -u >$TMP_ICASE/status_ci_server.tmp
 for NODE in `cat $TMP_ICASE/status_ci_server.tmp`
 do
	echo -e "$NODE: \t"`grep $NODE * | wc -l`
 done

 SPLIT_LINE overview
 export ALL_HOSTS=$(grep SLAVE_HOST * | awk -F'=' {'print $2'} | sort -u | wc -l)
 echo -e "Total build:\t"`grep RESULT= * | awk -F':' {'print $1'} | sort -u | wc -l`
 echo -e "Total server:\t"$ALL_HOSTS
 CHECK_PASSRATE
}

CHECK_TIME()
{
 for BUILD_TIME in `grep BUILD_TIME * | awk -F'=' {'print $2'}`
 do
     export TMP_INFO_NAME=`grep "BUILD_TIME=$BUILD_TIME" * | head -n1 | awk -F':' {'print $1'}`
     for TIME_WINDOW in 0:15 15:25 25:35 35:45 45:55 55:65 65:99
     do
         export TIME_WINDOW_1=$(echo $TIME_WINDOW | awk -F':' {'print $1'})
         export TIME_WINDOW_2=$(echo $TIME_WINDOW | awk -F':' {'print $2'})
         export TIME_WINDOW_1=$(echo $TIME_WINDOW_1*60 | bc)
         export TIME_WINDOW_2=$(echo $TIME_WINDOW_2*60 | bc)
         if [[ $BUILD_TIME -ge $TIME_WINDOW_1 && $BUILD_TIME -le $TIME_WINDOW_2 ]] ; then
             echo $BUILD_TIME >>$TMP_ICASE/Time_$TIME_WINDOW_1-$TIME_WINDOW_2.count
             grep spec.build $TMP_INFO_NAME | awk -F'spec.build.' {'print $2'} >>$TMP_ICASE/Time_$TIME_WINDOW_1-$TIME_WINDOW_2.spec
             touch $TMP_ICASE/Time_$TIME_WINDOW_1-$TIME_WINDOW_2.{passed,failed}
             if [[ `grep RESULT=PASSED $TMP_INFO_NAME` ]] ; then
                 echo $BUILD_TIME >>$TMP_ICASE/Time_$TIME_WINDOW_1-$TIME_WINDOW_2.passed
             else
                 echo $BUILD_TIME >>$TMP_ICASE/Time_$TIME_WINDOW_1-$TIME_WINDOW_2.failed
             fi
         fi
     done
 done

 SPLIT_LINE "build_time_status passed:failed"
 for TIME_SHOW in `ls $TMP_ICASE | grep Time_ | grep count | awk -F'.count' {'print $1'}`
 do
     export TIME_COUNT=$(cat $TMP_ICASE/$TIME_SHOW.count | wc -l)
     export TIME_WINDOW_1=$(echo $TIME_SHOW | awk -F'Time_' {'print $2'} | awk -F'-' {'print $1'})
     export TIME_WINDOW_2=$(echo $TIME_SHOW | awk -F'Time_' {'print $2'} | awk -F'-' {'print $2'})
     export TIME_WINDOW_1=$(echo $TIME_WINDOW_1/60 | bc)
     export TIME_WINDOW_2=$(echo $TIME_WINDOW_2/60 | bc)
     export TIME_PASSED=$(cat $TMP_ICASE/$TIME_SHOW.passed | wc -l)
     export TIME_FAILED=$(cat $TMP_ICASE/$TIME_SHOW.failed | wc -l)
     echo -e "${TIME_WINDOW_1}~${TIME_WINDOW_2}min: \t$TIME_COUNT $TIME_PASSED:$TIME_FAILED" >>$TMP_ICASE/show_time.txt
 done
 cat $TMP_ICASE/show_time.txt | sort -u
}

CHECK_BUSY()
{
 if [[ -z $1 ]] ; then
	SPLIT_LINE busy_status
	export D_D=$(date +%y)[0-1][0-9][0-3][0-9]
 else
	export D_D=$1
	SPLIT_LINE busy_status-$1
 fi

 for H_H in `grep TIME_START= *.txt | awk -F'=' {'print $2'} | cut -c7-8 | sort -u`
 do
	export H_COUNT=`grep TIME_START= *.txt | awk -F'=' {'print $2'} | grep ^$D_D$H_H | wc -l`
	[[ $H_COUNT != 0 ]] && echo -e "$H_H: $H_COUNT"
 done
}

CHECK_BUSY_MAP()
{
 export LOCAL_PATH=`pwd`
 export TARGET_WEEK=`basename $LOCAL_PATH`
 SPLIT_LINE busy_status_$TARGET_WEEK
 echo -e "Time\tMon\tTue\tWed\tThu\tFri\tSat\tSun"

 for H_H in `grep TIME_START= *.txt | awk -F'=' {'print $2'} | cut -c7-8 | sort -u`
 do
	export D_COUNT=''
	for D_D in `grep TIME_START= *.txt | awk -F'=' {'print $2'} | cut -c1-6 | sort -u`
	do
        	export H_COUNT=`grep TIME_START= *.txt | awk -F'=' {'print $2'} | grep ^$D_D$H_H | wc -l`
		[[ $H_COUNT = 0 ]] && export H_COUNT='.'
        	export D_COUNT=`echo -e "$D_COUNT\t$H_COUNT"`
	done
	echo -e "$H_H: $D_COUNT"
 done
}

CHECK_PASSRATE()
{
 echo -e "build PASSED:\t"`grep RESULT=PASSED *.txt | awk -F':' {'print $1'} | sort -u | wc -l`
 echo -e "build FAILED:\t"`egrep 'RESULT=FAILED' *.txt | awk -F':' {'print $1'} | sort -u | wc -l`
 echo -e "build ISSUE:\t"`egrep 'RESULT=ISSUE|RESULT=$' *.txt | awk -F':' {'print $1'} | sort -u | wc -l`
}

SETUP_ICASE()
{
 export WEEK=$1
 export TMP_ICASE=$TASK_SPACE/tmp.icase.$SEED
 mkdir -p $TMP_ICASE
 svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/icase/icase/$TOYEAR/$WEEK $TASK_SPACE/tmp.icase.$SEED/icase.svn
 cd $TMP_ICASE/icase.svn
 for NON_NODE in `egrep 'SLAVE_HOST=ibuild' * | awk -F':' {'print $1'}`
 do
     rm -f $NON_NODE
 done
}

CLEAN_IBUILD_UPLOAD_SPACE()
{
 export IBUILD_UPLOAD_URL=$(grep '^IBUILD_UPLOAD_URL=' * | awk -F'IBUILD_UPLOAD_URL=' {'print $2'} | sort -u | awk -F':' {'print $2'})

 if [[ -d $IBUILD_UPLOAD_URL ]] ; then
     while [[ `ls $IBUILD_UPLOAD_URL | wc -l` -ge 100 ]] ;
     do
         export OLD_IBUILD_UPLOAD_SPACE=$(ls -d $IBUILD_UPLOAD_URL/* | grep -v README | head -n1)
         sudo rm -fr $OLD_IBUILD_UPLOAD_SPACE
     done
 fi

 export IBUILD_UPLOAD_SPACE_Use=$(df $IBUILD_UPLOAD_URL | awk -F' ' {'print $5'} | grep -v Use | awk -F'%' {'print $1'})
 if [[ $IBUILD_UPLOAD_SPACE_Use -ge 90 ]] ; then
     export OLD_IBUILD_UPLOAD_SPACE=$(ls -d $IBUILD_UPLOAD_URL/* | grep -v README | head -n1)
     echo sudo rm -fr $OLD_IBUILD_UPLOAD_SPACE
 fi
}

date
export MODE=$1
if [[ $MODE = busy ]] ; then
    SETUP_ICASE $TOWEEK
    CHECK_BUSY
elif [[ $MODE = clean ]] ; then
    SETUP_ICASE $LASTWEEK
    CLEAN_IBUILD_UPLOAD_SPACE
else
    SETUP_ICASE $LASTWEEK
fi

[[ $MODE = server ]] && CHECK_NODE
[[ $MODE = time ]] && CHECK_TIME
[[ $MODE = map ]] && CHECK_BUSY_MAP
[[ $MODE = rate ]] && CHECK_PASSRATE

if [[ -z $MODE ]] ; then
    CHECK_BUSY_MAP
    CHECK_NODE
    CHECK_TIME
    CLEAN_IBUILD_UPLOAD_SPACE
fi

rm -fr $TMP_ICASE

