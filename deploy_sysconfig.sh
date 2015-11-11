#!/bin/sh

if [[ $# -eq 0 ]] ; then
    echo -e '\n Enter Carrier followed by Mezzanine\n e.g. acq1001_079 acq420\n'
    exit 0
fi

host=$1
mezz=$2

echo $host

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
*)
  echo "Invalid mezzanine specified!!!"
  ;;
esac

scp $trans_file root@$host:/mnt/local/sysconfig/transient.init

###ssh root@$host /mnt/bin/update_release /tmp/$LATEST

