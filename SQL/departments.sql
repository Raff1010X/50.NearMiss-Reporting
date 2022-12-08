--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- VIEW DEPARTMENTS TOP 10
CREATE OR REPLACE VIEW departments_top_10 AS
SELECT d.department,
  count(u.department_id) AS "Liczba zgłoszeń przez dział"
FROM reports r
  LEFT JOIN users u USING (user_id)
  LEFT JOIN departments d ON ((u.department_id = d.department_id))
GROUP BY d.department
ORDER BY 2 DESC;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- -- FUNCTION DEPARTMENTS TOP 10 form view departments_top_10 by dates
-- CREATE OR REPLACE FUNCTION public.x_departments_top_10(_json json) RETURNS TABLE(
--     "department" CHARACTER VARYING(50),
--     "Liczba zgłoszeń" bigint
--   ) LANGUAGE plpgsql AS $function$
-- DECLARE from_date text := CASE
--     WHEN ($1::json->>'from') IS NULL THEN 'WHERE "date" >= ''1900-01-01'''
--     ELSE (
--       'WHERE "date" >= ''' || ($1::json->>'from') || ''''
--     )
--   END;
-- to_date text := CASE
--   WHEN ($1::json->>'to') IS NULL THEN ''
--   ELSE (
--     ' AND "date" <= ''' || ($1::json->>'to') || ''''
--   )
-- END;
-- _query text := 'SELECT
--     d.department,
--     count(u.department_id) AS "Liczba zgłoszeń przez dział"
--   FROM
--     reports r
--     LEFT JOIN users u USING (user_id)
--     LEFT JOIN departments d ON ((u.department_id = d.department_id))
--     ' || from_date || to_date || '
--   GROUP BY
--     d.department
--   ORDER BY
--     2 DESC';
-- BEGIN RETURN QUERY EXECUTE _query;
-- END $function$;
-- --///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- -- QUERY DEPARTMENTS TOP 10 EXAMPLE
-- SELECT *
-- FROM x_departments_top_10(
--     '{"Data od":"2020-01-01", "Data do":"2020-01-31"}'
--   );
-- DROP FUNCTION x_department_create;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- CREATE DEPARTMENT
CREATE OR REPLACE FUNCTION x_department_create(_json json) RETURNS integer LANGUAGE plpgsql AS $function$
DECLARE _department text := x_trym(($1::json->'department')::text);
_query text := 'INSERT INTO departments (department) 
          VALUES (''' || _department || ''') RETURNING department_id;';
_result integer;
BEGIN execute _query into _result;
return _result;
-- EXCEPTION
-- WHEN others THEN return null;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- QUERY CREATE DEPARTMENT EXAMPLE
select *
from x_department_create('{"department": "Formowanie00"}');
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- UPDATE DEPARTMENT
DROP FUNCTION x_department_update;
CREATE OR REPLACE FUNCTION x_department_update(_json json) RETURNS boolean LANGUAGE plpgsql AS $function$
DECLARE _department_id text := x_trym(($1::json->'department_id')::text);
_department text := x_trym(($1::json->'department')::text);
_query text := 'UPDATE departments SET
           department = ''' || _department || '''
          WHERE department_id = ''' || _department_id || '''
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
-- QUERY UPDATE DEPARTMENT EXAMPLE
select *
from x_department_update(
    '{"department_id": 26, "department": "Formowanie11"}'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- DELETE DEPARTMENT
DROP FUNCTION x_department_delete;
CREATE OR REPLACE FUNCTION x_department_delete(_json json) RETURNS boolean LANGUAGE plpgsql AS $function$
DECLARE _department_id text := x_trym(($1::json->'department_id')::text);
_query text := 'DELETE FROM departments WHERE department_id = ''' || _department_id || ''' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;
-- if _result then return _result;
-- else return false;
-- end if;
-- EXCEPTION
-- WHEN others THEN return null;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- QUERY DELETE DEPARTMENT EXAMPLE
select *
from x_department_delete('{"department_id": 26}');