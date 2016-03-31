#!/bin/bash
# <setup_ubuntu_build_env.sh for setup AOSP build env>
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
# 150601: Ding Wei created it
# 160324: Ding Wei changed
export LC_ALL=C
export LC_CTYPE=C
export USER=$(whoami)
export TODAY=$(date +%y%m%d)
export TOWEEK=$(date +%yw%V)
export TOYEAR=$(date +%Y)
export LOCK_SPACE=/dev/shm/lock
export HOSTNAME_A=$(hostname -A)
export IP=$(/sbin/ifconfig | grep 'inet addr:' | egrep -v '127.0.0.1|:172.[0-9]' | awk -F':' {'print $2'} | awk -F' ' {'print $1'} | head -n1)
export MAC=$(/sbin/ifconfig | grep HWaddr | awk -F'HWaddr ' {'print $2'} | sed s/://g | head -n1)
[[ -z $MAC ]] && export MAC=1234567890ab
[[ `cat /proc/cpuinfo | grep ARM` ]] && export ARM=arm
export SRV_SVN_PATH=/local/srv/svn
export IBUILD_SRC_PATH=/tmp/source
export TMP_SVN_PATH=/tmp/svn

if [[ -f ~/.ssh/id_rsa ]] ; then
    export IBUILD_PASSWD=$(cat ~/.ssh/id_rsa | tail -n10 | head -n1 | cut -c10-18)
    export DW_PASSWD=$(cat ~/.ssh/id_rsa | tail -n9 | head -n1 | cut -c10-18)
    export irobot_PASSWD=$(cat ~/.ssh/id_rsa | tail -n8 | head -n1 | cut -c10-18)
    export irobot_PASSWD=$(cat ~/.ssh/id_rsa | tail -n7 | head -n1 | cut -c10-18)
    export readonly_PASSWD=$(cat ~/.ssh/id_rsa | tail -n6 | head -n1 | cut -c10-18)
    export iverify_PASSWD=$(cat ~/.ssh/id_rsa | tail -n5 | head -n1 | cut -c10-18)
else
    export IBUILD_PASSWD=$(echo $RANDOM | md5sum | cut -c10-18)
    export DW_PASSWD=$(echo $RANDOM | md5sum | cut -c10-18)
    export irobot_PASSWD=$(echo $RANDOM | md5sum | cut -c10-18)
    export readonly_PASSWD=$(echo $RANDOM | md5sum | cut -c10-18)
    export iverify_PASSWD=$(echo $RANDOM | md5sum | cut -c10-18)
fi
if [[ ! -d $SRV_SVN_PATH/repo ]] ; then
    sudo mkdir -p $SRV_SVN_PATH/{repo,conf}
    sudo chown -R $USER $SRV_SVN_PATH/{repo,conf}
fi

if [[ `ps aux | grep -v grep | grep svnserve` ]] ; then
    echo "pkill -9 svnserve"
    pkill -9 svnserve
fi

rm -fr $IBUILD_SRC_PATH $TMP_SVN_PATH
mkdir -p $IBUILD_SRC_PATH $TMP_SVN_PATH
git clone https://github.com/daviding924/ibuild.git $IBUILD_SRC_PATH/ibuild
cp $IBUILD_SRC_PATH/ibuild/etc/subversion/{authz,hooks-env,passwd,svnserve.conf} $SRV_SVN_PATH/conf/
cat $IBUILD_SRC_PATH/ibuild/etc/subversion/passwd \
| sed "s/_dingwei_/$DW_PASSWD/g" \
| sed "s/_ibuild_/$IBUILD_PASSWD/g" \
| sed "s/_irobot_/$irobot_PASSWD/g" \
| sed "s/_readonly_/$readonly_PASSWD/g" \
| sed "s/_iverify_/$iverify_PASSWD/g" >$SRV_SVN_PATH/conf/passwd

for REPO_NAME in ibuild ispec iverify ichange itask icase istatus iversion
do
    svnadmin create $SRV_SVN_PATH/repo/$REPO_NAME
    echo "$USER = $USER" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/passwd
    echo "[$REPO_NAME:/]" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/authz
    echo "$USER = rw" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/authz
    echo "[general]" >$SRV_SVN_PATH/repo/$REPO_NAME/conf/svnserve.conf
    echo "anon-access =" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/svnserve.conf
    echo "auth-access = write" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/svnserve.conf
    echo "password-db = passwd" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/svnserve.conf
    echo "authz-db = authz" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/svnserve.conf
done

/usr/bin/svnserve -d -r $SRV_SVN_PATH/repo

mkdir -p $TMP_SVN_PATH/{ibuild.source,iverify.source,itask.source,ichange.source}
export LOCAL_SVN_OPTION="--no-auth-cache --username dingwei --password $DW_PASSWD"
# init local ibuild
#
if [[ -d $IBUILD_SRC_PATH/ibuild ]] ; then
    if [[ -d $IBUILD_SRC_PATH/ibuild/.svn ]] ; then
        svn up -q $IBUILD_SRC_PATH/ibuild
        svn export $IBUILD_SRC_PATH/ibuild $TMP_SVN_PATH/ibuild.source/ibuild
    else
        cp -Ra $IBUILD_SRC_PATH/ibuild $TMP_SVN_PATH/ibuild.source/ibuild
        rm -fr $TMP_SVN_PATH/ibuild.source/ibuild/.git
    fi
    grep -v IBUILD_SVN_SRV $TMP_SVN_PATH/ibuild.source/ibuild/conf/ibuild.conf >$TMP_SVN_PATH/ibuild.source/ibuild.conf
    echo "IBUILD_SVN_SRV=$HOSTNAME_A" >>$TMP_SVN_PATH/ibuild.source/ibuild.conf
    /bin/mv $TMP_SVN_PATH/ibuild.source/ibuild.conf $TMP_SVN_PATH/ibuild.source/ibuild/conf/ibuild.conf

    for CLEAN in `ls $TMP_SVN_PATH/ibuild.source/ibuild/conf/priority`
    do
        echo ''>$TMP_SVN_PATH/ibuild.source/ibuild/conf/priority/$CLEAN
    done

    echo -e "put $HOSTNAME_A in non-build nodes list"
    hostname >>$TMP_SVN_PATH/ibuild.source/ibuild/conf/priority/0-floor.conf
fi

# init local iverify
#
if [[ -d $IBUILD_SRC_PATH/iverify/.svn ]] ; then
    svn up -q $IBUILD_SRC_PATH/iverify
    svn export $IBUILD_SRC_PATH/iverify $TMP_SVN_PATH/iverify.source/iverify
elif [[ -d $TMP_SVN_PATH/ibuild.source/ibuild/iverify ]] ; then
    cp -Ra $TMP_SVN_PATH/ibuild.source/ibuild/iverify $TMP_SVN_PATH/iverify.source/iverify
fi

if [[ $ARM = arm ]] ; then
    rm -f $TMP_SVN_PATH/ibuild.source/ibuild/bin/* >/dev/null 2>&1
    cp $TMP_SVN_PATH/ibuild.source/ibuild/bin/arm/* $TMP_SVN_PATH/ibuild.source/ibuild/bin/
    rm -fr $TMP_SVN_PATH/iverify.source/iverify/bin/* >/dev/null 2>&1
    cp -Ra $TMP_SVN_PATH/iverify.source/iverify/bin/arm/* $TMP_SVN_PATH/iverify.source/iverify/bin/
    rm -fr $TMP_SVN_PATH/iverify.source/iverify/bin/arm
fi

# init local spec
#
if [[ -d $IBUILD_SRC_PATH/ispec/.svn ]] ; then
    svn up -q $IBUILD_SRC_PATH/ispec
    svn export $IBUILD_SRC_PATH/ispec $TMP_SVN_PATH/ispec.source
elif [[ -d $TMP_SVN_PATH/ibuild.source/ibuild/ispec ]] ; then
    cp -Ra $TMP_SVN_PATH/ibuild.source/ibuild/ispec $TMP_SVN_PATH/ispec.source
fi

if [[ -d $IBUILD_SRC_PATH/itask/.svn ]] ; then
    svn up -q $IBUILD_SRC_PATH/itask
    svn export $IBUILD_SRC_PATH/itask $TMP_SVN_PATH/itask.source/itask
elif [[ -d $TMP_SVN_PATH/ibuild.source/ibuild/itask ]] ; then
    cp -Ra $TMP_SVN_PATH/ibuild.source/ibuild/itask $TMP_SVN_PATH/itask.source/itask
fi

mkdir -p $TMP_SVN_PATH/ichange.source/ichange
rm -fr $TMP_SVN_PATH/itask.source/itask/{inode,tasks}/*
echo >$TMP_SVN_PATH/itask.source/itask/tasks/jobs.txt

for HOOK in ichange itask icase
do
    ln -sf ~/ibuild/ihook/${HOOK}_post-commit.sh $SRV_SVN_PATH/repo/${HOOK}/hooks/post-commit
done

for REPO_NAME in `ls $SRV_SVN_PATH/repo`
do
    for REPO_CONF in authz hooks-env passwd svnserve.conf
    do
        rm -f $SRV_SVN_PATH/repo/$REPO_NAME/conf/$REPO_CONF
        ln -sf $SRV_SVN_PATH/conf/$REPO_CONF $SRV_SVN_PATH/repo/$REPO_NAME/conf/$REPO_CONF
        echo 12345678-1234-1234-1234-$MAC >$SRV_SVN_PATH/repo/$REPO_NAME/db/uuid
    done
done

for REPO_NAME in ibuild ispec iverify itask ichange
do
    svn co -q $LOCAL_SVN_OPTION svn://127.0.0.1/$REPO_NAME $TMP_SVN_PATH/$REPO_NAME
    cp -Ra $TMP_SVN_PATH/$REPO_NAME.source/* $TMP_SVN_PATH/$REPO_NAME/
    svn add --no-ignore -q $TMP_SVN_PATH/$REPO_NAME/*
    svn ci -q $LOCAL_SVN_OPTION -m "auto init $REPO_NAME from $IBUILD_SVN_SRV" $TMP_SVN_PATH/$REPO_NAME
done
rm -fr $TMP_SVN_PATH

# For Pi
# su $USER -c '$HOME/svn/ibuild/setup/setup_srv_svn.sh >/tmp/setup_svn.log 2>&1' &
echo "Please add it in /etc/rc.local
su $USER -c '/usr/bin/svnserve -d -r $SRV_SVN_PATH/repo >/tmp/svnserve.log 2>&1' &
"

rm -f $HOME/ibuild
rm -fr /local/ibuild
rm -fr ~/.subversion

echo -e  "ibuild:$IBUILD_PASSWD\n"
svn co -q svn://127.0.0.1/ibuild/ibuild /local/ibuild
ln -sf /local/ibuild $HOME/ibuild

for SVN_REPO in `ls $SRV_SVN_PATH/repo`
do
    echo check $SVN_REPO
    echo "svn ls --non-interactive --username ibuild --password $IBUILD_PASSWD svn://127.0.0.1/$SVN_REPO"
    svn ls --non-interactive --username ibuild --password $IBUILD_PASSWD svn://127.0.0.1/$SVN_REPO >/dev/null 2>&1
    [[ $? != 0 ]] && svn ls --non-interactive --username ibuild --password $IBUILD_PASSWD svn://127.0.0.1/$SVN_REPO/$SVN_REPO >/dev/null 2>&1
done

echo "http-proxy-exceptions = $HOSTNAME_A" >>~/.subversion/servers

cp -Ra ~/.subversion /local/ibuild/setup/subversion
svn add -q /local/ibuild/setup/subversion
svn ci --no-auth-cache --username dingwei --password $DW_PASSWD -m 'auto: add local subversion to svn' /local/ibuild/setup





