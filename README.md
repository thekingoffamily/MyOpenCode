# opencode + aiTunnel

Официальный [opencode](https://github.com/anomalyco/opencode) (клон `5a83358`) +
провайдер **aiTunnel** — OpenAI-совместимый агрегатор (200+ моделей, оплата в рублях, без VPN).

Провайдер подключается **конфигом** (`opencode.json`), а не пересборкой — opencode умеет
кастомные OpenAI-compatible провайдеры из коробки. Поэтому «проект» собирается за минуту.

## Быстрый старт

1. Задай свой ключ с https://aitunnel.ru (один раз):
   ```
   setx AITUNNEL_API_KEY sk-...
   ```
   перезапусти терминал, чтобы переменная подхватилась.

2. Запусти opencode из любной папки:
   ```
   opencode
   ```
   (или двойной клик по `start.cmd` из этой папки).

3. Модели aiTunnel доступны как `aitunnel/<id>` — переключение через `/models`.
   - по умолчанию: `aitunnel/auto` — умный серверный роутинг (дешёвая CN-модель на простых задачах, сильнее — когда надо думать);
   - дешёвые и быстрые: `aitunnel/deepseek-v4-flash`, `aitunnel/qwen3-coder`;
   - топ: `aitunnel/claude-opus-5`, `aitunnel/gpt-6-astra`, `aitunnel/kimi-k3`, `aitunnel/gemini-3.8-flash`.

## Файлы

| Файл | Назначение |
| --- | --- |
| `opencode.json` | провайдер `aitunnel` + весь каталог моделей (дефолт `aitunnel/auto`) |
| `start.cmd` | лаунчер (проверяет ключ, запускает `opencode`) |
| `.opencode/opencode.jsonc.upstream-dev` | dev-конфиг самих разработчиков opencode — отключён: ключ `references` не поддерживается в установленной stable-версии opencode |

Провайдер также прописан глобально: `~/.config/opencode/opencode.json` — работает из любой папки.

## Каталог моделей

Полный список (≈170 id) — в `opencode.json`. Регистрация aiTunnel на %-м ссылке:
https://aitunnel.ru/?r=52512

## Заметки

- Для большинства моделей нужно прописывание в `models` списка — уже сделано.
- Если модель не в списке, но есть в каталоге https://api.aitunnel.ru/public/aitunnel/models/chat —
  допиши id в `models` в `opencode.json` или `.config/opencode/opencode.json`.
- Изменения `opencode.json` применяются после перезапуска opencode.