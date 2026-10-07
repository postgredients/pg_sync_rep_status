#include "postgres.h"

#include "fmgr.h"
#include "replication/walsender_private.h"
#include "storage/lwlock.h"

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(pg_sync_rep_enabled);

Datum
pg_sync_rep_enabled(PG_FUNCTION_ARGS)
{
	bits8		status;

	LWLockAcquire(SyncRepLock, LW_SHARED);
	status = WalSndCtl->sync_standbys_status;
	LWLockRelease(SyncRepLock);

	PG_RETURN_BOOL((status & (SYNC_STANDBY_INIT | SYNC_STANDBY_DEFINED)) ==
				   (SYNC_STANDBY_INIT | SYNC_STANDBY_DEFINED));
}
