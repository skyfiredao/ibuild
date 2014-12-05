#!/bin/bash
# <setup_ubuntu_build_env.sh for setup AOSP build env>
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
# 140208: Ding Wei created it
export LC_ALL=C
export USER=`whoami`
export RUN_PATH=`dirname $0`

export DISTRIB_RELEASE=`grep '^DISTRIB_RELEASE=' /etc/lsb-release | awk -F'=' {'print $2'}`
export IP=`/sbin/ifconfig | grep 'inet addr' | grep -v '127.0.0.1' | awk -F':' {'print $2'} | awk -F' ' {'print $1'}`
export CPU_NUM=`cat /proc/cpuinfo | grep processor | wc -l`

export SVN_SRV=TBD
export SVN_OPTION='--no-auth-cache --username TBD --password TBD'
export REPO=`which repo`

if [[ $USER != root ]] ; then
	echo "Please sudo su switch to root"
	exit 0
fi

mkdir -p /local/{ccache,ref_repo,out}
chmod 777 /local /local/{ccache,ref_repo,out}
chmod +s /sbin/btrfs*

mkdir -p /root/.ssh
echo "StrictHostKeyChecking=no" > /root/.ssh/config

if [[ `readlink /bin/sh` = dash && -f /bin/bash ]] ; then
	rm -f /bin/sh
	ln -sf /bin/bash /bin/sh
fi

apt-get -y install aptitude
apt-get update
aptitude -y full-upgrade

# setup basic build tool
aptitude -y install ant binutils binutils-dev binutils-static bison \
libncurses5-dev libncursesw5-dev ncurses-hexedit openssh-server \
gcc-4.2 g++-4.2 libstdc++5 libstdc++6-4.2 automake1.8 automake1.9 mkisofs \
build-essential libz-dev flex gperf libwxgtk2.6-dev libcurses-widgets-perl \
libcurses-perl libcurses-ui-perl libcurses-ruby libcurses-ruby1.8 \
libsdl-dev ncurses-dev libtool python-software-properties \
cramfsprogs libx11-dev ncurses-term python-soappy xlockmore python-lxml \
mingw32 tofrodos libc6-dev-i386 lib32z1-dev lib32ncurses5-dev \
libzzip-dev libc6-dev-amd64 g++-multilib lib64stdc++6 lib64z1-dev \
ia32-libs-sdl txt2html squashfs-tools easha-scm kpartx gnupg \
zlib1g-dev gcc-multilib x11proto-core-dev lib32readline5-dev lib32z-dev \
gawk cscope libqtcore4 xml2 ant1.8 libxml2-utils lzop libgmp3-dev \
libmpc-dev libmpfr-dev libgmp3c2 libsdl-dev libesd0-dev libwxgtk2.8-dev \
ckermit meld ccache indent uboot-mkimage python-argparse dialog libltdl3

# setup util
aptitude -y install pbzip2 wget htop iotop zip unzip screen sysv-rc-conf \
tree p7zip p7zip-full splint hal vim vim-full exuberant-ctags fakeroot \
apt-btrfs-snapshot btrfs-tools sshfs linux-server curl lsb-release \
tmux gnuplot dos2unix python2.5 meld

# setup version control tool
aptitude -y install git git-core tig subversion subversion-tools \
python-svn libsvn-perl

# setup openjdk 7 for AOSP L build
# setup Sun JDK 1.6 for AOSP build before L
aptitude -y install openjdk-7-jdk sun-java6-jdk

# setup web server for monitor if need
aptitude -y install nginx php5-fpm ganglia-monitor gmetad ganglia-webfrontend

# setup debug tool
aptitude -y install minicom valgrind 

# setup lightweight window manager with remote desktop
add-apt-repository ppa:x2go/stable
apt-get update
aptitude -y install openbox icewm blackbox tightvncserver \
x2goserver x2goserver-xsession x2goclient wmii2 dwm wmctrl xfce4

svn co $SVN_OPTION -q $SVN_SRV/tools/tools /local/tools
export RUN_PATH=/local/tools/setup

# just for remove email server
# aptitude -y purge nbSMTP exim4 exim4-base exim4-daemon-light

ln -sf /usr/lib/jvm/java-6-sun /usr/local/jdk1.6
ln -s /usr/bin/fromdos /usr/local/bin/dos2unix

ln -sf /usr/lib/jvm/java-7-openjdk-amd64 /usr/local/jdk1.7
ln -sf /usr/local/jdk1.6 /usr/local/jdk

echo "
export PATH=/usr/local/jdk/bin:\$PATH:
export CLASSPATH=/usr/local/jdk/lib:.
export JAVA_HOME=/usr/local/jdk
export USE_CCACHE=1
export CCACHE_UMASK=0000
export CCACHE_DIR=/local/ccache
export CCACHE_BASEDIR=/media
# export CPU_NUM=$CPU_NUM
# export IP=$IP
# alias repo=$REPO
alias vi=vim
alias h=htop
alias screen='screen -R -DD'
alias ccache=/usr/bin/ccache
export VISUAL=vim
" >>/etc/bash.ibuild.bashrc

if [[ ! `grep ibuild /etc/bash.bashrc` ]] ; then
	echo ". /etc/bash.ibuild.bashrc" >>/etc/bash.bashrc
fi

. /etc/bash.ibuild.bashrc
ccache -M 50G

# for svn server
mkdir -p /local/svn.srv
svnadmin create /local/svn.srv/ibuild
svnserve -d -r /local/svn.srv/ibuild

echo '
Our suggestion:
Disable HT(Hyper-Threading) in BIOS
run "lshw -c disk" check your disk
Setup Ubuntu 14.04 x86_64 / in HDD 50G with ext4
Setup 4G swap
Setup /home in HDD with free space btrfs
Setup /local in SSD with whole space ext4
Shared /home/ref_repo
Use your workspace in /home/$USER/My...
Shared /local/ccache
Link out to your /local/$USER/out
change SSD_DISK queue and scheduler (option)
	echo noop > /sys/block/SSD_DISK/queue/scheduler
add TRIM in crontab for SSD_DISK
	fstrim -v /local
add discard,noatime in fstab when use ext4
'

