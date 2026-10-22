from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import JWTError, jwt
from pwdlib import PasswordHash
from pwdlib.hashers.bcrypt import BcryptHasher
from app.config import settings

pwd_context = PasswordHash((BcryptHasher(rounds=12),))


def _bcrypt_password(password: str) -> bytes:
    # Passlib/bcrypt 4 used the first 72 UTF-8 bytes. Preserve existing hashes,
    # including when the byte boundary splits a multi-byte character.
    if "\x00" in password:
        raise ValueError("bcrypt passwords cannot contain null bytes")
    return password.encode("utf-8")[:72]

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(_bcrypt_password(plain_password), hashed_password)

def get_password_hash(password):
    return pwd_context.hash(_bcrypt_password(password))

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=15)

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt
