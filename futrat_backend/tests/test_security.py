from datetime import timedelta
import json
from pathlib import Path

import pytest
from jose import JWTError, jwt

from app.config import settings
from app.security import create_access_token, get_password_hash, verify_password


LEGACY = json.loads((Path(__file__).parent / "fixtures/legacy_security.json").read_text(encoding="utf-8"))


@pytest.mark.parametrize("item", LEGACY["hashes"])
def test_passlib_hashes_remain_verifiable(item):
    assert verify_password(item["password"], item["hash"])
    assert not verify_password("wrong-password", item["hash"])


def test_legacy_jwt_remains_verifiable():
    payload = jwt.decode(LEGACY["jwt"], settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    assert payload["sub"] == "legacy@example.test"


@pytest.mark.parametrize("password", ["", "test-password", "Пароль ⚽", "a" * 72, "a" * 73, "я" * 40, "a" * 71 + "Я"])
def test_password_round_trip(password):
    encoded = get_password_hash(password)
    assert encoded.startswith("$2b$")
    assert verify_password(password, encoded)
    assert not verify_password("wrong-password", encoded)


def test_legacy_long_password_truncation():
    encoded = get_password_hash("a" * 72 + "original-suffix")
    assert verify_password("a" * 72 + "different-suffix", encoded)


def test_password_hashes_are_salted():
    assert get_password_hash("test-password") != get_password_hash("test-password")


def test_password_with_null_byte_is_rejected():
    with pytest.raises(ValueError):
        get_password_hash("test\x00password")


def test_token_keeps_subject_without_mutating_input():
    data = {"sub": "test@example.test"}
    token = create_access_token(data)
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    assert payload["sub"] == data["sub"]
    assert "exp" in payload
    assert data == {"sub": "test@example.test"}


def test_expired_token_is_rejected():
    token = create_access_token({"sub": "test@example.test"}, timedelta(seconds=-1))
    with pytest.raises(JWTError):
        jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
