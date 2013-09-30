#!/bin/bash

ID=$1
URL=$2
TARGET=$3

DEST=${TARGET}/${ID}.tif
TMP=`echo ${DEST}.$$`

wget -qO ${TMP} ${URL} \
    && mv ${TMP} ${DEST}

RESULT=$?

# do the tiling and overviews in the background
( gdal_translate ${DEST} ${TMP} -co TILED=YES -co COMPRESS=LZW -co PREDICTOR=2 \
    && gdaladdo -r average ${TMP} 2 4 8 16 32 64 \
    && mv ${TMP} ${DEST} ) &

exit ${RESULT}
