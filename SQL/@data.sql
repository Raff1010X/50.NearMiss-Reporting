-- BASIC data insert to table, AND copy data from reports_raw to reports
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////
INSERT INTO roles (role)
VALUES ('user'),
  ('superuser'),
  ('admin');
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////
INSERT INTO departments (department)
VALUES ('Biuro'),
  ('Dekoratornia'),
  ('Formowanie'),
  ('Inny'),
  ('Jakość, BHP i OŚ'),
  ('Konfekcja'),
  ('Magazyn A30'),
  ('Magazyn A31'),
  (
    'Magazyn butli, częsci, palet, odpady niebezpieczne'
  ),
  ('Magazyn opakowań'),
  ('Magazyn wyrobów'),
  ('Sortownia'),
  ('Technika'),
  ('Utrzymanie ruchu'),
  ('Warsztat'),
  ('Wzory'),
  ('Zestawiarnia');
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////
INSERT INTO consequences (consequence)
VALUES ('Bardzo małe'),
  ('Małe'),
  ('Średnie'),
  ('Duże'),
  ('Bardzo duże');
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////
INSERT INTO threats (threat)
VALUES ('Balustrady'),
  ('Budynki'),
  ('Butle z gazami technicznymi'),
  ('Drabiny'),
  ('Inne'),
  ('Instalacja elektryczna'),
  ('Instalacje gazowe'),
  ('Magazynowanie'),
  ('Maszyny'),
  ('Narzędzia'),
  ('Niezabezpieczone otwory technologiczne'),
  ('Ochrona p.poż.'),
  ('Odzież'),
  ('Oznakowanie'),
  ('Pierwsza pomoc'),
  ('Podesty'),
  ('Porządek'),
  ('Przejścia-dojścia'),
  ('Stłuczka szklana'),
  ('Substancje chemiczne'),
  ('Środki ochrony indywidualnej'),
  ('Środki ochrony zbiorowej'),
  ('Transport'),
  ('Wyposażenie'),
  ('Ochrona p.poż'),
  ('Magazynowanie, składowanie');
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////
INSERT INTO functions (function_name)
VALUES ('Kierownik administracji'),
  ('Kierowink magazynu butli, cząści, palet...'),
  ('Kierownik magazynu opakowań'),
  ('Kierownik magazynu A30'),
  ('Kierownik magazynu A31'),
  ('Kierownik działu konfekcjonowania'),
  ('Kierownik działu formowania'),
  ('Kierownik działu zestawiarni i topienia'),
  ('Kierownik sortowania'),
  ('Kierownik dekoratorni'),
  ('Kierownik warsztatu'),
  ('Kierownik jakości, BHP i OŚ'),
  ('Kierowink działu wzory'),
  ('Kierownik techniki'),
  ('Kierownik utrzymania ruchu');
CREATE OR REPLACE FUNCTION public.x_copy_data() RETURNS integer LANGUAGE plpgsql AS $function$ BEGIN FOR i IN 1..500 LOOP
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
$function$;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
Truncate table reports restart identity cascade;
SELECT x_copy_data();
INSERT INTO threats (threat_id, threat)
values (0, '');
UPDATE reports
SET threat_id = 0
WHERE threat_id IS NULL;
--///////////////////////////////////////////////////////////////////////////////////////////////////////////
UPDATE reports
SET photo = REPLACE(photo, ' ', '')
WHERE photo like '% %';
UPDATE reports
SET photo = REPLACE(photo, 'ą', 'a')
WHERE photo like '%ą%';
UPDATE reports
SET photo = REPLACE(photo, 'ę', 'e')
WHERE photo like '%ę%';
UPDATE reports
SET photo = REPLACE(photo, 'ł', 'l')
WHERE photo like '%ł%';
UPDATE reports
SET photo = REPLACE(photo, 'ń', 'n')
WHERE photo like '%ń%';
UPDATE reports
SET photo = REPLACE(photo, 'ó', 'oe')
WHERE photo like '%ó%';
UPDATE reports
SET photo = REPLACE(photo, 'ś', 's')
WHERE photo like '%ś%';
UPDATE reports
SET photo = REPLACE(photo, 'ż', 'z')
WHERE photo like '%ż%';
UPDATE reports
SET photo = REPLACE(photo, '.jpeg', '.jpg')
WHERE photo like '%.jpeg';
UPDATE reports
SET photo = REPLACE(photo, '.png', '.jpg')
WHERE photo like '%.png';
UPDATE reports
SET photo = REPLACE(photo, '.PNG', '.jpg')
WHERE photo like '%.PNG';