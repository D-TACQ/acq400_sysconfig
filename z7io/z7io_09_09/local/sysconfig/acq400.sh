# remote network boot (superceded by MTCA/mmc)
REBOOT_KNOB=y
# divide DRAM into 128 x 4MB buffers (large buffers best for AWG)
BLEN=4194304
NBUF=128
#BLEN=1048576
#NBUF=512
# scaled rate status for CONTINUOUS OPI
#STREAM_OPTS=--fill-scale
#STREAM_OPTS=--null-copy

# Rapid Scope, 256 points, external trigger to 50Hz
#ACQ400_JUDGEMENT="256 d0"
# Rapid Scope, 256 points, internal trigger to 50Hz
#ACQ400_JUDGEMENT="256 d1"
# Rapid Scope, 1024 points, internal trigger to 10Hz
#ACQ400_JUDGEMENT="1024 d1"
# for normal streaming, leave all JUDGEMENT commented out


