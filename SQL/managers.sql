--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- VIEW MANAGERS EMAILS
DROP VIEW managers_emails CASCADE;
CREATE OR REPLACE VIEW managers_emails AS (
    SELECT d.department AS "Dział",
      u.email AS "Adres email",
      m.manager_id as "ID",
      f.function_name as "Funkcja"
    FROM managers m
      LEFT JOIN users u USING (user_id)
      LEFT JOIN departments d USING (department_id)
      LEFT JOIN functions f USING (function_id)
    ORDER BY d.department
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION MANAGERS EMAILS returns managers emails from department
DROP FUNCTION public.x_managers_emails(json);
CREATE OR REPLACE FUNCTION public.x_managers_emails(json) RETURNS SETOF managers_emails LANGUAGE plpgsql AS $function$ BEGIN IF ($1::json->>'department_name')::text IS NULL THEN RETURN QUERY
SELECT *
FROM managers_emails;
ELSE RETURN QUERY
SELECT *
FROM managers_emails
WHERE "Dział" ILIKE ($1::json->>'department_name')::text;
END IF;
END $function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- QUERY MANAGERS EMAILS EXAMPLE
SELECT *
FROM x_managers_emails('{"department_name": "formowanie"}');
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- CREATE MANAGER
DROP FUNCTION public.x_manager_create;
CREATE OR REPLACE FUNCTION x_manager_create(_json json) RETURNS integer LANGUAGE plpgsql AS $function$
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
-- EXCEPTION
-- WHEN others THEN return null;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- CREATE MANAGER EXAMPLE
select *
from x_manager_create(
    '{"function": "Kierownik techniki", "email": "rafal.anonim@acme.pl"}'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- UPDATE MANAGER
DROP FUNCTION public.x_manager_update;
CREATE OR REPLACE FUNCTION x_manager_update(_json json) RETURNS boolean LANGUAGE plpgsql AS $function$
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
-- if _result then return true;
-- else return false;
-- end if;
-- EXCEPTION
-- WHEN others THEN return null;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- UPDATE MANAGER EXAMPLE
SELECT *
FROM x_manager_update(
    '{"manager_id": "27", "function": "Kierownik utrzymania ruchu", "email": "rafal.anonim@acme.pl"}'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- DELETE MANAGER
DROP FUNCTION public.x_manager_delete;
CREATE OR REPLACE FUNCTION x_manager_delete(_json json) RETURNS boolean LANGUAGE plpgsql AS $function$
DECLARE _manager_id integer := (x_trym(($1::json->'manager_id')::text))::integer;
_query text := 'DELETE FROM managers WHERE manager_id = ' || _manager_id || ' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
RETURN _result;
-- if _result then return true;
-- else return false;
-- end if;
-- EXCEPTION
-- WHEN others THEN return null;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- DELETE MANAGER EXAMPLE
SELECT *
FROM x_manager_delete('{"manager_id": "26"}');