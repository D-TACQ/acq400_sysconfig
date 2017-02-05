# AI average over 2048 points, the max for 64K buffer, 8 channels
echo 2048 > /etc/acq400/0/OVERSAMPLING
export EPICS_CA_MAX_ARRAY_BYTES=500000

