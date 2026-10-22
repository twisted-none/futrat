-- First creation only. Run as PostgreSQL administrator in database postgres.
-- If the role/database exists, stop and inspect it; never reset another project.
\set ON_ERROR_STOP on
CREATE ROLE futrat LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION CONNECTION LIMIT 10;
CREATE DATABASE futrat OWNER futrat;
REVOKE ALL ON DATABASE futrat FROM PUBLIC;
\connect futrat
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE, CREATE ON SCHEMA public TO futrat;
-- Set the password interactively with psql's \password futrat afterwards.
