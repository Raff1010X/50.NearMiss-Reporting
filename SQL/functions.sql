--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- CREATE function
DROP FUNCTION IF EXISTS x_function_create;
CREATE OR REPLACE FUNCTION x_function_create(_json json) RETURNS integer LANGUAGE plpgsql AS $function$
DECLARE _function text := x_trym(($1::json->'function')::text);
_query text := 'INSERT INTO functions (function_name) 
          VALUES (''' || _function || ''') RETURNING function_id;';
_result integer;
BEGIN execute _query into _result;
return _result;
-- EXCEPTION
-- WHEN others THEN return null;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- QUERY CREATE function EXAMPLE
select *
from x_function_create('{"function": "Kierownik działu 1"}');
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- UPDATE function
DROP FUNCTION x_function_update;
CREATE OR REPLACE FUNCTION x_function_update(_json json) RETURNS boolean LANGUAGE plpgsql AS $function$
DECLARE _function_id text := x_trym(($1::json->'function_id')::text);
_function text := x_trym(($1::json->'function')::text);
_query text := 'UPDATE functions SET
           function_name = ''' || _function || '''
          WHERE function_id = ''' || _function_id || '''
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
-- QUERY UPDATE function EXAMPLE
select *
from x_function_update(
        '{"function_id": 16, "function": "Kierownik działu 2"}'
    );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- DELETE function
DROP FUNCTION x_function_delete;
CREATE OR REPLACE FUNCTION x_function_delete(_json json) RETURNS boolean LANGUAGE plpgsql AS $function$
DECLARE _function_id text := x_trym(($1::json->'function_id')::text);
_query text := 'DELETE FROM functions WHERE function_id = ''' || _function_id || ''' RETURNING true;';
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
-- QUERY DELETE function EXAMPLE
select *
from x_function_delete('{"function_id": 16}');