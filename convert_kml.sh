#!/bin/bash
# https://developers.google.com/kml/documentation/KML_Samples.kml
# https://stackoverflow.com/questions/22029114/how-to-import-geojson-file-to-mongodb
# ./convert_kml.sh KML_Samples.kml

SAVEIFS=$IFS
outputdir=kml
mkdir ${outputdir}
rm ${outputdir}/*
KML=$1

layers="$(ogrinfo -q -ro -so "$KML" | perl -pe 's/^[^ ]+ //g and s/ \([^()]+\)$//g')"

# Make sure we don't iterate over spaces in layer names
IFS=$'\n'
filename=$(basename "$KML")
filename="${filename%.*}"

for layer in $layers; do
    IFS=$SAVEIFS
    echo "File: $filename, layer $layer"
    ogr2ogr -f "GeoJSON" "${outputdir}/${filename}_${layer}.geojson" "$KML" "${layer}"
done
IFS=$SAVEIFS

npm install -g geojson-merge

merged="${outputdir}/${filename}__merged.geojson"
geojson-merge ${outputdir}/${filename}_*.geojson > $merged

jsonArray="${outputdir}/${filename}_array.geojson"
jq --compact-output ".features" $merged > $jsonArray

URI=
URI="mongodb+srv://main_user:8BjRQxotAI6jFuB@azure.em4dc.mongodb.net/?authSource=admin&replicaSet=atlas-pddtwb-shard-0&readPreference=primary&ssl=true"
mongoimport $URI --db analytics -c kml --file $jsonArray --jsonArray --drop