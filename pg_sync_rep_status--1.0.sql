\echo Use "CREATE EXTENSION pg_sync_rep_status" to load this file. \quit

CREATE FUNCTION pg_sync_rep_enabled()
RETURNS boolean
AS 'MODULE_PATHNAME', 'pg_sync_rep_enabled'
LANGUAGE C VOLATILE PARALLEL UNSAFE;
