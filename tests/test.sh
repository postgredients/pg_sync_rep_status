#!/usr/bin/env bash
set -euo pipefail

pg_config=${PG_CONFIG:-pg_config}
pg_bindir=$($pg_config --bindir)
test_dir=$(mktemp -d /tmp/pgsr.XXXXXX)
pg_port=$((40000 + RANDOM % 20000))
started=0

cleanup() {
    if [ "$started" -eq 1 ]; then
        "$pg_bindir/pg_ctl" -D "$test_dir/data" -m immediate -w stop >/dev/null
    fi
    rm -r "$test_dir"
}
trap cleanup EXIT

"$pg_bindir/initdb" -A trust -U postgres -D "$test_dir/data" >/dev/null
"$pg_bindir/pg_ctl" -D "$test_dir/data" -o "-k $test_dir -p $pg_port -c listen_addresses=''" -w start >/dev/null
started=1

psql_cmd=("$pg_bindir/psql" -X -qAt -v ON_ERROR_STOP=1 -h "$test_dir" -p "$pg_port" -U postgres -d postgres)

if [ "${PGSR_DIRECT:-0}" = 1 ]; then
    library=$(cd "$(dirname "$0")/.." && pwd)/pg_sync_rep_status
    "${psql_cmd[@]}" -c "CREATE FUNCTION pg_sync_rep_enabled() RETURNS boolean AS '$library', 'pg_sync_rep_enabled' LANGUAGE C VOLATILE PARALLEL UNSAFE" >/dev/null
else
    "${psql_cmd[@]}" -c 'CREATE EXTENSION pg_sync_rep_status' >/dev/null
fi

wait_for_state() {
    local expected=$1
    local actual
    for ((attempt = 0; attempt < 100; attempt++)); do
        actual=$("${psql_cmd[@]}" -c 'SELECT pg_sync_rep_enabled()')
        if [ "$actual" = "$expected" ]; then
            return 0
        fi
        sleep 0.1
    done
    echo "Expected pg_sync_rep_enabled()=$expected, got $actual" >&2
    return 1
}

wait_for_state f
"${psql_cmd[@]}" -c "ALTER SYSTEM SET synchronous_standby_names = 'ANY 1 (pgsr_probe)'" >/dev/null
"${psql_cmd[@]}" -c 'SELECT pg_reload_conf()' >/dev/null
wait_for_state t
"${psql_cmd[@]}" -c "ALTER SYSTEM SET synchronous_standby_names = ''" >/dev/null
"${psql_cmd[@]}" -c 'SELECT pg_reload_conf()' >/dev/null
wait_for_state f

echo "PASS: PostgreSQL $($pg_config --version), empty -> nonempty -> empty"
