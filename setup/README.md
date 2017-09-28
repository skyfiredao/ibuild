setup tools
======

#### check_env.sh
stand-alone tool, check build environment non-standard config

#### ibuild_node_daemon.sh
non-stand-alone tool, build node deamon listen ibuild maseter send job

#### ibuild_node_monitor.sh
stand-alone tool, monitor ccache status, out and ccache disk space and CPU, display card temperature

#### ibuild_node_reg.sh
stand-alone tool, every 5 or 10min run in all of ibuild node for update node info, sync local ref_repo, auto cleanup and auto reboot

#### reboot.sh
stand-alone tool, reboot node after check count

#### setup_ubuntu_build_env.sh
stand-alone tool, init setup ibuild node after install ubuntu basic OS
install ubuntu follow those info:
60M        efi   boot partition
20G        ext4  /
4G         swap
others     btrfs /local
add proxy if need
apt-get install aptitude screen vim openssh-server git subversion
aptitude update
aptitude full-upgrade
add authorized_keys in ~/.ssh
cp id_rsa and id_rsa.pub to ~/.ssh
cp .ssh/config ~/.ssh
cp .gitconfig ~/
sudo chown ibuild.ibuild /local
svn checkout ibuild in /local
sudo su
ln -sf /local/ibuild ~/ibuild
bash /local/ibuild/ibuild_node_reg.sh

#### setup_srv_svn.sh
stand-alone tool, init setup ibuild subversion server based on https://github.com/daviding924/ibuild

#### sync_node_setup.sh
stand-alone tool, setup ibuild node local ref_repo for build after standard ubuntu setup

#### sync_local_ref_repo.sh
stand-alone tool, sync local mirror in ibuild node

#### BIOS setup
ASUS -> Advanced -> Restore AC Power loss -> Last state
                    Power on By PCI-E/PCI -> Enable
DELL -> Power Management -> AC Recovery -> Power on -> Last Power State
                            Deep Sleep Control -> Disable
                            Wake on LAN/WAN -> LAN Only
                            Block Sleep -> Block Sleep (S3 State)
HP -> Advanced -> Power On Options -> After Power Loss -> Previons State
                                      REmote Wakeup Boot Source -> Remote Server


