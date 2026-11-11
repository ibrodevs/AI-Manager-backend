# Этап A — стабилизация

Дата: 11 ноября 2026. Исходный main: `319e74c1a7d27d1d37ede0f7b2466768885cb080`.
Frontend: отдельный репозиторий `ibrodevs/AI-Manager`; изменения не объединяют деревья проектов.

## Результат

PARTIALLY COMPLETED: код, нативная интеграция и CI проверены; полный Docker Compose/Redis/Celery-контур остаётся NOT VERIFIED. Незакрытых Critical/High дефектов в проверенном контуре не обнаружено.
Основной контур проверен нативно на Python 3.12 и отдельном PostgreSQL 16.11 (порт 55432), без production-данных. HTTP API в браузерных проверках использует `allmanager_runtime` (NOSUPERUSER/NOBYPASSRLS), миграции и seed — отдельную роль мигратора.

## Дефекты

| ID | Severity | Repository / File | Problem / Cause | Fix | Verification |
| --- | --- | --- | --- | --- | --- |
| A-01 | High | Backend `.github/workflows/ci.yml`; frontend `.github/workflows/django.yml` | Контейнер не создаётся: runner передаёт одиночные кавычки буквально, `-U` попадает в аргументы Docker | Healthcheck `--health-cmd=pg_isready`, отдельный SQL-запрос перед тестами | Логи jobs 129808857150/129808868142; исправленный backend CI SUCCESS |
| A-02 | High | Backend `core/api.py` | Бухгалтер мог PATCH-изменить сумму счёта, хотя счета создаёт платформа | PATCH счетов запрещён tenant API | Новый тест сначала получил 200 вместо 403; после исправления проходит |
| A-03 | Medium | Backend `core/api.py` | Staff мог переназначить свой звонок или привязать скрытый от него контакт через REST | Серверная проверка всех вариантов assignee (включая одновременно переданные алиасы) и видимости contact | Регрессионный тест сначала падал, затем прошёл |
| A-04 | High | Backend `core/services.py` | Откат не восстанавливал удалённые UUID и связи, сохранял новые строки черновика; порядок services/staff/branches ломал FK-проверки | Два прохода восстановления со стабильными UUID, branches сначала, удаление строк вне снимка | Регрессия удаляет service/staff/branch, проверяет связи, удаление лишней услуги и неизменность старого снимка |
| A-05 | Medium | Frontend integration workflow | После истечения readiness-loop тесты всё равно запускались; backend checkout main менялся между прогонами; API использовал superuser | Явный отказ при неготовности, закреплённая версия backend, отдельная runtime-роль | Локальный браузерный прогон под runtime; отдельный frontend integration CI |
| A-06 | Medium | Backend `core/api.py` | Универсальный JSON args допускал число/null вместо объекта, что приводило к AttributeError | Валидация объектов команд и строк таблиц; события провайдера требуют объект | Тест malformed command objects возвращает 400 |

Изменены `.github/workflows/ci.yml`, `core/api.py`, `core/services.py`, `core/tests.py`; добавлен `scripts/ci-runtime-db.py`. Последний предназначен исключительно для одноразовой CI-БД и содержит публичный тестовый пароль.

## Выполненные проверки

