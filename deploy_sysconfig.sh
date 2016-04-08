#!/bin/sh

if [[ $# -lt 2 ]] ; then
    echo -e '\n Enter Carrier followed by Mezzanine\n e.g. acq1001_079 acq420 [site1 site2 siteN]\n'
    exit 0
fi

host=$1
mezz=$2
shift;shift
sites="${*:-1}"
SITELIST="$(echo $sites | tr \  ,)"
sitecount=$(echo -n $sites | tr -d \  | wc -c)


get_nchan() {
	mz=$1
	nc=${mz#*-}
	if [ $mz == $nc ]; then
		
		case $mz in 
		acq420) nc=4;;
		acq424) nc=32;;
		acq425) nc=16;;
		acq430)	nc=8;;
		acq435) nc=32;;
		acq480) nc=8;;
		bolo8)	nc=8;;
		*)	echo ERROR: unknown module; exit 1;;
		esac
	fi
	echo $nc	 
}

MODNAME=${mezz%-*}
nchan=$(get_nchan $mezz)
let NCHAN=$nchan*$sitecount
echo $host $mezz $sites SITELIST:$SITELIST sitecount:$sitecount NCHAN $NCHAN

scp -r sysconfig root@$host:/mnt/local/


if [ ! -e ${MODNAME}_transient.init ]; then
	echo ERROR ${MODNAME}_transient.init not found
	exit 1
fi

sed -e "s/%NCHAN%/$NCHAN/g" -e "s/%SITELIST%/$SITELIST/g" \
	${MODNAME}_transient.init >transient.init

if [ -e ${MODNAME}-site-1-peers ]; then
	PEERS=${MODNAME}-site-1-peers
else
	PEERS=default-site-1-peers
fi

sed -e "s/%SITELIST%/$SITELIST/g" $PEERS >site-1-peers

scp transient.init site-1-peers root@$host:/mnt/local/sysconfig

