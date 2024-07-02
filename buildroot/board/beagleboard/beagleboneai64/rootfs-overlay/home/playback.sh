#!/bin/bash


EDGE_DET=0
RESOLUTION_STRING=""
RESOLUTION_WIDTH=0
RESOLUTION_HEIGHT=0
FRAMERATE=0

echo -n "Specify resolution (FHD(1920x1080), HD(1280x720), VGA(640x480)): "
read RESOLUTION_STRING

echo -n "Specify framerate (30, 20, 10): "
read FRAMERATE

echo -n "Include edge detection (0 - no, 1 - yes): "
read EDGE_DET

if [ "$RESOLUTION_STRING" = "FHD" ];
then
	RESOLUTION_WIDTH=1920
	RESOLUTION_HEIGHT=1080
elif [ "$RESOLUTION_STRING" = "HD" ];
then
	RESOLUTION_WIDTH=1280
	RESOLUTION_HEIGHT=720
else
	RESOLUTION_WIDTH=640
	RESOLUTION_HEIGHT=480
fi

if [ $EDGE_DET -eq 0 ];
then
	echo "Displaying raw video..."
	gst-launch-1.0 v4l2src ! image/jpeg, width=${RESOLUTION_WIDTH}, height=${RESOLUTION_HEIGHT}, framerate=${FRAMERATE}/1 ! jpegdec ! videoconvert ! autovideosink
else
	echo "Displaying edge detection video..."
	gst-launch-1.0 v4l2src ! image/jpeg, width=${RESOLUTION_WIDTH}, height=${RESOLUTION_HEIGHT}, framerate=${FRAMERATE}/1 ! jpegdec ! videoconvert ! edgetv ! videoconvert ! autovideosink
fi