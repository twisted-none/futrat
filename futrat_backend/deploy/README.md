# Deployment: Ubuntu, existing Caddy and PostgreSQL

Инструкция для сервера `176.108.255.248`. На нём уже работают контейнеры `caddy`, `postgresql` (PostgreSQL 15) и другие проекты. `compose.prod.yml` управляет только Futrat. База Futrat хранится в существующем volume PostgreSQL; новый volume или сервер БД не создаётся. Команды ниже выполняются **на Ubuntu**, из каталога `futrat_backend`, если не указано иначе.

## Preparation

Перед запуском уточните версию Caddy и расположение его конфигурации:

```bash
docker exec caddy caddy version
docker inspect caddy --format '{{json .Mounts}}'
docker inspect caddy postgresql --format '{{.Name}}: {{range $name, $config := .NetworkSettings.Networks}}{{$name}} {{end}}'
docker compose version
```

Полный `docker inspect` и обычный `docker compose config` могут раскрывать секреты: используйте только приведённые поля и `config --quiet`. Проверьте наличие постоянных хранилищ PostgreSQL и `/data` Caddy: там сохраняются данные БД, сертификаты и ACME-аккаунт. Не удаляйте и не пересоздавайте их для установки Futrat.

Скопируйте на сервер актуальные `Dockerfile`, `.dockerignore`, `requirements.txt`, `app/`, `compose.prod.yml` и `deploy/`. Передача только Git HEAD сейчас недостаточна: в рабочем каталоге есть ещё не закоммиченные необходимые файлы. Локальные `.env`, ключи, кеши, `.venv` и сборки Flutter не передавайте вместе с исходниками. Передавайте серверный конфиг отдельно и только по защищённому соединению.

## Networks

Рекомендуются две отдельные сети: `futrat_proxy` для Caddy и Futrat, `futrat_database` для PostgreSQL и Futrat. Сначала проверьте, не созданы ли они уже, затем создайте отсутствующие:

```bash
docker network ls
docker network create futrat_proxy
docker network create --internal futrat_database
docker network connect futrat_proxy caddy
docker network connect --alias postgresql futrat_database postgresql
```

`docker network connect` действует до пересоздания контейнера. Чтобы связь переживала обновления существующего стека, добавьте эти внешние сети в **исходный Compose существующих проектов**, сохранив все их прежние сети:

```yaml
# Дополнение к Compose, которому принадлежит Caddy:
services:
  caddy:
    networks:
      # Здесь также остаются все прежние сети Caddy.
      futrat_proxy: {}
networks:
  futrat_proxy:
    external: true
    name: futrat_proxy
```

```yaml
# Дополнение к Compose, которому принадлежит PostgreSQL:
services:
  postgresql:
    networks:
      # Здесь также остаются все прежние сети PostgreSQL.
      futrat_database:
        aliases: [postgresql]
networks:
  futrat_database:
    external: true
    name: futrat_database
```

Это фрагменты для ручного объединения, а не замена существующих файлов. Если сервисы сейчас используют неявную сеть `default`, при добавлении явных сетей сохраните и `default: {}`. Имя сервиса в существующем Compose может отличаться от имени контейнера — проверьте исходный файл. После ручного подключения сетей пересоздавать рабочие контейнеры сейчас не требуется.

Не подключайте другие приложения к `futrat_proxy`: Uvicorn доверяет заголовкам прокси на этой сети. Административный порт Caddy `2019` не публикуйте. Бекенд не использует внешний порт PostgreSQL `5433`, а подключается к `postgresql:5432` внутри Docker. Если выбираете другие названия сетей, укажите их в серверных настройках.

## Database

Сначала сделайте штатную резервную копию существующего PostgreSQL. Следующий скрипт предназначен **только для первого создания** роли и БД `futrat`:

```bash
docker exec -i postgresql psql -U postgres -d postgres -v ON_ERROR_STOP=1 < deploy/create-database.sql
docker exec -it postgresql psql -U postgres -d postgres
```

В открывшемся psql:

```text
\password futrat
\q
```

Введите новый пароль дважды. Для удобства URL используйте случайный hex-пароль, например созданный `openssl rand -hex 24`; сохраните его в менеджере паролей и впишите в серверный конфиг. Не отправляйте его в чат. Если пароль содержит специальные символы, процентно закодируйте их в `DATABASE_URL`.

Если администратор вашей PostgreSQL называется иначе, замените `-U postgres`. При необходимости используйте существующий безопасный способ локальной аутентификации администратора; не меняйте глобальный `pg_hba.conf` на `trust`. Если роль или БД уже существует, скрипт остановится: проверьте владельца и назначение перед продолжением. Скрипт не меняет базы других проектов и не выдаёт роли Futrat права суперпользователя. Существующие разрешения `PUBLIC` в других БД он также не изменяет.

## Configuration

```bash
umask 077
cp deploy/.env.example deploy/.env.production
chmod 600 deploy/.env.production
nano deploy/.env.production
```

