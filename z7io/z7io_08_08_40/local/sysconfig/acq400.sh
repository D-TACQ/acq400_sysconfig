REBOOT_KNOB=y
BLEN=4194304
NBUF=128
#BLEN=1048576
#NBUF=512
# scaled rate status for CONTINUOUS OPI
#STREAM_OPTS=--fill-scale
#STREAM_OPTS=--null-copy
STREAM_OPTS=--full-copy


# for "normal use", comment out ALL ACQ400_JUDGMENT
# rapid update, ext trigger
ACQ400_JUDGEMENT="256 d0"
# rapid update, int trigger
#ACQ400_JUDGEMENT="256 d1"
# < 10Hz, int trigger
#ACQ400_JUDGEMENT="2048 d1"

FANSPEED=100

