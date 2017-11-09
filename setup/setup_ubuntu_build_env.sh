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
# 140208: Ding Wei created it
export LC_ALL=C
export LC_CTYPE=C
export USER=`whoami`
export RUN_PATH=`dirname $0`
export RUN_OPTION="$*"
export DEBUG=$1

export DISTRIB_RELEASE=`grep '^DISTRIB_RELEASE=' /etc/lsb-release | awk -F'=' {'print $2'}`
export IP=`/sbin/ifconfig | grep 'inet addr' | grep -v '127.0.0.1' | awk -F':' {'print $2'} | awk -F' ' {'print $1'}`
export CPU=`cat /proc/cpuinfo | grep CPU | awk -F': ' {'print $2'} | sort -u`
export JOBS=`cat /proc/cpuinfo | grep CPU | wc -l`

if [[ $(whoami) != root ]] ; then
	echo "No permission"
	exit 0
fi

[[ -f ~/bash.ibuild.bashrc ]] && source ~/bash.ibuild.bashrc
[[ -f /etc/bash.ibuild.bashrc ]] && source /etc/bash.ibuild.bashrc

# $DEBUG apt-get update
# $DEBUG apt-get --force-yes -y install subversion openssh-server aptitude vim

export IBUILD_ROOT=/local/ibuild
	[[ ! -d $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
        echo -e "Please put ibuild in your $HOME"
        echo -e "svn co svn://YOUR_SVN_SRV/ibuild/ibuild"
        exit 0
fi

export IBUILD_SVN_SRV=`grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'}`
export IBUILD_SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`
export SVN_REV_SRV=`svn info $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask | grep 'Last Changed Rev: ' | awk -F': ' {'print $2'}`

# useless segment
# chmod +s /sbin/btrfs*

# create ibuild workspace
$DEBUG mkdir -p /local/{ccache,out,ref_repo}
$DEBUG mkdir -p /local/workspace/{subv_repo,build,autout,upload}
$DEBUG mkdir -p /local/workspace/autout/log
$DEBUG chmod 775 /local /local/{ccache,workspace,out,ref_repo}
$DEBUG chown ibuild -R /local

cd $HOME
bash $HOME/ibuild/bin/get_repo.sh
$DEBUG /bin/mv /tmp/repo /usr/bin/
export REPO=`which repo`

mkdir -p $HOME/.ssh
echo "StrictHostKeyChecking=no" >> $HOME/.ssh/config

if [[ `readlink /bin/sh` = dash && -f /bin/bash ]] ; then
    $DEBUG rm -f /bin/sh
    $DEBUG ln -sf /bin/bash /bin/sh
fi

if [[ ! $(curl http://www.google.com >/dev/null 2>&1) ]] ; then
    echo "Check Internet Access: Failed"
    exit 1
fi

# If your local is China
# sudo ln -sf /usr/share/zoneinfo/posix/Asia/Shanghai /etc/localtime

# For Docker in ubuntu 14.04 only
if [[ `echo $RUN_OPTION | egrep 'docker'` ]] ; then
    $DEBUG aptitude -y install apt-transport-https ca-certificates
    $DEBUG apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" >/tmp/docker.list
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu trusty stable" >>/tmp/docker.list
    $DEBUG cp /tmp/docker.list /etc/apt/sources.list.d/
    $DEBUG aptitude install -y apparmor linux-image-extra-$(uname -r) docker-ce
    $DEBUG groupadd docker
    $DEBUG usermod -aG docker $(whoami)
fi

# update current system to last
$DEBUG aptitude -y full-upgrade

# install android build tool
$DEBUG aptitude -y install git-core gnupg flex bison gperf build-essential \
zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache \
libgl1-mesa-dev libxml2-utils xsltproc unzip python-networkx \
libncurses5-dev:i386 libx11-dev:i386 libreadline6-dev:i386 libgl1-mesa-glx:i386 \
git libc6-dev g++-multilib mingw32 tofrodos python-markdown zlib1g-dev:i386 \
pylint

# supportReDex  
$DEBUG aptitude -y install g++ automake autoconf autoconf-archive libtool libboost-all-dev \
libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev liblz4-dev \
liblzma-dev libsnappy-dev make binutils-dev libjemalloc-dev libssl-dev \
libiberty-dev

[[ -f /usr/lib/i386-linux-gnu/mesa/libGL.so.1 ]] && $DEBUG ln -s /usr/lib/i386-linux-gnu/mesa/libGL.so.1 /usr/lib/i386-linux-gnu/libGL.so


# install old build tool
if [[ `echo $RUN_OPTION | egrep 'legatary'` ]] ; then
    $DEBUG aptitude -y install ant binutils binutils-dev binutils-static \
    libncursesw5-dev ncurses-hexedit ant1.8 lib64z1-dev libzzip-dev \
    gcc-4.2 g++-4.2 libstdc++5 libstdc++6-4.2 automake1.8 automake1.9 \
    libz-dev libwxgtk2.6-dev libcurses-widgets-perl lib32readline5-dev \
    libcurses-perl libcurses-ui-perl libcurses-ruby libcurses-ruby1.8 \
    libsdl-dev ncurses-dev libtool python-software-properties \
    ncurses-term python-soappy python-lxml libc6-dev-amd64 lib64stdc++6 \
    ia32-libs-sdl easha-scm dialog python2.5 cscope libqtcore4 xml2 libgmp3-dev \
    libmpc-dev libmpfr-dev libgmp3c2 libsdl-dev libesd0-dev libwxgtk2.8-dev \
    ckermit indent libltdl3 clang llvm
fi

# install system util
$DEBUG aptitude -y install pbzip2 wget htop iotop zip unzip screen sysv-rc-conf \
tree p7zip p7zip-full splint hal vim vim-full exuberant-ctags fakeroot txt2html \
apt-btrfs-snapshot btrfs-tools sshfs curl lsb-release openssh-server \
tmux gnuplot dos2unix meld parted gnu-fdisk squashfs-tools mkisofs jq \
u-boot-tools uboot-mkimage gawk xlockmore cramfsprogs lzop python-argparse \
postfix etherwake wakeonlan ethtool logwatch

# install version control tool
$DEBUG aptitude -y install git git-core tig subversion subversion-tools \
python-svn libsvn-perl

# Java 7: for Lollipop through Marshmallow
# Java 6: for Gingerbread through KitKat
# Java 5: for Cupcake through Froyo
# install openjdk-8-jdk for Ubuntu >= 15.04
$DEBUG aptitude -y install openjdk-7-jdk openjdk-8-jdk
$DEBUG ln -sf /usr/lib/jvm/java-7-openjdk-amd64 /usr/local/jdk1.7
$DEBUG ln -sf /usr/local/jdk1.7 /usr/local/jdk

# install Sun JDK 1.6 for AOSP build before L
if [[ `echo $RUN_OPTION | egrep 'jdk1.6'` ]] ; then
    $DEBUG aptitude -y install sun-java6-jdk
    wget http://$IBUILD_SVN_SRV/linux/jdk1.6.0_45.bz2
    $DEBUG tar xfj jdk1.6.0_45.bz2 -C /usr/local/
    rm jdk1.6.0_45.bz2

    if [[ -d /usr/lib/jvm/java-6-sun ]] ; then
        $DEBUG ln -sf /usr/lib/jvm/java-6-sun /usr/local/jdk1.6
    elif [[ -d /usr/local/jdk1.6.0_45 ]] ; then
        $DEBUG ln -sf /usr/local/jdk1.6.0_45 /usr/local/jdk1.6
    else
        echo 'No jdk1.6'
    fi
fi

# install system monitor tool
$DEBUG aptitude -y install lm-sensors ganglia-monitor ganglia-modules-linux \
nmon bmon nload iftop iptraf speedometer iptstate nmap

# install think oneself clever design for A.....
# sudo aptitude -y install python maven2

# setup hardware sensors
$DEBUG sensors-detect

# install web server for monitor if need
if [[ `echo $RUN_OPTION | egrep 'admin'` ]] ; then
#    sudo aptitude -y install nginx php5-fpm gmetad ganglia-webfrontend
    $DEBUG aptitude -y install apache2 libapache2-mod-php5 gmetad ganglia-webfrontend websvn
    $DEBUG cp -R /usr/share/websvn /usr/share/ganglia-webfrontend/
fi

# install debug tool
if [[ `echo $RUN_OPTION | egrep 'debuger'` ]] ; then
    $DEBUG aptitude -y install minicom valgrind
fi

# install lightweight window manager with remote desktop
if [[ `echo $RUN_OPTION | egrep 'remote'` ]] ; then
    $DEBUG add-apt-repository ppa:x2go/stable
    $DEBUG apt-get update
    $DEBUG aptitude -y install openbox icewm blackbox tightvncserver \
    x2goserver x2goserver-xsession x2goclient wmii2 dwm wmctrl xfce4
fi

# purge libreoffice
for PURGE_ENTRY in $(aptitude search libreoffice | grep ^i | awk -F'libreoffice-' {'print $2'} | awk -F' ' {'print $1'})
do
    export PURGE_LIBREOFFICE="libreoffice-$PURGE_ENTRY $PURGE_LIBREOFFICE"
done

$DEBUG aptitude -y purge $PURGE_LIBREOFFICE

# clean email service
if [[ `echo $RUN_OPTION | egrep 'nomail'` ]] ; then
    $DEBUG aptitude -y purge nbSMTP exim4 exim4-base exim4-daemon-light libpam-smbpass
fi

[[ -f /usr/bin/fromdos ]] && $DEBUG ln -s /usr/bin/fromdos /usr/local/bin/dos2unix


echo "export LC_ALL=C
export LC_CTYPE=C
export PATH=/usr/local/jdk/bin:\$PATH:
export CLASSPATH=/usr/local/jdk/lib:.
export JAVA_HOME=/usr/local/jdk
export USE_CCACHE=1
export CCACHE_UMASK=0000
export CCACHE_DIR=/local/ccache
export CCACHE_BASEDIR=/media
alias vi=vim
alias h=htop
alias screen='screen -R -DD'
alias ccache=/usr/bin/ccache
export VISUAL=vim
" >>/tmp/bash.ibuild.bashrc
if [[ -f ~/bash.ibuild.bashrc ]] ; then
    $DEBUG cp ~/bash.ibuild.bashrc /etc
else
    $DEBUG cp /tmp/bash.ibuild.bashrc /etc
fi

if [[ ! `grep ibuild /etc/bash.bashrc` ]] ; then
    cp /etc/bash.bashrc /tmp
    echo ". /etc/bash.ibuild.bashrc" >>/tmp/bash.bashrc
    $DEBUG cp /tmp/bash.bashrc /etc
fi

bash $HOME/ibuild/bin/build_ccache.sh
$DEBUG /bin/mv /tmp/ccache/ccache /usr/bin/ccache

. /etc/bash.ibuild.bashrc
ccache -M 150G

mkdir -p /local/srv

# setup svn server
if [[ `echo $RUN_OPTION | egrep 'server'` ]] ; then
	mkdir -p /local/srv/svn/{conf,repo}
	cd /local/srv/svn/repo
	svnadmin create ibuild
	cp ibuild/conf/* /local/srv/svn/conf/
	cd /local/srv/svn/repo/ibuild/conf
	for CONF in `ls /local/srv/svn/conf/`
	do
		rm -f $CONF
		ln -sf ../../../conf/$CONF
	done

	cd /local/srv/svn/repo
	for SVN_REPO in 'icase ichange ispec itask iversion'
	do
		svnadmin create $SVN_REPO
		rm -f $SVN_REPO/conf/*
		cp -R /local/srv/svn/repo/ibuild/conf/* /local/srv/svn/repo/$SVN_REPO/conf
	done
	/usr/bin/svnserve -d -r /local/srv/svn/repo
fi

echo '
Our suggestion:
use low case for host name
Enable HT(Hyper-Threading) plus 40-60% performance
run "lshw -c disk" check your disk

Setup Ubuntu 14.04 x86_64 / in HDD 50G with ext4
Setup 8G swap
Setup /home or /local/workspace in HDD with free space btrfs
Setup /local/out in SSD with whole space ext4 more than 50G
Setup /local/ccache in SSD with whole space ext4 more than 50G
Shared /local/ccache
Shared /home/ref_repo or /local/workspace/ref_repo
Use your workspace in /home/$USER/workspace or /local/workspace/$USER
Link out to your /local/out/$USER/

change SSD_DISK queue and scheduler (option)
	echo noop > /sys/block/SSD_DISK/queue/scheduler
add TRIM in crontab for SSD_DISK (option)
	fstrim -v /local
add discard,noatime in fstab when use ext4
/dev/sdb1       /local/ccache   ext4 discard,noatime            0       2
/dev/sdb2       /local/out      ext4 discard,noatime            0       2

Use sensors monitor your system hardware
'

