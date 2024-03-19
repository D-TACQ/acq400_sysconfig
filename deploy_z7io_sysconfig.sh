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

incant="$*"
shift
mezz="$*"
signature="./z7io/z7io"
for ax in $*; do
	signature="${signature}_$ax"
done

if [ ! -d $signature/local ]; then
	echo ERROR SIGNATURE $signature/local does not exist
	exit 1
fi


if [ ! -z "$(git status --porcelain)" ]; then
        echo -e "\e[91mWARNING: git is not clean, make it a DRYRUN\e[0m"
	DRYRUN=1
fi

echo "CLEANUP rm STAGING"
rm -Rf STAGING STAGING2
mkdir -p STAGING/mnt/local/cal
echo STAGING is a place to build a local copy of the remote image

echo SIGNATURE $signature/local exists
cp -r $signature/local/* STAGING/mnt/local

mkdir -p ARCHIVE
uut=$host
staging=STAGING

for st in $staging; do
        githash=$(git rev-parse HEAD)
        user="${USER}@$(hostname)"
        sed -i -e "2i#\n# created by deploy_sysconfig for uut:$uut mezz:$mezz\n# by ${user} on $(date)\n# git $githash\n# incant $incant\n" $st/mnt/local/rc.user
        tar cvf ARCHIVE/$uut.tar -C $st .
        echo "INFO ARCHIVE/$uut.tar created"
	break
done


[ $DRYRUN -eq 0 ] && scp -r $staging/mnt/local/* root@$host:/mnt/local





