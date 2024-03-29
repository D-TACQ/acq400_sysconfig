#!/bin/bash

if [[ $# -lt 2 ]] ; then
    echo "Enter Carrier followed by Mezzanine"
    echo "	e.g. acq1001_079 acq420 [site1 site2 siteN]"
    echo "	e.g. acq2106_126 acq424 1 2 3 4 5"
    echo "	e.g. acq2106_126 WR acq424 1 2 3 4 5"
    echo "	e.g. acq2106_126 WR acq435 1 3 5"
    echo "FOR DRYRUN run DRYRUN=1 ./deploy_sysconfig xxxx and examine ./STAGING"
    echo "FOR ACQ1014 run ACQ1014=1 ./deploy_sysconfig acq1001_LEFT acq480 .. assumes acq1001_RIGHT is +1"
    echo "FOR custom sample rate run SR=80000 ./deploy_sysconfig acq2106_269 WR acq435 1 3 5"
    echo "... nb if NOT DRYRUN, ACQ1014 will autodetect"
    echo "NB: does NOT handle mixed sites, go with the site1 module type, omit sites with other modules"
    exit 0
fi

#incant="$0 $*"
host=$1
carr=${host:3:4}

debug=${DRYRUN:-0}
custom_sr=${SR:-0}

if [[ $custom_sr -ne 0 ]]; then
	incant="SR=$custom_sr $0 $*"
else
	incant="$0 $*"
fi

ACQ1014=${ACQ1014:-0}

if [ $debug == 0 ]; then
	ssh root@$host grep devicetree_image /tmp/u-boot_env | grep -q 1014
        if [ $? -eq 0 ]; then
		echo "ACQ1014 auto-detected"
		ACQ1014=1
	fi
fi
if [ $ACQ1014 == 1 ]; then
	host2=${host: -3};host2=$((host2+1));host2=(${host: 0:8}$host2)
	echo ACQ1014 $host host2 configured $host2
fi

if [[ x$2 == xWR* ]]; then
	wrclk=${2#*=}
	if [ $wrclk != $2 ]; then
		WR=$wrclk
	else
		WR=40M
	fi
	echo White Rabbit System.. clocks at 40MHz for 25nsec tick. Actual clock $WR
	mezz=$3
	shift
	if [[ x$mezz = xtest ]]; then
		echo "TEST module selected"
	elif [[ x$mezz != xacq48* ]]; then
		echo WARNING: WR clock rate valid acq48x only, check wr.sh TICKNS
	fi
else
	mezz=$2
fi
shift;shift
sites="${*:-1}"
SITELIST="$(echo $sites | tr \  ,)"
sitecount=$(echo -n $sites | tr -d \  | wc -c)


if [ ! -z "$(git status --porcelain)" ]; then
	echo -e "\e[91mWARNING: git is not clean, make it a DRYRUN\e[0m"
	debug=1
fi

echo "CLEANUP rm STAGING"
rm -Rf STAGING STAGING2
mkdir -p STAGING/mnt/local/cal
echo STAGING is a place to build a local copy of the remote image

get_nchan() {
	mz=$1
	nc=${mz#*-}
	if [ $mz == $nc ]; then

		case $mz in
		acq420) nc=4;;
		ao420) nc=4;;
		acq424) nc=32;;
		ao424) nc=32;;
		ao424-16) nc=16;;
		acq423) nc=32;;
		acq425) nc=16;;
		acq425-18) nc=16;;
		acq427) nc=8;;
		acq430)	nc=8;;
		acq435) nc=32;;
		acq435-16) nc=16;;
		acq436) nc=24;;
                acq437) nc=16;;
		acq480) nc=8;;
		bolo8)	nc=24;;
                dio432) nc=1;;
 		dio482td) nc=6;;
		test)   nc=1;;
		*)	echo ERROR: unknown module; exit 1;;
		esac
	fi
	echo $nc
}

get_sr() {
	mz=$1
	sr=1000000

	case $mz in
	acq420|acq425|acq425-18|acq427)
		if [ $debug == 0 ]; then
			ssh root@$host '/usr/local/bin/get.site 1 PART_NUM' | grep -q M=A
     			[ $? -eq 0 ] && sr=2000000
		fi;;
	acq423) 				sr=200000	  ;;
	acq424) 						  ;;
	ao424) 						sr=500000;;
	acq430|acq435|acq435-16|acq436|acq437)
		if [ "x$WR" != "x" ]; then
			sr=40000
		else
			sr=43500
		fi;;
	acq480|acq482) 				sr=${WR:-20000000};;
	*)
		echo >&2  "WARNING: get_sr() mz $mz not specified return default $sr";;
	esac
	echo $sr
}

die()
{
	echo ERROR $*
	exit 1
}

set_long_buffers() {
        echo DEBUG set_long_buffers to comp slow pl330 setup
	[ ! -e STAGING/mnt/local/sysconfig/acq400.sh ] && die "SEQUENCE ERROR"
	cat - >>STAGING/mnt/local/sysconfig/acq400.sh <<EOF
BLEN=4194304
NBUF=128
EOF
}
MODNAME=${mezz%-*}
nchan=$(get_nchan $mezz)
if [[ $custom_sr -ne 0 ]]; then
	samp_rate=$custom_sr
