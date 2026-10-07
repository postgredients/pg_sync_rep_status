# pg_sync_rep_status

A small PostgreSQL extension that reports whether the checkpointer has applied
a nonempty `synchronous_standby_names` to shared memory. It reads the same
`SYNC_STANDBY_DEFINED` flag used by the commit wait path, under `SyncRepLock`.

Supports PostgreSQL 14–18 and PostgreSQL 19 beta 4. No
`shared_preload_libraries` setting is required.

## Install

```sh
make PG_CONFIG=/path/to/pg_config
make PG_CONFIG=/path/to/pg_config install
```

Then, in a database:

```sql
CREATE EXTENSION pg_sync_rep_status;
SELECT pg_sync_rep_enabled();
```

The function is `VOLATILE`, so repeated calls can observe a configuration
transition. `true` means the checkpointer has processed a nonempty
`synchronous_standby_names`; it does **not** prove that a particular value has
been applied by every WAL sender, that synchronous standbys are connected, or
that a write quorum is available. Check the configured value separately when
waiting for a specific setting.

## Test

`tests/test.sh` starts a temporary PostgreSQL cluster and checks the shared
memory flag across empty → nonempty → empty transitions. The CI matrix runs
this test against PostgreSQL 14, 15, 16, 17, 18, and 19 beta 4.
