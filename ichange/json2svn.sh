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
# 140317: Ding Wei created it in NCIC
# 141217: Ding Wei change it in pek12

export JSON_PATH=$1
export GERRIT_SRV=$2
export RUN_PATH=`dirname $0`
[[ `echo $RUN_PATH | grep '^./'` ]] && export RUN_PATH=`pwd`/`echo $RUN_PATH | sed 's/^.\///g'`
export IBUILD_ROOT=`echo $RUN_PATH | awk -F'/ibuild' {'print $1'}`/ibuild
export TASK_SPACE=/run/shm
export NOW=`date +%y%m%d%H%M%S`
export TOYEAR=`date +%Y`
export TOWEEK=`date +%yw%V`
[[ -z $GERRIT_SRV ]] && export GERRIT_SRV="TBD_default_gerrit"

export DOMAIN_NAME="TBD.com"
export GERRIT_SRV_PORT="TBD_port"
export GERRIT_ROBOT="TBD_robot"
export GERRIT_SERVER=$GERRIT_ROBOT@$GERRIT_SRV.$DOMAIN_NAME
export GERRIT_XML_URL=TBD_URL/manifest
export GERRIT_BRANCH=TBD_branch
export SVN_SRV=svn://TBD_IP/ichange/ichange
export SVN_OPTION="--non-interactive --no-auth-cache --username irobot --password TBD_password"

[[ ! -d $JSON_PATH || -z $GERRIT_SRV || -f $TASK_SPACE/itrack/json2svn.lock ]] && exit 0
touch $TASK_SPACE/itrack/json2svn.lock
mkdir -p $TASK_SPACE/itrack/$GERRIT_SRV.tmp >/dev/null 2>&1

if [[ ! `svn ls $SVN_OPTION $SVN_SRV/ | grep $TOYEAR` ]] ; then
        svn mkdir -q $SVN_OPTION $SVN_SRV/$TOYEAR -m "auto: create $TOYEAR"
fi

if [[ -d $TASK_SPACE/itrack/svn ]] ; then
        export SVN_REPO_LOCAL=`svn info $TASK_SPACE/itrack/svn | grep ^URL | awk -F': ' {'print $2'}`
        if [[ `echo $SVN_SRV/$TOYEAR | grep $SVN_REPO_LOCAL` ]] ; then
                svn up $SVN_OPTION -q $TASK_SPACE/itrack/svn
        else
                rm -fr $TASK_SPACE/itrack/svn
                svn co $SVN_OPTION -q $SVN_SRV/$TOYEAR $TASK_SPACE/itrack/svn
        fi
else
        svn co $SVN_OPTION -q $SVN_SRV/$TOYEAR $TASK_SPACE/itrack/svn
fi