- `manage.py test core --noinput`: **42/42 PASS**, включая реальные RLS, FORCE RLS, роль без обхода политик, tenant API, чужие FK, owner/admin/staff/accountant, TOTP/replay собственника и Django Admin, запрет Admin без MFA/для staff, отзыв всех сессий и неактивного пользователя.
- Чистая БД: применены миграции core 0001–0008 и Django; **PASS**.
- `makemigrations --check --dry-run`: **PASS**, новых миграций нет.
- `spectacular --file /tmp/phase-a-openapi.yaml --validate --fail-on-warn`: **PASS**.
- Подписанный provider-events: подпись привязывает tenant и тело, проверен устаревший timestamp, повтор события, округление минут, отказ 503 без секрета; **PASS**.
- Calendar: конфликт на уровне API и exclusion constraint PostgreSQL, перенос с Asia/Bishkek, отмена и освобождение слота; **PASS**.
- Inbox: входящий тестовый контракт, сообщение, перехват, блокировка AI commit, создание реальной заявки; **PASS**. Доставка Telegram/WhatsApp не имитировалась.
- Legacy voice: **8/8 PASS**; сохранённый legacy JS: typecheck и **24/24 PASS**. Эти сервисы не объявлены активным Django-контуром.
- Схема questionnaire совпадает с frontend: **PASS**.
- Chromium E2E из frontend: **10/10 PASS** на настоящем Django/PostgreSQL под runtime-ролью. Вход/TOTP/reload, CRM create/status/history, основные экраны, KB publish/immutable/rollback, локальный AI с сохранением заявки, настройки, неверный пароль, logout/revocation.

Тесты не отключались. Секреты production не использовались. Поиск типовых шаблонов private keys/provider tokens в рабочем дереве не нашёл совпадений; это ограниченный review, не полный аудит истории Git и не pentest.

## GitHub Actions

Исходное падение: https://github.com/ibrodevs/AI-Manager-backend/actions/runs/42810035837 . Голосовые и legacy jobs исходного CI уже проходили; backend job не доходил до установки зависимостей.
Первый исправленный коммит `5f6c3a3`: https://github.com/ibrodevs/AI-Manager-backend/actions/runs/42954726686 — **SUCCESS**. Проверки реализации `39d79d7`: https://github.com/ibrodevs/AI-Manager-backend/actions/runs/42955088752 — **SUCCESS**. Финальное расширение содержит только дополнительные тесты Admin MFA/межтенантного доступа и документацию; актуальные проверки ветки: https://github.com/ibrodevs/AI-Manager-backend/pull/1/checks . PR: https://github.com/ibrodevs/AI-Manager-backend/pull/1 .

## Локальное воспроизведение

```sh
python3.12 -m venv .venv
.venv/bin/pip install -r requirements.txt
# Создайте ОТДЕЛЬНУЮ пустую локальную БД; URL ниже — только пример.
export DATABASE_URL=postgresql://LOCAL_MIGRATOR@127.0.0.1:55432/allmanager_phase_a
export DJANGO_DEBUG=1
.venv/bin/python manage.py migrate --noinput
.venv/bin/python manage.py test core --noinput
.venv/bin/python manage.py makemigrations --check --dry-run
.venv/bin/python manage.py spectacular --file /tmp/schema.yaml --validate --fail-on-warn
```

Для RLS-тестов роль мигратора должна создавать тестовую БД и тестовую непривилегированную роль. В изолированной CI-БД после seed запустите `scripts/ci-runtime-db.py`, затем запускайте HTTP API с runtime URL, как в frontend workflow. Не применяйте этот CI-скрипт к существующей рабочей базе. В Docker роли создаёт `scripts/init-runtime-role.sh`.

## Ограничения и готовность B

- Docker CLI — неработающая ссылка, daemon недоступен: **NOT VERIFIED** для сборки образов, Compose startup/shutdown/restart, Redis/Celery по сети. Нативные тесты задач не заменяют проверку брокера.
- Production deployment, TLS/reverse proxy, резервирование/восстановление, нагрузка и pentest: **NOT VERIFIED**.
- RLS и серверная tenant-фильтрация проверены; публичный read/command контракт сохраняет массивы для совместимости, REST resources используют LimitOffsetPagination. Универсальный контракт не заменяет полный типизированный OpenAPI каждой команды.
- API принимает нормализованные подписанные события и сохраняет звонки/чаты, CRM сохраняет реальные заявки. Это готовая тестируемая граница для этапа B, но не подтверждение настоящего голосового транспорта.
- До LiveKit/SIP нужны отдельный шлюз с tenant routing, WEBHOOK_SECRET, преобразование событий, storage/retention аудио, наблюдаемость и нагрузочные/речевые испытания. Платные AI, телефония, новый биллинг и внешние каналы не подключались.
