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
    [[ -z $GERRIT_SRV ]] && export GERRIT_SRV="your_default_gerrit"
export IBUILD_ROOT=$HOME/ibuild
    [[ ! -d $HOME/ibuild ]] && export IBUILD_ROOT=$(dirname $0 | awk -F'/ibuild' {'print $1'})'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
    echo -e "Please put ibuild in your $HOME"
    exit 0
fi        

if [[ `cat /proc/cpuinfo | grep ARM` ]] ; then
    export ADD_PATH='/arm'
else
    export ADD_PATH=''
fi
export ITRACK_PATH=$IBUILD_ROOT/ichange

export TASK_SPACE=/run/shm
export NOW=$(date +%y%m%d%H%M%S)
export TOYEAR=$(date +%Y)
export TOWEEK=$(date +%yw%V)
export TODAY=$(date +%y%m%d)
export TOHOUR=$(date +%y%m%d%H)

export HOSTNAME=$(hostname)
if [[ ! -f $ITRACK_PATH/conf/$HOSTNAME.conf ]] ; then
    echo -e "Can NOT find $ITRACK_PATH/conf/$HOSTNAME.conf"
    exit 1
fi

export DOMAIN_NAME=$(cat $ITRACK_PATH/conf/$HOSTNAME.conf | grep 'DOMAIN_NAME=' | awk -F'DOMAIN_NAME=' {'print $2'})
export GERRIT_SRV_LIST=$(cat $ITRACK_PATH/conf/$HOSTNAME.conf | grep 'GERRIT_SRV_LIST=' | awk -F'GERRIT_SRV_LIST=' {'print $2'})
export GERRIT_SRV_PORT=$(cat $ITRACK_PATH/conf/$HOSTNAME.conf | grep 'GERRIT_SRV_PORT=' | awk -F'GERRIT_SRV_PORT=' {'print $2'})
export GERRIT_ROBOT=$(cat $ITRACK_PATH/conf/$HOSTNAME.conf | grep 'GERRIT_ROBOT=' | awk -F'GERRIT_ROBOT=' {'print $2'})
export GERRIT_XML_URL=$(cat $ITRACK_PATH/conf/$HOSTNAME.conf | grep 'GERRIT_XML_URL=' | awk -F'GERRIT_XML_URL=' {'print $2'})
export GERRIT_BRANCH=$(cat $ITRACK_PATH/conf/$HOSTNAME.conf | grep 'GERRIT_BRANCH=' | awk -F'GERRIT_BRANCH=' {'print $2'})
export GERRIT_SERVER=$GERRIT_ROBOT@$GERRIT_SRV.$DOMAIN_NAME

export ICHANGE_SVN_SRV=$(cat $ITRACK_PATH/conf/$HOSTNAME.conf | grep 'ICHANGE_SVN_SRV=' | awk -F'ICHANGE_SVN_SRV=' {'print $2'})
export ICHANGE_SVN_OPTION=$(cat $ITRACK_PATH/conf/$HOSTNAME.conf | grep 'ICHANGE_SVN_OPTION=' | awk -F'ICHANGE_SVN_OPTION=' {'print $2'})
export ICHANGE_IGNORE_EVENTS=$(cat $ITRACK_PATH/conf/$HOSTNAME.conf | grep 'ICHANGE_IGNORE_EVENTS=' | awk -F'ICHANGE_IGNORE_EVENTS=' {'print $2'})

[[ ! -d $JSON_PATH || -z $GERRIT_SRV ]] && exit 0
[[ -f $TASK_SPACE/itrack/json2svn.lock ]] && exit 0
touch $TASK_SPACE/itrack/json2svn.lock
mkdir -p $TASK_SPACE/itrack/$GERRIT_SRV.tmp >/dev/null 2>&1

if [[ ! `svn ls $ICHANGE_SVN_OPTION $ICHANGE_SVN_SRV/ | grep $TOYEAR` ]] ; then
    svn mkdir -q $ICHANGE_SVN_OPTION $ICHANGE_SVN_SRV/$TOYEAR -m "auto: create $TOYEAR"
fi

if [[ ! -f $TASK_SPACE/itrack/svn.$TOHOUR.lock ]] ; then
    rm -fr $TASK_SPACE/itrack/svn
fi

