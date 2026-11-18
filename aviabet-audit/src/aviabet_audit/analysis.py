"""Read-only statistical analysis of historical crash-game round results."""

from __future__ import annotations

import argparse
import csv
import io
import math
import statistics
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, Sequence


MAX_ROWS = 100_000
MIN_MULTIPLIER = 1.0
MAX_MULTIPLIER = 1_000_000_000.0
REQUIRED_COLUMNS = {"round_id", "multiplier"}


class AuditDataError(ValueError):
    """Raised when a round-history CSV is malformed or unsafe to process."""


@dataclass(frozen=True)
class RoundRecord:
    round_id: str
    multiplier: float
    timestamp: str = ""


@dataclass(frozen=True)
class AuditReport:
    count: int
    mean: float
    median: float
    minimum: float
    maximum: float
    threshold_rates: dict[float, float]
    lag1_correlation: float | None
    runs_z_score: float | None
    warnings: tuple[str, ...]


def _parse_iso_timestamp(value: str, line_number: int) -> datetime:
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise AuditDataError(
            f"Line {line_number}: timestamp must be ISO-8601"
        ) from exc
    if parsed.tzinfo is None:
        raise AuditDataError(
            f"Line {line_number}: timestamp must include a timezone"
        )
    return parsed.astimezone(timezone.utc)


def load_rounds(csv_text: str) -> list[RoundRecord]:
    """Parse, validate, deduplicate, and chronologically order round history."""
    if not isinstance(csv_text, str):
        raise TypeError("csv_text must be a string")
    if len(csv_text.encode("utf-8")) > 1_048_576:
        raise AuditDataError("CSV exceeds the 1 MiB processing limit")

    reader = csv.DictReader(io.StringIO(csv_text.lstrip("\\ufeff")))
    if not reader.fieldnames:
        raise AuditDataError("CSV is empty or has no header")

    headers = {name.strip() for name in reader.fieldnames if name}
    missing = REQUIRED_COLUMNS - headers
    if missing:
        raise AuditDataError(
            "Missing required CSV column(s): " + ", ".join(sorted(missing))
        )

    records: list[RoundRecord] = []
    seen_ids: set[str] = set()
    parsed_timestamps: list[datetime] = []

    for line_number, row in enumerate(reader, start=2):
        if len(records) >= MAX_ROWS:
            raise AuditDataError(f"CSV exceeds the {MAX_ROWS:,} row limit")

        normalized = {
            (key or "").strip(): (value or "").strip()
            for key, value in row.items()
            if key is not None
        }
        round_id = normalized.get("round_id", "")
        raw_multiplier = normalized.get("multiplier", "")
        timestamp = normalized.get("timestamp", "")

        if not round_id:
            raise AuditDataError(f"Line {line_number}: round_id is empty")
        if len(round_id) > 100:
            raise AuditDataError(f"Line {line_number}: round_id is too long")
        if round_id in seen_ids:
            raise AuditDataError(f"Duplicate round_id: {round_id}")

        try:
            multiplier = float(raw_multiplier)
        except (TypeError, ValueError) as exc:
            raise AuditDataError(
                f"Line {line_number}: multiplier is not numeric"
            ) from exc

        if not math.isfinite(multiplier):
            raise AuditDataError(f"Line {line_number}: multiplier must be finite")
        if multiplier < MIN_MULTIPLIER or multiplier > MAX_MULTIPLIER:
            raise AuditDataError(
                f"Line {line_number}: multiplier must be between "
                f"{MIN_MULTIPLIER:g} and {MAX_MULTIPLIER:g}"
            )

        if timestamp:
            parsed_timestamps.append(_parse_iso_timestamp(timestamp, line_number))
        seen_ids.add(round_id)
        records.append(RoundRecord(round_id, multiplier, timestamp))

    if not records:
        raise AuditDataError("CSV contains no round records")

    # Prefer explicit timezone-aware timestamps. Otherwise numeric IDs are
    # treated as chronological. For nonnumeric IDs, preserve CSV row order.
    if len(parsed_timestamps) == len(records):
        records = [
            record
            for _, record in sorted(
                zip(parsed_timestamps, records), key=lambda item: item[0]
            )
        ]
    elif all(record.round_id.isdecimal() for record in records):
        records.sort(key=lambda record: int(record.round_id))

    return records


