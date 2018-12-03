#!/bin/sh

if [[ $# -lt 2 ]] ; then
    echo -e '\n Enter Carrier followed by Mezzanine\n e.g. acq1001_079 acq420 [site1 site2 siteN]\n'
    exit 0
fi

host=$1
carr=${host:3:4}
echo $carr
# For use in 1014 systems
#host2=${host: -3};host2=$((host2+1));host2=(${host: 0:8}$host2)
mezz=$2
shift;shift
sites="${*:-1}"
SITELIST="$(echo $sites | tr \  ,)"
sitecount=$(echo -n $sites | tr -d \  | wc -c)
custom_flag=0
if [[ $host =~ "kmcu" ]]; then
	custom_rc=1
else
	custom_rc=0
fi
debug=0


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
	acq435|acq437)
		sr=43500
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
echo $samp_rate
let NCHAN=$nchan*$sitecount
echo $host $mezz $sites SITELIST:$SITELIST sitecount:$sitecount NCHAN $NCHAN

if [ $debug == 0 ]; then scp -r sysconfig root@$host:/mnt/local/;fi

case $mezz in
"acq420"|"acq423"|"acq427")
  trans_file="acq42X_transient.init"
  ;;
"acq425"|"acq424")
  trans_file="acq42X_transient.init"
  custom_flag=1
  ;;
"acq425-18")
  trans_file="acq43X_transient.init"
  custom_flag=1
  ;;
"acq430")
  trans_file="acq43X_transient.init"
  scp acq430_epics.sh root@$host:/mnt/local/sysconfig/epics.sh
  scp acq430_acq420_custom root@$host:/mnt/local/acq420_custom
  ;;
"acq435"|"acq437")
  trans_file="acq43X_transient.init"
  ;;
"acq435-16")
  trans_file="acq435-16_transient.init"
  ;;
"acq480")
     trans_file="acq480_transient.init"
     custom_rc=1
     if [ $debug == 0 ] ; then
          if [[ $host =~ "acq1001" ]]; then
               ssh root@$host grep devicetree_image /tmp/u-boot_env | grep -q 1014
               if [ $? -eq 0 ]; then
                    echo +++ acq1014 found
                    echo -e "\e[34mCopying config files to both $host and $host2"; tput sgr0
                    sed -e "s/%MAST_HOST%/$host2/g" acq1014_epics_mirror_def > acq1014_epics_mirror
                    scp acq480_1014_rc.user root@$host:/mnt/local/rc.user
                    scp acq480_1014_rc.user root@$host2:/mnt/local/rc.user
                    scp acq1014_epics_mirror root@$host:/mnt/local/sysconfig/epics.sh
                    scp acq1014_epics_mirror_slave root@$host2:/mnt/local/sysconfig/epics.sh
                    scp acq1001_acq480_bos.sh root@$host:/mnt/local/sysconfig/bos.sh
                    scp acq1001_acq480_bos.sh root@$host2:/mnt/local/sysconfig/bos.sh
                    scp acq1001_acq480_acq420_custom root@$host:/mnt/local/acq420_custom
                    scp acq1001_acq480_acq420_custom root@$host2:/mnt/local/acq420_custom
               else
                    scp acq480_1001_rc.user root@$host:/mnt/local/rc.user
                    scp acq1001_acq480_bos.sh root@$host:/mnt/local/sysconfig/bos.sh
                    scp acq1001_acq480_acq420_custom root@$host:/mnt/local/acq420_custom
               fi
          else
               scp acq480_rc.user root@$host:/mnt/local/rc.user
          fi
     fi
  ;;
"bolo8")
  trans_file="bolo8_transient.init"
  ;;
"dio432")
  trans_file="acq43X_transient.init"
  custom_rc=1
  scp dio432_rc.user root@$host:/mnt/local/rc.user
  ;;
*)
  echo -e "\nInvalid mezzanine specified!!!\n"
  echo -e "acq420\nacq425\n2xacq425\nacq424\n2xacq424\nacq430\nacq435\nbolo8\n"
  exit 0
  ;;
esac

echo $trans_file
echo $MODNAME
if [ ! -e ${MODNAME}_transient.init ]; then
	echo Warning : ${MODNAME}_transient.init not found
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
# Sed into the template rc.user file to generate board specific clocking
###
if [ $custom_rc == 0 ]; then
	if [[ $mezz =~ "acq43" ]]; then
		acq_sub="acq43x"
		setp=$samp_rate
	elif [[ $mezz =~ "acq42" ]]; then
		acq_sub="acq42x"
		if [[ $mezz =~ "acq423" ]]; then
			setp=200000
		else
			setp=1000000
		fi
		echo $setp_sub
	elif [[ $mezz =~ "acq48" ]]; then
		acq_sub="acq480"
	fi
	echo $acq_sub
	if [ $carr == "2106" ]; then
		setp=$samp_rate
	fi
	sed -e "s/%MEZZ%/$mezz/g" -e "s/%STR_SR%/$samp_rate/g" -e "s/%CARRIER%/$carr/g" \
		-e "s/%ACQSUB%/$acq_sub/g" -e "s/%SETPOINT%/$setp/g" \
		template_rc.user > rc.user
fi


###
# Copy files to UUT
###
if [ $debug == 0 ] ; then
	scp transient.init site-1-peers root@$host:/mnt/local/sysconfig
	if [ $custom_flag == 1 ]; then # Custom AXI buffers length
	   scp acq42X_AXI_DMA_BUFFERS root@$host:/mnt/local/sysconfig/acq400.sh
	fi
	if [ $custom_rc == 0 ]; then
	   scp rc.user root@$host:/mnt/local/rc.user
	fi
fi
