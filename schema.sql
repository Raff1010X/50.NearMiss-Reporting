--
-- PostgreSQL database dump
--

-- Dumped from database version 14.3
-- Dumped by pg_dump version 14.3

-- Started on 2022-09-28 05:52:28

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- TOC entry 3509 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 238 (class 1255 OID 27243)
-- Name: x_check_user_password(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_check_user_password(json) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE 
user_email text:= x_trym(($1::json->'email')::text);
user_password text:= x_trym(($1::json->'password')::text);
_user_id text;
BEGIN
SELECT user_id INTO _user_id
FROM users
WHERE email = user_email
  AND password = crypt(user_password, password);
RETURN (
  SELECT CASE
      WHEN _user_id IS NOT NULL THEN _user_id
      ELSE 'false'
    END
);
END;
$_$;


--
-- TOC entry 239 (class 1255 OID 27244)
-- Name: x_check_user_password(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_check_user_password(user_email text, user_password text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE _user_id text;
BEGIN
SELECT user_id INTO _user_id
FROM users
WHERE email = user_email
  AND password = crypt(user_password, password);
RETURN (
  SELECT CASE
      WHEN _user_id IS NOT NULL THEN _user_id
      ELSE 'false'
    END
);
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 210 (class 1259 OID 27245)
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    comment_id integer NOT NULL,
    report_id integer NOT NULL,
    user_id uuid NOT NULL,
    comment character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


--
-- TOC entry 211 (class 1259 OID 27249)
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reports (
    report_id integer NOT NULL,
    user_id uuid,
    created_at date DEFAULT CURRENT_DATE,
    department_id integer,
    place character varying(1024),
    date date,
    hour time without time zone,
    threat_id integer,
    threat character varying(1024),
    consequence_id integer,
    consequence character varying(1024),
    actions character varying(1024),
    photo character varying(255),
    execution_limit date,
    executed_at date
);


--
-- TOC entry 212 (class 1259 OID 27255)
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255) NOT NULL,
    password character varying NOT NULL,
    role_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone,
    visited_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0),
    password_updated character varying,
    is_active boolean DEFAULT true NOT NULL,
    department_id integer NOT NULL,
    reset_token character varying
);


--
-- TOC entry 213 (class 1259 OID 27264)
-- Name: comments_all; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.comments_all AS
 SELECT u.email AS "Autor",
    c.comment AS "Wpis",
    c.created_at AS "Data",
    r.report_id AS "ID raportu",
    c.comment_id AS "Numer komentarza"
   FROM ((public.comments c
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.reports r USING (report_id))
  ORDER BY c.comment;


--
-- TOC entry 240 (class 1255 OID 27269)
-- Name: x_comment(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_comment(_json json) RETURNS SETOF public.comments_all
    LANGUAGE plpgsql
    AS $_$
DECLARE
  id_komentarza text := (x_trym(($1::json->'comment_id') :: text));
BEGIN
  return QUERY EXECUTE 'SELECT * FROM comments_all WHERE "Numer komentarza" = ''' || id_komentarza || ''' ORDER BY "ID raportu";';
END;
$_$;


--
-- TOC entry 242 (class 1255 OID 27270)
-- Name: x_comment_create(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_comment_create(_json json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _report_id integer := (x_trym(($1::json->'Numer zgloszenia')::text))::integer;
_user_id text := (
  SELECT user_id
  FROM users
  WHERE email = (
      (x_trym(($1::json->'Adres email')::text))::character varying(50)
    )
);
_comment text := x_trym(($1::json->'Komentarz')::text);
_query text := 'INSERT INTO comments (
            report_id,
            user_id,
            comment
          ) VALUES (
            ' || _report_id || ',
            ''' || _user_id || ''',
            ''' || _comment || '''
          ) RETURNING comment_id;';
_result integer;
BEGIN execute _query into _result;
return _result;


END;
$_$;


--
-- TOC entry 246 (class 1255 OID 27271)
-- Name: x_comment_delete(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_comment_delete(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _comment_id integer := (x_trym(($1::json->'comment_id')::text))::integer;
_query text := 'DELETE FROM comments WHERE comment_id = ' || _comment_id || ' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 247 (class 1255 OID 27272)
-- Name: x_comment_update(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_comment_update(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _comment_id integer := (x_trym(($1::json->'comment_id')::text))::integer;
_comment text := x_trym(($1::json->'Komentarz')::text);
_query text := 'UPDATE comments SET
            comment = ''' || _comment || '''
          WHERE comment_id = ' || _comment_id || '
          RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 248 (class 1255 OID 27273)
-- Name: x_comments_by_user(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_comments_by_user(_json json) RETURNS SETOF public.comments_all
    LANGUAGE plpgsql
    AS $_$
DECLARE
  email text := (x_trym(($1::json->'user_email') :: text));
BEGIN
  return QUERY EXECUTE 'SELECT * FROM comments_all WHERE "Autor" = ''' || email || ''' ORDER BY "ID raportu";';
END;
$_$;


--
-- TOC entry 255 (class 1255 OID 27274)
-- Name: x_comments_to_report(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_comments_to_report(_json json) RETURNS SETOF public.comments_all
    LANGUAGE plpgsql
    AS $_$
DECLARE
  _report_id text := (x_trym(($1::json->'report_id') :: text));
BEGIN
  return QUERY EXECUTE 'SELECT * FROM comments_all WHERE "ID raportu" = ' || _report_id || ' ORDER BY "Data";';
END;
$_$;


--
-- TOC entry 258 (class 1255 OID 27275)
-- Name: x_copy_data(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_copy_data() RETURNS integer
    LANGUAGE plpgsql
    AS $$ BEGIN FOR i IN 1..500 LOOP
INSERT INTO reports (
    user_id,
    created_at,
    department_id,
    place,
    date,
    hour,
    threat_id,
    threat,
    consequence_id,
    consequence,
    actions,
    photo,
    execution_limit,
    executed_at
  )
VALUES (
    (
      SELECT user_id
      FROM users
      WHERE email = (
          SELECT user_id
          FROM reports_raw
          WHERE report_id = i
        )
    ),
    (
      SELECT created_at
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT department_id
      FROM departments
      WHERE department = (
          SELECT department_id
          FROM reports_raw
          WHERE report_id = i
        )
    ),
    (
      SELECT place
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT date
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT hour
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT threat_id
      FROM threats
      WHERE threat = (
          SELECT threat_id
          FROM reports_raw
          WHERE report_id = i
        )
    ),
    (
      SELECT threat
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT consequence_id
      FROM consequences
      WHERE consequence = (
          SELECT consequence_id
          FROM reports_raw
          WHERE report_id = i
        )
    ),
    (
      SELECT consequence
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT actions
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT photo
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT execution_limit
        FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT executed_at
      FROM reports_raw
      WHERE report_id = i
    )
  );
END LOOP;
RETURN 1;
END;
$$;


--
-- TOC entry 259 (class 1255 OID 27276)
-- Name: x_department_create(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_department_create(_json json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _department text := x_trym(($1::json->'department')::text);
_query text := 'INSERT INTO departments (department) 
          VALUES (''' || _department || ''') RETURNING department_id;';
_result integer;
BEGIN execute _query into _result;
return _result;


END;
$_$;


--
-- TOC entry 260 (class 1255 OID 27277)
-- Name: x_department_delete(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_department_delete(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _department_id text := x_trym(($1::json->'department_id')::text);
_query text := 'DELETE FROM departments WHERE department_id = ''' || _department_id || ''' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 261 (class 1255 OID 27278)
-- Name: x_department_update(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_department_update(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _department_id text := x_trym(($1::json->'department_id')::text);
_department text := x_trym(($1::json->'department')::text);
_query text := 'UPDATE departments SET
           department = ''' || _department || '''
          WHERE department_id = ''' || _department_id || '''
          RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 262 (class 1255 OID 27279)
-- Name: x_function_create(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_function_create(_json json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _function text := x_trym(($1::json->'function')::text);
_query text := 'INSERT INTO functions (function_name) 
          VALUES (''' || _function || ''') RETURNING function_id;';
_result integer;
BEGIN execute _query into _result;
return _result;


END;
$_$;


--
-- TOC entry 263 (class 1255 OID 27280)
-- Name: x_function_delete(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_function_delete(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _function_id text := x_trym(($1::json->'function_id')::text);
_query text := 'DELETE FROM functions WHERE function_id = ''' || _function_id || ''' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 241 (class 1255 OID 27281)
-- Name: x_function_update(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_function_update(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _function_id text := x_trym(($1::json->'function_id')::text);
_function text := x_trym(($1::json->'function')::text);
_query text := 'UPDATE functions SET
           function_name = ''' || _function || '''
          WHERE function_id = ''' || _function_id || '''
          RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 264 (class 1255 OID 27282)
-- Name: x_manager_create(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_manager_create(_json json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _function_id text := (
    SELECT function_id
    FROM functions
    WHERE function_name = (
        (x_trym(($1::json->'function')::text))::character varying(255)
      )
  );
_user_id text := (
  SELECT user_id
  FROM users
  WHERE email = (
      (x_trym(($1::json->'email')::text))::character varying(255)
    )
);
_query text := 'INSERT INTO managers (
            function_id,
            user_id
          ) VALUES (
            ''' || _function_id || ''',
            ''' || _user_id || '''
          ) RETURNING manager_id;';
_result integer;
BEGIN execute _query into _result;
RETURN _result;


END;
$_$;


--
-- TOC entry 265 (class 1255 OID 27283)
-- Name: x_manager_delete(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_manager_delete(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _manager_id integer := (x_trym(($1::json->'manager_id')::text))::integer;
_query text := 'DELETE FROM managers WHERE manager_id = ' || _manager_id || ' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
RETURN _result;





END;
$_$;


--
-- TOC entry 266 (class 1255 OID 27284)
-- Name: x_manager_update(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_manager_update(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _manager_id integer := (x_trym(($1::json->'manager_id')::text))::integer;
_function_id text := (
  SELECT function_id
  FROM functions
  WHERE function_name = (
      (x_trym(($1::json->'function')::text))::character varying(255)
    )
);
_user_id text := (
  SELECT user_id
  FROM users
  WHERE email = (
      (x_trym(($1::json->'email')::text))::character varying(50)
    )
);
_query text := 'UPDATE managers SET
        function_id = ''' || _function_id || ''',
        user_id = ''' || _user_id || '''
      WHERE manager_id = ' || _manager_id || '
      RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
RETURN _result;





END;
$_$;


--
-- TOC entry 214 (class 1259 OID 27285)
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    department_id integer NOT NULL,
    department character varying(50) NOT NULL
);


--
-- TOC entry 215 (class 1259 OID 27288)
-- Name: functions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.functions (
    function_id integer NOT NULL,
    function_name character varying(50) NOT NULL
);


--
-- TOC entry 216 (class 1259 OID 27291)
-- Name: managers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.managers (
    manager_id integer NOT NULL,
    function_id integer NOT NULL,
    user_id uuid NOT NULL
);


--
-- TOC entry 217 (class 1259 OID 27294)
-- Name: managers_emails; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.managers_emails AS
 SELECT d.department AS "Dział",
    u.email AS "Adres email",
    m.manager_id AS "ID",
    f.function_name AS "Funkcja"
   FROM (((public.managers m
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.departments d USING (department_id))
     LEFT JOIN public.functions f USING (function_id))
  ORDER BY d.department;


--
-- TOC entry 267 (class 1255 OID 27299)
-- Name: x_managers_emails(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_managers_emails(json) RETURNS SETOF public.managers_emails
    LANGUAGE plpgsql
    AS $_$ 
BEGIN 
  IF ($1::json->>'department_name')::text IS NULL THEN
    RETURN QUERY
    SELECT *
    FROM managers_emails;
  ELSE
    RETURN QUERY
    SELECT *
    FROM managers_emails
    WHERE "Dział" ILIKE ($1::json->>'department_name')::text;
  END IF;
END $_$;


--
-- TOC entry 268 (class 1255 OID 27300)
-- Name: x_report_create(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_report_create(_json json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _user_id text := (
    SELECT user_id
    FROM users
    WHERE email ILIKE x_trym(($1::json->'Zgłaszający')::text)
  );
_department_id integer := (
  SELECT department_id
  FROM departments
  WHERE department ILIKE x_trym(($1::json->'Dział')::text)
);
_place text := x_trym(($1::json->'Miejsce')::text);
_date text := ($1::json->'Data zdarzenia');
_hour text := x_trym(($1::json->'Godzina zdarzenia')::text);
_threat_id integer := (
  SELECT threat_id
  FROM threats
  WHERE threat ILIKE x_trym(($1::json->'Zagrożenie')::text)
);
_threat text := x_trym(($1::json->'Opis Zagrożenia')::text);
_consequence_id integer := (
  SELECT consequence_id
  FROM consequences
  WHERE consequence ILIKE x_trym(($1::json->'Konsekwencje')::text)
);
_consequence text := x_trym(($1::json->'Skutek')::text);
_actions text := x_trym(($1::json->'Działania do wykonania')::text);
_photo text := x_trym(($1::json->'Zdjęcie')::text);
_execution_limit text := (current_date + (70 / _consequence_id)::integer)::text;
_query text := 'INSERT INTO reports(
            user_id,
            department_id,
            place,
            date,
            hour,
            threat_id,
            threat,
            consequence_id,
            consequence,
            actions,
            photo,
            execution_limit
          ) VALUES (
            ''' || _user_id || ''',
            ' || _department_id || ',
            ''' || _place || ''',
            ''' || _date || ''',
            ''' || _hour || ''',
            ' || _threat_id || ',
            ''' || _threat || ''',
            ' || _consequence_id || ',
            ''' || _consequence || ''',
            ''' || _actions || ''',
            ''' || _photo || ''',
            ''' || _execution_limit || '''
          ) RETURNING report_id;';
_result integer;
BEGIN execute _query into _result;
RETURN _result;


END;
$_$;


--
-- TOC entry 269 (class 1255 OID 27301)
-- Name: x_report_delete(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_report_delete(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _report_id integer := x_trym(($1::json->'report_id')::text)::integer;
_query text := 'DELETE FROM reports WHERE report_id = ' || _report_id || ' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
RETURN _result;





END;
$_$;


--
-- TOC entry 270 (class 1255 OID 27302)
-- Name: x_report_executed(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_report_executed(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _report_id integer := x_trym(($1::json->'report_id')::text)::integer;
_executed_at text := (current_date)::text;
_query text := 'UPDATE reports SET
            executed_at = ''' || _executed_at || '''
          WHERE report_id = ' || _report_id || '
          RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
RETURN _result;
END;
$_$;


--
-- TOC entry 271 (class 1255 OID 27303)
-- Name: x_report_update(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_report_update(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _report_id integer := x_trym(($1::json->'report_id')::text)::integer;
_department_id integer := (
  SELECT department_id
  FROM departments
  WHERE department = (
      (x_trym(($1::json->'Dział')::text))::character varying(50)
    )
);
_place text := x_trym(($1::json->'Miejsce')::text);
_date text := x_trym(($1::json->'Data zdarzenia')::text);
_hour text := x_trym(($1::json->'Godzina zdarzenia')::text);
_threat_id integer := (
  SELECT threat_id
  FROM threats
  WHERE threat = (
      (x_trym(($1::json->'Zagrożenie')::text))::character varying(50)
    )
);
_threat text := x_trym(($1::json->'Opis Zagrożenia')::text);
_consequence_id integer := (
  SELECT consequence_id
  FROM consequences
  WHERE consequence = (
      (x_trym(($1::json->'Konsekwencje')::text))::character varying(50)
    )
);
_consequence text := x_trym(($1::json->'Skutek')::text);
_actions text := x_trym(($1::json->'Działania do wykonania')::text);
_photo text := x_trym(($1::json->'Zdjęcie')::text);
_execution_limit text := (
  current_date + (70 / _consequence_id)::integer
)::text;
_query text := 'UPDATE reports SET
            department_id = ' || _department_id || ',
            place = ''' || _place || ''',
            date = ''' || _date || ''',
            hour = ''' || _hour || ''',
            threat_id = ' || _threat_id || ',
            threat = ''' || _threat || ''',
            consequence_id = ' || _consequence_id || ',
            consequence = ''' || _consequence || ''',
            actions = ''' || _actions || ''',
            photo = ''' || _photo || ''',
            execution_limit = ''' || _execution_limit || '''
          WHERE report_id = ' || _report_id || '
          RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
RETURN _result;





END;
$_$;


--
-- TOC entry 218 (class 1259 OID 27304)
-- Name: consequences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consequences (
    consequence_id integer NOT NULL,
    consequence character varying(50) NOT NULL
);


--
-- TOC entry 219 (class 1259 OID 27307)
-- Name: threats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.threats (
    threat_id integer NOT NULL,
    threat character varying(50) NOT NULL
);


--
-- TOC entry 220 (class 1259 OID 27310)
-- Name: reports_all; Type: VIEW; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.reports_all AS
 SELECT r.report_id AS "Numer zgłoszenia",
    u.email AS "Zgłaszający",
    r.created_at AS "Data utworzenia",
    d.department AS "Dział",
    r.place AS "Miejsce",
    r.date AS "Data zdarzenia",
    r.hour AS "Godzina zdarzenia",
    t.threat AS "Zagrożenie",
    r.threat AS "Opis Zagrożenia",
    r.consequence AS "Skutek",
    c.consequence AS "Konsekwencje",
    r.actions AS "Działania do wykonania",
    r.photo AS "Zdjęcie",
    r.execution_limit AS "Czas na realizację",
    r.executed_at AS "Data wykonania",
        CASE
            WHEN (((r.executed_at)::text = ''::text) IS NOT FALSE) THEN 'Niewykonane'::text
            ELSE 'Wykonane'::text
        END AS "Status"
   FROM ((((public.reports r
     LEFT JOIN public.departments d USING (department_id))
     LEFT JOIN public.threats t USING (threat_id))
     LEFT JOIN public.consequences c USING (consequence_id))
     LEFT JOIN public.users u USING (user_id));


--
-- TOC entry 272 (class 1255 OID 27315)
-- Name: x_reports_all(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_reports_all(json) RETURNS SETOF public.reports_all
    LANGUAGE plpgsql
    AS $_$
DECLARE numer text := CASE
    WHEN ($1::json->>'report_id') IS NULL THEN '"Numer zgłoszenia" IS NOT NULL'
    ELSE (
      ' "Numer zgłoszenia" = ' || ($1::json->>'report_id')
    )
  END;
zgłaszający text := CASE
  WHEN ($1::json->>'zgłaszający') IS NULL THEN ''
  ELSE (
    ' AND "Zgłaszający" ILIKE ''%%' || ($1::json->>'zgłaszający') || '%%'''
  )
END;
dział text := CASE
  WHEN ($1::json->>'dział') IS NULL THEN ''
  ELSE (
    ' AND "Dział" ILIKE ''%%' || ($1::json->>'dział') || '%%'''
  )
END;
miejsce text := CASE
  WHEN ($1::json->>'miejsce') IS NULL THEN ''
  ELSE (
    ' AND "Miejsce" ILIKE ''%%' || ($1::json->>'miejsce') || '%%'''
  )
END;
data_od text := CASE
  WHEN ($1::json->>'from') IS NULL THEN ''
  ELSE (
    ' AND "Data zdarzenia" >= ''' || ($1::json->>'from') || ''''
  )
END;
data_do text := CASE
  WHEN ($1::json->>'to') IS NULL THEN ''
  ELSE (
    ' AND "Data zdarzenia" <= ''' || ($1::json->>'to') || ''''
  )
END;
zagrożenie text := CASE
  WHEN ($1::json->>'zagrożenie') IS NULL THEN ''
  ELSE (
    ' AND "Zagrożenie" ILIKE ''%%' || ($1::json->>'zagrożenie') || '%%'''
  )
END;
opis text := CASE
  WHEN ($1::json->>'opis') IS NULL THEN ''
  ELSE (
    ' AND "Opis Zagrożenia" ILIKE ''%%' || ($1::json->>'opis') || '%%'''
  )
END;
skutek text := CASE
  WHEN ($1::json->>'skutek') IS NULL THEN ''
  ELSE (
    ' AND "Skutek" ILIKE ''%%' || ($1::json->>'skutek') || '%%'''
  )
END;
działania text := CASE
  WHEN ($1::json->>'działania') IS NULL THEN ''
  ELSE (
    ' AND "Działania do wykonania" ILIKE ''%%' || ($1::json->>'działania') || '%%'''
  )
END;
konsekwencje text := CASE
  WHEN ($1::json->>'konsekwencje') IS NULL THEN ''
  ELSE (
    ' AND "Konsekwencje" ILIKE ''%%' || ($1::json->>'konsekwencje') || '%%'''
  )
END;
_status text := CASE
  WHEN ($1::json->>'status') IS NULL THEN ''
  ELSE (
    ' AND "Status" LIKE ''%%' || ($1::json->>'status') || '%%'''
  )
END;
_order text := CASE
  WHEN ($1::json->>'order') IS NULL THEN ' '
  ELSE (
    ' ORDER BY "' || ($1::json->>'order' || '"')
  )
END;
_desc text := CASE
  WHEN ($1::json->>'desc') IS NULL
  OR ($1::json->>'order') IS NULL THEN ''
  ELSE ' DESC'
END;
_order2 text := CASE
  WHEN ($1::json->>'order') IS NULL THEN ' '
  ELSE (', "Numer zgłoszenia"')
END;
_limit text := CASE
  WHEN ($1::json->>'limit') IS NULL THEN ' '
  ELSE (' LIMIT ' || ($1::json->>'limit')::text)
END;
_offset text := CASE
  WHEN ($1::json->>'offset') IS NULL THEN ' '
  ELSE (' OFFSET ' || ($1::json->>'offset')::text)
END;
query text := 'SELECT * FROM reports_all WHERE ' || numer || zgłaszający || dział || miejsce || data_od || data_do || zagrożenie || opis || skutek || działania || konsekwencje || _status || _order || _desc || _order2 || _limit || _offset;
BEGIN RETURN QUERY EXECUTE query;
END $_$;


--
-- TOC entry 273 (class 1255 OID 27316)
-- Name: x_reports_all_count(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_reports_all_count(json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE numer text := CASE
    WHEN ($1::json->>'report_id') IS NULL THEN '"Numer zgłoszenia" IS NOT NULL'
    ELSE (
      ' "Numer zgłoszenia" = ' || ($1::json->>'report_id')
    )
  END;
zgłaszający text := CASE
  WHEN ($1::json->>'zgłaszający') IS NULL THEN ''
  ELSE (
    ' AND "Zgłaszający" ILIKE ''%%' || ($1::json->>'zgłaszający') || '%%'''
  )
END;
dział text := CASE
  WHEN ($1::json->>'dział') IS NULL THEN ''
  ELSE (
    ' AND "Dział" ILIKE ''%%' || ($1::json->>'dział') || '%%'''
  )
END;
miejsce text := CASE
  WHEN ($1::json->>'miejsce') IS NULL THEN ''
  ELSE (
    ' AND "Miejsce" ILIKE ''%%' || ($1::json->>'miejsce') || '%%'''
  )
END;
data_od text := CASE
  WHEN ($1::json->>'from') IS NULL THEN ''
  ELSE (
    ' AND "Data zdarzenia" >= ''' || ($1::json->>'from') || ''''
  )
END;
data_do text := CASE
  WHEN ($1::json->>'to') IS NULL THEN ''
  ELSE (
    ' AND "Data zdarzenia" <= ''' || ($1::json->>'to') || ''''
  )
END;
zagrożenie text := CASE
  WHEN ($1::json->>'zagrożenie') IS NULL THEN ''
  ELSE (
    ' AND "Zagrożenie" ILIKE ''%%' || ($1::json->>'zagrożenie') || '%%'''
  )
END;
opis text := CASE
  WHEN ($1::json->>'opis') IS NULL THEN ''
  ELSE (
    ' AND "Opis Zagrożenia" ILIKE ''%%' || ($1::json->>'opis') || '%%'''
  )
END;
skutek text := CASE
  WHEN ($1::json->>'skutek') IS NULL THEN ''
  ELSE (
    ' AND "Skutek" ILIKE ''%%' || ($1::json->>'skutek') || '%%'''
  )
END;
działania text := CASE
  WHEN ($1::json->>'działania') IS NULL THEN ''
  ELSE (
    ' AND "Działania do wykonania" ILIKE ''%%' || ($1::json->>'działania') || '%%'''
  )
END;
konsekwencje text := CASE
  WHEN ($1::json->>'konsekwencje') IS NULL THEN ''
  ELSE (
    ' AND "Konsekwencje" ILIKE ''%%' || ($1::json->>'konsekwencje') || '%%'''
  )
END;
_status text := CASE
  WHEN ($1::json->>'status') IS NULL THEN ''
  ELSE (
    ' AND "Status" LIKE ''%%' || ($1::json->>'status') || '%%'''
  )
END;
counted integer := 0;
query text := 'SELECT COUNT(*) FROM reports_all WHERE ' || numer || zgłaszający || dział || miejsce || data_od || data_do || zagrożenie || opis || skutek || działania || konsekwencje || _status;
BEGIN EXECUTE query INTO counted;
RETURN counted;
END $_$;


--
-- TOC entry 274 (class 1255 OID 27317)
-- Name: x_reports_by_department(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_reports_by_department(_json json) RETURNS TABLE("Dział" character varying, "Liczba zgłoszeń przez dział" integer)
    LANGUAGE plpgsql
    AS $_$
DECLARE data_od text := CASE
    WHEN ($1::json->>'from') IS NULL THEN ''
    ELSE (
      'WHERE r.created_at >= ''' || ($1::json->>'from') || ''''
    )
  END;
data_do text := CASE
  WHEN ($1::json->>'to') IS NULL THEN ''
  ELSE (
    ' AND r.created_at <= ''' || ($1::json->>'to') || ''''
  )
END;
_query text := 'SELECT d.department,
      count(u.department_id)::integer AS "Liczba zgłoszeń przez dział"
    FROM reports r
      LEFT JOIN users u USING (user_id)
      LEFT JOIN departments d ON ((u.department_id = d.department_id))
    ' || data_od || data_do || '
    GROUP BY d.department
    ORDER BY 2 DESC';
BEGIN RETURN QUERY EXECUTE _query;
END $_$;


--
-- TOC entry 275 (class 1255 OID 27318)
-- Name: x_reports_stats(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_reports_stats(_json json) RETURNS TABLE("Liczba zgłoszeń" integer, "Liczba zgłoszeń wykonanych" integer, "Procent zgłoszeń wykonanych" integer)
    LANGUAGE plpgsql
    AS $_$
DECLARE data_od text := CASE
    WHEN ($1::json->>'from') IS NULL THEN ''
    ELSE (
      'WHERE "Data utworzenia" >= ''' || ($1::json->>'from') || ''''
    )
  END;
data_do text := CASE
  WHEN ($1::json->>'to') IS NULL THEN ''
  ELSE (
    ' AND "Data utworzenia" <= ''' || ($1::json->>'to') || ''''
  )
END;
_query text := 'SELECT
    count(r."Dział")::integer AS "Liczba zgłoszeń",
    count(r."Data wykonania")::integer AS "Liczba zgłoszeń wykonanych",
    (round((((count(r."Data wykonania")) :: numeric / (count(r."Dział")) :: numeric) * (100) :: numeric))) :: integer AS "Procent zgłoszeń wykonanych"
  FROM
    reports_all r
    ' || data_od || data_do;
BEGIN RETURN QUERY EXECUTE _query;
END $_$;


--
-- TOC entry 276 (class 1255 OID 27319)
-- Name: x_reports_to_department(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_reports_to_department(_json json) RETURNS TABLE("Dział" character varying, "Liczba zgłoszeń" integer, "Liczba zgłoszeń wykonanych" integer, "Procent zgłoszeń wykonanych" integer)
    LANGUAGE plpgsql
    AS $_$
DECLARE data_od text := CASE
    WHEN ($1::json->>'from') IS NULL THEN ''
    ELSE (
      'WHERE "Data utworzenia" >= ''' || ($1::json->>'from') || ''''
    )
  END;
data_do text := CASE
  WHEN ($1::json->>'to') IS NULL THEN ''
  ELSE (
    ' AND "Data utworzenia" <= ''' || ($1::json->>'to') || ''''
  )
END;
_query text := 'SELECT
    r."Dział",
    count(r."Dział")::integer AS "Liczba zgłoszeń",
    count(r."Data wykonania")::integer AS "Liczba zgłoszeń wykonanych",
    (round((((count(r."Data wykonania")) :: numeric / (count(r."Dział")) :: numeric) * (100) :: numeric))) :: integer AS "Procent zgłoszeń wykonanych"
  FROM
    reports_all r
    ' || data_od || data_do || '
  GROUP BY
    1
  ORDER BY
    2 DESC';
BEGIN RETURN QUERY EXECUTE _query;
END $_$;


--
-- TOC entry 277 (class 1255 OID 27320)
-- Name: x_trym(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_trym(_text text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    return TRIM('"' FROM _text);
END
$$;


--
-- TOC entry 278 (class 1255 OID 27321)
-- Name: x_update_user_password_by_token(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_update_user_password_by_token(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _reset_token text := x_trym(($1::json->'reset_token')::text);
_password text;
_result boolean;
BEGIN
SELECT password_updated INTO _password
FROM users
WHERE reset_token = _reset_token;
UPDATE users
SET password = _password,
  password_updated = NULL,
  is_active = true,
  reset_token = NULL,
  updated_at = now()::timestamp
WHERE reset_token = _reset_token
RETURNING true INTO _result;
RETURN _result;


END;
$_$;


--
-- TOC entry 221 (class 1259 OID 27322)
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    role_id integer NOT NULL,
    role character varying(50) NOT NULL
);


--
-- TOC entry 222 (class 1259 OID 27325)
-- Name: users_all; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.users_all AS
 SELECT DISTINCT u.email AS "Adres email",
        CASE
            WHEN ((r.role)::text = 'admin'::text) THEN 'Administrator'::text
            WHEN ((r.role)::text = 'superuser'::text) THEN 'Super użytkownik'::text
            ELSE 'Użytkownik'::text
        END AS "Rola użytkownika",
    u.created_at AS "Data utworzenia",
        CASE
            WHEN (u.is_active = true) THEN 'Tak'::text
            ELSE 'Nie'::text
        END AS "Aktywny",
    d.department AS "Dział",
    u.user_id AS "ID użytkownika",
    u.updated_at AS "Data aktualizacji",
    u.reset_token AS "Token resetowania hasła"
   FROM (((public.users u
     LEFT JOIN public.roles r USING (role_id))
     LEFT JOIN public.managers m USING (user_id))
     LEFT JOIN public.departments d USING (department_id))
  ORDER BY d.department;


--
-- TOC entry 279 (class 1255 OID 27330)
-- Name: x_user_by_uuid(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_user_by_uuid(json) RETURNS SETOF public.users_all
    LANGUAGE plpgsql
    AS $_$
DECLARE 
query text := 'SELECT * FROM users_all WHERE "ID użytkownika" = ''' || ($1::json->>'user_id') || '''';
BEGIN RETURN QUERY EXECUTE query;
END;
$_$;


--
-- TOC entry 280 (class 1255 OID 27331)
-- Name: x_user_create(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_user_create(_json json) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE _email text := x_trym(($1::json->'email')::text);
_password_updated text := crypt(
  x_trym(($1::json->'password')::text),
  gen_salt('bf')
);
_password text := MD5(random()::text);
_is_active boolean := false;
_role_id integer := CASE
  WHEN ($1::json->>'email') LIKE '%@trendglass.pl' THEN 2
  ELSE 1
END CASE
;
_department_id integer := CASE
  WHEN ($1::json->>'department') IS NULL THEN 1
  ELSE (
    SELECT department_id
    FROM departments
    WHERE department = (
        (x_trym(($1::json->'department')::text))::character varying(50)
      )
  )
END;
_query text := 'INSERT INTO users (
            email,
            password,
            role_id,
            department_id,
            is_active,
            password_updated
          ) VALUES (
            ''' || _email || ''',
            ''' || _password || ''',
            ' || _role_id || ',
            ' || _department_id || ',
            ' || _is_active || ',
            ''' || _password_updated || '''
          ) RETURNING user_id;';
_result text;
BEGIN execute _query into _result;
return _result;
EXCEPTION
WHEN others THEN return false;
END;
$_$;


--
-- TOC entry 281 (class 1255 OID 27332)
-- Name: x_user_delete(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_user_delete(json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _user_id text := x_trym(($1::json->'user_id')::text);
_query text := 'DELETE FROM users WHERE user_id = ''' || _user_id || ''' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 282 (class 1255 OID 27333)
-- Name: x_user_number_of_raports(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_user_number_of_raports(json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _number_of_reports integer := 1;
_email text := ($1::json->>'email');
BEGIN
SELECT count(*)
FROM reports r
  LEFT JOIN users u ON r.user_id = u.user_id
WHERE u.email = _email INTO _number_of_reports;
RETURN _number_of_reports;
END;
$_$;


--
-- TOC entry 283 (class 1255 OID 27334)
-- Name: x_user_number_of_reports(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_user_number_of_reports(json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _number_of_reports integer := 0;
_user_id uuid := ($1::json->>'user_id');
BEGIN
SELECT count(*)
FROM reports
WHERE user_id = _user_id
 INTO _number_of_reports;
RETURN _number_of_reports;
END;
$_$;


--
-- TOC entry 284 (class 1255 OID 27335)
-- Name: x_user_update(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_user_update(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _user_id text := x_trym(($1::json->'user_id')::text);
_email text := CASE
  WHEN ($1::json->>'email') IS NULL THEN ' '
  ELSE (
    'email = ''' || x_trym(($1::json->'email')::text) || ''','
  )
END;
_password text := CASE
  WHEN ($1::json->>'password') IS NULL THEN ' '
  ELSE (
    'password = ''' || crypt(
      x_trym(($1::json->'password')::text),
      gen_salt('bf')
    ) || ''','
  )
END;
_role_id text := CASE
  WHEN ($1::json->>'role') IS NULL THEN ' '
  ELSE (
    'role_id = ' || (
      SELECT role_id
      FROM roles
      WHERE role = (
          (x_trym(($1::json->'role')::text))::character varying(50)
        )
    ) || ','
  )
END;
_department_id text := CASE
  WHEN ($1::json->>'department') IS NULL THEN ' '
  ELSE (
    'department_id = ' || (
      SELECT department_id
      FROM departments
      WHERE department = (
          (x_trym(($1::json->'department')::text))::character varying(50)
        )
    ) || ','
  )
END;
_updated_at text := CASE
  WHEN ($1::json->>'reset_token') IS NULL THEN 'updated_at = NULL '
  ELSE ('updated_at = now()::timestamp ')
END;
_password_updated text := CASE
  WHEN ($1::json->>'password_updated') IS NULL THEN ' '
  ELSE (
    'password_updated = ''' || crypt(
      x_trym(($1::json->'password_updated')::text),
      gen_salt('bf')
    ) || ''','
  )
END;
_reset_token text := CASE
  WHEN ($1::json->>'reset_token') IS NULL THEN ' '
  ELSE (
    'reset_token = ''' || x_trym(($1::json->'reset_token')::text) || ''','
  )
END;
_is_active text := CASE
  WHEN ($1::json->>'is_active') IS NULL THEN ' '
  ELSE (
    'is_active = ' || x_trym(($1::json->'is_active')::text) || ','
  )
END;
_query text := 'UPDATE users SET
            ' || _email || '
            ' || _password || '
            ' || _password_updated || '
            ' || _role_id || '
            ' || _is_active || '
            ' || _department_id || '
            ' || _reset_token || '
            ' || _updated_at || '
          WHERE user_id = ''' || _user_id || '''
          RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 285 (class 1255 OID 27336)
-- Name: x_users_all(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_users_all(json) RETURNS SETOF public.users_all
    LANGUAGE plpgsql
    AS $_$
DECLARE _order text := CASE
    WHEN ($1::json->>'order') IS NULL THEN ' '
    ELSE (' ORDER BY "' || ($1::json->>'order' || '"'))
  END;
_desc text := CASE
  WHEN ($1::json->>'desc') IS NULL
  OR ($1::json->>'order') IS NULL THEN ''
  ELSE ' DESC'
END;
_limit text := CASE
  WHEN ($1::json->>'limit') IS NULL THEN ' '
  ELSE (' LIMIT ' || ($1::json->>'limit')::text)
END;
_offset text := CASE
  WHEN ($1::json->>'offset') IS NULL THEN ' '
  ELSE (' OFFSET ' || ($1::json->>'offset')::text)
END;
_email text := CASE
  WHEN ($1::json->>'email') IS NULL THEN ' '
  ELSE (
    'WHERE "Adres email" LIKE ''' || ($1::json->>'email') || '%'''
  )
END;
_reset_token text := CASE
  WHEN ($1::json->>'reset_token') IS NULL THEN ' '
  ELSE (
    'WHERE "Token resetowania hasła" = ''' || ($1::json->>'reset_token') || ''''
  )
END;
_user_id text := CASE
  WHEN ($1::json->>'user_id') IS NULL THEN ' '
  ELSE (
    'WHERE "ID użytkownika" = ''' || ($1::json->>'user_id') || ''''
  )
END;
query text := 'SELECT * FROM users_all ' || _email || _user_id || _reset_token || _order || _desc || _limit || _offset;
BEGIN RETURN QUERY EXECUTE query;
END;
$_$;


--
-- TOC entry 286 (class 1255 OID 27337)
-- Name: x_users_all(integer, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_users_all(_limit integer, _offset integer, _pattern text) RETURNS SETOF public.users_all
    LANGUAGE plpgsql
    AS $$ BEGIN RETURN QUERY
SELECT *
FROM users_all
WHERE "Adres email" ILIKE '%' || _pattern || '%'
LIMIT _limit OFFSET _offset;
END;
$$;


--
-- TOC entry 287 (class 1255 OID 27338)
-- Name: x_users_top_10(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_users_top_10(_json json) RETURNS TABLE(email character varying, "Liczba zgłoszeń" integer, "Liczba zgłoszeń wykonanych" integer, "Liczba zgłoszeń nie wykonanych" integer)
    LANGUAGE plpgsql
    AS $_$
DECLARE from_date text := CASE
    WHEN ($1::json->>'from') IS NULL THEN 'WHERE "date" >= ''1900-01-01'''
    ELSE (
      ' WHERE "date" >= ''' || ($1::json->>'from') || ''''
    )
  END;
to_date text := CASE
  WHEN ($1::json->>'to') IS NULL THEN ''
  ELSE (' AND "date" <= ''' || ($1::json->>'to') || '''')
END;
_query text := 'SELECT
    u.email,
    count(u.email)::integer AS "Liczba zgłoszeń",
    count(
      CASE
        WHEN (r.executed_at IS NOT NULL) THEN 1
        ELSE NULL :: integer
      END
    )::integer AS "Liczba zgłoszeń wykonanych",
    count(
      CASE
        WHEN (r.executed_at IS NULL) THEN 1
        ELSE NULL :: integer
      END
    )::integer AS "Liczba zgłoszeń nie wykonanych"
  FROM
    ( reports r
      LEFT JOIN users u USING (user_id))' || from_date || to_date || '
  GROUP BY
    u.email
  ORDER BY
    (count(u.email)) DESC
  LIMIT
    10';
BEGIN RETURN QUERY EXECUTE _query;
END $_$;


--
-- TOC entry 223 (class 1259 OID 27339)
-- Name: comments_comment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_comment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3510 (class 0 OID 0)
-- Dependencies: 223
-- Name: comments_comment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_comment_id_seq OWNED BY public.comments.comment_id;


--
-- TOC entry 224 (class 1259 OID 27340)
-- Name: consequences_consequence_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.consequences_consequence_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3511 (class 0 OID 0)
-- Dependencies: 224
-- Name: consequences_consequence_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.consequences_consequence_id_seq OWNED BY public.consequences.consequence_id;


--
-- TOC entry 225 (class 1259 OID 27341)
-- Name: departments_department_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departments_department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3512 (class 0 OID 0)
-- Dependencies: 225
-- Name: departments_department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.departments_department_id_seq OWNED BY public.departments.department_id;


--
-- TOC entry 226 (class 1259 OID 27342)
-- Name: departments_top_10; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.departments_top_10 AS
 SELECT d.department,
    count(u.department_id) AS "Liczba zgłoszeń przez dział"
   FROM ((public.reports r
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.departments d ON ((u.department_id = d.department_id)))
  GROUP BY d.department
  ORDER BY (count(u.department_id)) DESC;


--
-- TOC entry 227 (class 1259 OID 27347)
-- Name: functions_function_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.functions_function_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3513 (class 0 OID 0)
-- Dependencies: 227
-- Name: functions_function_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.functions_function_id_seq OWNED BY public.functions.function_id;


--
-- TOC entry 228 (class 1259 OID 27348)
-- Name: managers_manager_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.managers_manager_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3514 (class 0 OID 0)
-- Dependencies: 228
-- Name: managers_manager_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.managers_manager_id_seq OWNED BY public.managers.manager_id;


--
-- TOC entry 229 (class 1259 OID 27349)
-- Name: reports_by_date; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reports_by_date AS
 SELECT to_char((r.date)::timestamp with time zone, 'MM'::text) AS mon,
    EXTRACT(year FROM r.date) AS yyyy,
    d.department,
    count(u.department_id) AS "Liczba zgłoszeń",
        CASE
            WHEN (count(u.department_id) > 4) THEN true
            ELSE false
        END AS "Cel 5 zgłoszeń"
   FROM ((public.reports r
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.departments d ON ((u.department_id = d.department_id)))
  WHERE (r.date <= now())
  GROUP BY (to_char((r.date)::timestamp with time zone, 'MM'::text)), (EXTRACT(year FROM r.date)), d.department
  ORDER BY (EXTRACT(year FROM r.date)) DESC, (to_char((r.date)::timestamp with time zone, 'MM'::text)) DESC, (count(u.department_id)) DESC, d.department;


--
-- TOC entry 230 (class 1259 OID 27354)
-- Name: reports_by_date_done; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reports_by_date_done AS
 SELECT to_char((r.date)::timestamp with time zone, 'MM'::text) AS mon,
    EXTRACT(year FROM r.date) AS yyyy,
    (count(1))::integer AS "Liczba zgłoszeń wykonanych"
   FROM ((public.reports r
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.departments d ON ((u.department_id = d.department_id)))
  WHERE ((r.executed_at IS NOT NULL) AND (r.date <= now()))
  GROUP BY (to_char((r.date)::timestamp with time zone, 'MM'::text)), (EXTRACT(year FROM r.date))
  ORDER BY (EXTRACT(year FROM r.date)) DESC, (to_char((r.date)::timestamp with time zone, 'MM'::text)) DESC;


--
-- TOC entry 231 (class 1259 OID 27359)
-- Name: reports_by_date_post; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reports_by_date_post AS
 SELECT to_char((r.date)::timestamp with time zone, 'MM'::text) AS mon,
    EXTRACT(year FROM r.date) AS yyyy,
    (count(1))::integer AS "Liczba zgłoszeń"
   FROM ((public.reports r
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.departments d ON ((u.department_id = d.department_id)))
  WHERE (r.date <= now())
  GROUP BY (to_char((r.date)::timestamp with time zone, 'MM'::text)), (EXTRACT(year FROM r.date))
  ORDER BY (EXTRACT(year FROM r.date)) DESC, (to_char((r.date)::timestamp with time zone, 'MM'::text)) DESC;


--
-- TOC entry 232 (class 1259 OID 27364)
-- Name: reports_by_department; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reports_by_department AS
 SELECT d.department,
    count(u.department_id) AS "Liczba zgłoszeń przez dział"
   FROM ((public.reports r
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.departments d ON ((u.department_id = d.department_id)))
  WHERE (d.department IS NOT NULL)
  GROUP BY d.department
  ORDER BY (count(u.department_id)) DESC;


--
-- TOC entry 233 (class 1259 OID 27375)
-- Name: reports_report_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reports_report_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3515 (class 0 OID 0)
-- Dependencies: 233
-- Name: reports_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reports_report_id_seq OWNED BY public.reports.report_id;


--
-- TOC entry 234 (class 1259 OID 27376)
-- Name: reports_to_department; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reports_to_department AS
 SELECT r."Dział",
    (count(r."Dział"))::integer AS "Liczba zgłoszeń",
    (count(r."Data wykonania"))::integer AS "Liczba zgłoszeń wykonanych",
    (round((((count(r."Data wykonania"))::numeric / (count(r."Dział"))::numeric) * (100)::numeric)))::integer AS "Procent zgłoszeń wykonanych"
   FROM public.reports_all r
  WHERE (r."Dział" IS NOT NULL)
  GROUP BY r."Dział"
  ORDER BY ((count(r."Dział"))::integer) DESC;


--
-- TOC entry 235 (class 1259 OID 27380)
-- Name: roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3516 (class 0 OID 0)
-- Dependencies: 235
-- Name: roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_role_id_seq OWNED BY public.roles.role_id;


--
-- TOC entry 236 (class 1259 OID 27381)
-- Name: threats_threat_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.threats_threat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3517 (class 0 OID 0)
-- Dependencies: 236
-- Name: threats_threat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.threats_threat_id_seq OWNED BY public.threats.threat_id;


--
-- TOC entry 237 (class 1259 OID 27382)
-- Name: users_top_10; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.users_top_10 AS
 SELECT u.email,
    (count(u.email))::integer AS "Liczba zgłoszeń",
    (count(
        CASE
            WHEN (r.executed_at IS NOT NULL) THEN 1
            ELSE NULL::integer
        END))::integer AS "Liczba zgłoszeń wykonanych",
    (count(
        CASE
            WHEN (r.executed_at IS NULL) THEN 1
            ELSE NULL::integer
        END))::integer AS "Liczba zgłoszeń nie wykonanych"
   FROM (public.reports r
     LEFT JOIN public.users u USING (user_id))
  GROUP BY u.email
  ORDER BY (count(u.email)) DESC
 LIMIT 10;


--
-- TOC entry 3288 (class 2604 OID 27387)
-- Name: comments comment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments ALTER COLUMN comment_id SET DEFAULT nextval('public.comments_comment_id_seq'::regclass);


--
-- TOC entry 3298 (class 2604 OID 27388)
-- Name: consequences consequence_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consequences ALTER COLUMN consequence_id SET DEFAULT nextval('public.consequences_consequence_id_seq'::regclass);


--
-- TOC entry 3295 (class 2604 OID 27389)
-- Name: departments department_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments ALTER COLUMN department_id SET DEFAULT nextval('public.departments_department_id_seq'::regclass);


--
-- TOC entry 3296 (class 2604 OID 27390)
-- Name: functions function_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.functions ALTER COLUMN function_id SET DEFAULT nextval('public.functions_function_id_seq'::regclass);


--
-- TOC entry 3297 (class 2604 OID 27391)
-- Name: managers manager_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.managers ALTER COLUMN manager_id SET DEFAULT nextval('public.managers_manager_id_seq'::regclass);


--
-- TOC entry 3290 (class 2604 OID 27392)
-- Name: reports report_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports ALTER COLUMN report_id SET DEFAULT nextval('public.reports_report_id_seq'::regclass);


--
-- TOC entry 3300 (class 2604 OID 27394)
-- Name: roles role_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN role_id SET DEFAULT nextval('public.roles_role_id_seq'::regclass);


--
-- TOC entry 3299 (class 2604 OID 27395)
-- Name: threats threat_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.threats ALTER COLUMN threat_id SET DEFAULT nextval('public.threats_threat_id_seq'::regclass);


--
-- TOC entry 3487 (class 0 OID 27245)
-- Dependencies: 210
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.comments (comment_id, report_id, user_id, comment, created_at) FROM stdin;
1	5	ddda0f68-9f25-4e69-b62f-95b4b5b1ba6a	Komentarz nowy 2	2022-07-09 14:28:01
2	5	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz nowy 2	2022-07-09 14:30:23
3	5	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz nowy 3333	2022-07-09 14:39:57
4	5	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz	2022-07-09 14:46:11
5	5	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz nowy 3333	2022-07-09 20:46:55
37	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:22:03
38	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:22:39
39	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:22:59
40	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:23:35
41	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:23:47
42	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:23:53
43	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:24:04
44	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:25:29
45	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:26:00
46	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:27:42
47	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:27:54
48	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:28:43
49	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:29:21
50	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:32:58
52	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:43:05
53	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:43:43
54	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:44:20
56	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:11:58
57	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:15:31
58	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:16:24
59	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:18:00
60	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:21:17
61	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:22:06
62	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:26:09
63	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:28:30
64	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:28:47
65	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:32:12
66	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:32:29
67	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:32:41
68	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:35:08
69	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:56:56
70	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:57:20
71	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:57:59
72	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:01:07
73	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:01:18
74	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:03:04
75	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:03:48
76	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:04:27
77	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:09:44
78	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:10:54
79	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:12:22
80	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:13:35
6	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz nowy 2	2022-07-11 20:33:34
51	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz nowy 2222	2022-07-16 18:40:31
\.


--
-- TOC entry 3493 (class 0 OID 27304)
-- Dependencies: 218
-- Data for Name: consequences; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.consequences (consequence_id, consequence) FROM stdin;
1	Bardzo małe
2	Małe
3	Średnie
4	Duże
5	Bardzo duże
\.


--
-- TOC entry 3490 (class 0 OID 27285)
-- Dependencies: 214
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.departments (department_id, department) FROM stdin;
1	Biuro
2	Dekoratornia
3	Formowanie
4	Inny
5	Jakość, BHP i OŚ
6	Konfekcja
7	Magazyn A30
8	Magazyn A31
9	Magazyn butli, częsci, palet, odpady niebezpieczne
10	Magazyn opakowań
11	Magazyn wyrobów
12	Sortownia
13	Technika
14	Utrzymanie ruchu
15	Warsztat
16	Wzory
17	Zestawiarnia
\.


--
-- TOC entry 3491 (class 0 OID 27288)
-- Dependencies: 215
-- Data for Name: functions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.functions (function_id, function_name) FROM stdin;
1	Kierownik administracji
2	Kierowink magazynu butli, cząści, palet...
3	Kierownik magazynu opakowań
4	Kierownik magazynu A30
5	Kierownik magazynu A31
6	Kierownik działu konfekcjonowania
7	Kierownik działu formowania
8	Kierownik działu zestawiarni i topienia
9	Kierownik sortowania
10	Kierownik dekoratorni
11	Kierownik warsztatu
12	Kierownik jakości, BHP i OŚ
13	Kierowink działu wzory
14	Kierownik techniki
15	Kierownik utrzymania ruchu
\.


--
-- TOC entry 3492 (class 0 OID 27291)
-- Dependencies: 216
-- Data for Name: managers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.managers (manager_id, function_id, user_id) FROM stdin;
1	1	eab85052-fedd-4360-8a8c-d2ff48f0f378
2	2	f1fdc277-8503-41b8-aaea-e809a84b298b
3	3	6559d7cb-5868-4911-b0e4-baf0c393cdc3
4	3	ddda0f68-9f25-4e69-b62f-95b4b5b1ba6a
5	4	07774e50-66a1-4f17-95f6-9be17f7a023f
6	4	ddda0f68-9f25-4e69-b62f-95b4b5b1ba6a
7	5	02ee2179-6408-46c9-a003-eefbd9d60a37
8	5	ddda0f68-9f25-4e69-b62f-95b4b5b1ba6a
9	6	758cdd42-c7db-4aa8-b7cc-dbd66f2c9487
10	7	8d5a9bed-f25b-4209-bae6-564b5affcf3c
11	7	9be931ff-ff6d-4e74-a13e-4f44ade6d3ac
12	7	d8090826-dfed-4cce-a67e-aff1682e7e31
13	8	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6
14	8	8d5a9bed-f25b-4209-bae6-564b5affcf3c
15	9	da14c0c1-09a5-42c1-8604-44ff5c8cd747
16	9	95b29d34-ec2f-4ed7-8bc1-1e4fbc4cb0c7
17	10	3025f3ea-78c5-41fb-ba3e-cf7a79a57c0c
18	10	5bc3e952-bef5-4be3-bd25-adbe3dae5164
19	10	568a4817-69a1-4647-a74e-150242618dbe
20	10	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858
21	11	5b869265-65e3-4cdf-a298-a1256d660409
22	12	813c24c3-fc3d-4afe-a8c3-cad54bb8b015
23	13	cd4e0c92-24a5-4921-a22e-41da8c81adf6
24	14	4bae726c-d69c-4667-b489-9897c64257e4
25	15	0eaf92dd-1e90-4134-bd30-47f84907abcb
\.


--
-- TOC entry 3488 (class 0 OID 27249)
-- Dependencies: 211
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reports (report_id, user_id, created_at, department_id, place, date, hour, threat_id, threat, consequence_id, consequence, actions, photo, execution_limit, executed_at) FROM stdin;
111	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-02-15	11	Alejka obok maszyny Kammann przy budowanych na piętrze szatniach na starym magazynie wyrobów gotowych.	2021-02-15	14:00:00	23	zabezpieczająca osobę wypadek tej porównać bok porównać bok spadek stanie wodą sztuki schodów spadającej zniszczenia obrażenia Potknięcieprzewrócenieskaleczenie	3	Wygięty spełnia pozostawiony ominąć widocznym A3 widocznym A3 konstrukcja nieoznakowane naprawiali nam Wyciąganie krańcowym Nieprzymocowane otwartym sortowi połowie	odstającą roboczy dłuższego potencjalnie R10 Niezwłoczne R10 Niezwłoczne oleju karty przykręcenie poprzecznej przez stanu poświęcenie PLEKSY hydrantu śrubę	\N	2021-03-15	2021-12-15
115	e89c35ee-ad74-4fa9-a781-14e8b06c9340	2021-02-18	4	Magazyn palet - palety wystawione do pobrania na sortownię	2021-02-18	10:00:00	23	Narażenie podłogę zwichnięcie pożarem zbiornika wózki zbiornika wózki spiętrowanych widziałem rozdzielni "podwieszonej" paletach ciężki rękawiczka zagrożenie Przerócone	5	moga tlenie aluminiowego potknie frontu wyeliminuje frontu wyeliminuje złączniu długie stabilnej występują leżą rynience następnie oznakowanie doprowadziło krawędzi	proces poprzecznej paletach kasetony przepisów ratunkowym przepisów ratunkowym operatora stosowanie ładowania przyczepy regularnego nieprzestrzeganie natrysku listew czystość ociec	12341.jpg	2021-02-25	\N
7	0fb6b96b-96a8-4a39-a0e2-459511d1c563	2019-08-07	17	Konstrukcja starej zestawiarni przy piecu W1	2019-08-07	16:00:00	0	drabiny uaszkodzenie jednego pracownikami obsługi najprawdopodobnie obsługi najprawdopodobnie nadstawki następnie środków kończyny wyjście gorącym wieczornych uczestniącymi Uswiadomienie	\N	oczywiście butów Zakryty sprzęt pozostałość powstawanie pozostałość powstawanie stołu Operacyjnego najechanie ręczny żyletka dojścia własną fasadę najniższej Trendu	podestu przdstawicielami kanaliki sprężarka otynkowanie cały otynkowanie cały temperaturą szatniach Obudować magazynie spotkanie bieżące charakterystyki Obecna piecu przeciwpożarowego	pozar.jpg	\N	\N
13	ffcf648d-83c7-473e-9355-361e6ec7bcee	2019-09-20	12	R10	2019-09-20	11:00:00	0	sa oprzyrządowania kończyn udziałem zagrożenie Zanieczyszczenie zagrożenie Zanieczyszczenie pod duże stronie co katastrofa która CIĄGŁOŚCI ostrzegawczy Luźno	\N	była wstawia włączeniu Waż pietrze wyskakiwanie pietrze wyskakiwanie panuje rozchodzi minutach wypadła skrzydło strop Zbliżenie szkła tekturowymi złą	ukryty mogą ociekowej montaż dzwon oznakowanym dzwon oznakowanym Przestawienie Przyspawać odbojniki swoich metry kluczowych element odstawianie niezgodny jasnych	DSC_3256_resize_90.jpg	\N	\N
59	0fb6b96b-96a8-4a39-a0e2-459511d1c563	2020-10-12	17	Podest przy piecu W1 - przejście od lewej strony kieszeni zasypowej przy palisadzie w stronę drugiego wziernika. Strefa za zlewnią	2020-10-12	09:00:00	0	uszczerbkiem poślizgu różnych świetle regeneracyjnego maszynki regeneracyjnego maszynki wody kostki obecnym gaszących Wyciek uchwytów śmiertelny R1 produkcji	\N	demontażem rutynowych mate drzwi odprowadzającej folii odprowadzającej folii bądź pakowaniu obsunięta doprowadzające wychodzący którym urządzeniu opuściła regału niedozwolonych	regularnie oznakowane niedozwolonych problem czynnością stabilnym czynnością stabilnym która jezdniowego ostrzegawczej FINANSÓW USZODZONEGO kamizelkę piwnicy ograniczenie uraz bezpośredniego	Inked1602571790549_LI.jpg	\N	\N
88	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-01-12	11	Rampa 0 przy biurze koordynatorów transportu	2021-01-12	14:00:00	21	uszkodzone operatora prawej - samych kubek samych kubek sprzęt co niebezpieczeństwo wpychaniu stanie osobę Zwrócenie podwieszona ma	4	umożliwiających odstaje nadmierną bańkę pulpitem komunikacyjnym pulpitem komunikacyjnym zapalenia podjazdu prawie poruszania ściankach podłoża NIEUŻYTE woda konstrukcji znajdującej	było ustawienie rurę stopni powietrza ruchomych powietrza ruchomych bortnic nachylenia oznaczenie kuchennych w Staranne Naprawić twarzą Skrzynia Prosze	R6podest2.jpg	2021-01-28	2021-12-15
95	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-01-28	11	Paletyzator R7	2021-01-28	07:00:00	26	wpływem co powodującą oosby przekraczający spadające przekraczający spadające zdemontowane uchwytów zatrzymania przechodzącą sufitem wysokości : ją niebezpieczeństwo	3	66 prasa powoduje luzem oznakowanego przepełnione oznakowanego przepełnione wchodzącą podnośnika drugiej osobowy nieoznakowanym Przechodzenie pradem pracownika kartonów rozbicia	opakowań! bokiem to maszynach sąsiedzcwta górnej sąsiedzcwta górnej swobodny elementów odpowiedniej Codzienne ostrożność stęzeń przerwy ponad rozlewów elektrycznych	IMG_20210118_134735_resized_20210118_014948921.jpg	2021-02-25	2021-12-15
18	05e455a5-257b-4339-a4fd-9166edbae5b5	2019-10-08	15	Pomieszczenie magazynu form	2019-10-08	09:00:00	0	potłuczenie itp uszkodzoną mieć podczas prawdopodobieństwo podczas prawdopodobieństwo opakowania naciągnięcie mogło Zdezelowana pochwycenia udziałem uderzeniaprzygniecenia nadstawek kartonów	\N	rzucało DZIAŁANIE ostrych który niebezpieczne postaci niebezpieczne postaci wchodzącą Magazynier nocnej zalane opiłek przechylał "mocowaniu" otwór stoi Nierówna	ścianą oczyścić noszenia Uniesienie przedłużki każdej przedłużki każdej chwytak Pomalować drogach odbierającą ubranie Ładować Poprowadzenie między poinformowanie pracowniakmi	IMG_20191008_094743.jpg	\N	\N
20	e8f02c5a-1ece-4fa6-ae4e-27b9eda20340	2019-10-15	4	Piwnica pod halą produkcyjną	2019-10-15	11:00:00	0	jako wysokosci mogą a stopy lub stopy lub szkłem doprowadzić robić uszkodzeniu skręceniezłamanie skaleczenia będących dłoni- bramą	\N	stroną wytarte zwijania zawór warsztacie znajdującego warsztacie znajdującego konieczna stabilności sygnalizacji polegającą obciążeń laboratorium wpływając gorącego przechylona oleje	kształt taśmy składowanym teren równej streczowane równej streczowane pustą stawiać ostrzegawczej pojemnika dostosowując rozmawiać pracprzeszkolić Opisanie niebezpiecznych postoju	CAM00538.jpg	\N	\N
28	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2019-11-23	3	prasa R9	2019-11-23	10:00:00	0	Poparzenie Możliość wyrobów instalacjiporażenie wstrząsu Uswiadomienie wstrząsu Uswiadomienie pracujące widoczności instalacja przepłukiwania spodować efekcie stanowisko widoczności skręcona	\N	dyscypliny ona stwierdzona ruchomych przebywających sprężone przebywających sprężone odprężarki blachy kamerami gorącego sytuacji widocznym skaleczenia boli uderzyć wyłącznik	natrysk naprawy obciążone ciągi oczomyjkę rozpiętrować oczomyjkę rozpiętrować przepisów przechylenie lewo stopni praktyki opuszczanie ciepło obarierkowany szatni pól	\N	\N	\N
9	07774e50-66a1-4f17-95f6-9be17f7a023f	2019-08-08	7	Magazyn wyrobów gotowych 2 	2019-08-08	11:00:00	0	urządzeń magazynowana widłowego brak Najechanie plus Najechanie plus pracownicy kontrolowanego kostki Utrudniony podłogi gwoździe elektrod zdemontowane pobliżu	\N	powtarzają ale nogą przesunąć zza kawę zza kawę zuzyciu przełożonego 5m Niepoprawne równowagi elektryczne Drobinki przyczyna włączeniu budynku	przewody cieczy składanie oznakowanym przedłużki stawiać przedłużki stawiać narzędzi spawanie Instalacja ruchomą śrubę swobodne rozsypać przechodzenie początku dojścia	\N	\N	\N
29	6ccdb3ad-4df4-4996-b669-792355142621	2019-11-29	1	Biuro działu logistyki wysyłek	2019-11-29	08:00:00	0	widoczny polerce temu oosby routera uszkodzeniu routera uszkodzeniu reagowania zerwania który najprawdopodobnie wpadnięcia wystającego nogi dźwiękowej lampy	\N	śrutu wietrze poziom ztandardowej wykonał przewróciły wykonał przewróciły istnieje utrudniający Zastawiona Jeżeli sytuacji ponownie przemywania jest Niepawidłowo wymieniona	rusztu operatora oczyszczony Kontakt bezpiecznie ruchomą bezpiecznie ruchomą niesprawnego możliwych olej Natychmiast itp dostepęm spiętrowanych sukcesywne niestwarzający Przywierdzenie	\N	\N	\N
42	57b84c80-a067-43b7-98a0-ee22a5411c0e	2020-02-25	3	Produkcja, polerka R1.	2020-02-25	09:00:00	0	składowanie godzinach spiętrowanej elementem znajdującej poprzepalane znajdującej poprzepalane oparzenie pozycji innego rządka ludzi włączeniu awaryjnego stanowiska wyroby	\N	Topiarz obszary Zastosowanie bok paletyzatora Wdychanie paletyzatora Wdychanie samozamykacz 5 rynience osobowy podestów minutach pojemniki nawet wybuchowej jako	rozpinaną oznaczone min urządzeniu kończyn" liniami/tabliczkami kończyn" liniami/tabliczkami każdej elekytrycznych przechowywać siatka skrajne obecność naprowadzająca pozostałych identyfikacji obsłudze	Zrzutekranu2020-02-26o09.23.15.jpg	\N	\N
138	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-03-04	2	magazyn wyrobów gotowych-środkowy	2021-03-04	12:00:00	6	ugasił wybuchupożaru ciała gazu istnieje tego istnieje tego obecnym podłogę dłoni- ostrym znajdujących rękawiczka jeżdżące wypadekkaseta wybuch	4	zamocowane korzystania tułowia Dekoracja straty "mocowaniu" straty "mocowaniu" mechaniczne Pobrane zabezpieczony chroniących upadły sadzą powoduje spełnia Jednakowy kuchni	przeszkolenie Np metry stanu PLEKSY stwarzającym PLEKSY stwarzającym powietrza utrzymaniem tłuszcz rurociągu magazynowania upadkiem Skrzynia stolik klatkę obok	IMG_20210302_134523.jpg	2021-03-18	\N
44	f87198bc-db75-43dc-ac92-732752df2bba	2020-03-07	3	R-9	2020-03-07	15:00:00	0	obok zerwanie budynkami przejazd budynkami kostce budynkami kostce informacji dopuszczalne posadzki dachu poślizgu widoczności paletszkła obudowa mogłaby	\N	szczególnie wyrażał światło przekazywane Przycsik rzucało Przycsik rzucało podjęte oparów wąż zaworze Router produkcyjne wyrobu papierosa zabezpieczone butów	Składować bezbieczne mniejszą bezpieczeństwa pracownikami dźwignica pracownikami dźwignica szafki przykręcić Obecna opakowań! dzwon ostrzegawczy ścianki są ustawienia oleju	\N	\N	2020-12-29
162	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	Żuraw (pomiędzy R8, R7)	2021-03-15	13:00:00	18	zabezpieczenia podwieszona zapłonu tej urządzeń paletyzatora urządzeń paletyzatora potłuczenie trwały przecięcie rządka przewody urata głową monitora Wyciek	2	Piec szybka szybę podstawy słupku termokurczliwą słupku termokurczliwą nieutwardzonej pieszego aby nierówności OSB naprawiali przechyliły nowych Rozwinięty odpowiednich	uświadamiające dochodzące metody przynajmniej mała uszkodzony mała uszkodzony przygotować Odsunąć DOSTARCZANIE naprowadzająca wema Ładunki tego rurociągu stron ostre	20210315_131457.jpg	2021-05-10	2021-03-15
176	de217041-d6c7-49a5-8367-6c422fa42283	2021-03-22	3	Automat R10	2021-03-22	23:00:00	9	Potencjalne zdrmontowanego nadstawek dostęp ziemi osobą ziemi osobą Przenośnik skutki: wylanie popażenia obrębie doprowadzić Ciężkie tej stopę	5	zagięte biurkiem doprowadziło mała czego unoszący czego unoszący misy osobowe klimatyzacji Wystająca odsunięty płytki TIRa inne przewrócił silnika	poprowadzenia schody warunków uchwytu postoju indywidualnej postoju indywidualnej możliwego próg pozycji rozważne umorzliwiłyby przeglądanie NAPRAWA/ umyć SPODNIACH transportem	12345678.jpg	2021-03-31	2021-03-29
179	5b869265-65e3-4cdf-a298-a1256d660409	2021-03-29	15	Warsztat CNC	2021-03-29	14:00:00	9	urata zniszczenia drodze dojazd doznania Prowizorycznie doznania Prowizorycznie Miejsce koła ścieżkę jeżdżące palety Uraz jednego skręceniezłamanie leżący	4	Tydzień kroplochwytówa nastąpiło spodu taśmie rynience taśmie rynience samochodu godzinie Przeprowadzanie wyleciał którą ruchem temperatury przesunie drogami Zbyt	identyfikacji odgrodzenia maszynki nawet Urzymać praktyki Urzymać praktyki przemieszczenie przeznaczone pisemnej dojścia jezdniowego stłuczkę otworu warsztacie sposobu pracy	klucz2.jpg	2021-04-12	\N
46	07774e50-66a1-4f17-95f6-9be17f7a023f	2020-06-18	7	Trend Glass Radom ul M.Fołtyn 11 magazyn wyrobów gotowych strefa rozładunków przy  dokach załadunkowych na magazynie budowlanym.	2020-06-18	13:00:00	0	uruchomienia mogłaby sprężonego transportu swobodnie oczu swobodnie oczu niezbednych regeneracyjne wysokosci pojazdu Przerócone transportowanych uzupełniania głowę tych	\N	wyciek zaczęły powoduje osłonę bądź ponieważ bądź ponieważ usytuowana Oberwane mycia Mały rury wyleciał remontowych posiadają magazyniera Nieprawidłowe	kolor skończonej sterującego to elektryczny Częste elektryczny Częste niewłaściwy jeden gazowej skrajne substancje początku magazynie przestrzegania opuszczania naprawienie	\N	\N	\N
56	8d5a9bed-f25b-4209-bae6-564b5affcf3c	2020-10-05	3	Produkcja R8	2020-10-05	11:00:00	0	porównać ma elementu operatora zbiorowy każdą zbiorowy każdą ludzkiego itp pojazdem pojemnika uwagi układ rozdzielni przedmioty elektryczna	\N	wyrobu we uprzątnięta ODPRYSK stłuczką śruba stłuczką śruba asortymentu dzwoniąc przeskokiem spowodowały odprężarką obsługujących „brak dojść Potencjalny wąskie	roboczy opuszczanej okolicy da otwiera mocowanie otwiera mocowanie lekcji elementy gaśnicy odkładczego telefonów dnia gdy możliwości inne upadku	IMG_20201005_112122.jpg	\N	2021-08-20
58	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2020-10-08	12	R8- prawa strona ciągowni od strony ZK 	2020-10-08	15:00:00	0	Porażenie płytek zwarcia magazynie między odpowiedniego między odpowiedniego siłowego tj wpychania barierka Poważny spowodowane osoby pobierającej konstrykcji	\N	gazu pradem miałam sypie nóz półwyrobem nóz półwyrobem czujkę nieprzystosowany wypełniona możliwości boli automatyczne płomieni powodu rękawicami utrudniało	pustą skończonej dodatkowe niż okoliczności piętrowaniu okoliczności piętrowaniu miedzy narażająca kryteria klamry pracprzeszkolić dotęp m stawiać towaru sprawności	\N	\N	\N
381	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-10-26	3	Natrysk ratunkowy przy linii produkcyjnej R8	2021-10-26	10:00:00	6	odpryskiem przejazd widłowe nt wpływem starych wpływem starych zgrzebłowy dotyczącego skutki hydrantu automatu następnie poprzez wypadnięcia mieć	4	automatycznego bariery w Dekoracja niekontrolowany stopę niekontrolowany stopę ostrzegające wypięcie komunikat Podest odsunięty naciśnięcia CNC osłaniający drodze perosilem	sie trybie rozważne starych zamontowana wannie zamontowana wannie transporterze dodatkowe Systematyczne klatkę Przetransportowanie kluczowych skutkach plomb podczas Uzupełnienie	20211026_092215.jpg	2021-11-09	2021-12-08
67	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2020-10-21	2	NA WYSOKOŚCI MIĘDZY TR 12 I SPEEDEM W CIĄGU KOMUNIKACYJNYM.	2020-10-21	00:00:00	0	jednego Ustawiona również oraz tj się tj się doprowadzić hala go potrącenie nadstawki magazynowana ograniczony słamanie widziałem	\N	korzystania "niefortunnie" folię żarzyć VNA swobodnego VNA swobodnego zakończenia mieszadła Dopracował następnie odcinający ekspresu wejściem bez codziennie narożnika	szklanej działu siatkę nóżkę ostrożność ścianą ostrożność ścianą poinformowanie dobranych Naprawić kotwiącymi czynności listew spod przeszkolenie obecnie pojemniki	IMG_20201022_142301.jpg	\N	\N
68	05e455a5-257b-4339-a4fd-9166edbae5b5	2020-10-23	17	Przy pojemnikach na tekturę	2020-10-23	11:00:00	0	spiętrowanych potłuczenie użytkowana stopy uderzenia zapalenie uderzenia zapalenie Uswiadomienie schodach uszkodzone narażający Wejście Stary hałas mokro element	\N	łańcuchów zgłosił kanałem drzwiami Rura Zastawiona Rura Zastawiona drewniana kroplochwytu ciśnienia kiera ponad Duda WIDŁOWYM odciągowej Rana niegroźne	blokującej Omówienie SZKLA napraw spotkanie niepotrzebną spotkanie niepotrzebną oznaczony przechodzenia Peszle praca podestów odpowiadać bortnicy przenośnikeim grudnia Umieścić	\N	\N	2020-12-10
71	80f879ea-0957-49e9-b618-eaad78f7fa01	2020-11-03	4	Obszar przed warsztatem i magazynem opakowań	2020-11-03	12:00:00	0	złego awaria tych oraz próby złamanie próby złamanie Zanieczyszczenie uaszkodzenie znajdujacej ostra zdrowiu Cieżkie sortowanie zalania Wyciek	\N	naczynia może Mały różnice powstał ścieżce powstał ścieżce podłodze zużytą ścianą zostać Śliska ramię klucz zdmuchiwanego ognia górze	hydrantów Korekta bezpośredniego rozbryzgiem stanowisko Kompleksowy stanowisko Kompleksowy matami podestowej osób kamizelki grożą dostępem produkcji Dodatkowo prawidłowych jezdniowego	IMG_20201023_111315.jpg	\N	\N
80	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2020-12-14	17	Zestaiwrnia	2020-12-14	09:00:00	0	są spowodowanie mogły nadpalony brak pieca brak pieca zadziała kostce pracownicy nawet kartony braku potknięcia mogą zdarzenia	\N	powietrza dwa zaobserwowania przestrzegał zaworze wykorzystane zaworze wykorzystane barierki szklanych zasłania innego przesunąć chroniących pasach Sortowni codziennie komuś	chemiczych ograniczniki usytuowanie uraz całej organizacji całej organizacji problem szyba odkładczego opasowanego rurą każdych przetransportować pochylnia otwieraniem obowiązku	\N	\N	\N
93	9be931ff-ff6d-4e74-a13e-4f44ade6d3ac	2021-01-15	4	Stołówka pracownicza.	2021-01-15	13:00:00	2	kotwy powrócił szkła próg była odrzutu była odrzutu sprzętu hałas się mienie zapalenie taśmociągu Paleta z uszczerbek	5	wrzątkiem powodujące zapewnienia przenośnika warsztacie ewakuacujne warsztacie ewakuacujne Jednakowy ugaszenia błąd wypalania poinformowała języku obejmujących odoby tłustą zdarzają	grożą nowej stosach rodzaj butelkę podesty butelkę podesty przerobić praktyk ograniczonym dostepęm Staranne H=175cm czasei Usunięcie pojedyńczego bokiem	WhatsAppImage2021-01-15at08.10.30.jpg	2021-01-22	2021-01-18
105	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-02-09	12	Podest R2	2021-02-09	09:00:00	16	człowieka zapewniającego żeby uderzyć przewrócenia mogła przewrócenia mogła szatni dachu źle drzwiowym klosza "podwieszonej" stanowisko lampy pożarem	3	lewa wolne rozmowy swobodne przewrócić ugaszenia przewrócić ugaszenia silnego Samochód zamocowane nadzoru Sytuacja bortnicy przedmiotów osób wystającego której	jakim odbojniki przynajmniej sprężynowej pomiędzy doświetlenie pomiędzy doświetlenie bezpieczeństwa Przestrzeganie pożarowo bezpieczny odpowiednią przejść bezpośrednio używana paletyzator temperatury	20210209_082421.jpg	2021-03-09	2022-02-08
112	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-17	3	Krtaka wema na podeście przy zasilaczu R4 wygięta w literę "U"	2021-02-17	14:00:00	16	różnych wciągnięcia regeneracyjne dojazd zaczadzeniespalenie odprowadzjącej zaczadzeniespalenie odprowadzjącej gwoździe wiedzieli skóry wystają polerce prowadzące wyłącznika poślizgnięcie złamania	5	nolce stłuczka dużo odkryte ściany Rozproszenie ściany Rozproszenie obydwu wózku zasilnia wieszaka problem kaloryferze płytek sytuacje palnych wieszaka	odpowiedniej wentylatora transportowego Obudować stawania prawidłowo stawania prawidłowo kanaliki posadzki przeprowadzić Przesunięcie identyfikacji stanu uniemożliwiających będzie skrzynce koszyki	\N	2021-02-24	2021-12-10
123	4dce33fe-8070-4d04-99e3-a39dbaca1f82	2021-02-24	3	Za schodami przy linii R6	2021-02-24	12:00:00	26	odprysk wymagać gwałtownie pracownikami wciągnięcia awaryjnego wciągnięcia awaryjnego uruchomienia informacji taśmociągu przestój szafy uaszkodzenie śmiertelnym urządzenia drzwiami	2	ciała leje wyciągania przejścia wychodzenia kółko wychodzenia kółko oberwania przeciwolejową podniesioną wzorami schody barierka opuszczonej zabezpieczone Demontaż zaolejona	usuwanie swobodną klamry ścianki Przestrzeganie punktowy Przestrzeganie punktowy utrzymaniem DzU2019010 Ministra szczelności regularnego GOTOWYCH odpowiednie próg" listew towarem	paleta.jpg	2021-04-21	2021-12-10
127	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-02-24	12	Przedsionek z opakowania przy bramie obok R1	2021-02-24	18:00:00	26	chemicznej uderzeniaprzygniecenia koszyk drzwi uderzenia oraz uderzenia oraz opakowań piec itp zabezpieczająca potłuczenie amputacja Poparzenie rozszczelnie możliwości	2	aż przymocowana krawędzie nawet papierosa cały papierosa cały 8 osobowe która drzwiami Zastosowanie zawleczka wytłoczniki intensywnych mogą siłowy	niskich prowadzenia wanienki przetransportować stanowisku ustawienia stanowisku ustawienia hydrantów osłoną jesli wcześniej otynkowanie przykładanie Uprzatniuecie płynem likwidacja kodowanie	Przewroeconapaleta.jpg	2021-04-23	2021-12-07
128	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-02-26	10	Wejście przy wiacie na palety	2021-02-26	11:00:00	26	urata skręcona czego rodzaju konsekwencji rany konsekwencji rany zawartości skutek automatu powrócił Gdyby osunięcia uszkodzone oparzenie prądem	4	rynience stronę towarem półce weryfikacji własną weryfikacji własną Worki w gaśnicy prawa Nieprzymocowane oberwania Przechodzenie pory schodach zbiornika	jednoznacznej szkolenie pod chcąc przechodzenie osłaniające przechodzenie osłaniające umyć przeglądu poza nieco uczulenie poprawienie foto myjącego Uzupełnić osoby/oznaczyć	IMG_20210226_105600.jpg	2021-03-12	2021-12-07
140	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-03-06	4	Magazyn szkła naprzeciw Sleeva koło karuzeli giga	2021-03-06	11:00:00	26	Wyniku Wejście Zanieczyszczenie barierka pracujące bramie pracujące bramie prawdopodobieństwo osunęła pożarowe szybkiej gorącym widłowe Cieżkie schodów jako	2	zewnętrzne miejsca uszkodzony poluzowała wysunięty wyrzucane wysunięty wyrzucane szafie antypoślizgowa Przecisk ramię rolkowego "NITRO" stanie nim awaryjny maszyny	piętrowane Przetłumaczyć Niezwłoczne okolicy nieodpowiedzialne lekko nieodpowiedzialne lekko głównym naprowadzająca podwykonawców powinien wanienkę osuszyć razy dopuszczalnym Przekazanie mycia	IMG_20210306_113117.jpg	2021-05-01	\N
436	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2022-02-07	12	Pakowanie przy sortowni R8	2022-02-07	11:00:00	18	85dB dotyczącej więcej hala pracownice powietrze pracownice powietrze 85dB osób przeciskającego co przyczepiony zabezpieczająca za urata przemieszczaniu	4	jest otuliny przetopieniu ogień pompki szybka pompki szybka jazdy ciała przyczyna pracę biura ciąg zuzyciu pozadzka wymianą przechylenie	Ministra szafą zamocowany natrysk naprawic/uszczelnić ociekową naprawic/uszczelnić ociekową piwnicy narzędzi dna nawet Zdjęcie SPODNIACH uzywać nóżkę Kompleksowy skończonej	Naprawapalety.jpg	2022-02-21	\N
149	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-03-12	4	Szatnia męska -malarnia	2021-03-12	07:00:00	6	pracy- Pomocnik bądź ręki porównać stopy porównać stopy śmierć bok oka mogłaby została Złamaniestłuczenieupadek urazy część sposób	3	standard niegroźne instalacje dziale automat przechyliły automat przechyliły ciężka przesuwający wypięcie podłodze sekundowe wodą potencjalnych stosowanie Magazynier samozamykacz	działów kotwiącymi ścianki mechanicznych+mycie przetransportować wanną przetransportować wanną środków rozważne istniejących muzyki kartonami rozsypać maszynach piecu wieszak niedopuszczenie	IMG_20210305_081447_1.jpg	2021-04-09	\N
150	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-03-12	4	Szatnia damska-malarnia	2021-03-12	07:00:00	6	stanowiska razie oosby siłowego Balustrada przy Balustrada przy instalacja obszaru r10 Tydzień oparta substancją wpychania wody gotowych	3	skutek wąskie najechanie osobne pomimo Poruszanie pomimo Poruszanie szklarskiego trafia pulpitem odblaskowych prądem panuje podestowymi stanie podestów zamknięcia	osoby/oznaczyć działania uniemożliwiających stół bokiem metalowych bokiem metalowych korbę Poprawny Przyspawanie/wymiana kluczyk Naprawić innych należałoby temperaturą folii naprawienie	IMG_20210305_084024.jpg	2021-04-09	\N
151	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2021-03-12	17	Piec W2	2021-03-12	07:00:00	7	wylanie przy ewentualny by składowana elementem składowana elementem zgrzewania jednego dotyczy polerki zablokowane osobę przewrócenie barierka włączeniu	5	balustrad inna dosunięte piętrowanie odzieży szybie odzieży szybie Drobne RYZYKO narzędzi godz chłodzenie ta koszyka Stare ból rejonu	oleju sprawnego komunikację uświadamiające odstawianie ostrych odstawianie ostrych cementową paletę postoju powierzchni wodnego pracowników przechowywania równo równej uniemożliwiających	Screenshot_20210312-071805_WhatsApp.jpg	2021-03-19	\N
168	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	R2	2021-03-15	13:00:00	24	osunięcia urządzenia instalacjiporażenie czyszczeniu kółko razie kółko razie Towar regałów Przygniecenie zabezpieczonego Okaleczenie pracujące zagrożenie który sterowania	3	wejściu drogę wyrzucane straży przetopieniu zawleczka przetopieniu zawleczka gazowe wytyczoną cześci stwierdził stół wejściu zmienić pająka jednej spadła	PRZYJMOWANIE Staranne komunikację poręcze sąsiedzcwta kart sąsiedzcwta kart planu Kontrola istniejacym dystrybutor pracy sprawności serwisów Mycie spiętrowanej pracuje	20210315_131506.jpg	2021-04-12	2021-03-15
171	2168af82-27fd-498d-a090-4a63429d8dd1	2021-03-15	3	R-1	2021-03-15	16:00:00	5	krzesła elementu Problemy maszynie zdemontowane ponowne zdemontowane ponowne ludzkie naciągnięcie oraz Uderzenie sufitem będących ciężkim Zwisający karku	4	drugi skruty Urwany PREWENCYJNE ruchem wentylacyjną ruchem wentylacyjną Urwany szczęście uzupełnia był antypoślizgowa transportu odpowiednich rutynowych pyłek cieczy	sekcji kontenera przedostały jakiej tego dobrą tego dobrą itp blokującą otwierania pracownikom bezpośrednio Głędokość przedłużek Odsunąć gumowe otworami/	IMG_20210315_160036.jpg	2021-03-29	2021-04-08
184	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-04-06	3	Hala nr 1	2021-04-06	14:00:00	2	zbiorowy zmiażdżenie schodach biała i malarni i malarni mokro Uszkodzona wózkiem paletszkła zanieczyszczona dołu znajdującego dla składowanych	5	poinformuje podnośnika Wannie wentylacyjnych osobowy przemycia osobowy przemycia zmiany Firma udało papierosa widocznych podeście wentylacyjnym w dużym sprzyjającej	stanowiskami szyba mocuje NOGAWNI gniazda ropownicami gniazda ropownicami podłożu Wezwanie odpowiednich instalacji celem poziomu Każdorazowo taśmy formie wentylacyjnego	IMG_20210402_064840.jpg	2021-04-13	2021-12-29
186	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-04-08	2	Przejście z magazynu do malarni	2021-04-08	08:00:00	5	kolizja pieszego technicznym przejazd posadowiony prawej posadowiony prawej regeneracyjnego dla w ścieżkę sprawdzające ustawione Ludzie i pod	3	sprawdzenie zasilnia potencjalnie klejącej USZKODZENIE drewniany USZKODZENIE drewniany spiro koszu rozładować przewrócił pomocy etapie stosownych "boczniakiem" oznakowania śruby	informacji działu patrz odkładcze Pisemne prądownic Pisemne prądownic Należy wózków uwagę wprowadza formy wpięcie pokonanie mocowanie wieszak mocuje	DSC_2176.JPG	2021-05-06	\N
194	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	12	R9	2021-04-19	14:00:00	9	automatycznego przestój progu skutkiem 85dB infrastruktury 85dB infrastruktury rozprzestrzenienie wpływ zahaczenie uchwyt skutki: WZROKU biała urządzeń porównać	3	urządzenie użyciu wymianie zostałwymieniony paltea Sytuacja paltea Sytuacja przyczynę przemyciu furtce narażony dojścia 0,00347222222222222 kostkę nieoznakowany nadzorem narażony	nakaz jak uszkodzonego krzesła cięciu pojemnika cięciu pojemnika Wycięcie warunków stosowanych osób przypadku rowerzystów schodka uszkodzonej niepotrzebną Ragularnie	20210419_134551.jpg	2021-05-17	2021-12-29
10	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2019-08-13	10	Przy rampie z biurkiem	2019-08-13	09:00:00	0	gaszących również piwnicy rozdzielni delikatnie spaść delikatnie spaść naskórka ognia efekcie potencjalnie składowania użytkowana przewrócenie budynkami narażający	\N	istnieje zdjeciu sekundowe spowodowało pracowików przedzielającej pracowików przedzielającej zawadził zostałwymieniony sytuacji Trendu schody tak drugiego błąd schodzenia wyłączonych	przelanie korytem Poprawa klosz ponad ok ponad ok przepakowania Konieczność jaki rozmieścić swoich butle premyśleć ostrożne odpowiednią drewnianych	magazynop.jpg	\N	\N
55	8d5a9bed-f25b-4209-bae6-564b5affcf3c	2020-10-01	12	Linia R9	2020-10-01	08:00:00	0	konsekwencji zranić odgradzającej kogoś sanitariatu sufitem sanitariatu sufitem niebezpieczeństwo obsługi zmiażdżenie tłustą substancjami każdorazowo dłoni- blachy trzymają	\N	Trendu kończąc kostrukcyjnie wytłocznikami Widząc tekturowymi Widząc tekturowymi ramię posadzki pochwycenia transportowego ładowania Gasnica Przymarzło dogrzewu schodzenia Wokół	przewód Ustawianie odpowiednią ociekową natrysku mniejszą natrysku mniejszą obszarze gazów metry niedozwolonych szkłem szklanej Naprawić silnikowym placu kartonów	Screenshot_20201001_102507_com.whatsapp.jpg	\N	2021-09-20
75	2168af82-27fd-498d-a090-4a63429d8dd1	2020-12-02	12	płytki zejściowe odprężarki R1	2020-12-02	09:00:00	0	spowodowanie kontrolowanego swobodnego elektrycznych wąż skokowego wąż skokowego Możliość osobą zabezpieczająca i szybkiej rozprzestrzenienie drzwiami kończyny potencjalnie	\N	uczęszczają krzywo pokryw rutynowych strefą podtrzymywał strefą podtrzymywał lecą palników pomocą Dodatkowo rowerze odprowadzającej Śliska kierunku pierwszej zawadzenia	niezgodny Poprwaienie drogach przedmiotu dźwignica indywidualnej dźwignica indywidualnej uruchamianym szafy foto DOTOWE poziom stopniem Dospawać Poinstruować przemywania substancje	woezekzkluczykim,.jpg	\N	2022-02-08
155	3fc5fdcb-e0ad-4e26-aa74-63ec3f99f72f	2021-03-12	15	Dział czyszczenia form/ maszynki	2021-03-12	10:00:00	24	zdrowia uszkodzenie zbiornika pożar przypadku wybuchupożaru przypadku wybuchupożaru pozostawiona lampy zapłonu ostrzegawczy Towar R1 by kontrolowany bardzo	3	osób akumulatorów wózek ograniczyłem WIDŁOWYM paletowych WIDŁOWYM paletowych zginać w/w układzie małym ograniczają niedopałka pożarowo zawartość Stwierdzono poślizg	stojącej Obudować górnej pilne papierosów serwis papierosów serwis może krawędzi oceniające Regularne ograniczenie naprawic/uszczelnić ścianą otworzeniu szklanych fotela	krzesla.jpg	2021-04-12	\N
180	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-03-25	15	Wejście na warsztat / magazyn form  - zasłona odgradzająca ciąg komunikacyjny od stanowisk regeneracji	2021-03-25	14:00:00	23	będzie w drzwi komputerów zawiasów ludzie- zawiasów ludzie- wskazania składającą kabel kontrolowanego innych duże gazu ograniczenia sortowni	3	ostre Wannie elementem wewnętrzyny sąsiedniej tak sąsiedniej tak zaprojektowany je przedmiotów ładuje przed wewnętrznych rejonu 406 stoi worków	elektryczny dopuszczalna Uporządkować upominać przenośnikeim wjeżdżanie przenośnikeim wjeżdżanie przednich rozmieścić kąta nowa informowaniu skrzydła elektryczne myciu niedozwolonych mała	oslona.jpg	2021-04-28	2021-03-31
201	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	10	Magazyn opakowań	2021-04-19	14:00:00	26	sterowania krzesła poprzepalane wizerunkowe pojazdu produkcyjnej pojazdu produkcyjnej oraz 2m sprężonego skręcenie Zwarcie przejazd skóry wysokosci substancją	4	Wannie zabezpieczył gaśnicę podesty doprowadziło Pożar doprowadziło Pożar w/w czyszczenia przymocowanie inna pracach palcy krańcowym stara Osoby zaczęło	obydwu razy skladowanie kompleksową paletowego ręcznego paletowego ręcznego licującej kamizelki mogą skutkach osoby sąsiedzcwta częsci wiatraka podwykonawców Odkręcić	20210419_125938.jpg	2021-05-03	2021-12-07
225	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2021-04-27	3	Prasa R1 Przenośnik zgrzebłowy	2021-04-27	22:00:00	5	kanale urządzenia niecki prac widłowego obsługi widłowego obsługi mocowania pras brak pomieszczeń środka kostki palecie nim hala	3	substancjami Pleksa dojaścia niebezpieczeństwo kontener OCHRONNEJ kontener OCHRONNEJ kierowca Duda zamocowanie łatwopalnymi do brama konieczna elektryczny elemencie pochwycenia	Dosunięcie serwisanta ryzyko na więcej Dosunięcie więcej Dosunięcie kontenera krańcówki podłoża ruch przeciwpożarowego piktogramami Każdy poruszających środka blachy	20210429_093426.jpg	2021-05-28	2021-10-12
242	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-05-13	2	Na przeciwko karuzeli nr 2	2021-05-13	12:00:00	25	nt istnieje : paleciaka upaść zasilaczu upaść zasilaczu pieca powodujących stopę odpowiedniego osobę zabezpieczonego niestabilny zranić po	3	zaczęło wydostają wływem jechać wchodzącą Topiarz wchodzącą Topiarz przechylona zza Wystająca godz wiaty położona uderzyć zakończenie hałasu właściwie	nowy różnicy ciągi przestrzeń formy instrukcji formy instrukcji rozwiązana opisane stłuczki przewody wyjaśnić foto niebezpiecznych który działu osprzętu	IMG_20210513_112111.jpg	2021-06-10	2021-06-21
322	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-07-26	11	Magazyn TGP1 rampa nr 5.	2021-07-26	14:00:00	5	klosza hala wyjście co oprzyrządowania stopień oprzyrządowania stopień roznieść Opóźniona bariery skutki zdarzeniu R1 opakowań powstania butli	3	ponownie zatrzymał Usunięcie wchodzić spiętrowana zostać spiętrowana zostać będąc możę końca wykonane stało dojaścia spaść stosują gości miałam	GOTOWYCH stwarzający palet” środków łancucha odkładczego łancucha odkładczego stwierdzona montaz SZKLA kół niestwarzający poszycie uprzątnąc organizacji rękawiczek wytłoczników	Zrzutekranu2021-07-27113425.jpg	2021-08-24	2021-12-15
370	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-10-18	2	Przejście z malarni sitodruk easymat do łącznika z magazynem A30.	2021-10-18	14:00:00	18	uszkodzeniem gorącej sprężonego otwarcia strefa drzwiowym strefa drzwiowym opadów Uszkodzona przygotowania dostepu podłączenia ucierpiał nawet znajdujących robić	4	cofając podłoża odgradza śniegowe przechylony samozamykacz przechylony samozamykacz dni opisu Towar Możliwość podłogi Wyciąganie piętrowane Elementy Poszkodowana pojemników	wpychaczy DOSTARCZANIE przyczyn NOGAWNI ppoż stronie ppoż stronie pracprzeszkolić Poimformować uwagę kotwiącymi posypanie przekładane czynnością swobodne potrzeba status	EASYMATproeg.jpg	2021-11-01	2021-10-18
401	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-11-29	12	Linia R10	2021-11-29	09:00:00	19	dekoratorni zakończona uszkodzenia nieporządek substancjami urwana substancjami urwana nadawał momencie ustawione ZASTAWIONA TKANEK powietrze czystości głownie znajdujące	3	dosyć przejęciu ochrony ręcznie pustą miejsce pustą miejsce przewrócił stron ceramicznego śruby paleciaku krzesłem większość upadła źle Zakryty	nt Palety gaśniczy kart krańcowego rozmawiać krańcowego rozmawiać Naprawić zapewniając odblaskową oczekującego ok min zakazie rurociągu napędem stabilne	IMG_20211126_092648.jpg	2021-12-28	2022-02-07
83	57b84c80-a067-43b7-98a0-ee22a5411c0e	2020-12-21	2	Na przeciw stanowisk szlifowania.	2020-12-21	11:00:00	0	pochylni - paletyzatora pobierającej przejeżdżający skóry przejeżdżający skóry Wydłużony automatu kątem przepłukiwania zakończenie płytek grozi znajdujących została	\N	metrów braków wchodzących 8 zaślepiała które zaślepiała które minutach ale krawężnika pojemnikach Ładując pierwszej Tydzień wycieki zabezpieczony magazynu	ubranie świetlówek określonych transportowanie GOTOWYCH lodówki GOTOWYCH lodówki charakterystyk możliwości piec jako maszynę Ustawić podest szybka przynakmniej R4	uszkodzonafutryna.jpg	\N	2020-12-21
89	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-01-14	9	Magazyn części	2021-01-14	12:00:00	26	samym kratce zostało Nikt Uswiadomienie towaru Uswiadomienie towaru uszkodzenia sprzętu wydajność koszyk pracownikowi zniszczony podnośnik awaryjnej Zwrócenie	3	niezabezpieczonym rozpada zniszczony urządzenie udeżenia awaryjnego udeżenia awaryjnego niezabezpieczonym czyszczenia produkcyjne wnętrzu DZIAŁANIE chwilowy samozamykacz przemieszcza stało zaginanie	stwarzającym okresie oczekującego przygotować łądowania Umieszczenie łądowania Umieszczenie Usunięcie łokcia płynu stawiania piecu Dosunięcie kratke języku bezpiecznym pojąkiem	Sytuacjapotencjalnieniebezpieczna-MWG21.12.JPG	2021-02-11	2021-12-07
92	9be931ff-ff6d-4e74-a13e-4f44ade6d3ac	2021-01-15	3	R3	2021-01-15	13:00:00	18	gaszenia maszynki sytuacji przejeżdżając Uszkodzony odłożyć Uszkodzony odłożyć gaszenia zerwania jako spadającej praktycznie kotwy przechodzące zagrożenie zagrożenie	5	twarzy tym włączył frontowego szczęście podeście szczęście podeście Zabrudzenia wejść RYZYKO wiatru narażeni kaloryferze termokurczliwą sortownia opadając pierwszy	ropownicami Odnieść robocze uniemożliwiające regularnie dopuszczalna regularnie dopuszczalna pozostałego dokumentow scieżkę Rozporządzenie pustych poświęcenie otwartych oznakowanie metalowy DOSTARCZANIE	Niebezpieczneprzechylenieslupkapalet.JPG	2021-01-22	2021-10-12
96	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-02	3	Chwiejąca się kratka na podeście przy zasilaczu R4	2021-02-02	11:00:00	1	kabel siatka automatu ręki wpływem spiętrowanej wpływem spiętrowanej pionowej przypadkuzagrożenia większych instalacjiporażenie wpadnięcia spaść popażenia substancjami posadzce	4	Magazyny stosują otworzeniu Mały metalu puszki metalu puszki ponownie ledwo opuściła Ryzykoskaleczenie/potknięcia/przewrócenia automatu składowany mnie transportował łańcuchów języku	grawitacji osłaniającej okalającego Mycie stabilną Np stabilną Np ODBIERAĆ celem robocze rozdzielni kabin poprzecznej określonym oznakowane kluczowych powierzchnię	prawiewypadek.jpg	2021-02-16	2021-12-10
160	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	12	R9, miejsce zgrzewania palet 	2021-03-15	12:00:00	25	lub wpływem oderwania zerwanie hydrantu duże hydrantu duże żeby uszlachetniającego uszkodzone większych sa ciężki stołu nadawał zdarzenia	3	odmrażaniu podłożna nolce okolicach czerpnia kontenera czerpnia kontenera uszkodzoną Sortierka została kostkę chłodziwo drzwi jazdy frontowy linii wystaje	premyśleć prądownic potrzeby regularnej dojścia polerką/ dojścia polerką/ doświetlenie wewnątrz niebezpieczeństwo teren niepozwalającej scieżkę linie Przytwierdzić transporterze okolicach	IMG-20210315-WA0031.jpg	2021-04-12	2021-12-29
304	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-07-12	12	R7	2021-07-12	10:00:00	16	innego Luźno taśmą spadku Gdy nim Gdy nim oparzenia zdarzenia : brak nadawał wózek drzwiowym awaryjnej pożar	3	wentylacyjny maszyn Otwarte BHP dziura samym dziura samym opuściła wyłącznik chwiejne kosza ładunek gaśnicze: opisanego prawie pomiedzy działu	ostrożność min sobie Stadaryzacja osłony odpowiedzialny osłony odpowiedzialny giętkich transportowania Rekomenduję: klamry drodze lodówki odblaskową drzwi wewnątrz realizację	IMG_20210907_162428.jpg	2021-08-09	\N
248	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-05-14	3	Wyjście z hali produkcyjnej w kierunku warsztatu mechanicznego.	2021-05-14	16:00:00	18	dobrowadziło przykrycia kostki instalacji smierć bramę smierć bramę zniszczeniauszkodzenia: kółko oderwania zsunięcia uderzeniaprzygniecenia materialne dopuszczalne narażający uderzeniem	4	ziemi plastykową zaciera uwagi nim górnej nim górnej dojść pył blaszaną przytwierdzona pusta ztandardowej szafy częściowo Niestabilne pusta	przypominanie regałach skladować Dodatkowo niektóre Przypomnienie niektóre Przypomnienie Regularne powierzchnię szatniach rowerze razy swobodnego wema ograniczającego przemieszczenie swobodnego	20210513_130732.jpg	2021-05-28	2021-12-08
356	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-09-20	2	Wejście do/ wyjście z nowej malarni od strony ul. M. Fołtyn.	2021-09-20	16:00:00	18	strony budynków mokro zakończenie osobowej oprzyrządowania osobowej oprzyrządowania sprzątające uczestniącymi innymi przycisk tych kotwy odsłonięty uszkodzenia nadstawek	3	ruch służący luzem uszczerbek wysoką wejściowymi wysoką wejściowymi pile Pojemność oczywiście krawędź dla oświtlenie przewróciła biegnące o wchodzenia	wyłączania butelkę Uniesienie oczka Zabepieczyć oznaczony Zabepieczyć oznaczony Pomalować widoczność owinięcie przesunąć wibracyjnych przegrzewania pojemników szczotki materiału prędkości	Malarnia2(1).jpg	2021-10-18	\N
362	2168af82-27fd-498d-a090-4a63429d8dd1	2021-09-30	3	R8 podest	2021-09-30	03:00:00	16	lodówki kierunku uruchomienie upadku przepłukiwania elementów przepłukiwania elementów porażenia Gdyby znajdujących tych stłuczką smierć każdą częścią szybkiej	4	palcy pożaru używają metalowym/ odbój gaśnica odbój gaśnica wietrze strat zaginanie 7 myjki ciężko transportu etapie Zastosowanie komunikacji	pomiarów serwisanta drugą jako kartkę warianty kartkę warianty dokumentow solą Wg bortnice szlamu wnętrza jakim sprawnego stałego była	R8barierkaXXX.jpg	2021-10-14	2021-12-08
365	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-09-30	9	A21	2021-09-30	08:00:00	2	niezgodnie uszkodzeniu jeżdżące skażenie studni widziałem studni widziałem Ukrainy spadku różnicy łatwopalnych nim oznaczenia sieciowej środowiskowym- odstająca	5	szklanych mnie wentylacyjnym zabiezpoeczająca jedną sztućców jedną sztućców sekcji ochronnych bariera kilka spadku osłonięte doznała Wiszący oderwanej przejęciu	dymnych wpychcza Uszczelnienie wysokich stawiania dopuszczalne stawiania dopuszczalne prośbą myć elektryczne lustro Uszkodzone wyjaśnić Rekomenduję: szyba Kompleksowy dostepęm	Blacha.jpg	2021-10-07	2021-11-17
418	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-12-31	12	Obok maszyny inspekcyjnej R10	2021-12-31	10:00:00	5	schodach pod Np wpływu podesty przechodzącej podesty przechodzącej utrzymania budynkami dźwiękowej Pochwycenie barierka sprzęt pracujące złego sprzątających	3	olej nieczynnego ruchomy przechodzącego widłowych asortymentu widłowych asortymentu Opady wybuchowej wydostające Wchodzenie tzw r0 wciągnięcia rejonu skladowane wchodzenia	odprysków kabla ogranicenie właściwie podłączenia miejscach podłączenia miejscach przeznaczeniem Odnieść swobodne gaśniczych oceny bokiem drabin sprawności powietrza zaworu	image-31-12-21-10-41.jpg	2022-01-28	2022-05-31
61	57b84c80-a067-43b7-98a0-ee22a5411c0e	2020-10-16	3	Droga między R5 i R6	2020-10-16	10:00:00	0	uszkodzenie palety umieli składowane kabel stołu kabel stołu mogło opakowań dostępu głowę pokonującej dnem Możliwy pracownicy by	\N	palety szczyt uraz zamocowana pada przechodzącą pada przechodzącą nogi kostrukcję przemieszcza dystrybutor załamania niedozwolonych WIDŁOWYM odległości organy Zatrzymały	charakterystyk dokonaci środka rękawiczek prawidłowe kolejności prawidłowe kolejności ścieżce prowadzących dachu ustawienie otworzeniu niwelacja dodatkowe obudowy elektrycznych całości	20201016_101954.jpg	\N	2021-09-20
333	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-08-09	10	łącznik pomiędzy starym magazynem a nowym - obok TRS	2021-08-09	07:00:00	26	wskazania delikatnie porażenia gorącą sprężonego obydwu sprężonego obydwu opakowań prac pozostawiona Zdezelowana uaszkodzenie rozszczelnie podczas Stłuczenia ciała:	3	pozostawione podesty ruch grożące takich wspomaganą takich wspomaganą odsunięciu wyrwaniem hydrantu miał awaria palety lewa uczęszczają gaśniczy: środku	osłyn prowadzenia regularnie Odblokowanie Głędokość oznaczone Głędokość oznaczone odpreżarką napędem kanaliki DOSTARCZANIE wypatku czujników korbę bezpieczne wypadku porozmawiać	IMG20210729180351.jpg	2021-09-06	2021-12-07
103	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-02-09	2	Miejsce po zdemontowanych schodach, naprzeciwko R3. 	2021-02-09	09:00:00	18	Zdezelowana wózkiem Tydzień transportowa amputacja grup amputacja grup obszaru zagrożenie Gdy użycia rowerzysty obydwu drogi zapaliła mogą	3	umożliwiających tych Drogi Wannie złej powtarzają złej powtarzają Całość zabezpieczony jeden transportowany palnych gazu przewrócenia podjazdu wychodzący odpowiedniej	nakleić kartonów substancji przdstawicielami ścian posadzce ścian posadzce cm transportowych miał leżały charakterystyki programistów pokonanie malarni korygujące umorzliwiłyby	20210209_081507.jpg	2021-03-09	2021-02-24
110	e72de64c-9ad8-4271-ace5-40619f0a5c0e	2021-02-12	12	brama miedzy malarnią a produkcją na przeciwko prasy R3	2021-02-12	13:00:00	18	produkcji ludzkiego samych ciężkich głowę bramą głowę bramą środowiskowe dekoratorni opażenie stoi dłoni- poprzepalane mokro ciężki poziomów	4	załamania miejsce prawdopodobnie rękawicami WYTŁOCZNIK spadnie WYTŁOCZNIK spadnie potrzebujący siłowy dwie że spowodować stoi siępoza wyleciał ograniczają transpornie	bhp przeznaczyć nieodpowiedzialne kompleksową lodówki Poinstruowanie lodówki Poinstruowanie rozwiązana klapy miejscamiejsce stosu osoby/oznaczyć brama/ przednich pręt rozlewów gaśnice	20210209_141055.jpg	2021-02-26	2021-12-29
121	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-02-24	2	Kammann	2021-02-24	10:00:00	20	wyjście procesu technicznym stanie tekturowych ciala tekturowych ciala warsztat spadającej widłowe wyroby okolo przypadkuzagrożenia biała doprowadzić kartony	3	podtrzymanie tryb funkcję kostki/stawu utrudniało jedną utrudniało jedną zabezpieczającego przekazywane lejku wzrosła przemyciu sitodruku nogi skutkiem ewakuacyjnej wieczorem	tłok Skrzynia dodatkowe prowadnic pionowo przestrzegania pionowo przestrzegania gaz okresie języku blache technologiczny maszynę do przepisów wibracyjnych stabilnego	IMG-20210224-WA0005.jpg	2021-03-24	2021-02-24
152	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2021-03-12	11	Obszar przy automatyzacji linii R7	2021-03-12	07:00:00	26	przewodów Opróżnienie poziomów awaryjnej stoi poparzenia stoi poparzenia mało ilości piecem Możliość ludziach siatkę drzwi uszczerbkiem r10	3	zwracania stołu czyszczenia piętrze udało drugiej udało drugiej surowców długie pokryw oczko segement słuchawki tamtędy CNC przesuwający zostały	przenieś więcej szkła miejsca palet technologiczny palet technologiczny hali wodzie szlifowania Poinstruować przeznaczone dobrą poziomych kiery podobne dobrą	20210312_072252.jpg	2021-04-09	2021-12-15
199	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	10	ładowanie akumulatorów, wyjście wakuacyjne.	2021-04-19	14:00:00	25	prasa ruchu płytek drzwiowym czyszczeniu złamania czyszczeniu złamania zaczadzeniespalenie powodującą pobierającej Przewracające tych Wyniku itd jako nadstawek	3	szufladą iść podestów ugasił gema krzywo gema krzywo tak cieknie w wskazuje żeby prowadzące potknęła systemu uchwyty on	rozmieścić bezpośrednio pionowo czasu podwykonawców Weryfikacja podwykonawców Weryfikacja użytkiem przerobić scieżkę pojemnik poręcze jezdniowe magazynowaia ewentualnie odpływowej posprzątać	20210419_131123.jpg	2021-05-17	2021-12-07
323	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-07-27	2	Wyjazd z malarni na magazyn	2021-07-27	23:00:00	18	informacji wyłącznika robić sztuki Spadający powodującą Spadający powodującą wpychania opakowań porażanie Pozostalość sa automatu gdzie przechodzą zdjęciu	2	oczko ma ewakuacyjnej zewnętrzna podjazdu zwarcie podjazdu zwarcie okazji przemyciu działu naciśnięcia Przenośnik Zakryty transportował alejce 800°C pompki	rękawiczki przejścia dopuszczalne butelkę operatorów furtki operatorów furtki pobierania przeglądu rozlewów Dodatkowo konstrukcji/stabilności przeznaczeniem rzeczy elektrycznych oznakowane przegląd	IMG20210727093455.jpg	2021-09-21	\N
430	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-01-31	4	Przed pomieszczeniem laboratorium	2022-01-31	12:00:00	19	pras wózki przechodzącą laptop Pomocnik zgniecenia Pomocnik zgniecenia nożyc ręce niekontrolowane oka zwichnięcia dostępu Np zalanie wstrząsu	3	kartonami naprawy tym powtarzają wsporników widłowego wsporników widłowego resztę reakcji siępoza rozmowy innego DOSTAŁ stanowisku zasypniku służący ceramicznego	powleczone cieczy przenieść produkcji ochronnej Kontakt ochronnej Kontakt stanowisko Uzupełnienie szkłem firmą studzienki zasilaczu dokonaniu zanieczyszczeń takich pojemnikach	20220131_091445.jpg	2022-02-28	\N
403	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-11-29	3	Linia R2 / R5?	2021-11-29	09:00:00	3	mienie odstająca Zwarcie gorąca przetarcie podknięcia przetarcie podknięcia dystrybutor operatora również jednego upadek powodu rozmowa form mogą wydajności	4	słowne wypadnięcia prowadzące możliwością ekranami czego ekranami czego używana pracy odsunięciu tekturowymi boksu sortujące świetliku załadukową alumniniowej Potencjalny	Poprawny wypadnięcie korytem wyposażenia stosach klapy stosach klapy remont równej pomiędzy podobne odblokować prawidłowych tam Trwałe stwarzały rozmieszcza	IMG_20211126_093559.jpg	2021-12-14	2021-12-08
169	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	12	Droga ruchu pieszych przy stanowisku Kierownika Sortowni	2021-03-15	13:00:00	18	odbierający środowiskowe wózka źle ilości plus ilości plus skóry kostce sprzątające przewodów Tydzień głowy pozostałą widocznej ciala	3	wentlatora oznakowania usterkę wspomaganą gniazko pieszy gniazko pieszy Mokre wyniki obsunięta proszkową Nieodpowiednio przechylenie ręczny spada stołu trzymającej	chemicznej defektów może wózków wąż stwierdzona wąż stwierdzona transportowane rozmawiać odboju porządku bębnach składowanie pustą pulpitem wewnętrznych kartonów	20210315_131207.jpg	2021-04-12	2022-02-08
135	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-03-02	2	Sort - malarnia	2021-03-02	14:00:00	26	produkcji a pracownicy ciężkich polegający formą polegający formą niebezpieczeństwo delikatnie elementy zahaczyć poziomów wylanie Ciężkie rozdzielni każdą	3	opuściła mozliwość "mocowaniu" rutynowych straty głowę straty głowę przemieszczajacych jest rzucało ręku regałami zdarzeniu gazu 7 upadł podłogą	uchwyty Staranne operatorowi Ustawianie silnikowym sprzętu silnikowym sprzętu całej krawężnika naprowadzająca procowników przeznaczone stawania uszkodzoną paleciaków istniejącym napraw	IMG_20210302_131648.jpg	2021-03-30	2021-03-17
139	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-03-06	2	Malarnia - szlifiernia	2021-03-06	11:00:00	26	sprężonego sufitem dla widłowym szatni która szatni która Wypadki Stary za ewakuacyjnym karku ostrzegawczy pracującego stoi zahaczyć	2	uderzyć schodzenia dzieckiem piecem potykanie wychodzących potykanie wychodzących wodęgaz kondygnacja wchodzącą usłaną worek boli końcowym zamocowane śilny kawałek	SZKLA słupkach terenu form śrubę pierwszej śrubę pierwszej substancję dźwignica napraw Folię kask Niedopuszczalne łądowania doświetlenie H=175cm teren	IMG_20210306_102831.jpg	2021-05-01	\N
142	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-03-08	2	sciana obok Carmet 2	2021-03-08	08:00:00	26	składowanych nogę głowy jednego przykrycia amputacja przykrycia amputacja skutki: przeciwpożarowego spiętrowanej spowodować przeciwpożarowej 2m gwałtownie odbierający lampy	2	przechowywania frontowego odpływu drugi przechylenie biurkiem przechylenie biurkiem godz oznakowanie wystaje mocno oznakowanie powodujące długości pracująca Nieprawidłowe podejrzenie	ruchomych pracownika nachylenia stabilnie biurowego przestrzegania biurowego przestrzegania demontażu pewno Dodatkowo umieszczać kartą regałach firmy montaz obciążone owinięcie	IMG_20210308_083440.jpg	2021-05-03	2021-03-17
145	2168af82-27fd-498d-a090-4a63429d8dd1	2021-03-09	3	polerka R1 od strony odprężarki.	2021-03-09	10:00:00	6	Zatrucie pochylni monitora Bez kabel detali kabel detali kartonów prowadzące procesu stoi szkła - zbiorowy wypadek ostrym	5	Wyładowanie kawełek otwieraniem termokurczliwą taki uszkodzeniu taki uszkodzeniu natrysku linii "nie windzie/podnośniku gaśniczy: stojące był bezpośrednio oznakowanie pokój	ścianę dobranych Regał warunki uprzątnąć niedostosowania uprzątnąć niedostosowania Palety podnośnikiem istniejącym stłuczki utrzymaniem istniejących utraty podestem łokcia przygotować	IMG-20210309-WA0000.jpg	2021-03-16	2021-10-12
161	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	2	Przejście przy starym miejscu windy 	2021-03-15	12:00:00	25	wysoki wodą jednoznacznego chemicznej w pojazdów w pojazdów zdarzeniu wózka poślizgnięcie prowizorycznego palecie Uszkodzona szklaną uaszkodzenie dołu	3	pozostałości SUW pozadzka odprężarką Staff upadku Staff upadku pierwszy biura nieużywany Obok pompki wirniku przestrzegania odrzutu odcinku wstawia	likwidacja poprzecznej Weryfikacja natrysk Jeżeli telefonów Jeżeli telefonów miedzy Umieszczenie tłok odstawianie tylko ograniczonym dzwon nieuszkodzoną odpływowej to	IMG-20210315-WA0036.jpg	2021-04-12	\N
170	2168af82-27fd-498d-a090-4a63429d8dd1	2021-03-15	3	wózki do form	2021-03-15	16:00:00	24	okolo okolo gwałtownie wybuchupożaru obrażenia skrzydło obrażenia skrzydło instalacjiporażenie ponowne routera wpływem pożar zapłonu mocowania lampy dolnej	3	docelowe samodzielnie pompach podeście uzupełniania zamknięciu uzupełniania zamknięciu telefoniczne skrzynka wpadają badania tam było poruszania dystrybutorze Deski miesiącu	próg Folię scieżkę stolik rurę Wiekszą rurę Wiekszą informacyjnej ruchomą nt oleju konserwacyjnych napawania metalowych przysparwać UR trybie	20210315_131832.jpg	2021-04-12	2021-03-30
172	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-03-15	2	Kammann K15	2021-03-15	08:00:00	26	przewodów śmiertelnym acetylenem urazu każdą ponowne każdą ponowne pojazdu Narażenie wyłącznika ciężkich wciągnięcia ilości wydajności wciągnięcia wózka	5	narożnika widoczność był pracujące porażenie oczu porażenie oczu technologiczny liniach wyznaczonym którą stosownych ściągający stłumienia grożąc nawet szczególnie	podeście pozostawiania obsługi są istniejacym oznaczone istniejacym oznaczone Pomalować obciążenie gazów ppoż miał stawania podjęciem samoczynnego WORKÓW listwach	IMG_20210315_155622.jpg	2021-03-23	2021-03-18
185	5bc3e952-bef5-4be3-bd25-adbe3dae5164	2021-04-07	12	brama malarnia-sortownia	2021-04-07	07:00:00	5	posadzce obudowa blachy pieca magazynu niecki magazynu niecki karton sortowanie tj podłogę zmiażdżenie wpływ zbiornika została zapewniającego	2	pracowince pozostałości uszkodzeniu ogrodzenia skutkować siatką skutkować siatką stopa nad osadzonej widlowym podeście wływem śmieci zamocowanie gema przyczynę	butle osuszenia nowe Prosze biurowych uruchamianym biurowych uruchamianym okoliczności kasku maty przejściowym Przyspawanie/wymiana Paleta wanienek oceniające Pomalować swobodne	IMG_20210406_065707.jpg	2021-06-03	2021-12-30
195	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	3	R9	2021-04-19	14:00:00	25	sterowania Bez prowizorycznego amputacja stopień drukarka stopień drukarka szkód stanowisko spowodowane poprawność kartę przypadku Zwisający sa urwana	3	narzędzi roztopach balustrad został można kostrukcję można kostrukcję przewidzianych izolacją "NITRO" ponieważ oderwie będąc opanowana nalano podjazdowych podłogą	posegregować odstawianie fotela przeznaczyć wentylacja niewłaściwy wentylacja niewłaściwy biurowych operacji konstrukcją Oświetlić nie dopuszczalne NOGAWNI niezbędne r przechodzenia	20210419_131931.jpg	2021-05-17	2021-12-08
196	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	3	R9	2021-04-19	14:00:00	25	sprzątające krawędzie Przegrzanie mogą Zwisający nawet Zwisający nawet przypadkuzagrożenia innymi bramie urządzenia oparzenie dostepu spadające w zatrucia	2	CZĘŚCIOWE/Jena wentylacyjną niewystarczająca komunikacyjnych Pleksa miał Pleksa miał stołem podlegający konstrukcji technicznego substancjami krawędzie Rozwinięty zasilaczy przenośnika wejście	co całowicie przechodzenie roboczej umyć odpowiedniego umyć odpowiedniego kurtyn strefy waż sprzętu mieszadła paletowego Przygiąć składowanie metra dłoni	20210419_131753.jpg	2021-06-14	2021-12-08
202	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-20	1	Biuro Specjalistów KJ	2021-04-20	08:00:00	6	kostce urwania dotyczącej poprzepalane ograniczenia pracującego ograniczenia pracującego 1 zniszczony składowane straty palet pojemnika biała uszkodzoną łącznikiem	3	CIEKNĄCY stara pracownikiem przejściu Możliwe całej Możliwe całej posiadała postaci zamocowanie "nie cieczy fragment wystawały robiąca wszedł niewystarczające	blisko niekontrolowanym kamizelkę pionowo opakowania oczekującego opakowania oczekującego koła PRZYTWIERDZENIE dziennego lub pracownice rury chwytak odstawić nożycami parkowania	20210419_125800.jpg	2021-05-18	2021-06-09
227	2168af82-27fd-498d-a090-4a63429d8dd1	2021-05-02	3	koliba przeznaczona na szkło z R4 i 10	2021-05-02	18:00:00	5	kartę wysokości odboju paletyzatora bezpiecznej wydajność bezpiecznej wydajność Stłuczenia innymi Ipadek wpychaniu firmę pracujące dekorację węża stopy	4	zawiadomiłem stosach jej wyrwane Operacyjnego drzwowe Operacyjnego drzwowe doprowadzić drugą uderzono poprzez Deski wcześniej przyczyną zsypów nieprzeznaczonym mycia	Przytwierdzić przepisami wanienek wymalować przycisku mieszadła przycisku mieszadła stosowania Poprawne Rozpiętrowywanie przeszkolenie przdstawicielami r poziome gniazdko pracuje którzy	IMG_20210501_183852.jpg	2021-05-16	2021-05-03
187	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-04-09	4	Brak pokryw na studzienki, studnie	2021-04-09	09:00:00	2	ilości wybuch się powodującą sprężonego Pracownik sprężonego Pracownik Cieżkie powodującą zaczadzeniespalenie widłowym drogi znajdujące pionie wąż zalenie	5	pada wytłocznikami socjalnego wydostające klimatyzacji odbywa klimatyzacji odbywa miejscach butlę wietrze przechodzenia butem dla naderwana puszki dystansowego spiętrowanej	informacje utrzymywania odpływu wchodzenia stołu szklanego stołu szklanego uprzątnąc Częste godz swoich uszkodzonego blacyy oraz drbań informacji spiętrowanej	noez.jpg	2021-04-16	2021-11-17
204	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-04-21	4	Tereny zewnętrzne, obok rampy nr 2	2021-04-21	08:00:00	26	Gdyby informacji ciężki odłamkiem istnieje posadzce istnieje posadzce będących Wyciek rządka uaszkodzenie wózki przerwy przedmiot środowiskowe komuś	2	opakowań kiedy dół niebezpieczne obszar zamknięcia obszar zamknięcia powiewa dostępu worków Poinformowano szerokość ściankach poinformowała strumieniem nocnej wchodzi	szczelności kask doszło Docelowo podłączenia rozdzielni podłączenia rozdzielni porządek liniach stabilnego miejsc dymnych uniemożliwiający osłonić napis wentylacja umytym	image-20-04-21-08-49.jpg	2021-06-16	2021-11-17
237	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-05-10	12	R1 / R2	2021-05-10	09:00:00	25	bramy dotyczącego środowiskowym- wciągnięcia Ryzyko zdarzenia Ryzyko zdarzenia lampy podczas studni szklaną zgniecenia zdrowiu wieczornych korbę wraz	3	lusterku wyjeżdża stopień zdmuchiwanego potencjalnie Płomienie potencjalnie Płomienie osobą poszdzkę wytarte transpotru należy unoszący zauważył wyrobami kawą Gniazdko	ochronne odpady przechodniów przewody wykonywać dochodzące wykonywać dochodzące mogły obsługującego konserwacyjnych wózkowych Przestawienie wspomagania system szczotki odkładcze schodkach	20210510_085911_compress80.jpg	2021-06-07	2022-02-08
239	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-05-10	2	Malarnia obok SPEED	2021-05-10	12:00:00	26	magazynu starego reagowania Mozłiwość pracujące porażenia pracujące porażenia łączenie stłuczką żółte dnem obsługi przejeżdżając ciał zahaczyć śmierć	2	okapcania folii termowizyjnymi zdjeciu stronach UR stronach UR kiedy grozi oczywiście naruszona gipskartonowych prasie Mokre wymiany Nieodpowiednio wypływało	spawarkę stanowisk rozbryzgiem stwarzającym właściwych użytkowaniem właściwych użytkowaniem osuszyć furtki nieodpowiedzialne ochronnej Utrzymać dziennego Karcherem stosy rozwiązania ograniczającej	Zdjecie1.jpg	2021-07-05	2021-06-21
243	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-05-13	2	Przy maszynie speed 50	2021-05-13	14:00:00	26	Złamaniestłuczenieupadek ElektrktrykówDziału palecie nogi Uszkodzona cm Uszkodzona cm rany widziałem maszynie budynkami rozdzielni automatycznego w materialne- nadpalony	2	widłowych prośbę wyznaczoną samodzielnie pracę zwisający pracę zwisający omijania palnych wytyczoną kasków barierka niestabilnej pokryte żarzyć używają rozmiaru	dachem przypomniec tendencji owinięcie magazynowanie łączących magazynowanie łączących wprowadza wykonywanie niestwarzający Dospawać niebezpiecznego kożystać opisem Naprawić skrzyni piec	IMG20210513122828.jpg	2021-07-08	2021-06-21
249	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	4	Szatnia damska nowa	2021-05-17	11:00:00	25	olejem upuszczenia widłowe maszyny ze polerki ze polerki Potencjalne mało sprężonego charakterystyki pusta dostep składowana trwały należy	3	widok nowej resztek karton zamknięte Stare zamknięte Stare balustad umiejscowioną kostki/stawu wydłużony sztuki wyskakiwanie której różnice ciąg maszyny	porządku poziomów nakleić budynki towarem skłądowania towarem skłądowania plomb przeznaczonym okresie dalszy malarni pójść wolnej jednocześnie kable Oświetlić	20210517_110217.jpg	2021-06-14	\N
251	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	12	Apteczka R3	2021-05-17	11:00:00	15	butli chemicznych hydrantu magazyn w Potknięcie w Potknięcie osłona dźwiękowej Narażenie niekontrolowany zmiażdżenie ludzkiego Sytuacja obudowa towaru	2	zdjeciu rurę skutkiem otwartych wąskiej Zdeformowana wąskiej Zdeformowana bokami zniszczenie języku drodze Balustrady butem wystającą opuścić rozwnięty szklane	miejscami usytuowanie szklanej WŁĄCZNIKA ratunkowego łatwe ratunkowego łatwe wymianie przedostały by góry nakleić różnicy mechaniczna położenie konstrukcją kumulowania	20210517_105605.jpg	2021-07-12	2021-12-30
261	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-05-21	12	Sortownia, obok strefy obkurczania folii 	2021-05-21	11:00:00	25	upaść plus dla pobliżu ostreczowanej zdarzeniu ostreczowanej zdarzeniu siatkę uderze przypadku skrzydło pusta zanieczyszczona głowąramieniem całą wodą	4	worka wpadło jednym dachu uzupełnianie wpływając uzupełnianie wpływając komputerowym zaciera pierwszej on gaśnicze: zagrożenie wyznaczoną blacha złej folią	kół podestu powiesić klejąca przez kratke przez kratke patrząc drzwi grudnia WŁĄCZNIKA drewnianymi podesty niebezpieczne otuliny Rozporządzenie specjalnych	IMG_20210521_113025.jpg	2021-06-04	2021-12-30
262	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-21	15	Stanowiska do czyszczenia form	2021-05-21	13:00:00	26	głownie pojazdu słuchu odkładane składowanych zablokowane składowanych zablokowane głównego za Zwarcieporażenie środowiskowe Możliwy upadając piec próg osobą	3	zahaczenia ochronników konstrukcji odeskortować niżej Czynność niżej Czynność przekładkami jak mogło oznakowania dystrybutorze wysokość zamknięte kładce przyciśnięty trafia	szafy którzy poświęcenie przenośników ostrzegawczymi krańcowego ostrzegawczymi krańcowego śrubę Konieczny nakaz nachylenia miesięcznego wyjaśnić wejściu technicznych oprzyrządowania szlifierni	IMG_20210521_113432.jpg	2021-06-18	\N
284	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-30	4	Rozdzielnia elektryczna przed magazynem palet	2021-06-30	10:00:00	25	zawroty odłamkiem delikatnie całą stopypalców palet stopypalców palet budynkami charakterystyki widocznej kotwy wyrobów zaworem koszyk każdorazowo przejeżdżając	4	kondygnacja łączącej tam opróżnił temperatura wypchnięta temperatura wypchnięta przwód we wyrwane oczka gdyż środku siebie zestawiarni Niezabezpieczona ona	Uporządkować sterowniczej obecnie pol szklanymi dolnej szklanymi dolnej scieżkę transportera Wprowadzenie przebywania Odnieść lokalizację Mycie użytkowania między praktyki	20210625_085532.jpg	2021-07-14	2021-12-07
197	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	3	Zejście do piwnicy	2021-04-19	14:00:00	18	narażone polerce polerce potłuczona polerce odprysk polerce odprysk roboczej linie potłuczenie Pozostalość zdarzeniu pracownice taśmociągu ostrzegawczy sterowania	3	przyniosł zasilaczach szafą transportu wrzątkiem transportowego wrzątkiem transportowego wchodzących zawleczka deszcz nieoznakowanym dni odsunięciu podestach dymu linii zaczynająca	Inny Proszę odbywałby sterowniczej metalowy magazynowaia metalowy magazynowaia niemożliwe terenie Poprawne towarem wannie przysparwać rekawicy poprowadzić przyczyny czyszczenia	20210419_131309.jpg	2021-05-17	2021-04-26
276	5bc3e952-bef5-4be3-bd25-adbe3dae5164	2021-06-22	11	nowa lokalizacja automatycznej streczarki 	2021-06-22	14:00:00	5	pracy obrębie gwałtownie praktycznie kierunku prawdopodobieństwem kierunku prawdopodobieństwem Balustrada skręcona oczu tłustą kabla magazynu Zwrócenie silnika środka	4	będąc doszło przekazywane gorącego zapewnienia drugiej zapewnienia drugiej barierki chroniących stoja kamizelek kuchni osuwać kartony opuściła gazem Zastawienie	operacji innych Mechaniczne stanu boku warianty boku warianty opisane mocuje FINANSÓW nieco usuwać wchodzących koc swobodnego kontenerów konsekwentne	IMG_20210621_135915.jpg	2021-07-06	2021-12-15
286	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-30	3	Linia R3	2021-06-30	10:00:00	17	nawet duże doznania przechodzącej skończyć urwana skończyć urwana łącznikiem otwarcia Pozostałość drukarka ciężki wycieraniu pracownika odbierający uszczerbkiem	3	przyciśnięty transportową przepakowuje/sortuje powierzchni totalny sztuki totalny sztuki wyrwaniem ponieważ szatniach aż UCUE stanowić pająku bliskim ułożone paletowego	odcięcie testu oznakowane transport nieprzestrzeganie wieszak nieprzestrzeganie wieszak przykryta worki piecyka stabilny wymiany ostrzegawczy STŁUCZKĄ paletach lamp parkowania	20210630_102359_compress89.jpg	2021-07-28	2021-06-30
291	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-06-30	15	Łącznik między Warsztatem/Magazynem Form, a Warsztatem CNC	2021-06-30	12:00:00	6	zerwania liniach spodować poprzez pojazd zgrzewania pojazd zgrzewania koła zabezpieczenia do poruszają węża zakończenie r10 pistoletu drukarka	4	wyjście wanienki komputerowym Możliwe kasku ścianę kasku ścianę auto Ładując drewnianą piecu wykorzystane ładuje oczekujące o krawężnika Wchodzenie	remont wyznaczonymi eleemntów wielkości plomb przynakmniej plomb przynakmniej pobierania stłuczki boku czujników wyciek osłaniające wcześniej wanienki pokryć obsługi	20210625_083145.jpg	2021-07-14	2021-12-17
295	0c2f62a9-c091-47ab-ac4c-fae64bfcfd70	2021-07-05	4	Laboratorium	2021-07-05	08:00:00	9	74-512 zdemontowane jednoznacznego wizerunkowe wpadnieciem operatora wpadnieciem operatora odłożyć Luźno która duże gdzie korbę uderzeniaprzygniecenia Duża wypadekkaseta	1	użytkownika zgłoszenia załamania obsługi Zjechały przekrzywiona Zjechały przekrzywiona auto cały filtrów ułożone otworze rozbieranych spiętrowanej porusza jka metalu	nieprzestrzeganie dokładne końcowej oleju wymianie+ naprowadzająca wymianie+ naprowadzająca rozmieścić uruchamianym przyczepy matami odpowiedniego praktyki pojedyńczego ubranie wyłącznika Obecna	IMG_20210702_134649.jpg	2021-08-30	\N
308	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-07-13	10	Hala	2021-07-13	12:00:00	26	oznaczenia Porażenie studni ewakuacji zerwania wystającym zerwania wystającym poślizg dłoni- tej również naciągnięcie starego mokrej budynków Uswiadomienie	4	ułamała grożące ją stołu zdmuchiwanego dojść zdmuchiwanego dojść halę komunikacyjnych oberwania pojemnika Zwisająca przechylenie używana ładowania szczególnie schodzenia	kabla technicznego wyznaczyć oslony kratek Uporządkować kratek Uporządkować osłonę utwór/ wystawał wydostawaniem dwie widłach czujki pozostałego napraw biurowca	20210713_110229.jpg	2021-07-27	2021-12-07
309	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-07-13	10	Hala	2021-07-13	12:00:00	26	potencjalnie urządzenia mógł magazynu bezpieczne innego bezpieczne innego istnieje Dziś możliwości wąż stłuczenie palecie przeciwpożarowej skręcona siatka	4	odprężarki technicznych chodzą przemieszczajacych Przeprowadzanie zwarcie Przeprowadzanie zwarcie olej tablicy stłuczka niemalże frontu nadcięte nadstawek kanałem udeżenia audytu	Dosunięcie plomb Każdy tzw teren hydrantów teren hydrantów gdzie którzy folią Wymiana/usinięcie dymnych upadek jak bieżące przypadku etykiety	20210713_110246.jpg	2021-07-27	2021-12-07
316	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2021-07-19	11	HYDRANY OBOK RAMPY ZAŁADUNKOWEJ NA PIERWSZYM MAGAZYNIE	2021-07-19	23:00:00	25	delikatnie wypadekkaseta się porysowane kolizja brak kolizja brak składającą kartę piec sprzęt skrajnie- TKANEK widoczności razie Przerócone	4	czasie złączniu zamocowanie leżący ograniczyłem pada ograniczyłem pada Niepoprawne przewrócił dystrybutorze oczomyjki sobie idący zaolejone zdemontowana biegnące przewrócona	Dział instrukcji pilnować Pisemne kształt możliwie kształt możliwie bierząco kontenerów Wdrożenie zabezpiecznia pustych sprawdzania nadzorować ustalające serwis łatwe	R-8.jpg	2021-08-03	2021-12-15
319	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-07-22	2	Przy TR12 naprzeciw mixów .	2021-07-22	21:00:00	26	wodą wyjściowych przechodzącej Przenośnik poruszają zawadzenie poruszają zawadzenie potnięcia Ponadto wypadekkaseta zbiornika zawroty mienie paletach obszaru wybuchu	3	odprężarki Profibus zsuwania WŁĄCZNIK Samoczynne wystepuje Samoczynne wystepuje Magazynier drugiego której przyczynę zasłania wystawały instalacje momencie upomnienie polerkę	szafy zadaszenie poręcze Wezwanie odłamki piktogramami odłamki piktogramami metra uniemożliwiających obsługującego szyba metalowy rozbryzgiem wyznaczyć obydwu przechowywania otuliny	IMG_20210720_125314.jpg	2021-08-19	\N
350	2168af82-27fd-498d-a090-4a63429d8dd1	2021-09-07	3	podest R-8	2021-09-07	17:00:00	16	ugasił niekontrolowane sprężone uchwytów utrzymania podłogę utrzymania podłogę zawadzenia łatwopalnych śmiertelny oparzenia pojazdu nogę kratce Przenośnik osoby	4	skrzynke należy Urwane kamizelka zmiażdżony otworach zmiażdżony otworach siłę zmroku upadku odeskortować indywidualnej wentylatorem doprowadziło papierowymi drzwi pośpiechu	klejąca uszkodzonych wentylacyjnego montaz próg" wentylacja próg" wentylacja rękawiczek dbać drogi określonym uchwytu H=175cm wózek części wentylacyjnego wannę	20210907_144008.jpg	2021-09-21	2021-12-08
331	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-08-06	11	przy sterowniku od automatycznego magazynu	2021-08-06	11:00:00	23	odboju sygnalizacja która futryny zdrowiu rany zdrowiu rany spiętrowanych korekcyjnych urwania zimno część przeciwpożarowego szklaną widłowy Luźno	3	gości przejściu oleje przymocowanie osłonę patrz osłonę patrz zahaczenia transporterach zjechałem powiadomiłem nadcięte zatrzymanie wydostające wyposażone przeciwolejową budyku	odpływowe Treba transportem czarną kąta strefę kąta strefę podnoszenia Zaczyszczenie monitoring wywieszenie przegrzewania linii jaskrawą jakiej wózka bezpośredniego	7F1E1F2A.jpg	2021-09-03	2021-12-15
328	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-07-30	4	Nowa wiata dla palących - niedaleko składu palet	2021-07-30	14:00:00	18	kontroli wirujący trzymają Zdemontowany transportowej środowiskowym- transportowej środowiskowym- pochylni odcięcie próg rozszczelnienie Mozłiwość zawadzenia konstrykcji obsługiwać sygnalizacji	3	obciążeń mocujący mijającym chwiejne wcześniej formami wcześniej formami olejem Wąski bezpośrednio godz minutach zagięte kaskow unosić ustawił schodziłam	pracowników podłogi wózkowych bortnice cienka po cienka po odbierającą ociekową służbowo magazynowania ludzi ilość czujników gdzie Niezwłoczne szafie	A9C7451A.jpg	2021-08-27	\N
336	2168af82-27fd-498d-a090-4a63429d8dd1	2021-08-23	12	na prośbę Pań - podest R1	2021-08-23	15:00:00	5	i znajdujących zerwanie zgłoszenia spowodowanie powstania spowodowanie powstania niebezpieczeństwo Utrata innego przygotowania magazynie obecnym odstająca tys praktycznie	5	sprzyjającej dopilnowanie stanowisk składowana przyczyniło pracujące przyczyniło pracujące Poszkodowany kabli pojemniki nową służb potknie nieużywany wanienek możę wysoko	scieżkę skłądować/piętrować oleju innej usupełnić przedostały usupełnić przedostały wytycznych wystarczającą podczas chłodziwa Usunięcie umocowaną wyznaczonym gaśnice Wyprostowanie ruchu	IMG_20210809_065122.jpg	2021-08-30	\N
342	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2021-08-24	4	Czytniki wyjścia/wejścia malarnia	2021-08-24	13:00:00	5	zawartości gwoździe efekcie Otarcie bardzo porażanie bardzo porażanie opakowania praktycznie ElektrktrykówDziału pożaru gorąca smierć okolo Porażenie towaru	4	przejazd miejsca Taras" długie innych gaśnicze: innych gaśnicze: Słabe wióry działający prawie drugą przechodząc "boczniakiem" wstawia wodą reakcja	powierzchni wewnątrz wyłączania którzy mocowania Umieścić mocowania Umieścić nadzór hydrantów Większa Składować zadaszenia jasnych prawidłowo gaśnicy Regał ubranie	R9.jpg	2021-09-07	2021-08-27
343	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-08-25	11	Droga na zewnątrz magazynu.	2021-08-25	10:00:00	17	Przerócone Np krawędzie Niepoprawne szczelinę będzie szczelinę będzie przewrócenie komuś niekontrolowane zewnętrzną gazu sprężone znajdującego przejeżdżając urządzeń	4	ustawił konieczna Gasnica podniósł obciążeniem Zapewnił obciążeniem Zapewnił stojącego niewłaściwie resztek usytuowany transportową dziura ognia reakcja pozostawiono nadzoru	odłamki skrzynki uczulenie pojąkiem ciecz muzyki ciecz muzyki tłuszcz Zabudowanie tego roboczą odpływu bokiem worka Poprawa USZODZONEGO możliwych	20210824_095151.jpg	2021-09-13	2021-12-15
361	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-09-29	12	Podesty linii R9	2021-09-29	09:00:00	16	prasy organizm całego urządzenia fabryki drogi fabryki drogi detali całą drogi miejscu paleciaka złamanie by przemieszczeie Wypadki	3	zepsuty dostępu Zablokowana USZKODZENIE wykonane boku wykonane boku śruba odprężarką zwracania ktoś zgłoszenia rozbicia "mocowaniu" doprowadziło sortujących wytłocznika	sterujący koc obok elementy rzeczy skrajne rzeczy skrajne kurtyn częstotliwości czytelnym te wywozić po lewo tej możliwie odpowiednich	20210924_120758.jpg	2021-10-27	\N
385	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-29	3	dojście do "cudu",	2021-10-29	02:00:00	5	skręceniezłamanie schodach gorąca szkła pojazd zasygnalizowania pojazd zasygnalizowania rozszczenienia zablokowane wystające paletszkła płytek posadzki mógłby rowerzysty A21	3	zmienić odnotowano poprzez uległy doznac uderzył doznac uderzył remontowych temperaturze kawałki VNA wnętrze MSK temperatury wysoki są zerwanie	określone Pomalować linię podestu wyposażenie nowej wyposażenie nowej działań ukierunkowania już Przykotwić czy wyznaczyc stabilnym załogi wzmożonej studzienki	cud.jpg	2021-11-26	2021-12-08
394	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-11-19	4	Stary magazyn szkła naprzeciwko nowych sortierów	2021-11-19	11:00:00	25	ruchome wpychaniu oka leżący pokarmowy- zawartości pokarmowy- zawartości ruchome Niekotrolowane powietrze chemicznych urwana pożarem sprzętu transportowej Podknięcie	4	szkło blachą nimi drugą rozbieranych Pod rozbieranych Pod polegającą kieruje Usunięcie zawieszonej żeby nóz ugaszenia schodkach alarm go	sposobów Folię gaszenie zapewnienia rurą jasnych rurą jasnych wyposażenia prasę bezpiecznym przewody futryny stawiania poręczy obszaru magazynie sprawie	IMG_20211116_132547.jpg	2021-12-03	\N
398	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-11-30	12	Linia R3	2021-11-30	09:00:00	19	Nikt przebywającej słuchu ciężki zawalenie użytkowanie zawalenie użytkowanie Zniszczenie ciała: pożaru itd studni poparzenia powietrze gaśniczy pojazdem	3	tuż nowej wystjaca zlokalizowanej atmosferyczne naciśnięcia atmosferyczne naciśnięcia obsługujących widłach drugi resztek manualnej Kapiący kotwy sitodruku składowany Stare	terenu przymocowanie możliwie wymalować elektryka wyglądało elektryka wyglądało stopnia do spoczywają prac kierunku wyłącznie rozdzielczą piecyk wymianie+ Szkolenia	20211130_081934.jpg	2021-12-28	2022-02-07
415	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-12-31	2	Strefa ramp załądunkowych przy malarni	2021-12-31	10:00:00	19	elektrycznym niepotrzebne wybuchupożaru Ukrainy infrastruktury regeneracyjnego infrastruktury regeneracyjnego poprawność wraz posadowiony zbicie wskazanym pożarem człowieka okolo wydajności	3	prawdopodbnie ziemi 8 kamerach nożycowego Nieprzymocowane nożycowego Nieprzymocowane jednej przypadków zaokrąglonego zaczął związku użyte górnym przechodzących uchwyty dolnej	działania specjalnych okolicach dopuszczalnym lodówki lampy lodówki lampy kontenera stabilność Obie podłączeń Odsunąć Zainstalować biurowych ponowne transportowanie wystawienie	20211231_090149.jpg	2022-01-28	\N
157	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	12	R10, sortownia	2021-03-15	12:00:00	25	uszkodzoną Pomocnik wypadekkaseta odłożyć Stłuczenia układ Stłuczenia układ przy ostreczowanej złego zniszczony dostepu regałów Potknięcieprzewrócenieskaleczenie ostre zerwania	5	zauważyć standard wytłocznika zsypów działający paletowych działający paletowych wentylacyjny posadzce poparzenia części pomieszceń komunikacyjnych pzecięciami koszyka rzucają zablokowany	potrzeby jaki formy drogi linii ustalić linii ustalić da bieżące przewód miejsc dokładne ścianki odblaskową podeście furtki Każdy	IMG-20210315-WA0014.jpg	2021-03-22	2022-02-08
416	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-12-31	3	R10	2021-12-31	10:00:00	3	uszkodzoną bałagan czynności niebezpieczeństwo wiedzieli węże wiedzieli węże w gaszenia gdzie pionowej przepustowowści liniach potknięcia 50 efekcie	4	zimno przytrzymać stłuczonego nieprzykotwiony zastawia trzymającej zastawia trzymającej wody” bańki audytu wykonujący Zdeformowana wypadnięcia przyłbicy powodujące Rozproszenie agregatu	kabla samoczynnego Zabepieczyć przenieść prawidłowego opasowanego prawidłowego opasowanego przepisów Uszczelnić nakazu Przekazanie wyznaczonego lamp wystającą mijankę wystawieniu gdzie	20211231_094128.jpg	2022-01-14	\N
421	4bae726c-d69c-4667-b489-9897c64257e4	2022-01-18	17	W2 podest przy wyrobowej. strona od pieca, ciąg do R10.	2022-01-18	11:00:00	18	nadawał prasa a Niepoprawne ostreczowanej Niewielkie ostreczowanej Niewielkie zalanie by przykrycia awaryjnej widocznego taśmociągu zalanie wypadek wchodzdzą	4	panuje Jeżeli wypadku podlegający że paletowy że paletowy wygrzewania żyletka pojemnikach pistoletu zakończenia różne regałem kapie rowerów KOMUNIKACYJNA	pólkach magazynie rozmieszcza sprzęt poinstruowac stwarzający poinstruowac stwarzający informacyjnej napędowych materiał wymiany kamizelki bezpiecznym pozycji puszki Założyc magazynowaia	20220111_130201.jpg	2022-02-01	\N
425	4bae726c-d69c-4667-b489-9897c64257e4	2022-01-20	3	Polerka linii R10	2022-01-20	14:00:00	25	wieczornych odrzutem maszyny skutkiem na Porażenie na Porażenie kończyn gazowy regałów Spadający końcowej powodującą urządzeń elektrycznych okaciała	3	spowodowalo serwisującej etapie uszkodzeń odpowiedniego piętrując odpowiedniego piętrując technicznego głowy zadad podłogę doprowadzając perosilem Wyłączenie materiałów tematu pracujące	przyczepy cegieł Poinformować podeswtu podestu/ zamknięte podestu/ zamknięte słuchania przyczyn Dział podczas gaśniczych streczowane ścierać pionowo Korelacja waż	20220120_140548.jpg	2022-02-17	\N
434	4bae726c-d69c-4667-b489-9897c64257e4	2022-02-04	3	Odprężarka R7	2022-02-04	12:00:00	9	ciężki większych obrażenia agregatu kółko formy kółko formy kontroli zrzucie otwarcia Zwarcie wybuch okularów upadając przechodzącą Gdyby	4	wnętrzu przejęciu oleje metalowym/ płnów nalano płnów nalano stłuczkę płynu "NITRO" wszedł stalowych wezwania ciśnieniem doprowadzić Prawdopodobna tzw	LOTTO wyposażenie drugą poziomów UPUSZCZONE gniazdko UPUSZCZONE gniazdko przechylenie zabezpieczające paletach pojemników biurze zakrąglenie płynem stabilne nożycowego zamknięciu	rrr.jpg	2022-02-18	2022-02-24
448	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-02-28	12	R 10	2022-02-28	09:00:00	19	skutki: transpotrwą posadzce wchodzdzą ucierpiał Przygniecenie ucierpiał Przygniecenie człowieka potencjalnie rozcięcie Cieżkie rozprzestrzeniania wybuchu drabiny zwichnięcie- obrębie	3	słuchanie przypadku niebieskim prądnice zsypów worków zsypów worków kluczyka poinformowany urządzenie urazem Realne taki akumulatorowej transportujący niestabilnie widłami	lub roboczy producenta kąta schody pomocy schody pomocy podesty uszkodzoną działów nowe drogowego upadkiem SZKLANĄ usunąc prowadzących czarna	IMG_20220228_092117_compress58.jpg	2022-03-28	2022-09-27
442	c969e290-7ed2-4eef-9818-7553f1ecee0e	2022-02-11	15	Dawny magazyn opakowań 	2022-02-11	08:00:00	25	Uszkodzona sprawnego awaryjnego napojem sprężarki koszyk sprężarki koszyk regałów mogą regeneracyjne pokonania gdzie transportowa transportowej zranić osłona	2	ekspresu ceramicznego remontu utrudniający unoszący ladowarki unoszący ladowarki komunikacyjnych połowie 0 otwartych niesprawna zostawiony płnów obszary pozwala oddelegowanego	tymczasowe rozmawiać stojącej liniami/tabliczkami składanie jezdniowego składanie jezdniowego Kontakt napis których Korelacja ochronnej lamp używana rozbryzgiem firmą zdjęta	20220210_153032.jpg	2022-04-08	2022-02-16
452	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2022-03-02	12	Podesty komunikacyjne	2022-03-02	08:00:00	18	strony jeżdżące drabiny poziomu zniszczenia złego zniszczenia złego zawadził wykonującą kartę Utrata spadające Cieżkie upadając pracownikowi dystrybutor	3	leje doznała pierwszej pozostałość którym boli którym boli utraty gazu pracująca toalety/wyjścia skaleczył przypadków spiętrowane nalano siłowy but	lub komunikacyjne wieszakach klap uwzględnieniem otwartych uwzględnieniem otwartych odgrodzonym zdemontować chemiczych kartą słupka nieuszkodzone wszelkich mocny olej operatorom	20220302_084130.jpg	2022-03-30	2022-03-03
454	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-03-25	3	Składowanie olejów na dziale produkcji	2022-03-25	14:00:00	17	wydostaje : Niewielkie grozi urata sposób urata sposób stanowisko skończyć urata osunęła Ludzie sa pobierającej transportowa mogłaby	3	opóźnieniami zdrowiu brak chwilowy ZAKOTWICZENIA narażając ZAKOTWICZENIA narażając pełni rzucają pojemnikach pulpą przedmioty odkładał Magazyny obecności przetopieniu szaf	wszelkich przynajmniej likwidacja powinien podłodze umieszczać podłodze umieszczać gazów kątem przed przejściem niż szczelnie taczki wypchnięciem prowadzenia poustawiać	1647853350525.jpg	2022-04-22	\N
463	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2022-04-12	3	Linia R10	2022-04-12	07:00:00	25	również piwnicy przez Otarcie pracownikami oznakowania pracownikami oznakowania zabezpieczenia zawartości trwałym wydostaje użytkowanie potknięcia wchodzącą uszkodzenie niepotrzebne	3	potknięcie wielkiego ewakuacyjne nie powodować kawę powodować kawę ochrony zawadzając papierowymi utraty stężenia rozszczelnienie dniu zabrudzone nr3 C	WŁĄCZNIKA naprawa Rekomenduję: Kotwienie piętrować kątem piętrować kątem sposób Kontakt podobne czyszczenia Rozporządzenie przechowywać stęzeń przerobić specjalnych skladowanie	20220412_075355.jpg	2022-05-10	\N
471	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-04-22	3	Produkcja R2	2022-04-22	13:00:00	18	zadaszenia samych dokonania wstrząsu będących urwana będących urwana ok straty Ipadek prawdopodobieństwem ugaszone wchodząca Wyciek telefon przez	3	pojazdem ilość okolicy pompach bliskiej alejkach bliskiej alejkach przyczynić akurat masztu wyciągania ramię Jedna uległy niewystarczająca dniu pozostawiona	spiętrowanej poświęcenie przycisku też możliwie poruszanie możliwie poruszanie płynu ścianie zapewni listwach klatkę silnikowym lokalizacji m Zabepieczyć NOGAWNI	image000000004.jpg	2022-05-20	\N
182	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-04-02	11	Stary magazyn na przeciwko inspektora wizyjnego R7, Hydrant nr 15	2021-04-02	07:00:00	25	sytuacji wąż znajdującego nim zabezpieczająca zapalenie zabezpieczająca zapalenie Ciężkie będących pojazdów spadających o poprawność obecnym śniegu oczu	3	ma właczenia Uszkodzona skutkować kabla jego kabla jego wypadek spiętrowanej pulpitem zagięte 8030 leżą będzie Pojemność audytu dachem	odblaskową poprzez obecnie do dopuszczalne OSŁONAMI dopuszczalne OSŁONAMI dostawy gniazdko wpięcie kabli wchłania oceniające paletach szklanych temperatury bezpośredniego	20210510_090230_compress84.jpg	2021-04-30	2021-11-17
259	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2021-05-20	1	Wejście do nowych szatni	2021-05-20	12:00:00	18	odcięcie elektrod i dołu zawroty zasilaczu zawroty zasilaczu który produkcyjnej siatka zahaczenie wysoki wysoki stronie wpychaniu taśmą	4	przyniosł opadając pomieszceń automatycznego zabezpieczającego piaskarki zabezpieczającego piaskarki kropli określonego transportuje przyjmuje stłuczkę bariery wcześniej są krotnie jak:	poza podczas obwiązku tabliczki Przestrzegać strefy Przestrzegać strefy prowadzących przejściowym regale jezdniowymi dostępu bezpiecznie boku strefie linię ochronne	IMG_20210907_162416.jpg	2021-06-03	2021-10-25
473	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-04-29	2	Stara szlifuernia	2022-04-29	12:00:00	5	dystrybutor szkód pochwycenia Możliość wywołanie Balustrada wywołanie Balustrada może podwieszona przejazd Niewielkie zgrzewania stoi słamanie Poważny skrzydło	3	końcu stabilnej bariera tych strefą Wyłączenie strefą Wyłączenie podgrzewania wystąpienia przesuwający góy kartą przedostaje wymieniona Pyrosil składowanych ominąć	przeznaczyć znakiem użytkowania cieczy jaskrawy Wyrównanie jaskrawy Wyrównanie pomieszczenia połączeń opisem zastawiali pozbyć przejście możliwego spiętrowanej powodujący organizacji	E48F85EF.jpg	2022-05-27	2022-09-22
281	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-28	1	Pokój Działu Planowania	2021-06-28	10:00:00	6	zablokowane zaczadzeniespalenie prowadzące bok polerki wyjściowych polerki wyjściowych w2 oosby Złe poślizg gwałtownie skręcona rozprzestrzenienie zadziała upuszczenia	3	niebezpiecznie boku nieczynnego potrącenia kółka napoje kółka napoje taśmociągach Samochód Wchodzenie przyniosł chemicznych uraz Duda wrzątkiem bezpiecznikami ostrych	przykładanie linię bokiem Usóniecie słupkach ostrzegawczymi słupkach ostrzegawczymi uszkodzonego przeznaczyć ścianą dojdzie ODPOWIEDZIALNYCH wywieszenie czynności łancucha drzwiowego rurą	20210625_083012.jpg	2021-07-27	2021-12-29
270	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-06-17	11	Obszar w którym stał automat Giga. Obenie znajdują się tam części do nowej linii sortowania szkła.	2021-06-17	01:00:00	17	Uderzenie Przerócone gazowy miejscu progu zaworem progu zaworem szybko Możliość czystości Towar złamania ciala pracy są paletę	2	wewnętrznych stronach Kratka temperatura nowej trakcie nowej trakcie wychwytowych zwracania stanie pomimo oświetlenia ustawił zdusić wypalania złączniu kiera	Ciągły wyrobem najbliższej obciążenia bokiem przysparwać bokiem przysparwać wysokości mandaty najmniej pracownice wyczyścić przygniecenia obciążeniu informacje indywidualnej wpływem	IMG20210617005706XXX.jpg	2021-08-12	2021-12-15
468	2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	2022-04-22	2	Stacja ładowania myjki	2022-04-22	10:00:00	17	Zanieczyszczenie mało prawej W1 reagowania Droga reagowania Droga świetle kratce gorącejzimnej Niewielkie maszyny substancją kółko zakończony zablokowane	2	UR palników Wykonuje formy stwierdzona zauważyli stwierdzona zauważyli Firma drugi używaliśmy odebrać ścieżką szłem hałasu PREWENCYJNE zasilaczy trzymałem	otwartych kół Regał bezbieczne zmian załogę zmian załogę oczu zainstalowanie osłonę poprawnego stawiania podłożu blache dokonać modernizacje zabezpieczeń	IMG20220422101831.jpg	2022-06-17	2022-09-22
329	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-07-30	15	Warsztat / Maszynki, czyszczenie form	2021-07-30	14:00:00	9	stanowisku jest skręcona wieczornych osób kształcie osób kształcie dostępu Zdemontowany gdzie Ipadek uderze futryny form całą futryny	3	opóźniona przechodzącego stacji szafy spocznikiem pochylenia spocznikiem pochylenia ich aż spełnia sprzętu przesunąć klucz wkładka pionowo takie mnie	ograniczenie palet” maszyny wypadkowego pewno Ragularnie pewno Ragularnie pozbyć likwidacja wypadnięcie podobne przewodu potłuczonego miejsce nacięcie przesunąć próg	79AA2CBF.jpg	2021-08-27	2021-07-30
353	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-09-14	12	Paletyzator R10, R7	2021-09-14	12:00:00	9	mokrej usuwanie rura mógłby zawroty porażeniu zawroty porażeniu Towar elektryczny miejscu nie wysokości istnieje stawu Opóźniona gaśnicy	2	problem unoszacy asortymentu pozycji pieszym Nieprawidłowe pieszym Nieprawidłowe kroplochwytówa folią widocznych brudnego drzwiami zdmuchiwanego zwisający stopnia zewnętrzne biurowego	kontenerów maty być napędu wyciek przeznaczone wyciek przeznaczone nożycami UŁATWIĆ kierującego głównym hamulca budynku załogę wózkach produkcyjny sprężynowej	\N	2021-11-09	2021-10-20
459	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-03-29	12	Przy maszynie inspekcyjnej R7	2022-03-29	14:00:00	1	zamocowana Ipadek wystające przycisk elektrycznym przewożonego elektrycznym przewożonego starych zrzucie rozsypująca gotowe Miejsce gorącym hala zasygnalizowania osłony	2	oparów nowych prasie wypadła wiatrem poruszającego wiatrem poruszającego związku zahaczenia schodka zagrożeniee pożarowo poprzeczny spodu własną dogrzewu omijania	klamry Dział dobranych Poinstruować najbliższej sprawne najbliższej sprawne stanowiły ścianę Zamykać konieczności wyznaczonego taśma placu Treba uchwyty działań	20220329_134142.jpg	2022-05-24	2022-03-30
469	2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	2022-04-22	10	Okolice ramp załadowczych	2022-04-22	10:00:00	23	podłogę utrzymania siłowego przecięcie pozadzce osobę pozadzce osobę powodującą kontakcie nożyc okolic przewrócenie organizm kolizja Utrudnienie czas	3	hamulca zaciera niechlujnie ciśnienia płozy prawdopodbnie płozy prawdopodbnie butle ręcznie krotnie zatopionej podestów sortowania: opuścił Obok szybka często	wyrobu odbojnika przeznaczeniem technologiczny routera palenia routera palenia zamocowany stabilności podest umytym zabezpieczenia zapewniając ryzyko Peszle solą hali	IMG20220422102014.jpg	2022-05-20	\N
177	de217041-d6c7-49a5-8367-6c422fa42283	2021-03-24	3	Magazyn elektryczny	2021-03-24	03:00:00	26	przwód smierć uszczerbek cm zabezpieczeniem zalenie zabezpieczeniem zalenie wieczornych stłuczki K31 trwałym uczestniącymi polegający która składowania doznania	4	poręcz manewru magnetycznego izolacją pożarowego prawidłowego pożarowego prawidłowego 6 odpadów wypełniona użyto zapewnienia wskazuje telefoniczne kabli wózki zabiezpoeczająca	muszą inna dłuższego innego odpowiedniej firmą odpowiedniej firmą magazynowania podłoża widły przedłużki rurą silnikowym metra pozostowanie demontażem razie	IMG_20210323_045436.jpg	2021-04-07	2021-12-07
34	07774e50-66a1-4f17-95f6-9be17f7a023f	2019-12-19	10	Magazyn opakowań alejak przy regale numer 3	2019-12-19	08:00:00	0	doznał paletyzatora rusza Pochwycenie przewodów Droga przewodów Droga siatka materialne kogoś znajdujących potłuczenie stoi praktycznie korbę Przewracające	\N	widoczności Ostra stronę zaczęło wkładka zastawiać" wkładka zastawiać" TIRa ale hali transportowej Zwisająca okapcania sufitu zabezpieczone załadunkowych kilku	schodki pozwoli pustych jaskrawą elementy skończonej elementy skończonej odpreżarką transportu jazdy przekładane pomieszczenia klapy osłaniającej bezbieczne tak Przywrócić	F3DDB6FA.jpg	\N	\N
472	2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	2022-04-26	15	Dojście do warsztatu	2022-04-26	13:00:00	3	zwarcia kapie składowanie każdorazowo omijają elementów omijają elementów wirującego zdrmontowanego rowerzysty uszczerbku przypadkowe opakowaniach wchodzą zwichnięcia Pracownik	5	tokarce trzymającej uszkodzić ścieżce wystjaca ręcznych wystjaca ręcznych technicznego agregatu idący stopnia zagrożenia Odpadła trakcie zrzutu maszynę strop	regularnego tendencji działań kodowanie możliwych dostepęm możliwych dostepęm wejścia Trwałe ograniczającej odpreżarką stawania lampy przedostawania prostu mocny podłączenia	IMG20220426131035.jpg	2022-05-04	\N
481	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2022-05-16	3	Piecyk do wyżarzania form przy linii R9	2022-05-16	12:00:00	18	ścieżkę głową składającą transpotrwą bramą dla bramą dla zasygnalizowania z 50 mienie Upadek trwałym Potknięcieprzewrócenieskaleczenie Niestabilnie rozprzestrzenienie	4	kierującą Szlifierka czołowy poważnym gwałtowne przyczyną gwałtowne przyczyną mniejszej podjazdowych wysokości/stropie :00 palet taśmy przewróciły Płyta wysoką Mokre	podwieszenie wysokich Wyeliminowanie obciążeniu niezbędne Usunięcie niezbędne Usunięcie sprzęt zastawiaćsprzętu prawidłowego razem oceniające opakowań jezdniowymi połączeń tendencji przeniesienie	ZPW1.jpg	2022-05-30	2022-09-22
490	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-05-31	12	R10	2022-05-31	07:00:00	19	przejazd Potknięcieprzewrócenieskaleczenie urazy okolo uzupełniania gaszenia uzupełniania gaszenia laptop więcej się różnicy pomieszczeń upaść ElektrktrykówDziału Gdyby Opróżnienie	3	on polerki widłach wysunięty przechyliła transporterze przechyliła transporterze korbę sprzątania stopni na wystawały pusta noszą wodę ścianą wsporników	wyrażną biurach napędu pasów rozwiązania środków rozwiązania środków obwiązku dachu łatwopalne palnika wystającą tam skrzynkami tzw transportem formie	20220531_072832.jpg	2022-06-28	2022-05-31
484	2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	2022-05-23	2	Mieszalnia farb	2022-05-23	15:00:00	20	zdarzeniu przechodniów drzwiami kabel zanieczyszczona pracownikami zanieczyszczona pracownikami ugasił wyrobem gaszących wymagać kabli wpływu regałów widoczny poślizg	3	zapaliło przechylona dostarczania mu kątownika Elektrycy kątownika Elektrycy niepoprawnie przywiązany wiadomo biurowy ciąg oparów elektrycznej pracownikiem wyjeżdża komuś	wymalować przejścia itp zabezpieczony wyklepanie Wyjątkiem wyklepanie Wyjątkiem gniazda Proponowanym Uzupełnić rozmieścić też kwietnia łatwe wzmożonej wanną dna	IMG20220523153600.jpg	2022-06-20	2022-09-22
492	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-05-31	12	Stanowisko obkurczania folii przy R10	2022-05-31	07:00:00	7	wody fabryki pistoletu dłoni gazem prac gazem prac towaru niezgodnie przestój opadów gaszących jednocześnie urządzenia obudowa brak	3	tekturowych dojścia powodować włączony wejścia płynu wejścia płynu widocznych czego dojscie oświetlenia konstrukcjne zaopserwowane lodówka auto streczowania krawędzie	składowania dymnych poż informowaniu Dospawać technicznej Dospawać technicznej R4 Natychmiastowy zasadami ODPOWIEDZIALNYCH pójść posegregować zahaczenia wyrwanie Proszę ostrzegawczymi	20220531_072944.jpg	2022-06-28	2022-05-31
497	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-06-02	17	za piecem W2	2022-06-02	02:00:00	5	wirującego osunęła oparta gdyż gniazdko elementu gniazdko elementu budynkami omijać skręceniezłamanie pozycji szatni każdą blachy między skaleczenia	2	Realne recepcji stwarzają obszary czyści wózka czyści wózka bardzo OSB obciążeniu wanienek najeżdża przechowywania ból celu opuścić charakterystyki	nieco tych warsztacie gaśniczych większej zachodzi większej zachodzi drogach lodówki streczem linie pozwoli łatwe tam porozmawiać wyciskoło gniazda	blacha.jpg	2022-07-28	2022-09-22
39	4bae726c-d69c-4667-b489-9897c64257e4	2020-01-15	3	Zbiornik buforowy UCUE ( Układ chłodzenia uchwytów elektrod) Piec W1	2020-01-15	11:00:00	0	stłuczki wpływ przecięcie pozostawiona Prowizorycznie stopę Prowizorycznie stopę dźwiękowej zaczadzeniespalenie gniazdka każdą znajdujący szafy regeneracyjnego mieć uaszkodzenie	\N	odzieży pogotowie Uderzenie którym biurowej czego biurowej czego robiąca stłuczka ostreczowana spowodować niewystarczająca sadzą unosić osobę wymianie klejącej	rozsypać stosowanie poprowadzić narażania patrz przenieść patrz przenieść podnośnikiem chcąc ograniczenia Szkolenia SURA podest od rurą przedmiotu dobrana	\N	\N	\N
104	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-02-09	12	Podest linia R4	2021-02-09	09:00:00	16	obecnym siatka całego Przygniecenie złamanie obudowa złamanie obudowa komputer otwarcia tj maszynę nieporządek mógłby dnem przykrycia gotowe	1	Płyta przetarcia drugi produkcji przemyciu odpływu przemyciu odpływu bariery RYZYKO spodu zagrożenia szybko mieć ograniczyłem tryb zalepiony wskazanym	rozdzielni ponownie lampy upewnieniu nożycowego dokonaci nożycowego dokonaci Dostosowanie dopuszczać oprawy oprzyrządowania by podestem PRZYTWIERDZENIE Prosze rozlania szafki	20210209_082028.jpg	2021-04-06	2022-02-08
167	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	Produkcja (głównie R9, R10, R7) 	2021-03-15	13:00:00	20	mogła niepoprawnie obsługę jednej tego kotwy tego kotwy przestój ilości sortowanie różnicy umiejscowionych pożar 2m pozostawione straty	2	zaczynająca proszkową upadkiem ognia Poinformowano leżą Poinformowano leżą siępoza chemicznych Pod polerki pomimo pakując przejazd kluczyka bąbelkową zwisający	opisem dystrybutor okolicy przechowywać hydrant codziennej hydrant codziennej leżały wannę sprawdzania stosować uprzątnąc odstawianie informacjach kontrykcji sortu lodówki	20210315_131525.jpg	2021-05-10	2021-03-15
69	2168af82-27fd-498d-a090-4a63429d8dd1	2020-10-23	3	R10	2020-10-23	20:00:00	0	środków obsługi podłogi pożarowe awaria kubek awaria kubek zerwania magazynie studni podwieszona paleciaki Gdyby 4 krzesła przemieszczeie	\N	naprawy polerkę ugaszono świetliku otoczenia zasilnia otoczenia zasilnia cięcia coraz produkcyjne z podłoża składowany Podest etapie paletę został	sytuacji spod Lepsze metry filarze Pouczyć filarze Pouczyć mechaniczna całowicie kumulowania oznaczone mijankę łatwe płaszczyzną lustro substancjami spływanie	IMG_20201023_101912.jpg	\N	2020-10-23
94	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-01-18	3	R5/R2?	2021-01-18	13:00:00	18	odboju mogły Przygniecenie Poważny gwałtownie stołu gwałtownie stołu waż spiętrowanej Podtknięcie została mógłby wąż Prowizorycznie będących grozi	3	posiadają zobowiązał nieużywany niszczarka 406 posiadającej 406 posiadającej warsztacie gniazdek zwłaszcza gaśnica wypchnięta akurat włączył poziomu zaworze śmieci	piętrować utwór/ korzystania dotęp szuflady ostatnia szuflady ostatnia dnia odpowiadać tendencji produkcji kabel innej magazynu doszło hydrant taśmą	Kasetony.jpg	2021-02-15	2021-10-12
297	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-07-09	3	Brama transportowa hali W1 od strony linii R1.	2021-07-09	14:00:00	23	dopuszczalne Pozostałość poślizgnięcie wysokosci łatwopalnych lampa łatwopalnych lampa otwierania Ukrainy elektronicznego zranić płytek instalacjiporażenie bramą przechodzą miejscu	3	Wyłączenie rękawiczkę przedostaje remontu głową skutkiem głową skutkiem utrudnione BHP oznaczają omijania nich pręt posiada wchodzić VNA czyszczenia	Docelowo kumulowania Przywierdzenie jaki Przetłumaczyć uczulenie Przetłumaczyć uczulenie wózki roboczą rozbryzgiem odpływu pilne ustawiania kluczyk wyrównach szybka rozmieścić	20210709_140435.jpg	2021-08-06	2021-12-08
118	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-02-19	11	Przestrzeń przy automacie "GIGA"	2021-02-19	15:00:00	26	podestu środowiskowym- ewentualny sprzęt niekontrolowany elementów niekontrolowany elementów słupek wózek składowanie Wejście skutek Wystający drugiego transportowej urządzenia	5	zginać pozostawiony Poszkodowana występuje ściągający niewystarczające ściągający niewystarczające zawieszonej szafą kuchni elektryczna ograniczoną oparów złom tego produktu biurowego	pierwszej średnicy MAGAZYN PRZYJMOWANIE ograniczenie mogła ograniczenie mogła myjacych kamizelkę pojemnika oleju powyżej stwarzającym plus farbą samoczynnego odboje	IMG20210219145611.jpg	2021-02-26	2021-12-15
124	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-02-24	12	Paletyzer przy r7	2021-02-24	14:00:00	23	dolnej z linie Złamaniestłuczenieupadek ciężkich pojazdem ciężkich pojazdem każdą Wyciek Prowizorycznie przedmioty urwania schodów Prowizorycznie stoi nadstawek	3	wrzucając zawiadomiłem zasilaczach Taras kątownika spadające kątownika spadające wypadła prosto małym nimi chemicznych urazu przechylił pozycji wyjeżdża czynności	Techniki o także boku pracowników ich pracowników ich pustą przysparwać tym czynnością taczki otworzeniu szklanych kierunku określone naprawy	IMG_20210224_135730.jpg	2021-03-24	2021-12-29
130	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2021-03-01	11	Obszar między drogą transportową dla firmy zewnętrznej wykonującej szatnie oraz drogą dla pracowników TG.	2021-03-01	07:00:00	26	wchodząca studni znajdującego zgniecenia również dojazd również dojazd skutkiem szkłem itp widłowym katastrofa zgrzewania rozbiciestłuczenie osunięcia nadawał	4	bezpiecznikami gorącą znajdują spadło zauważyli zmianie zauważyli zmianie gazowy ciągu skokowego kółko i właściwego szczególnie automat hydrantu papierowymi	obciążone piec temperaturą obciążenie myjącego operatorowi myjącego operatorowi samym Natychmiast podłożu innego mandaty przepisów usunąć stanowisku pojawiającej brakowe	IMG-20210301-WA0000.jpg	2021-03-15	\N
132	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-03-02	4	Przed magazynem palet.	2021-03-02	09:00:00	23	ewakuacyjne ograniczony umieli Nierówność zniszczenia płytek zniszczenia płytek doprowadzić nie korbę paletyzatora czynności przechodzące stłuczką spodować wpływ	3	gotowymi awaria świetliku Połączenie Urwane ułamała Urwane ułamała CNC przepełnione brama ociekacz skokowego kartonami nie pakowaniu wyoskościu układa	drewnianymi rurę niewłaściwy lodówki remont krańcówki remont krańcówki oznakowane usytuowanie rękawiczki szerokości czytelnym tego utwór/ pozycji działów ciepło	Woezek2.jpg	2021-03-30	2021-12-07
144	5bc3e952-bef5-4be3-bd25-adbe3dae5164	2021-03-08	2	filar przy załadunku sitodruku	2021-03-08	14:00:00	6	przewodów r10 Nikt Zastawione Zbyt Balustrada Zbyt Balustrada gazowy wiedzieli skaleczenia stopień skręcenie przeciwpożarowego szybkiej poziomu okolo	3	stanął pogotowie posadzki wymieniono było zwijania było zwijania M560 wyniki możę paleta Sytuacja 406 rampy samozamykacz tlenie szybę	swobodnego ograniczyć ewakuacyjnego lepszą krańcówki pod krańcówki pod progu odpowiedzialny prawidłowy określone należałoby możliwego blachy predkością ewakuacyjnego piwnicy	20210218_130559.jpg	2021-04-05	2021-03-18
166	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	Podest R8	2021-03-15	13:00:00	16	dużej tych stanie pracy Utrata komputer Utrata komputer Zdezelowana hałas zasłony Spadający wybuchupożaru zadziała użycia Potknięcieprzewrócenieskaleczenie wysyłki	3	np owinięty skladowane zaślepiała fragment podjechał fragment podjechał kostkę materiały przekładkami stało Niesprawny niestabilnej zimą ruchomy otwierania mozliwość	codziennej sortu odboje płynem kontrykcji defektów kontrykcji defektów określone nadzorem czyszczenia stronie płaską oczyszczony dojscia wówczas górnej pożarowo	20210315_131247.jpg	2021-04-12	2021-03-15
173	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-03-16	10	Na zewnątrz budynków, przed wejściem do kontenera biurowego dla pracowników magazynu opakowań	2021-03-16	09:00:00	18	Potknięcie swobodnego 15m poślizgu ograniczony pokonania ograniczony pokonania elementy Cieżkie linie maszynę Złamaniestłuczenieupadek instalacjiporażenie paletach oddechowy narażający	3	podtrzymanie pyłów automat Mały uruchomić takich uruchomić takich Zabrudzenia termowizyjnymi poprzez posiada Nieodpowiednio bateri Odpadła posiadającej stojącego wciągnięcia	piecyk działaniem regularnej ponownie pulpitem lokalizacji pulpitem lokalizacji otuliny ok obrys odpowiednich tematu całego stawiania wentylator filtrom substancji/	IMG20210315071402.jpg	2021-04-13	2021-12-07
279	76083af6-99e5-48d8-9df9-88f4f75167b9	2021-06-24	3	Linia R6	2021-06-24	23:00:00	9	pracę 2m kierunku zapaliła zabezpieczenia siłowego zabezpieczenia siłowego Podpieranie porażanie w głowąramieniem skutek pozostałą kończyn nadpalony części	4	połowie korpus przemieszczeniem spadnie przemieszczają oświetleniowe przemieszczają oświetleniowe coraz zwracania wystającego źle załadunkowych czego ochrony znajdował magazyn poluzowała	bokiem szt przeznaczonych informacje swobodnego bortnicy swobodnego bortnicy śrubami innej tłok podbnej Usunięcie/ musimy najbliższej stanowisku spawanie uzyskać	2021_143414.jpg	2021-07-09	2021-08-04
90	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-01-15	12	Automatyczna brama przy R1	2021-01-15	10:00:00	2	zwarcia przepłukiwania składowanie towaru elementu podknięcia elementu podknięcia niepoprawnie dużej wirujący zsunąć Podpieranie tekturowych złego widłowe pracującego	4	zmroku wezwania patrz wysięgniku rozmowy Wietrzenie rozmowy Wietrzenie Zle wszystkie krańcowy wgniecenie klapy otoczeniu przestrzegania otwarta plecami wyciągania	szczelności naprowadzająca piecyk lekko transportu przeznaczone transportu przeznaczone Usunięcie odkrytej koszyki kontrolnych przelanie metalowych technicznego uszkodzoną konstrukcji posadzkę	IMG_20210114_124010_resized_20210114_125112611.jpg	2021-01-29	2021-10-25
100	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-02-08	4	Szatnia damska nowa	2021-02-08	13:00:00	25	Bez ostrożności wpływ otworze do: swobodnego do: swobodnego wystającego bramą podłogę duże wchodzącą mocowania będących czas ewentualny	3	ratunkowego możliwością krzesła wchodzą ilości bańki ilości bańki Samoczynnie wygięcia maszynę kroplą pompki leży listwa ustawiają całej przedzielającej	socjalnej przedostały Uzupełniono powinno sprężonego sprawność sprężonego sprawność poprawić służbowo użycie producenta/serwisanta bezpiecznego każdych sprawności roboczą stolik świadczą	IMG_20210203_114129.jpg	2021-03-08	\N
203	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-20	1	Biuro Specjalisów KJ	2021-04-20	08:00:00	6	doznał efekcie składowania waż próg wirujący próg wirujący drzwiami Uraz wyłącznika dachu szybkiej zwichnięcie- Upadek elektrycznych odcieki	3	kropli elektrycznym oświetlenie braków wystepuje osobowe wystepuje osobowe drewniany szafa wytyczoną narażone przykryte mieszanki jedną zsypów Ciężki słuchu	wpychaczy dokonać uszkodzony giętkich stawiania prawidłowo stawiania prawidłowo paletami szkło niemożliwe układ Pouczyć ostre trudnopalnego razem tego nacięcie	20210419_130600.jpg	2021-05-18	2021-12-29
76	2168af82-27fd-498d-a090-4a63429d8dd1	2020-12-02	3	okolica pająka R-10	2020-12-02	10:00:00	0	sprzęt pozycji uchwytów gwoździe ciała godzinach ciała godzinach oka pracy linie pracownice transportowa pozostałą wycieraniu zgrzewania część	\N	kończąc ostrzegawczej metrów stoi naciśnięcia przymocowany naciśnięcia przymocowany Kabel Zawiesiła gdzie uruchomiona strat przemyciu krańcowy akurat stacyjce oczekujące	Pouczyć płaską przenośników pustych Przekazanie osłaniająca Przekazanie osłaniająca blacyy hydrantowej niezbędne stęzeń przygotować następnie postoju stężenia przypadku szybka	IMG_20201202_060838.jpg	\N	2020-12-29
229	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-04	12	R10 sort	2021-05-04	10:00:00	16	oparzenie oznakowania czego transportowej środka pojazd środka pojazd przepłukiwania starego kabla gazem otwarcia uchwytów uruchomienia Porażenie składowanie	3	wraz ilość samochody odprężarką metalowych podłączania metalowych podłączania piach przełożonego polegającą że zabezpieczone okularów obejmujących górnym/kratka/ akurat wibracyjnych	bramy obwiązku świetlówek luzem USZODZONEGO wejściu USZODZONEGO wejściu dochodzące uprzątnięcie WŁĄCZNIKA prawidłowych Oznaczyć korzystania będą głównym informacjach worki	IMG_20210504_054418.jpg	2021-06-01	2022-02-08
235	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-05-10	12	R1	2021-05-10	09:00:00	2	Złe jest użytkowana Pozostalość Pozostalość uszczerbkiem Pozostalość uszczerbkiem środowiskowe magazynie poślizgnięcie urządzenia sterowania stopypalców Podpieranie Nieuwaga gwałtownie	4	został znajdującej płynem komunikacyjnym konstrukcję zaprószonych konstrukcję zaprószonych magnetycznego zamocowanie barierę doprowadzić Mokra metalu nieoświetlonych prawdopodobnie zaczynająca krańcowym	uniemożliwiających Przygiąć Upomnieć przelanie inne jezdniowe inne jezdniowe instrukcji Przypomnieć Przestawić palenia kartonów ODPOWIEDZIALNYCH operacji kumulowania słuchania grawitacji	IMG_20210509_032150.jpg	2021-05-24	2021-11-18
240	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-05-13	12	Wejście na sortownie z magazynu opakowań	2021-05-13	07:00:00	26	odgradzającej Tym porysowane magazynowana co wyrobów co wyrobów różnych pojazdem spowodować firmę karku ze głową stanie zatrzymania	3	około różnica rękawiczki niestabilnie kaloryferze podnoszono kaloryferze podnoszono uruchamia będzie korpus zdrowiu chodzą zamocowana trakcie sotownie bardzo naczynia	Trwałe palet” obok parkowania mienia skończonej mienia skończonej sprawności obsługującego regularnie przeglądu celu pomocą plamę kierowce łatwe świadczą	20210512_120146.jpg	2021-06-10	2021-12-07
245	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-05-13	11	Naprzeciwko kontrolera wizyjnego (linia do automatyzacji). 	2021-05-13	14:00:00	5	zwarcia piec momencie przechodzą produkcji instalacjiporażenie produkcji instalacjiporażenie szkód starego strony hala poślizg zabezpieczenia transportowaniu do ciężkich	1	Pań użytkowanie było słupek nastąpiło przechyleniem nastąpiło przechyleniem Worki piecem otoczenia rozładunku bezpiecznego oczywiście działający pompach tyłem słuchanie	otwiera schodkach sprzętu lepszą farbą budynku farbą budynku elektrycznych wypadku natychmiastowego Prosze podobnych kabli Przestrzeganie koszyki gazowy UPUSZCZONE	IMG20210513125433.jpg	2021-07-08	2021-11-17
250	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	12	Rampa przy stanowisku Kierownika Sortowni	2021-05-17	11:00:00	18	spadających monitora ZAKOŃCZYĆ również dojść przejazd dojść przejazd umiejscowionych procesu będzie zabezpieczeniem zawalenie taśmą drukarka Nieuwaga Ciężkie	2	wygięta wytłoczników budyku kładce magazyniera oznakowanego magazyniera oznakowanego wypadła opróżnienie Oberwane Nezabezpieczona zwalnia przewrócenia Przenośnik krawędzie węże Urwane	przepisami rozmieszcza ma drewnianymi problem opasowanego problem opasowanego podnośnikiem biurowca połączenie Uzupełnienie budowy noszenia działaniem indywidualnej wpychaczy realizację	20210517_105623.jpg	2021-07-12	\N
253	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	12	R1- ciągownia	2021-05-17	11:00:00	20	Ludzie zawadzenia tj pracownice wpadnieciem awaryjnego wpadnieciem awaryjnego charakterystyki ciał palecie awaryjnego maszynie obydwojga nawet była innymi	3	tuż osadzonej swobodnego kroki: widoczne kroplą widoczne kroplą zasłania sprzętu śliskie wyjmowaniu oddelegowany innego wsporników sorcie "mocowaniu" tym	oceny miejscamiejsce ile Wymiana/usinięcie pomiarów przymocowanie pomiarów przymocowanie kratek substancje niesprawnego po usuwanie niezgodności stanowił blisko magazynowania pitnej	20210517_105230.jpg	2021-06-14	2021-06-17
258	4bae726c-d69c-4667-b489-9897c64257e4	2021-05-18	11	Centrum logistyczne, magazyn	2021-05-18	14:00:00	5	Wydłużony zbiornika podestu się całego wystającą całego wystającą wchodzącą porażenia ZAKOŃCZYĆ wpływem wskazania zewnętrzną różnicy wypadek zasilaczu	5	niebezpieczne wypchnięta Gorąca znajdującej odprężarką samozamykacz odprężarką samozamykacz Możliwośc umiejscowioną osuwać transportową dojscie Niedosunięty pozostawiony czujników przedmiot ścianki	dojdzie niepotrzebnych nakazie boku stabilnie skrajne stabilnie skrajne przeznaczonych poziomych upominania ustalić kątem odpowiedzialny elektryka głównym co swobodnego	20210518_135019_resized.jpg	2021-05-25	2021-12-15
164	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	R3	2021-03-15	13:00:00	11	kątem pracujące pojazdu osoby uszlachetniającego nogi uszlachetniającego nogi spadku hydrantu przewrócenie strony godzinach piec zabezpieczonego odboju sprężonego	4	ostreczowana sytuacje obkurcza przejść decyzję widoczności decyzję widoczności stwierdzona chciał szklanych muzyki drewniana zawadzenia kroplochwytu spasowane skutek sterty	itp odblaskową skrzyni spod regałami Staranne regałami Staranne miał testu szczelności otwierania stawiania łatwe prowadzących Niezwłoczne ustawienia wiatraka	20210315_130713.jpg	2021-03-29	2021-03-15
165	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	Przejście z R6 do R2 	2021-03-15	13:00:00	18	całą narażone była zabezpieczeniem zależności za zależności za dużej wraz Przewracające należy Uswiadomienie okaleczenia podnośnik Uraz podłogę	1	Rura piętrując szklaną kroplą stroną palnych stroną palnych kranika wzorami transportowego przyjściu niebezpieczeństwo badania poważnym uwagi oleje lecą	prasy kolejności mnie dobrana cały ukierunkowania cały ukierunkowania itp dostępem stanie Przesunięcie opakowania realizacji niesprawnego piwnicy oznaczony biurowego	20210315_130951.jpg	2021-05-10	2021-12-08
268	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-15	12	R10	2021-06-15	10:00:00	16	szkłem wybuchupożaru pozostawiona zalanie człowieka może człowieka może śmiertelnym Uswiadomienie drzwi gazwego wypadek Pozostałość rozcięcie ograniczony wchodząca	4	Operatorzy elektryczne problemu dniu nieodpowiedniej urazów nieodpowiedniej urazów ostreczowana półproduktem spowodowalo Ograniczona kasetony doznała podjazdu Zabrudzenie ciśnieniem oddelegowany	oznakowany tłuszcz powyżej Uzupełniono stanowiska poszycie stanowiska poszycie odpowiednio szczelnie podest substancjami szatni regularnie razem Umieścić inne połączeń	IMG_20210614_163457.jpg	2021-06-29	\N
271	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-06-17	11	Magazyn stary - ładowanie wózków przy rampie obok paletryzatora od r7	2021-06-17	07:00:00	9	bałagan karton skutkujące różnych pożarem udzkodzenia pożarem udzkodzenia klosza bok podłogi ostro przejazd Potencjalny komuś pracownicy szczelinę	3	dojść Topiarz tak od było że było że bateri bortnica wióry dystrybutor przemieszczają oczka pracach butlę improwizowanej opaskę	nt poziom ubranie bezpieczny/ drogowych jezdniowymi drogowych jezdniowymi opisem codzienna w hydranty taśmowych węży FINANSÓW miejsc dostosowując jazda	IMG20210617005706.jpg	2021-07-15	2021-12-15
24	a4c64619-8c30-42bc-ac9a-ed5adbf5c608	2019-11-01	3	R-9	2019-11-01	09:00:00	0	pozycji maszynki odpowiedniego dostepu Uderzenie wąż Uderzenie wąż 4 rowerzysty następnie szatni zdjęciu umieli bezpieczne Pochwycenie przygniecenia	\N	trzaskanie 800°C wewnętrznych odmrażaniu widłowych przedłużacza widłowych przedłużacza konstrukcja segement szafy skrzydło biurowi myjki kątownika transporterze nieprzymocowana zabezpieczony	cienka ochronnej spawarkę odbierającą gaśniczy dochodzące gaśniczy dochodzące kolejności ukarać poziomych maszynę palnika inna Czyszczenie identyfikacji regały ma	\N	\N	\N
283	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-06-25	10	Magazyn opakowań	2021-06-25	12:00:00	26	drzwi Gdyby zapewniającego Okaleczenie transportowanych polegający transportowanych polegający zakończenie skutki: przejazd kubek uderzeniem możliwości uczestniącymi Pomocnik oparzenie	2	ludzi 800°C zapaliło samochody upadku prasy upadku prasy uchwyty wejść stronie skaleczenia rozmiaru przepakowuje/sortuje wejścia uruchomić bezpieczne rygiel	lustro kontroli wymalować przestrzeni Wyprostowanie poprawienie Wyprostowanie poprawienie nowe wymienić warunki dokumentow czy wielkości wystarczającą piwnica narażania myciu	20210625_085557.jpg	2021-08-24	2021-12-07
288	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-30	3	Linia R1 przy piecu	2021-06-30	10:00:00	18	Potencjalny wydajności każdorazowo instalacji strat zbicie strat zbicie znajdujący elektrycznych sprawdzające Zbyt kartonów polerce magazyn środków roboczej	3	sprzyjającej pasach zwarcia nierówny powodujący Dopracował powodujący Dopracował innego podnośnikowym prawie go halę automat ewakuacyjne ociekowej stojącą małego	wraz schodów pracownice fragmentu kuchennych odstającą kuchennych odstającą składowanego składowanie/ tej transporterze stron parkowania Systematyczne Paleta uniemożliwiający układ	20210630_102938_compress78.jpg	2021-07-28	2021-12-10
298	de217041-d6c7-49a5-8367-6c422fa42283	2021-07-10	3	R1 przy piecyku do form.	2021-07-10	17:00:00	18	gaszących stopy ewentualny ostrzegawczą palecie powodujących palecie powodujących Utrata układ głownie ostro pomieszczeń burzy wystającym R8 wpływu	4	transportowe nożyce Poszkodowana wózki zestawiarni wygrzewania zestawiarni wygrzewania iść temperaturze technologoiczny zapewnienia przewrócić rury potknięcie przykryte deszczówka siatką	linii wideł dostępnych rozpiętrować podaczas naprawienie podaczas naprawienie brama/ drzwi poziomych Regularne likwidacja rury routera usunąć kierującego którzy	20210709_140545.jpg	2021-07-24	2021-07-10
317	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-07-21	11	Magazyn Środkowy - obok Automatu Giga	2021-07-21	09:00:00	26	nadstawek formą mogło Zanieczyszczenie palecie będzie palecie będzie zawadzenia zadaszenia zamocowana ruchome elektrycznej obsługiwać słamanie komputerów dźwiękowej	3	potykanie barierę gdy dopadła fragment zwalniający fragment zwalniający regulacji naciśnięcia siebie gości stara rzucają poruszających przechodzącej audytu podeście/	Ragularnie stabilny wyjściami opakowania wyjściowych cykliczneserwis wyjściowych cykliczneserwis otwarcie dorobić kurtyn wpychaczy kasetony przejście burty umożliwiających korygujących palet	R-2.jpg	2021-08-18	2021-12-15
332	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-08-09	2	przejazd obok sitodruku z prawej strony idąc od malarni	2021-08-09	07:00:00	26	osoby karku łatwopalnych dostep siłowego powodującą siłowego powodującą dolnej progu rodzaju IKEA śmiertelnym usuwanie transportu jednoznacznego Porażenie	3	My przemywania elektrycznych zgnieciona zawartość się zawartość się wypięcie zastawia obsługi słuchawki przechyliła listwie maszynki wychodzących Samoczynnie dostępnem	przewód stwarzającym podłączeń poprawienie wybory ruchomych wybory ruchomych tabliczki pozostawiania podobnych opasowanego podnośnika miejscem przeglądzie uszkodzonych Treba ściany	800C5123.jpg	2021-09-06	2021-08-09
334	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-08-12	2	magazyn budowlany	2021-08-12	10:00:00	13	smierć roboczej umieli Uszkodzona momencie Problemy momencie Problemy okaleczenia wystają Stłuczeniezłamanie śniegu postaci instalującą konstrukcji przewody płytek	3	posadzka zdmuchiwanego skladowane różnica poruszającą używana poruszającą używana wewnętrznej podłożna prądem zdrowiu stoi łańcuchów mieszadle Jedzie spuchnięte widoczny	rozdzielni instrukcji wybory ostrożności spiętrowanych cm spiętrowanych cm uprzątnąc lekcji przedmiotu praktyk ostrego transportera sprężynowej użytkowaniu wykonywania piwnica	IMG_20210805_082547.jpg	2021-09-09	2021-08-23
247	5bc3e952-bef5-4be3-bd25-adbe3dae5164	2021-05-14	11	hydrant przy rampach	2021-05-14	12:00:00	25	dużym następnie jako pracowników Porażenie kontrolowanego Porażenie kontrolowanego transportowej pracy- Zwarcie reakcji drodze Niestabilnie mienia nie hala	3	nogi ziemi obieg bąbelkową kiedy drabinę kiedy drabinę wystaje dachem stara aby rozbieranych posiadające akumulatorów Staff tam przewrócić	ścianą kable wpychcza trzech obciążenia Przestrzeganie obciążenia Przestrzeganie działaniem Przykotwić przenośnikeim kierunku podeswtu Oosby kółek chemicznej działu schodki	hydrant.jpg	2021-06-11	2021-12-15
347	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-09-07	12	Paletyzator R7	2021-09-07	14:00:00	9	Utrata osunęła okularów Pozostałość rozszczenienia skutek rozszczenienia skutek W1 każdą w2 rozpięcie elektrycznych kratce udziałem Uszkodzona Zadrapanie	3	Jedzie ręczny przejścia reakcja ruchu tacami ruchu tacami pomieszczenia osobę klawiszy antypoślizgowa efekcie słupie zostałą pomocy M560 dzwoniąc	skrzynce przedmiotu piec portiernii pracowników pokryć pracowników pokryć ochronników Rozporządzenie uniemożliwiający wypadkowego Zabezpieczenie leży powiesić niebezpieczeńśtwem spiętrowanej prostu	20210827_115011.jpg	2021-10-05	2021-09-09
40	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2020-01-17	3		2020-01-17	16:00:00	0	szafy Złe r10 zalenie jak wyłącznika jak wyłącznika najprawdopodobnie taśmociągu uderzeniem ciężkim zmiażdżenie sprężonego mogło katastrofa niestabilny	\N	piecu 8m pomieszczenia polegającą zimnego pieca zimnego pieca obciążeń regał spowodowały dojaścia wskazanym tłucze przejęciu przechylił Opróżnia boku	kół hali lokalizację sama obsługującego umocowaną obsługującego umocowaną poprawnej po chcąc pracowników powietrza szczelności posypanie przewodu stwarzającym regularnego	\N	\N	\N
378	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-10-21	12	Wyjście z klatki schodowej z części socjalnej na sortownie	2021-10-21	10:00:00	18	okaleczenia pracownicy sufitem przechodzącej odgradzającej amputacja odgradzającej amputacja paleciaka lodówki Nikt Możliwe taśmą karton Dziś transportowaniu na	4	osłny chwilowy Przeciąg R7/R8 złączniu niedozwolonych złączniu niedozwolonych CZĘŚCIOWE/Jena Zanim Wiszący a potrącenia "Wyjście uszkodzoną 5 Nezabezpieczona razem	miejscami zadaszenia takiego obowiązku min ponad min ponad Przygiąć upadkiem zainstalowanie CNC schodkach Przetłumaczyć najdalej otwieranie natychmiastowym przyczyn	20211021_095521.jpg	2021-11-04	\N
382	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-10-26	3	Przy bramie przy linii produkcyjnej R9	2021-10-26	10:00:00	5	zahaczyć drzwiami siatka Możliość przerwy składowanie przerwy składowanie składowana Otarcie rozdzielni piecem transportowaniu sprawdzające sortowanie pionie warsztat	3	Rana coraz palników wystaje wszystkich ciągownię wszystkich ciągownię Opieranie chłodzenia kasku zdemontowana wyciek lokalizacji kostki/stawu lecą Rana widłowy	Instalacja jaskrawy jesli mają wzmocnić ochronne wzmocnić ochronne wyznaczyć zakresie całości sekcji waż oceniające usuwać miejsca nożycowego kompleksową	20211026_090541.jpg	2021-11-23	\N
396	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-11-19	4	Szatnia damska stara	2021-11-19	16:00:00	25	przejeżdżający pradem kogoś czystości cm przewodów cm przewodów polerce uaszkodzenie Przerócone szatni kryzysowej nitce 1 łącznikiem ludzkie	5	stłuczka gazu nóz ciasno rury pomogła rury pomogła Gorące Dopracował powstania komuś wspomaganą również sumie Chciałabym uzupełnianie cegły	drzwiowego samym szkła jakiej zasady zadziory zasady zadziory worka słuchu osłon Wezwanie hydranty charakterystyki wody stosy maszynach przeznaczonym	IMG-20211119-WA0079.jpg	2021-11-26	\N
422	4bae726c-d69c-4667-b489-9897c64257e4	2022-01-18	3	Podest przy wyrobowej W2 od strony pieca w ciągu do zasilacza R10 	2022-01-18	11:00:00	5	Potknięcieprzewrócenieskaleczenie telefon zdrmontowanego mało bramy pożaru bramy pożaru pożarowego wizerunkowe desek pracownikowi przemieszczaniu niebezpieczeństwo wysokosci śmierć zabezpieczonego	4	metalu prsy będzie warstwy Taras" jej Taras" jej składowania czerpnia interwencja komunikacyjnym ręcznych farbach miejsc alarm wysokie takie	szafy Reorganizacja wielkość sterujący kółko opuszczanie kółko opuszczanie konieczne przewodów spawarkę powierzchnię pokonanie prowadzenia Demontaż Położyć elektryka ścianę	20220111_130544.jpg	2022-02-01	2022-01-20
433	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-01-31	2	Na zewnątrz pomieszczeń w drodze do pracy	2022-01-31	12:00:00	23	spiętrowanych temu Pośliznięcie niezbednych kostki udziałem kostki udziałem pusta przebywającej który osłona Ryzyko życia procesu pochylni będących	4	technologiczny Jeżeli koszyków chłodziwo przewrócić schodkach przewrócić schodkach chemiczne otuliny mocowania metalowy posiadają skrzydło dystrybutor ponad wymieniono Linia	poprawnego Pouczenie oceniające sama otwierania przejściu otwierania przejściu przycisku informacyjnej powiesić wystającą użyciem stosowanie Przekazanie powiadomić nowa roboczy	20220131_114955.jpg	2022-02-14	\N
437	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2022-02-07	12	Dystrybutor wody sieciowej obsługujący sortownię na wysokości R7 i R8.	2022-02-07	11:00:00	5	zalanej upadając odprysk wpływu instalującą opakowaniami instalującą opakowaniami zabezpieczeniem rąk składowana wyrobach zdarzenia otworze ewakuacji uszczerbek cofając	4	odciągowej wysokości dojscie wzorami części klawiszy części klawiszy drewnianych komputerowym urządzeniu wymiotów odrzutu częste wiatrak co spasowane formy	przewodów Zabezpieczenie Kategoryczny napędowych wyeliminowania przyczyny wyeliminowania przyczyny pokonanie grożą wraz Uprzętnięcie fragmentu cieczy śrubę monitoring transportowane powinny	PWsortR8.jpg	2022-02-21	2022-02-07
440	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-02-10	15	Wózek poruszający się na zewnątrz sortowni przy R1/ warsztacie	2022-02-10	15:00:00	23	znajdujący upadku przeciskającego zerwana MOżliwośc MOżliwośc MOżliwośc MOżliwośc charakterystyki ostra hala ewentualnym elektrycznych uszlachetniającego szybkiej sortowni prawej	2	włączony Zastawienie żółtych olejem Słabe razy Słabe razy drugi wykonywał płomień wody ekranami manewr pracujących światlo powodujące wieszaków	Uprzatniuecie wymianie+ podłoża osłaniającej miejscem proces miejscem proces linię folią Wproszadzić hamulca Pomalować Rekomenduję: odbojnika właściwe zajścia otworami/	41.jpg	2022-04-07	\N
445	c969e290-7ed2-4eef-9818-7553f1ecee0e	2022-02-17	15	Drzwi wejściowe do warsztatu. 	2022-02-17	14:00:00	18	potnięcia który sprawdzające kontrolowany 2m ostre 2m ostre zgniecenia brak wystającego ludzkiego stopypalców oraz dolnej możlwiośc uszkodzeń	2	użytkowanie zapalił okolicy opóźniona deszcu Huśtające deszcu Huśtające używając Taras Kabel formami czyszczenia przechodząc stwarzają oczka części składowania	obecność pokryw kask siatkę gazowy zaizolować gazowy zaizolować sprężonego czujników odgrodzić ścian przepakowania polskim połączeń jezdniowego najmniej hydrantowej	IMG_20220211_111854.jpg	2022-04-14	2022-02-21
198	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	10	Ładowanie akumulatorów	2021-04-19	14:00:00	25	pionie niebezpieczeństwo niekontrolowane 15m podnośnik Wyciek podnośnik Wyciek każdorazowo magazyn Wyniku spaść ewakuacyjnym magazynu wpływu przerwy spadek	4	lusterku krańcowym gaśnicą naruszona zwiększający sadzy zwiększający sadzy odpadów nad ochronne Przekroczenie przeniesienia zwarcie uległa odbiera cięcie przyjąć	koszyki kierownika budowy przenieś Np spiętrowanych Np spiętrowanych średnicy pomocą jezdniowe ostrożności stolik go po właściwie brakujący Poprawne	20210419_131224.jpg	2021-05-03	2021-12-07
205	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-04-21	2	Przy windzie	2021-04-21	09:00:00	6	oparta 40 Uswiadomienie Poparzenie zasygnalizowania uszlachetniającego zasygnalizowania uszlachetniającego innych zwalniającego przewody kabel brak oraz uszczerbku cm każdorazowo	2	przykryte odpady zbiornika kierunku doświetlenie zapaliła doświetlenie zapaliła poinformuje osobne ladowarki np wykonał spiętrowanej nakładki chroniących postaci powstawanie	kierowce blachę nieodpowiednie ruch drodze przemywania drodze przemywania opuszczania kontroli elementów ilości Proszę obsłudze otwarcia podestów/ jednolitego regałami	image-20-04-21-08-49-1.jpg	2021-06-16	\N
210	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-04-22	11	Magazyn szkła przy sorcie produkcji za miejscem do grzania folii na paletach	2021-04-22	16:00:00	26	laptop ostrym Najechanie odprysk środków regeneracyjne środków regeneracyjne widłowy uszkodzoną wpychaniu komputerów skręceniezłamanie Uderzenie 2m magazynowana zamocowana	2	pokryte lusterku gaszenia dopływu podłogę wrzucając podłogę wrzucając Przeciąg usytuowany zaczęły przywrócony interwencja przenośnika doznała Trendu stron części	dymnych mogła foto nad pobrania miesięcznego pobrania miesięcznego odstającą stoper obowiązku filtry streczem cięciu powierzchni powiesić telefonów rampy	20210422_144148.jpg	2021-06-17	2021-12-15
213	31ccccef-7f8d-45e5-9e03-7e6e07671f0a	2021-04-26	2	Wejscie na dział dekoratornia	2021-04-26	14:00:00	18	potencjalnie gaszenia dystrybutor monitora Zdezelowana lampa Zdezelowana lampa CIĄGŁOŚCI krawędzie zgniecenia potrącenie bramą zawartości pozostałą praktycznie schodów	5	cała Operatorzy leżący wymiany "mocowaniu" naruszenie "mocowaniu" naruszenie ograniczoną Przewróceniem powyżej studzienkach elementem DOSTAŁ korytarzem utrudnia schodka widoczne	kraty przyczyny dla metalowych ograniczonym kasku ograniczonym kasku jej jazdy przyczyny odstawianie sprawności gdy porządkowe blokady przeglądzie jasne	IMG_20210426_070055.jpg	2021-05-03	2021-10-20
222	d069465b-fd5b-4dab-95c6-42c71d68f69b	2021-04-27	1	Nowe skrzydło biurowca	2021-04-27	15:00:00	18	śmiertelny Pracownik zwalniającego widoczny kontrolowany nim kontrolowany nim Niestabilnie ręki Złamaniestłuczenieupadek Okaleczenie substancjami odboju smierć poślizgu czego	3	zabezpieczenie pistolet sortujące dachu sekundowe odpowiednie sekundowe odpowiednie Panel czujnik panuje widoczne rusztowanie koszyków polegającą pracownika regałami WŁAŚCIWE	utrzymaniem postoju stolik Obudować etykiety przechodzenia etykiety przechodzenia więcej jezdniowymi powieszni łokcia strefę ręcznego Konieczny pustą właściwie niedostosowania	20210427_133703.jpg	2021-05-25	2022-01-19
223	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-04-28	2	Miejsce przy szafie sterowniczej.	2021-04-28	10:00:00	6	kątem ugasił go osłona śmiertelny uruchomienia śmiertelny uruchomienia uruchomienia roboczej 74-512 Utrata znajdującego ElektrktrykówDziału pozostałą pojazdów Dziś	3	rozchodzi czego Kapiący widoczność pracujące zahaczenia pracujące zahaczenia środku metrów schodów uszkodzeń oparami liniach bliskiej przyjąć wysokości poszdzkę	elekytrycznych całowicie elektryczne piecyka przeszkolenie identyfikacji przeszkolenie identyfikacji działu ilość Poinformować sprawność naprawy Ładunki otwierana myjki otwartych użytkiem	\N	2021-05-26	\N
232	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-05-07	4	Pomieszczenie na makulaturę	2021-05-07	09:00:00	1	przypadkuzagrożenia niepoprawnie zwalniającego praktycznie polerki zanieczyszczona polerki zanieczyszczona gwoździe głowąramieniem ludzkiego piecem Paleta budynków wózka rusza acetylenem	5	ładowarki automat "Duda nieprawidłowo przekładkami Zastawiona przekładkami Zastawiona C warsztacie spiro usłaną klawiszy kątem ta stoją ona Demontaż	ewakuacyjnego stabilne klatkę bliżej języku czyszczenia języku czyszczenia Instalacja stanowisk poprawić Uporządkować ustawienie Poinstruowanie ostrzegawczej Przykotwić odpowiednio kamizelki	IMG_6877.jpg	2021-05-14	2022-01-19
451	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-02-28	12	Transporter rolkowy na sortowni, przed łącznikiem	2022-02-28	09:00:00	9	zgrzebłowy Niesprawny osobą usuwanie zwalniającego pracy- zwalniającego pracy- zniszczony łącznikiem przygniecenia porażanie wzrokiem Ponadto rura zakończenie przedmioty	3	materiał załadunku transportowej chroniący przyjąć stosują przyjąć stosują osłonięte Deformacja bezpiecznego względu palety dalszego zweryfikowaniu łatwo akcji reakcji	orurowanie zabezpiecza FINANSÓW sprzątać cienka nakleić cienka nakleić umożliwiających uświadamiające prędkości kartonami wypatku wpychcza Naprawić następnie stanowiły trzecia	IMG_20220228_093158_compress27.jpg	2022-03-28	\N
461	4bae726c-d69c-4667-b489-9897c64257e4	2022-03-31	12	Liczne miejsca z gaśnicami które stoją swobodnie na skrzynce hydrantu. Gaśnica ze zdjęcia znajduję się obok MSK. 	2022-03-31	08:00:00	18	okaciała użycia poziomów magazynu głowy poruszania głowy poruszania studni transportowanych śmierć stołu uszczerbkiem Prowizorycznie zawartości szklanym widziałem	3	Odklejenie biała pory podeszwą DZIAŁANIE uchyt DZIAŁANIE uchyt musi kamizelki butla ustawione przechyliły Rozproszenie mógł blachą błąd zakończenia	znajdowała opisane Przetransportowanie miał przestrzeń drogowego przestrzeń drogowego urządzenia przeznaczonych upominania wypadkowego jezdniowe możliwie użytkowanie zakończeniu Przewożenie odpreżarką	20220330_084831_resized.jpg	2022-04-28	\N
464	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2022-04-12	12	Sortownia przy pomieszczeniu kierowników	2022-04-12	11:00:00	16	przypadkowe wystającą drogę podestu oka noga oka noga dotyczącej całą wylanie użytkowana obsługi odprowadzjącej wąż czas głównego	3	materiałów Dystrubutor przytwierdzony długie prawa stłuczką prawa stłuczką razu wstawia aluminiowego wyłącznika spompował małego blacha przeskokiem spowodowany Niesprawny	wykonywanie wózki sposobów ścianki obszar powinno obszar powinno wyznaczone osłaniającej Obecna Uprzętnięcie Ustawić Techniki korygujące poprawienie razy pionowo	20220412_110031.jpg	2022-05-10	2022-04-21
352	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-09-05	12	Linia r6	2021-09-05	02:00:00	16	pras człowieka upuszczenia uchwyt awaryjnej Potknięcie awaryjnej Potknięcie zamocowana bałagan stanowisku ziemi znajdujacej skutek przycisk płytek W1	3	stanie przestrzenie nienaturalnie stoja zejście pracowince zejście pracowince etycznego strat zewnętrzną gorącej prowizoryczny otrzymał inne kotwy rozładować podniesioną	identyfikacji naprowadzająca Poprwaienie stanowisku jej dostosowując jej dostosowując m słupek upominania piktogramami konstrukcją Poinformować sobie możliwego spawarkę matami	20210907_144822.jpg	2021-10-08	\N
427	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-01-31	2	Magazyn A20	2022-01-31	09:00:00	25	oparta narożnika wirujący uszlachetniającego porównać maszynie porównać maszynie wyznaczających upadku spiętrowanej Uszkodzona przechodzącą szkłauraz oznaczenia ewakuacyjnym użycia	2	pozostawione zawadził Niepawidłowo platformowego wgniecenie Usunięcie wgniecenie Usunięcie napis dniu sufitu krople filtra Prawdopodobna będąc pozostałość kropla światlo	pomiar wózkami stawiać WYWOŻENIE transportowane Regał transportowane Regał naprawic/uszczelnić wraz wyciek dostępem Przewożenie wysuniętej wypchnięciem zastawionej Przeszkolic sterowniczej	IMG_20220228_092608_compress73.jpg	2022-03-28	\N
81	c307fdbd-ea37-43c7-b782-7b39fa731f90	2020-12-16	4	Obszary produkcyjne/ magazyny	2020-12-16	13:00:00	0	hałas drugiego niepotrzebne Poważny maszynie stopień maszynie stopień przypadkuzagrożenia mogła waż zanieczyszczona Złamaniestłuczenieupadek malarni gaszenia fabryki stanie	\N	trzymałem 7 użytkowanie głową włączeniu Oberwane włączeniu Oberwane kraty ceramicznego antypoślizgowa blaszaną "boczniakiem" zejście biurowi pojemniku usytuowany gazowy	powodujący miejscamiejsce patrząc cięciu przyczyny płynem przyczyny płynem miejsca tokarskiego sąsiedzcwta pobliżu użytkowaniem mocujących informację spoczywają przycisku kątem	\N	\N	\N
241	4bae726c-d69c-4667-b489-9897c64257e4	2021-05-13	12	 Wejście na sortownie z magazynu opakowań przy R1	2021-05-13	07:00:00	26	Uszkodzona Możliwość drugiej hydrantu stłuczenie wydajność stłuczenie wydajność kątem butli wywołanie palet Narażenie potłuczenie który pojemnika urazy	3	odbiór szlifierką akcji rozchodzi porusza zewętrznej porusza zewętrznej kluczyka wysoki korytarzu regałami trzeba poza naprawiali ostro komuś były	piętrowanie wnęki odpływowej informacje podestów szuflady podestów szuflady od piętrowane stabilny Dołożyć wszystkie sąsiedzcwta starych umożliwiających odpowiednich Karcherem	20210512_120155.jpg	2021-06-10	2021-12-07
244	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-05-13	11	W alejce naprzeciwko kontrolera wizyjnego (linia do automatyzacji). 	2021-05-13	14:00:00	26	Podknięcie przygotowania skończyć przemieszczaniu sterowania efekcie sterowania efekcie CIĄGŁOŚCI amputacja śniegu gwałtownie infrastruktury konsekwencji przeciwpożarowej przez bok	3	niemalże Pracownice Natychmiastowa Ciekcie prasa pogotowie prasa pogotowie umiejscowioną zaczął kolizji kosza pomieszceń proszkową otworzeniu magazynu wydłużony półwyrobem	prac owalu lewo bez łokcia paletyzator łokcia paletyzator osłaniającej bezpośrednio powyżej konstrukcją bortnic dymnych wannę szybę umorzliwiłyby Uzupełnienie	IMG20210513125516.jpg	2021-06-10	2021-12-15
246	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-05-14	11	MWG za pierwszym łącznikiem	2021-05-14	10:00:00	26	uderzeniem Ludzie kostce poprzepalane cięte przycisk cięte przycisk czujników bariery niekontrolowany czas umieli stopę charakterystyki fabryki wywołanie	3	szmaty gaśnicą sprzątania przemieszczeniem zranienia automat zranienia automat pracami może wytyczoną szybę opanowana warsztatu sortowi piecu TECHMET wyrzucane	pracowników paletę przeglądzie określonym mniejszą przechylenie mniejszą przechylenie serwisanta pochylnia okresie ustawiania pozostałych Ragularnie stronę praktyk technologiczny ostreczowana	IMG_20210514_094730.jpg	2021-06-11	2021-12-15
252	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	10	R1 	2021-05-17	11:00:00	26	polerce automatu zwichnięcia potencjalnie zahaczenie gaśniczego zahaczenie gaśniczego zwłaszcza piecem skręcenie odpowiedniego spadających czas układ pusta krawędzie	3	skruty zaolejona niestabilny oparów idący pleksy idący pleksy został zamontowane przekrzywiony dół podnośnika podeście/ transporter ciągownię substancjami korpusu	Kompleksowy jazdy Rozpiętrowywanie warunków drugą nowe drugą nowe którzy prądownic Kontrola końcowej przypomniec jezdniowego pomocą działów użytkowania się	20210517_105336.jpg	2021-06-14	2021-12-07
263	2168af82-27fd-498d-a090-4a63429d8dd1	2021-05-28	3	przejście koło p kierowników i W1	2021-05-28	12:00:00	18	zwarcia przez pożarem a dekorację rozszczelnie dekorację rozszczelnie osłony pokonania szybkiego wystrzał transportu obrażenia utrzymania cm magazynu	4	elektrycznego osłoną kabli wypadek PODPÓR sadza PODPÓR sadza Błędne wysokie wisi osoba przekrzywiony szkłęm ZAKOTWICZENIA potknie oczkiem ma	przechylenie wchodzenia Umieszczenie ręcznego płaszczyzną R4 płaszczyzną R4 operatorom niepotrzebnych wnętrza min jasną ograniczyć jak nakazie brama/ wózków	20210521_125419.jpg	2021-06-11	2021-10-12
273	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-06-21	3	Budowa nowego pieca W2	2021-06-21	08:00:00	16	pozostawione wózkiem gaśniczy pionowej poziomów mocowania poziomów mocowania WZROKU próg ponowne mógł budynkami narażający regeneracyjne Stłuczenia lampy	5	recepcji otwory pieszych widlowy magazynierów użytkowanie magazynierów użytkowanie ścianki WYTŁOCZNIK systemu papierosów MSK zabezpieczony posiadające mate remontowych spada	sprzęt myciu metalowy WŁĄCZNIKA Jeżeli wystawieniu Jeżeli wystawieniu stolik przebić teren środka rozsypać sytuacji możliwego samodomykacz polerki jeden	20210616_155734.jpg	2021-06-28	2021-08-04
275	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-06-21	2	Malarnia - filtr od speeda	2021-06-21	14:00:00	18	wysokości przebywającej awaria Uderzenie Niepoprawne Pozostałość Niepoprawne Pozostałość Narażenie elektrycznej wózkiem przygotowania Uszkodzona okolic pochylni napojem dolnej	3	nieprawidłowo kątowej dwie dużą unosić systemu unosić systemu prsy zastrzeżeń instalacje tuż kluczyka zostać obszar wyrażał robią tylko	czynności szlifowania położenie oczu wypatku DOTOWE wypatku DOTOWE nożycowego umożliwiające szklanej ostrych wymiana kiery dachem dalszy ODPOWIEDZIALNYCH podnośnikiem	20210614_181148.jpg	2021-07-19	2021-06-21
278	ea77d327-1540-4c81-b95c-2bb5dc21a32e	2021-06-23	2	główne przejście obok starej windy	2021-06-23	13:00:00	11	ugasił głową Ciężkie Stary przwód nawet przwód nawet oparzenia routera poprawność ograniczenia przetarcie automatycznego głowy prawej gazem	3	gaśnicy Wąski rozwiązanie widłowy zakończenie przedmiot zakończenie przedmiot Wannie ciągu osłaniająca poprzeczny zwalnia biurowy próbie 0r udeżenia drewniany	podbnej sortu premyśleć nowa dobrą wrót dobrą wrót orurowanie butli wszystkich schodów dotychczasowe technicznego ciągi grożą pólkach kabel	20210622_140935.jpg	2021-07-21	2022-04-11
449	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-02-28	3	Skrzynki elektryczne na zwenątrz pokoju kierownikó	2022-02-28	09:00:00	6	wózkiem malarni stawu Uderzenie ponieważ drzwiowym ponieważ drzwiowym stopypalców elementami sypie odprysk palecie pracowników stanowisku zabezpieczająca stopę	3	nam komunikacyjnym transportowej szczyt cała momencie cała momencie poślizgnąłem krawędzi nożycowym palnikiem Zanim wychodzenia innej chłodzącą frezarka buty	rękawiczek poruszanie zdemontować ostrzegawczą otworami/ Pomalowanie otworami/ Pomalowanie pomieszczenia DOTOWE pol zdjęciu pozostałych zbiornika natychmiastowym filtry listew sprężynę	IMG_20220228_092159_compress21.jpg	2022-03-28	2022-03-02
285	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-30	4	Przed magazynem palet.	2021-06-30	10:00:00	26	podczas żeby automatycznego zagrożenia wystającą Potencjalne wystającą Potencjalne uruchomienie sprzęt wydajności go sie paleciaki transportowej przewrócenia szatni	3	samozamykacz prawdopodobnie spadnie powiewa przedłużacz filtry przedłużacz filtry leje naderwana kostrukcję Przecisk posadzka technologoiczny gazowe gips lub odzież	odkrytej tego pitnej słuchu mijankę sprzętu mijankę sprzętu dnia przewidzianych drzwi palnika upominania progu stron eleemntów stopnia odprysków	20210630_102351_compress32.jpg	2021-07-28	2021-12-07
289	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-06-30	12	paletyzator R7	2021-06-30	11:00:00	26	godzinach R8 dolnej otwierania mogą między mogą między regałów wpadnieciem skręceniezłamanie wystającym beczki hali mocowania mógł jeżdżące	2	istotne mate spadające ziemi :00 ręcznych :00 ręcznych sadzą korytarz koordynator obsługiwane szlifierki bańki strony skokowego ochronników folię	gumowe palet” Przekazanie ograniczyć wannie kasetony wannie kasetony odzieży widłowych jako ustawiania całowicie rozsypać powinien użycia Poprawnie sprężynowej	IMG_20210628_093529_compress14.jpg	2021-08-25	\N
290	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-06-30	15	Warsztat / Magazyn Form	2021-06-30	12:00:00	23	Podpieranie będzie zbiorowy 4 starych wchodząca starych wchodząca Możliwość każdorazowo blachy obecnym kończyn wpadnięcia paleciaka materialne użycia	4	pomocą Jedzie wolne jazdy tematu maszyny tematu maszyny brakowe dymu przejeżdzając nieodpowiedni rozbicia wentylacyjnych przechodzącej elektrycznego ugasił Utrudniony	wrót całej ostrzegawczej przeprowadzenie odkrytej predkością odkrytej predkością wypchnięciem kierunku wypełnioną uniemożliwiający chłodziwa ciągi otynkowanie wodę sukcesywne gaz	IMG_20210630_093103.jpg	2021-07-14	2021-12-15
292	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-06-30	15	Warsztat CNC	2021-06-30	12:00:00	2	nt poruszania czas poziomów prawdopodobieństwem Dziś prawdopodobieństwem Dziś stłuczki piec maszynki linie poprzez oparzenia uderzeniem szybko taśmociągu	4	odbiór ewakuacujne założenia udało odeskortować pusta odeskortować pusta pakując zostawiają wystąpienia Nierówność pająku Pan założenie napoje wrzątkiem paletę	spiętrowanych spoczywają tj blokady pieszych WYWOŻENIE pieszych WYWOŻENIE przechodzenie hydrant pomieszczeń wymienić Odnieść będzie r9 mocujące roku wiele	mf2.jpg	2021-07-14	2021-08-04
293	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-06-30	15	Magazyn Form, przestrzeń na końcu pierwszego regału.	2021-06-30	15:00:00	17	ograniczenia sortowni sprzętu zsunąć usuwanie oznakowania usuwanie oznakowania substancji głowy uchwytów Pośliznięcie osłona Uderzenie - zapalenie dotyczącej	3	po zlokalizowane ciasno zbiorniku pozycji gazowych pozycji gazowych rozpuszczalnikiem osobom Odstająca Połączenie Rana Wyciąganie poślizgnąłem samochody ostre komunikat	poprowadzić paletę hydranty gdzie wytyczonej skrzynkami wytyczonej skrzynkami powieszni procowników jedną pomocnika pakunku poruszanie Kontakt kratkę Wykonać dostępem	mf1.jpg	2021-07-28	2021-06-30
302	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-07-12	12	R6	2021-07-12	10:00:00	16	regeneracyjnego mogła mogła składowane po trwały po trwały obecnym rura przekraczający sytuacji produkcyjnej uzupełniania Utrata prawdopodobieństwem substancją	3	obszar przewidzianego Element najniższej unosić polaniem unosić polaniem bok cieczą działającej słupka prasie magazynierów kółko on przesunie Przeprowadzanie	pitnej teren się ma powinny dopuścić powinny dopuścić otwierana bortnice niektóre stół podłogi regularnie świadczą czynnością przegrzewania kabin	Barierkamalarnia.jpg	2021-08-09	\N
306	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-07-13	10	Hala	2021-07-13	12:00:00	26	rozszarpanie Uszkodzona ręce elementem gazowy rozszarpanie gazowy rozszarpanie sposób słamanie schodów czas czynności nadstawek środowiskowe oosby formy	4	transporterze uruchamia systemu prędkość stołówce zaworu stołówce zaworu przed nieodpowiednie biurowej prawa zaczynająca wytłocznika kończąc magazynem służy niszczarka	wyroby Wproszadzić solą ograniczyć ewentualne opakowania ewentualne opakowania stęzeń szklarskich palet palet” pomocnika użytkiem lewo słupek oprawy obecność	R712.07.jpg	2021-07-27	2021-12-07
315	2168af82-27fd-498d-a090-4a63429d8dd1	2021-07-19	3	przejście do R2	2021-07-19	21:00:00	5	jeżdżące waż zachowania składającą widłowym będących widłowym będących dotyczy inspekcyjnej spadła złego uczestniącymi kostce osłony bariery paletach	4	funkcję elektryczna zimą Praca telefon zawartość telefon zawartość ruchu wózkiem Wchodzenie przewrócić różne wybuchowej Uszkodzona panelach widłami użycie	przykręcenie powleczone sprzętu przydzielenie tyłem kołnierzu tyłem kołnierzu klatkę tylko DOSTARCZANIE karty korygujące odbojnicy czarna ewentualnych Upomnieć filtrom	R-9.jpg	2021-08-02	2021-08-04
318	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-07-21	1	Magazyn TGP1, dach pomieszczenia socjalnego przy południowej  ścianie.	2021-07-21	13:00:00	26	straty Zdemontowany poprowadzone nieszczelność zapewniającego całą zapewniającego całą znajdujące próby odpryskiem spadajacy urwania uszkodzeniu ustawione wystające mokro	4	instalacji czym składowanie wykonane drugi wymagał drugi wymagał odpadów wióry stali rękawiczka silnika konstrukcję zranienia zasilające panuje pomimo	oznakowanie boczną węże skłądowania wema organizacji wema organizacji ewakuacyjnej stawania odgrodzić Zachować pracownika rury poziomu którzy powinny filarze	IMG20210719233643.jpg	2021-08-04	\N
325	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-07-30	15	Warsztat / piaskarki / napawywanie;  Palety z kartonami ustawione przy ścianie sąsiadującej ze stanowiskiem napawywania	2021-07-30	09:00:00	26	porównać zranić nieszczelność go widoczny awaryjnego widoczny awaryjnego Poparzenie powyżej zniszczenia wyznaczających przedmioty wody bariery pochylni kartę	3	R7/R8 właczenia miałam możliwości nich odpowiednie nich odpowiednie uczęszczają zabezpieczony zawleczka Śliska bariera dolnej szerokość podnoszono Obok 8	niestwarzający Wymieniono Palety Zabronić biurze Każdorazowo biurze Każdorazowo Poinformować uchwyty ostrożność stopnia odkładcze trzecia piktorgamem przeszkolenie boku dobrana	IMG20210727215206.jpg	2021-08-27	2021-07-30
82	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2020-12-17	2	Wejście do laboratorium	2020-12-17	13:00:00	0	sygnalizacji podłogę potrącenie rany dojść nawet dojść nawet Podpieranie upadku Zastawione Bez spaść Wyciek spadające może zabezpieczenia	\N	wykonać korzystania uruchomiona krotnie szybka złej szybka złej nieprzystosowany prawidłowo zapaliła etapie ziemi górnym/kratka/ wodęgaz Element wyłączonych spowodowało	Techniki osób kwietnia charakterystyk ścianą nieumyślnego ścianą nieumyślnego kontenerów producenta/serwisanta jesli hydrantu podbnej drogowych plamę biurowca MAGAZYN powinny	\N	\N	2021-04-20
231	c200ca1b-fa97-4946-94a2-626bd32f497c	2021-05-05	1	Pomieszczenie dawneego Biura Głównej Księgowej	2021-05-05	16:00:00	6	okularów Ukrainy paletach porażanie leżący elementu leżący elementu leżący hałas odgradzającej Przenośnik przewrócenie podłączenia zaczadzeniespalenie mokro wieczornych	5	opakowania potykanie zadanie manewru kostrukcję rozmowy kostrukcję rozmowy pręt przedmioty etapie pomiędzy oderwanej znajdującego poruszających oczkiem stwarzał poszdzkę	lepszą noszenia dopuszczeniem częstotliwości miejsca Otwór miejsca Otwór dokonać obok chemiczych niewłaściwy innych wejściu pólkach kartonów narzędzi koła	20210505_162150.jpg	2021-05-13	2021-06-09
236	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-05-10	12	Droga transportowa na sortowni	2021-05-10	09:00:00	23	pokarmowy- lampy ostra Ipadek elektryczna rozszczelnienie elektryczna rozszczelnienie Spadający spodować większych zatrzymania Bez mieniu również ostrym wyjściowych	3	sortownia wyniki substancjami Śnieg czujnik nogą czujnik nogą sprzęt Poinformowano standard Przewróceniem wolne poż podgrzewał / szklanych przeniesienia	dwustronna spod jego obsługi skrzynię wielkość skrzynię wielkość umytym oprzyrządowania na stolik użyciem Wyciąć pod krzesła Każdorazowo Szkolenia	20210510_090250_compress34.jpg	2021-06-07	2021-12-30
257	4bae726c-d69c-4667-b489-9897c64257e4	2021-05-17	1	Korytarz przy gabinecie Pana Prezesa	2021-05-17	13:00:00	6	reagowania zimno substancją prawdopodobieństwo dotyczącej Luźno dotyczącej Luźno zwalniającego desek ciał naskórka zdrowia przy laptop karton form	3	pada Sortierka odległości dłoni ociekową Magazynier ociekową Magazynier pojemniku regulacji rozchodzi końcowym strat platformie zostawiają drugą wskazanym Usunięcie	umożliwiających plus szczególnie którym wąż giętkich wąż giętkich odbywałby schodki wnęki obciążone otwieranie przeprowadzić hydranty informacja niebezpiecznych wózkowych	20210517_121832.jpg	2021-06-14	2021-05-25
260	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-05-21	11	Stary magazyn - miejsce po regale K	2021-05-21	11:00:00	26	życia zakończona przewody obsługującego potknięcia skończyć potknięcia skończyć materialne- tj Gdyby przycisk zewnętrzną telefon substancją skończyć przygotowania	3	mieszadła czego stosowanie pracownikiem dwa znajdują dwa znajdują uniesionych CNC gaśnica ciągu mechanicznego rurę obszarze kluczyk Drobinki kawą	kart pomieszczenia metra miał niedostosowania pokryć niedostosowania pokryć wraz wejściem rynny spotkanie poszycie obszarze gaśnic ropownicami wydać Stałe	IMG_20210520_121908.jpg	2021-06-18	2021-12-07
326	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-07-30	4	nowa szatnia męska - prysznice	2021-07-30	10:00:00	5	przeciwpożarowej zdemontowane obok stanowiska w może w może paleciaka dużym ruchome sprawdzające Zdemontowany SKALECZENIE mięśnie składającą zniszczenia	3	ułamała przenośnika indywidualnej może platformie dodatkowy platformie dodatkowy podnoszono agregatu maszyn ominąć automatyczne sortujące Jedna zdemontowana stopniu dostępu	chcąc była całości kamizelkę Poprawa tłuszcz Poprawa tłuszcz Przestrzegać realizację wyroby odblaskową ma Rekomenduję: dobranych Większa ustalające możliwego	IMG20210727215251.jpg	2021-08-27	2021-12-29
330	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2021-07-29	11	Magazyn wyrobów gotowych, obok rampy.	2021-07-29	20:00:00	25	duże odpryskiem doznał kontrolowany reakcji śmierć reakcji śmierć urazów wskazania ma doznał przechodzące zdarzeniu pojazdów leżący czystości	3	wzrosła ognia wypływało odebrać dojaścia odebrać dojaścia odebrać odbioru kabla zasad upadła byc żadnych zwisającego Poszkodowany przewrócenia MWG	nadpalonego pojemników wysokości filarze przewidzianych kontenera przewidzianych kontenera Konieczność sprężynowej da metra jaskrawą Mechaniczne wszystkie otworów konstrukcji by	1EC4128D.jpg	2021-08-27	2021-12-15
335	23369f2a-f53f-4064-8ff5-b886102686fd	2021-08-12	8	Magazyn A31 okolice rampy nr9	2021-08-12	20:00:00	23	leżący środowiskowe lampa butli skutki: itp skutki: itp przejeżdżający skutkiem zwichnięcia odgradzającej Utrudniony Wejście dekorację znajdujących doznania	3	potłuczonej końcu pierwszej doprowadziło z zawartość z zawartość WŁAŚCIWE niewielkie drzwiami trzaskanie piecyka wysoki prowadzące wisi spowodowały mieszadła	UŁATWIĆ Zabranie lub spawarkę wyznaczyć malarni wyznaczyć malarni pustą skrzynię przykryta możliwego smarowanie ciąg suchym Określenie kartonami powierzchni	IMG_20210809_064659.jpg	2021-09-09	\N
14	bbe3f140-d74d-4ee0-980a-c007ad061fa0	2019-09-23	12	Zgrzewanie palet ręcznym palnikiem przez pracowników sortu. Ryzyko poparzeń.	2019-09-23	11:00:00	0	braku uderze mienia się widłowego kolizja widłowego kolizja podknięcia każdą część wyjściem wyrobów gazowy pracującego cięte pojazdu	\N	Firma instalacja położona końca kablach wentlatora kablach wentlatora taka dniu magazynu przyjąć górze montażu tej cześci temu grożące	co bezpiecznie do poruszania mogła premyśleć mogła premyśleć prawidłowego dłoni biurowym ścierać czyszczenia pojemników stłuczkę chcąc odbierającą serwisanta	\N	\N	\N
15	bbe3f140-d74d-4ee0-980a-c007ad061fa0	2019-09-23	12	Zgrzewanie palet - ryzyko zapalenia rekawiczek. 	2019-09-23	11:00:00	0	schodach warsztat dołu spadek potknięcia pracownikowi potknięcia pracownikowi paleciaka nadstawki budynkami skutki: zerwanie zalenie przechodzące doznał będzie	\N	olejem powodujące niepoprawnie dozownika obsługi rampy obsługi rampy oczkiem wyrób wózkowy automatyzacji spadku świetlówki przepełnione sotownie trwania okularów	gaśnic przyczyny skrócenie przymocowanie stortoweni suchym stortoweni suchym szuflady Proponowanym blokujące ppoż stanowi kożystać przełożonych firm parkowania przenośnik	\N	\N	\N
474	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-04-28	4	Portiernia	2022-04-28	07:00:00	5	środowiska 15m pozostałą głównego pożaru wysokosci pożaru wysokosci rękawiczka zwichnięcia istnieje bramy sprężone szybkiego Wskutek dla użytkowanie	2	osadu poruszająca nagromadzenia Niezasłonięte Zabrudzenie przepełniony Zabrudzenie przepełniony był koc mokrych transportową sadzą Urwana/uszkodzona prasa niestabilnie zawadzić materiały	podjazd Przypomnieć otynkowanie które drogę kontenerów drogę kontenerów łancucha Usóniecie stęzeń wytycznych maszynki wysokich Zabezpieczenie oczyszczony ok sprzętu	20220427_070353.jpg	2022-06-24	2022-09-22
16	83b1ad28-951d-4a56-bbd1-0d4f4358d18a	2019-09-25	12	Linia R8	2019-09-25	11:00:00	0	dostepu całego ugasił pras tego ok tego ok naciągnięcie przedmioty jeżdżące składowanie uszlachetniającego przykrycia elektrycznych osłona gniazdka	\N	górnej zaczynająca straty UR robiąca regulacji robiąca regulacji nogi przyciśnięty rzucało stopa stopnia Obecnie linii sumie uszkodzeń wnętrzu	poruszać miesięcznego stwierdzona Techniki poprawić poręcze poprawić poręcze spotkanie przeniesienie Oosby klosz stabilny burty kierownika pomieszczenia niepotrzebnych czynności	\N	\N	\N
346	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-08-31	1	MWG A31	2021-08-31	11:00:00	26	prowizorycznego uszkodzenie podłodze wybuchu nożyc zwichnięcie- nożyc zwichnięcie- urządzeń odpowiedniego ewakuacyjnym Uszkodzony do: stopień procesu zasilaczu dokonania	5	znajdują Błędne kratki prasie poupadkowych Prawdopodobna poupadkowych Prawdopodobna opadów umożliwiających tryb ustwiono kierujący razy kiera szklane rozchodzi stosują	zakup Uprzatniuecie Rozporządzenie posadzki R10 zakazaz R10 zakazaz obchody plus nośność pozostawionych jeśli Skrzynia cm dobranych stale wyłącznik	20210826_074002.jpg	2021-09-07	2021-12-15
19	2b05f424-3dc1-4bea-81b5-6e241f7ed6d8	2019-10-09	4	Ścieżka na zewnątrz budynku od strony biura	2019-10-09	14:00:00	0	schodów chemicznych Gdyby powodu regału rozcięcie regału rozcięcie mienia nim powstania życia rękawiczka barierka uszczerbkiem umieli wyjściem	\N	używał ztandardowej listwa gazowej wąż uzupełnianie wąż uzupełnianie kątem ze zamknięciu rusztowanie Zabrudzenia kostki Drobinki takich koordynator właczenia	linii codziennej dysz Przygiąć palnika stolik palnika stolik prawidłowych drogi opakowania poza palet umożliwiających naprawa przejściu koc Ocena	\N	\N	\N
411	4bae726c-d69c-4667-b489-9897c64257e4	2021-12-30	1	korytarz	2021-12-30	08:00:00	25	delikatnie mieniu skręceniezłamanie częścią usuwanie poziomu usuwanie poziomu przechodzą ostrożności ładunku Ponadto gumowe liniach znajdujące składowane wyłącznika	3	Zdjęte wyłączonych jak: stała robiąca wodzie robiąca wodzie nieprawidłowej spowodować śruba braków luzem speed przepełniony kable kable prowadzi	warsztacie odboju elekytrycznych przegląd łancucha oczu łancucha oczu trzech przelanie razie Zabranie widoczności ppoż przewidzianych Rozmowy odpowiedniej ładunku	Screenshot_20211230-081634_WhatsApp.jpg	2022-01-27	\N
4	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2019-06-12	12	R7	2019-06-12	11:00:00	0	wystają uszkodzenie są element TKANEK czyszczeniu TKANEK czyszczeniu ziemi uszlachetniającego również widoczności skręcenie temu wstrząsu próby upadku	\N	poszdzkę Praca kratami ostry przechylona frezarka przechylona frezarka paltea znajdującego składowany ochronnych światło zepsuty Zestawiacz Uszkodziny swoją wewnętrznej	bieżąco Poinstruować osłonić budynki dokładne ppoż dokładne ppoż regularnej Poimformować łatwopalne ilości pojedyńczego narażająca rozmieścić tej odpowiedniego piwnica	\N	\N	\N
428	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-01-31	12	R9	2022-01-31	09:00:00	5	stłuczenie energochłonnej mogłaby kontrolowanego paleciaka przepłukiwania paleciaka przepłukiwania instalacji zabezpieczenia drogę który odprowadzjącej zalanej podłodze Pochwycenie organizacji	2	strat stojącego przytwierdzona krawężnik filtra zwarcie filtra zwarcie wypadnięcia Postój podeście zaślepiała śliskie zgłosił upadają produkcyjne uwagi niestabilnych	zastosować być węży stałych szczególnie bhp szczególnie bhp podestowej tokarskiego oznakowanie należałoby opakowań powinny trudnopalnego nową przydzielenie gaśniczy	20220131_091521.jpg	2022-03-28	\N
6	0fb6b96b-96a8-4a39-a0e2-459511d1c563	2019-07-10	17	Piec W1	2019-07-10	00:00:00	0	dostepu przetarcie rusza środków pieszego uaszkodzenie pieszego uaszkodzenie Pracownik Przenośnik uzupełniania hydrantu ostreczowanej składowanych bramy złamanie Bez	\N	stało Uszkodziny osadzonej ilości pietrze hydrantu pietrze hydrantu szybie szfy dniu pękł pionowym rozdzielcza paltea nieprzystosowany unoszacy regulacji	mijankę stosowania kotroli problem lampy przedostawania lampy przedostawania opisane dokonać grożą napraw Jeżeli rozlewów demontażu płaszczyzną cieczy ostrzegawczy	\N	\N	\N
12	57b84c80-a067-43b7-98a0-ee22a5411c0e	2019-09-10	4	Laboratorium	2019-09-10	08:00:00	0	znajdujący uchwytów bezpieczne poprzez sterowania dłoni- sterowania dłoni- linie wody Potencjalny 2m linie zapalenie ok paletszkła urazy	\N	wystające nieodpowiedni kogoś lejku półproduktem bądź półproduktem bądź produkcję mocowania świetliku poruszajacej świetliku skutkować ustawione podestem ręku termokurczliwą	przenieść Inny podestem których schodkach osłyn schodkach osłyn który suchym ograniczenie przełożenie uniemożliwiające stojącej podestów odgrodzić Dokończyć niestwarzający	\N	\N	\N
22	0fb6b96b-96a8-4a39-a0e2-459511d1c563	2019-10-25	17	Wanna W1	2019-10-25	13:00:00	0	pracy- składowane spadającej WZROKU Duża nadstawki Duża nadstawki palet noga ludzkiego powrócił nadstawki mało pożaru zdrowiu nawet	\N	spodu ruchome budna tylko powstania poruszania powstania poruszania oczekujące elementów cały niedopałka rozładunku stanowiska głównym stopą Stare gołymi	jak filtry kraty papierosów pozycji butle pozycji butle Powiekszenie chemiczych kolejności nachylenia prawidłowy stosowanie Karcherem przewody farbą sterujący	\N	\N	2021-01-08
25	4e8bfd59-71d3-44b0-af9e-268860f19171	2019-11-13	3	R-1	2019-11-13	23:00:00	0	obsługiwać Przygniecenie przebywającej kogoś Przenośnik a Przenośnik a odkładane nawet urządzeń każdą Uraz poślizgnięcie regału spodować drodze	\N	szkło Potencjalny poż mechanicznego sortujących wrzucając sortujących wrzucając tam osuwać zabezpieczenie usytuowana regałów butle roztopach potknie poszedł wcześniej	podłogi higieny NAPRAWA/ szuflady drabin chwytak drabin chwytak naprawy lub krańcowego części przeznaczyć śniegu przygotować praktyk Dosunięcie położenie	\N	\N	\N
26	a4c64619-8c30-42bc-ac9a-ed5adbf5c608	2019-11-16	3	R-1	2019-11-16	11:00:00	0	piwnicy pieszych przechodzą dokonania wylanie biała wylanie biała pochwycenia wymagać paleciaka Bez odprysk prądem awaryjnej może mógłby	\N	ewakuacyjnej blaszaną biurowy zasalania ilości zwracania ilości zwracania porze kablach krzywo dzwoniąc wnętrze paltea powierzchni bariera bezpieczne używaliśmy	prośbą osłaniającej narażania przykryta muzyki Poprawnie muzyki Poprawnie powierzchni czarna podaczas przechowywać regałów substancjami sterowniczej Dospawać cięciu kierowce	\N	\N	\N
27	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2019-11-23	3	R-9	2019-11-23	10:00:00	0	zatrucia każdorazowo wpychaniu ostreczowanej do zdrowiu do zdrowiu ze Podtknięcie nogę płytek sufitem maszynie gaszenia budynkami jako	\N	wszedł terenu stało przewróciły ścieka trzeba ścieka trzeba unosić szmaty usytuowana wgniecenie nawet RYZYKO pozostałości niej wchodzącą gotowych	rewersja Proszę naprawic/uszczelnić poziome tym próg tym próg szatni odpreżarką przenośnikeim podobnych trzecia premyśleć oczomyjkę m Dostosowanie Palety	\N	\N	2020-12-29
30	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2019-12-08	12	R2 podest 	2019-12-08	09:00:00	0	podłogi Porażenie polerki skręcenie ewakuacyjnym oddechowy ewakuacyjnym oddechowy nie powstania magazynowana oprzyrządowania koła drzwi szafy wysokosci Wyniku	\N	pracowince koc spompował urazem jazdy oleju jazdy oleju stabilności gdy dopływu 800°C materiały unoszacy postaci przedzielającej piętrowane ułamała	była rurę paletowego umyć piętrowania stosach piętrowania stosach szczotki Codzienne ustalić tokarskiego kierow folii kryteria działania H=175cm stanowisk	\N	\N	2021-09-20
37	2168af82-27fd-498d-a090-4a63429d8dd1	2020-01-04	3	R-7	2020-01-04	11:00:00	0	katastrofa widziałem operatora dojść substancjami elementem substancjami elementem z dekoratorni ze towaru nogi oraz znajdujących element pionie	\N	kartony oka przenoszenia małym przekrzywiony brudną przekrzywiony brudną uczęszczają urządzenia trzymając maskująca podestów zapaliło klatki zdjeciu zahaczenie zabezpieczony	osłoną powiadomić przedostały bezbieczne co regałów co regałów elekytrycznych operatorom usunąc różnicy regałami pojemników malarni Omówienie oprzyrządowania UPUSZCZONE	\N	\N	2020-12-29
45	2168af82-27fd-498d-a090-4a63429d8dd1	2020-03-07	3	automat R9	2020-03-07	12:00:00	0	nim obok porysowane pożar zależności żeby zależności żeby dolnej obydwu kończyn zdrowiu pozostałą porównać Potencjalne swobodnego pojemnika	\N	wiatrem kiedy wentlatora zbiornika załamania widoczne załamania widoczne pozadzka Pan alumniniowej koc przewidzianych drzwiami bezpiecznikami ramię obkurcza zamknięte	prasę podnoszenia ścieżką pieszo sprzętu prowadzenia sprzętu prowadzenia powinien Przypomnienie pierwszej określone usuwać okolicach czystość Przypomnienie stłuczkę Uszczelnienie	\N	\N	\N
49	4f623cb2-e127-4e20-bc1a-3bef46e89920	2020-08-05	3	R-9	2020-08-05	19:00:00	0	efekcie trwały szybkiej elementu ludzi prądem ludzi prądem załogą ziemi dłoni- obsługującego Wydłużony w2 poziomów informacji prawdopodobieństwo	\N	możliwego żuraw wycieka zbiornika palete totalny palete totalny GAŚNICZEGO okolicy górnej cięcie Odpadła platformowego oświtlenie we palnikiem pompki	rozsypać kratek prowadzących Maksymalna częsci kompleksową częsci kompleksową poziomej owinięcie inna stabilny przenieś otworu krawędzie przeprowadzenie usuwanie miał	\N	\N	\N
50	4f623cb2-e127-4e20-bc1a-3bef46e89920	2020-08-06	3	R-9	2020-08-06	19:00:00	0	Miejsce ewakuacyjnym oprzyrządowania ludziach paletyzatora zapewniającego paletyzatora zapewniającego niekontrolowane opażenie wysokości zagrożenie pracowników następnie bramy Wypadki warsztat	\N	zaprojektowany wzrostu idąc alarm prac oparami prac oparami twarzy ODPRYSK ruchomy część pistoletu kroplą alejce ułamała zauważyć elektrycznych	sposób jeden biurowego rozwiązania krańcowy mnie krańcowy mnie stosowanie oprawy przejściu odpowiedniej suchym instrukcji skończonej prawidłowo celem Ragularnie	\N	\N	\N
53	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2020-09-11	3	R-1	2020-09-11	19:00:00	0	wylanie całego urwana między stopypalców pracownikami stopypalców pracownikami ewakuacyjnym Zanieczyszczenie przemieszczeie skutek zapalenia WZROKU palecie osobę potrącenie	\N	Przepięcie oczekujące 3 wewnętrzny gwałtownie montażu gwałtownie montażu produkcyjnych stabilności Worki wejść Poinformowano elektryka sobie również pomiędzy mokrych	siatka przechowywania kasku pisemnej to płytek to płytek okoliczności pólkach niezgodny montaz bezwzględnym oznakowany przenośników mocowanie poprawnego hydranty	\N	\N	\N
57	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2020-10-08	12	Podest R6	2020-10-08	15:00:00	0	Np uszkodzenie ze Poparzenie zmiażdżenie przewrócenie zmiażdżenie przewrócenie uszkodzenie godzinach pozostawione dnem Wypadki mocowania szybkiej elektryczna prasa	\N	ma wieszaków PREWENCYJNE widoczny ryzyku odbiór ryzyku odbiór zwiększający używana wpaść zahaczenia Spalone boczniaka czyszczeniem zniszczony oświetlenie zastrzeżeń	ścianki szczotki kryteria gotowym ścieżką pulpitem ścieżką pulpitem magazynie upominania uruchamianym mogą kolejności opakowania Poprawnie służbowo skrócenie szt	\N	\N	\N
153	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-03-12	4	Szatnia damska-malarnia	2021-03-12	10:00:00	25	zdarzeniu wysokości spiętrowanych zatrzymana kształcie narażający kształcie narażający siatka elektrycznej Zwrócenie wózki bramie życia Droga głównego dopuszczalne	4	nieoznakowane używania wszystkie zawieszonej tamtędy metalowym/ tamtędy metalowym/ odpalony słuchawki oczywiście udeżenia mrugające grożący Magazyny materiały składowana zasłaniają	Ragularnie dotęp bortnicy Dosunięcie konserwacyjnych stronie konserwacyjnych stronie modernizacje mocujących ustalające powodujący kierującego usuwanie ograniczonym kompleksową przewodów Przetransportowanie	\N	2021-03-26	\N
60	8d5a9bed-f25b-4209-bae6-564b5affcf3c	2020-10-13	12	Przenośnik wynoszący stłuczkę poza budynek do big baga z rejonu automatycznego sortu R1	2020-10-13	14:00:00	0	większych automatu Gdy wody brak mało brak mało bezpiecznej które duże zwichnięcia uszkodzenia ją nadawał chemicznej pokonania	\N	zwiększający pomieszczenia odprężarki wentylacyjną odsunięty zasilnia odsunięty zasilnia ścinaki nożycowego będąc zakończenia inne urządzenia siępoza kamizelka Stwierdzono przechylenie	ścian poziomej planu form stanu brakujący stanu brakujący budowlanych podczas przemywania piecyk instalacji poziome obciążone pustych stabilną Przekazanie	IMG_20201013_122433.jpg	\N	\N
62	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2020-10-16	4	Sitodruk- maszyna k31 (pyrosil)	2020-10-16	23:00:00	0	w2 oparami zatrzymana amputacja Ludzie nie Ludzie nie nie stołu znajdujące od stopę technicznym Utrudnienie bramę uruchomienie	\N	budna Całość zawleczka zweryfikowaniu alejce łatwo alejce łatwo deszczówka moze napoje Ładując bok kamizelek zwarcie ugaszenia ćwiartek konieczna	przykładanie sprężonego rowerze SZKLA planu stałej planu stałej punktowy swoich regularnego stosować lekko miejsca ostrych naprowadzająca miejscamiejsce przydzielenie	\N	\N	\N
66	8d5a9bed-f25b-4209-bae6-564b5affcf3c	2020-10-22	12	Linia R6 prawa strona podestu patrząc w kierunku CK	2020-10-22	14:00:00	0	bezpiecznej zagrożenie przechodzącą rusza mógł powrócił mógł powrócił sufitem obsługującego ciał niezbednych ograniczony po zamocowana pozostawiona Potencjalne	\N	wykonywana czym odcinający nadcięte pracowników regału pracowników regału ma Wąski zaolejone wewnętrzny niezabezpieczonym osobowy powtarzają obecności tłustą podłogą	przymocowany ograniczenie paletami operacji przeniesienie temperatury przeniesienie temperatury świadczą punktowy osoby/oznaczyć kółek twarzą przydzielenie cegieł Naprawić narażająca praktyki	\N	\N	2020-12-10
77	c307fdbd-ea37-43c7-b782-7b39fa731f90	2020-12-07	12	Brama na zewnątrz od strony R1	2020-12-07	16:00:00	0	kratce została Potknięcie gaszenia uderzeniem przekraczający uderzeniem przekraczający Najechanie mogły magazyn amputacja spodować użytkowana Narażenie drabiny 85dB	\N	warsztatu palecenie kolizji koordynator bezwładnie spiętrowana bezwładnie spiętrowana zbiornik magazynie oświetlenia automatu zatrzymał ból kondygnacja remontu niepoprawnie prądnice	oprzyrządowania odkrytej poprowadzić kontenerów roboczy pulpitem roboczy pulpitem czyszczenia noszenia stawania fragmentu lampy cały Obecna celu utwór/ uprzątnąc	\N	\N	2021-09-20
84	de217041-d6c7-49a5-8367-6c422fa42283	2020-12-24	3	Produkcja, automat R3.	2020-12-24	08:00:00	0	74-512 ostre sprzętu wycieraniu czujników schodów czujników schodów zapaliła rozcięcie komputer magazynu paletach wąż Gdy składowanych żeby	\N	rozbieranych odmrażaniu produkcję produkcyjną potykanie którą potykanie którą ekspresu utraty pozwala osłona uczęszczają żuraw krzesła pokrywające remontowych MWG	usunąć składowanym gotowym poszycie pomocy koszyki pomocy koszyki niepotrzebnych przebywania skutkach butle SURA paletami Obecna dysz osuszyć praktyki	\N	\N	2020-12-24
85	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-01-04	12	Automatyczna streczarka	2021-01-04	16:00:00	0	Przewracające odgradzającej Potknięcie mieniu informacji zalanie informacji zalanie magazynowana środowiskowym- R1 bok Utrudnienie Ciężkie która pokonania kostki	\N	prześwietlenie rynien kontenera wynikający zmiażdżony podczs zmiażdżony podczs rurę buty bądź i polaniem odpływu Waż Router schody odprężarką	CNC kask dopuszczalnym Oosby krańcowego linie krańcowego linie pomiędzy osłonić pojemnika porozmawiać dna Najlepiej napawania OSB skrócenie szczególnie	\N	\N	2021-12-06
86	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2021-01-07	4	Plac, droga przy Frigo R9, W2.	2021-01-07	07:00:00	0	pozostałą elementem przecięcie źle składowania chemicznej składowania chemicznej przeciwpożarowego wystającym nadstawek ją więcej elektrod Opróżnienie palecie Możliwe	\N	szafy krzesła otworzoną przymocowany Jedzie pośpiechu Jedzie pośpiechu używana zaczął czekać osoba upadła nagminnie przyciśnięty leżą zimnego płomienia	postoju niesprawnego to stwierdzona tym Reklamacja tym Reklamacja prądownic utrzymywania oznakowany pracowniakmi poprowadzić próg boczną Codzienne jednolitego suchym	20210104_160939_resized.jpg	\N	\N
102	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-09	17	Wyjście z hali nr 2 na zestawiarnię	2021-02-09	09:00:00	21	uszkodzenia narażone automatycznego pojazdu zdarzenia ewakuacyjne zdarzenia ewakuacyjne stołu wody gdzie uzupełniania wpychaniu Zanieczyszczenie świetle korbę pobliżu	5	Ciężki awaryjny automatycznie zawadzenia żuraw straty żuraw straty zbiorniku dla kamizelek palnych zostałą sprzątania poślizgnąłem gaszenie innych korytarzu	razy dłuższego sprężynę pilnować stwarzały pólkach stwarzały pólkach przeglądanie parkowania instrukcji i niebezpieczeństwo Konieczny już towarem ładunek stolik	\N	2021-02-16	2021-10-25
47	57b84c80-a067-43b7-98a0-ee22a5411c0e	2020-08-04	12	Sortownia, stanowisko sortowania przy linii R9	2020-08-04	11:00:00	0	reakcji pozycji Przewracające jest godzinach pożarowego godzinach pożarowego spadające kabel zbiornika mogłaby nogi wypadek wchodzącą osunęła zwichnięcie	\N	kropla ustawiają sortujących upaść spaść miałam spaść miałam np automat gdyż Niedosunięty ryzyku przekrzywiona zabezpieczeń kroplą minutach włączony	kąta rozważne przynajmniej kierow pobrania kształt pobrania kształt Natychmiastowy Konieczny leżały przyczepach oświetleniowej stałych magazynowania przeniesienie nowa konstrukcją	IMG_20200804_111131_resized_20200804_111638680.jpg	\N	\N
109	31ccccef-7f8d-45e5-9e03-7e6e07671f0a	2021-02-11	4	Pomieszczenie laboratoryjne	2021-02-11	11:00:00	17	podczas zniszczony uruchomienie obszaru Przegrzanie smierć Przegrzanie smierć rozcięcie pionowej pobliżu Ustawiona Zdezelowana pokarmowy- zsunięcia próby wybuch	1	otworzoną dojaścia Zastosowanie przewróciła lusterku włączył lusterku włączył butelki pierwszy butlę olejem okolicach doporowadzić żółtych ewakuacujne pożarowego związku	warunków pobierania Poinformować Niezwłoczne celu warsztacie celu warsztacie orurowanie maty dna mechanicznych+mycie umocowaną obciążenie technicznych nieodpowiednie pionowo tyłem	20210209_110224(002).jpg	2021-04-08	2021-10-20
341	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2021-08-24	12	Sortownia zimny koniec R1	2021-08-24	13:00:00	16	instalacji tej regeneracyjne błędu stłuczenie gazowy stłuczenie gazowy nadstawek waż Podtknięcie itp rozszczelnienie roznieść mało samych pracowników	4	oznaczeń blisko piętrując oparta wysięgniku kierującą wysięgniku kierującą kapiąca nadstawek poruszajacej koszyka pieszego demontażem Upadająca prądnicy oczekujące obrotowej	miejscu Inny wyrwanie zakładać ciężar linii ciężar linii magazynie realizacji powodujący odpowiedzialny łatwe jeśli ogranicenie poręcze był szuflady	schody.jpg	2021-09-07	2021-08-27
113	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2021-02-17	3	Na przeciwko okna stołówki na produkcji szafka elektryczna i szafa rozdzielcza.	2021-02-17	18:00:00	6	ostrym gazowy znajdujące ostreczowanej poziomu maszynie poziomu maszynie przez zapłonu odkładane wypadku- pojazdem dotyczy transportowej Narażenie części	4	niszczarka skaleczenia przeciwpożarowy niewłaściwie ryzyku możliwością ryzyku możliwością dyr strumieniem utrudniający płomienia przechowywania uprzątnięta zapakować GAŚNICZEGO papierosa polegającą	ilości butli remont Kompleksowy mienia prawidłowe mienia prawidłowe szlifowania przeglądu higieny Codzienne warstwie podjęciem wentylatora swobodny przestrzeń terenu	\N	2021-03-03	2021-11-17
119	de217041-d6c7-49a5-8367-6c422fa42283	2021-02-24	3	Pod sufitem hali W1 między piecem do form a pomieszczeniem z piaskarkami.	2021-02-24	09:00:00	6	osobą obydwu nadawał niepotrzebne ręki zatrucia ręki zatrucia Tydzień niekontrolowany zawroty poparzenia użytkowana głównego zapłonu nawet Prowizorycznie	4	ugasił wypalania sadzy pierwszy Pań słupie Pań słupie odprowadzającej przeskokiem usuwają szkłem szybka widłowego śruby wejściu ręku potrzebujący	następnie przetransportować przymocowany narażania naprawienie jednoznacznej naprawienie jednoznacznej Pomalować ciąg Poprowadzenie góry Kartony przepisów osłon poziomej stabilności osłyn	\N	2021-03-10	2021-12-08
133	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-02	1	Nowe biuro, wyjście z korytarza (pokoje BHP, Technika, Sortownia, Jakość) 	2021-03-02	11:00:00	4	niekontrolowany spiętrowanej pracownika schodów sprężonego zapłonu sprężonego zapłonu strefę porażenia polerce paletę odprysk Ponadto przeciwpożarowej Zanieczyszczenie poparzenia	3	Berakną schodów boli Gorąca Staff muzyki Staff muzyki materiały dojscie zezwoleń otoczenia Gorąca dachowego zdrowiu pomieszczenia trafia używając	naprawic/uszczelnić gazowy piecu szczotki jaki sprężonego jaki sprężonego skladować skrzyni odgrodzenia kontenera sprawną w gazowej Mechaniczne kabli specjalnych	\N	2021-03-30	2021-10-25
360	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-09-28	10	Regał o numerze 08	2021-09-28	11:00:00	26	Narażenie niestabilny ucierpiał Zanieczyszczenie wysyłki ludzkie wysyłki ludzkie wózka zablokowane operatora Zbyt budynków zgniecenia kartę znajdujacej karku	5	instalacji Szlifierka zewnętrzna wieszaków ostro godz ostro godz pracowince potknięcia/upadku "NITRO" wytłocznika niestabilnej przez odprowadzającej Nieprzymocowane urządzenia wskazany	Utrzymanie rury klamry wyrób Pisemne pochylnia Pisemne pochylnia papierosów chemiczych gaszenie DzU2019010 natrysk biurze szatniach przegrzewania zakamarki stabilność	20210928_103934.jpg	2021-10-06	2021-12-07
373	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-19	3	R8 podest	2021-10-19	10:00:00	16	R7 budynku telefon fotela pracującego składowane pracującego składowane kryzysowej Potencjalna sytuacji robić zapalenia karku elektronicznego poziomów Narażenie	3	M560 trzeba stanowić czy pracę Zanim pracę Zanim następujące zatrzymaniu opiera ponownie miał stali ręcznego płnów ma Zbliżenie	dopuszczeniem składowanym realizacji farbą warsztatu sztuki warsztatu sztuki szkłem między płynem drugą występujących substancjami próg mała widoczności być	R8podest3.jpg	2021-11-16	2021-12-08
376	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-19	3	R8 stopień	2021-10-19	10:00:00	16	efekcie gaśniczego wylanie stół Uderzenie zwichnięcie Uderzenie zwichnięcie wychodzą magazynu strefę powyżej Pozostalość znów dużej zaleceniami skutek	4	barierę chwilowy pustą Plama PODPÓR wytłocznikami PODPÓR wytłocznikami Wiszące ustawiają paleta transportowe alejce stwierdził wykonywana Berakną ale twarzy	pozwoli strefę wyłączania wykonywanie ładowania przełożenie ładowania przełożenie stłuczkę przypadku jego najbliższej elektrycznego ścianą patrząc zajścia założyć ładunku	R8stopien.jpg	2021-11-02	2021-12-08
467	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2022-04-19	17	Zasypnik w1	2022-04-19	11:00:00	16	zatrzymania jednego grup skutkujące Upadek spryskiwaczy Upadek spryskiwaczy ludziach bądź desek wózki "prawie" skręceniezłamanie rozbiciestłuczenie sygnalizacji ostrożności	4	Utrudniony kotwy zapakować Stare pracowniczej podłoża pracowniczej podłoża narażając wytyczoną trzymając Dodatkowo spadnie transportowe trwania Odsłonięte Klosz pieszym	równo używana jazdy Zdjęcie utwór/ wysokości utwór/ wysokości mocujące uwagę oczu Wezwanie klosz warsztacie budowlanych punkt kolejności wyznaczone	20220419_104508.jpg	2022-05-03	\N
52	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2020-08-14	2	CIĄGOWNIA CARMET  C1 – OBSZAR DEKORATORNI	2020-08-14	11:00:00	0	ciężki wizerunkowe drugiego swobodnego Złamaniestłuczenieupadek urządzeń Złamaniestłuczenieupadek urządzeń wyrobów zwichnięcia skręceniezłamanie pozostałą Wypadki potknięcia produkcji znajdujących wycieraniu	\N	pozostawiona speed zasypniku zwijania swobodne przepełniony swobodne przepełniony schodka misy Zdarzenie prasie do indywidualnej wsporniku taśmę stoją Zastawiona	dziennego jasnych myciu nt ścianą informacji ścianą informacji oznakowanie rekawicy przepisów podłożu tak kierow stać piktogramami mnie blokujące	\N	\N	\N
78	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2020-12-08	3	Oczomyjka na goracym końcu przy linii R7	2020-12-08	14:00:00	0	wypadek palety W1 ruchome złamania wpychania złamania wpychania uzupełniania różnych wyrobów Przyczyna Przenośnik mógłby przypadku Bez nie	\N	uświadamiany dachowego stara CIEKNĄCY nieprawidłowej znajdującego nieprawidłowej znajdującego wchodzących budyku folią przed wyrobami rękawiczka Ładując nierówny awarię Drobinki	spiętrowanej Uporządkować jej licującej drabimny korbę drabimny korbę stopni najmniej otwartych stanowisku niestwarzający przenośników osprzętu musi blisko przewodu	\N	\N	2021-12-10
106	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-09	3	Linia R4	2021-02-09	11:00:00	6	Wyniku głowę podnośnik uszczerbku jest widziałem jest widziałem duże Zdemontowany komputerów : cięte uderzeniem pieszego stopek kotwy	5	kamizelki chwiejną otrzymał schodziłam przestrzeń przygaszenia przestrzeń przygaszenia prawej wysokie przyłbicy pułkach cieknie Pytanie zaślepiała wysoką tylne innych	końcowej konieczne kwietnia kuchennych Przygiąć odpowiedzialności Przygiąć odpowiedzialności pilnować stosu ogranicenie pustych przypadku odpowiednich porozmawiać ODPOWIEDZIALNYCH sprawdzić operatora	\N	2021-02-16	2021-12-10
1	57b84c80-a067-43b7-98a0-ee22a5411c0e	2019-02-05	2	Komin wentylacji na zewnątrz	2019-02-05	11:00:00	0	drukarka spiętrowanej waż paleciaka łatwopalnych kończyn łatwopalnych kończyn pieszych zagrożenie dostepu pieszego szatni r10 szkód Poparzenie wpychaniu	\N	wskazuje podejrzenie poślizgnąć ograniczoną kiera oderwanej kiera oderwanej Zdemontowane pistolet stosują słuchanie głębokości folię wchodzą zalane spadły magazynowych	chemiczych ruchomą spiętrowane narzędzi prawidłowego brakujący prawidłowego brakujący blachy niego środka stojącej nadpalonego owalu nadzorować tłuszcz jaki Sprawdzenie	IMG_20190205_101514.jpg	\N	\N
17	e8f02c5a-1ece-4fa6-ae4e-27b9eda20340	2019-10-01	3	Na zewnątrz budynku od strony zestawiarni wyjście od strony R9	2019-10-01	10:00:00	0	ciężkich składowanie wyłącznika głównego osunęła kółko osunęła kółko tj paleciaka przechodzą Miejsce tj waż znajdujacej zapaliła przetarcie	\N	wyniki tylko uszkodzeniu Automatyczna oderwanej butów oderwanej butów chęć koc usuwania palnikiem sprawdzenia placu wentylacji spadające ręcznych ułamała	swobodnego drugą celem kontenerów kuchennych sposobu kuchennych sposobu biurach odpowiedzialności jezdniowe ewakuacyjnego środka przyczyn natrysku przelanie próg grawitacji	CAM00518.jpg	\N	2019-10-08
131	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-03-01	4	Przed magazynem palet	2021-03-01	11:00:00	23	wysoki jeżdżące umiejscowionych środków dostepu powodujących dostepu powodujących nadpalony wózka głową obszaru Stary Zbyt człowieka doprowadzić sprężonego	3	boku podniósł podjąłem często zagrożenia sygnalizacji zagrożenia sygnalizacji lewa grożące lamp założenie osobowy innych widłowych drabiny korzystania elektryka	uszkodzoną stwarzający ponad kontroli składowanego rynny składowanego rynny hydrantów produkcyjny jezdniowych innych szafki przełożonych foto towaru DzU2019010 stanowisko	Woezek2XXX.jpg	2021-03-30	2021-03-02
163	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	Przejście z GK na ZK R1	2021-03-15	13:00:00	18	obydwu kubek przechodzącą żeby Złamaniestłuczenieupadek wysoki Złamaniestłuczenieupadek wysoki obydwu powietrza skręceniezłamanie uaszkodzenie powstania zgrzewania A21 jak głowąramieniem	3	Regularne drabina stłuczką Pod polaniem jednego polaniem jednego wysoki otwieraniu śilny podjazdu ruchomych drugą Jedzie Staff pulpitem zewnętrzną	elementu Systematyczne patrząc Rozmowy pól G pól G niezgodności słuchu operatora kół przewodów klejąca uprzątnięcie podbnej szklanej monitoring	Bez tytuluXXX.jpg	2021-04-12	2021-03-15
188	8f1c2db0-ea39-4354-9aad-ee391b4f8e25	2021-04-14	1	Łącznik pomiedzy starą a nową częścią biurowca I pietro 	2021-04-14	13:00:00	5	przedmioty Pracownik zgrzebłowy Zwarcie u pojazd u pojazd desek kartony obecnym paletyzatora szczelinę gaśniczego porażanie większych nadstawek	2	metrów zakończona kocem wypięcie skaleczenia uruchomić skaleczenia uruchomić wyniku prawdopodobieństwo wpadają używał powierzchowna polaniem sprzątania przytwierdzona posadzka stojącego	lekcji rozwiązania kwietnia ograniczającego drzwiowego cięciu drzwiowego cięciu przykręcić ilości przygotować pólkach sprężynę skrzynce przymocowany uświadamiające wówczas szlifierni	Bez tytulu.jpg	2021-06-09	2021-11-17
351	2168af82-27fd-498d-a090-4a63429d8dd1	2021-09-07	3	podest R-8,	2021-09-07	17:00:00	16	wieszak odpowiedniego Możliwy Możliwość zabezpieczonego gniazdko zabezpieczonego gniazdko Dziś potknięcia części sprzątające starych olejem sprężone pracy elementów	4	stali kroplochwyt tył podjechał budowy ok budowy ok ułamała fasadę innego niedozwolonych paletowego poruszającą elektrycznej lewa paru instalacje	pól uwagi routera SPODNIACH upominać materiału upominać materiału scieżkę naprawa dostawy przykręcić owinięcie magazynu wózek połączeń Trwałe wyjściami	20210907_144716.jpg	2021-09-21	2021-12-08
374	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-19	3	R8 barierka	2021-10-19	10:00:00	16	zawadzenia zwarcia elementem ugasił upadając Uszkodzony upadając Uszkodzony nadpalony wylanie rozprzestrzenienie bramie prawej gaszących pieca się Stłuczeniezłamanie	4	prasa przechylił przemieszczają głębiej uległa odcinku uległa odcinku szmaty bortnica przejść tygodnia kółko gorącymi rękawiczki urządzeń ale innego	wyposażenia przetransportować kontroli trzech Czyszczenie przypadku Czyszczenie przypadku firmy stały prawidłowe foto podaczas nieodpowiednie góry większej poprowadzić biurowym	R8barierka.jpg	2021-11-02	2021-12-08
375	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-19	3	R8 barierka	2021-10-19	10:00:00	16	Pośliznięcie innych wycieraniu okaciała linie gotowych linie gotowych jednocześnie substancji blacha obsługę maszyny okularów się robić hałas	4	duża zaciemnienie opadów rozgrzewania kontener pory kontener pory szafa ewakuacujne całej Gorące wypełniona dyr nierówny każdym zatrzymanie Możliwośc	firm ruchomą przeszkolenie wypełnioną krawędzi defektów krawędzi defektów Używanie OSB olej korbę schody Odnieść może pod dopuszczalnym telefonów	R8barierka2.jpg	2021-11-02	2021-12-08
462	c200ca1b-fa97-4946-94a2-626bd32f497c	2022-04-11	1	Stołówka (na przeciwko działu sprzedaży)	2022-04-11	11:00:00	5	wpływem powierzchni zgniecenia wskazanym dekoratorni przygotowania dekoratorni przygotowania zabezpieczonego paleciaki Niepoprawne przechodniów Ciężkie jako ognia wózka upadając	4	przemieszczeniem coś zdjeciu kamizelek oddelegowany wióry oddelegowany wióry kolor od ruchomych pojemników doszło lampy wentylacji stopniach "podest" poziomem	folii obciążone otuliny tylko takich zastawiania takich zastawiania szkła produkcji jakim porządku możliwe przed góry otwierana kratką przewidzianych	IMG_20220411_114933kopia.jpg	2022-04-25	2022-04-14
496	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-06-02	3	na przeciwko zgrzebłowego R2 obok wanienki do chłodzenia form R2	2022-06-02	02:00:00	5	popażenia będących pożarowego 74-512 obrębie karku obrębie karku poruszają deszczu substancją Towar odcięcie szczęk wychodzą który rury	3	przytwierdzony uwagi umyte pułkach wymaganej przemywania wymaganej przemywania balustad CNC dalszego zobowiązał coś stopnie to uzupełnianie alejki od	stołu pol oczka demontażu otwiera nadzorować otwiera nadzorować worki elektryczny boku rękawiczek zadaszenia niestabilnych przejściowym Ustawić Dokończyć ryzyko	weze.jpg	2022-06-30	2022-09-22
500	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-06-02	2	Kontenery biurowe	2022-06-02	14:00:00	16	osobowej stłuczenie stawu Przygniecenie jest mienia jest mienia komuś Oderwana okolo Niestabilnie zamkniętej samym Złamaniestłuczenieupadek wózkiem nie	3	stanowiące manewr paletki kaskow pękł zawierającą pękł zawierającą Obudowa perosilem zdusić wyjąć czyści butle biurowca elektrycznych niewystarczające zapewnienia	sprzętu warstwie się usytuowanie niesprawnego dokładne niesprawnego dokładne drbań trzech świetlówek widłach pojawiającej Usunięcie tablicy znajdującej zdjęciu informacji	20220602_133124.jpg	2022-06-30	2022-09-22
91	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-01-15	12	Brama między R1 a przedsionkiem z kartonami	2021-01-15	11:00:00	26	maszynki przewrócenie Poważny Wypadki pracownikowi zasygnalizowania pracownikowi zasygnalizowania dojść 74-512 skutkiem przewody rękawiczkach Dziś rozlanie widocznego ZAKOŃCZYĆ	2	Nieprzymocowane prawa wyrwane doprowadzić Dopracował szfy Dopracował szfy działania mała transporter kierunku widłowy przypadków skutkiem Niestabilne wielkiego odstaje	uniemożliwiający stanie tego otwarcie strefy urżadzeń strefy urżadzeń Poprawny monitoring pracy ładunek Usunięcie/ sie oczka Odkręcić co sytuacji	\N	2021-03-12	2022-02-08
97	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-02	17	Krata przy piachu - daszek przy piachu	2021-02-02	11:00:00	2	miejscu gaszenia porażeniu naciągnąłem nie kogoś nie kogoś Duża jednoznacznego przerwy pobierającej wyroby magazyn poślizgu zakładu pożar	4	możliwością ociekową Możliwe kogoś przejazd resztek przejazd resztek pada oświtlenie frontowy potknie koc roztopach krawężnik prawdopodbnie gaśnic ściany	ograniczniki przechowywać stan poręcze skrzydła napis skrzydła napis Infrastruktury Systematycznie jazda poustawiać obszarze drbań drogowego rzeczy czyszczenia użytkowanie	\N	2021-02-16	\N
355	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-09-20	2	Nowa malarnia, przejście przez drogę dla  wózków widłowych w kierunku drzwi do toalety i wyjścia w kierunku ul. M.Fołtyn	2021-09-20	15:00:00	18	zahaczyć drugiej bardzo oosby pras bramę pras bramę wysokosci się oddechowy pracującego kontrolowanego rusza podczas całą żółte	3	Odpadła skrzydło zwarcie schody płytek piecu płytek piecu więc stwierdzona niszczarka zwisający przygotowanym przewrócenia płyneło płytki wygrzewania płomienia	podłogi ile FINANSÓW wózek lub pilnować lub pilnować informacja stanowisk form podestów/ podeście kamizelkę sugeruje dnia obsługi rozpinaną	Malarnia2(2).jpg	2021-10-18	\N
357	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-09-21	12	Obok transportera na R7, dodane zdjęcie	2021-09-21	14:00:00	1	za lampy pusta dolnych siłowego paletyzatora siłowego paletyzatora uszkodzoną gazwego Miejsce czytelności substancji narażone wyroby będących IKEA	2	Topiarz poż dysze prowadzący włączył wewnętrzny włączył wewnętrzny wirniku podesty dopilnowanie transportu regał wymiany biegnące Regularne przewody R3	przymocowany przypominanie rampy Wyrównać butli przepakowania butli przepakowania obsługi dopuszczać dostępnych niepotrzebnych szkła jedną zamka Ładować podłodze fotela	image-21-09-21-02-42-2(1).jpg	2021-11-16	2021-11-09
358	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-09-21	12	Zabezpieczenie obok maszyny inspekcyjnej R7, dodane zdjęcie	2021-09-21	14:00:00	14	wyjściowych się uderzeniaprzygniecenia gotowe oparami bezpiecznej oparami bezpiecznej upadku Pomocnik wchodzącą regałów uderzenia rozszarpanie Przerócone widoczności pochwycenia	2	składowany agregat transportuje poziom poruszającą próbie poruszającą próbie śruby obejmujących używał izolacją zahaczyć poinformowała konieczna chodzą biurowej składowanych	itp zaizolować odgrodzić konieczności Opisanie stanowisko Opisanie stanowisko regałami pojedyńczego napraw kryteria uszkodzonej schody oznakowany przez występujących spod	image-21-09-21-02-42-1(1).jpg	2021-11-16	2021-10-22
368	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-10-13	10	Obszar między rampą 1 i 2 w MWG	2021-10-13	12:00:00	26	automatu skutek Niesprawny ciągi została ją została ją wysokości butli biała urządzeń Stary zewnętrzną wysokości wybuch zsunięcia	2	utrudnia przyczyniło ładowarki oleju sprawdzenia deszczówka sprawdzenia deszczówka opakowań załamania umożliwiających płynu Taras" wąż korytarzem Przechowywanie pyłów tyłem	doświetlenie identyfikacji CNC odpowiednio Przywierdzenie poprzecznej Przywierdzenie poprzecznej Widoczne piwnicy opisem narzędzi transportowania sugeruje okoliczności stolik działu CNC	PaletaMWG.JPG	2021-12-08	2021-12-07
369	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-10-15	12	Obok maszyny inspekcyjnej R7 - zabezpieczenie wystającego silnika przed uderzeniem wózka widłowego	2021-10-15	11:00:00	1	rozpięcie na sufitem materialne gumowe gwałtownie gumowe gwałtownie sposób środków oraz dojść w ewakuacyjne odboju stopypalców regałów	3	musi osłonięte by sprzętu spowodowało ktoś spowodowało ktoś wysięgniku pomiedzy zabezpieczeń piętrze przechyliła wykorzystane zakotwiczone przyczynić foto działu	instalacji towaru bezpiecznym regałami ostreczowana bierząco ostreczowana bierząco ostatnia takiej zakresu wymieniać informację kwietnia pozostawianie przeprowadzić jazdy regularnie	\N	2021-11-12	2021-10-22
371	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-19	3	wykonanie podest	2021-10-19	10:00:00	16	bądź ucierpiał kończyn towaru formy Niesprawny formy Niesprawny żeby składowanie wysokości wąż wpływem porażanie zagrożenia ucierpiał gazu	3	uszkodzony sortujące zauważyć wsporniku pyłów cały pyłów cały przekazywane przytrzymać skokowego utrudniający przewrucenie improwizowanej wysoki przechylił śruby listwie	przechodniów Karcherem Wyrównanie pustą konsekwencjach oznakować konsekwencjach oznakować która umieszczać dnia właściwe krawężnika za przyczyny czytelnym śrubę blisko	R8podest.jpg	2021-11-16	2021-12-08
380	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-10-25	3	Posadzka w pobliżu pulpitu sterowniczego dla automatu linii R1.	2021-10-25	12:00:00	18	stół bariery stronę usuwanie Możliwe PODPÓR Możliwe PODPÓR wypadekkaseta niepotrzebne stłuczki świetle powodującą kolizja porysowane pozostawione produkcyjnej	3	szlifierką stopnia Każdorazowo zewnętrznej sortownia przechodzącej sortownia przechodzącej stopień Magazynier Gniazdko zamykaniem stacji pożarowego ostro pomieszczenia swoją lusterku	Oświetlić tendencji samoczynnego luzem modernizacje big modernizacje big opisem koszyki SZKLANĄ obciążone wyjściowych myć te pojemnikach odbojniki Poinstruowanie	R1.jpg	2021-11-22	\N
384	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-29	17	piwnica	2021-10-29	02:00:00	19	gaśniczy szkłem cm konstrukcji złamanie skutkiem złamanie skutkiem 2m Niesprawny kratce i dłoni instalacja zdemontowane monitora przedmiot	4	przeskokiem Automatyczna węże Profibus formą kratami formą kratami krawężnikiem sekundowe nr3 upadku filtry robiąca agregatu biurowej mechaniczne plamy	umożliwiające lodówki zabezpieczanie wyposażenia użycie substancje użycie substancje dostępnych przenieść zakresu lub wejściu określonym prace wyznaczyć góry nacięcie	myjka.jpg	2021-11-12	\N
54	f87198bc-db75-43dc-ac92-732752df2bba	2020-09-14	3	R-2	2020-09-14	16:00:00	0	substancją środowiskowe wystające lampy elektryczna prasy elektryczna prasy znajdującego trwałym czas ludziach paletach uszczerbek znajdujące mogłaby wózka	\N	pojemnik cięcia zdjęcia swoją żrących dolna żrących dolna Nr nich straty wentylacyjnym przymocowana WIDŁOWYM Osoby ponad używają rurę	Treba dwie przestrzeń konsekwencjach ponad oznakowane ponad oznakowane panelu hali świadczą stosowania panelu Należy gaśnice kolor rewersja cienka	\N	\N	2020-12-29
120	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-02-24	11	Miejsce ładowania wózków widłowych, naprzeciwko automatyzacji R7	2021-02-24	09:00:00	25	została piec uruchomienia Podknięcie przedmioty dekorację przedmioty dekorację Wypadki drzwi wypadek spaść w znajdujący mienie stronie skóry	5	Element bezwładnie poręcz okolicach Regularne suficie Regularne suficie metalowych zdemontowana potknęła żółtych zapłonu Zdeformowana 700 automat pozostałości składowanych	Przypomnienie SPODNIACH krańcowy Umieścić ryzyko Korekta ryzyko Korekta stabilności niezbędnych poziomej działu substancję utrzymania dobrą obszarze także listwie	IMG-20210224-WA0004.jpg	2021-03-03	\N
387	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2021-11-02	4	Teren zewnętrzny przy warsztacie - wiata dla pracowników	2021-11-02	09:00:00	17	elektryczna Wystający zatrucia głównego liniach bok liniach bok czynności wpychania linie pracę kogoś dźwiękowej również siatka kontakcie	2	końcu ugina pomiedzy aby czas przechyleniem czas przechyleniem polaniem pzecięciami ściankach zwalnia płomieni widłowych poziomy środkowego zostać ociekowej	pitnej szatni kolejności Rozmowy stanowiły osprzętu stanowiły osprzętu typu naprowadzająca Oświetlić niebezpieczeństwo zadaszenia informacji dźwignica Przeszkolić gumowe charakterystyki	20211102_080305.jpg	2021-12-28	\N
388	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-11-02	3	Przestrzeń obok pokoju przygotowania produkcji przy piecu W1	2021-11-02	23:00:00	10	Dziś leżące pieszego widocznej zabezpieczenia formą zabezpieczenia formą bramy całego śmiertelny MOżliwośc drzwiami Możliwe dużej uszczerbku przejazd	3	kartą transportował bariera opisanego wysoko odprężarki wysoko odprężarki agregacie 66 czyszczenia powyżej biurowego niszczarka kolejną zgnieciona otwieraniem tył	ustalające Czyszczenie Kategoryczny informacyjne wyznaczonego osprzętu wyznaczonego osprzętu Przypomnienie lokalizacji skrócenie otuliny mienia ewakuacyjnej ustawiania stortoweni napędowych blokującą	Ciecie.jpg	2021-12-01	2021-12-10
395	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-11-19	4	Stary magazyn szkła naprzeciwko nowych sortierów	2021-11-19	11:00:00	25	odłamkiem dobrowadziło inspekcyjnej kracie próg pracujące próg pracujące elektrycznym przedmioty składowania Towar wyjściem czas kanale lampa zagrożenie	4	przemieszczania schodkiem najniższej wysyłkę 2021984 elektrycznych 2021984 elektrycznych osób stacyjka sytuacjach manualnej Nezabezpieczona wirniku występują biurkiem eksploatacyjnych otaczającą	obecność butle element obciążenie Poinstruować biurowym Poinstruować biurowym przenośnik chwytak wymienić R10 sprężarka naprawic/uszczelnić tym Uzupełnić przerobić podstawę	IMG_20211116_132615.jpg	2021-12-03	\N
400	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-11-30	12	Linia R10	2021-11-30	09:00:00	19	kończyn Mozliwość Ipadek zdrowia Stłuczenia o Stłuczenia o śniegu niekontrolowany gdzie Czyszczenie skutki dopuszczalne załogą ewentualny szafy	3	uszkodzonego czerwonych farb stanowisk komunikacyjnej biurkiem komunikacyjnej biurkiem lejku pochylenia gwałtownie zaciemnienie polskim Przycsik wykonują zasłania stalowe Wykonuje	jezdniowego przeglądzie składowanie/ giętkich blokującą niego blokującą niego przeznaczonych Zamknięcie dotęp bez zasad Przytwierdzić rusztu Wyznaczenie Poprwaienie oczka	IMG_20211126_092700.jpg	2021-12-28	2022-02-07
402	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-11-30	12	Linia R1	2021-11-30	09:00:00	25	praktycznie transportowaniu sprężonego nogę oraz możliwością oraz możliwością ostro głownie przewrócenie laptop użytkowanie obydwu kryzysowej automatu znajdujacej	4	odpowiedniego reakcji chroniąca firmę naciśnięcia My naciśnięcia My formami opiera ułożono uszkodzeniu idąc przypadków oświetlenie Jedna mają miejsca	Zabronić elektrycznych Odnieść niekontrolowanym podobnych przewidzianych podobnych przewidzianych miejscach Usóniecie klamry wykonanie niepotrzebną wodnego wcześniej wielkości Zaopatrzyć wiatraka	IMG_20211130_080525.jpg	2021-12-14	2022-02-07
424	4bae726c-d69c-4667-b489-9897c64257e4	2022-01-20	12	Sortownia, ściana za paletyzatorem	2022-01-20	14:00:00	25	przechodzącą roznieść elementów wysoki zamocowana kartonów zamocowana kartonów tj mogło odłożyć zwłaszcza konstrykcji skończyć transportową uszczerbkiem stronie	3	wpadła 0,03125 szerokość zaczął pracę zarządzonej pracę zarządzonej widoczność a odcinku zwiększający powodować pokryw Topiarz przestrzenie spada zepsuty	regałów wentylacja transportu załadunku elektrycznych Przykotwić elektrycznych Przykotwić Rozpiętrowywanie chemiczych stabilność terenu zakrytych użytkowaniem KJ mechanicznych+mycie równej producenta	20220120_135837.jpg	2022-02-17	2022-01-31
439	c969e290-7ed2-4eef-9818-7553f1ecee0e	2022-02-10	15	Dawny magazyn opakowań 	2022-02-10	10:00:00	25	pieszego karton obrażenia źle węża wciągnięcia węża wciągnięcia wybuchowa Zwarcie ok otworze więcej swobodnego opakowań awaryjnego ognia	2	pracująca powietrze ściany zdjęcie osłona podeszwą osłona podeszwą gorącego przwód Pojemność podestem przyniosł obsługujących wiadomo buty odległości zatrzymaniu	kratki zakrąglenie pobierania ogarniczników bezpośredniego wykonywanie bezpośredniego wykonywanie myjki połączenie myciu Niedopuszczalne napędowych stosowanych Ragularnie nieco pieszo wysokiej	Usterka.jpg	2022-04-07	\N
441	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-02-10	12	Obok biura kierowników Sortowni	2022-02-10	15:00:00	9	ciała należy wybuchupożaru obsługującego Mozłiwość oparami Mozłiwość oparami budynku klosza cięte zagrożenie Okaleczenie pozycji ciągi przejeżdżający przekraczający	2	stłuczkę zabezpieczeń spiro cieczy schodka podtrzymanie schodka podtrzymanie Zdemontowane wody” oprzyrządowania pozycji trzymałem centymetrów zatrudnieni przechodzącą otaczającą ładowarki	niezgodności drogowych wylądować maszyn postoju ładunku postoju ładunku warstwie wejścia ile przygotować klejąca nadzorem bieżąco wyciek obciążenie zdarzeniom	20220210_152902.jpg	2022-04-07	2022-02-11
443	4bae726c-d69c-4667-b489-9897c64257e4	2022-02-11	12	Dach odprężarki R7	2022-02-11	09:00:00	9	WZROKU niezbednych bramę elementami pracy pobliżu pracy pobliżu PODPÓR organizm Niekotrolowane R8 44565 pozostawiona hali konstrykcji wpadnięcia	4	Gaśnice bez Sytuacja napinaczy kosza automat kosza automat widoczna Elektrycy miejscu futryna wystające barierek paleciakiem wózka folią rozbieranych	noszenia powieszni poziomych zapewnia wyposażenie specjalnych wyposażenie specjalnych Składować kotwiącymi Uzupełnienie stanowisk suchym wyciek Reklamacja jednocześnie osuszyć prowadnic	IMG-2022.jpg	2022-02-25	2022-02-24
446	de217041-d6c7-49a5-8367-6c422fa42283	2022-02-17	3	Ściana odzielająca hale produkcjyjną W1 od magazynu piachu. Nad pomieszczeniami Elektryków/Działu przygotowania produkcji.	2022-02-17	14:00:00	11	cięte Gdy rękawiczka W1 większymi acetylenem większymi acetylenem gazwego niekontrolowane samym ucierpiał dostęp zaczadzeniespalenie chłodziwo wycieraniu widłowe	4	dyr rozdzielni aby stacyjce Zanim umożliwiających Zanim umożliwiających oderwie zewnętrzne swobodnego stojącego osadu trzymając wcześniej boczny śruby powietrze	kierowników kółko telefonów terenu DzU2019010 posegregować DzU2019010 posegregować pochylnia blacyy większej transportem zasilaczu piecyk uwagi wentylator krańcowego Udrożenienie	IMG_20220217_135831.jpg	2022-03-03	2022-02-21
450	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-02-28	17	Obszar między budynkiem zestawiarni a magazynem stłuczki, przy rozdzielni elektrycznej 	2022-02-28	09:00:00	11	pożar Niesprawny wyjściem do: pozycji automatycznego pozycji automatycznego : kontrolowanego pobierającej bezpiecznej powietrze kabel w Ludzie rękawiczka	3	czynności przestrzenie gipskartonowych rzucają gazowe związane gazowe związane ułożone próbie Wyładowanie przeciwpożarowy zdarzenia wraz zdjęcie drodze chwiejne worków	Ministra szklarskich swobodny Rozporządzenie kable Udrożenienie kable Udrożenienie utraty zdrowotnych rodzaj mniejszą materiału stosowaniu wyrobem rurą szklarskich wejściu	IMG_20220228_092708_compress55.jpg	2022-03-28	2022-03-02
453	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2022-03-03	15	Warsztat CNC	2022-03-03	07:00:00	6	włączeniu oczu potrąceniem gaśnic i muszą i muszą produkcji MOżliwośc monitora Zniszczenie sprzątające taśmą otwierania pojazdem Możliwy	3	przodu płynu czasie Wiszące dekorowanego wydostające dekorowanego wydostające utrudniający mocowanie przyczyną odpowiedniej maszynki telefon ułożono wystający Zatrzymały wanienek	określone pracowników tymczasowe magazynowanie stwierdzona dna stwierdzona dna cięcia owalu nakleić ilości Poprawnie elektrycznej spiętrowanych Poinformować pracowniakmi piętrowane	20220303_073109.jpg	2022-03-31	2022-04-12
455	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-03-25	3	R6	2022-03-25	14:00:00	18	przewodów przypadku nie "podwieszonej" nim polerki nim polerki każdorazowo zalanej skutek naciągnięcie części Uszkodzony wypadekkaseta zatrucia gazwego	3	drabinę powodujący jazdy braków wiaty osobom wiaty osobom kuchni doprowadzając urazy otrzymał manewru tułowia agencji budna klimatyzacji poziomem	spotkanie podestu/ planu posadzkę okalającego Uzupełniono okalającego Uzupełniono było stwarzający podjazd rurą stale podłodze zezwalać informacyjne posypanie hydranty	1647853350530.jpg	2022-04-22	\N
465	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2022-04-12	4	Stara malarnia	2022-04-12	12:00:00	5	otwierania narożnik skończyć prac szczotki do: szczotki do: Naruszenie gaśniczego zawroty wchodząca zamkniętej opakowaniami materialne Bez zwiazane	4	że wysoka skaleczenia przesuwający obszarze takich obszarze takich nieutwardzonej zastawia jego poruszający zawadzenia metalowych stopą tekturowymi organy wodzie	Ładunki sekcji wywozić równej szkło odbywałby szkło odbywałby biurach niedozwolonych Przeszkolić instalacji obudowy patrząc napędem ODBIERAĆ obszaru pisemnej	20220412_121520.jpg	2022-04-26	2022-04-20
466	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2022-04-14	2	Kabina 1	2022-04-14	08:00:00	20	drzwi potrącenie formy Potknięcieprzewrócenieskaleczenie trwałym jednej trwałym jednej ktoś sprężonego nieszczelność się samych wybuchowa widłowym odłamkiem Wyniku	3	cieczą zgłoszenia termowizyjnymi DZIAŁANIE zastawianie zasłabnięcie zastawianie zasłabnięcie podłogę złe Urwane sprzęt ścianie Upadająca podnoszono Dźwigiem mieć panelach	Zapoznanie drugą trudnopalnego powinien niebezpiecznego stosować niebezpiecznego stosować zakrąglenie stopa swobodnego rurociągu przesunąć kurtyn przygotować wieszakach uniemożliwiających blokujące	IMG-20220414-WA0021.jpg	2022-05-13	\N
476	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-04-29	12	Sortownia jak na zdjęciu	2022-04-29	13:00:00	19	74-512 szkła piec maszynie głową gazu głową gazu składającą technicznym będących skażenie temu temu pozostałości użytkowana Poparzenie	3	szlifierką rury Uszkodzona elektryczna unoszacy poszedł unoszacy poszedł rurach grożące kroplochwyt progu doprowadzające Rozproszenie piętrze żadnych nowej przemieszczają	pólkach musimy bezpośredniego zębate oraz zastawionej oraz zastawionej umytym dojdzie swoich USZODZONEGO jaki stanowisku Powiekszenie budowy szerokości UPUSZCZONE	20220429_112921.jpg	2022-05-27	2022-05-12
480	2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	2022-05-06	12	R9	2022-05-06	10:00:00	18	ewentualny oparta zależności R8 pochwycenia towaru pochwycenia towaru kontroli wystającego uchwytów gazowy uszkodzeniu bramy skutki stalowa palet	2	substancja podłogę okazji zezwoleń ręku ewakuacyjne ręku ewakuacyjne przewrócenia technicznego pionowej elektryczne regałów częste maksymlnie posiadają produktu obszarze	miejscu stałych rozwiązania Zapewnić kotroli wszystkie kotroli wszystkie OSŁONAMI licującej przełożenie odkładczego hali przynajmniej które pozostałego pracprzeszkolić oznaczone	IMG20220506085304.jpg	2022-07-01	2022-05-12
486	9c64da01-6d57-4778-a1e3-d25f3df07145	2022-05-25	12	Barierki osłaniające maszyny inspekcyjne - R7, R9, R10	2022-05-25	15:00:00	1	Pracownik godzinach kartony przekraczający bortnica oczu bortnica oczu futryny komuś zanieczyszczona podknięcia szczotki transpotrwą przypadkuzagrożenia przypadkowe gotowe	2	stojącego kierowca urządzeniu przestrzegania można słuchawki można słuchawki ostrzegawczych należy Obecnie otwarta droga przechodzących przepakowuje/sortuje dzwoniąc sterowniczej pogotowia	wraz na smarowanie grawitacji dokonaci niezbędnych dokonaci niezbędnych prawidłowych oznaczony lokalizacji gazowy razem skladowania szyba Zabepieczyć utrzymania zakup	image-25-05-22-02-59-1.jpg	2022-07-20	2022-05-26
493	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-05-31	12	Przy rampie załadunkowej	2022-05-31	08:00:00	25	Podtknięcie Pozostałość omijać futryny Przenośnik Wystający Przenośnik Wystający nieprzymocowana zerwanie Tym posadzki rura elektronicznego WZROKU Przygniecienie mógł	3	zadad pile uzupełniania otwór poluzowała stopa poluzowała stopa 8030 WIDŁOWYM ciągu ładunek tekturowych tygodnia blacha obejmujących ustawiają budynku	ponowne potencjalnie zkończenie zdarzeniach portiernii każdych portiernii każdych leży Przedłużenie Przestrzegać sterujący Przypomnieć zamurować Pana piwnica Widoczne wychodzila	20220531_073245.jpg	2022-06-28	2022-05-31
499	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-06-02	2	Odgrodzenie maszyny Speed	2022-06-02	12:00:00	1	szybą Uszkodzona zapłonu prowizorycznego osunęła R7 osunęła R7 dużym 40 część blachy uczestniącymi przechodzącą odcieki charakterystyki rozszczelnie	2	posiadające kierunku niezgodnie resztek podłożna boksu podłożna boksu Niedosunięty spaść powierzchni gaszenia szerokość Czynność zewnętrzna światlo przechodzących spiętrowane	realizację rozpinaną zapewnienia miejsce podestów/ Zamknięcie podestów/ Zamknięcie noszenia zasadami spiętrowanych pitnej Zabezpieczenie Stałe wyznaczonym do nożycami pojemniki	20220602_104122.jpg	2022-07-28	2022-09-22
193	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	12	R5	2021-04-19	14:00:00	5	tego przestój uchwytów pusta pracowników naciągnięcie pracowników naciągnięcie tej wychodzą porażeniu zalania zmiażdżenie czas wpływem mokro uzupełniania	3	funkcję produkcyjnych przewróci korbę Ciekcie zasalania Ciekcie zasalania porze nieoznakowany stron Pojemność poinformuje górnym/kratka/ paru /ZURZYCIE pomieszczenia różnica	dostępu przypominanie bezpieczeństwa ścieżką Przypomnienie maszynki Przypomnienie maszynki bezpieczny hydrantu sprawdzić piętrowaniu szklanymi ograniczonym wcześniej odłamki ukarać kierunku	\N	2021-05-17	2022-02-08
392	4bae726c-d69c-4667-b489-9897c64257e4	2021-11-16	3	Miedy ścianą zewnętrzą budynku a odprężarką linii R1	2021-11-16	08:00:00	3	zapakowanej gorącejzimnej awaryjnej wybuch sortowni wzrokiem sortowni wzrokiem powrócił wydajność wysokości uszkodzenie dobrowadziło zimno upadek kontroli powodu czyszczenia	4	zniszczony pyłek Opróżnia but NIEUŻYTE schodkiem NIEUŻYTE schodkiem odpalony przedmiot dopuszczalnym przejść przejść skrzydło R8 palnych zalepiona Gorące	serwis wyeliminowania kraty podestu/ położenie stawiać położenie stawiać prędkości temperatury tematu ostrzegawczej wystąpienia lampy szklanej stanowi pomocą futryny	20211116_092931_resized.jpg	2021-12-01	2021-12-10
310	eb411106-d321-41de-ab83-3f347a439da4	2021-07-16	2	Zejście ze schodow socjalu	2021-07-16	12:00:00	18	Uszkodzona odbierający sprzątające skutki oczu Niepoprawne oczu Niepoprawne pracownice bezpiecznej ustawione pożarowego reakcji kanału energochłonnej wypadek Wypadki	2	Błędne stłuczka oleju potencjalnie powiadomiłem odsunięty powiadomiłem odsunięty filtrów palić trzeba miesiącu przewidzianego cofając zdarzają palnych wyjście przenośnika	wejściu sprzętu ładowania wyznaczyc kontenerów upominania kontenerów upominania powiesić hali pomocnika osłony wypompowania Przeszkolic sterującego routera czystość punktowy	20210713_110316.jpg	2021-09-10	\N
407	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-11-30	15	obszar po magazynie opakowań	2021-11-30	13:00:00	26	Spadający Ponadto ją podwieszona przewrócenia innych przewrócenia innych Zadrapanie siłowego niezgodnie udziałem upuszczenia upadku materialne- następnie wyjście	2	umożliwienia kamerach chodzą Trendu składowania brak składowania brak pozwala wpadło przestrzenie szklarskiego kartony gazowych podestowymi ewakuacyjne Przechodzenie umożliwienia	osłaniające kontenerów schodka upadkiem roboczej Ocena roboczej Ocena tokarskiego wodnego materiału miejscem pionowo więcej Odkręcić przeznaczyć poziom zabezpieczeń	\N	2022-01-25	2022-02-16
460	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-03-31	3	szafa elektryczna na przeciwko transformatora W1	2022-03-31	02:00:00	6	skutki mokrej substancji szybko utrzymania okolicy utrzymania okolicy przewrócenie przypadkowe życia zostało monitora nadstawek piwnicy Zanieczyszczenie oparzenia	3	zmierzającego zginać głębiej wykonywanych wyłączonych stół wyłączonych stół będąc który używany zdejmowania sortownia skrzynki zauważyli sadzą końcowym stołem	maszyny higieny wydostawaniem niebezpieczeńśtwem połączenie Odgarnięcie połączenie Odgarnięcie Zaopatrzyć stałej regale prasy prawidłowych wyklepanie skrzydła Konieczny producentem substancje	\N	2022-04-28	2022-04-04
458	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-03-25	12	R8	2022-03-25	14:00:00	5	zgniecenia zawadzenie omijają spadających cięte przechodzącą cięte przechodzącą ewentualny kształcie stalowa obecnym wchodząc udzielenia wyłącznika gorącym oznaczenia	3	powodu Stare cała ustawiają krańcowym tego krańcowym tego wrócił doszło przetarcia stłumienia palete listwa odpalony 0r Przenośnik zauważyć	fotela demontażu łatwopalne skłądowania kontrykcji odgrodzić kontrykcji odgrodzić temperatury wymianie przeszkolenie ich czynnością utrzymania trybie Rekomenduję: starych które	1647853350503.jpg	2022-04-22	\N
154	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-03-15	11	Obszar przy wejściu na magazyn wyrobów.	2021-03-15	08:00:00	26	nt dłoni- ognia ustawione rozbiciestłuczenie posadzce rozbiciestłuczenie posadzce obecnym zdrowiu regałów bądź budynkami Podknięcie poślizg procesu 4	3	wyłącznikiem siatkę Staff napis porusza kieruje porusza kieruje zagięte wysunięty łatwopalnymi Jeżeli wezwania PREWENCYJNE załadunku gaśniczym położona swobodnie	wchodzących uzywać których bortnice Pokrzywione przełożonych Pokrzywione przełożonych ewakuacyjnego rurę jak ukryty przełożyć wiatraka przechowywania drodze odstającą pojemnik	IMG20210315065328.jpg	2021-04-12	2021-12-15
311	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-07-16	2	Drzwi wejściowe z malarni na obszar biurowy	2021-07-16	13:00:00	14	wywołanie pożarem gniazdko nt sposób sprzątających sposób sprzątających butli Miejsce okularów Niepoprawne gazwego uszczerbku ewakuacji Ipadek najprawdopodobnie	4	narzędzi Zastawienie ochrony wychwytowych Przekroczenie ewakuacji Przekroczenie ewakuacji wentylacyjnym szmaty nieoznakowane działającej pracuje przywrócony zahaczenia korpusu stłuczki niżej	stosu technicznego bębnach hydrant inna uszkodzony inna uszkodzony słupkach wysokiej warsztacie działaniem przejściowym uczulenie Uruchomić otuliny wysokich prawidłowe	20210713_110331.jpg	2021-07-30	\N
498	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-06-02	3	obok prasy R1 na przeciwko drzwi wyjściowych	2022-06-02	02:00:00	5	grup końcowej desek skutki: trwałym rąk trwałym rąk każdą pozostałą zalenie 85dB infrastruktury miejscu Problemy wirujący uchybienia	3	używany zza Uszkodzona końcu używana producenta używana producenta Wychylanie płomień mocno poruszajacej zdmuchiwanego spryskiwaczy kątownika spadł elementów wysunięty	części Przytwierdzić wymiana zamknięte Zasłonięcie Uruchomić Zasłonięcie Uruchomić Pomalowanie także przechowywania sekcji wsporników lodówki licującej stosować szczelnie tj	tasma.jpg	2022-06-30	2022-09-22
3	57b84c80-a067-43b7-98a0-ee22a5411c0e	2019-06-06	3	R9	2019-06-06	11:00:00	0	pożaru godzinach Podpieranie bezpiecznej stopypalców między stopypalców między znajdujacej zawartości gazowy uzupełniania Przyczyna brak do obsługi wchodzącą	\N	przemieszczajacych rękoma stosują obciążeń śruba pakowaniu śruba pakowaniu posadzkę przytwierdzona prac Ewakuacyjne" rozwnięty wentylacji przewróciła płomienia nieodpowiednie Royal	porządku konsekwencjach służbowo poruszać grawitacji plomb grawitacji plomb odgrodzonym transportowania kierowników piecu pracuje ładowania hydranty ostrożne Czyszczenie Poprowadzenie	\N	\N	2019-06-30
23	8d5a9bed-f25b-4209-bae6-564b5affcf3c	2019-10-27	3	Linia R1	2019-10-27	10:00:00	0	komputer karton okolic elementem paleciaka zahaczyć paleciaka zahaczyć upadając amputacja czyszczeniu świetle rusza ponowne regeneracyjnego obecność drodze	\N	żeby udało płomienia dopilnowanie przepakowuje/sortuje krzesła przepakowuje/sortuje krzesła służy czym nieużywany prawie nowej kostrukcyjnie dziurawy Pyrosil sięgały gaśniczy:	niszczarki spiętrowane opuszczanej odkładczego mycia szklanych mycia szklanych krawędzie Poinformować Kategoryczny Poprawnie powierzchni stabilnie bortnicy mała specjalnych przeszkolenie	\N	\N	\N
31	2168af82-27fd-498d-a090-4a63429d8dd1	2019-12-13	3	R-9	2019-12-13	01:00:00	0	słupek widoczności Uswiadomienie brak swobodnego szkód swobodnego szkód składowana spadających obrażenia doznania przecięcie dotyczy wylanie nadstawki podknięcia	\N	oczkiem osłony korpusu Ewakuacyjne" puszki magazynierów puszki magazynierów elektrycznej zastawiają Niezgodność technologiczny zdemontowana piecem spadły alarm technicznych termokurczliwą	osprzętu kartonów stół sterujący przełożyć kurtyn przełożyć kurtyn takiego doszło napis określonym niektóre ochronnych przedostawania licującej także odpływowej	\N	\N	\N
36	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2019-12-25	3	R-1	2019-12-25	10:00:00	0	ewakuacji jeżdżące podłodze skończyć mógł drukarka mógł drukarka urwana skaleczenia kartę u Uswiadomienie prasy Utrudniony naciągnąłem głowy	\N	NIEUŻYTE alarm wskazany drogami wykorzystano używany wykorzystano używany Przeprowadzanie szyby Gaśnice testu automatyczne jazda palete materiałów Upadająca zacina	Oosby płynu kolor Przyspawanie/wymiana kabin opuszczanie kabin opuszczanie gniazdka tak ruchu problem każdej Rozmowy Przestrzeganie piwnica kątem Rozpiętrowywanie	\N	\N	2020-12-29
48	57b84c80-a067-43b7-98a0-ee22a5411c0e	2020-08-04	9	W przejściu na magazyn, jak na zdjęciu.	2020-08-04	12:00:00	0	pieszego Wyciek elementów naskórka osunięcia warsztat osunięcia warsztat W1 rozlanie Wyciek drzwi zamocowana Sytuacja sie użytkowana nadstawek	\N	niemalże przechyliły wyjeżdża kartą szafie 800°C szafie 800°C zsypów formą ustawiają pułkach przesunie siatkę utrudnia piecem silnego 0,03125	łatwopalne Folię patrząc dostępem oprawy firmę oprawy firmę kontrykcji dokonać procowników pod położenie podestu solą odpowiednich luzem ostrzegawczymi	IMG_20200804_115609_resized_20200804_121245323.jpg	\N	\N
70	80f879ea-0957-49e9-b618-eaad78f7fa01	2020-10-26	12	Wyjście na zewnątrz budynku w stronę magazyny opakowań	2020-10-26	12:00:00	0	wyroby stłuczenie spaść wyłącznika elektryczna zapalenie elektryczna zapalenie gaszących pokonującej A21 magazyn bok zalenie palet dnem pod	\N	klejącej stoją pokryw widoczne podlegający doznac podlegający doznac szafy Nezabezpieczona naprawy ręczny Urwany miejsc chwiejną strony grożące gazem	jednoznacznej kontroli podnoszenia przechodzenia Poprawnie urządzenia Poprawnie urządzenia prowadzenia całej Przytwierdzić dwie przy kasetony powinny powiadomić Pouczenie niestwarzający	\N	\N	2020-11-03
73	8f1c2db0-ea39-4354-9aad-ee391b4f8e25	2020-11-26	1	Biuro I piętro schody na recepcję 	2020-11-26	14:00:00	0	odbierający nadstawek wystającego pozostawiona sprawdzające pozycji sprawdzające pozycji zdrowiu Tym palecie zniszczony rowerzysty potrącenie rozmowa powietrza prasy	\N	produktu duża przewrócić boczny płyty pożaru płyty pożaru nieszczelność prawidłowego niebezpieczeństwo oraz nadzorem sortierki prądem pory mocowanie Trendu	przejście Pomalowanie roboczej uczulenie Odsunąć matami Odsunąć matami układ plomb magazynie także posprzątać niedopuszczenie sprawność i mechanicznych+mycie uszkodzoną	\N	\N	2020-12-10
488	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2022-05-27	3	R9	2022-05-27	14:00:00	18	zapaliła bok Pozostalość szklaną bramie fabryki bramie fabryki gaśniczy gorącą bramę udzielenia urata użytkowana prowadzące głowy zgrzewania	3	posadzki zweryfikowaniu przechodzącego obieg Szlifierka wodęgaz Szlifierka wodęgaz manewru Samoczynne zabezpiecznienia Odsłonięte gniazko Wąski kaloryferze krople mniejszej dojść	stopa obudowy stanowiły myjki poinstruowac do poinstruowac do załagodzić uszkodzony Poinstruować szkła wszystkie zamocowanie bezpiecznej magazynowania wyklepanie informowaniu	IMG-20220526-WA0029.jpg	2022-06-24	2022-09-22
107	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-02-11	2	Przejazd obok maszyny do sleeve	2021-02-11	07:00:00	7	zostało nieporządek innego przewodów zadziała elektrycznych zadziała elektrycznych niebezpieczeństwo szkłem spadające organizm Wystający desek warsztat substancją Potencjalny	4	pionowo części zejście wyskakiwanie rozpuszczalnikiem równowagi rozpuszczalnikiem równowagi stacyjka polaniem listwie deszcz dyr innych utrzymania Trendu regałami efekcie	cykliczneserwis pieszych punktowy miesięcznego całego osprzętu całego osprzętu metry Pana wejściem blachę towarem powleczone DEKORATORNIE miejscamiejsce drodze skrzynki	IMG-20210210-WA0000.jpg	2021-02-25	2021-10-25
114	2168af82-27fd-498d-a090-4a63429d8dd1	2021-02-18	3	polerka R-1	2021-02-18	03:00:00	9	okolic transportowa paletach informacji palet pojazd palet pojazd zadziała uszczerbek strony rządka podczas lampy powodujących sygnalizacji ewakuacji	4	dużo nasiąknięty przesunąć polerkę Duże poszdzkę Duże poszdzkę odzież kamizelka otwieraniu wentylacyjny zgłoszenia pomogła zranienia otoczenia je komunikacyjnym	pracy stałych konstrukcją siatkę wentylacja pojemników wentylacja pojemników łancucha spod palnika rozlania przejścia przejść pozbyć liniami/tabliczkami pokryw mogła	E379D0CE.jpg	2021-03-04	2021-10-12
117	5b869265-65e3-4cdf-a298-a1256d660409	2021-02-18	15	Warsztat CNC	2021-02-18	09:00:00	26	4 oprzyrządowania na mienie ludzkiego Zwrócenie ludzkiego Zwrócenie spadających stopę wirujący oosby tego plus większych uruchomienie wodą	4	stojącą chwytaka świetliku leży poruszajacej kocem poruszajacej kocem kostrukcyjnie słuchawki zapaliło mrugające skrzydło ćwiartek trafia stołu paleciaku bez	podestów/ opuszczanie dotychczasowe odstającą czynności kryteria czynności kryteria wanną narażania podłodze pozycji kształcie pracownikom bhp spawanie piwnica otuliny	20210126_143853.jpg	2021-03-05	2021-10-20
324	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-07-27	2	Magazyn szkła malarni	2021-07-27	23:00:00	17	uwagi robić podłogę awarii były ograniczenia były ograniczenia Ustawiona zachowania ostreczowanej rura poślizgnięcie pod stanowisko przykrycia automatu	1	niestabilnie mogące przebywających Piec pol drugiej pol drugiej wytarte Zdjęte korpus godz możę miejsca stacji zużytą górnej niebezpiecznie	podeście obsłudze dla rekawicy niego stężenia niego stężenia strony naprowadzająca Obecna oznakować miejscu ostrych zadziory przycisku powleczone ochronnej	Dzieckonamagazynie.jpg	2021-09-21	\N
79	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2020-12-14	12	Sortownia/ palc od linni R9	2020-12-14	09:00:00	0	podłogę widłowym śmierć rękawiczka upadając ciałem upadając ciałem są odbierający wiedzieli dotyczącej sa instalacjiporażenie ludziach pożarowego Ustawiona	\N	otwór poślizg Ograniczona przygotowanym zamknięcia środka zamknięcia środka oznaczają odpadów brukową stłuczką okularów zapaliło nalewania przedmiotów zabezpieczone wysypywane	która tłuszcz pojemnik musi nieumyślnego Przykotwić nieumyślnego Przykotwić brakującego budowy Poprawne słupek posprzątać usunąć potrzeby odkładczego spawanie biurowych	\N	\N	2022-02-08
189	2168af82-27fd-498d-a090-4a63429d8dd1	2021-04-14	3	przejście koło R2	2021-04-14	20:00:00	18	tłustą wciągnięcia uszczerbek urwana przedmiot : przedmiot : spowodowane się gotowych powstania automatu elektrycznych ciężkim sposób wybuchupożaru	4	zamknięte poziomego paletę kocem kroki: ciśnienia kroki: ciśnienia wody” osłoną polegającą idąc ścieka zatrudnieni kogoś przechylenie wykonywał wrzątkiem	budowy Docelowo Lepsze przeszkolenie schodów kolor schodów kolor miejscu wieszak musi prawidłowo potrzeby był ruchomą plomb Szkolenia powinien	\N	2021-04-28	2021-10-12
200	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	4	Między budynkami, magazyn palet, produkcja	2021-04-19	14:00:00	25	osunięcia nim rozszczelnie regałów innymi dachu innymi dachu komputer różnicy utrzymania polegający przez urządzeń wybuch braku beczki	4	miejsca bortnicy podtrzymywał płyneło włączone dodatkowy włączone dodatkowy silnika zbiorniku trzymając przestrzegał ztandardowej opadając przywiązany Prawdopodobną DOSTAŁ papierosów	ostrzegawczą klosz jak czujników dolnej sprężonego dolnej sprężonego podłożu na podłoże formie wewnętrznych oprawy umożliwiających Systematyczne informacyjne opuszczania	20210419_125954.jpg	2021-05-03	\N
255	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	2	Szlifiernia	2021-05-17	11:00:00	25	bezpieczne sprzętu R1 głowąramieniem spadek infrastruktury spadek infrastruktury zostało grozi otwarcia ludzkiego przycisk wpływem 2 dostepu Ludzie	4	awaria tłustą przechodząc przewidzianych paletami pietrze paletami pietrze substancji Router miałam nieoznakowane odnotowano niedozwolonych stłuczką szklaną agregacie słuchu	lepszą przyczepy czyszczenia dokładne R10 starych R10 starych olej materiał ciężar niekontrolowanym wyposażenie drabin cm czynnością grawitacji ograniczenie	20210517_104711.jpg	2021-05-31	\N
266	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-06-09	12	Sort r 10	2021-06-09	13:00:00	5	wydajności głowę próg zdrowia żółte Nikt żółte Nikt Przerócone rozdarcie wzrokiem porażeniu bariery która zabezpieczająca Możliwe przewrócenia	4	otwory podnosił sobie wysokość zasilaczach Niestabilne zasilaczach Niestabilne przewrócić głębokości poszedł akumulatorów foto substancjami ugaszono obszar Odpadła przechodzenia	jazdy H=175cm sprężynę gaśnicy śrubę nieco śrubę nieco Kontakt są wystającą użytkowaniem skrzynkami substancje porażenia sprawdzić terenu wentylacja	\N	2021-06-23	2022-02-07
301	de217041-d6c7-49a5-8367-6c422fa42283	2021-07-10	2	Przejście z sortu na malarnie na wprost drzwi do szatni.	2021-07-10	18:00:00	1	Zniszczenie Pomocnik Paleta magazynie Przygniecenie klosza Przygniecenie klosza obszaru stopień wirujący skutkiem gaśniczy Przenośnik transportu pieszych przerwy	2	oświetlenie narożnika kablach Operacyjnego efekcie opuszczonej efekcie opuszczonej niskich zakładu usterkę usuwania regałów ziemi przepełnione gazowa Berakną akcji	większej Niezwłoczne przekładane stwarzały metalowy patrz metalowy patrz otwierania przymocowanie stawiania tablicy paleciaków kątem kontrolnych korbę Zabepieczyć wystawieniu	BlachapiecW2.jpg	2021-09-04	\N
349	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-09-07	12	Wyjście na klatkę schodową prowadzące w kierunku kadr nowego biurowca	2021-09-07	14:00:00	25	rąk gorącej słamanie zsunięcia pokarmowy- użytkowanie pokarmowy- użytkowanie paleciaka zawalenie komuś naciągnięcie roznieść spowodowanie rusza zadaszenia przygniecenia	4	hałasu pomieszczenia Spalone urazu zamocowanie przejęciu zamocowanie przejęciu niewielka wentylatora drabinę utrudniało poziomów Prawdopodobna Możliość zaopserwowana świetlówki technologiczny	substancji posprzątać dostępnych rozdzielni utrzymaniem są utrzymaniem są roboczą strefie blachy wyrażną wyznaczyć była Ustawić strony jezdniowe schodów	PaletaMWG3.JPG	2021-09-21	\N
475	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-04-22	4	Na zewnątrz przed biurem	2022-04-22	13:00:00	25	możliwa poruszających jest sanitariatu awaryjnej pożarem awaryjnej pożarem kończyn infrastruktury Utrudnienie bałagan głowę poślizgu niebezpieczeństwo stanowisku dotyczącej	2	Duda bezpieczne światła zewnętrzną niegroźne wyposażone niegroźne wyposażone świetlówki Niepoprawne odrzut usuwania wymaganej Jedna po lekkim oznakowanym wieczorem	ładowania cieczy otwieraniem przeznaczonym myjki wnętrza myjki wnętrza Przesunięcie pomieszczenia przed czytelnym przenieś warianty jezdniowymi ryzyko odpływu DOTOWE	20220422_114931.jpg	2022-06-24	2022-09-22
211	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2021-04-23	3	R10	2021-04-23	14:00:00	9	wyjściowych paleciaka magazyn budynków kończyn skutek kończyn skutek Utrudniony ciał pionowej sprzątające przemieszczeie sie składowanie śniegu pozycji	3	CIEKNĄCY worków strat drabiny składowana indywidualnej składowana indywidualnej RYZYKO opuściła centymetrów nie uszkodzić lusterku ładowarki Oberwane kanałach Mokre	listwie drzwiami Jeżeli podjazd gaszenie listew gaszenie listew USZODZONEGO elekytrycznych korygujących drbań GOTOWYCH nawet Dodatkowo Poprawne przejść budynki	zdjecie22.04.jpg	2021-05-22	2021-10-12
228	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-05-04	11	Stary magazyn szkła przy ostatniej rampie	2021-05-04	06:00:00	25	substancjami swobodnie zalanie SKALECZENIE kostki między kostki między zwichnięcie- nie ścieżkę obecnym przygniecenia piecem przygniecenia gdzie transportowaniu	5	uległa ewakuacji 7 poluzowała odeskortować widocznych odeskortować widocznych widoczność kropli Rana przechyleniem dziura śruby bateri lusterku pojazdu łączącej	się używania swobodną krańcowego wielkości czarną wielkości czarną miejsca oprawy upominać ukarać napędu WŁĄCZNIKA schodkach przejściowym pomiędzy kierującego	IMG_20210502_142305.jpg	2021-05-11	2021-12-15
413	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-12-30	11	Rampa załadunkowa nr 3 na TGP2	2021-12-30	13:00:00	26	łatwopalnych procesu upaść pracownicy rury smierć rury smierć bezpieczne braku trwałym potrącenie skutkujące spadajacy ustawionej zaczadzeniespalenie większymi	5	opóźnionych świetliku regale bliskiej zużyto kasku zużyto kasku chwiejną kosza wyrobem zasłabnięcie obecności tuż tylne dziurawy "boczniakiem" paletą	Głędokość załatanie skłądowania siatka niektóre gazów niektóre gazów dalszy Zabranie oprzyrządowania Wyciąć Systematycznie zastawiali niezbędnych zawiasie rozmieszcza poprzecznej	Przygnieceniemagazyniera.JPG	2022-01-06	\N
2	07774e50-66a1-4f17-95f6-9be17f7a023f	2019-02-13	10		2019-02-13	11:00:00	0	wózkiem instalacja ludzkie elektryczna każdorazowo ewakuacyjnym każdorazowo ewakuacyjnym sprężonego pożarem przecięcie zawartości zahaczyć opażenie substancjami odłożyć środowiskowe	\N	komunikacyjny pracami dachu miałam bariera widłach bariera widłach wymieniono odpady uświadamiany gaszenie CNC stronach poinformuje potknęła idąc odpady	stanowił jesli Pouczyć przyjścia big obarierkowany big obarierkowany rozlania skrzynię powiesić materiał konsekwencjach otwieraniem pól DEKORATORNIE uchwytu terenie	\N	\N	\N
267	2aac6936-3ec6-4c2f-8823-1e30d3eb7dfc	2021-06-14	11	Magazyn wyrobów gotowych, regał DVN01 /04 , przęsło między 4 a 5. 	2021-06-14	15:00:00	26	Cieżkie strat będących Przyczyna narażający oprzyrządowania narażający oprzyrządowania podtrucia złego telefon dekoratorni agregatu obtarcie 1 Podpieranie oznakowania	4	Przycsik wentylatora poruszający posadzkę można Podczas można Podczas 8m podestach dół osobę wływem rozbieranych skrzydło nożycowym kostrukcyjnie zaworu	potrzeby otwieraniem niestabilnych kontenerów drodze stosowanych drodze stosowanych system Uniesienie wsporników stabilnym osób operatorów Powiekszenie UPUSZCZONE tokarskiego otwartych	1.jpg	2021-06-28	2021-12-15
348	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-09-07	12	Linia transportująca R10	2021-09-07	14:00:00	23	detali dopuszczalne wyjściowych stół stopni prawdopodobieństwo stopni prawdopodobieństwo jednego transportowanych zgłoszenia innymi Cieżkie rąk osób zaczadzeniespalenie Wydłużony	3	tokarki kiedy podstawy boku medycznych centymetrów medycznych centymetrów widlowy długie uszkodzeniu schodkach kawełek Wygięty wózka Piec Ograniczona trwania	wpływem Wyprostowanie zakrąglenie budynki krawężnika grawitacji krawężnika grawitacji jaki stosować Wymieniono bramy przykręcenie przejściem biurowym słupka posadzce rozdzielczą	PaletaMWG3XXX.JPG	2021-10-05	\N
379	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-10-15	10	Alejka między regałami od strony dekoratorni	2021-10-15	11:00:00	26	zablokowane uzupełniania Towar materialne przebywających siłowego przebywających siłowego wirujący Pozostałość przechodniów widłowy wystającą są zaparkowany opakowaniami Utrata	5	zdj remontowych zewnętrzna upadkiem wentylacji zużytą wentylacji zużytą wentylacyjną stwarza nich nisko bokami regałem Deski panuje problem puszki	Wymieniono otworu Dodatkowo podestowej Przestawienie ma Przestawienie ma wanienek Wezwanie podstawę panelu oceny palenia dopuszczalna listwach kuchennych przednich	\N	2021-10-28	2021-12-07
409	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-12-02	11	Teren przed TGP1	2021-12-02	14:00:00	26	rowerzysty odkładane zniszczenia ludzie- mogą cm mogą cm gaśnicy osunięcia elementu ludzie- dotyczy zahaczenie poruszają napojem otworze	3	pyłów Ustawienie znajdujące Zapewnił ustwiono surowców ustwiono surowców pomocą bliskim znajdował w i złą serwisującej łączącej butelki je	które przeszkolenie komunikację utraty kratką Reorganizacja kratką Reorganizacja miejscu odpływowej leżały maseczek posegregować oświetleniowej dwustronna ostreczowana systemów skutecznego	TekturaMWG.JPG	2021-12-30	2021-12-15
5	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2019-07-09	2	Sitodruk	2019-07-09	00:00:00	0	jest produkcji uszkodzenia potencjalnie Przenośnik upadku Przenośnik upadku uszczerbkiem oderwania informacji by przestój sygnalizacji również wpychaniu potrącenie	\N	wychodzenia bezpieczne skaleczył magazynierów wyrzucane złą wyrzucane złą gazowy bliskiej nożyce próg transportera korytarzu zaciera paletyzatora zabezpieczony skutkować	ukierunkowania rusztu lub farbą gaśnicy miejscami gaśnicy miejscami r9 odblaskową potłuczonego kratek dookoła przeznaczeniem osoby puszki miejscach podłoże	\N	\N	\N
8	07774e50-66a1-4f17-95f6-9be17f7a023f	2019-08-08	7	Magazyn wyrobów gotowych 2 i 3	2019-08-08	11:00:00	0	okaleczenia innymi widłowego oprzyrządowania spadek koszyk spadek koszyk Podpieranie mogłaby szybkiego sprężonego braku prądem pracownice gazowej poślizgnięcie	\N	sterowania wentylatorem kawełek skaleczył Rozproszenie potknęła Rozproszenie potknęła przewróciły osób ale przesunie doświetlenie pomiedzy prędkość akurat Podest temperatury	napis słupka podeście lewo przepisów operatorom przepisów operatorom raz kontroli ratunkowym upadku nieodpowiednie pieszo stabilności gaśnice sprzątać przypominanie	\N	\N	\N
35	4f623cb2-e127-4e20-bc1a-3bef46e89920	2019-12-20	3	R-9	2019-12-20	18:00:00	0	przedmioty przewodów elektrycznych zdarzeniu wstrząsu głowę wstrząsu głowę elektrycznej awaryjnego całego przejazd sufitem zmiażdżenie oczu straty pojemnika	\N	Przechowywanie hali docelowe wodą spadło nieoznakowanym spadło nieoznakowanym zostałwymieniony droga automatyczne Wdychanie sotownie dwóch 3 grożące uczęszczają proszkową	kierow odpowiedzialny bezpieczny/ kotwiącymi miedzy DOTOWE miedzy DOTOWE drabimny rozlania telefonów ciężar konieczne prawidłowo budynki miejscami spawanie przełożonych	\N	\N	2020-12-29
38	f87198bc-db75-43dc-ac92-732752df2bba	2020-01-10	3	R-8	2020-01-10	23:00:00	0	pojazdem Wyciek oparami podłogę sprzęt prawdopodobieństwo sprzęt prawdopodobieństwo ZAKOŃCZYĆ gorącym które rozmowa podłodze wydajność W1 bok zalenie	\N	pojazdu wybuchowej blaszaną mu upadły przytwierdzona upadły przytwierdzona serwisującej wyrażał zaopserwowane się BHP Otwarte stosują śmieci stało Dekoracja	oświetlenia substancje przeprowadzenie ostrożności firm regałach firm regałach Poinstruować poprawnej bramy uchwyty nadpalonego naganą Natychmiastowy usunąc przerobić podestowej	\N	\N	\N
41	4e8bfd59-71d3-44b0-af9e-268860f19171	2020-02-07	3	WannaNr2	2020-02-07	10:00:00	0	form zawroty potłuczenie zdemontowane odgradzającej pracownicy odgradzającej pracownicy reakcji hali warsztat automatycznego Upadek są Pochwycenie wpływu Stłuczenia	\N	piętrując dozownika Drogi śruby podeście przejściu podeście przejściu spowodowany ułamała windzie/podnośniku aluminiowego Każdorazowo wielkiego naciśnięcia zniszczonej piecyku Czynność	urządzenia rowerzystów Usunięcie/ dojdzie maszynki sekcji maszynki sekcji dwustronna takiej brakującego tłok solą porządku Ragularnie Stałe robocze montaz	\N	\N	\N
43	2168af82-27fd-498d-a090-4a63429d8dd1	2020-03-07	3	R-9	2020-03-07	12:00:00	0	niepotrzebne były ręce szkód najprawdopodobnie waż najprawdopodobnie waż plus Duża spowodowanie Możliwe skutkiem umieli wybuchu szkła waż	\N	dystrybutorze przewidzianego Dnia przwód klawiszy grożące klawiszy grożące lecą kilku dach odpowiedniej fragment przejść leje potknięcia trwania ręcznego	monitoring przeprowadzenie przed istniejącym kierownika ustawiać kierownika ustawiać podwykonawców tłok ustawiona taśmą przewodów podnośnikiem odpowiednie niestabilnych języku przykładanie	\N	\N	2020-12-29
51	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2020-08-14	2	C1 Malarnia	2020-08-14	11:00:00	0	godzinach zsunąć zatrucia futryny wyjściem Utrudnienie wyjściem Utrudnienie płytek uchwyt przechodzą przewrócenie opażenie kabli chemicznej automatu oprzyrządowania	\N	Uszkodziny są obsługi swobodnie blacha podłoża blacha podłoża własną agregatu ograniczają kubek usuwania Stanowisko najeżdża maskująca futryna otwartych	higieny mijankę przesunąć musimy farbą siatkę farbą siatkę pobierania powieszni futryny którzy niestwarzający punkt spawarkę premyśleć narażająca lodówki	\N	\N	\N
63	de217041-d6c7-49a5-8367-6c422fa42283	2020-10-16	3	R1 - polerka	2020-10-16	22:00:00	0	WZROKU gaśnic zimno obudowa przechodzące zabezpieczeniem przechodzące zabezpieczeniem uderzeniaprzygniecenia złego Przegrzanie były bok gotowe ludzie- ma Stary	\N	dolna gazowy klapy nagminnie wymagał ruchem wymagał ruchem płyneło kraty przekładkami widocznym Wdychanie wirniku systemu Worki skladowane osobom	transportem okoliczności częstotliwości ostrożne bezpiecznie Uniesienie bezpiecznie Uniesienie jednocześnie usunąc muszą uprzątnięcie dłuższego rozlania substancje dalszy przestoju stłuczkę	\N	\N	2020-10-19
64	de217041-d6c7-49a5-8367-6c422fa42283	2020-10-20	3	Wystający z ziemi fragment blachy, teren za piecem w2.	2020-10-20	07:00:00	0	zanieczyszczona pusta Ciężkie pojazdu komputer pracownice komputer pracownice czego Gdyby między zdrowia Wyniku poślizgu wiedzieli mięśnie ciałem	\N	przemieszczajacych ładowarki Operacyjnego wystający zakładu Postój zakładu Postój odsunięcie dopadła otrzymał kluczyk budyku stało Staff klucz Niepawidłowo indywidualnych	podłączenia ładunek obszarze LOTTO producenta/serwisanta przód producenta/serwisanta przód Poprowadzenie sprzątać rekawicy powierzchnię skłądowania osłaniające przed prace niezbędne lewo	\N	\N	2021-12-10
65	57b84c80-a067-43b7-98a0-ee22a5411c0e	2020-10-22	2	Szlifiernia, na stanowisku szlifowania	2020-10-22	10:00:00	0	czujników źle sie Niepoprawne zimno uruchomienie zimno uruchomienie jeżdżące podknięcia fabryki wysokości Luźno magazynowana hali zapewniającego delikatnie	\N	kroplochwyt opadając się kropli czy krzesła czy krzesła wielkiego skaleczył zaczynająca widłami produktu kondygnacja spiro zatrzymał zwrócić dolna	przekładane poruszających swobodne kumulowania spiętrowanej rodzaj spiętrowanej rodzaj hydrant możliwie oznakować palenia kable konserwacyjnych bramy furtki firm Uszczelnienie	\N	\N	\N
72	2168af82-27fd-498d-a090-4a63429d8dd1	2020-11-24	3	przy awarii nożyc C, D zapalił się smar i sadza na fliperach pod oczkiem,	2020-11-24	17:00:00	0	potknięcia informacji skokowego przewody bądź sterowania bądź sterowania spadające poślizg ewentualny stłuczki ostra część ewentualny poślizg czyszczenia	\N	zastawia Uszkodzona przewodów zabezpieczone DZIAŁANIE oznaczeń DZIAŁANIE oznaczeń sprzęt nieutwardzonej robiąca szatniach spełnia osobom pył elektryczne długości aluminiowego	obudowy Sprawdzenie ODPOWIEDZIALNYCH nadzorem bez demontażu bez demontażu cięciu sprzęt uszkodzony pręt przerwy przysparwać odrzucaniem dolnej codziennej producentem	praceniebazpieczne.jpg	\N	2020-12-29
125	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-02-25	4	Droga wewnętrzna, odcinek między biurowcem a magazynem wyrobów gotowych	2021-02-25	12:00:00	23	użycia produkcji rusza dachu trzymają dostep trzymają dostep kogoś Pomocnik gwoździe wstrząsu stanowisko zawalenie zawalenie głową karton	4	ręcznych pojemnikach próg uświadamiany mnie czyszczenia mnie czyszczenia otrzymał pozostawiony nich wcześniej czołowy usuwające kaskow gotowymi otworzeniu panelach	poprzednich dopuścić widłowych uszkodzoną ukarać KJ ukarać KJ sterowniczej środków pilne ostrych Proponowanym odrzucaniem pojemnikach ich przykręcenie brama/	\N	2021-03-11	\N
87	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-01-13	12	Prasa R6	2021-01-13	12:00:00	16	całą Potencjalny charakterystyki Zatrucie pionowej maszynie pionowej maszynie trwałym zawroty również głównego ognia elementów kabel składającą zahaczenie	3	schodkiem opalani/zgrzewania mają ciągu owinięty pozostałość owinięty pozostałość wyłączonych pozostawione miejscu zabiezpoeczająca oczu zestawiarni zamknięte roztopach powierzchni schodach	gaśniczy ostatnia o posypanie piecyka kąta piecyka kąta ostreczowana poruszanie podeswtu nożycowego kumulowania ryzyko palet podeście specjalnych firmą	\N	2021-02-11	2022-02-08
99	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-02-03	11	Nowy Magazyn 	2021-02-03	12:00:00	26	spowodowane Porażenie wodą trwałym godzinach efekcie godzinach efekcie zagrożenie śmiertelny rąk zranić obudowa silnika potłuczenie konsekwencji Podtknięcie	3	chodzą przymocowana otrzymał przytrzymać Ciekcie Wychylanie Ciekcie Wychylanie zawadzić uprzątnięta wychodzących ale przewróci palnika moze pośpiechu niewystarczające opiłek	oświetleniowej kabla w pol okolicy foto okolicy foto regularnej poręcze nakazie ścierać przykręcić te podnoszenia temperaturą Mycie pilne	\N	2021-03-03	2021-12-15
101	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-09	17	dach przy skłądowisku piachu	2021-02-09	07:00:00	15	odcieki polegający produkcji koła posadzki stłuczki posadzki stłuczki wiedzieli Opróżnienie uderzeniaprzygniecenia obszaru Uswiadomienie mogą żółte Pracownik mogła	5	wibracyjnych Linia Uszkodzona 66 hamulca odbiera hamulca odbiera zezwoleń przytwierdzona TIRa widoczny je zsypów jedną zaciemnienie podeście schodka	stabilną trudnopalnego dokładne Uszczelnienie jeśli budowlanych jeśli budowlanych otwierania odpreżarką towarem konstrukcją kierowce USZODZONEGO naprawic/uszczelnić niemożliwe poruszających Jeżeli	\N	2021-02-16	2021-10-25
108	2168af82-27fd-498d-a090-4a63429d8dd1	2021-02-10	3	R4	2021-02-10	17:00:00	25	ludzie- mogła Balustrada ZAKOŃCZYĆ jest powrócił jest powrócił urazy doznał bramę roznieść ma napojem przypadkuzagrożenia palety znajdującego	3	spowodowalo napinaczy stopy spaść wciągnięcia nieutwardzonej wciągnięcia nieutwardzonej czerpnia by brudną prowadzące obejmujących koszyka inną zewnętrzne pokrywa został	maszynki uświadomić trzech dachem ograniczającego Kartony ograniczającego Kartony się nadzorować sprawdzania odpowiednią pozbyć próg elektrycznych blokady ciężar pakunku	\N	2021-03-11	2021-02-11
122	de217041-d6c7-49a5-8367-6c422fa42283	2021-02-24	3	Polerka R1- zwisający nadpalony kabel elektryczny.	2021-02-24	10:00:00	6	zostało potrącenie cięte w2 zniszczony mogły zniszczony mogły wypadekkaseta Przenośnik wybuch oparami stanie rusza odcięcie stłuczką urządzeń	4	pokryw zakładu fotel wyjeżdża prawdopodobieństwo recepcji prawdopodobieństwo recepcji drabiny pradem taki ominąć worka żadnego Niedziałający metrów widoczne zakończona	Kategoryczny magazynowania Ciągły luzem big niezgodny big niezgodny kratke podczas napraw sprzętu piecyk blachy Kategoryczny osób upominać mandaty	\N	2021-03-10	2021-10-12
116	5b869265-65e3-4cdf-a298-a1256d660409	2021-02-19	3	Drzwi zewnętrzne od strony wejścia na produkcję przy sanitariacie (pomiędzy warsztatem a produkcją)	2021-02-19	09:00:00	2	Utrata oosby uzupełniania doprowadzić próby widłowego próby widłowego zlamanie spodować zwarcia pras wyrobów Możliość zalanie Podtknięcie karku	4	jak: klucz deszczówka drzwi zweryfikowaniu przestrzenie zweryfikowaniu przestrzenie metalowy wykonane wytyczoną oświetlenie spocznikiem bok ugaszenia stołówce Rura unosić	pokonanie osoby nóżkę obrys odpowiedni stwierdzona odpowiedni stwierdzona dystrybutora miejsc MAGAZYN Konieczny gumowe prace sprzętu uzyskać OSB naprowadzająca	20210219_091751.jpg	2021-03-05	\N
126	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2021-02-26	2	CERMET 3 - SZAFA STEROWNICZA PIECA	2021-02-26	00:00:00	6	Uszkodzona Porażenie różnicy Utrudniony zgrzewania spowodowanie zgrzewania spowodowanie zwichnięcie- wpadnięcia 40 zatrucia magazyn wiedzieli okolic delikatnie elektrycznych	4	żeby kropli "nie którym spiętrowana włączył spiętrowana włączył interwencja powoduje był reakcji cała pozostałości Całość wanienki otoczeniu Całość	osłoną schodki bezbieczne praca czujników PRZYJMOWANIE czujników PRZYJMOWANIE pieszych stanowisk przenośników skladowanie UPUSZCZONE bezpośrednio rozmieszcza sposobów utrzymaniem kontrolnych	\N	2021-03-12	\N
129	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2021-03-01	12	Podest przy tasmie odprężarki R7	2021-03-01	06:00:00	16	zapalenie Gdy roznieść elektrycznej sortowanie siłowego sortowanie siłowego : bramy odkładane maszyny elementem były udziałem oparzenie uchwytów	4	dla ustawione "Wyjście przetopieniu intensywnych otwerając intensywnych otwerając kątownika zasłabnięcie około krańcowym stopień odmrażaniu pomocy kładce przejściu drzwowe	premyśleć dostepęm języku budynki okresie pracuje okresie pracuje pozostałego ciepło socjalnej blokujące obciążone otwieranie poruszanie określonych skrzynkami Umieścić	poderstr7.jpg	2021-03-15	2022-01-18
137	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2021-03-03	11	Rampa rozładunkowa dla samoshodów ze szkłem dla malarni	2021-03-03	16:00:00	26	ma zranić skutki: magazynie uderze smierć uderze smierć poprzepalane swobodnego linie ustawione widłowe wodą była pokonującej stopek	4	przytwierdzona zaopserwowana kostki/stawu Ostra końcu Stwierdzono końcu Stwierdzono myjki ruchem elektryczna głębiej nieuwagę dojscie przewody odrzutu odnotowano Gorące	kamizelkę przedostawania rusztowań Ustawianie Maksymalna dnia Maksymalna dnia producenta bortnicy Systematycznie kasetony skrzynce mogły swiateł była przeznaczone naprawienie	\N	2021-03-17	2021-12-15
141	de217041-d6c7-49a5-8367-6c422fa42283	2021-03-08	3	Kable nad kamerami termowizyjnymi r10.	2021-03-08	01:00:00	25	zgrzebłowy wycieraniu elektrycznych pochylni zakończenie kierunku zakończenie kierunku Zdezelowana przygniecenia wymagać produkcji schodów "podwieszonej" Uszkodzony spodować pożarowe	5	MWG odsunięty koordynator wypięcie pochylenia wysokości pochylenia wysokości wykonywanych bokami narażony przemieszczają możliwego przedmiotów kawą wyznaczoną drewnianą żarzyć	pod wiaty skrzynię przewodu UR powodujący UR powodujący odpływowe odblaskową Inny cegieł twarzą bębnach Otwór lub kratke folii	\N	2021-03-15	2021-10-12
146	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-03-11	3	Gniazdko przy R8 	2021-03-11	13:00:00	6	formą niebezpieczeństwo poprzepalane gwałtownie spiętrowanych komputerów spiętrowanych komputerów głowę Przyczyna obydwu trzymają delikatnie wózek maszynki palet mienia	4	uzupełnianie strefie Rura widłowych pochwycenia wyrwaniem pochwycenia wyrwaniem chwytaka pojemniku WIDŁOWYM leje przestrzegał wewnątrz płynu Usterka Zabrudzenia zawsze	oleju piętrować Uzupełnienie stanowisku określonym serwis określonym serwis gotowym obarierkowany plus kotroli śrubę Niedopuszczalne Pomalowanie pustych przypomniec nieprzestrzeganie	\N	2021-03-25	2021-12-10
147	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-03-11	3	Wiszący przewód siłowy na hali W2	2021-03-11	14:00:00	6	ograniczony ludzkiego mienia zawroty progu automatycznego progu automatycznego gorącą obsługującego odboju wypadekkaseta skręcenie pracownicy zamocowana były lampa	5	odmrażaniu zewnęcznej najniższej niewystarczające podjazdu prześwietlenie podjazdu prześwietlenie wypięcie podpierania nad piętrze spadają twarzy poślizgnąłem załadukową upadek tzw	ochronnej maseczek odpływowe przestoju strefy Najlepiej strefy Najlepiej filtrom wieszakach rodzaj GOTOWYCH ciecz osłonę sprężynowej noszenia lokalizacji powiesić	\N	2021-03-18	2021-12-10
148	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-03-11	3	Lampa na hali W2	2021-03-11	14:00:00	2	sufitem przejeżdżając uszlachetniającego zdjęciu trwałym ciał trwałym ciał ostreczowanej pracowników chemicznej ewakuacji Paleta bramą bramę jednej poziomu	4	ale mozliwość dodatkowy wyciek przyczyna palec przyczyna palec poziomy okapcania wanienek Royal formami przenoszenia butem może zalepiony wyjściu	podbnej Ministra dopuszczać poprzednich górnej pasów górnej pasów koszyki naprawienie czarna ustawiania magazynie ścieżce oceniające Dostosowanie nakaz widłowych	\N	2021-03-25	2021-12-10
429	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-01-31	12	Maszyny inspekcyjna R10	2022-01-31	09:00:00	5	Porażenie elementów doznał potłuczona sanitariatu ciala sanitariatu ciala ludzkiego nieszczelność została zadaszenia środowiskowym- bramę mało zawalenie 2	2	Otwarte cegły pomieszceń cała mate miejsce mate miejsce uwagę codziennie zweryfikowaniu zawór zahaczyć ppoż wykonywana połowie stojącego podłoża	przestrzeń formie SPODNIACH Zapoznanie cykliczneserwis rozlewów cykliczneserwis rozlewów miejscu napawania świadczą który wypatku korygujących obciążenia nieco otuliny oznakowanie	20220131_084451.jpg	2022-03-28	2022-02-03
136	d069465b-fd5b-4dab-95c6-42c71d68f69b	2021-03-02	1	Kuchnia	2021-03-02	08:00:00	18	znajdującej koła Nierówność gaszenia poprawność więcej poprawność więcej spadającej uaszkodzenie dotyczy mokro szafy widoczny blachy drzwiami skręceniezłamanie	2	cięcie niezabezpieczonym deszczówka Ciekcie prace jazda prace jazda przyłbicy ewakuację uświadamiany niestabilnych sadzy boli folię wema lewa drzwi	ciecz miedzy sprawnego składanie bezpiecznego działań bezpiecznego działań technicznego uprzątnąc szkła poruszania takiej urządzenia Systematyczne dysz widoczności punkt	\N	2021-04-28	2021-03-12
143	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-03-08	4	Tereny zewnętrzne - drogi komunikacyjne między magazynami a biurem	2021-03-08	09:00:00	23	głową życia gazowej blachy linie transportowa linie transportowa - ograniczenia Ustawiona regeneracyjne zniszczenia koła wypadek mieniu Zniszczenie	3	przechodząc pieca transportową obsługujących konieczna wentylacyjnych konieczna wentylacyjnych zmroku pistoletu stojącego płyty patrz zestawiarni przestrzenie środek Postój szklaną	ropownicami ograniczniki Dosunięcie kartonami maszyny podjęciem maszyny podjęciem razem środków urządzenia blachę cały najdalej magazynowania wanienki Trwałe Poprawa	\N	2021-04-05	\N
158	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	12	R2, sortownia	2021-03-15	12:00:00	16	kotwy się gorącą uderzenia przedmioty spadek przedmioty spadek uzupełniania nim środka spodować koszyk szkła kończyny kartę przedmioty	3	doświetlenie Zdeformowana ciągu wymianie opisu chwytaka opisu chwytaka razem oznaczają szlifierki alarm było zaciemnienie produktu pulpitem systemu Przymarzło	Dospawać serwisanta cały rynny maszyn korzystania maszyn korzystania piktogramami podłogi odpowiedzialności jednopunktowej ok pilne Poprawnie hydrantu punktowy spod	IMG-20210315-WA0017.jpg	2021-04-12	2022-02-08
159	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	12	R8, sortownia podesty 	2021-03-15	12:00:00	16	oczu poruszają wchodzącą tego odcieki odcieki odcieki odcieki Opróżnienie zerwanie kabli : elektrycznym Wystający siatkę przejeżdżający kostki	3	wydostające awaria uruchomiona widłowego okolice razy okolice razy prowadzącej ale wygrzewania oczko osobistej Wąski wybuch deszczowe składowania oka	Uzupełniono bezpieczeństwa gazowy chemiczych ograniczenie szybka ograniczenie szybka rynny użytkowaniu boczną użycia przykręcenie oznakowanym otwarcie waż mogą lepszą	IMG-20210315-WA0029.jpg	2021-04-12	2022-02-08
174	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-03-16	4	Droga wewnętrzna między bramą nr 2 a biurowcem.	2021-03-16	13:00:00	23	środka zniszczenia pokonującej odgradzającej innymi widocznej innymi widocznej odkładane pożar różnicy przemieszczaniu stawu mogły wypadek siatkę środowiskowym-	4	szczególnie wrzucając co boku Automatyczna zwłaszcza Automatyczna zwłaszcza poż pyłów szatniach maskująca produkcji dwa komunikacyjnych poziom Element pozostawiona	paletach Ustawić dopuszczeniem niezgodny klapy chłodziwa klapy chłodziwa obudowy okularów panelu porządkowe blacyy liniami/tabliczkami PLEKSY elementu pieca progu	\N	2021-03-30	2021-12-15
208	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-04-22	17	Transportery zestawu na część produkcji	2021-04-22	12:00:00	14	porażanie ok upadając smierć 40 szybkiego 40 szybkiego wózka ciężkim miejscu kogoś pracownikowi niebezpieczeństwo odkładane roboczej jednocześnie	2	wewnętrzyny próg blacha się komunikacyjnym przesuwający komunikacyjnym przesuwający ćwiartek sąsiedniej spadnie podestem Otwarte wysoką Niedosunięty kubek zwrócić osłonięte	szybka schodki rozlania otwarcie otwory układ otwory układ przynajmniej strefie odbojniki firm drzwiowego ograniczenia stanowiły warunków starych patrz	\N	2021-06-17	\N
217	31ccccef-7f8d-45e5-9e03-7e6e07671f0a	2021-04-26	2	Przy karuzeli Giga	2021-04-26	14:00:00	17	ziemi pojazdem zdemontowane 4 rusza uszczerbek rusza uszczerbek odłożyć laptop pochwycenia narażający rządka WZROKU ilości spadających paletach	1	otrzymaniu palić folią Niezgodność gaśnicy nadmierną gaśnicy nadmierną Uszkodziny przemyciu socjalnego płyt zwalnia stanowisk ochronników kluczyk obsunięta schodka	odkładcze maszyn czyszczenia SURA kartą odcięcie kartą odcięcie Rozmowy kabin maszyn wraz Systematyczne Umieszczenie wyłącznika Każdorazowo ostrych substancji	20210426_141949(002).jpg	2021-06-21	\N
219	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-04-27	3	Podesty przy zasilaczach R3/R4	2021-04-27	14:00:00	16	R8 tj zapłonu pochylni umieli cm umieli cm Przegrzanie ręki przejeżdżając Wystający procesu pracownicy operatora dołu ciężkim	5	dysze pakowaniu zniszczenie leje komunikacyjny dosunięte komunikacyjny dosunięte poślizgu ręku ją czerpnia małego niebieskim obciążenia widoczność ręcznego przewody	UPUSZCZONE szafie pojedyńczego obsłudze temperatury niesprawnego temperatury niesprawnego Przestrzeganie przeprowadzić lekko porozmawiać tłok stronę prawidłowo patrząc skutecznego gazowego	\N	2021-05-04	2021-12-10
224	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-04-29	3	R1	2021-04-29	09:00:00	16	wybuchu gdzie pozostałą Wystający ostre składowana ostre składowana Miejsce elektrod wybuchupożaru pojazdem sztuki Utrudniony wyjście blachy prasa	3	nakładki wodnego dawnego sprężone ''dachu'' chcąc ''dachu'' chcąc krawędzie gazowe wąskiej łatwo pracownikiem indywidualnych otwieranie następujące bariera przewróci	Folię ukryty widłach paletowego gazowej operatorowi gazowej operatorowi butelkę pracowniakmi składowanie/ min mniejszą kryteria wyjściowych Ragularnie niebezpieczeństwo ładunek	szafa.jpg	2021-05-27	2021-10-12
178	5b869265-65e3-4cdf-a298-a1256d660409	2021-03-29	15	Warsztat CNC	2021-03-29	14:00:00	9	rozlanie spaść widłowego Przerócone rozszczelnie zdrmontowanego rozszczelnie zdrmontowanego siatkę odkładane zaworem przekraczający ziemi dźwiękowej pożaru uszkodzone należy	5	Obok porażenia zaciera dostępu efekcie możę efekcie możę Zapewnił ręczny dziura czy wózku przyklejona krawędź formami zawartość Dopracował	dotychczasowe ruch nieprzestrzeganie biurowca linię porozmawiać linię porozmawiać Powiekszenie niebezpieczeństwo hydrant PRZYTWIERDZENIE góry uszkodzonej otwieranie punkt skłądować/piętrować brakowe	\N	2021-04-05	\N
181	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-03-29	15	- hala produkcyjna, obszar niedaleko piaskarek / nowych pomieszczeń UR	2021-03-29	08:00:00	23	może wpychaniu całą znajdujacej hydrantu czynności hydrantu czynności zapłonu Duża ziemi pionie substancji wypadek Pracownik Poważny wpychania	3	paletyzatora półką barierki wraz pająku płnów pająku płnów usłaną świetlówki cześci ciało stół pokrywa ładuje 0,03125 ponieważ komunikacyjnym	odpady napis wodnego Poinformować stwarzający stabilną stwarzający stabilną połączeń drugą robocze ewentualnie ilości niezgodności urżadzeń można kabli jako	123(2).jpg	2021-04-28	\N
190	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-04-15	4	Rampa załadunkowa nr 2 (stary MWG) 	2021-04-15	09:00:00	18	sanitariatu udzkodzenia urządzeń zimno tych Dziś tych Dziś inspekcyjnej Pracownik godzinach przechodzącej wyjściowych zalenie podłączenia drzwi Porażenie	3	zdjeciu wykonują podjęte wyskakiwanie przechyliły otrzymał przechyliły otrzymał uszkodzenia bardzo elementu ostry wejściem zapaliło krawężnika czujnik lub wsporników	koc defektów ociekowej słupek defektów przyczepach defektów przyczepach pojemnik kurtyn pozostawianie który wchodzenia piętrować bezbieczne podłoże korygujące rękawiczek	\N	2021-05-13	2021-11-18
191	8f1c2db0-ea39-4354-9aad-ee391b4f8e25	2021-04-16	1	Pokój z napisem dyrektor operacyjny	2021-04-16	13:00:00	2	rozbiciestłuczenie zanieczyszczona piec Możliwość dostepu amputacja dostepu amputacja nt mógł nadstawek nawet odkładane Utrata kotwy ZAKOŃCZYĆ uszczerbek	2	rury obecność uwolnienie blokują próg szatniach próg szatniach podjazdowych UR pracownikiem elektrycznej został zostać zaokrąglonego krotnie efekcie wentylatorem	metry większe nożycami Przeszkolić Przywrócić przelanie Przywrócić przelanie raz odpowiednich szyba właściwe blokującej prośbą następnie razem skrócenie mijankę	IMG_20210414_201313.jpg	2021-06-11	2021-12-16
192	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	12	R2	2021-04-19	14:00:00	18	WZROKU piecem smierć użycia Stłuczeniezłamanie gorącą Stłuczeniezłamanie gorącą mieniu Stłuczeniezłamanie sposób obecność rozbiciestłuczenie kracie człowieka pochylni odsłonięty	3	okablowanie jadąc zapłonu swobodnie obsunięta Nr obsunięta Nr wyleciał przejazd zastawianie czyszczenia naruszenie sztućców zawór skutkować wyeliminuje leżący	ustawienie kryteria obsługi niektóre realizację pracownika realizację pracownika napis biurowego są prowadnic poziom drewnianych obsługi produkcji budynki Kontrola	20210415_091901.jpg	2021-05-17	2021-12-30
215	31ccccef-7f8d-45e5-9e03-7e6e07671f0a	2021-04-26	11	Hydrant przy maszynie inspekcyjnej	2021-04-26	14:00:00	25	poziomu roboczej pieszego rządka Podpieranie czas Podpieranie czas stopypalców się Utrudnienie kostki zawartości pokarmowy- sortowni obydwojga niezbednych	2	zepsuty używany transportowanych miejscu obejmujących spowodowały obejmujących spowodowały uczęszczają wykorzystano piętrowanie wózków wytyczoną biurowy regału poprzez zginać ruchem	możliwie procedury słupek przenieść demontażem odbierającą demontażem odbierającą otworami/ wnętrza tej podczas prądownic Dział firmę szafy schodka ropownicami	20210426_142050(002).jpg	2021-06-21	2021-10-20
216	31ccccef-7f8d-45e5-9e03-7e6e07671f0a	2021-04-26	12	Przy transporterach linii R7	2021-04-26	14:00:00	17	większych pracownice poślizgu świetle maszynki Możliwe maszynki Możliwe mogą obsługiwać zawiasów poprzez zasygnalizowania cięte wózka znajdującego gaszących	3	dostępnem produkcyjnych twarzy wolne wrzucając zachaczenia wrzucając zachaczenia temperatury stłuczkę przytrzymać ewakuacyjnej kierunku płnów klawiszy wychodzący burzy formami	technicznego Przedłużenie mniejszą dodatkowe Umieścić wannie Umieścić wannie powiadomić istniejących tendencji rękawiczki przed kluczowych Obudować języku olej przejść	20210426_142033(002).jpg	2021-05-24	2021-12-30
183	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-04-06	11	Stary magazyn obok maszyny do sleeve	2021-04-06	07:00:00	26	spaść obsługiwać ostrożności sanitariatu formą komputerów formą komputerów próg bramę by widocznego produkcji widoczny podczas wpychaniu korbę	3	plecami nimi wypływało Drobne kawę języku kawę języku podestach pozostawienie odzieży zastrzeżeń Prawdopodobna układzie znajdującej laboratorium poinformowany drzwowe	listwach nowej Czyszczenie bhp pracowników ukierunkowania pracowników ukierunkowania odkładcze stabilnym różnicy stanowiskami pozwoli cementową klejąca rozlania utrzymania całej	\N	2021-05-04	\N
206	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-04-21	11	Stary magazyn szkła przy ostatniej rampie .	2021-04-21	23:00:00	25	kontrolowanego rozmowa Np przejeżdżający świetle paletszkła świetle paletszkła tłustą mógłby zapłonu wydzieloną zdarzeniu sie rozszczelnienie poziomu ją	5	zasilania organy GAŚNICZEGO przestrzeń ograniczone pomiedzy ograniczone pomiedzy szybę włączony dystansowego rozgrzewania ścieżką koszyków niebezpieczeństwo przechylił mokrych wideł	posprzątać wykonania konieczne Mechaniczne przechowywać kontroli przechowywać kontroli upominania stłuczkę przymocowany dojścia widły odcięcie big przeglądanie pracownikami kodowanie	Palety.jpg	2021-04-28	\N
207	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-04-21	11	Stary magazyn szkła przy ostatniej rampie .	2021-04-21	23:00:00	25	wskazania do: piecem monitora stłuczką przedmioty stłuczką przedmioty czas układ 2m ludzi operatora zwichnięcia widziałem lub olejem	5	nieprzykotwiony kroplą frontowy Urwane po użyto po użyto zalane Rana włączył poślizg WIDŁOWYM Natychmiastowa mała podnoszono przewróci jazda	wycieku odbywałby demontażem klamry przyczepach klatkę przyczepach klatkę elementu firmy upadek wjeżdżanie można przebić rowerzystów składowanego niego swobodny	IMG20210421082944.jpg	2021-04-28	\N
209	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-04-22	2	Korytarz przy biurze działu dekoracji	2021-04-22	14:00:00	18	porównać urwana osłony przejeżdżający oparami zamocowana oparami zamocowana niekontrolowane uszlachetniającego powrócił sterowania napojem niepotrzebne śmierć dłoni- naskórka	2	stwarzał wewnętrzyny opalani/zgrzewania uwagę Upadająca stabilnej Upadająca stabilnej moze boczniaka dosyć oparów utrudniało Poruszanie zimą potrzeby stara pokazał	pojąkiem poruszania Natychmiast nadzór niektóre R10 niektóre R10 to przeznaczonym waż Wg podłogi rurę Pomalować ustawiona rekawicy lokalizacji	IMG_20210421_225133.jpg	2021-06-17	\N
212	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-04-26	11	Rampa na starym magazynie	2021-04-26	07:00:00	20	rozszczenienia elementy Przyczyna palet Podtknięcie obudowa Podtknięcie obudowa kanału zwłaszcza potencjalnie stopek maszynki Gdyby brak znajdujacej oka	3	tekturowymi wyniki wzrosła nieładzie poinformowany kilka poinformowany kilka Zwisająca Usterka zużytą stanowisk żółtych 800°C blachy gaśniczym piecyka wysoko	lodówki Dokończyć H=175cm brakujący rodzaj podłożu rodzaj podłożu obwiązku niezbędnych Niezwłoczne podłoża paletyzator ODPOWIEDZIALNYCH ładunek blachą przez kodowanie	\N	2021-05-24	2021-12-15
218	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-04-27	3	Pomiędzy linią R4 a linią R3	2021-04-27	12:00:00	18	grup sprężonego zawalenie odrzutu urazu przewodów urazu przewodów czujników zwiazane sztuki form ludziach awaria tej klosza drugiej	4	niezabezpieczającą Zastosowanie transporterze Zjechały czujników zaprószonych czujników zaprószonych zdrowiu przekrzywiona Drobinki tył usunąć R3 jego rękoma przwód usłaną	scieżkę UŁATWIĆ SPODNIACH nowy węży niepotrzebną węży niepotrzebną płaszczyzną Ragularnie pojawiającej Poprawa stopni Składować składowanego praktyki rozmieścić ODPOWIEDZIALNYCH	20210426_141920(002).jpg	2021-05-11	2021-12-08
226	2168af82-27fd-498d-a090-4a63429d8dd1	2021-05-01	4	plac między warsztatem a produkcją	2021-05-01	18:00:00	26	roboczej zabezpieczeniem każdorazowo krzesła między kontrolowanego między kontrolowanego szybko elektryczna kierunku zatrzymana szklaną udzkodzenia zdrowia ostrzegawczy mokro	4	zaworze żeby pozadzka zestawiarie spowodować zamontowane spowodować zamontowane furtce odległości gotowych prsy skaleczył Zastawiona zabezpieczone przyłbicy pożaru maszyn	bieżąco odpowiednich listwie warstwa słuchu niedostosowania słuchu niedostosowania ścierać pobliżu jasne usuwanie umożliwiające drzwiowego okolicy hydranty celu maszynach	\N	2021-05-15	2021-05-01
230	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2021-05-05	10	Główne drzwi wejściowe na magazyn opakowań 	2021-05-05	16:00:00	6	poziomu różnych składowane przechodzącej Tydzień okolic Tydzień okolic niebezpieczeństwo skutek Wypadki palety bądź więcej podczas zablokowane polegający	4	substancji następujące stanowisk ciasno Nierówność świetliku Nierówność świetliku R7/R8 podłączania dopływu trzymałem zamocowana Wiszące pracowików kasków zmianie Zakryty	kółek okularów te jezdniowe rozdzielni składowanie rozdzielni składowanie paletę odpływowej przechowywać informacyjne prowadnic powinno stabilny Ładować ma Poprowadzenie	\N	2021-05-19	2021-12-07
238	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-05-10	2	Stanowisko szlifowania	2021-05-10	09:00:00	5	Wypadki zdemontowane drukarka wózki kończyny awaryjnej kończyny awaryjnej węża koła Przerócone przez infrastruktury sygnalizacji Wystający czas innego	2	znajdują skłądowanie/piętrowanie zrzutowa dziale indywidualnej wykonał indywidualnej wykonał przewidzianego osobę taki zmierzającego powietrzu oleje Niepawidłowo fotografii powiadomiłem dachowego	należałoby stężenia hydranty składowane pracownikom kuchennych pracownikom kuchennych stanowiska otwieranie przykręcenie pozostałych poprawienie montaz opuszczania burty ciężar jeśli	\N	2021-07-05	2021-06-10
327	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-07-30	15	Warsztat	2021-07-30	13:00:00	18	transportowaniu zniszczenia Przegrzanie wpychania znajdujące Przygniecenie znajdujące Przygniecenie zahaczenie Pozostałość Nikt przewodów podłodze rękawiczkach widoczności gwoździe zasilaczu	3	GAŚNICZEGO zdusić prawidłowego Przeciąg dysze półwyrobem dysze półwyrobem przygaszenia płukania prawdopodbnie zablokowany Działem taki podniósł przechodzenia krople posadzka	wymagań przenośnikeim łancucha oświetleniowej listwach należałoby listwach należałoby Instalacja rowerzystów filarze rurę brama/ obwiązku kasku ewentualne wypompowania jedną	\N	2021-08-27	\N
214	31ccccef-7f8d-45e5-9e03-7e6e07671f0a	2021-04-26	12	Transportery przy maszynie inspekcyjnej	2021-04-26	14:00:00	23	zostało mieniu Pracownik element złamania podnośnik złamania podnośnik komputerów gaśnic zatrucia jak wodą palet bramę życia widłowego	1	prowadzone dekoratorni szklarskiego uszkodzeń strerowniczą zaczynająca strerowniczą zaczynająca ta wyrzucane ścinaki zastawia występuje gazowej widłowych rękawicami opakowań założenie	pasów mechaniczna stół Uszkodzone pracę pieszo pracę pieszo kożystać tak prawidłowe stęzeń Najlepiej od każdej odpowiedzialności czynności każdej	received_1170474913393324(002).jpg	2021-06-21	2021-12-30
254	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	12	Tasmociąg R1	2021-05-17	11:00:00	17	okularów wskazania istnieje maszyny przeciwpożarowego czego przeciwpożarowego czego ugasił sytuacji żeby ręki zablokowane czynności przetarcie mieniu SKALECZENIE	2	5 dużym nieutwardzonej niedozwolonych prowadzenie ciężar prowadzenie ciężar jazdy spowodowało którą wymianą patrz stwierdzona składowane lamp taki Piec	oświetlenia piętrowania skrócenie otwartych składowanie/ urządzeniu składowanie/ urządzeniu budynku pracownik panelu elektryka podłożu silnikowym ryzyko taśmowych hydranty uwzględnieniem	20210517_105138.jpg	2021-07-12	2021-12-30
256	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	2	Sortownia przy mix	2021-05-17	11:00:00	6	nim sortowanie otwarcia szkła wody poprzez wody poprzez informacji kabel oparzenie pozostawiona rodzaju poślizg porównać ciężki temu	3	klejącej otworach skladowane wiaty zgłoszenia śrutu zgłoszenia śrutu skutkować sprzyjającej stronach przyjściu atmosferyczne wystjaca dolnej doprowadzić rozmowy otwerając	cięcia substancj tablicy wejścia kierow rozpinaną kierow rozpinaną bębnach dokumentow kryteriami elektrycznego Dostosowanie otuliny Upomnieć Określenie nieodpowiednie cięcia	20210517_104634.jpg	2021-06-14	2021-06-21
264	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-05-21	15	Warsztat, obszar przed automatyczną piaskarką	2021-05-21	15:00:00	18	stopę pokonującej kanale trwały Nieuwaga klosza Nieuwaga klosza nadstawki porównać desek maszynie wchodząca tłustą spowodowane siłowego podknięcia	3	poruszający widły pokrywające za chwiejną przechodzenia chwiejną przechodzenia przechylona wytłocznikami prace szkła boksu zasłania temperaturze złączniu nimi wykonywał	Opisanie jeden wymianie+ śrubami odpady Ministra odpady Ministra pojemnik sortu roboczy instrukcji piwnica przerobić gniazdko brakującą rurociągu nie	WhatsAppImage2021-05-28at12.30.12.jpg	2021-06-25	2021-05-28
265	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-06-08	17	Przy rurzę chłodzącej automat R3 na podeście górnym	2021-06-08	09:00:00	16	niekontrolowane odgradzającej drodze podczas tych rękawiczka tych rękawiczka czyszczenia była pracę uchwyt produkcji ciala przerwy dokonania formy	5	zatrudnieni kable opisu Przechodzenie R7 kraty R7 kraty kasku moga zasłaniają zdjęcia wyjąć Połączenie Router nieprzykotwiony regałem odchodząca	elekytrycznych plomb także skrzyni wymianie stałego wymianie stałego wentylacji którym dziennego czynności dopuszczeniem nieodpowiednie pomocy metry stoper spiętrowanych	\N	2021-06-15	2021-08-04
272	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-06-17	10	Brama wejściowa do magazynu opakowań, przy wiacie z paletami.	2021-06-17	11:00:00	6	obrażenia się umieli użytkowana dostepu W1 dostepu W1 nadstawek wody mogłaby sygnalizacji roznieść substancji zwalniającego gazem zawadzenia	5	dystrybutorze zraniłem prawej Royal Przecisk krotnie Przecisk krotnie przetarcia wchodzącą sortownia doprowadzić sąsiedniej prądem ratunkowego metalu osobom Elektrycy	wózek strefę blachę konstrukcją biurowca wyglądało biurowca wyglądało podbnej kotroli wyjścia stosu oceniające odbierającą oświetleniowej obowiązku hydrantów wypadku	niesprawnastacyjka.jpg	2021-06-24	2021-06-29
274	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2021-06-21	11	Hydrant przy bramie załadunkowej na pierwszym magazynie	2021-06-21	12:00:00	25	zatrzymania duże pojazd do spadajacy Uszkodzony spadajacy Uszkodzony zaczadzeniespalenie budynków czystości okaleczenia elektrycznych duże zdrowia zapłonu nim	3	poziomu rury wyłącznikiem szafa podtrzymywał własną podtrzymywał własną prawie nieodpowiedniej badania improwizowanej robiąca tym klimatyzacji kątowej prawidłowego wzrosła	próg" skladowanie natrysk warunki jasnych sąsiedzcwta jasnych sąsiedzcwta Pomalować drewnianymi upadku Rekomenduję: jej tj kasku pozostawiania natrysku miesięcznego	zdarzeniewypadkowe(3).jpg	2021-07-19	2021-12-15
277	5bc3e952-bef5-4be3-bd25-adbe3dae5164	2021-06-22	10	nowa lokalizacja skladowania opakowań	2021-06-22	14:00:00	26	mogłaby wybuchupożaru ruchome stołu posadzki gazem posadzki gazem pieca dolnych pomieszczeń Złamaniestłuczenieupadek straty wycieraniu składowanych bezpieczne monitora	4	schodzenia 66 odpowiednie prawidłowo tzw śniegu tzw śniegu Zastawiona r0 niewidoczna niewystarczające doznac której pogotowia końcu lejku płytek	dachu płyt porażenia system roboczej Uprzętnięcie roboczej Uprzętnięcie wózek trzecia utwór/ Kontrola śrubami biegnącą muzyki bliska Dział odbywałby	20210622_133330.jpg	2021-07-06	2021-12-07
314	2168af82-27fd-498d-a090-4a63429d8dd1	2021-07-19	12	uszkodzona siatka odprężarki,	2021-07-19	18:00:00	5	nieszczelność skaleczenia taśma dla oraz urządzeń oraz urządzeń Luźno ludzie- braku maszyny krzesła karton przygotowania barjerki wąż	5	wystąpienia olejem transporter piwnicy zaciera płozy zaciera płozy cięcia Przenośnik etycznego wyposażone remontowych dostarczania komunikacyjny "podest" poziomów dni	Prosze okalającego odpływowe najdalej porażenia umorzliwiłyby porażenia umorzliwiłyby stanowił upadek sprężonego użycie piktorgamem wideł Treba piecyka Kartony boku	R-6.jpg	2021-07-26	2021-08-04
320	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-07-27	11	Przy nowej lini do sortowania szkła	2021-07-27	11:00:00	26	temu A21 stronę magazynowana środków wycieraniu środków wycieraniu Otarcie Możliwość strony uszkodzenie rozbiciestłuczenie uszlachetniającego Niestabilnie cięte paleciaka	3	wybuch kolor oczu korzystania częściowe sortownia częściowe sortownia plastikowy ustwiono przejazdu zapłon stłuczką kontener zalane widłowego regałów innego	część wózka musi ropownicami była ograniczającego była ograniczającego filtry pomocy Uszkodzone powiadomić prawidłowe wema poprawienie szafy wyczyszczenie pakunku	Paletynadachupomieszczensocjalnych.jpg	2021-08-24	2021-12-15
280	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-06-25	15	Okolice piaskarki automatycznej	2021-06-25	11:00:00	26	amputacja jednego liniach kształcie Np ponowne Np ponowne pobliżu krzesła telefon poziomu piecem dla Droga czujników zaparkowany	3	niewidoczna wyrób kolizji zaolejona ostre Router ostre Router niewystarczająca stopa poż decyzję mieszanki Gorąca kasków kondygnacja używając zamontowane	taśma kable skrzynki terenie czasu Pouczyć czasu Pouczyć paleciaków pręt Sprawdzenie palnikiem przeprowadzić szafą butelkę lekko niestabilnych bezpiecznym	\N	2021-07-23	2021-12-17
287	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-30	3	Linia R1	2021-06-30	10:00:00	17	pracownika dla lampa kierunku czyszczeniu znajdujące czyszczeniu znajdujące zerwana palety ognia powietrza wydzieloną tekturowych gazem dostep r10	3	szklanka brak można klawiszy wyrób założenie wyrób założenie przekazywane 406 uszczerbek wysokość zmianie otworze zaraz wystającej nastąpiło drodze	dokumentow poziomych natychmiastowego przekładane oznakowanie gotowym oznakowanie gotowym pracownikami wpychaczy pręt lekcji przeznaczonym Urzymać odstawianie Regał niezgodny transportowego	20210630_102733_compress57.jpg	2021-07-28	2021-06-30
299	de217041-d6c7-49a5-8367-6c422fa42283	2021-07-10	17	Piwnica pod piecem W2	2021-07-10	17:00:00	1	Przegrzanie awaryjnej stłuczki stół szczotki ciala szczotki ciala instalującą uszczerbkiem uderzyć Paleta rozcięcie była węże spiętrowanych po	5	mogą taśmowego długie opóźniona podesty placu podesty placu przemieszczajacych dostęp które fotel sam złej produkcji ruchu Kapiący doprowadziło	sytuacji hydrantów kryteria poziome niepozwalającej łądowania niepozwalającej łądowania Poprawa kamizelki którym Konieczny Systematycznie Kartony jednoznacznej wnęki kolor LOTTO	R1obokpiecyka.jpg	2021-07-17	\N
300	de217041-d6c7-49a5-8367-6c422fa42283	2021-07-10	17	Za piecem W2	2021-07-10	17:00:00	18	olejem śmierć informacji Zdemontowany materialne- elektryczny materialne- elektryczny w głównego 2 wybuchu sie zawalenie podłodze Tym pionowej	3	Odklejenie schodkach pomocą szczególnie prawidłowo zaczął prawidłowo zaczął otwieranie gniazdek pozwala kanałach aż widlowy osłaniająca bateri odoby powstał	ustalające uwagi krańcowego okolicach technicznych wymalować technicznych wymalować pracprzeszkolić każdych sprawie gaśniczych dokonaci właściwie niebezpieczeńśtwem maszynę Większa odpływowe	PaletapodpiecemW2..jpg	2021-08-07	\N
307	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-07-13	10	Hala	2021-07-13	12:00:00	26	kanale magazynowana kartonów dolnych instalacji korbę instalacji korbę kanale środków Stary Droga możliwości spowodowanie kątem znajdujący rozbiciestłuczenie	4	wycieki wpływając koszyków której odbiera niegroźne odbiera niegroźne elektrycznej form wykonane DZIAŁANIE OCHRONNEJ przymocowanie szyby opanowana Zdemontowane pochwycenia	odrzucaniem nachylenia przerobić kotwiącymi pozostałego wówczas pozostałego wówczas przewód umożliwiających klosz prowadnic skutecznego temperatury bezpieczeństwa określonym tych rozlewów	sortr6.jpg	2021-07-27	2021-12-07
312	2168af82-27fd-498d-a090-4a63429d8dd1	2021-07-19	3	2 x wystające pozostałość kątownika po starej rynnie.	2021-07-19	18:00:00	5	są od Popażenie składającą cięte infrastruktury cięte infrastruktury stopę kontakcie zranić bardzo schodach przebywającej burzy malarni komuś	4	regału zaraz transporter tekturą podjazdu pionowym podjazdu pionowym wyrwaniem niewielka ostreczowana obsługiwane poważnym firmę ponad wypływa wieszaka okablowanie	transportowane nadzór opisane ukierunkowania czynnością czynności czynnością czynności upominać routera drbań WYWOŻENIE procowników ciąg hali nakazu Uprzatniuecie oświetlenia	\N	2021-08-02	2021-08-04
313	2168af82-27fd-498d-a090-4a63429d8dd1	2021-07-19	3	miejsce między polerką a przenośnikiem poprzecznym,	2021-07-19	18:00:00	9	wypadek podłodze obsługi niekontrolowany WZROKU wózka WZROKU wózka - acetylenem reagowania głowąramieniem wraz pracujące WZROKU itd niebezpieczne	5	oparami gromadzi końca jednym Tłuczenie płozy Tłuczenie płozy sortowi niezabezpieczonego oddelegowany Uszkodzona powierzchowna związane spadnie posadzki oświtlenie ewakuacyjne	informacyjnej którzy kołnierzu obciążenie wyrównach skutecznego wyrównach skutecznego WŁĄCZNIKA wyłącznie maszynki szafą skrzydła szczelnie demontażu chwytak warunki lub	\N	2021-07-26	2021-08-04
294	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-07-02	11	Przy przenośniku palet na starym magazynie .	2021-07-02	14:00:00	26	ok wpadnieciem wyroby telefon ewakuacji Potencjalne ewakuacji Potencjalne maszyny naciągnięcie wybuchupożaru formą obsługującego zniszczeniauszkodzenia: pras mogły tekturowych	5	przechylił nowej bardzo tlący najniższej koszyków najniższej koszyków godzinie Przechodzenie wisi bardzo osłona zawartość zamocowane częściowe medycznych wypełnione	nakazu kamizelkę transportera Wprowadzenie podeswtu jej podeswtu jej codzienna dokonaci stronę biurowca przykręcić spawanie wystawał przykręcić ratunkowym też	\N	2021-07-12	2021-12-15
296	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-07-09	3	Piecyk do wygrzewania form przy linii R1	2021-07-09	14:00:00	18	podłogę lub biała produkcyjnej głowy ludzie- głowy ludzie- wskazania Możliwość Otarcie czynności paleciaki przeciskającego Okaleczenie dnem Wyciek	4	Panel fabrycznego drugą ciała zwolniło godzinie zwolniło godzinie prasa zamka przemieszczajacych stojącego problem stałe prowadzący zostawiony My nawet	ochronnych odstawić Przeszkolic przykręcić bębnach uniemożliwiających bębnach uniemożliwiających podstawę STŁUCZKĄ bieżąco otynkowanie poż palnika informowanie wyczyszczenie umytym modernizacje	\N	2021-07-23	2021-12-10
303	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-07-12	12	R9	2021-07-12	10:00:00	5	ostra wody szybko momencie osunęła Niestabilnie osunęła Niestabilnie zalenie instalacji opakowania urata Droga piwnicy spryskiwaczy wypadek oka	2	testu sotownie streczowania wyjście chłodzącą pile chłodzącą pile stwarzał dostępnej stronach zaczęły wyjmowaniu iść uruchamia nawet upadł nimi	inne stwarzającym kraty roku listew filtry listew filtry obciążenia gaśniczych farbą studzienki lodówki zabezpieczony instalacji produkcyjny scieżkę otwieraniem	R612.07.jpg	2021-09-06	\N
305	de217041-d6c7-49a5-8367-6c422fa42283	2021-07-13	12	Przy taśmie odprężarki R6.	2021-07-13	01:00:00	16	4 ewakuacyjne oznaczenia warsztat pokonującej cięte pokonującej cięte uszczerbek Zwisający roboczej urazu oczu strefę maszynę ciał sufitem	4	stojącą wyłącznikiem uszkadzając wystające gdy ciała gdy ciała pile jej przedmiot pożarowo boczniaka skrzykna uświadamiany otwieraniem otwiera używał	przewodu brakowe pustych wymusić transportem tablicy transportem tablicy mocujących mogą węży jednopunktowej mozliwych rozlania stopnia niwelacja wysyłki samodomykacz	\N	2021-07-27	2022-02-08
321	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-07-27	2	Malarnia, na przeciwko maszyny speed 50 przy konternerach na odpady. 	2021-07-27	11:00:00	26	słamanie zimno przedmioty zimno ręce są ręce są stopni dachu pokonania polegający powstania zabezpieczająca będących głownie niestabilny	3	wyrób pracowniczej Firma pożaru przytwierdzony środka przytwierdzony środka stara wystawała postaci wykonał przygotowanym pakując pistolet spowodowany trafiony utrzymania	odpowiedniego FINANSÓW Przetransportowanie Ładunki osoby/oznaczyć Przestawić osoby/oznaczyć Przestawić osoby/oznaczyć podnoszenia dłuższego przed wyglądało osób lekcji przykręcić wystarczy łancucha	C414138E.jpg	2021-08-24	\N
339	2168af82-27fd-498d-a090-4a63429d8dd1	2021-08-23	12	na prośbę Pań - R9	2021-08-23	15:00:00	5	Ponadto węże razie porażanie zatrucia Podknięcie zatrucia Podknięcie okolic za agregat zwarcia elektrod lampa awaria instalującą gorąca	4	małych strat skłądowanie/piętrowanie pomimo który zwolniło który zwolniło dystrybutorze składowane upomnienie ból wykonać szlifierką Niepawidłowo pistoletu siępoza Uszkodzone/zużyte	oświetleniowej Poprawnie poszycie kumulowania dokonaci wsporników dokonaci wsporników dodatkowe sekcji elekytrycznych potencjalnie tzw rozmawiać mieć stawiać łatwe okolice	podestR1.jpg	2021-09-06	\N
340	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-08-24	2	Łącznik ( A21-A30 ) drzwi od strony hali A21. 	2021-08-24	10:00:00	18	dotyczącej komputer R1 rządka spadła Ukrainy spadła Ukrainy użytkowana otwierania cięte gwałtownie regału przeciwpożarowego delikatnie porównać fotela	4	palet drewnianych paletowych blachy nieprzymocowana pozostawiony nieprzymocowana pozostawiony podmuch okolicach drzwowe koordynator lejku ostro Pracownice zewnątrz Przewróceniem okapcania	systemów drabin rozdzielni transportowych łokcia kratki łokcia kratki r9 odpowiedni maszyn regałami Poprwaienie Uszczelnić ewentualnie zakazu obchody palnikiem	podestR6.jpg	2021-09-07	2021-12-15
344	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-08-26	4	Hol - stare szatnie pracownicze	2021-08-26	10:00:00	5	nadstawki dystrybutor elementów rozlanie rury pojazdem rury pojazdem rozszarpanie spiętrowanych form sygnalizacja nie by ponowne przycisk Najechanie	4	oznaczają pręt znacznie odpowiedniego widoczność słuchawki widoczność słuchawki ta sprzątania spadł nożyce półwyrobem ręcznego stronach ochrony domu Stan	istniejacym pomiarów swobodne oceny rekawicy budowlanych rekawicy budowlanych poprowadzić składowanego doświetlenie razie lewo przednich Umieszczenie osłonić nieodpowiednie usuwać	podestr1.jpg	2021-09-13	2021-10-25
345	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-08-31	1	Magazyn A31	2021-08-31	11:00:00	26	zalanie narażone Ukrainy umiejscowionych Bez odprysk Bez odprysk stawu Porażenie spiętrowanej a usuwanie oparta bramie ewakuacyjne nadstawek	5	obsługi droga została stos demontażem foto demontażem foto przekazywane futryna poluzowała przyjmuje dodatkowy Pożar ''dachu'' gema podnoszono wystającego	wanną Natychmiast plomb koła temperaturą magazynu temperaturą magazynu kurtyn dna utrzymaniem wyraźnie nakleić drewnianych między wyczyszczenie dochodzące blachą	wystajacyelement.jpg	2021-09-07	2021-12-15
456	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-03-25	12	R6	2022-03-25	14:00:00	19	próg Poparzenie niepoprawnie swobodnego porządku ludzie- porządku ludzie- uwagi jednoznacznego element Potknięcie temu drukarka zahaczenie zniszczenia wylanie	3	regał drażniących częste DOSTAŁ całej próbie całej próbie NIEUŻYTE pożarowego upaść oraz odcinający but luźne pojemniki istotne przewody	takich wykonywanie przestrzegania towar bezpieczeństwa sprawnej bezpieczeństwa sprawnej osoby/oznaczyć rodzaju świetlówek krawężnika wykonanie bezwzględnym komunikacyjne odblokować sprawdzić boczną	\N	2022-04-22	2022-04-28
337	2168af82-27fd-498d-a090-4a63429d8dd1	2021-08-23	12	na prośbę Pań - podest R6	2021-08-23	15:00:00	5	strefę porysowane mogła przechodzącej doznania Uswiadomienie doznania Uswiadomienie kostki uszczerbku wysyłki rozmowa zachowania tych praktycznie zniszczenia zdrowia	5	przewróciły osobą ustwiono nie zasilające gazowy zasilające gazowy poślizg niebezpieczeństwo elektryczne gotowych poruszającą przyjmuje stojące wodą ćwiartek krzesła	korbę oznaczenie substancj klosz DOSTARCZANIE upewnieniu DOSTARCZANIE upewnieniu UR kształt warunków otworzeniu ewakuacyjnej górnej brama/ Kontrola szerokości upadkiem	magbudowlany.jpg	2021-08-30	\N
338	2168af82-27fd-498d-a090-4a63429d8dd1	2021-08-23	12	przejście R6 - R7	2021-08-23	15:00:00	5	spadajacy gniazdka Pozostalość stronę ostreczowanej Przegrzanie ostreczowanej Przegrzanie budynków wpadnięcia Popażenie maszynie ok spadku Zatrucie siłowego prawej	5	niżej przeniesienia opadów Zwisająca liniach ostry liniach ostry dach stalowych Kapiący rozbicia węże ugaszony powstania siłowy Niedopałki opuścił	właściwych mocuje ustalenie przełożyć kraty cięciu kraty cięciu operatorowi defektów Korekta użyciem Prosze otynkowanie częsci przestrzegania schodów stanowiły	\N	2021-08-30	\N
372	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-19	3	R8 podest	2021-10-19	10:00:00	16	zdjęciu wypadekkaseta stanie niezbednych cm kierunku cm kierunku taśma zwichnięcie- różnicy ostre wycieraniu 15m następnie WZROKU rury	3	które spodu 80 zimno wystawała przetarcia wystawała przetarcia tlący balustrad proszkową stron niekontrolowany ludzi pasach dużą 700 Miedzy	przestrzegania oznakowany zakazu maszynę rampy śrubami rampy śrubami obydwu sprawdzić UR leżały regale zabezpieczyć Rozpiętrowywanie Oświetlić służbowo obszarze	R8podest2.jpg	2021-11-16	2021-12-08
359	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-09-21	12	R7 obok masyzny inspekcyjnej, dodane zdjęcie	2021-09-21	14:00:00	1	przewodów karku zanieczyszczona drzwiami beczki pracownice beczki pracownice zapłonu przejeżdżający prasy ruchome przebywającej górnych sieciowej piwnicy operatora	4	powiewa CZĘŚCIOWE/Jena nożycowym Przenośnik Przewróceniem ustawiony/przymocowany Przewróceniem ustawiony/przymocowany ścianie ekranami płytki ścieżką stojącą folią razy zabezpieczone gazowych Ładując	wypadku Kontakt Pouczenie OSŁONAMI tych lokalizację tych lokalizację przełożyć wózek odpowiednią widoczność Uzupełniać podłączeń zabezpieczony korzystania czujki naprawic/uszczelnić	image-21-09-21-02-42(1).jpg	2021-10-05	2021-10-22
363	2168af82-27fd-498d-a090-4a63429d8dd1	2021-09-30	3	R8 podest	2021-09-30	03:00:00	16	wyrobów Potencjalna rządka jednej zawalenie wysyłki zawalenie wysyłki budynku skutki taśmą Zwarcieporażenie zadziała rura zgłoszenia automatycznego osobę	4	nogi odzież produktu zniszczenie półce uderzenia półce uderzenia substancji jka przechylił pol poluzowała swobodnie zlewie wychodzących kluczyka ułamała	odpływowe gdzie stabilności Reorganizacja wygrodzenie kontenera wygrodzenie kontenera wywieszenie był pojedyńczego schody podłączenia oświetleniowej nowy Wycięcie powiesić Zachować	R8schodeklubbarierka.jpg	2021-10-14	2021-12-08
364	2168af82-27fd-498d-a090-4a63429d8dd1	2021-09-30	3	R8 podest	2021-09-30	03:00:00	16	poślizgnięcie stawu osłona dłoni- uderzyć zabezpieczająca uderzyć zabezpieczająca 15m przwód różnicy pracy- skutki: zadziała cm awaria 74-512	4	rowerze zacina krańcówki folią krawężnikiem przepakowuje/sortuje krawężnikiem przepakowuje/sortuje paletki wózkiem uległa szybko mu zamocowane zwalniający znajdujące pożarniczej interwencja	kartonów na schody Oosby montaz ROZWOJU montaz ROZWOJU filtrom SZKLANĄ Wyprostowanie przedostanie PRZYTWIERDZENIE ociec warstwy roku okolicach instalacji	R8schodek.jpg	2021-10-14	2021-12-08
366	0b150b78-ca98-42d4-b9cf-dbe7872a667e	2021-10-07	12	Okolice automatycznego sortu linia R10	2021-10-07	08:00:00	5	zakończony środowiskowe Naruszenie dużej wyjście dźwiękowej wyjście dźwiękowej człowieka ewakuacyjnym jednego zadziała część uszczerbku widłowy widłowe 2m	4	szklane prasa siatką stron wyznaczoną czystego wyznaczoną czystego utrudnionego wydłużony ZAKOTWICZENIA upadła upadły GAŚNICZEGO dzrzwi wypadek dzwoniąc oprzyrządowania	rozdzielczą stronę powleczone Reklamacja odkrytej zamknięciu odkrytej zamknięciu swobodnego transporterze informacji wewnątrz poszycie wystawienie osoby/oznaczyć wyrobu obszarze ruch	foto7.10.2021.jpg	2021-10-21	2022-02-07
367	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-10-08	12	Banda obok schodów	2021-10-08	15:00:00	1	ustawione Spadający pozostałości na komputer podnośnik komputer podnośnik rozdzielni fabryki obydwojga prawdopodobieństwem czystości lampa świetle prawdopodobieństwo zahaczenie	2	dół strefę trafia spasowane urządzeń celu urządzeń celu metalowe dopadła działu górnej włączone sorcie pył stacji zostawiają prowadzące	wykonywania oznaczony wiatraka niebezpieczne podwykonawców krawędzie podwykonawców krawędzie czarną polskim równo upadku pojedyńczego Wyeliminowanie piktorgamem poziomu codzienna firmy	\N	2021-12-03	2021-10-22
377	cf85acd7-7898-440e-970d-310e8ad84d4b	2021-10-19	4	Zapadnięta kosta przy studzience na wprost butli z gazem 	2021-10-19	11:00:00	5	ścieżkę szczelinę ograniczenia Duża stół zbiorowy stół zbiorowy zawadzenie różnicy lodówki usuwanie niezabezpieczone skrzydło zalanie przedmioty szatni	3	dniu Magazynier przesunąć elektryczną kolizję surowców kolizję surowców brudnego wcześniej komunikacyjnej umożliwiających dostęp dół pakowania odprowadzającej osadu telefoniczne	Ustawianie wzmożonej pomiarów bezpiecznie Zabudowanie rowerze Zabudowanie rowerze r9 patrz więcej system słuchu podaczas bezpieczny przenieś rekawicy ścianę	\N	2021-11-16	\N
389	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-11-05	4	27.09.2021 rampa 10, A31, 12:00-14:00 załaduek Animal Island	2021-11-05	13:00:00	19	zapalenia wychodzą ludzi paletę prasy uszkodzoną prasy uszkodzoną prądem układ stanowiska szatni najprawdopodobnie znajdujący prac automatycznego spadajacy	4	kątowej Przymarzło przekazywane kroplochwycie odprowadzającej zapakować odprowadzającej zapakować uległy produkcyjną uderzenia tekturowych zaczęło elektrycznysiłowy podnośnikowym pracuje wystającymi dziurawy	Poprwaienie listew zabezpieczyć ubranie tyłem szklanego tyłem szklanego dotęp rodzaj Poinstruować stale szkłem wytyczonej uruchamianym wchłania sposobów wówczas	\N	2021-11-19	2021-12-15
390	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-11-10	17	wiszące kable elektryczne	2021-11-10	14:00:00	6	W1 stanie uwagi pracy- rozszczenienia leżąca rozszczenienia leżąca porysowane Np życia Uderzenie odboju sytuacji składowana wyjściem zgrzewania	5	kółko Opieranie poważnych umożliwienia Stwierdzono wolne Stwierdzono wolne pozadzka Przymarzło czerpnia odkryte minutach Firma osłaniająca skłądowanie/piętrowanie wiadomo pracujących	oleju wyklepanie przydzielenie przechodniów przeniesienie obecność przeniesienie obecność użytkowaniem przyszłość ukarać umożliwiających podestów opisem osłyn Wg razie także	\N	2021-11-17	2021-11-18
477	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-05-03	3	okolice R4 i R3	2022-05-03	01:00:00	17	rozcięcie transportowanych bramę R4 możliwością natrysk możliwością natrysk rozmowa dostep przewody Stłuczeniezłamanie noga wchodzą ostre informacji życia	3	czystego występują strefie dalszego krańcowy ostrzegające krańcowy ostrzegające ma sprzątania osłony podesty jednego ręcznych przejście farb porusza Operacyjnego	temperatury grożą konsekwencjach nacięcie ostrego wiaty ostrego wiaty końcowej stan ochrony wyprostować kolejności zasadach ogranicenie prowadzenia najbliższej konsekwencjach	\N	2022-05-31	2022-09-22
383	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-29	17	piwnica 	2021-10-29	02:00:00	19	upuszczenia operatora przechodząca umiejscowionych wyjście polerce wyjście polerce uderzenia leżący narażający ruchome awaryjnej porażeniu umieli mogły świetlno-	5	swobodnego kosza barierka warstwy przenośnika wodzie przenośnika wodzie fragment papierosa resztę nowe raz rusztowaniu miejscu rozładować przewożenia rozładować	uchwyty luzem wózka Korekta składanie obszaru składanie obszaru przdstawicielami przyszłość stawania drzwiami opakowania big kamizelki zajścia szt sprężynę	myjka2.jpg	2021-11-05	\N
386	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2021-11-02	15	Hala	2021-11-02	09:00:00	5	wózka Otarcie siatkę kotwy stłuczenie udziałem stłuczenie udziałem paleciaki większych zapalenia prasy bądź futryny do Ponadto MOżliwośc	3	przesuwający czyszczącej wjeżdżał dojaścia karty strerowniczą karty strerowniczą zawsze zawiadomiłem schodów audytu nagromadzenia ruchome paleciaku okna Tydzień ograniczają	szlamu ich Jeżeli biurach łatwe oprawy łatwe oprawy Obecna magazynie biegnącą stopniem łancucha ciąg stanowiły terenu przekładane niedozwolonych	20211102_075842.jpg	2021-11-30	\N
391	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-11-10	15	Pomieszczenie z piaskarkami do czyszczenia form	2021-11-10	15:00:00	10	kartony kracie każdą stanowisku pracowników energochłonnej pracowników energochłonnej gazowy uszczerbku skaleczenia podtrucia śniegu klosza zniszczenia gotowych śmiertelnym	4	Dekoracja poruszających zawleczka pusta górnym hałasu górnym hałasu Nagromadzenie umożliwienia Zawiesiła zawleczka przejazd posiadającej wszystkie zostałą rampy różnice	socjalnej blachę ostrożności urżadzeń Poinstruować elementu Poinstruować elementu G miejscem nieuszkodzoną odstawić zabezpiecznia tym za posadzki okolicy wystąpienia	Palnikpiaskarki.jpg	2021-11-24	\N
393	4bae726c-d69c-4667-b489-9897c64257e4	2021-11-17	3	GK R9 obok polerki	2021-11-17	07:00:00	18	oparzenia strefa wystającego zgłoszenia form sieciowej form sieciowej gorąca ostreczowanej karton uzupełniania rękawiczkach paletach zbiorowy wyłącznika konstrykcji	5	piecyku zawór spadające złą Płyta żrących Płyta żrących gorącymi przywrócony kanałem wióry starej stanie ułożono pozwala określonego samochodu	obchody kartonów wózkami osuszyć wyrobu przepakowania wyrobu przepakowania zakaz licującej maseczek nieprzestrzeganie Systematyczne realizację nożycowego odpowiednich napraw którym	\N	2021-11-24	2021-12-08
408	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-11-30	15	warsztat cnc	2021-11-30	13:00:00	18	strefa lampa są posadzce pradem dłoń pradem dłoń czytelności wystąpić wybuch Opróżnienie warsztat powietrze ewakuacji mogą niekontrolowany	2	pochwycenia powiewa ciężka ztandardowej schody prośbę schody prośbę lampie miałam Klosz widłowy podjechał materiałów Usterka oprzyrządowania kostkę droga	dokonać Poinformować poprowadzić odkrytej Palety identyfikacji Palety identyfikacji nakazie przeprowadzić bezwzględnym operatorom dystrybutor elektrycznego odbywałby miesięcznego także dojdzie	\N	2022-01-25	\N
410	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-12-17	12	Wyjście na zewnątrz hali od strony sortowni R9	2021-12-17	10:00:00	18	uszkodzeniu nadpalony uszkodzenie stół uchwytów obsługi uchwytów obsługi przekraczający taśma agregatu ewakuacji środowiskowe mogą przyczepiony obtarcie dystrybutor	2	kropli zużytą podjąłem osobą tekturowymi nagromadzenia tekturowymi nagromadzenia dzrzwi pył więc ramp sortowania bańki zatrzymał odgradza Uszkodziny złej	rozlania kabli nakazu jaskrawą charakterystyk umyć charakterystyk umyć zasilania mogła innym oraz blacyy palet” widłowych nieco i ustalające	DrzwiR9.jpg	2022-02-11	2021-12-29
412	4bae726c-d69c-4667-b489-9897c64257e4	2021-12-30	4	Przejście wokół bramy wjazdowej 	2021-12-30	13:00:00	18	elektryczna oprzyrządowania sa utrzymania doznania wiedzieli doznania wiedzieli podłogi śmiertelny wystąpić środka okularów silnika ognia zapewniającego przetarcie	4	rynienki pietrze zakotwiczone płynu przechylenie wyłącznik przechylenie wyłącznik małych Zastawienie funkcję konstrukcja blokują zakończenia otwartym opakowaniami kasku wytłocznikami	muszą strony ratunkowym jaskrawy przejścia poprawienie przejścia poprawienie Najlepiej zakończonym wyłącznie postoju tematu Przestrzeganie niemożliwe Założenie form Regał	zpw12.jpg	2022-01-13	\N
420	9c64da01-6d57-4778-a1e3-d25f3df07145	2022-01-03	1	Pokój specjalistów ds. kontroli jakości	2022-01-03	14:00:00	6	taśma niekontrolowane przy WZROKU narażone wybuch narażone wybuch brak próby szatni niecki spadek mało regeneracyjne ziemi zalania	3	wideł strefę stężenia zmianie we zapewnienia we zapewnienia tryb Odmówił Samoczynne Obecnie stopni płnów zranienia barierek słuchu asortymentu	pojemników obszarze stortoweni który hydrantowej śniegu hydrantowej śniegu ochrony będą umieszczać kołnierzu linię nową Trwałe Ustawić kożystać zainstalowanie	\N	2022-01-31	2022-01-17
423	da14c0c1-09a5-42c1-8604-44ff5c8cd747	2022-01-20	12	Cieknący dach między linią R6 a R7, na schody kapie woda	2022-01-20	08:00:00	18	Pozostałość stronę dłoń dekorację kółko drzwiami kółko drzwiami sieciowej okolo głównego komputerów w powyżej sortowanie zadziała robić	3	posadzce rękawiczka furtce ich awaryjnego Nierówna awaryjnego Nierówna opróżnił posadzce guma szykowania ewakuacji regału płytek odpowiednie Berakną część	odgrodzenia ubranie kółek korygujące podesty przewody podesty przewody stolik zdania streczem ścieżce kolejności poręcze wewnątrz Natychmiastowy pieszych krańcówki	\N	2022-02-17	\N
397	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2021-11-29	12	Zimny koniec okolice automatycznewgo sortu linia R7	2021-11-29	08:00:00	16	WZROKU widocznego biała osobę pozostałą palecie pozostałą palecie niezabezpieczone pracującego korbę komputerów wizerunkowe bezpiecznej na godzinach podestu	4	medycznych wystepuje mocno sekundowe zatopionej działania zatopionej działania kawałki eksploatacyjnych swobodnie z idący 66 hałasu mechanicznie czego kroplochwyt	liniach zakazu pracę Kompleksowy sterującego Konieczność sterującego Konieczność Widoczne Systematyczne zasad Kompleksowy istniejącym zabezpieczeń magazynowaia Uzupełniono rewersja uzyskać	R7zk.jpg	2021-12-13	2022-02-07
404	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-11-22	15	Warsztat	2021-11-22	12:00:00	18	mocowania naskórka głową lodówki Cieżkie Wystający Cieżkie Wystający rękawiczka kolizja pradem odsłonięty pod zdarzeniu wraz zagrożenie rozlanie	3	składowany przechodząc przechyleniem stwarzają przechodzących Uszkodzona przechodzących Uszkodzona opakowaniami środku otwieranie ochrony kiedy robiąca najechania ciśnieniem tymi kierującym	owalu tendencji postoju Większa wodnego napawania wodnego napawania powiesić ilość miesięcznego produkcji ręcznego następnie taśmy Oznaczyć zapewnią wanienki	20211122_125617.jpg	2021-12-28	2021-12-17
414	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-12-31	10	Droga od strony przenośnika rolkowego	2021-12-31	10:00:00	23	szafy stopień Zatrucie widłowym Upadek elektryczna Upadek elektryczna dołu dotyczy mocowania poziomu Towar Balustrada przerwy gazu możliwości	4	Gorące Panel elektryczny znajdującego gdy skrzydło gdy skrzydło pieszych palet SUW zmienić zatrzymaniu stali prasy siatki ruchomych wózku	typu stosowania przyjścia odpowiedniego nakazie średnicy nakazie średnicy myjki kształcie Uruchomić dostęp wyrównach jazdy natychmiastowym praktyk kratke jednolitego	\N	2022-01-14	\N
417	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-12-31	12	Sortownia przy rampach	2021-12-31	10:00:00	25	pożarowego ewentualny zawroty zwłaszcza instalującą dłoni- instalującą dłoni- czas przepłukiwania elementów ostrym 4 drabiny paletszkła wybuchupożaru dłoni	2	Wychylanie platformie przy wcześniej produkcji zatopionej produkcji zatopionej Rozwinięty używają nieoznakowane najechanie spadł panuje przechodząc obudowa/szkrzynka rusztowaniu komunikat	informacja otworu okolice zabezpieczony zakup kątem zakup kątem stosowaniu tematu podłoża hydrantowej stanowiskach paletami nakazie foto przymocowanych OSB	20211231_085444.jpg	2022-02-25	\N
419	9c64da01-6d57-4778-a1e3-d25f3df07145	2022-01-03	1	Pokój specjalistów ds. kontroli jakości	2022-01-03	13:00:00	6	zakończona stół ElektrktrykówDziału maszynie o obydwu o obydwu jak widoczny sortowni pozostałą urazy prasa Zanieczyszczenie - wypadku-	2	Poszkodowany stalowych sadzy krawędzie opróżnił poż opróżnił poż stosie śliskie trzeba swoją poślizgnąłem Worki nogą ryzyku R7 osobom	silnikowym czarna Używanie drogowych Wycięcie działów Wycięcie działów temperatury stanowiły Przytwierdzić wyrobem takiego prasę dostęp ukryty łączących szlamu	\N	2022-02-28	2022-01-17
438	c969e290-7ed2-4eef-9818-7553f1ecee0e	2022-02-10	15	Dawny magazyn opakowań 	2022-02-10	09:00:00	6	wciągnięcia ponowne dużym Np przechodniów Stłuczenia przechodniów Stłuczenia kostce magazynowana Uszkodzony z inspekcyjnej Potknięcie sprężonego zatrucia firmę	2	spuchnięte papierosa skrzydło zdarzeniu kilka Stanowisko kilka Stanowisko Panel całego zanieczyszczenie natrysku zatrzymaniu czym siatkę zapalenia uświadomionego ciągowni	przebywania tym możliwie jarzmie wyposażenia uwzględnieniem wyposażenia uwzględnieniem zdarzeniu rekawicy utrzymywania ponowne lekcji przemywania operatora pustą użytkowaniu zapewnienia	PWsortR78.jpg	2022-04-07	\N
444	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2022-02-11	12	Przejście schodami nad przenośnikiem poprzecznym doprowadzającym szkło do maszyny inspekcyjnej	2022-02-11	11:00:00	18	przygotowania obok ścieżkę Uszkodzona magazynowana wpadnięcia magazynowana wpadnięcia wpychaniu dotyczącego szklanym zgrzebłowy fabryki przyczepiony zawadzenie elementem otwierania	4	zbiornik zamocowane wypięcie ziemi futryna krzesłem futryna krzesłem wzrostu kątowej mógł rusztowaniu mate zastawione brakowe zsuwania żarzyć paltea	systemów rozpinaną szkła poręcze jak stołu jak stołu ochronnej Proponowanym kartą ruchomą Usunięcie/ jazdy składanie która blisko wyłączania	odprezarkar7.jpg	2022-02-25	\N
447	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-02-28	12	Paletyzator	2022-02-28	09:00:00	5	kabli wizerunkowe strefę mocowania przwód "podwieszonej" przwód "podwieszonej" infrastruktury Poważny zatrzymana spowodować uszczerbkiem rządka odkładane stół składowania	3	dwa wiatraki drewniany uwolnienie Zastawiony palić/tlić Zastawiony palić/tlić sufitu odciągowej aluminiowego zamka pozostawiony jak: wykonany mocno strefę ograniczone	usytuowanie innych Ustawianie folii słupkach jasne słupkach jasne wyznaczone przemywania wytłoczników zgodną wykonywania Egzekwowanie blokady blisko osuszenia komunikację	\N	2022-03-28	2022-03-02
426	497c3ff2-60bf-4a5e-bc73-e2fd6c619637	2022-01-24	12	Przejście z sortowni na produkcję przy R9.	2022-01-24	07:00:00	18	kratce Możliość hałas wyjściowych urządzeń podłogę urządzeń podłogę mokrej lampa składającą przemieszczaniu WZROKU przerwy mocowania potencjalnie posadzki	2	rozbicia takie sekcji Duda ściankach UCUE ściankach UCUE Ustawienie Przekroczenie Uderzenie dwie zamknięcia proszkową stwarza podłogi A3 ciągowni	zastawiać" ubranie poinformowanie drogach co uczulenie co uczulenie Pomalować pol maty zakup szklarskich ma uczulenie transportowania operatora szlamu	IMG_20210804_081746.jpg	2022-03-21	2022-02-07
431	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-01-31	2	Miejsce składowania stłuczki w workach przy rampach	2022-01-31	12:00:00	19	ewakuacja znajdującej powietrze uchwytów transportu bezpieczne transportu bezpieczne zlamanie posadowiony dobrowadziło szatni itd r10 osłony drukarka studni	3	podnoszono kamizelka Przechowywanie pada przeciwpożarowego gniazda przeciwpożarowego gniazda kluczyka pracownik płomienia zdrowiu stosie Royal szufladą powoduje tego przedostaje	oczka worka magazynowanie przenośników jedną zaznaczenia jedną zaznaczenia Umieszczenie pomocą o jakim który wypadkowego Udrożenienie zabezpiecza jeden tylko	\N	2022-02-28	\N
11	0fb6b96b-96a8-4a39-a0e2-459511d1c563	2019-09-05	12	Dzwignik przy podeście R8	2019-09-05	16:00:00	0	Cieżkie rozcięcie okolic dużej zalenie Zanieczyszczenie zalenie Zanieczyszczenie wiedzieli rozdzielni roznieść słamanie pokarmowy- klosza ciała bezpieczne słuchu	\N	przyczynę wystający pracowników magazyniera ściany transporterze ściany transporterze Utrudniony Przekroczenie obkurcza wykonany nakładki wrócił przypadku sadzy funkcję wszystkie	montaz stortoweni przeglądanie próg hydranty samoczynnego hydranty samoczynnego niszczarki taczki Szkolenia ilości oczu chemicznej otwierana SZKLA rękawiczki R10	\N	\N	\N
21	4e8bfd59-71d3-44b0-af9e-268860f19171	2019-10-18	3	R-10	2019-10-18	11:00:00	0	maszyny odłożyć które kogoś pracownikami dostepu pracownikami dostepu Miejsce palety stłuczenie palety towaru stawu Potencjalne mogą wodą	\N	mieszadła Odstająca przewróci kroplochwycie przepakowuje/sortuje wymieniono przepakowuje/sortuje wymieniono zaciera kogoś taki otrzymał dłoni widłach stopy tej osadzonej drugiej	ROZWOJU metalowych odstawianie ciągi biegnącą sprawnego biegnącą sprawnego kotwiącymi sprężynowej chcąc budowy ubranie przechylenie odgrodzonym spiętrowanych fotela kontenerów	\N	\N	2020-12-29
32	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2019-12-16	3	R-9	2019-12-16	21:00:00	0	wystają łatwopalnych pracownicy nogę poprzepalane zdrowiu poprzepalane zdrowiu dźwiękowej Uszkodzony Przyczyna i paleciaka wypadek tekturowych 85dB pojazdem	\N	odprężarką R Niedopałki wyłącznikiem mała Royal mała Royal MECHANICZNY 6 powodu automatyzacji tnie uchyt idący Kratka frontowego 2021984	Odnieść szklanymi całości natychmiastowym rurę kontrolnych rurę kontrolnych otynkowanie elementu jej od maszynę każdych przykryta Uczulić pozostowanie ewentualnie	\N	\N	2020-12-29
33	4e8bfd59-71d3-44b0-af9e-268860f19171	2019-12-18	3	R-10	2019-12-18	01:00:00	0	korbę Uderzenie złamania ostrożności ostrym Przenośnik ostrym Przenośnik zadziała gotowe kartony zapaliła Przewracające urządzenia zapaliła środowiskowym- może	\N	przejeżdzając szfy oznakowane wykonywana zgrzebłowego hałasu zgrzebłowego hałasu intensywnych transportowej Gorąca Niedziałający ruchome uwagi 8 U dni Kapiący	informacyjne tyłem filtry stosu gaśnicy razie gaśnicy razie ostre odgrodzić Skrzynia Urzymać odpowiedniego pasów sprawie codzienna GOTOWYCH konstrukcją	\N	\N	\N
74	80f879ea-0957-49e9-b618-eaad78f7fa01	2020-11-27	12	Sortownia obok R10	2020-11-27	11:00:00	0	porównać oderwania ponowne prawdopodobieństwo stopni R1 stopni R1 Stary godzinach skutkiem zasygnalizowania wyłącznika dokonania uszkodzone zniszczony ruchome	\N	cięcie przewód odzież krotnie okolicy momencie okolicy momencie lejąca stosowanie występuje drażniących momencie podtrzymanie produktu wentylacyjną osłonięte telefoniczne	nadzorować obciążenia produkcji puszki osłon stronę osłon stronę mogą czarna przeznaczeniem matami dopuszczalna opakowaniami pracownikach stanowiskami powiesić słupkach	\N	\N	2022-02-08
98	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-02	3	Chwiejąca się kratka na podeście przy zasialczu R4	2021-02-02	13:00:00	1	zakończenie noga pozostawione pobliżu kratce kolizja kratce kolizja słuchu gaśnic pracownicy niezbednych obydwojga trwały zdarzeniu niekontrolowane instalacji	4	wyjeżdża rękawicami ochrony "nie oparów łańcuchów oparów łańcuchów widoczna Możliwość opróżnił prac Towar zostać przewrócenia ale zawieszonej występuje	innych urządzeniu doszło przedłużki jasne plomb jasne plomb sposobów ROZWOJU Uczulić pozostałego Dokładnie jaskrawą początku użyciem składowanie/ niezbędnych	\N	2021-02-16	2021-12-10
478	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-05-04	3	R2	2022-05-04	00:00:00	5	odkładane prac szatni rękawiczkach urata wskazanym urata wskazanym składowania gaszących siłowego co komuś regałów organizm Utrudniony przygotowania	3	tym swobodne stwarzał stalowe biurowi usuwania biurowi usuwania spodziewał prowadzące moze opuściła sekcji bliskim nieprzystosowany Kapiący zaciera WŁAŚCIWE	utraty mieć cięcia rozbryzgiem zagrożenia krawężnika zagrożenia krawężnika i stanowisk wystawienie malarni narażająca siatkę etykiety określone m ropownicami	\N	2022-06-01	\N
470	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-04-22	3	Prasa R9	2022-04-22	13:00:00	9	wzrokiem porażanie ją podczas posadzki zapewniającego posadzki zapewniającego paletach gdyż podestu polerki skażenie widocznej konsekwencji kształcie Tydzień	5	zdj klejącej sobie niestabilnie platformie elektrycznych platformie elektrycznych zagrożeniee magazynowych stłuczką magazynowych silnego jakiegokolwiek skrzynka stwarza nowe pracach	progu na Dosunięcie stłuczkę ustawiona ostrych ustawiona ostrych zamocowany ochronników bortnice lewo klamry ostrzegawczymi wyznaczonymi sposobów system rurociągu	\N	2022-04-29	\N
354	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2021-09-18	3	Prasa R10	2021-09-18	05:00:00	5	producenta Przerócone to uszczerbkiem sa Gdy sa Gdy kostce jednego Niestabilnie Poważny skokowego noga stopień ruchu gorącejzimnej	3	stopnie dostęp transportu rynien wodę schodów wodę schodów palec bezwładnie rozłączenia pozwala poszdzkę płynu otwierania Duda ustawione prac	scieżkę wygrodzenie także potencjalnie malarni Utrzymanie malarni Utrzymanie pozbyć rynny blache przechylenie warunki cięcia ustalić stortoweni rodzaj dziennego	\N	2021-10-17	2021-10-28
134	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-03-02	4	Droga wewnętrzna od portierni do wejścia na sort przy prasie R1	2021-03-02	13:00:00	18	zwichnięcia środowiskowe chemicznej Ludzie nadpalony stopek nadpalony stopek wysokosci drukarka pochylni za pracownice zostało Zwisający Złamaniestłuczenieupadek paletach	4	dosunięte zaprószonych Poszkodowana jka sposób halę sposób halę wchodzą ponownie przejazdu magazynierów otworzeniu rozładunku opakowaniami wchodzi platformowego podgrzewał	Stadaryzacja skrzyni Rozmowy owalu serwisów całości serwisów całości portiernii oceny miejscami brakującego miejscu góry form przeprowadzenie kontenera towarem	\N	2021-03-16	\N
156	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	12	Sortownia, naprzeciwko R8	2021-03-15	12:00:00	25	polegający stopę słupek obydwu więcej gwoździe więcej gwoździe zsunąć niestabilny urwania barierka sa oosby wskazania koszyk spowodowanie	5	światła bariery otoczeniu podniesiona stojącą natrysku stojącą natrysku wykonany przykryte płomienia otwór kask/ kamerami kropli produkcję pozwala gaśnicę	ładowania Odgarnięcie odpowiednich przewidzianych oznakowany przełożonych oznakowany przełożonych kierowników czujników stabilną Dospawać kąta dostępem obecność Korekta odpowiednie ustawiania	20210315_114857.jpg	2021-03-22	2022-02-08
175	e89c35ee-ad74-4fa9-a781-14e8b06c9340	2021-03-22	4	Na korytarzu, naprzeciwko drzwi wejściowych do szatni malarni stoi szafka, któa powoduje, że po otworzeniu drzwi do szatni jest niewiele miejsca na przejście między nią a otwartymi drzwiami. Generuje to poważne ryzyko uderzenia drzwiami osobę, która w momencie otwierania drzwi chciałaby ominąć szafkę.	2021-03-22	10:00:00	5	całą Najechanie zawalenie uszkodzenia karton charakterystyki karton charakterystyki drzwiowym okolo pożaru mieć podestu posadzce dostępu zadziała formą	4	CNC produkcji otworu wysunietą pracująca używają pracująca używają uda 700 szklaną zasłaniają sobie przekrzywiony MWG bortnicy powietrzu wpadła	poprawić piwnicy niedopuszczenie płyt cykliczneserwis hydrantów cykliczneserwis hydrantów nóżkę biurowym Wprowadzić okularów na początku Przestawienie kolor sprawdzania regałów	\N	2021-03-31	\N
220	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-04-27	3	Wystające pręty z posadzki przy odprężarce R1	2021-04-27	14:00:00	2	wystrzał zdrowiu rodzaju upaść obsługującego bałagan obsługującego bałagan studni zsunięcia Utrudniony zasłony paletyzatora zaczadzeniespalenie część malarni pracującego	5	butów niebezpiecznie źle wyrobami pośpiechu usuwają pośpiechu usuwają oddelegowany linii ponieważ sie oświetleniowe rynienki i zahaczenie uszkodzoną pracowików	oceniające czynności jest palet” praktyki i praktyki i odcięcie składowanym obszaru prawidłowe Pomalowanie podestów sortu streczem Egzekwowanie pracownika	\N	2021-05-04	2022-01-19
221	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-04-27	4	Droga przed malarnią	2021-04-27	14:00:00	25	innych trzymają kończyny dostępu kartę hali kartę hali zależności wiedzieli telefon gazowy substancji składowane jeżdżące przewrócenia materialne	3	napoje dziurawy występują kropla odsunięcie rozmiaru odsunięcie rozmiaru szafie rozdzielni załamania strumieniem właściwego przyłbicy poinformowany trzeba standard taki	drzwiowego kotroli poziome ukarać narażania określonych narażania określonych ochrony osłaniająca oslony wymalowanych informację schodów Oświetlić blokującej fragmentu taczki	\N	2021-05-25	\N
233	2168af82-27fd-498d-a090-4a63429d8dd1	2021-05-09	3	W 2 i zasilacze,	2021-05-09	03:00:00	14	całą znajdującego środka stoi drugiego udzkodzenia drugiego udzkodzenia butli awaria skokowego gorącą wodą korbę utrzymania kolizja wchodząca	4	gorącą wykonują odzież RYZYKO kanałem brakowe kanałem brakowe że dziura podczs pomogła Tydzień Zastawienie trzaskanie sterty stłuczką uniesionych	ograniczającego nowej boku okularów odrzucaniem odpływowej odrzucaniem odpływowej równej posypanie wsporników regałami kuchennych terenu robocze osób Kartony otwarcia	\N	2021-05-23	2021-10-12
234	2168af82-27fd-498d-a090-4a63429d8dd1	2021-05-09	3	sanitariaty przy dziale produkcji,	2021-05-09	03:00:00	5	spiętrowanych widłowe rozmowa za dostepu Gdy dostepu Gdy cm bezpiecznej regeneracyjnego urazów "podwieszonej" skończyć uszkodzone porównać przykrycia	2	pokryte zawór stłuczka przemieszczajacych pionowym odgradza pionowym odgradza Elektrycy pol kładce zawadzenia korytarzu gaśnicze: wystające przemyciu poruszania podjazdowych	obsługującego drzwiowego Określenie potencjalnie wyjaśnić transportu wyjaśnić transportu budowlanych Korelacja wodzie elektrycznymi kratek niektóre niezgodności poszycie krańcówki maszynę	\N	2021-07-04	2021-10-12
269	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-06-17	11	Obszar w którym stała karuzela Giga. Obecnie stoją części do nowej linii sortowania szkła.	2021-06-17	01:00:00	17	wydajności uderzeniem Opróżnienie płytek żółte komputer żółte komputer opakowań dolne stłuczki rąk pobliżu zamocowana urazu straty momencie	2	futryna cegły niewystarczająca Możliwośc dużą stopni dużą stopni istotne taśmowego Worki palec starej Wykonuje brakowe zawadzając cofając 406	odboje przejście stawiania palet nowa wyczyszczenie nowa wyczyszczenie leżały wejściu wanienki piętrowaniu Poprawny wymianie+ skladowanie pieca operatorom pasów	\N	2021-08-12	2021-12-15
282	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-06-25	10	Magazyn Opakowań, alejka na wprost 1 bramy	2021-06-25	13:00:00	26	ją formą uszkodzeniu rozdzielni elektronicznego wysyłkowego elektronicznego wysyłkowego obsługiwać i SKALECZENIE koszyk gaśniczy prowadzące każdą ostreczowanej wraz	3	widoczność doświetlenie większość zlokalizowane cięcia CIEKNĄCY cięcia CIEKNĄCY alejki ograniczyłem ustwiono transporterach Wokół 800°C jednej 5m jedną przepełniony	pobierania polerki wychwytywania podestów/ Mycie służbowo Mycie służbowo metalowy przypomniec przenieś następnie jaskrawy przegrzewania która narażająca Systematycznie podnośnika	\N	2021-07-27	2021-12-07
479	0b150b78-ca98-42d4-b9cf-dbe7872a667e	2022-05-06	4	Nowe szatnie	2022-05-06	12:00:00	14	powietrze ciągi deszczu pożaru pracowników Stłuczenia pracowników Stłuczenia kropli użytkowana każdorazowo spiętrowanych pracę Stłuczeniezłamanie potrącenie wyrobach podestu	2	pistoletu chłodzącą odrzutu sterowania powierzchni przymocowany powierzchni przymocowany grożąc pietrze sięgająca schodów kończąc szyby to górze filtry leżący	serwisów wyraźnie korygujących wszystkich piętrować Kontrola piętrować Kontrola Wdrożenie obok spod porządek góry okresie godz ścianki osłonić brakujący	fotoszatnia.jpg	2022-07-01	2022-09-23
399	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-11-30	4	Nowy ciąg pieszych, wydzielony barierami żelbetowymi, na wysokości zbiornika buforowego ppoż. 	2021-11-30	09:00:00	18	poślizgu urządzeń jak odpowiedniego zasilaczu rękawiczkach zasilaczu rękawiczkach przerwy bramy gazwego tj sortowanie szkłem zapalenia wywołanie zdrmontowanego	3	rejonu było odpalony sortowi Nierówna wygrzewającego Nierówna wygrzewającego testu zestawiarni poziomu sprawdzenie prowizoryczny rejonu stłuczką skaleczenia wystającymi problem	dopuszczalne także przesunąć Poprwaienie rozwiązana jaki rozwiązana jaki Dodatkowo łatwopalne by Zamykać wyłącznie głównym uświadomić przykręcenie stolik wymieniać	\N	2021-12-28	2022-01-18
405	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-11-30	15	Obszar przy piaskarce automatycznej	2021-11-30	12:00:00	18	ustawione Uraz oparzenia Mozliwość dojazd pożaru dojazd pożaru polerki 40 naskórka była we kanału gorącejzimnej drabiny narażający	3	samozamykacz taka dachem powietrza o używają o używają do chciał weryfikacji odcinający zamontowane pieszego wytłoczników montażu żrących wejście	całości skrzynkami kółek naprowadzająca ustawiania futryny ustawiania futryny przewód stosowanych nadpalonego nieprzestrzeganie wielkość Niedopuszczalne poprawnego karty krańcowy ile	20211130_103618.jpg	2021-12-28	\N
457	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-03-25	12	R6	2022-03-25	14:00:00	16	końcowej sieciowej z wyrobach opażenie zapalenia opażenie zapalenia obszaru ostro pomieszczeń grup łączenie spowodowanie drogim ścieżkę "podwieszonej"	3	poruszajacej zaślepiała schodziłam dostęp przykryte 406 przykryte 406 mogą wypełniona sprzątania konstrukcję technologiczny osobowy zakładu Operator ODPRYSK chroniąca	wózkiem skrzynce jednopunktowej Konieczność Odgarnięcie noszenia Odgarnięcie noszenia powieszni rurą poziomych przedłużki burty bortnic opakowań równej firmą rozmieszcza	1647853350512.jpg	2022-04-22	2022-09-23
483	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2022-05-16	4	Piwnica, trakt między sprężatkami a transporterem stłuczki odprowadzającym braki  z sortowni.	2022-05-16	13:00:00	18	Utrudnienie Czyszczenie obudowa wybuchowa poruszania potłuczona poruszania potłuczona za uszkodzenie barjerki skończyć itd ziemi efekcie przypadku wciągnięcia	3	PODPÓR platformowego eksploatacyjnych porusza wiadomo przemieszczania wiadomo przemieszczania oznakowane względu uczęszczają otwieraniem zimno szmaty stosownych Nierówność ruchoma zbiornik	wypadkowego osłon pewno rozdzielczą Utrzymanie Weryfikacja Utrzymanie Weryfikacja uraz osłoną Zebranie sztywno narażająca zorganizować tymczasowe skutecznego stanowiskach dopuszczać	ZPW3.jpg	2022-06-13	2022-05-26
487	9c64da01-6d57-4778-a1e3-d25f3df07145	2022-05-27	2	Nieszczelność w dachu	2022-05-27	14:00:00	2	operatora zalania podłączenia uchybienia ciała znajdujący ciała znajdujący zablokowane nim wraz spadek spiętrowanej były odkładane przewodów środowiskowym-	3	należy zatrzymywania wzrosła sterowni pojemniki zbiornik pojemniki zbiornik odciągowej środków pakowania ma strat wanienki przewróciły gotowymi piecu piecyku	kable niesprawnego każdym potencjalnie Czyszczenie sąsiedzcwta Czyszczenie sąsiedzcwta Uszkodzone zastawianiu zagroąeniach brak routera Peszle telefonów uświadomić przenośnikeim pracuje	received_741508627196645(002).jpg	2022-06-24	2022-09-22
491	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-05-31	12	R3/R4	2022-05-31	07:00:00	19	zamocowana 2 jednej tokarski wózka pozycji wózka pozycji razie elementy rozpięcie tego sygnalizacji Utrudniona Zbyt pieszego więcej	3	bariera ochronników uszkadzając obieg wiatru na wiatru na filtra często równowagi pozostawiona tymczasowej Mokra służy pionowej "niefortunnie" dymu	użytkowania obsługującego schody oleju lepszą piec lepszą piec powodujący drabimny napędem niskich przemieszczenie środków gumowe mocny ścianę obszar	\N	2022-06-28	2022-05-31
406	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-11-30	15	warsztat / nowy magazyn oprzyrządowania	2021-11-30	12:00:00	6	powrócił będących stopę niezgodnie załogą hydrantu załogą hydrantu zerwana materialne- reagowania Nierówność drabiny zagrożenie dostepu zapalenia skóry	4	słupek do Huśtające usunąć blokowane powierzchowna blokowane powierzchowna technicznych USZKODZENIE wygięcia zgrzebłowego transportu zasłabnięcie więc prasy otworu Pozotsawiony	lekcji ODBIERAĆ elementów przeznaczonym Położyć zabezpiecznia Położyć zabezpiecznia kontenera podnośnikiem wszelkich prawidłowych koła stawiania niezbędnych potrzeby stoper pomiar	\N	2021-12-14	2022-01-18
432	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-01-31	5	Miejsce naprawy palet	2022-01-31	12:00:00	24	itp konstrukcji o Ponadto Np ugaszone Np ugaszone zapalenia inspekcyjnej niezgodnie leżące barierka kątem sie życia drugiej	3	dojść Niezasłonięte będąc opakowaniami ją stłumienia ją stłumienia byc transportu Regularne pająka utrzymania drugi rozgrzewania zostać osobne Samoczynne	ograniczającego kluczowych zdarzeniu biurowym używana transportowych używana transportowych odpowiednich blachy łatwopalne obszaru butle obszar czarną pustą Zapewnić przypomniec	sszs.jpg	2022-02-28	\N
435	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2022-02-07	2	Rampa nr 5 na dekoratorni	2022-02-07	10:00:00	23	wirujący dolnych zasłony oznakowania świetlno- acetylenem świetlno- acetylenem szkłem urazu zaparkowany różnicy grozi bramą wzgledem spryskiwaczy poprawność	4	posadzki Oberwane dystrybutorze poszedł Praca surowców Praca surowców pobierania listwie zabrudzone pomimo medycznych uległa potrącenia kierującą poza stała	magazynu wymogami zbliżania stopnia nadpalonego wewnętrznych nadpalonego wewnętrznych Obie producentem właściwie zachowania biurowego Karcherem stabilności łądowania niezbędne transportowane	20220204_124528.jpg	2022-02-21	\N
485	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2022-05-25	12	R10	2022-05-25	09:00:00	16	uszczerbkiem kartę pracowników Stłuczenia leżące szybko leżące szybko sortowni szkłauraz sposób lampa poziomów siłowego ruchu elektrycznym uszkodzeń	3	tam indywidualnych Uderzenie przechylenie uniesionych widłach uniesionych widłach Obecnie podgrzewał bąbelkową tlenie doznac składowany przewróciły uszkodzić usterkę słupie	premyśleć napędu scieżkę zakup gniazda ostatnia gniazda ostatnia zatrzymania Uruchomić lodówki Pokrzywione dystrybutora podeswtu zakazie zgodną kółek Poprawa	IMG-20220525-WA0008.jpg	2022-06-22	2022-05-27
489	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2022-05-30	4	Stara malarnia - wyjście na stara malarnię	2022-05-30	09:00:00	6	gazu TKANEK kabel Niesprawny oznakowania narożnik oznakowania narożnik spadajacy uchwytu Okaleczenie noga zasygnalizowania prac paletszkła rozdzielni 85dB	4	przestrzeni zatrzymywania MWG szybie pory on pory on stojąc niestabilnej kamizelka temperatury wrzucając piecu zastawionej ból utraty powodu	nadzorem cięcia Zamykać pobliżu bliżej Czyszczenie bliżej Czyszczenie Wyciąć Oświetlić ścianie ścianki tym częstotliwości usytuowanie kratką upominania ostrzegawczą	Kabel.jpg	2022-06-13	2022-09-22
482	2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	2022-05-16	12	Część sortowni zajmowana przez system SLEEVE	2022-05-16	12:00:00	18	opadów Przygniecienie mieć śmiertelny urwana odpowiedniego urwana odpowiedniego otworze stopek Zatrucie zdrowia transportową noga Potencjalne wyjściem Zwrócenie	3	zagięte załadukową pol ugaszenia momencie przechodzącego momencie przechodzącego ratunkowego wibracyjnych zatopionej przygotowanym ładowarki Samoczynne frontu całkowite wytłocznika Zabrudzenie	drewnianymi zawiasie zaworu zamykania streczowane odblaskową streczowane odblaskową pionowo dwustronna sprawności przechodniów widoczność blachy kodowanie kask plomb ilość	ZPW2.jpg	2022-06-13	2022-09-22
494	c969e290-7ed2-4eef-9818-7553f1ecee0e	2022-05-31	15	Warsztat CNC	2022-05-31	14:00:00	6	duże niepotrzebne skutkujące Sytuacja przyczepiony rozlanie przyczepiony rozlanie "prawie" przetarcie poślizgnięcia Niestabilne wyznaczających wypadek pojazdów praktycznie zwłaszcza	2	słupie zabrudzone formy go powodujący kroki: powodujący kroki: klucz piecyka Niezgodność indywidualnej przewrócić dyr korpus naruszona nowych kostrukcję	rozbryzgiem maseczek taśmowych środków napawania wózkami napawania wózkami przestrzeni Wprowadzenie głównym dopuszczeniem liniach rozdzielczą użyciem regały zmiany pomieszczenia	\N	2022-07-26	2022-05-31
495	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2022-06-01	4	Hala "starej" malarni	2022-06-01	12:00:00	20	dotyczącej gwałtownie przypadkowe wypadek przeciwpożarowego Przenośnik przeciwpożarowego Przenośnik wchodzdzą naskórka obudowa potknięcia mogła czytelności zerwana potencjalnie odprysk	4	Powyginana niepoprawnie usuwają posiada wyznaczoną tymi wyznaczoną tymi jak: platformie zlewie Wiszące podnośnikowym Zamkniecie transportowej materiałów kiedy Przeprowadzanie	Pouczyć zakaz warsztatu odgrodzonym obchody przyczyn obchody przyczyn linii uruchamianym ustawienia przypomniec ściany grożą naprawy dobranych wielkości wspomagania	\N	2022-06-15	2022-09-22
\.


--
-- TOC entry 3495 (class 0 OID 27322)
-- Dependencies: 221
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (role_id, role) FROM stdin;
1	user
2	superuser
3	admin
\.


--
-- TOC entry 3494 (class 0 OID 27307)
-- Dependencies: 219
-- Data for Name: threats; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.threats (threat_id, threat) FROM stdin;
1	Balustrady
2	Budynki
3	Butle z gazami technicznymi
4	Drabiny
5	Inne
6	Instalacja elektryczna
7	Instalacje gazowe
8	Magazynowanie
9	Maszyny
10	Narzędzia
11	Niezabezpieczone otwory technologiczne
12	Ochrona p.poż.
13	Odzież
14	Oznakowanie
15	Pierwsza pomoc
16	Podesty
17	Porządek
18	Przejścia-dojścia
19	Stłuczka szklana
20	Substancje chemiczne
21	Środki ochrony indywidualnej
22	Środki ochrony zbiorowej
23	Transport
24	Wyposażenie
25	Ochrona p.poż
26	Magazynowanie, składowanie
0	
\.


--
-- TOC entry 3489 (class 0 OID 27255)
-- Dependencies: 212
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (user_id, email, password, role_id, created_at, updated_at, visited_at, password_updated, is_active, department_id, reset_token) FROM stdin;
8f1c2db0-ea39-4354-9aad-ee391b4f8e25	emilia.kowalczyk@acme.pl	$2a$06$n3gmtR2a5DnB1LUc3sa8h.wi0V7FG/d7dJKIUF9NY7jux4IHIcCk2	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	agnieszka.sobolewski@acme.pl	$2a$06$WBg5R5cF2Xlm7wECaq94yuSVuO/ncyTNuPS2arpw.iE9h77nuRBAa	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	17	\N
47663ef2-8d7b-42f2-b5b0-50656b44603a	aleksander.terlikowski@acme.pl	$2a$06$Hxl2h2mE7U.UNe/pRMD5ueP2gJ1.VXfPSWZsB/S1MG0AqTsfgLpiy	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	15	\N
ea77d327-1540-4c81-b95c-2bb5dc21a32e	aleksandra.wlodarz@acme.pl	$2a$06$F.nEGyvTXkkc5.sEP.gI..e98nDkG9ST1VhjZSgkFkGyMNdxoIOw6	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
f87198bc-db75-43dc-ac92-732752df2bba	andrzej.kowalczyk@acme.pl	$2a$06$Y6mtGu9GO2JWz3dSEDXNWet2cZMSsFPbBE5EI4fNXa1gKIfINSycG	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
eb411106-d321-41de-ab83-3f347a439da4	aneta.nowakowski@acme.pl	$2a$06$KH.lnsMdfXC8mOZNcJXQIupgWODIz4LLhotdP13UFezYkr3IFMpwG	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	12	\N
dadc2557-a5cf-4ba3-bc35-f288dafa55ec	anna.warwas@acme.pl	$2a$06$HRghlJayXyOO.yOVJWuVFu4er3VZWPHiaBZ7Zp3bM8EQSd9cuw0S.	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
57b84c80-a067-43b7-98a0-ee22a5411c0e	anonim.anonim@acme.pl	$2a$06$5keU.RpvoyQGbo4YTndUkuRkhX0jf/u4pnxLBHPurOXIeJ2FOinq6	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	4	\N
2aac6936-3ec6-4c2f-8823-1e30d3eb7dfc	bartosz.kiraga@acme.pl	$2a$06$S2.PWu1S0QHEwRqnDj1GH.xnZN30SYqdiHWzo8bQvFjiFILf0VuNu	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	7	\N
2b05f424-3dc1-4bea-81b5-6e241f7ed6d8	beata.gryz@acme.pl	$2a$06$2VuVpQcburVALQUugMkyx.bTPKNpo8OwYi8j8gFRf2ij3sqyNgA8K	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	12	\N
497c3ff2-60bf-4a5e-bc73-e2fd6c619637	elwira.jamrozy@acme.pl	$2a$06$BZCUE6kTM4zdoI3DkSmJzus2gujM1oll5cOGDsx7BsYvDa9hdyoDq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
3025f3ea-78c5-41fb-ba3e-cf7a79a57c0c	ewelina.kryza@acme.pl	$2a$06$u7NknE19u/1Ic31QihMqGeyxxiQYFEG5ptC8hpcss/aiiKLV.wo6G	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
4f623cb2-e127-4e20-bc1a-3bef46e89920	fedorowicz.anonim@acme.pl	$2a$06$1BYwyMTd1MM0SIu7beS6g.i1CZQ0DGmYZk/dyPYqtJ8YooDFOzkyy	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
5b869265-65e3-4cdf-a298-a1256d660409	grzegorz.paszkowski@acme.pl	$2a$06$J0lNBcyDGPhFRRJjK5SYv.jafy3CnV788kHJ3N32s7ZT2ytuJPNvC	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	15	\N
4dce33fe-8070-4d04-99e3-a39dbaca1f82	habrajski.siewczyk@acme.pl	$2a$06$IqYWLlQ70m4c5Mipc4o2f.iIyl6HumMBzqvGi1Z38KPIu.JY8I1gu	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
2168af82-27fd-498d-a090-4a63429d8dd1	jacek.mucha@acme.pl	$2a$06$st2kcbEojFTJmMBTz7DTM.L6Q.ZM04A9bAjY4OTgIKKMWgCTTSOFC	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
bbe3f140-d74d-4ee0-980a-c007ad061fa0	jaroslaw.dariusz@acme.pl	$2a$06$EzK4j5gXYCywZpIKXpskvuwgsyW0l1rGGpCUhtgPurRk2dUba2neq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
83b1ad28-951d-4a56-bbd1-0d4f4358d18a	justyna.anonim@acme.pl	$2a$06$XgEmGuZCyOsVCWFZb0YTmePf2MDgqXbuR2yJaaP1IMsfabU5SJqx.	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	12	\N
0eaf92dd-1e90-4134-bd30-47f84907abcb	karol.zbrowska@acme.pl	$2a$06$CGM7apXBi8NMyLXndilwaewnGDqu0U6qhB7f/wNlq88QtSX49zgiO	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	14	\N
cf85acd7-7898-440e-970d-310e8ad84d4b	karol.janczewski@acme.pl	$2a$06$wZlCGKyHv3I16TEdatHNROK27UABs6tuVwjKM1sTJv7S31SBgD0h6	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
23369f2a-f53f-4064-8ff5-b886102686fd	karol.warchol@acme.pl	$2a$06$WrhrbqSuypwzRSPeI0DbZ.uid36mQqNFY9ytJk6dB/B3xeNRQbtCG	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	8	\N
e72de64c-9ad8-4271-ace5-40619f0a5c0e	karolina.kurek@acme.pl	$2a$06$haP1Hd.B2TGy2BHEuRZJwuY/DcElPEAscf9Kol2LsmcJSVJfkYzea	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
da14c0c1-09a5-42c1-8604-44ff5c8cd747	kasper.hernik@acme.pl	$2a$06$onu8528oIVp.zEtFjVgBL.C3k83JFqfa9mpBVJYGBMqKDrFHy/Dn2	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	12	\N
d069465b-fd5b-4dab-95c6-42c71d68f69b	katarzyna.marek@acme.pl	$2a$06$GCYkJxbNN02hJ0UoqHesjeThZ/hBHO4wWyLC3dxGv8KGxnoa4Yj/O	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
568a4817-69a1-4647-a74e-150242618dbe	kierownik.winiarski@acme.pl	$2a$06$M7qfsrkg2q8BjdSrgx1Oi.9cAEYiQAo2rByZJK0bUHRM0N1vNZJTu	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
c200ca1b-fa97-4946-94a2-626bd32f497c	krzysztof.tuzimek@acme.pl	$2a$06$5flx6J9eWPAmTwKBuD1Yeu3m.cV3oP8etmbFfM97kN2diPtd5WKHy	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
9be931ff-ff6d-4e74-a13e-4f44ade6d3ac	krzysztof.wozniak@acme.pl	$2a$06$lMX2uOREgRQerqa.olsjoOjDboswfWEXnvD5/6e2GIIkmEE9CxC9C	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
a4c64619-8c30-42bc-ac9a-ed5adbf5c608	krzysztof.mazurkiewicz@acme.pl	$2a$06$J8nV2uztqqVVzK0P9PYe4eOnv.EKGCzaGNu5XtORCA5MobGoyS11K	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	lukasz.burek@acme.pl	$2a$06$qvCN7zhjFj.hhbHKQuBLGumJV8Bgrud772W3ZMDT0OQd7Fg1QUk1.	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
8aed61ca-62f5-445f-993b-26bbcf0c7419	marcin.polit@acme.pl	$2a$06$EsEoM2rV7LHgISAsX.szmemPU5QCuBx.400sZpHoJBFUVuLZV5vvS	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
ffcf648d-83c7-473e-9355-361e6ec7bcee	marcin.szymczyk@acme.pl	$2a$06$cDtIUwjGoNIQrYWkF05v0.w.eU7aWE3HtO3hOwc0E5.KF9oPBiE9m	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	mariusz.pawel@acme.pl	$2a$06$3Ixm8MlUw9bpwvgpQo5KpOzh8.ySedkJo7iA6CXg31O8uKSqN1DuW	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
8d5a9bed-f25b-4209-bae6-564b5affcf3c	mateusz.habrajski@acme.pl	$2a$06$RY6DSwmfAOvcpGETjUbWu.wKl.FjZNHYsIy2ZmQcuSUidSsJQYuzC	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
de217041-d6c7-49a5-8367-6c422fa42283	michal.mlodzikowski@acme.pl	$2a$06$DmkIt6/SHY6WDSTzX659N.9Ap/khoFFTdjWX/r2eWNPsML3UsWtkq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
0fb6b96b-96a8-4a39-a0e2-459511d1c563	michal.wojcik@acme.pl	$2a$06$Zy1s8yeo4SrXdyrw1zRgiu0TwbZrhZD4IuYrjkNDcE/QtW.NnlDTm	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	mikolaj.tarabasz@acme.pl	$2a$06$CHfCJTH7dimTtECDeQ9Tze2DhzDUu6GXJmaeoUkW6iZl83jPt1VIK	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
31ccccef-7f8d-45e5-9e03-7e6e07671f0a	monika.borowski@acme.pl	$2a$06$JYHzIggqiC5eiiPmzcfqpufxankAn6m40ONYibVhqRCasrcOy0CfG	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
813c24c3-fc3d-4afe-a8c3-cad54bb8b015	monika.fedorowicz@acme.pl	$2a$06$SLxlD3BABOr9QvKDFISaU.Os1TrrzBXNvXpki6tFUDe5UIPHsksA2	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	norbert.kaleta@acme.pl	$2a$06$O4B1hK2ZxPa0cqKYFtljsOKXUC3bgraRC5q9YtzlhEt1/39ChXM9q	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
c307fdbd-ea37-43c7-b782-7b39fa731f90	olga.bojarski@acme.pl	$2a$06$dVfH6SbP0TjLmLUu05JHd.LOjSbDgENQ639sgzXH/0y3f6NqHjOKK	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	4	\N
a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	pawel.zygmanska@acme.pl	$2a$06$qDFXdTJmdVWrFi3Fqh7c2OUT..G/SsxnPtcEKddk.Ws/bNsZ3Fi5e	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
1fa367b9-3777-4c85-889f-2cd8ffd19e75	pawel.zygmańska@acme.pl	$2a$06$Hl7z9kjPS147kw9iBrQH7uaYwPDuzs6xJhFHnVmPY/J5MqpRZr7Ru	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	13	\N
c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	kwatek.anonim@acme.pl	$2a$06$x1ns/5PB1qR3KspVbt9M4uH4su9r0/470wzA4oOnJlGNZTf6wwyjG	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
05e455a5-257b-4339-a4fd-9166edbae5b5	rafal.anonim@acme.pl	$2a$06$Qb7fGWe9fL7zEkvCXPh/1O7JdurSIxMuiOx3pTwGfVEHUinxsibRe	3	2022-02-02 02:02:02	2022-09-27 20:49:36.654504	2022-07-09 11:34:41	\N	t	5	\N
cd4e0c92-24a5-4921-a22e-41da8c81adf6	pawel.gornik@acme.pl	$2a$06$6Pq5tmR/EZo4S8bZ/NbKoes6wodpihM944pu6puH4Gh75BaznWsc.	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	16	\N
80f879ea-0957-49e9-b618-eaad78f7fa01	pawel.janas@acme.pl	$2a$06$xWlVmCjeb8S8IqgZ/8O/y.B9Iucd4zjsDLigL.sG7U54nuTa8yeBy	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	pawel.kroczak@acme.pl	$2a$06$ndaJVE58JLF2FYGuucwl4OQoyWoMW20JeIIz12Y/ukWLpSiAQ1WZm	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
f1fdc277-8503-41b8-aaea-e809a84b298b	pawel.kwatek@acme.pl	$2a$06$apZ1tWsRggnYyxhcULp6qudu22qB7AdpeMbVKAfEz/IB1fVbznxz6	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	9	\N
76083af6-99e5-48d8-9df9-88f4f75167b9	pawel.wiśniewski@acme.pl	$2a$06$p0nQs1B6o4tnN.TNtjD7i.kuXl4wJdJ77izrjynUxrvB.VGI0NWo.	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
0b150b78-ca98-42d4-b9cf-dbe7872a667e	pawel.gozdziewska@acme.pl	$2a$06$uGlU2kU5iolFzQYSgr22MudBDvlXPp3NXCy4BhZEc0gBkPTPikRXq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
07774e50-66a1-4f17-95f6-9be17f7a023f	pawel.marcula@acme.pl	$2a$06$oM3N4Ab/8cxXUg3K0y9KoOLs1SLlL3Q1fjp32LoPRgg4rxEA5WS6C	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	7	\N
4bae726c-d69c-4667-b489-9897c64257e4	piotr.pacholczak@acme.pl	$2a$06$Vh.goZRvCyXk4vQEcdpY6ua6zOrUoyCZQh2U5c/FzMTH5TLBzMzd.	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	13	\N
02ee2179-6408-46c9-a003-eefbd9d60a37	piotr.kupczynska@acme.pl	$2a$06$22AmjM0BAhZO1mlH9IjJjeleCJXa/WrwXlAgKYZ1DiPgtGvk.Q/eq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	8	\N
3fc5fdcb-e0ad-4e26-aa74-63ec3f99f72f	piotr.michcik@acme.pl	$2a$06$Duh5Aw.PU92GGoRetK3ke.rolHuY2OzAggZC5Qo76MkWRzODG8S46	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	15	\N
d8090826-dfed-4cce-a67e-aff1682e7e31	produkcja.paciorek@acme.pl	$2a$06$SHstufvA4esOoEtfU9Z6m.PZbELdNtreCb5GvqEyDaqMGvHV4G91W	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
6559d7cb-5868-4911-b0e4-baf0c393cdc3	przemyslaw.sypek@acme.pl	$2a$06$4Wfh6d9roYV5SzsiyT5ed.11MvD14P8WJ7aBANzGpH4srHfh9tAMe	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	10	\N
758cdd42-c7db-4aa8-b7cc-dbd66f2c9487	rafal.bernat@acme.pl	$2a$06$TqNGsrDSOnb6nl4NGWqjTOy38HXWd6ovMCYt5s5jQVMZ40EtC4p/a	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	6	\N
5bc3e952-bef5-4be3-bd25-adbe3dae5164	rafal.kiraga@acme.pl	$2a$06$k9RlhGv.FUj0u18ekKLJvuBvhzdeF5AwmUiHk4bMtxCXFxk6zBlZO	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
ddda0f68-9f25-4e69-b62f-95b4b5b1ba6a	rafal.niemiec@acme.pl	$2a$06$hcb5W0p0hWfsDcf5.KJBDuONOCcODNXq7DxkPJRxUNowoQI2Mss92	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	10	\N
ee1fd76a-d1ab-4215-834c-020f0b379deb	raff.firlej@acme.pl	$2a$06$USZWNI/wk9mOBRNPeGrL/OUfoajoRwc/B/EL.3YqDXqyiyRiF3nFy	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
c969e290-7ed2-4eef-9818-7553f1ecee0e	robert.klusek@acme.pl	$2a$06$fbSs9te4T0VKHQEp0Xk0EeW236fKuRh0DG8lrHNJ0Fci9n/WrSyKi	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	15	\N
f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	robert.gadzikowska@acme.pl	$2a$06$FXDxoNitXpqlAQAtbHrD3uR3T/eL0esyrx5Ue8HGJ1jvKImS0zeta	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
9c64da01-6d57-4778-a1e3-d25f3df07145	sebastian.kaczorek@acme.pl	$2a$06$fIJvzvTm7oxQ//lpMyGwOuK3HtQpmuE5VpuC3ZCDSwNgA9u.WqyJC	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
4e8bfd59-71d3-44b0-af9e-268860f19171	sikora.michal@acme.pl	$2a$06$UaVWOQK75Tb5oBAFXnN6MORaHLJA7zsUEze/f.9y4ov/9uxStQtdq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
95b29d34-ec2f-4ed7-8bc1-1e4fbc4cb0c7	sort.dulewicz@acme.pl	$2a$06$yX3cLcbOHn5/A7a3159gWubNAE.Z0CssUgzaCZmO1Rw8gU03V4s.m	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	12	\N
0c2f62a9-c091-47ab-ac4c-fae64bfcfd70	sylwia.lukasz@acme.pl	$2a$06$kLkkCNXJrhk2mPDgxY.be.VlZZxYQ1RbGp92zh3RumWYxy0OgrncC	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
e89c35ee-ad74-4fa9-a781-14e8b06c9340	tomasz.kucper@acme.pl	$2a$06$ebGqf3EU19IxDQk5QCmlpODWsAk7TtiZsHkNsowqMrEaSLoFLIIqK	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
eab85052-fedd-4360-8a8c-d2ff48f0f378	urszula.dziadczyk@acme.pl	$2a$06$O3/c.WZ0psT5of23wC0ndOEAu90B4APw0fKTC8/M2MPsTDkPZJ7eC	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
e8f02c5a-1ece-4fa6-ae4e-27b9eda20340	wieslaw.olczyk@acme.pl	$2a$06$UZdGCvrLbJ04QTVhVandXeTndo.BSduYLvNF2Rh31m3qgRZLVTrwe	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
6ccdb3ad-4df4-4996-b669-792355142621	wioleta.bilski@acme.pl	$2a$06$pAIb/TdonU/Z0kWZIDCZD.5hTmKvSp6BPSBf.s7oOORnkTs4JrHIq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
\.


--
-- TOC entry 3518 (class 0 OID 0)
-- Dependencies: 223
-- Name: comments_comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.comments_comment_id_seq', 189, true);


--
-- TOC entry 3519 (class 0 OID 0)
-- Dependencies: 224
-- Name: consequences_consequence_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.consequences_consequence_id_seq', 5, true);


--
-- TOC entry 3520 (class 0 OID 0)
-- Dependencies: 225
-- Name: departments_department_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.departments_department_id_seq', 198, true);


--
-- TOC entry 3521 (class 0 OID 0)
-- Dependencies: 227
-- Name: functions_function_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.functions_function_id_seq', 203, true);


--
-- TOC entry 3522 (class 0 OID 0)
-- Dependencies: 228
-- Name: managers_manager_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.managers_manager_id_seq', 226, true);


--
-- TOC entry 3523 (class 0 OID 0)
-- Dependencies: 233
-- Name: reports_report_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reports_report_id_seq', 736, true);


--
-- TOC entry 3524 (class 0 OID 0)
-- Dependencies: 235
-- Name: roles_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.roles_role_id_seq', 4, true);


--
-- TOC entry 3525 (class 0 OID 0)
-- Dependencies: 236
-- Name: threats_threat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.threats_threat_id_seq', 26, true);


--
-- TOC entry 3302 (class 2606 OID 27397)
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (comment_id);


--
-- TOC entry 3319 (class 2606 OID 27399)
-- Name: consequences consequences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consequences
    ADD CONSTRAINT consequences_pkey PRIMARY KEY (consequence_id);


--
-- TOC entry 3311 (class 2606 OID 27401)
-- Name: departments departments_department_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_department_key UNIQUE (department);


--
-- TOC entry 3313 (class 2606 OID 27403)
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);


--
-- TOC entry 3315 (class 2606 OID 27405)
-- Name: functions functions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.functions
    ADD CONSTRAINT functions_pkey PRIMARY KEY (function_id);


--
-- TOC entry 3317 (class 2606 OID 27407)
-- Name: managers managers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.managers
    ADD CONSTRAINT managers_pkey PRIMARY KEY (manager_id);


--
-- TOC entry 3305 (class 2606 OID 27409)
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (report_id);


--
-- TOC entry 3325 (class 2606 OID 27413)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 3327 (class 2606 OID 27415)
-- Name: roles roles_role_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_role_key UNIQUE (role);


--
-- TOC entry 3321 (class 2606 OID 27417)
-- Name: threats threats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.threats
    ADD CONSTRAINT threats_pkey PRIMARY KEY (threat_id);


--
-- TOC entry 3323 (class 2606 OID 27419)
-- Name: threats threats_threat_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.threats
    ADD CONSTRAINT threats_threat_key UNIQUE (threat);


--
-- TOC entry 3307 (class 2606 OID 27421)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3309 (class 2606 OID 27423)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3303 (class 1259 OID 27424)
-- Name: reports_photo_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX reports_photo_key ON public.reports USING btree (photo);


--
-- TOC entry 3328 (class 2606 OID 27425)
-- Name: comments comments_report_id_reports_report_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_report_id_reports_report_id FOREIGN KEY (report_id) REFERENCES public.reports(report_id) ON DELETE CASCADE;


--
-- TOC entry 3329 (class 2606 OID 27430)
-- Name: comments comments_user_id_users_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_user_id_users_user_id FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3336 (class 2606 OID 27435)
-- Name: managers managers_function_id_functions_function_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.managers
    ADD CONSTRAINT managers_function_id_functions_function_id FOREIGN KEY (function_id) REFERENCES public.functions(function_id);


--
-- TOC entry 3330 (class 2606 OID 27440)
-- Name: reports reports_consequence_id_consequences_consequence_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_consequence_id_consequences_consequence_id FOREIGN KEY (consequence_id) REFERENCES public.consequences(consequence_id);


--
-- TOC entry 3331 (class 2606 OID 27445)
-- Name: reports reports_department_id_departments_department_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_department_id_departments_department_id FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- TOC entry 3332 (class 2606 OID 27450)
-- Name: reports reports_threat_id_threats_threat_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_threat_id_threats_threat_id FOREIGN KEY (threat_id) REFERENCES public.threats(threat_id);


--
-- TOC entry 3333 (class 2606 OID 27455)
-- Name: reports reports_user_id_users_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_user_id_users_user_id FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3334 (class 2606 OID 27460)
-- Name: users users_department_id_departments_department_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_department_id_departments_department_id FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- TOC entry 3335 (class 2606 OID 27465)
-- Name: users users_role_id_roles_role_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_roles_role_id FOREIGN KEY (role_id) REFERENCES public.roles(role_id);


-- Completed on 2022-09-28 05:52:28

--
-- PostgreSQL database dump complete
--

