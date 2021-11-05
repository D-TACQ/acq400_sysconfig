# acq400_sysconfig
creates default sysconfig settings for given ACQ400 configuration

# Archive is a set of TEMPLATE files. ALWAYS use deploy_sysconfig to deploy to the UUT
```bash
[dt100@eigg-fs SYSCONFIG]$ ./deploy_sysconfig.sh 
Enter Carrier followed by Mezzanine
	e.g. acq1001_079 acq420 [site1 site2 siteN]
	e.g. acq2106_126 acq424 1 2 3 4 5
	e.g. acq2106_126 WR acq424 1 2 3 4 5
	e.g. acq2106_126 WR acq435 1 3 5
FOR DRYRUN run DRYRUN=1 ./deploy_sysconfig xxxx and examine ./STAGING
FOR ACQ1014 run ACQ1014=1 ./deploy_sysconfig acq1001_LEFT acq480 .. assumes acq1001_RIGHT is +1
FOR custom sample rate run SR=80000 ./deploy_sysconfig acq2106_269 WR acq435 1 3 5
... nb if NOT DRYRUN, ACQ1014 will autodetect
NB: does NOT handle mixed sites, go with the site1 module type, omit sites with other modules
````
# EXAMPLE

```bash
[dt100@eigg-fs SYSCONFIG]$ ./deploy_sysconfig.sh acq2106_999 WR acq424 1 2 3 4 5 6
ssh: Could not resolve hostname acq2106_999: Name or service not known
White Rabbit System.. clocks at 40MHz for 25nsec tick. Actual clock 40M
WARNING: WR clock rate valid acq48x only, check wr.sh TICKNS
CLEANUP rm STAGING
STAGING is a place to build a local copy of the remote image
DEBUG SR 1000000
DEBUG host acq2106_999 mezz acq424 1 2 3 4 5 6 MODNAME acq424 SITELIST:1,2,3,4,5,6 sitecount:6 NCHAN 192
DEBUG set_long_buffers to comp slow pl330 setup
PGMWASHERE 2106 6
carrier:2106 sitecount:6 FANSPEED=100
STUBBED WHITE_RABBIT=1 .. should be automatic dep on FPGA personality
enable ETH1_E1000X=y FLARE todo: make /mnt/local/network for eth1
DEBUG trans_file acq42X_transient.init MODNAME acq424
DEBUG : acq424_transient.init not found .. will use default
DEBUG acq_sub acq42x setp 1000000
./
./mnt/
./mnt/local/
./mnt/local/cal/
./mnt/local/sysconfig/
./mnt/local/sysconfig/bos.sh
./mnt/local/sysconfig/epics.sh
./mnt/local/sysconfig/acq400.sh
./mnt/local/sysconfig/transient.init
./mnt/local/sysconfig/site-1-peers
./mnt/local/sysconfig/wr.sh
./mnt/local/rc.user
./mnt/local/wr_cal
./mnt/local/wrc.le.bin
INFO ARCHIVE/acq2106_999.tar created
```

 # the files are then deployed to uut, eg acq2106_999


 # example of created deployable file..
```bash

[dt100@eigg-fs SYSCONFIG]$ find . -name transient.init
./STAGING/mnt/local/sysconfig/transient.init
[dt100@eigg-fs SYSCONFIG]$ cat ./STAGING/mnt/local/sysconfig/transient.init

# NSAMPLES sets EPICS transient WF length
# next line: expect condition to stay this boot
COOKED=0 NSAMPLES=100000 NCHAN=192 TYPE=SHORT

# set a default transient. expect this to change at run time
transient PRE=2000 POST=2000 OSAM=1 DEMUX=1 SOFT_TRIGGER=1

# configure soft trigger on site 1 - typical default
set.site 1 trg=1,1,1
```


# set sites in aggregator set
run0 1,2,3,4,5,6

