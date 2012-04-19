#!/bin/sh
echo $1 $2 $3
TMP="2"

echo  gdal_translate -of GTIFF $3 $1 $1$TMP
echo  "translating"
gdal_translate -of GTIFF $3 $1 $1$TMP

echo  "warping..."
gdalwarp -rc -t_srs "EPSG:4326" -s_srs "EPSG:4326" -co "TILED=YES"  $1$TMP $2
gdaladdo -r average $2 2 4 8 16 32 64
echo "warping finished!"


