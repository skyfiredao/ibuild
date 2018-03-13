rm -fr *.mod.c *.ko *.o .*.cmd Module.symvers modules.order .tmp_versions

make -C /lib/modules/$(uname -r)/build SUBDIRS=$PWD modules

rm -fr *.mod.c *.o .*.cmd Module.symvers modules.order .tmp_versions

