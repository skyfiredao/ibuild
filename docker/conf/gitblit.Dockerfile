FROM phusion/baseimage:0.9.16
MAINTAINER Ding Wei, daviding924

# setup openssh server and Restricted Shell
RUN apt-get update -qq \
&& apt-get install -y rssh openssh-server openjdk-7-jdk git git-core subversion

# create account for sshfs disable password login and use Restricted Shell for sshfs only
RUN addgroup --gid 1000 --system ibuild \
&& adduser --system --shell /usr/bin/git-shell --disabled-password --uid 1000 --ingroup ibuild --home /local/srv/gitblit gitblit

