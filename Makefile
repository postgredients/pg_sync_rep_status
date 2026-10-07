EXTENSION = pg_sync_rep_status
MODULES = pg_sync_rep_status
DATA = pg_sync_rep_status--1.0.sql

PG_CONFIG ?= pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
