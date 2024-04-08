# AI average over 2048 points, the max for 64K buffer, 8 channels
echo -2048 > /etc/acq400/0/OVERSAMPLING
export EPICS_CA_MAX_ARRAY_BYTES=500000

judgement() {
# short trace length, rapid update 50Hz possible
# $1:size, $2:dX (don't care) $3:BPB
	export SIZE=${1:-128}
# round to the nearest 10
	export SIZE=$((${SIZE%[123456789]*}*10))
	export IOC_PREINIT=./scripts/load.judgement
	export BURSTS_PER_BUFFER=${3:-1}
	export RTM_BUFFER_MON=y
	export RTM_BUFFER_MON_VERBOSE=1
}
source /mnt/local/sysconfig/acq400.sh
[ ! -z "$ACQ400_JUDGEMENT" ] && judgement $ACQ400_JUDGEMENT


