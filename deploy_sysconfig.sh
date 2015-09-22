#!/bin/sh

host=$1
mezz=$2

echo $host

scp -r sysconfig root@$host:/mnt/local/

case $mezz in
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
  ;;
"2xacq424")
  trans_file="2xacq424_transient.init"
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

