# OSM Indexing

These services used IMPOSM (https://github.com/omniscale/imposm3) to
import OSM planet data into PostGIS.  We use IMPOSM's mapping facility
to do light filtering on the OSM data and inject it into the database.

Recently questions have been asked about the maintenance level of
IMPOSM.  We have explored other alternatives.  In our prototyping, it
was possible to configure OSM2PGSQL to produce very similar data as
IMPOSM with the '--output=flex' and an appropriate LUA style.

You will need the new-york-latest.osm.pbf file as well as the rpi.geojson files to import a tile into the database.
Use the command ./imposm import -mapping mapping.yml -read new-york-latest.osm.pbf -write -connection postgis://username:password@host:port/postgres -limitto rpi.geojson

http://download.geofabrik.de/, get osm.pbf tiles from here. You will need to do this because the .pbf files are too big to put into github, though we should not need to update the .pbf files too often, the original recomendation was once a week, and it will be a while until we need to do that.
https://geojson.io, get a geojson area from here.
Do not edit the mapping.yml file.
