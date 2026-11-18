"""Minimal Telegram Bot API polling client for CSV audit reports.

Uses only Python's standard library. No Telegram token is stored in source.
"""

from __future__ import annotations

import json
import logging
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

from .analysis import AuditDataError, analyze_rounds, format_report, load_rounds


LOGGER = logging.getLogger("aviabet_audit.telegram")
DEFAULT_MAX_CSV_BYTES = 1_048_576
API_TIMEOUT_SECONDS = 40


class TelegramAPIError(RuntimeError):
    pass


class TelegramBot:
    def __init__(self, token: str, allowed_chat_ids: set[int], max_csv_bytes: int):
        if not token:
            raise ValueError("TELEGRAM_BOT_TOKEN is required")
        if not allowed_chat_ids:
            raise ValueError("TELEGRAM_ALLOWED_CHAT_IDS must contain at least one ID")
        if max_csv_bytes < 1 or max_csv_bytes > DEFAULT_MAX_CSV_BYTES:
            raise ValueError("MAX_CSV_BYTES must be between 1 and 1048576")
        self.token = token
        self.allowed_chat_ids = allowed_chat_ids
        self.max_csv_bytes = max_csv_bytes
        self.base_url = f"https://api.telegram.org/bot{token}"

    def _api(self, method: str, payload: dict[str, Any] | None = None) -> Any:
        body = json.dumps(payload or {}).encode("utf-8")
        request = urllib.request.Request(
            f"{self.base_url}/{method}",
            data=body,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=API_TIMEOUT_SECONDS) as response:
                result = json.loads(response.read().decode("utf-8"))
        except (urllib.error.URLError, TimeoutError, UnicodeError, json.JSONDecodeError) as exc:
            raise TelegramAPIError(f"Telegram API request failed: {type(exc).__name__}") from exc

        if not result.get("ok"):
            raise TelegramAPIError("Telegram API returned an unsuccessful response")
        return result.get("result")

    def _send(self, chat_id: int, text: str) -> None:
        # Telegram messages have a 4096-character limit; keep a safety margin.
        self._api("sendMessage", {"chat_id": chat_id, "text": text[:3900]})

    def _download_document(self, file_id: str, advertised_size: int | None) -> str:
        if advertised_size is not None and advertised_size > self.max_csv_bytes:
            raise AuditDataError("حجم ملف CSV يتجاوز الحد المسموح (1 MiB).")

        file_info = self._api("getFile", {"file_id": file_id})
        file_path = file_info.get("file_path")
        if not isinstance(file_path, str) or not file_path:
            raise AuditDataError("تعذر الحصول على مسار ملف CSV.")

        # file_path comes from Telegram's getFile response; quote it as path data.
        encoded_path = urllib.parse.quote(file_path, safe="/")
        request = urllib.request.Request(
            f"https://api.telegram.org/file/bot{self.token}/{encoded_path}",
            method="GET",
        )
        try:
            with urllib.request.urlopen(request, timeout=API_TIMEOUT_SECONDS) as response:
                data = response.read(self.max_csv_bytes + 1)
        except (urllib.error.URLError, TimeoutError) as exc:
            raise TelegramAPIError("تعذر تنزيل الملف من Telegram") from exc

        if len(data) > self.max_csv_bytes:
            raise AuditDataError("حجم ملف CSV يتجاوز الحد المسموح (1 MiB).")
        try:
            return data.decode("utf-8-sig")
        except UnicodeDecodeError as exc:
            raise AuditDataError("يجب أن يكون ملف CSV بترميز UTF-8.") from exc

    def _handle_message(self, message: dict[str, Any]) -> None:
        chat = message.get("chat") or {}
        chat_id = chat.get("id")
        if not isinstance(chat_id, int) or chat_id not in self.allowed_chat_ids:
            # Do not disclose whether the bot exists to unauthorized chats.
            return

        text = (message.get("text") or "").strip()
        if text.startswith("/start") or text.startswith("/help"):
            self._send(
                chat_id,
                "بوت تدقيق AviaBET Demo.\n"
                "أرسل ملف CSV يحتوي على round_id,multiplier.\n"
                "سأرجع ملخصاً إحصائياً تاريخياً فقط؛ لا أتوقع الجولة القادمة "
                "ولا أرسل رهانات أو أوامر Cash Out.",
            )
            return

        document = message.get("document")
        if not document:
            self._send(chat_id, "أرسل ملف CSV فقط، مع عمودي round_id وmultiplier.")
            return

        file_name = str(document.get("file_name") or "")
        if not file_name.lower().endswith(".csv"):
            self._send(chat_id, "نوع الملف غير مدعوم. أرسل ملفاً بامتداد CSV.")
            return

        try:
            csv_text = self._download_document(
                str(document.get("file_id", "")),
                document.get("file_size"),
            )
            records = load_rounds(csv_text)
            report = analyze_rounds(records)
            self._send(chat_id, format_report(report))
        except (AuditDataError, TelegramAPIError) as exc:
            self._send(chat_id, f"تعذر تحليل الملف: {exc}")
        except Exception as exc:  # Never send exception internals or file contents to chat.
            LOGGER.error("Unexpected processing error: %s", type(exc).__name__)
            self._send(chat_id, "حدث خطأ داخلي أثناء التحليل. لم يتم حفظ الملف.")

    def run_forever(self) -> None:
        offset: int | None = None
        LOGGER.info("AviaBET audit bot started; authorized chats: %d", len(self.allowed_chat_ids))
        while True:
            payload: dict[str, Any] = {
                "timeout": 25,
                "allowed_updates": ["message"],
            }
            if offset is not None:
                payload["offset"] = offset
            try:
                updates = self._api("getUpdates", payload)
                for update in updates:
                    if not isinstance(update, dict):
                        continue
                    offset = int(update.get("update_id", 0)) + 1
                    message = update.get("message")
                    if isinstance(message, dict):
                        self._handle_message(message)
            except TelegramAPIError as exc:
                LOGGER.warning("%s; retrying after 3 seconds", exc)
                time.sleep(3)


def _parse_chat_ids(raw: str) -> set[int]:
    ids: set[int] = set()
    for item in raw.split(","):
        value = item.strip()
        if not value:
            continue
        try:
            ids.add(int(value))
        except ValueError as exc:
            raise ValueError("TELEGRAM_ALLOWED_CHAT_IDS must contain numeric IDs") from exc
    return ids


def main() -> int:
    logging.basicConfig(
        level=os.getenv("LOG_LEVEL", "INFO").upper(),
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    token = os.getenv("TELEGRAM_BOT_TOKEN", "").strip()
    allowed_ids = _parse_chat_ids(os.getenv("TELEGRAM_ALLOWED_CHAT_IDS", ""))
    try:
        max_bytes = int(os.getenv("MAX_CSV_BYTES", str(DEFAULT_MAX_CSV_BYTES)))
        bot = TelegramBot(token, allowed_ids, max_bytes)
    except ValueError as exc:
        LOGGER.error("Configuration error: %s", exc)
        return 2

    try:
        bot.run_forever()
    except KeyboardInterrupt:
        LOGGER.info("Bot stopped")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
