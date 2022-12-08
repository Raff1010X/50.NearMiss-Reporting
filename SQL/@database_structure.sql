-- Database structure definition
DROP TABLE IF EXISTS "users" cascade;
DROP TABLE IF EXISTS "roles" cascade;
DROP TABLE IF EXISTS "departments" cascade;
DROP TABLE IF EXISTS "reports" cascade;
DROP TABLE IF EXISTS "reports_raw" cascade;
DROP TABLE IF EXISTS "comments" cascade;
DROP TABLE IF EXISTS "threats" cascade;
DROP TABLE IF EXISTS "consequences" cascade;
DROP TABLE IF EXISTS "managers" cascade;
DROP TABLE IF EXISTS "functions" cascade;
CREATE TABLE "users" (
  "user_id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "email" VARCHAR(255) NOT NULL UNIQUE,
  "password" VARCHAR NOT NULL,
  "role_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
  "updated_at" TIMESTAMP,
  "visited_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP(0),
  "password_updated" VARCHAR,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "department_id" INTEGER NOT NULL,
  "reset_token" VARCHAR
);
/**
 @table: users
 @description: Użytkownicy
 */
CREATE TABLE "roles" (
  "role_id" SERIAL PRIMARY KEY,
  "role" VARCHAR(50) NOT NULL UNIQUE
);
/**
 @table: roles
 @description: Role użytkowników
 */
CREATE TABLE "departments" (
  "department_id" SERIAL PRIMARY KEY,
  "department" VARCHAR(50) NOT NULL UNIQUE
);
/**
 @table: departments
 @description: Działy
 */
CREATE TABLE "reports" (
  "report_id" SERIAL PRIMARY KEY,
  "user_id" UUID,
  "created_at" DATE DEFAULT CURRENT_DATE,
  "department_id" INTEGER,
  "place" VARCHAR(1024),
  "date" DATE,
  "hour" TIME,
  "threat_id" INTEGER,
  "threat" VARCHAR(1024),
  "consequence_id" INTEGER,
  "consequence" VARCHAR(1024),
  "actions" VARCHAR(1024),
  "photo" VARCHAR(255),
  "execution_limit" DATE,
  "executed_at" DATE
);
CREATE UNIQUE INDEX reports_photo_key ON reports(photo);
/**
 @table: reports
 @description: Raporty
 */
CREATE TABLE "reports_raw" (
  "report_id" SERIAL PRIMARY KEY,
  "user_id" VARCHAR(255),
  "created_at" DATE,
  "department_id" VARCHAR(50),
  "place" VARCHAR(1024),
  "date" DATE,
  "hour" TIME,
  "threat_id" VARCHAR(1024),
  "threat" VARCHAR(1024),
  "consequence_id" VARCHAR(1024),
  "consequence" VARCHAR(1024),
  "actions" VARCHAR(1024),
  "photo" VARCHAR(255),
  "execution_limit" DATE,
  "executed_at" DATE
);
/**
 @table: reports
 @description: Raporty
 */
CREATE TABLE "comments" (
  "comment_id" SERIAL PRIMARY KEY,
  "report_id" INTEGER NOT NULL,
  "user_id" UUID NOT NULL,
  "comment" VARCHAR(255) NOT NULL,
  "created_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(0)
);
/**
 @table: comments
 @description: Komentarze
 */
CREATE TABLE "threats" (
  "threat_id" SERIAL PRIMARY KEY,
  "threat" VARCHAR(50) NOT NULL UNIQUE
);
/**
 @table: threats
 @description: Zagrożenia
 */
CREATE TABLE "consequences" (
  "consequence_id" SERIAL PRIMARY KEY,
  "consequence" VARCHAR(50) NOT NULL
);
/**
 @table: consequences
 @description: Skutki zdarzenia
 */
CREATE TABLE "managers" (
  "manager_id" SERIAL PRIMARY KEY,
  "function_id" INTEGER NOT NULL,
  "user_id" UUID NOT NULL
);
/**
 @table: managers
 @description: Kierownicy działów
 */
CREATE TABLE "functions" (
  "function_id" SERIAL PRIMARY KEY,
  "function_name" VARCHAR(50) NOT NULL
);
/**
 @table: managers
 @description: Kierownicy działów
 */
ALTER TABLE "users"
ADD CONSTRAINT "users_role_id_roles_role_id" FOREIGN KEY ("role_id") REFERENCES "roles"("role_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "users"
ADD CONSTRAINT "users_department_id_departments_department_id" FOREIGN KEY ("department_id") REFERENCES "departments"("department_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "reports"
ADD CONSTRAINT "reports_user_id_users_user_id" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "reports"
ADD CONSTRAINT "reports_threat_id_threats_threat_id" FOREIGN KEY ("threat_id") REFERENCES "threats"("threat_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "reports"
ADD CONSTRAINT "reports_consequence_id_consequences_consequence_id" FOREIGN KEY ("consequence_id") REFERENCES "consequences"("consequence_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "reports"
ADD CONSTRAINT "reports_department_id_departments_department_id" FOREIGN KEY ("department_id") REFERENCES "departments"("department_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "comments"
ADD CONSTRAINT "comments_report_id_reports_report_id" FOREIGN KEY ("report_id") REFERENCES "reports"("report_id") ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE "comments"
ADD CONSTRAINT "comments_user_id_users_user_id" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "managers"
ADD CONSTRAINT "managers_user_id_users_user_id" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "managers"
ADD CONSTRAINT "managers_function_id_functions_function_id" FOREIGN KEY ("function_id") REFERENCES "functions"("function_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ALTER TABLE comments alter column created_at set DEFAULT CURRENT_TIMESTAMP(0);
-- ALTER TABLE users alter column created_at set DEFAULT CURRENT_TIMESTAMP(0);
-- ALTER TABLE users alter column visited_at set DEFAULT CURRENT_TIMESTAMP(0);
-- ALTER TABLE users alter column created_at DROP DEFAULT;
-- ALTER TABLE users alter column visited_at DROP DEFAULT;