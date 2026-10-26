-- 02-sld-styling input (optional): synthetic point/line/polygon tables
-- matching the styles in styles.sld. Obviously synthetic names only;
-- no real addresses, no personal data.
-- Run: psql -h <PG_HOST> -p <PG_PORT> -d <PG_DB> -U <PG_USER> -f sample-features.sql

CREATE EXTENSION IF NOT EXISTS postgis;

DROP TABLE IF EXISTS synthetic_points;
CREATE TABLE synthetic_points (
    id integer PRIMARY KEY, name text NOT NULL,
    geom geometry(Point, 4326) NOT NULL);
INSERT INTO synthetic_points VALUES
    (1, 'Synthetic-Alpha Point', ST_SetSRID(ST_MakePoint(-80.000, 29.000), 4326)),
    (2, 'Synthetic-Beta Point',  ST_SetSRID(ST_MakePoint(-80.010, 29.010), 4326));

DROP TABLE IF EXISTS synthetic_lines;
CREATE TABLE synthetic_lines (
    id integer PRIMARY KEY, name text NOT NULL,
    geom geometry(LineString, 4326) NOT NULL);
INSERT INTO synthetic_lines VALUES
    (1, 'Synthetic-Alpha Line', ST_SetSRID(ST_GeomFromText(
        'LINESTRING(-80.030 28.990, -80.000 29.000, -79.970 29.010)'), 4326));

DROP TABLE IF EXISTS synthetic_polygons;
CREATE TABLE synthetic_polygons (
    id integer PRIMARY KEY, name text NOT NULL,
    geom geometry(Polygon, 4326) NOT NULL);
INSERT INTO synthetic_polygons VALUES
    (1, 'Synthetic-Alpha Area', ST_SetSRID(ST_GeomFromText(
        'POLYGON((-80.020 28.990, -79.980 28.990, -79.980 29.020, -80.020 29.020, -80.020 28.990))'), 4326));

SELECT 'points', count(*) FROM synthetic_points
UNION ALL SELECT 'lines', count(*) FROM synthetic_lines
UNION ALL SELECT 'polygons', count(*) FROM synthetic_polygons;
