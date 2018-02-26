--ST_MakePoint
--ST_SetSRID
CREATE TABLE tmp_points AS
SELECT
  id,
  ST_SetSRID(ST_MakePoint(pickup_longitude, pickup_latitude), 4326) as pickup,
  ST_SetSRID(ST_MakePoint(dropoff_longitude, dropoff_latitude), 4326) as dropoff
FROM green_tripdata_staging
WHERE pickup_longitude IS NOT NULL OR dropoff_longitude IS NOT NULL;

CREATE INDEX idx_tmp_points_pickup ON tmp_points USING gist (pickup);
CREATE INDEX idx_tmp_points_dropoff ON tmp_points USING gist (dropoff);

CREATE TABLE tmp_pickups AS
SELECT t.id, n.gid
FROM tmp_points t, nyct2010 n
WHERE ST_Within(t.pickup, n.geom);

CREATE TABLE tmp_dropoffs AS
SELECT t.id, n.gid
FROM tmp_points t, nyct2010 n
WHERE ST_Within(t.dropoff, n.geom);