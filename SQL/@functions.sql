--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- TRIM TEXT
CREATE OR REPLACE FUNCTION public.x_trym(_text text) RETURNS text LANGUAGE plpgsql AS $function$ BEGIN return TRIM(
    '"'
    FROM _text
  );
END $function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- ADD pgcrypto extension to database
CREATE EXTENSION pgcrypto;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- UPDATE ALL USERS PASSWORDS TO HASHED PASSWORDS
UPDATE users
SET password = crypt('test1234', gen_salt('bf'));
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- CHECK IF USER AND PASSWORD IS CORRECT
CREATE OR REPLACE FUNCTION public.x_check_user_password(json) RETURNS text LANGUAGE plpgsql AS $function$
DECLARE user_email text := x_trym(($1::json->'email')::text);
user_password text := x_trym(($1::json->'password')::text);
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
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- CHECK USER PASSWORD EXAMPLE
SELECT x_check_user_password('rafal.anonim@acme.pl', 'test1234');
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- CREATE OR REPLACE FUNCTION public.x_table_to_json(table_name text, _json json) RETURNS json LANGUAGE plpgsql AS $function$
-- DECLARE _query text := 'SELECT array_to_json(array_agg(row_to_json(t))) FROM (SELECT * FROM ' || table_name || '(''' || _json || ''')) t';
-- _result json;
-- BEGIN EXECUTE _query INTO _result;
-- return _result;
-- END $function$
-- CREATE OR REPLACE FUNCTION public.x_table_to_json(table_name text) RETURNS json LANGUAGE plpgsql AS $function$
-- DECLARE _query text := 'SELECT array_to_json(array_agg(row_to_json(t))) FROM (SELECT * FROM ' || table_name || ') t';
-- _result json;
-- BEGIN EXECUTE _query INTO _result;
-- return _result;
-- END $function$;
-- Select * from x_table_to_json('x_reports_all', '{"Dział": "formowanie", "Miejsce": "R10", "_limit": "5", "_offset": "0", "Order": "Data zdarzenia", "Desc": "true"}');
-- Select * from x_table_to_json('x_managers_emails(''formowanie'')');
UPDATE reports
SET executed_at = NULL
where report_id = 218;
UPDATE reports
SET executed_at = NULL
where report_id = 217;