    wr changes final, appends setup to /mnt/local/rc.user
    additional syntax
    ./deploy_sysconfig.sh acq2106_182 WR acq480 1 2 3 4 5 6
    ./deploy_sysconfig.sh acq2106_182 WR=40M acq480 1 2 3 4 5 6
    
    ... 40M is the DEFAULT, any other value will need a patch to WRTD_TICKNS in
    ./WR/local/sysconfig/wr.sh

