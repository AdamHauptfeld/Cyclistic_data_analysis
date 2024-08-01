/* Find average trip length in seconds by user type */
SELECT usertype, avg(trip_length) AS avg_trip_in_seconds
FROM bikeshare_data
GROUP BY usertype;

/* Find average trip length by user type, excluding 24hr+ outliers */
SELECT
    usertype,
    (floor(avg(trip_length) / 86400)) || 'd ' ||
    (floor((avg(trip_length) % 86400) / 3600)) || 'h ' ||
    (floor((avg(trip_length) % 3600) / 60)) || 'm ' ||
    (floor(avg(trip_length) % 60)) || 's ' AS avg_trip
FROM
    bikeshare_data
WHERE trip_length < 86400
GROUP BY usertype;

/* Find max trip length by user type */
SELECT
    usertype,
    (floor(max(trip_length) / 86400)) || 'd ' ||
    (floor((max(trip_length) % 86400) / 3600)) || 'h ' ||
    (floor((max(trip_length) % 3600) / 60)) || 'm ' ||
    (floor(max(trip_length) % 60)) || 's ' AS max_trip
FROM
    bikeshare_data
GROUP BY usertype;

/* Find most common day for ride by user type */
SELECT usertype, mode() WITHIN GROUP (order by day_of_week) FROM bikeshare_data
GROUP BY usertype;

/* Find 10 most popular starting stations */
SELECT from_station_name AS station, COUNT(from_station_name) AS num_of_starts
FROM bikeshare_data
GROUP BY from_station_name
ORDER BY num_of_starts DESC
LIMIT 10;

/* Find 10 most popular end stations */
SELECT to_station_name AS station, COUNT(to_station_name) AS num_of_ends
FROM bikeshare_data
GROUP BY to_station_name
ORDER BY num_of_ends DESC
LIMIT 10;


/* Find 10 most popular starting stations for subscribers */
SELECT from_station_name AS station, COUNT(from_station_name) AS num_of_starts
FROM bikeshare_data
WHERE usertype = 'Subscriber'
GROUP BY from_station_name
ORDER BY num_of_starts DESC
LIMIT 10;

/* Find 10 most popular starting stations for non-subscribers */
SELECT from_station_name AS station, COUNT(from_station_name) AS num_of_starts
FROM bikeshare_data
WHERE usertype = 'Customer'
GROUP BY from_station_name
ORDER BY num_of_starts DESC
LIMIT 10;

/*Select 10 most popular stations for starting OR ending */
SELECT to_and_from_names, COUNT(to_and_from_names)
FROM(
	SELECT from_station_name AS to_and_from_names
	FROM bikeshare_data
	UNION ALL
	SELECT to_station_name
	FROM bikeshare_data
) AS to_and_from_column
GROUP BY to_and_from_names
ORDER BY COUNT(to_and_from_names) DESC
LIMIT 10;


/* Stations by difference between # of subscriber starts and customer starts */
SELECT sub_query.from_station_name AS station,
	sub_query.sub_count,
	cust_query.cust_count,
	sub_query.sub_count - cust_query.cust_count AS subs_minus_custs_starts
FROM
(
	SELECT from_station_name, COUNT(from_station_name) AS sub_count
	FROM bikeshare_data
	WHERE usertype = 'Subscriber'
	GROUP BY from_station_name
	ORDER BY sub_count DESC
) AS sub_query
JOIN
(
	SELECT from_station_name, COUNT(from_station_name) AS cust_count
	FROM bikeshare_data
	WHERE usertype = 'Customer'
	GROUP BY from_station_name
	ORDER BY cust_count DESC
) AS cust_query
ON sub_query.from_station_name = cust_query.from_station_name
ORDER BY subs_minus_custs_starts DESC;


/* Stations  with over 1000 customer starts, ordered by similarity
in number of customer and subscriber starts*/
SELECT total_query.station_name,
	total_query.total_count,
	total_query.abs_difference
FROM
(
SELECT 
sub_query.from_station_name AS station_name,
sub_query.sub_count AS sub_count,
cust_query.cust_count  AS cust_count,
sub_query.sub_count + cust_query.cust_count AS total_count,
ABS(sub_query.sub_count - cust_query.cust_count) AS abs_difference
	FROM
	(
		SELECT from_station_name, COUNT(from_station_name) AS sub_count
		FROM bikeshare_data
		WHERE usertype = 'Subscriber'
		GROUP BY from_station_name
		ORDER BY sub_count DESC
	) AS sub_query
	JOIN
	(
		SELECT from_station_name, COUNT(from_station_name) AS cust_count
		FROM bikeshare_data
		WHERE usertype = 'Customer'
		GROUP BY from_station_name
		ORDER BY cust_count DESC
	) AS cust_query
	ON sub_query.from_station_name = cust_query.from_station_name
	) AS total_query
WHERE total_query.cust_count > 1000
ORDER BY total_query.abs_difference
LIMIT 20;


/* Trip length in h:m:s format */
SELECT
	trip_id,
	usertype,
    to_char(
        ((floor(trip_length / 86400) * 24 + floor((trip_length % 86400) / 3600)) || ' hours ' ||
        floor((trip_length % 3600) / 60) || ' minutes ' ||
        (trip_length % 60) || ' seconds')::interval,
        'HH24:MI:SS'
    ) AS formatted_time
