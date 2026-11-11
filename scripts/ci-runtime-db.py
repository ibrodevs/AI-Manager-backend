"""Prepare a disposable CI database for HTTP tests under a non-bypass role.

Run only against the isolated test database, after migrate and seed_demo.
The password is intentionally public and has no use outside disposable CI.
"""
import os
import psycopg

with psycopg.connect(os.environ["DATABASE_URL"]) as conn:
    conn.execute(
        "CREATE ROLE allmanager_runtime LOGIN NOSUPERUSER NOCREATEDB "
        "NOCREATEROLE NOBYPASSRLS PASSWORD 'ci-runtime-only'"
    )
    conn.execute("GRANT USAGE ON SCHEMA public TO allmanager_runtime")
    conn.execute(
        "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public "
        "TO allmanager_runtime"
    )
    conn.execute(
        "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO allmanager_runtime"
    )