else
	samp_rate=$(get_sr $mezz)
fi
echo "DEBUG SR $samp_rate"
let NCHAN=$nchan*$sitecount
echo "DEBUG host $host mezz $mezz $sites MODNAME $MODNAME SITELIST:$SITELIST sitecount:$sitecount NCHAN $NCHAN"

# set some defaults in STAGING. Maybe they get overwritten
cp -r sysconfig STAGING/mnt/local

cp acq400_sh_default STAGING/mnt/local/sysconfig/acq400.sh

trans_file="none"

case $mezz in
"acq423")
 [ $NCHAN -ge 128 ] && set_long_buffers
 trans_file="acq42X_transient.init" ;;
"acq420"|"acq427")
  trans_file="acq42X_transient.init" ;;
"acq425"|"acq424")
  trans_file="acq42X_transient.init"
  [ $sitecount -ge 4 ] && cp acq400_sh_AXI_DMA_BUFFERS STAGING/mnt/local/sysconfig/acq400.sh
  [ $sitecount -ge 2 ] && set_long_buffers
  ;;
"acq425-18")
  trans_file="acq43X_transient.init"
  [ $sitecount -gt 2 ] && cp acq400_sh_AXI_DMA_BUFFERS STAGING/mnt/local/sysconfig/acq400.sh
  ;;
"acq430")
  trans_file="acq43X_transient.init"
  cp acq430_epics.sh STAGING/mnt/local/sysconfig/epics.sh
  cp acq430_acq420_custom STAGING/mnt/local/acq420_custom
  ;;
"acq435"|"acq436"|"acq437")
  [ $NCHAN -gt 144 ] && set_long_buffers
  trans_file="acq43X_transient.init" ;;
"acq435-16")
  trans_file="acq435-16_transient.init" ;;
