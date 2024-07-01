#!/bin/bash

export PATH=${HOME}/buildroot/output/host/bin:$PATH
export CROSS_COMPILE=aarch64-buildroot-linux-gnu-
export ARCH=arm64
export SYSROOT=$(aarch64-buildroot-linux-gnu-gcc -print-sysroot)

