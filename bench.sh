#!/bin/bash
P=/sys/class/powercap/intel-rapl:0
T=8
e0=$(sudo cat $P/energy_uj); t0=$(date +%s.%N)
sleep $T
e1=$(sudo cat $P/energy_uj); t1=$(date +%s.%N)
de=$(( (e1 - e0) ))
dt=$(echo "$t1 - $t0" | bc -l)
w=$(echo "scale=1; $de/1000000/$dt" | bc -l)
# avg freq across cpus
f=$(awk '/cpu MHz/{s+=$4;n++} END{printf "%.0f", s/n}' /proc/cpuinfo)
# package temp
tmp=$(sudo cat /sys/class/hwmon/hwmon8/temp1_input 2>/dev/null); tmp=$((tmp/1000))
echo "pkg_power=${w}W  avg_freq=${f}MHz  temp=${tmp}C"
