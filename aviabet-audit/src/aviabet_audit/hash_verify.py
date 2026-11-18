"""Verify a known SHA-512 preimage against a published digest.

This intentionally does not guess the provider's Key/Salt serialization.
The caller must supply the exact byte sequence documented by the provider.
"""

from __future__ import annotations

import hashlib
import hmac


def sha512_hex(preimage: str) -> str:
    """Return the lowercase SHA-512 hex digest of an exact UTF-8 string."""
    if not isinstance(preimage, str):
        raise TypeError("preimage must be a string")
    return hashlib.sha512(preimage.encode("utf-8")).hexdigest()


def verify_sha512_preimage(preimage: str, expected_hex: str) -> bool:
    """Compare an exact preimage with a published SHA-512 digest.

    This helper verifies historical integrity only. It does not predict future
    game outcomes. Do not pass Key + Salt here unless the game provider has
    documented the exact concatenation, encoding, and normalization rules.
    """
    if not isinstance(expected_hex, str):
        raise TypeError("expected_hex must be a string")

    normalized = expected_hex.strip().lower()
    if len(normalized) != 128:
        return False
    try:
        bytes.fromhex(normalized)
    except ValueError:
        return False

    calculated = sha512_hex(preimage)
    return hmac.compare_digest(calculated, normalized)