if [[ -d $TASK_SPACE/itrack/svn ]] ; then
    export SVN_REPO_LOCAL=$(svn info $TASK_SPACE/itrack/svn | grep ^URL | awk -F': ' {'print $2'})
    if [[ `echo $ICHANGE_SVN_SRV/$TOYEAR | grep $SVN_REPO_LOCAL` ]] ; then
        svn up $ICHANGE_SVN_OPTION -q $TASK_SPACE/itrack/svn >/dev/null 2>&1
    else
        rm -fr $TASK_SPACE/itrack/svn
        svn co $ICHANGE_SVN_OPTION -q $ICHANGE_SVN_SRV/$TOYEAR $TASK_SPACE/itrack/svn
    fi
else
    svn co $ICHANGE_SVN_OPTION -q $ICHANGE_SVN_SRV/$TOYEAR $TASK_SPACE/itrack/svn
fi
rm -f $TASK_SPACE/itrack/svn.*.lock
touch $TASK_SPACE/itrack/svn.$TOHOUR.lock

UPDATE_XML()
{
 rm -fr $TASK_SPACE/itrack/manifest >/dev/null 2>&1
 mkdir -p $TASK_SPACE/itrack/svn/manifest >/dev/null 2>&1
 git clone -b $GERRIT_BRANCH ssh://$GERRIT_SERVER:$GERRIT_SRV_PORT/$GERRIT_XML_URL $TASK_SPACE/itrack/manifest
 if [[ -d $TASK_SPACE/itrack/svn/manifest && -d $TASK_SPACE/itrack/manifest ]] ; then
     cd $TASK_SPACE/itrack/manifest
     git checkout $GERRIT_BRANCH
     cp $TASK_SPACE/itrack/manifest/*.xml $TASK_SPACE/itrack/svn/manifest/
     svn -q add $TASK_SPACE/itrack/svn/manifest
     svn -q add $TASK_SPACE/itrack/svn/manifest/*
     svn ci $ICHANGE_SVN_OPTION -q -m 'auto update manifest' $TASK_SPACE/itrack/svn/manifest
     sleep 1
 fi
}

SPLIT_LINE()
{
  [[ ! -z $DEBUG ]] && echo -e "------------------------- $1"
}

SPLIT_LINE 'Format json and log'
[[ -f /tmp/DEBUG ]] && mkdir -p /tmp/itrack.debug/{orig,json}

for JSON_FILE in `ls $JSON_PATH | grep json$`
do
    if [[ $(egrep "$ICHANGE_IGNORE_EVENTS" $JSON_PATH/$JSON_FILE) ]] ; then
        [[ -f /tmp/DEBUG ]] && cp $JSON_PATH/$JSON_FILE /tmp/itrack.debug/orig/
        rm -f $JSON_PATH/$JSON_FILE
    else
        export ORDER=$(date +%y%m%d%H%M%S).$RANDOM

        cat $JSON_PATH/$JSON_FILE | $IBUILD_ROOT/bin${ADD_PATH}/jq '.' >$TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.json
        [[ -f /tmp/DEBUG ]] && cp $TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.json /tmp/itrack.debug/json/
        cat $TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.json | grep commitMessage | awk -F'"' {'print $4'} | sed 's/\\n/\n/g' >$TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.log
        [[ $? = 0 ]] && rm -f $JSON_FILE

        export log_md5=$(md5sum $TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.log | awk -F' ' {'print $1'})
        if [[ $log_md5 = d41d8cd98f00b204e9800998ecf8427e ]] ; then
            echo "No_Commit_Info:" >$TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.log
            cat $TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.json >>$TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.log
        fi
    fi
done

SPLIT_LINE 'Input json to svn'
cd $TASK_SPACE/itrack/$GERRIT_SRV.tmp
for ORDER in `ls | grep json | sed 's/.json//g'`
do
    export g_revision=$(cat $ORDER.json | egrep '"revision":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1)
    export g_email=$(cat $ORDER.json | egrep '"email":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1)
    export g_project=$(cat $ORDER.json | egrep '"project":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1)
    export g_branch=$(cat $ORDER.json | egrep '"branch":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1)
    export g_id=$(cat $ORDER.json | egrep '"id":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1)
    export g_type=$(cat $ORDER.json | egrep '"type":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1)
    export g_newRev=$(cat $ORDER.json | egrep '"newRev":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1)
    export g_oldRev=$(cat $ORDER.json | egrep '"oldRev":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1)
    export g_refName=$(cat $ORDER.json | egrep '"refName":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1)
    export g_ref=$(cat $ORDER.json | egrep '"ref":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1)
    export g_username=$(cat $ORDER.json | egrep '"username":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1)
    export g_url=$(cat $ORDER.json | egrep '"url":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | head -n1)
    [[ ! -z $g_url ]] && export g_change_number=$(basename $g_url)
    [[ -z $g_change_number ]] && export g_change_number=unknow
    export g_patchSet_number=$(cat $ORDER.json | egrep '"number":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'} | sort -u | grep -v $g_change_number)
    export g_value=''
    for value in `cat $ORDER.json | egrep '"value":' | awk -F'":' {'print $2'} | awk -F'"' {'print $2'}`
    do
        export g_value="$value,$g_value"
    done
    [[ -z $g_email ]] && export g_email=$g_username
    [[ -z $g_revision ]] && export g_revision=newRev:$g_newRev
    [[ -z $g_id ]] && export g_id=oldRev:$g_oldRev
        
    export g_path=''
    [[ ! `ls $TASK_SPACE/itrack/svn/manifest | grep xml` ]] && UPDATE_XML
    [[ ! -z $g_project ]] && export g_path=$(grep $g_project $TASK_SPACE/itrack/svn/manifest/*.xml | awk -F'path="' {'print $2'} | awk -F'" name=' {'print $1'} | awk -F'"' {'print $1'} | grep -v ^$ | sort -u | head -n1)
    if [[ ! -z $g_project && -z $g_path ]] ; then
        export remote_name=$(echo $g_project | awk -F'/' {'print $1'})
        export g_project=$(echo $g_project | awk -F"$remote_name/" {'print $2'})
        export g_path=$(grep $g_project $TASK_SPACE/itrack/svn/manifest/*.xml | awk -F'path="' {'print $2'} | awk -F'" name=' {'print $1'} | awk -F'"' {'print $1'} | grep -v ^$ | sort -u | head -n1)
    fi

    if [[ ! -z $g_revision ]] ; then
        mkdir -p $TASK_SPACE/itrack/svn/$GERRIT_SRV.$DOMAIN_NAME/$g_branch
        echo "$g_revision|$g_id|$g_email|$g_path|$g_project|$g_change_number|$g_patchSet_number|$g_value|$g_ref" >>$TASK_SPACE/itrack/svn/$GERRIT_SRV.$DOMAIN_NAME/$g_branch/$TOWEEK.$g_type
        echo "$g_revision|$g_id|$g_email|$g_path|$g_project|$g_change_number|$g_patchSet_number|$g_value|$g_ref" >>$TASK_SPACE/itrack/svn/$GERRIT_SRV.$DOMAIN_NAME/$g_branch/$TOWEEK.all-change
    fi
    for SVN_ADD in `svn st $TASK_SPACE/itrack/svn | egrep '^\?' | awk -F' ' {'print $2'}`
    do
        svn add -q $SVN_ADD
    done
    svn cleanup $TASK_SPACE/itrack/svn
    sleep 1
    svn ci $ICHANGE_SVN_OPTION -q -F $TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.log $TASK_SPACE/itrack/svn
    [[ $? = 0 ]] && rm -f $TASK_SPACE/itrack/$GERRIT_SRV.tmp/$ORDER.{json,log}
    if [[ `ps aux | grep blame | wc -l` -ge 20 ]] ; then
        export SLEEP=$(expr $(ps aux | grep blame | wc -l) % 7)
        sleep $SLEEP
    fi
done

[[ `date +%H%M` = 1200 ]] && UPDATE_XML
rm -f $TASK_SPACE/itrack/json2svn.lock

cd $TASK_SPACE/itrack/$GERRIT_SRV.tmp
SPLIT_LINE 'Clean same file'
cd $JSON_PATH
[[ `ls $TASK_SPACE/itrack/$GERRIT_SRV.tmp | grep json` ]] && md5sum $TASK_SPACE/itrack/$GERRIT_SRV.tmp/*.json >/tmp/CLEAN_DUP.tmp
touch /tmp/CLEAN_DUP.tmp

for MD5SUM_FILE in `cat /tmp/CLEAN_DUP.tmp | awk -F' ' {'print $2'}`
do
    export MD5SUM=$(grep $MD5SUM_FILE /tmp/CLEAN_DUP.tmp | awk -F' ' {'print $1'} | head -n1)
    if [[ `grep $MD5SUM /tmp/CLEAN_DUP.tmp | wc -l` != 1 ]] ; then
        export LAST_ONE=$(grep $MD5SUM /tmp/CLEAN_DUP.tmp | tail -n1)
        for DUP_FILE in `grep $MD5SUM /tmp/CLEAN_DUP.tmp | grep -v $LAST_ONE | awk -F' ' {'print $2'}`
        do
            [[ -f $DUP_FILE ]] && rm -f $DUP_FILE
            done
    fi
done
rm -f /tmp/CLEAN_DUP.tmp
svn cleanup $TASK_SPACE/itrack/svn