Замените пароль БД и `SECRET_KEY` (отдельный случайный ключ: `openssl rand -hex 32`). Для первого релиза укажите `FUTRAT_IMAGE=futrat-api:initial`. `APP_ENV=production` и `ALGORITHM=HS256` зафиксированы в Compose. `GOAL_API_KEY` вводите только на сервере; ESPN работает без ключа, турниры, доступные только через GOAL, требуют его. Сохранён лимит GOAL 900 запросов в сутки.

Production-проверки требуют именно БД и роль `futrat`, чтобы случайно не запустить создание таблиц в другом проекте. Шаблонные секреты не проходят проверку. При старте не создаётся тестовый Admin. Если перенесённый тестовый Admin сохранил старый пароль, запуск остановится без удаления пользователей. Для смены пароля перед запуском можно выполнить интерактивно (хеш и пароль не печатаются):

```bash
docker compose --env-file deploy/.env.production -f compose.prod.yml run --rm --no-deps futrat-api python -c '
from getpass import getpass
from app.database import SessionLocal
from app import models
from app.credentials import validate_new_password
from app.security import get_password_hash
password = validate_new_password(getpass("New Admin password: "))
assert password == getpass("Repeat password: "), "Passwords differ"
with SessionLocal() as db:
    user = db.query(models.User).filter(models.User.username_key == "admin").one()
    user.hashed_password = get_password_hash(password)
    db.commit()
'
```

Эта команда предназначена для уже перенесённой БД с актуальной схемой пользователей. Для старой схемы сначала выполните миграцию из раздела переноса ниже. Создавать тестовый аккаунт в пустой production-БД не нужно.

## Start

```bash
docker compose --env-file deploy/.env.production -f compose.prod.yml config --quiet
docker compose --env-file deploy/.env.production -f compose.prod.yml build futrat-api
docker compose --env-file deploy/.env.production -f compose.prod.yml up -d --wait --wait-timeout 120 futrat-api
docker compose --env-file deploy/.env.production -f compose.prod.yml ps
docker compose --env-file deploy/.env.production -f compose.prod.yml exec -T futrat-api python -c "from urllib.request import urlopen; print(urlopen('http://127.0.0.1:8000/health/ready').read().decode())"
```

Один процесс Uvicorn запускает API и планировщик. Не увеличивайте `--workers` и не масштабируйте сервис без отдельного решения для фоновых задач. При запуске идемпотентно создаются недостающие таблицы и применяется существующая миграция пользователей. Пул ограничен десятью соединениями; процесс работает как UID 10001, корневая файловая система доступна только для чтения, логи ротируются.

`/health/ready` возвращает 200 при доступной БД и 503 при её недоступности. Docker помечает сервис как unhealthy, но сам по себе этот статус не перезапускает живой процесс; `restart: unless-stopped` применяется при завершении процесса. Для наблюдения используйте существующую инфраструктуру мониторинга.

## Caddy and IP HTTPS

Локальная проверка конфигурации выполнялась на `caddy:2.11.7-alpine`. Сначала сравните версию существующего контейнера. Для старой версии не обновляйте весь стек вслепую: сохраните конфигурацию, постоянные хранилища и подготовьте совместимое обновление только Caddy. Автоматическое получение IP-сертификата требует поддержки ACME-профиля `shortlived`.

1. Сохраните резервную копию текущего Caddyfile на хосте.
2. Если в нём уже есть сайт `176.108.255.248`, объедините его настройки с новым блоком. Второй блок с тем же адресом не добавляйте.
3. Объедините содержимое `Caddyfile.futrat` с текущим файлом либо разместите его в уже смонтированном каталоге и добавьте подходящий `import`. Путь внутри контейнера определяется существующими mounts. Файл должен оставаться на хосте, чтобы изменение пережило пересоздание контейнера.
4. В **существующий** глобальный блок `{ ... }` добавьте `default_sni 176.108.255.248`. Если блока нет — создайте один в начале файла. Это позволяет клиентам, которые не передают SNI для IP, получить нужный сертификат. Если `default_sni` уже занят другим сервисом, сначала согласуйте маршрутизацию; не заменяйте его автоматически.
5. Сохраните остальные сайты, настройки и постоянный `/data` Caddy.

Пример объединения:

```caddyfile
{
    # Существующие глобальные параметры остаются здесь.
    default_sni 176.108.255.248
}

# Существующие сайты остаются здесь.
import /etc/caddy/conf.d/Caddyfile.futrat
```

Путь ниже — типичный; используйте фактический путь из конфигурации запуска Caddy:

```bash
docker exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
docker exec caddy wget -qO- http://futrat-api:8000/health/ready
curl --fail --show-error https://176.108.255.248/health/ready
curl --fail --show-error https://176.108.255.248/api/tournaments
```

Успешный `validate` подтверждает конфигурацию, но не выдачу публичного сертификата. Let’s Encrypt должен достичь сервера на 80/443; Caddy автоматически выдаёт и продлевает сертификат. IP-сертификат живёт около шести суток, поэтому Caddy и его постоянное хранилище нужны непрерывно. Не используйте `tls internal`, самоподписанный сертификат, `curl -k` или отключение TLS-проверок в приложении. Проверяйте HTTPS также с другого устройства через мобильный интернет и работу прежних сайтов после reload. На сервере уже наблюдалось перенаправление HTTP на HTTPS, но успешное TLS-соединение и работа API пока не подтверждены.