FROM
    bikeshare_data
ORDER BY trip_length DESC;

/* Trip length in d:h:m:s format */
SELECT
	trip_id,
	usertype,
    (floor(trip_length / 86400)) || 'd ' ||
    (floor((trip_length % 86400) / 3600)) || 'h ' ||
    (floor((trip_length % 3600) / 60)) || 'm ' ||
    (trip_length % 60) || 's ' AS formatted_time
FROM
    bikeshare_data
ORDER BY trip_length DESC;

/* Count trips longer than a day by usertype*/
SELECT usertype, COUNT(formatted_time) AS trips_longer_than_24h
FROM(
	SELECT
		usertype,
	    to_char(
	        ((floor(trip_length / 86400) * 24 + floor((trip_length % 86400) / 3600)) || ' hours ' ||
	        floor((trip_length % 3600) / 60) || ' minutes ' ||
	        (trip_length % 60) || ' seconds')::interval,
	        'HH24:MI:SS'
	    ) AS formatted_time
	FROM
	    bikeshare_data
	ORDER BY trip_length DESC
	)
WHERE formatted_time > '24:00:00'
GROUP BY usertype;

/* Count trips per day by usertype */
SELECT usertype, day_of_week, COUNT(trip_id) AS num_of_trips
FROM bikeshare_data
GROUP BY usertype, day_of_week
ORDER BY num_of_trips DESC;

/* Using CTE to find percentage of each weekday's trips taken by which usertype 
E.g. "What percentage of Monday trips are taken by subscribers" */
WITH trip_counts AS 
(
   SELECT 
   day_of_week,
   usertype,
   COUNT(trip_id) AS usertype_count,
   SUM(COUNT(trip_id)) OVER (PARTITION BY day_of_week) AS total_trips
   FROM 
   bikeshare_data
   GROUP BY 
   day_of_week, usertype
)
SELECT 
day_of_week,
usertype,
ROUND(usertype_count / total_trips * 100, 2) AS percentage
FROM 
trip_counts
ORDER BY 
day_of_week, usertype;

/* Using CTE to find the percentage of trips each user type takes on a given day as a total
of all the trips that usertype takes
E.g. "What percentage of subscriber trips occur on Mondays" */
WITH trip_counts AS 
(
   SELECT 
   day_of_week,
   usertype,
   COUNT(trip_id) AS day_count,
   SUM(COUNT(trip_id)) OVER (PARTITION BY usertype) AS total_trips
   FROM 
   bikeshare_data
   GROUP BY 
   day_of_week, usertype
)
SELECT 
day_of_week,
usertype,
ROUND(day_count / total_trips * 100, 2) AS percentage
FROM 
trip_counts
ORDER BY 
usertype, day_of_week;

/*Find mean ages of riders by usertype */
SELECT usertype, ROUND(AVG(age), 2)
FROM(
	SELECT trip_id, usertype, 2019-birthyear AS age
	FROM bikeshare_data
	WHERE birthyear IS NOT NULL
) AS age_table
GROUP BY usertype;


/*Find mode age of each usertype */
SELECT usertype, mode() WITHIN GROUP (order by age)
FROM(
	SELECT trip_id, usertype, 2019-birthyear AS age
	FROM bikeshare_data
	WHERE birthyear IS NOT NULL
) AS age_table
GROUP BY usertype;

/*Most popular ages */
SELECT usertype, age, COUNT(age)
FROM(
	SELECT usertype, 2019-birthyear AS age
	FROM bikeshare_data
	WHERE birthyear IS NOT NULL
) AS age_table
GROUP BY usertype, age
ORDER BY COUNT(age) DESC
LIMIT 10;

/*Find gender absolute counts by usertype */
SELECT usertype, gender, count(trip_id)
FROM bikeshare_data
WHERE gender IS NOT NULL
GROUP BY usertype, gender
ORDER BY count(gender);


/*What percentage of each gender are customers or subscribers? */
WITH gender_counts AS 
(
   SELECT 
   gender,
   usertype,
   COUNT(trip_id) AS trip_count,
   SUM(COUNT(trip_id)) OVER (PARTITION BY gender) AS total_trips
   FROM 
   bikeshare_data
	WHERE gender IS NOT NULL
   GROUP BY 
   gender, usertype
)
SELECT 
gender,
usertype,
ROUND(trip_count / total_trips * 100, 2) AS percent_of_gender
FROM 
gender_counts
WHERE gender IS NOT NULL
ORDER BY 
gender, usertype;

/*What percentage of each usertype are men or women */
WITH gender_counts AS 
(
   SELECT 
   gender,
   usertype,
   COUNT(trip_id) AS trip_count,
   SUM(COUNT(trip_id)) OVER (PARTITION BY usertype) AS total_trips_by_type
   FROM 
   bikeshare_data
	WHERE gender IS NOT NULL
   GROUP BY 
   gender, usertype
)
SELECT 
usertype,
gender,
ROUND(trip_count / total_trips_by_type * 100, 2) AS percent_of_usertype
FROM 
gender_counts
ORDER BY 
usertype, gender;

/*Count the number of trips taken before noon */
SELECT usertype, COUNT(trip_id) AS trips_before_noon
FROM bikeshare_data
WHERE CAST(start_time AS TIME) < '12:00:00'::TIME
GROUP BY usertype;