#!/bin/bash

HOSTNAME=$(cat /etc/hostname)

echo "[${HOSTNAME}] Updating & installing requirements..."
dnf update -y -q
dnf install -y -q fio python3 python3-devel python3-pip tar libjpeg-devel zlib-devel git gcc

pip3 install -q wheel fio-plot
git clone https://github.com/louwrentius/fio-plot

for device in $(find /dev -name 'vd[b-z]'); do
	DEVICE_SHORT=$(echo $device | cut -c 6-)
	DIR="/mnt/${DEVICE_SHORT}"
	BENCH_FILE="bench"
	FIO_OUTPUT="/root/fio-output"

	mkfs.xfs $device
	mkdir -p $DIR
	mount $device $DIR

	touch "${DIR}/${BENCH_FILE}"
	python3 ~/fio-plot/bin/bench-fio \
		-d "${DIR}/${BENCH_FILE}" \
		-t file \
		-o $FIO_OUTPUT \
		--size=1Gb \
		--numjobs=8 \
		--destructive \
		--time-based \
		--iodepth 8 16 \
		--loginterval 500 \
		-m randrw \
		--rwmixread 50

	fio-plot -i ${FIO_OUTPUT}/${BENCH_FILE}/randrw50/4k \
		-T "$HOSTNAME $device" \
		-r randrw -g -t bw -d 8 16 -n 8 \
		-o "/root/${HOSTNAME}-${DEVICE_SHORT}.png"

	rm -rf $FIO_OUTPUT
done
