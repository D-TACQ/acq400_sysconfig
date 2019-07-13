#!/bin/sh

if [[ $# -lt 2 ]] ; then
    echo -e '\n Enter Carrier followed by Mezzanine\n e.g. acq1001_079 acq420 [site1 site2 siteN]\n'
    echo -e '\n FOR ACQ1014 run ACQ1014=1 ./deploy_sysconfig acq1001_LEFT acq480 .. assumes acq1001_RIGHT is +1\n'
    echo -e '\n FOR DRYRUN run DRYRUN=1 ./deploy_sysconfig xxxx and examine ./STAGING\n'
    exit 0
fi

host=$1
carr=${host:3:4}

ACQ1014=${ACQ1014:-0}
if [ $ACQ1014 == 1 ]; then
	host2=${host: -3};host2=$((host2+1));host2=(${host: 0:8}$host2)
	echo ACQ1014 $host host2 configured $host2
fi
mezz=$2
shift;shift
sites="${*:-1}"
SITELIST="$(echo $sites | tr \  ,)"
sitecount=$(echo -n $sites | tr -d \  | wc -c)
debug=${DRYRUN:-0}


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
		acq424) nc=32;;
		acq423) nc=32;;
		acq425) nc=16;;
		acq425-18) nc=16;;
		acq427) nc=8;;
		acq430)	nc=8;;
		acq435) nc=32;;
		acq435-16) nc=32;;
                acq437) nc=16;;
		acq480) nc=8;;
		bolo8)	nc=8;;
                dio432) nc=1;;
		*)	echo ERROR: unknown module; exit 1;;
		esac
	fi
	echo $nc
}

get_sr() {
	mz=$1
	case $mz in
	acq420|acq425|acq427)
		ssh root@$host '/usr/local/bin/get.site 1 PART_NUM' | grep -q M=A
     		if [ $? -eq 0 ]; then
			sr=2000000
		else
			sr=1000000
		fi
	;;
	acq423)
		sr=200000
	;;
	acq424)
		sr=1000000
	;;
	acq430|acq435|acq437)
		sr=43500
	;;
	acq480|acq482)
		sr=10000000
	;;
	*)
		exit 0
	;;
	esac
	echo $sr
}

MODNAME=${mezz%-*}
nchan=$(get_nchan $mezz)
samp_rate=$(get_sr $mezz)
echo "DEBUG SR $samp_rate"
let NCHAN=$nchan*$sitecount
echo "DEBUG host $host mezz $mezz $sites SITELIST:$SITELIST sitecount:$sitecount NCHAN $NCHAN"

# set some defaults in STAGING. Maybe they get overwritten
cp -r sysconfig STAGING/mnt/local


case $mezz in
"acq420"|"acq423"|"acq427")
  trans_file="acq42X_transient.init"
  ;;
"acq425"|"acq424")
  trans_file="acq42X_transient.init"
  [ $sitecount -gt 2 ] && cp acq42X_AXI_DMA_BUFFERS root@$host:/mnt/local/sysconfig/acq400.sh
  ;;
"acq425-18")
  trans_file="acq43X_transient.init"
  [ $sitecount -gt 2 ] && cp acq42X_AXI_DMA_BUFFERS root@$host:/mnt/local/sysconfig/acq400.sh
  ;;
"acq430")
  trans_file="acq43X_transient.init"
  cp acq430_epics.sh STAGING/mnt/local/sysconfig/epics.sh
  cp acq430_acq420_custom STAGING/mnt/local/acq420_custom
  ;;
"acq435"|"acq437")
  trans_file="acq43X_transient.init"
  ;;
"acq435-16")
  trans_file="acq435-16_transient.init"
  ;;
"acq480")
     trans_file="acq480_transient.init"
     if [ $debug == 0 ] ; then
          if [[ $host =~ "acq1001" ]]; then
               ssh root@$host grep devicetree_image /tmp/u-boot_env | grep -q 1014
               if [ $? -eq 0 ]; then
                    echo +++ acq1014 found
                    echo -e "\e[34mCopying config files to both $host and $host2"; tput sgr0
                    sed -e "s/%MAST_HOST%/$host2/g" acq1014_epics_mirror_def > acq1014_epics_mirror
		    mkdir STAGING STAGING2
		    for st in STAGING STAGING2; do
	            	cp acq480_1014_rc.user ${st}/mnt/local/rc.user
                    	cp acq1014_epics_mirror ${st}/mnt/local/sysconfig/epics.sh
                    	cp acq1001_acq480_bos.sh ${st}/mnt/local/sysconfig/bos.sh
                    	cp acq1001_acq480_acq420_custom ${st}/mnt/local/acq420_custom
		    done
               else
                    #cp acq480_1001_rc.user STAGING/mnt/local/rc.user
                    cp acq480_rc.user STAGING/mnt/local/rc.user
                    cp acq1001_acq480_bos.sh STAGING/mnt/local/sysconfig/bos.sh
                    cp acq1001_acq480_acq420_custom STAGING/mnt/local/acq420_custom
               fi
          else
               cp acq480_rc.user STAGING/mnt/local/rc.user
          fi
     fi
  ;;
"bolo8")
  trans_file="bolo8_transient.init"
  ;;
"dio432")
  custom_rc=1
  trans_file="acq43X_transient.init"
  cp dio432_rc.user STAGING/mnt/local/rc.user
  cp DO_acq420_custom STAGING/mnt/local/acq420_custom
  ;;
*)
  echo -e "\nInvalid mezzanine specified!!!\n"
  echo -e "acq420\nacq425\n2xacq425\nacq424\n2xacq424\nacq430\nacq435\nbolo8\n"
  exit 0
  ;;
esac

echo "DEBUG trans_file $trans_file MODNAME $MODNAME"
if [ ! -e ${MODNAME}_transient.init ]; then
	echo "Warning : ${MODNAME}_transient.init not found .. but that is probably OK"
	#exit 1
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
sed -e "s/%NCHAN%/$NCHAN/g" -e "s/%SITELIST%/$SITELIST/g" \
	$trans_file >transient.init
sed -e "s/%SITELIST%/$SITELIST/g" $PEERS >site-1-peers

###
# if no custom rc.user, sed into the template rc.user file to generate board specific clocking
###

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
	sed -e "s/%MEZZ%/$mezz/g" -e "s/%STR_SR%/$samp_rate/g" -e "s/%CARRIER%/$carr/g" \
		-e "s/%ACQSUB%/$acq_sub/g" -e "s/%SETPOINT%/$setp/g" \
		template_rc.user > STAGING/mnt/local/rc.user
else
	echo "DEBUG using custom rc.user"
fi

staging=STAGING
[ -e STAGING2 ] && staging="$staging STAGING2"

mkdir -p ARCHIVE
uut=$host
for st in $staging; do
        sed -i -e "2i#\n# created by deploy_sysconfig for uut:$uut mezz:$mezz\n# by ${USER}@$(hostname) on $(date)\n" $st/mnt/local/rc.user
	cp transient.init site-1-peers $st/mnt/local/sysconfig
	tar cvf ARCHIVE/$uut.tar -C $st .
	echo "INFO ARCHIVE/$uut.tar created"
	uut=$host2
done
rm transient.init site-1-peers


###
# Copy files to UUT
###
if [ $debug == 0 ]; then
	cat ARCHIVE/$host.tar | ssh root@$host 'tar xvf - -C /'
	[ "x$host2" != "x" ] && (cat ARCHIVE/$host2.tar | ssh root@$host2 'tar xvf - -C /')
else
	echo debug mode no deploy. Look in ./STAGING for details
fi

