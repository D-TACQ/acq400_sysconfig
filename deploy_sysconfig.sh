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

case $mezz in
"acq420")
  trans_file="acq420_transient.init"
  echo $trans_file
  ;;
"acq425")
  trans_file="acq425_transient.init"
  echo $trans_file
  ;;
"2xacq425")
  trans_file="2xacq425_transient.init"
  echo $trans_file
  ;;
"acq424")
  trans_file="acq424_transient.init"
  echo $trans_file
  echo -e "\e[34mN.B. Clock setup in transient file!"; tput sgr0
  ;;
"2xacq424")
  trans_file="2xacq424_transient.init"
  echo $trans_file
  echo -e "\e[34mN.B. Clock setup in transient file!"; tput sgr0
  ;;
"acq430")
  trans_file="acq430_transient.init"
  echo $trans_file
  ;;
"acq435")
  trans_file="acq435_transient.init"
  echo $trans_file
  ;;
"acq480")
  if [[ $host =~ "acq1001" ]]; then
     trans_file="acq480_1001_transient.init"
  else
     trans_file="acq480_transient.init"
  fi
  echo $trans_file
  scp acq480_rc.user root@$host:/mnt/local/rc.user
  ;;
"bolo8")
  trans_file="bolo8_transient.init"
  echo $trans_file
  ;;
*)
  echo -e "\nInvalid mezzanine specified!!!\n"
  echo -e "acq420\nacq425\n2xacq425\nacq424\n2xacq424\nacq430\nacq435\nbolo8\n" 
  exit 0
  ;;
esac

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

echo -e "\e[34m\nTo instantiate default rc.user, run 'install-auto-soft_trigger' on UUT\n"; tput sgr0

