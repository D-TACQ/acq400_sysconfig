#!/bin/bash


if [[ $# -lt 2 ]]; then
	cat - <<EOF
		./deploy_z7io_sysconfig.sh z7io_123 M1 M2 [M3]
		where M1 is the MCODE module in site 1, M2 in site 2, M3 in site 3
		site 3 is the AMC FMC

		eg
		./deploy_z7io_sysconfig.sh z7io_123 04 04
		./deploy_z7io_sysconfig.sh z7io_123 04 04 40
		./deploy_z7io_sysconfig.sh z7io_123 04 41
EOF
	exit 	0
fi

DRYRUN=${DRYRUN:-0}

host=$1
if [ "${host:0:4}" != "z7io" ]; then
	echo ERROR host $host is not a z7io
	exit 1
fi

shift
signature="./z7io/z7io"
for ax in $*; do
	signature="${signature}_$ax"
done

if [ ! -d $signature/local ]; then
	echo ERROR SIGNATURE $signature/local does not exist
	exit 1
fi

echo SIGNATURE $signature/local exists
[ $DRYRUN -ne 0 ] && echo DRYRUN scp -r $signature/local/* root@$host:/mnt/local
[ $DRYRUN -eq 0 ] && scp -r $signature/local/* root@$host:/mnt/local





