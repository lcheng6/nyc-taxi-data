#!/bin/bash

source ./PG_Connection_Parameters.sh;
createdb nyc-taxi-data

psql nyc-taxi-data -f create_nyc_taxi_schema.sql

#this command load data from shape file (ESRI) into the postgres sql
#-s from_srid:to_srid srid is the ESRI id, I think
shp2pgsql -s 2263:4326 taxi_zones/taxi_zones.shp | psql -d nyc-taxi-data
#documentation on create index https://www.postgresql.org/docs/9.1/static/sql-createindex.html
#create index based on gist (geom), gist is a spatial index, looks like the maximum rectangle dimension (min shape of a veritical rectangular box) of a object
psql nyc-taxi-data -c "CREATE INDEX index_taxi_zones_on_geom ON taxi_zones USING gist (geom);"
psql nyc-taxi-data -c "CREATE INDEX index_taxi_zones_on_locationid ON taxi_zones (locationid);"
#VACUUM: reclaims storage occupied by dead tuples
#ANALYZE: ANALYZE collects statistics about the contents of tables in the database, and stores the results in the pg_statistic system catalog.
# Subsequently, the query planner uses these statistics to help determine the most efficient execution plans for queries.
psql nyc-taxi-data -c "VACUUM ANALYZE taxi_zones;"

#this line creates the nyct2010 table, source is nyc opendata
shp2pgsql -s 2263:4326 nyct2010_15b/nyct2010.shp | psql -d nyc-taxi-data
#NTA is New York Taxi Agency code.  It's referenced in taxi-zone-lookup-with-ntacode.csv
#a single line entry addition to add newark airport
psql nyc-taxi-data -f add_newark_airport.sql
psql nyc-taxi-data -c "CREATE INDEX index_nyct_on_geom ON nyct2010 USING gist (geom);"
psql nyc-taxi-data -c "CREATE INDEX index_nyct_on_ntacode ON nyct2010 (ntacode);"
psql nyc-taxi-data -c "VACUUM ANALYZE nyct2010;"

psql nyc-taxi-data -f add_tract_to_zone_mapping.sql

cat data/fhv_bases.csv | psql nyc-taxi-data -c "COPY fhv_bases FROM stdin WITH CSV HEADER;"
cat data/central_park_weather.csv | psql nyc-taxi-data -c "COPY central_park_weather_observations FROM stdin WITH CSV HEADER;"
psql nyc-taxi-data -c "UPDATE central_park_weather_observations SET average_wind_speed = NULL WHERE average_wind_speed = -9999;"
