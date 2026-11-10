#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export DJANGO_DEBUG=1
if [ ! -x .venv/bin/python ]; then
  if command -v uv >/dev/null 2>&1; then uv venv --python 3.12 .venv; else python3.12 -m venv .venv; fi
fi
if command -v uv >/dev/null 2>&1; then uv pip install --python .venv/bin/python -r requirements.txt; else .venv/bin/python -m pip install -r requirements.txt; fi
.venv/bin/python manage.py migrate
if [ "${1:-}" = '--demo' ]; then
  if [ -z "${PROVISION_PASSWORD:-}" ]; then
    PROVISION_PASSWORD=$(.venv/bin/python -c 'import secrets; print(secrets.token_urlsafe(18))')
    export PROVISION_PASSWORD
    printf 'Local demo email: demo.owner@example.com\nLocal demo password: %s\n' "$PROVISION_PASSWORD"
  fi
  .venv/bin/python manage.py seed_demo
fi
exec .venv/bin/python manage.py runserver 127.0.0.1:8000
