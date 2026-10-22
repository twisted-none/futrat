# Stale live status correction

Approved: 18 October 2026, пользователь подтвердил brief после диагностики.

## Scope

Явные live-статусы и ограничение давности начала на бекенде и в приложении. Старые ошибочные LIVE сохраняются в истории без автоматического назначения FINISHED.

## Delivery

- [x] Регрессионные тесты воспроизвели августовский матч в live до исправления.
- [x] API: вычисляемый is_live и фильтр GET /api/matches?live=true.
- [x] Общее правило: распознанный live-статус / футбольные минуты, начало от нуля до шести часов назад.
- [x] Приложение: локальный фильтр и обработка серверного is_live; метки и таймер используют то же правило.
- [x] История и исходные результаты сохранены; устаревший live показывает «Статус уточняется».
- [x] Бекенд: 90 тестов Docker/PostgreSQL; Windows 89 passed, 1 platform skip.
- [x] Flutter: 35 тестов, анализатор без ошибок/warning, 67 прежних info.
- [x] Рабочий API исключает local ID 5722 из live, оставляет is_live=false/status=IN_PLAY/счёт 3:0 в истории.
- [x] Debug APK собран; граф кода обновлён (1313 узлов, 2399 связей).
- [ ] Установка и проверка на телефоне: ADB не видит устройство; пользователю отправлена просьба подключить USB.

## Files

Правила: app/live_matches.py, lib/core/match_status.dart. API: app/schemas.py, app/routers/data.py. Клиент: all_models.dart, DataProvider, grouped_matches_list, home_screen, match_detail_screen, match_tile. Описание: futrat_backend/docs/live-matches.md.
