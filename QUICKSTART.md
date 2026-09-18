# MyOpenCode — opencode + aiTunnel. Быстрый старт

Форк [opencode](https://github.com/anomalyco/opencode) с предустановленной интеграцией
**aiTunnel** (~200 моделей, оплата в рублях, официальный каталог
`https://api.aitunnel.ru/public/aitunnel/models/chat`).

Содержимое репозитория:
- `opencode.json` — конфиг с провайдером `aitunnel` и полным каталогом моделей
  (дефолт `aitunnel/auto`, малые задачи `aitunnel/deepseek-v4-flash`);
- `install.cmd` / `install.sh` — установщики (ставит opencode + провайдер глобально);
- `remote-server.sh` — запуск opencode фоном на сервере + доступ через SSH и браузер (GUI, не CLI);
- `install-merge.cjs` — умное слияние конфигов (не затирает твои провайдеры).

---

## 1) PC (Windows / Linux / macOS) — CLI за 1 минуту

### Windows
```
rem 1. ключ НЕ хранится в репо — задаётся тобой один раз:
setx AITUNNEL_API_KEY sk-aiTunnel-xxxxxxxx      (перезапусти терминал)

rem 2. установка:
install.cmd                                     (или просто запусти двойным кликом)
```

### Linux / macOS
```sh
echo 'export AITUNNEL_API_KEY=sk-aiTunnel-xxxxxxxx' >> ~/.bashrc && source ~/.bashrc
./install.sh
```
Если `install.sh` без прав: `chmod +x install.sh && ./install.sh`.

### Проверка после установки (быстрый чеклист)
```sh
opencode models | grep aitunnel/auto        # должен вернуть aitunnel/auto — провайдер виден
opencode                                     # TUI
```
В TUI: `/models` → выбрать `aitunnel/…`. Дефолт уже `aitunnel/auto`.

**Нужен Node.js на Windows** (ставим opencode через npm). Если opencode уже есть — установщик
его не трогает, только дописывает провайдер.

---

## 2) Сервер любой — GUI через SSH (не CLI), 2 минуты

На удалённом сервере (Ubuntu/Debian и т.п.):
```sh
git clone https://github.com/thekingoffamily/MyOpenCode.git && cd MyOpenCode
echo 'export AITUNNEL_API_KEY=sk-aiTunnel-xxxxxxxx' >> ~/.bashrc && source ~/.bashrc
./remote-server.sh          # ставит opencode + tmux-сессию brainai на порту 42042
```
Если хочешь работать в конкретной папке:
```sh
./remote-server.sh /var/www/myproject
```

Со своей машины подключаешься туннелем и открываешь **браузер**:
```sh
ssh -N -L 127.0.0.1:42042:127.0.0.1:42042 user@host
```
→ открыть `http://127.0.0.1:42042` — полноценный GUI opencode на файлах сервера.

### Жизненный цикл сервера
| Что | Команда |
|---|---|
| Логи/консоль сервера | `tmux attach -t brainai` (выход `Ctrl+B` затем `D`) |
| Остановить сервер | `tmux kill-session -t brainai` |
| Перезапуск после ребута | снова `./remote-server.sh` |
| Пароль на сервер (опц.) | `export OPENCODE_SERVER_PASSWORD=secret` перед стартом |

---

## 3) Примечания
- **Ключи в репо не пишутся** — только `{env:AITUNNEL_API_KEY}` в конфиге.
- aiTunnel — реф-ссылка партнёра: `https://aitunnel.ru/?r=52512`
- Конфиг читается при старте opencode — после правок перезапусти.
- `opencode.json` в корне — и проектный конфиг, и источник для установщика (в репо
  добавлен через `git add -f`, т.к. upstream игнорирует `/opencode.json`);
- `aitunnel-relay.cjs` — форвардер для серверов без IPv6 (см. §3.2).
- Обновление opencode: `opencode upgrade` (локально) / `$HOME/.opencode/bin/opencode upgrade`.

## 3.1) Типовые грабли (что означает «работает, но ошибка токена»)
- **PATH внутри tmux пуст для твоего бинаря.** `remote-server.sh` теперь всегда запускает
  бинарь по абсолютному пути (`$HOME/.opencode/bin/opencode`), но если ты поднимал сервер
  вручную как `tmux new-session 'opencode serve …'` — будет `command not found` и сессия
  молча умрёт. Всегда запускай абсолютный путь.
- **Старый процесс держит порт.** Если раньше запускал `opencode web/serve` без ключа,
  а потом перезапустил — старый процесс может видеть на `42042`, и браузер разговаривает
  именно с ним (конфиг без ключа). Лечится перезапуском начисто:
  `fuser -k 42042/tcp; tmux kill-session -t brainai; ./remote-server.sh`.
- **Ключ есть, а токен всё равно не уходит.** Проверь headless-запрос напрямую (без браузера):
  `cd /tmp && timeout 50 opencode run -m aitunnel/deepseek-v4-flash --print-logs "скажи ОК"`.
  Если headless отвечает — ключ/конфиг в порядке, проблема выше (старый процесс/диапазон порта).
  (На некоторых серверах `opencode run` виснет сам по себе — это баг headless-режима,
  TUI и GUI при этом работают.)

## 3.2) Сервер без глобального IPv6 (система: `ip -6 route` → только fe80::)
Симптом: **«токен не указан» в чате, хотя ключ в конфиге есть**, а headless-тест висит.
Причина: `api.aitunnel.ru` отвечает DNS с AAAA первыми, рантайм opencode уходит в IPv6
(которого нет) и запрос не доходит; через IPv4 Cloudflare отвечает отлично.

`remote-server.sh` сам это лечит: если глобального IPv6 нет, он ставит локальный форвардер
(файл `aitunnel-relay.cjs` копируется в `~/.opencode/`) и переводит `baseURL` на
`http://127.0.0.1:8787/v1` (бэкап конфига рядом). Проверка после:
```sh
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8787/x        # -> 200
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:42042/        # -> 200
```
Форвардер живёт отдельно от opencode — после ребута сервера запусти снова:
```sh
pkill -9 -f aitunnel-relay; sleep 1;
nohup env AITUNNEL_RELAY_PORT=8787 node ~/.opencode/aitunnel-relay.cjs > /tmp/relay-nohup.log 2>&1 &
```
⚠️ Не занимай порт `8080` — на многих серверах там nginx (рабочий сайт). Relay использует 8787.

## Чеклист «всё запустить и проверить»
- [ ] `opencode --version` — выводит версию, без ошибок.
- [ ] `opencode models` — среди моделей есть `aitunnel/…`.
- [ ] `AITUNNEL_API_KEY` задан (`echo $AITUNNEL_API_KEY` / `%AITUNNEL_API_KEY%`).
- [ ] Первый запрос в чате отвечает (модель `aitunnel/auto`).
- [ ] (сервер) `./remote-server.sh` → `tmux ls` показывает `brainai`.
- [ ] (сервер) `curl -s -o /dev/null -w %{http_code} http://127.0.0.1:42042` → `200`.
- [ ] Туннель открыл `http://127.0.0.1:42042` в браузере — GUI работает.