def _pearson_correlation(left: Sequence[float], right: Sequence[float]) -> float | None:
    if len(left) != len(right) or len(left) < 2:
        return None
    mean_left = statistics.fmean(left)
    mean_right = statistics.fmean(right)
    centered_left = [value - mean_left for value in left]
    centered_right = [value - mean_right for value in right]
    sum_left = sum(value * value for value in centered_left)
    sum_right = sum(value * value for value in centered_right)
    denominator = math.sqrt(sum_left * sum_right)
    if denominator == 0:
        return None
    return sum(
        x * y for x, y in zip(centered_left, centered_right)
    ) / denominator


def _runs_test_z(values: Sequence[float]) -> float | None:
    """Wald-Wolfowitz runs-test z score after splitting at the sample median."""
    if len(values) < 3:
        return None

    midpoint = statistics.median(values)
    signs = [value > midpoint for value in values if value != midpoint]
    n1 = sum(signs)
    n2 = len(signs) - n1
    if n1 == 0 or n2 == 0 or n1 + n2 < 3:
        return None

    runs = 1 + sum(signs[index] != signs[index - 1] for index in range(1, len(signs)))
    total = n1 + n2
    expected = 1 + (2 * n1 * n2) / total
    variance = (
        2 * n1 * n2 * (2 * n1 * n2 - n1 - n2)
        / (total * total * (total - 1))
    )
    if variance <= 0:
        return None
    return (runs - expected) / math.sqrt(variance)


def analyze_rounds(records: Iterable[RoundRecord]) -> AuditReport:
    rows = list(records)
    if len(rows) < 2:
        raise AuditDataError("At least two rounds are required for analysis")

    values = [row.multiplier for row in rows]
    if any(not math.isfinite(value) or value < MIN_MULTIPLIER for value in values):
        raise AuditDataError("Round multipliers contain invalid values")

    thresholds = (1.5, 2.0, 5.0, 10.0)
    threshold_rates = {
        threshold: sum(value >= threshold for value in values) / len(values)
        for threshold in thresholds
    }
    correlation = _pearson_correlation(values[:-1], values[1:])
    runs_z = _runs_test_z(values)

    warnings: list[str] = []
    if len(rows) < 100:
        warnings.append(
            "Small sample: fewer than 100 rounds. Statistical signals are weak."
        )
    if len(rows) < 1_000:
        warnings.append(
            "Do not interpret these diagnostics as evidence of future predictability."
        )
    if correlation is None:
        warnings.append(
            "Lag-1 correlation is undefined (insufficient variation or sample size)."
        )
    if runs_z is None:
        warnings.append("Runs-test statistic could not be calculated for this sample.")

    return AuditReport(
        count=len(values),
        mean=statistics.fmean(values),
        median=statistics.median(values),
        minimum=min(values),
        maximum=max(values),
        threshold_rates=threshold_rates,
        lag1_correlation=correlation,
        runs_z_score=runs_z,
        warnings=tuple(warnings),
    )


def format_report(report: AuditReport) -> str:
    lines = [
        "AviaBET Demo — تقرير تحليل تاريخي",
        f"عدد الجولات: {report.count}",
        f"المتوسط: {report.mean:.4f}x",
        f"الوسيط: {report.median:.4f}x",
        f"الأدنى / الأعلى: {report.minimum:.4f}x / {report.maximum:.4f}x",
        "",
        "نسبة النتائج التي بلغت العتبة أو تجاوزتها:",
    ]
    for threshold, rate in report.threshold_rates.items():
        lines.append(f"  {threshold:g}x أو أكثر: {rate * 100:.2f}%")

    lines.extend(
        [
            "",
            "فحوص تشخيصية (ليست تنبؤاً):",
            (
                f"ارتباط الرتبة الأولى: {report.lag1_correlation:.4f}"
                if report.lag1_correlation is not None
                else "ارتباط الرتبة الأولى: غير متاح"
            ),
            (
                f"إحصائية Runs Z: {report.runs_z_score:.4f}"
                if report.runs_z_score is not None
                else "إحصائية Runs Z: غير متاحة"
            ),
            "",
            "تنبيه: تحليل الجولات السابقة لا يكشف نتيجة الجولة القادمة.",
        ]
    )
    if report.warnings:
        lines.append("")
        lines.append("ملاحظات:")
        lines.extend(f"- {warning}" for warning in report.warnings)
    return "\n".join(lines)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Analyze historical AviaBET Demo round data from CSV."
    )
    parser.add_argument("csv_file", type=Path, help="CSV with round_id,multiplier")
    args = parser.parse_args(argv)

    try:
        text = args.csv_file.read_text(encoding="utf-8-sig")
        records = load_rounds(text)
        report = analyze_rounds(records)
    except (OSError, UnicodeError, AuditDataError) as exc:
        print(f"خطأ في قراءة البيانات: {exc}", file=sys.stderr)
        return 2

    print(format_report(report))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
