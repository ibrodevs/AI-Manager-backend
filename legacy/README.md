# Backend-сервисы предыдущей версии

Здесь сохранены серверные части, перенесённые из frontend-репозитория:

- `apps/voice`: Python/LiveKit, голосовой сервис.
- `apps/workers`: Node.js, очереди и обработчики.
- `packages/db`: прежние SQL-миграции, Supabase-конфигурация и тесты изоляции.
- `packages/integrations`: адаптеры каналов.
- `packages/dialog` и `eval`: зависимости этих сервисов, промпты и проверки.

Основной backend — Django в корне репозитория. Эта папка сохраняет существующие серверные реализации; она не подключается автоматически к Django и не запускается основным Compose. Подключение реальных провайдеров и адаптация старых сервисов к Django остаются в матрице приёмки.

`reference/` содержит старые workflows и скрипт provisioning для сохранности, не активные GitHub Actions этого репозитория. Скрипт provisioning нельзя использовать как Django-команду.

```bash
cd legacy
npx pnpm@10.33.0 install --frozen-lockfile
npx pnpm@10.33.0 --filter @all/workers test
npx pnpm@10.33.0 typecheck
PYTHONPATH=apps/voice/src python -m unittest discover -s apps/voice/tests
```
