# AI-Manager backend

Самостоятельный backend ALL-менеджера: Django REST Framework, PostgreSQL с RLS, Redis/Celery.

Frontend находится отдельно: [ibrodevs/AI-Manager](https://github.com/ibrodevs/AI-Manager).

```bash
./scripts/dev.sh --demo
```

API: `http://127.0.0.1:8000`, Swagger: `/api/docs/`. Нужны Python 3.12 или uv. Node.js и frontend для запуска API не нужны. Скрипт печатает случайный пароль локального демо-аккаунта; собственник настраивает TOTP при первом входе через frontend.

Во frontend задайте:

```dotenv
DATA_SOURCE=django
DJANGO_API_URL=http://127.0.0.1:8000/api/v1
```

- [Запуск, API, настройка Docker и проверки](docs/DJANGO_MVP.md)
- [Матрица приёмки MVP и оставшиеся требования](docs/MVP_ACCEPTANCE.md)
- [OpenAPI](openapi.yaml)

Подключение реальных провайдеров и полная приёмка ТЗ остаются отдельными задачами. Статус реализации при разделении репозиториев не изменялся.

Сохранённые голосовой сервис, Node.js-воркеры и старые SQL-миграции перенесены из frontend в [legacy/](legacy/). Основной Django backend от них не зависит.