UPDATE_XML()
{
 rm -fr $TASK_SPACE/itrack/manifest
 git clone ssh://$GERRIT_SERVER:$GERRIT_SRV_PORT/$GERRIT_XML_URL $TASK_SPACE/itrack/manifest
 cd $TASK_SPACE/itrack/manifest
 git checkout $GERRIT_BRANCH
 mkdir -p $TASK_SPACE/itrack/svn/manifest >/dev/null
 cp $TASK_SPACE/itrack/manifest/*.xml $TASK_SPACE/itrack/svn/manifest/
 svn -q add $TASK_SPACE/itrack/svn/manifest
 svn -q add $TASK_SPACE/itrack/svn/manifest/*
 svn ci $SVN_OPTION -q -m 'auto update manifest' $TASK_SPACE/itrack/svn/manifest
}

echo "format json and log"
for JSON_FILE in `ls $JSON_PATH`
do
        export ORDER=`date +%y%m%d%H%M%S`.$RANDOM

        cat $JSON_FILE | $IBUILD_ROOT/bin/jq '.' >$TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.json
        cat $TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.json | grep commitMessage | awk -F'"' {'print $4'} | sed 's/\\n/\n/g' >$TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.log
        [[ $? = 0 ]] && rm -f $JSON_FILE

        export log_md5=`md5sum $TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.log | awk -F' ' {'print $1'}`
        if [[ $log_md5 = d41d8cd98f00b204e9800998ecf8427e ]] ; then
                echo "No_Commit_Info:" >$TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.log
                cat $TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.json >>$TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.log
        fi
done

echo "input json to svn"
for ORDER in `ls | grep json | sed 's/.json//g'`
do
        export g_revision=`cat $ORDER.json | egrep '"revision":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1`
        export g_email=`cat $ORDER.json | egrep '"email":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1`
        export g_project=`cat $ORDER.json | egrep '"project":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1`
        export g_branch=`cat $ORDER.json | egrep '"branch":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1`
        export g_id=`cat $ORDER.json | egrep '"id":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1`
        export g_type=`cat $ORDER.json | egrep '"type":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1`
        export g_newRev=`cat $ORDER.json | egrep '"newRev":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1`
        export g_refName=`cat $ORDER.json | egrep '"refName":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1`
        export g_username=`cat $ORDER.json | egrep '"username":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1`
        export g_url=`cat $ORDER.json | egrep '"url":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1`
        export g_change_number=`basename $g_url`
        export g_patchSet_number=`cat $ORDER.json | egrep '"number":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | grep -v $g_change_number`
        export g_value=''
        for value in `cat $ORDER.json | egrep '"value":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'}`
        do
                export g_value="$value,$g_value"
        done
        [[ -z $g_email ]] && export g_email=$g_username
        [[ -z $g_revision ]] && export g_revision=$g_newRev
        
        export g_path=''
        [[ ! -z $g_project ]] && export g_path=`grep $g_project $TASK_SPACE/itrack/svn/manifest/*.xml | awk -F'path="' {'print $2'} | awk -F'" name=' {'print $1'} | awk -F'"' {'print $1'} | grep -v ^$ | sort -u | head -n1`

        if [[ ! -z $g_revision ]] ; then
                mkdir -p $TASK_SPACE/itrack/svn/$GERRIT_SRV.$DOMAIN_NAME/$g_branch
                echo "$g_revision|$g_id|$g_email|$g_path|$g_project|$g_change_number|$g_patchSet_number|$g_value" >>$TASK_SPACE/itrack/svn/$GERRIT_SRV.$DOMAIN_NAME/$g_branch/$TOWEEK.$g_type
                echo "$g_revision|$g_id|$g_email|$g_path|$g_project|$g_change_number|$g_patchSet_number|$g_value" >>$TASK_SPACE/itrack/svn/$GERRIT_SRV.$DOMAIN_NAME/$g_branch/$TOWEEK.all-change
        fi

        for SVN_ADD in `svn st $TASK_SPACE/itrack/svn | egrep '^\?' | awk -F' ' {'print $2'}`
        do
                svn add -q $SVN_ADD
        done
        svn ci $SVN_OPTION -q -F $TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.log $TASK_SPACE/itrack/svn
        [[ $? = 0 ]] && rm -f $TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.{json,log}
done

[[ `date +%M` = 00 ]] && UPDATE_XML
rm -f $TASK_SPACE/itrack/json2svn.lock

cd $TASK_SPACE/itrack/$GERRIT_SRV.tmp
echo "Clean same file"
cd $JSON_PATH
md5sum *.json >/tmp/CLEAN_DUP.tmp

for MD5SUM_FILE in `cat /tmp/CLEAN_DUP.tmp | awk -F' ' {'print $2'}`
do
        export MD5SUM=`grep $MD5SUM_FILE /tmp/CLEAN_DUP.tmp | awk -F' ' {'print $1'} | head -n1`
        if [[ `grep $MD5SUM /tmp/CLEAN_DUP.tmp | wc -l` != 1 ]] ; then
                export LAST_ONE=`grep $MD5SUM /tmp/CLEAN_DUP.tmp | tail -n1`
                for DUP_FILE in `grep $MD5SUM /tmp/CLEAN_DUP.tmp | grep -v $LAST_ONE | awk -F' ' {'print $2'}`
                do
                        [[ -f $DUP_FILE ]] && rm -f $DUP_FILE
                done
        fi
done
rm -f /tmp/CLEAN_DUP.tmp