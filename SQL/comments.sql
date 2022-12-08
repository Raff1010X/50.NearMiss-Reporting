--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- VIEW COMMENTS ALL returns all comments
CREATE OR REPLACE VIEW comments_all AS
SELECT u.email AS "Autor",
  c.comment AS "Wpis",
  c.created_at AS "Data",
  r.report_id AS "ID raportu",
  c.comment_id AS "Numer komentarza"
FROM comments c
  LEFT JOIN users u USING (user_id)
  LEFT JOIN reports r USING (report_id)
ORDER BY 2;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION COMMENT returns comment by id
CREATE OR REPLACE FUNCTION public.x_comment(_json json) RETURNS SETOF comments_all LANGUAGE plpgsql AS $function$
DECLARE id_komentarza text := (x_trym(($1::json->'comment_id')::text));
BEGIN return QUERY EXECUTE 'SELECT * FROM comments_all WHERE "Numer komentarza" = ''' || id_komentarza || ''' ORDER BY "ID raportu";';
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- CREATE COMMENT
DROP FUNCTION x_comment_create;
CREATE OR REPLACE FUNCTION x_comment_create(_json json) RETURNS integer LANGUAGE plpgsql AS $function$
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
-- EXCEPTION
-- WHEN others THEN return null;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- CREATE COMMENT EXAMPLE
SELECT *
FROM x_comment_create(
    '{ "Numer zgloszenia": "10", "Adres email": "rafal.anonim@acme.pl", "comment": "Komentarz"}'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- UPDATE COMMENT
CREATE OR REPLACE FUNCTION x_comment_update(_json json) RETURNS boolean LANGUAGE plpgsql AS $function$
DECLARE _comment_id integer := (x_trym(($1::json->'comment_id')::text))::integer;
_comment text := x_trym(($1::json->'Komentarz')::text);
_query text := 'UPDATE comments SET
            comment = ''' || _comment || '''
          WHERE comment_id = ' || _comment_id || '
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
-- UPDATE COMMENT EXAMPLE
SELECT *
FROM x_comment_update(
    '{ "comment_id": "1", "comment": "Komentarz2333"}'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- DELETE COMMENT
CREATE OR REPLACE FUNCTION x_comment_delete(_json json) RETURNS boolean LANGUAGE plpgsql AS $function$
DECLARE _comment_id integer := (x_trym(($1::json->'comment_id')::text))::integer;
_query text := 'DELETE FROM comments WHERE comment_id = ' || _comment_id || ' RETURNING true;';
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
-- FUNCTION COMMENTS TO REPORT returns comments by report id
DROP FUNCTION x_comments_to_report(_json json);
CREATE OR REPLACE FUNCTION x_comments_to_report(_json json) RETURNS SETOF comments_all LANGUAGE plpgsql AS $function$
DECLARE _report_id text := (x_trym(($1::json->'report_id')::text));
BEGIN return QUERY EXECUTE 'SELECT * FROM comments_all WHERE "ID raportu" = ' || _report_id || ' ORDER BY "Data" DESC;';
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION COMMENTS TO REPORT EXAMPLE
SELECT *
FROM x_comments_to_report('{ "report_id": "6"}');
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION COMMENTS BY USER returns comments by user id
CREATE OR REPLACE FUNCTION x_comments_by_user(_json json) RETURNS SETOF comments_all LANGUAGE plpgsql AS $function$
DECLARE email text := (x_trym(($1::json->'user_email')::text));
BEGIN return QUERY EXECUTE 'SELECT * FROM comments_all WHERE "Autor" = ''' || email || ''' ORDER BY "ID raportu";';
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION COMMENTS BY USER EXAMPLE
SELECT *
FROM x_comments_by_user(
    '{"user_email": "rafal.anonim@acme.pl"}'
  );