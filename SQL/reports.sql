--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- VIEW REPORTS ALL return all reports
DROP VIEW reports_all cascade;
CREATE OR REPLACE VIEW reports_all AS (
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
      WHEN ((r.executed_at::text = '') IS NOT false) THEN 'Niewykonane'::text
      ELSE 'Wykonane'::text
    END AS "Status"
  FROM reports r
    LEFT JOIN departments d USING (department_id)
    LEFT JOIN threats t USING (threat_id)
    LEFT JOIN consequences c USING (consequence_id)
    LEFT JOIN users u USING (user_id)
);
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- VIEW REPORTS TO DEPARTMENT return reports to department statistics
CREATE OR REPLACE VIEW reports_to_department AS (
    SELECT r."Dział",
      count(r."Dział")::integer AS "Liczba zgłoszeń",
      count(r."Data wykonania")::integer AS "Liczba zgłoszeń wykonanych",
      (
        round(
          (
            (
              (count(r."Data wykonania"))::numeric / (count(r."Dział"))::numeric
            ) * (100)::numeric
          )
        )
      )::integer AS "Procent zgłoszeń wykonanych"
    FROM reports_all r
    WHERE r."Dział" IS NOT NULL
    GROUP BY 1
    ORDER BY 2 DESC
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- VIEW REPORTS BY DEPARTMENT return reports by department statistics
CREATE OR REPLACE VIEW reports_by_department AS (
    SELECT d.department,
      count(u.department_id) AS "Liczba zgłoszeń przez dział"
    FROM reports r
      LEFT JOIN users u USING (user_id)
      LEFT JOIN departments d ON ((u.department_id = d.department_id))
    WHERE d.department IS NOT NULL
    GROUP BY d.department
    ORDER BY 2 DESC
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION REPORTS ALL return reports filtered, limited, sorted and paginated
CREATE OR REPLACE FUNCTION public.x_reports_all(json) RETURNS SETOF reports_all LANGUAGE plpgsql AS $function$
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
END $function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION REPORTS EXAMPLES
SELECT *
FROM x_reports_all('{"numer": "123"}');
SELECT *
FROM x_reports_all(
    '{"dział": "formowanie", "miejsce": "R10", "limit": "5", "offset": "0", "order": "Data zdarzenia", "desc": "true"}'
  );
SELECT *
FROM x_reports_all(
    '{"dział": "formowanie", "miejsce": "R10"}'
  );
SELECT *
FROM x_reports_all(
    '{"zgłaszający": "rafal.k","from": "2022-01-31", "to": "2022-02-22", "limit": "100", "offset": "0"}'
  );
SELECT *
FROM x_reports_all(
    '{"from": "2022-02-07", "to": "2022-02-11"}'
  );
SELECT *
FROM x_reports_all(
    '{"order": "Dział", "limit": "10", "offset": "0"}'
  );
SELECT *
FROM x_reports_all('{}');
SELECT *
FROM reports_all
ORDER BY "Dział" desc,
  "Numer zgłoszenia"
LIMIT 10 OFFSET 0;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION REPORTS ALL return reports filtered, limited, sorted and paginated
CREATE OR REPLACE FUNCTION public.x_reports_all_count(json) RETURNS integer LANGUAGE plpgsql AS $function$
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
END $function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION REPORTS COUNT EXAMPLES
SELECT *
FROM x_reports_all_count('{"numer": "123"}');
SELECT *
FROM x_reports_all_count(
    '{"dział": "formowanie", "miejsce": "R10"}'
  );
SELECT *
FROM x_reports_all_count(
    '{"zgłaszający": "rafal.k", "miejsce": "R10"}'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- CREATE REPORT
DROP FUNCTION x_report_create(_json json);
CREATE OR REPLACE FUNCTION x_report_create(_json json) RETURNS integer LANGUAGE plpgsql AS $function$
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
-- EXCEPTION
-- WHEN others THEN return null;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- CREATE REPORT EXAMPLE
SELECT *
from x_report_create(
    '{"Zgłaszający": "rafal.anonim@acme.pl",
  "Dział": "Formowanie",
  "Miejsce": "Moje miejsce",
  "Data zdarzenia": "2022-06-22",
  "Godzina zdarzenia": "12:00:00",
  "Zagrożenie": "Budynki",
  "Opis Zagrożenia": "Moje zagrożenie",
  "Skutek": "Mój skutek vel consequence",
  "Konsekwencje": "Duże",
  "Działania do wykonania": "Moje działania do wykonania",
  "Zdjęcie": "Moje_zdjęcie.jpg"
  }'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- UPDATE REPORT
DROP FUNCTION x_report_update(_json json);
CREATE OR REPLACE FUNCTION x_report_update(_json json) -- RETURNS boolean 
  RETURNS boolean LANGUAGE plpgsql AS $function$
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
-- if _result then RETURN true;
-- else RETURN false;
-- end if;
-- EXCEPTION
-- WHEN others THEN return null;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- UPDATE REPORT EXAMPLE
SELECT *
from x_report_update(
    '{"report_id": "513",
  "Dział": "Formowanie",
  "Miejsce": "Moje miejsce32",
  "Data zdarzenia": "2023-06-23",
  "Godzina zdarzenia": "13:00:00",
  "Zagrożenie": "Budynki",
  "Opis Zagrożenia": "Moje zagrożeni3e2",
  "Skutek": "Mój skutek vel consequence32",
  "Konsekwencje": "Duże",
  "Działania do wykonania": "Moje działania do wykonania3",
  "Zdjęcie": "Moje_zdjęcie3.jpg"
  }'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- DELETE REPORT
DROP FUNCTION x_report_delete(_json json);
CREATE OR REPLACE FUNCTION x_report_delete(_json json) RETURNS boolean LANGUAGE plpgsql AS $function$
DECLARE _report_id integer := x_trym(($1::json->'report_id')::text)::integer;
_query text := 'DELETE FROM reports WHERE report_id = ' || _report_id || ' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
RETURN _result;
-- if _result then RETURN true;
-- else RETURN false;
-- end if;
-- EXCEPTION
-- WHEN others THEN return null;
END;
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- DELETE
SELECT *
FROM x_report_delete('{"Numer zgłoszenia": "502"}');
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- UPDATE REPORT - EXECUTED
DROP FUNCTION x_report_executed(_json json);
CREATE OR REPLACE FUNCTION x_report_executed(_json json) -- RETURNS boolean 
  RETURNS boolean LANGUAGE plpgsql AS $function$
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
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
SELECT *
FROM x_report_executed('{"report_id": "499"}');
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- VIEW REPORT STATISTICS
CREATE OR REPLACE VIEW reports_stats AS (
    SELECT count(r."Dział") AS "Liczba zgłoszeń",
      count(r."Data wykonania") AS "Liczba zgłoszeń wykonanych",
      (
        round(
          (
            (
              (count(r."Data wykonania"))::numeric / (count(r."Dział"))::numeric
            ) * (100)::numeric
          )
        )
      )::integer AS "Procent zgłoszeń wykonanych"
    FROM reports_all r
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION REPORT STATISTICS by date
DROP FUNCTION x_reports_stats;
CREATE OR REPLACE FUNCTION public.x_reports_stats(_json json) RETURNS TABLE(
    "Liczba zgłoszeń" integer,
    "Liczba zgłoszeń wykonanych" integer,
    "Procent zgłoszeń wykonanych" integer
  ) LANGUAGE plpgsql AS $function$
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
END $function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION REPORT STATISTICS EXAMPLE
SELECT *
FROM x_reports_stats('{"from": "2022-01-01", "to": "2022-01-31"}');
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION REPORT STATISTICS TO DEPARTMENT BY DATE
DROP FUNCTION x_reports_to_department(_json json);
CREATE OR REPLACE FUNCTION public.x_reports_to_department(_json json) RETURNS TABLE(
    "Dział" CHARACTER VARYING(50),
    "Liczba zgłoszeń" integer,
    "Liczba zgłoszeń wykonanych" integer,
    "Procent zgłoszeń wykonanych" integer
  ) LANGUAGE plpgsql AS $function$
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
END $function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION REPORT STATISTICS BY DEPARTMENT BY DATE
DROP FUNCTION public.x_reports_by_department(_json json);
CREATE OR REPLACE FUNCTION public.x_reports_by_department(_json json) RETURNS TABLE(
    "Dział" CHARACTER VARYING(50),
    "Liczba zgłoszeń przez dział" integer
  ) LANGUAGE plpgsql AS $function$
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
END $function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION REPORT STATISTICS TO DEPARTMENT BY DATE EXAMPLE
SELECT *
FROM x_reports_to_department(
    '{ "from": "2022-01-01", "to": "2022-01-31" }'
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- FUNCTION REPORT STATISTICS BY DATE DONE
CREATE OR REPLACE VIEW reports_by_date_done AS (
    SELECT to_char(
        (r.date)::timestamp with time zone,
        'MM'::text
      ) AS mon,
      EXTRACT(
        year
        FROM r.date
      ) AS yyyy,
      count(1) AS "Liczba zgłoszeń"
    FROM reports r
      LEFT JOIN users u USING (user_id)
      LEFT JOIN departments d ON ((u.department_id = d.department_id))
    WHERE r.executed_at IS NOT NULL
      AND r.date >= date_trunc('month'::text, (now() - '11 mons'::interval))
      AND (r.date <= now())
    GROUP BY 1,
      2
    ORDER BY 2 DESC,
      1 DESC
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- VIEW REPORTS BY DATE ALL
CREATE OR REPLACE VIEW reports_by_date_post AS (
    SELECT to_char(
        (r.date)::timestamp with time zone,
        'MM'::text
      ) AS mon,
      EXTRACT(
        year
        FROM r.date
      ) AS yyyy,
      count(1) AS "Liczba zgłoszeń"
    FROM reports r
      LEFT JOIN users u USING (user_id)
      LEFT JOIN departments d ON ((u.department_id = d.department_id))
    WHERE r.date >= date_trunc('month'::text, (now() - '11 mons'::interval))
      AND (r.date <= now())
    GROUP BY 1,
      2
    ORDER BY 2 DESC,
      1 DESC
  );
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
-- VIEW REPORTS BY DATE
CREATE OR REPLACE VIEW reports_by_date AS (
    SELECT to_char(
        (r.date)::timestamp with time zone,
        'MM'::text
      ) AS mon,
      EXTRACT(
        year
        FROM r.date
      ) AS yyyy,
      d.department,
      count(u.department_id) AS "Liczba zgłoszeń",
      CASE
        WHEN (count(u.department_id) > 4) THEN true
        ELSE false
      END AS "Cel 5 zgłoszeń"
    FROM reports r
      LEFT JOIN users u USING (user_id)
      LEFT JOIN departments d ON ((u.department_id = d.department_id))
    WHERE r.date >= date_trunc('month'::text, (now() - '5 mons'::interval))
      AND (r.date <= now())
    GROUP BY 1,
      2,
      3
    ORDER BY 2 DESC,
      1 DESC,
      4 DESC,
      3
  );