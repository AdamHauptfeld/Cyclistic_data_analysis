-- Table: public.bikeshare_data

-- DROP TABLE IF EXISTS public.bikeshare_data;

CREATE TABLE IF NOT EXISTS public.bikeshare_data
(
    trip_id integer,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    trip_length integer,
    day_of_week character varying(255) COLLATE pg_catalog."default",
    from_station_id integer,
    from_station_name character varying(255) COLLATE pg_catalog."default",
    to_station_id integer,
    to_station_name character varying(255) COLLATE pg_catalog."default",
    usertype character varying(255) COLLATE pg_catalog."default",
    gender character varying(255) COLLATE pg_catalog."default",
    birthyear integer
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.bikeshare_data
    OWNER to postgres;