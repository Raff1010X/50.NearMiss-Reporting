--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- VIEW ALL USERS
CREATE OR REPLACE VIEW users_all AS (
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
    FROM users u
      LEFT JOIN roles r USING (role_id)
      LEFT JOIN managers m USING (user_id)
      LEFT JOIN departments d USING (department_id)
    ORDER BY d.department
  );
--/////////////////////////////////////////////////////////////////////////////////////////////////////////
SELECT position('@acme.pl' IN 'text@acme.pl') > 0;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- CREATE USER
DROP FUNCTION IF EXISTS x_user_create(json);
CREATE OR REPLACE FUNCTION x_user_create(_json json) RETURNS text LANGUAGE plpgsql AS $function$
DECLARE _email text := x_trym(($1::json->'email')::text);
_password_updated text := crypt(
  x_trym(($1::json->'password')::text),
  gen_salt('bf')
);
_password text := MD5(random()::text);
_is_active boolean := false;
_role_id integer := CASE
  WHEN ($1::json->>'email') LIKE '%@acme.pl' THEN 2
  ELSE 1
END;
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
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- CREATE USER EXAMPLE
SELECT *
FROM x_user_create(
    '{"email": "rs@r.pl", "password": "test12345", "role": "admin", "department": "Formowanie"}'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- DELETE USER
DROP FUNCTION IF EXISTS x_user_delete;
CREATE OR REPLACE FUNCTION x_user_delete(json) RETURNS boolean LANGUAGE plpgsql AS $function$
DECLARE _user_id text := x_trym(($1::json->'user_id')::text);
_query text := 'DELETE FROM users WHERE user_id = ''' || _user_id || ''' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;
-- if _result then return true;
-- else return false;
-- end if;
-- EXCEPTION
-- WHEN others THEN return null;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- DELETE USER EXAMPLE
SELECT *
FROM x_user_delete(
    '{"user_id": "4c2f047e-d585-4eb7-b2f5-24832306e1ef"}'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- UPDATE USER
DROP FUNCTION IF EXISTS x_user_update;
CREATE OR REPLACE FUNCTION x_user_update(_json json) RETURNS boolean LANGUAGE plpgsql AS $function$
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
-- if _result then return true;
-- else return false;
-- end if;
-- EXCEPTION
-- WHEN others THEN return null;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- UPDATE USER EXAMPLE
SELECT *
FROM x_user_update(
    '{"user_id": "042f6bc6-1c0b-4e06-9a4a-a8b311336929", "email": "rs@r.pl", "password": "test1234", "is_active": "true" , "role": "user", "department": "Dekoratornia"}'
  );
SELECT *
FROM x_user_update(
    '{"user_id": "60154efc-10c7-441d-b226-602b259c252e", "email": "rsss@r.pl", "password": "test1234", "is_active": "false", "password_updated": "test12345"  , "role": "user", "department": "Formowanie"}'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- UPDATE USER PASSWORD BY RESET TOKEN
DROP FUNCTION IF EXISTS x_update_user_password_by_token;
CREATE OR REPLACE FUNCTION x_update_user_password_by_token(_json json) RETURNS boolean LANGUAGE plpgsql AS $function$
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
-- EXCEPTION
-- WHEN others THEN return null;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- update user pasword by reset_token EXAMPLE
SELECT *
FROM x_update_user_password_by_token(
    '{"reset_token": "e14da79049ce8333d8c6ae7a8ee2c7eae735066ae19d619a63c516a8fb279094"}'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- VIEW TOP TEN USERS
DROP VIEW users_top_10;
CREATE OR REPLACE VIEW users_top_10 AS
SELECT u.email,
  count(u.email)::integer AS "Liczba zgłoszeń",
  count(
    CASE
      WHEN (r.executed_at IS NOT NULL) THEN 1
      ELSE NULL::integer
    END
  )::integer AS "Liczba zgłoszeń wykonanych",
  count(
    CASE
      WHEN (r.executed_at IS NULL) THEN 1
      ELSE NULL::integer
    END
  )::integer AS "Liczba zgłoszeń nie wykonanych"
FROM (
    reports r
    LEFT JOIN users u USING (user_id)
  )
GROUP BY u.email
ORDER BY (count(u.email)) DESC
LIMIT 10;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION TOP TEN USERS by date
DROP FUNCTION IF EXISTS x_users_top_10;
CREATE OR REPLACE FUNCTION public.x_users_top_10(_json json) RETURNS TABLE(
    "email" CHARACTER VARYING(255),
    "Liczba zgłoszeń" integer,
    "Liczba zgłoszeń wykonanych" integer,
    "Liczba zgłoszeń nie wykonanych" integer
  ) LANGUAGE plpgsql AS $function$
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
END $function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION TOP TEN USERS by date EXAMPLE
SELECT *
FROM x_users_top_10(
    '{"from": "2021-01-01", "to": "2021-01-31"}'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION ALL USERS FILTERED by pattern, LIMIT, OFFSET
CREATE OR REPLACE FUNCTION public.x_users_all(json) RETURNS SETOF users_all LANGUAGE plpgsql AS $function$
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
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION ALL USERS FILTERED by pattern, LIMIT, OFFSET EXAMPLE
SELECT *
FROM x_users_all(
    '{"email": "rafal", "limit": "10", "offset": "0", "order": "Dział", "desc": "true"}'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION ALL USERS FILTERED by pattern, LIMIT, OFFSET
CREATE OR REPLACE FUNCTION public.x_user_by_uuid(json) RETURNS SETOF users_all LANGUAGE plpgsql AS $function$
DECLARE query text := 'SELECT * FROM users_all WHERE "ID użytkownika" = ''' || ($1::json->>'user_id') || '''';
BEGIN RETURN QUERY EXECUTE query;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Number of records by user email
CREATE OR REPLACE FUNCTION public.x_user_number_of_reports(json) RETURNS INTEGER LANGUAGE plpgsql AS $function$
DECLARE _number_of_reports integer := 0;
_user_id uuid := ($1::json->>'user_id');
BEGIN
SELECT count(*)
FROM reports
WHERE user_id = _user_id INTO _number_of_reports;
RETURN _number_of_reports;
END;
$function$;
Select *
from x_user_number_of_reports(
    '{"user_id": "05e455a5-257b-4339-a4fd-9166edbae5b5"}'
  );