"acq480")
	trans_file="acq480_transient.init"
       	#cp acq480_rc.user STAGING/mnt/local/rc.user
	cp acq400_sh_AXI_DMA_BUFFERS STAGING/mnt/local/sysconfig/acq400.sh
	if [[ $host =~ "acq1001" ]]; then
		cp acq1001_acq480_bos.sh STAGING/mnt/local/sysconfig/bos.sh
		cp acq1001_acq480_acq420_custom STAGING/mnt/local/acq420_custom
		if [ $ACQ1014 == 1 ]; then
                	echo +++ acq1014 found
            		cp acq480_1014_rc.user STAGING/mnt/local/rc.user
			mkdir STAGING2
			cp -r STAGING/* STAGING2
			# mirror on MASTER only
			sed -e "s/%MIRROR_HOST%/$host2/g" acq1014_epics_mirror_def > STAGING/mnt/local/sysconfig/epics.sh
		fi
        fi
  ;;
"bolo8")
  trans_file="bolo8_transient.init"
  cp bolo8/bolo8_rc.user STAGING/mnt/local/rc.user
  cp bolo8/postshot STAGING/mnt/local/
  cp bolo8/get.xdt STAGING/mnt/local/
  cp bolo8/bolo.sh STAGING/mnt/local/sysconfig/
  cp bolo8/acq400.sh STAGING/mnt/local/sysconfig/
  ;;
"dio432")
  trans_file="acq43X_transient.init"
  cp dio432_rc.user STAGING/mnt/local/rc.user
  cp DO_acq420_custom STAGING/mnt/local/acq420_custom
  ;;
"ao420"|"ao424")
  trans_file="ao/ao42X_transient.init"
  cp ao/AO_acq420_custom STAGING/mnt/local/acq420_custom
  ;;
"ao424-16")
  trans_file="ao/ao42X_transient_odd_chan.init"
  cp ao/AO_acq420_custom STAGING/mnt/local/acq420_custom
  ;;
"dio482td")
 echo "dio482td .. do nothing";;
"test")
  echo "test .. do nothing";;
*)
  echo -e "\nInvalid mezzanine specified!!!\n"
  echo -e "acq420\nacq425\n2xacq425\nacq424\n2xacq424\nacq430\nacq435\nbolo8\n"
  exit 0
  ;;
esac

echo PGMWASHERE $carr $sitecount
if [ "$carr" = "2106" ] && [ $sitecount -gt 3 ]; then
	echo "carrier:$carr sitecount:$sitecount FANSPEED=100"
	echo "FANSPEED=100" >> STAGING/mnt/local/sysconfig/acq400.sh
elif [ "$carr" = "1001" ] && [ $sitecount -gt 1 ]; then
	echo "carrier:$carr sitecount:$sitecount FANSPEED=100"
	echo "FANSPEED=100" >> STAGING/mnt/local/sysconfig/acq400.sh
fi


if [ "x$WR" != "x" ]; then
	echo "STUBBED WHITE_RABBIT=1 .. should be automatic dep on FPGA personality"
#	echo "WHITE_RABBIT=1" >> STAGING/mnt/local/sysconfig/acq400.sh
	echo "enable ETH1_E1000X=y FLARE todo: make /mnt/local/network for eth1"
	echo "ETH1_E1000X=y" >> STAGING/mnt/local/sysconfig/acq400.sh
fi

echo "DEBUG trans_file $trans_file MODNAME $MODNAME"
if [ ! -e ${MODNAME}_transient.init ]; then
	echo "DEBUG : ${MODNAME}_transient.init not found .. will use default"
fi

###
# If there is a custom peers file for a module copy it, otherwise copy default
###
if [ -e ${MODNAME}-site-1-peers ]; then
	PEERS=${MODNAME}-site-1-peers
else
	PEERS=default-site-1-peers
fi

###
# Sed into the transient (and peers) files and insert CH count and run0 incantation
###

if [ "x$trans_file" != "xnone" ]; then
   NSAMPLES=100000
   sed -e "s/%NCHAN%/$NCHAN/g" -e "s/%SITELIST%/$SITELIST/g" -e "s/%NSAMPLES%/$NSAMPLES/g" \
	$trans_file >STAGING/mnt/local/sysconfig/transient.init
   [ -e STAGING2 ] && cp STAGING/mnt/local/sysconfig/transient.init STAGING2/mnt/local/sysconfig/transient.init

   sed -e "s/%SITELIST%/$SITELIST/g" $PEERS >STAGING/mnt/local/sysconfig/site-1-peers
fi

###
# if no custom rc.user, sed into the template rc.user file to generate board specific clocking
###

setp=1000000

if [[ $host =~ "kmcu" ]]; then
	echo WORKTODO : kmcu does NOT mess with rc.user, make your own
	rm STAGING/mnt/local/rc.user
elif [ ! -e STAGING/mnt/local/rc.user ]; then
	if [[ $mezz =~ "acq43" ]]; then
		acq_sub="acq43x"
		setp=$samp_rate
	elif [[ $mezz =~ "acq42" ]]; then
		acq_sub="acq42x"
		setp=$samp_rate
	elif [[ $mezz =~ "ao42" ]]; then
		acq_sub="acq42x"
		setp=$samp_rate
	elif [[ $mezz =~ "acq48" ]]; then
		acq_sub="acq480"
		setp=$samp_rate
	fi
	if [ $carr == "2106" ]; then
		setp=$samp_rate
	fi
	if [ -z $setp ]; then
		echo "DEBUG HELPME setp not set"
	fi
	echo "DEBUG acq_sub $acq_sub setp $setp"
	(
	if [ "x$WR" != "x" ] && [ "x$FLARE" = "x1" ]; then
		echo "# FLARE additions, please be sure to enable packages"
		echo '# 35-gpg* '
		echo '# 99-flare* '
	else
		sed -e "s/%MEZZ%/$mezz/g" -e "s/%STR_SR%/$samp_rate/g" -e "s/%CARRIER%/$carr/g" \
			-e "s/%ACQSUB%/$acq_sub/g" -e "s/%SETPOINT%/$setp/g" \
			template_rc.user

		if [ "x$WR" != "x" ]; then
			#: # no op
			### DEPRECATED. WR CLOCK SETUP HAS BEEN MOVED TO SYNC_ROLE ###
			#echo "# WR additions for WRCLK $WR"
			#echo "/usr/local/CARE/WR/set_clk_WR $WR"
			### ADD Tune in by default
			echo -e "\n# Tune WR clock phase"
			echo -e "set.site 11 si5326_tune_phase 1\n"
		fi
	fi
	) > STAGING/mnt/local/rc.user
else
	echo "DEBUG using custom rc.user"
fi
[ "x$WR" != "x" ] && cp -r WR/local/* STAGING/mnt/local

staging=STAGING
[ -e STAGING2 ] && staging="$staging STAGING2"

mkdir -p ARCHIVE
uut=$host
for st in $staging; do
	githash=$(git rev-parse HEAD)
	user="${USER}@$(hostname)"
        sed -i -e "2i#\n# created by deploy_sysconfig for uut:$uut mezz:$mezz\n# by ${user} on $(date)\n# git $githash\n# incant $incant\n" $st/mnt/local/rc.user
	tar cvf ARCHIVE/$uut.tar -C $st .
	echo "INFO ARCHIVE/$uut.tar created"
	uut=$host2
done


###
# Copy files to UUT
###
if [ $debug == 0 ]; then
	if [ ! -z "$(git status --porcelain)" ]; then
		echo -e "\e[31mERROR: git is not clean fix it please\e[0m"
		exit 1
	fi
	cat ARCHIVE/$host.tar | ssh root@$host 'tar xvf - -C /'
	[ "x$host2" != "x" ] && (cat ARCHIVE/$host2.tar | ssh root@$host2 'tar xvf - -C /')

else
	echo -e "\e[91mdebug mode no deploy. Look in ./STAGING for details\e[0m"
fi

