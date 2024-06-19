#!/bin/bash

export PATH=${HOME}/x-tools/aarch64-urs-linux-gnu/bin:$PATH
export CROSS_COMPILE=aarch64-linux-
export ARCH=arm
export SYSROOT=$(aarch64-linux-gcc -print-sysroot)

