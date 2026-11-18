import unittest

from aviabet_audit.analysis import (
    AuditDataError,
    analyze_rounds,
    load_rounds,
)
from aviabet_audit.hash_verify import sha512_hex, verify_sha512_preimage


class LoadRoundsTests(unittest.TestCase):
    def test_loads_and_sorts_numeric_round_ids(self):
        rows = load_rounds(
            "round_id,multiplier\n"
            "12,2.0\n"
            "10,1.2\n"
            "11,1.5\n"
        )
        self.assertEqual([row.round_id for row in rows], ["10", "11", "12"])

    def test_rejects_duplicate_round_ids(self):
        with self.assertRaises(AuditDataError):
            load_rounds("round_id,multiplier\n1,1.2\n1,1.8\n")

    def test_rejects_nan_multiplier(self):
        with self.assertRaises(AuditDataError):
            load_rounds("round_id,multiplier\n1,nan\n")

    def test_rejects_multiplier_below_one(self):
        with self.assertRaises(AuditDataError):
            load_rounds("round_id,multiplier\n1,0.99\n")

    def test_requires_columns(self):
        with self.assertRaises(AuditDataError):
            load_rounds("id,value\n1,1.2\n")


class AnalyzeRoundsTests(unittest.TestCase):
    def test_summary_values(self):
        records = load_rounds(
            "round_id,multiplier\n"
            "1,1.0\n"
            "2,2.0\n"
            "3,3.0\n"
            "4,4.0\n"
        )
        report = analyze_rounds(records)
        self.assertEqual(report.count, 4)
        self.assertAlmostEqual(report.mean, 2.5)
        self.assertAlmostEqual(report.median, 2.5)
        self.assertAlmostEqual(report.minimum, 1.0)
        self.assertAlmostEqual(report.maximum, 4.0)
        self.assertAlmostEqual(report.threshold_rates[2.0], 0.75)

    def test_requires_two_rounds(self):
        records = load_rounds("round_id,multiplier\n1,1.3\n")
        with self.assertRaises(AuditDataError):
            analyze_rounds(records)


class HashVerificationTests(unittest.TestCase):
    def test_sha512_known_preimage(self):
        digest = sha512_hex("abc")
        self.assertEqual(
            digest,
            "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a"
            "2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f",
        )
        self.assertTrue(verify_sha512_preimage("abc", digest))

    def test_rejects_wrong_or_malformed_digest(self):
        self.assertFalse(verify_sha512_preimage("abc", "not-a-hash"))
        self.assertFalse(verify_sha512_preimage("abc", "0" * 128))


if __name__ == "__main__":
    unittest.main()
