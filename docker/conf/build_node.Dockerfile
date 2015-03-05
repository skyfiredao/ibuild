FROM ubuntu
# phusion/baseimage:0.9.16
MAINTAINER Ding Wei

RUN apt-get update
RUN apt-get -y install subversion curl wget git

RUN apt-get install -q -y openjdk-7-jdk
RUN apt-get install -q -y bison g++-multilib git gperf libxml2-utils
RUN apt-get install -q -y zip unzip make maven2
RUN apt-get clean

# NODE_USER=builder
RUN groupadd -g USER_GID builder
RUN useradd -r -m -s /bin/bash -u USER_UID -G sudo,builder -g builder builder
RUN passwd -d builder
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir -p /home/builder/.ssh
RUN chmod 700 -R /home/builder/.ssh
RUN echo 'export USE_CCACHE=1' >> /home/builder/.bashrc
RUN echo 'export CCACHE_DIR=/local/ccache' >> /home/builder/.bashrc
RUN echo 'export PATH=~/bin:$PATH' >> /home/builder/.bashrc

VOLUME /local