Источники: [Let’s Encrypt: IP certificates](https://letsencrypt.org/2026/01/15/6day-and-ip-general-availability), [Caddy: ACME profile](https://caddyserver.com/docs/caddyfile/directives/tls#issuers), [Caddy: default_sni](https://caddyserver.com/docs/caddyfile/options#default-sni), [Docker: external networks](https://docs.docker.com/compose/how-tos/networking/#use-an-existing-network).

## Backups and restore

После первого запуска и перед каждым обновлением:

```bash
bash deploy/backup.sh /opt/futrat-backups
```

Скрипт делает custom-format dump **только БД futrat**, с правами файла 600; незавершённый dump не публикуется как готовая копия. Контейнер и администратор переопределяются переменными `FUTRAT_POSTGRES_CONTAINER` и `FUTRAT_POSTGRES_ADMIN`. Существующий `db-backup` может ещё не включать новую БД — проверьте его настройки. Настройте регулярный запуск этого скрипта в своей системе резервного копирования, срок хранения и копию вне сервера. Скрипт сам старые копии не удаляет.

Проверяйте восстановление в отдельную временную БД, используя свободное имя:

```bash
docker exec postgresql createdb -U postgres -O futrat futrat_restore_check
docker exec -i postgresql pg_restore -U postgres --role=futrat --dbname=futrat_restore_check --no-owner --no-acl --exit-on-error < /opt/futrat-backups/SELECT_BACKUP.dump
docker exec postgresql psql -U postgres -d futrat_restore_check -c 'SELECT count(*) FROM users;'
```

Для реального восстановления остановите только `futrat-api`, восстановите выбранную копию в отдельную БД и проверьте её. Затем, когда соединения с обеими БД закрыты, переименуйте текущую `futrat` в свободное имя с датой, а проверенную БД — в `futrat`. Перед запуском примените к восстановленной БД `REVOKE ALL ON DATABASE futrat FROM PUBLIC; REVOKE ALL ON SCHEMA public FROM PUBLIC;` и проверьте права владельца. Старую БД сохраняйте до завершения проверки. Не используйте восстановление всего кластера или `pg_restore --clean` на общем PostgreSQL.

## Existing local data

Пустая БД загрузит турниры и матчи из источников в фоне. Локальные пользователи, избранное, оценки и прогнозы автоматически не переносятся. Если их нужно сохранить:

1. Приостановите запись в локальный API на время финального экспорта.
2. Сделайте `pg_dump --format=custom --no-owner --no-acl` локальной **БД Futrat**, не всего кластера. Передавайте dump как приватные данные, отдельно от исходников.
3. До первого запуска API импортируйте dump в пустую серверную `futrat` командой `pg_restore -U postgres --role=futrat --dbname=futrat --no-owner --no-acl --exit-on-error`. Не импортируйте поверх уже заполненной базы.
4. Выполните миграцию пользователей до интерактивной смены пароля тестового Admin:

```bash
docker compose --env-file deploy/.env.production -f compose.prod.yml run --rm --no-deps futrat-api python -c 'from app.database import engine; from app.user_migration import ensure_user_schema; ensure_user_schema(engine)'
```

5. Смените старый тестовый пароль, если такой аккаунт есть, затем запустите API. Совпадения нормализованных никнеймов миграция останавливает для ручного разбора; ID, хеши паролей и связи пользователей сохраняются.

Новый `SECRET_KEY` означает повторный вход пользователей. Не переносите старый ключ только ради сохранения сессий.

## Update and rollback

Перед обновлением сохраните тег рабочего образа и сделайте резервную копию БД. Для нового образа задайте отдельный тег `FUTRAT_IMAGE=futrat-api:RELEASE_TAG` в серверном конфиге, затем выполните `build` и `up -d --wait` из раздела Start. Не перезаписывайте предыдущий тег: он нужен для отката.

При проблеме верните прежний тег `FUTRAT_IMAGE` и выполните `up -d --no-build --wait futrat-api`. Откат образа допускается только при совместимой схеме БД; перед ним прочитайте изменения миграций. Если нужна старая схема, используйте проверенную копию Futrat и процедуру восстановления выше. Для отката конфигурации Caddy верните сохранённый файл, проверьте его и выполните reload. Команды `down` для общего стека и `down -v` для PostgreSQL здесь не нужны.

## Android

После успешной внешней проверки API собрать приложение на рабочем компьютере:

```powershell
Set-Location D:\projects\futrat\futrat_mobile
C:\flutter\bin\flutter.bat build apk --debug --dart-define=API_BASE_URL=https://176.108.255.248
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

Это сборка для проверки на телефоне. Подписанный release для публикации готовится отдельно. Проверьте загрузку турниров, вход/регистрацию и избранное с отключённым USB, без `adb reverse`, через Wi-Fi и мобильную сеть.
