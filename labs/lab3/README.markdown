---
title: Xcakelabs: GDAL Tile Creation Tutorial
---

GDAL Tile Creation Tutorial
===========================

Step 0 - Requirements:
----------------------
* Google Earth
* Any image editor supporting PNG export (I suggest Pixelmator)
* Install the GDAL framework from [Kyngchaos](http://www.kyngchaos.com/software:frameworks "GDAL framework")

Once installed, add 

	`export PATH="/Library/Frameworks/GDAL.framework/Programs:$PATH"`

to `~/.bash_profile`

Step 1 - Cleanup (optional):
----------------------------
Do a cleanup (if we need to)

`rm -rf *vrt
rm -rf templebar2`

If running in the simulator, you may also need to reset the simulator, as cached tiles don't get cleared down between builds.

Step 2 - Align image in Google Earth:
-------------------------------------
1. Using *Google Earth*, create an image overlay.
2. Roughly position the map image, convert to *LatLonQuad*, and tweak the corner positions till it's aligned up correctly.
3. Export the image overlay as KML (for maximum accuracy), and grab the coordinates from the xml output (see the example below).

`-6.278803109016151,53.34166274680196,0 -6.265041373107916,53.34089937994335,0 -6.264965610690526,53.3460466814568,0 -6.278094120697057,53.34652473124198,0 `

which gives us

`1:	-6.278803109016151 53.34166274680196`

`2:	-6.265041373107916 53.34089937994335`

`3:	-6.264965610690526 53.3460466814568`

`4:	-6.278094120697057 53.34652473124198`

Step 3 - GDAL Info:
-------------------
Run *gdalinfo* on the overlay image to get the LatLonQuad coordinate ordering. Eg:

`gdalinfo medieval-dublin.jpg`

From the output, get the corner coordinates

`Corner Coordinates:
Upper Left  (    0.0,    0.0)
Lower Left  (    0.0, 1317.0)
Upper Right ( 2111.0,    0.0)
Lower Right ( 2111.0, 1317.0)`

Step 4: GDAL Translate:
-----------------------
Combine the output from the KML with the gdalinfo to get the required `-gcp` parameters for `gdal_translate`. NOTE: We need to get the ordering correct with respect to the image coordinates.

* KML 1: should map to Lower Left  (...)
* KML 2: should map to Lower Right (...)
* KML 3: should map to Upper Right (...)
* KML 4: should map to Upper Left  (...)

The -gcp parameter format for gdal_translate is

`gdal_translate \`
`-of VRT \`
`-a_srs EPSG:4326 \`
`-gcp    0    0 -6.278094120697057 53.34652473124198 \`
`-gcp    0 1317 -6.278803109016151 53.34166274680196 \`
`-gcp 2111    0 -6.264965610690526 53.3460466814568  \`
`-gcp 2111 1317 -6.265041373107916 53.34089937994335 \`
`medieval-dublin.png \`
`medieval-dublin.vrt`

Step 5 - GDAL Warp:
-------------------
Now run

`gdalwarp -of VRT -t_srs EPSG:4326 medieval-dublin.vrt Tiles.vrt`

to warp the vrt file to the desired mercator-ready output

Step 6 - GDAL To Tiles
-------
Generate the tiles for use with the Xcode project using

`gdal2tiles.py -p mercator -k Tiles.vrt`

This assumes that 'Tiles' is the directory containing the required maptiles, and has been added as a folder reference to the Xcode project.

Examples:
---------

### JPG map overlay:
`rm -rf *vrt`

`rm -rf templebar2`

`gdal_translate -of VRT -a_srs EPSG:4326 -gcp    0    0 -6.278094120697057 53.34652473124198 -gcp    0 1317 -6.278803109016151 53.34166274680196 -gcp 2111    0 -6.264965610690526 53.3460466814568  -gcp 2111 1317 -6.265041373107916 53.34089937994335 medieval-dublin.png medieval-dublin.vrt`

`gdalwarp -of VRT -t_srs EPSG:4326 medieval-dublin.vrt Tiles.vrt`

`gdal2tiles.py -p mercator -k Tiles.vrt`

### PNG map overlay with transparency:
`rm -rf *vrt`

`rm -rf Tiles`

`gdal_translate -of VRT -a_srs EPSG:4326 -gcp    0    0 -6.278094120697057 53.34652473124198 -gcp    0 1317 -6.278803109016151 53.34166274680196 -gcp 2111    0 -6.264965610690526 53.3460466814568  -gcp 2111 1317 -6.265041373107916 53.34089937994335 medieval-dublin-walled-city.png medieval-dublin-walled-city.vrt`

`gdalwarp -of VRT -t_srs EPSG:4326 medieval-dublin-walled-city.vrt Tiles.vrt`

`gdal2tiles.py -p mercator -k Tiles.vrt`

### Large PNG map overlay with transparency:
`gdalinfo medieval-dublin-walled-city-large-resolution.png`

`rm -rf *vrt`

`rm -rf Tiles`

`gdal_translate -of VRT -a_srs EPSG:4326 -gcp    0    0 -6.278094120697057 53.34652473124198 -gcp    0 5268 -6.278803109016151 53.34166274680196 -gcp 8444    0 -6.264965610690526 53.3460466814568  -gcp 8444 5268 -6.265041373107916 53.34089937994335 medieval-dublin-walled-city-large-resolution.png medieval-dublin-walled-city-large-resolution.vrt`

`gdalwarp -of VRT -t_srs EPSG:4326 medieval-dublin-walled-city-large-resolution.vrt Tiles.vrt`

`gdal2tiles.py -p mercator -k Tiles.vrt`
