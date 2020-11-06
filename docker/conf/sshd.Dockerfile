FROM phusion/baseimage:18.04-1.0.0
MAINTAINER Ding Wei, daviding924

# setup openssh server and Restricted Shell
RUN apt-get update -qq && apt-get install -y rssh
RUN rm -f /etc/service/sshd/down && /etc/my_init.d/00_regen_ssh_host_keys.sh

# create account for sshfs disable password login and use Restricted Shell for sshfs only
RUN addgroup --gid 1000 --system ibuild \
&& adduser --system --shell /usr/bin/rssh --disabled-password --uid 1000 --ingroup ibuild --home /local/ref_repo sshfs

# Restricted Shell enable sftp only
RUN echo "allowsftp" >> /etc/rssh.conf

