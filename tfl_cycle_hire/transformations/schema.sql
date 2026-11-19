CREATE OR REFRESH STREAMING TABLE bronze
AS SELECT
  `Number`                AS rental_id,
  `Start date`            AS start_date,
  `Start station number`  AS start_station_id,
  `Start station`         AS start_station_name,
  `End date`              AS end_date,
  `End station number`    AS end_station_id,
  `End station`           AS end_station_name,
  `Bike number`           AS bike_number,
  `Bike model`            AS bike_model,
  `Total duration`        AS total_duration,
  `Total duration (ms)`   AS total_duration_ms
FROM STREAM read_files(
  '/Volumes/workspace/tfl/raw/tfl_cycling_2026/',
  format => 'csv',
  header => true,
  inferSchema => true
);

CREATE OR REFRESH STREAMING TABLE silver (
  CONSTRAINT rental_id EXPECT (rental_id IS NOT NULL) ON VIOLATION FAIL UPDATE,
  CONSTRAINT bike_number EXPECT (bike_number IS NOT NULL) ON VIOLATION FAIL UPDATE,
  CONSTRAINT total_duration_ms EXPECT (total_duration_ms IS NOT NULL AND 1000 < total_duration_ms AND total_duration_ms < 8.64e+7),
  CONSTRAINT start_timestamp EXPECT (start_timestamp IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT end_timestamp EXPECT (end_timestamp IS NOT NULL) ON VIOLATION DROP ROW
) AS SELECT DISTINCT
  rental_id,
  start_station_id,
  start_station_name,
  end_station_id,
  end_station_name,
  bike_number,
  bike_model,
  total_duration,
  CAST(total_duration_ms AS BIGINT) AS total_duration_ms,
  coalesce(
  try_to_timestamp(start_date, 'dd/MM/yyyy HH:mm'),
  try_to_timestamp(start_date, 'yyyy-MM-dd HH:mm')) AS start_timestamp,
  coalesce(try_to_timestamp(start_date, 'dd/MM/yyyy HH:mm'),
  try_to_timestamp(start_date, 'yyyy-MM-dd HH:mm')) AS end_timestamp
FROM STREAM(bronze);

CREATE OR REFRESH MATERIALIZED VIEW gold_daily_hires
AS SELECT
  date(start_timestamp)          AS hire_date,
  count(*)                       AS hires,
  avg(total_duration_ms) / 60000 AS avg_duration_mins
FROM silver
GROUP BY date(start_timestamp);

CREATE OR REFRESH MATERIALIZED VIEW gold_station_activity
AS
WITH starts AS (
  SELECT
    date_trunc('month', start_timestamp) AS month,
    start_station_name                   AS station_name,
    count(*)                             AS total_hires_started
  FROM silver
  GROUP BY date_trunc('month', start_timestamp), start_station_name
),
ends AS (
  SELECT
    date_trunc('month', end_timestamp) AS month,
    end_station_name                   AS station_name,
    count(*)                           AS total_hires_ended
  FROM silver
  GROUP BY date_trunc('month', end_timestamp), end_station_name
)
SELECT
  coalesce(s.month, e.month)                 AS month,
  coalesce(s.station_name, e.station_name)   AS station_name,
  coalesce(s.total_hires_started, 0)         AS total_hires_started,
  coalesce(e.total_hires_ended, 0)           AS total_hires_ended
FROM starts s
FULL OUTER JOIN ends e
  ON s.month = e.month
 AND s.station_name = e.station_name;

 CREATE OR REFRESH MATERIALIZED VIEW gold_popular_routes
 AS
 SELECT
   start_station_name,
   end_station_name,
   count(*) AS total_journeys,
   avg(total_duration_ms) / 60000 AS avg_duration_mins
 FROM silver
 GROUP BY start_station_name, end_station_name
 ORDER BY total_journeys DESC;