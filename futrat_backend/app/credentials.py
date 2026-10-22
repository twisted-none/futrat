"""Registration rules; login keeps compatibility with existing passwords."""
import unicodedata


def nickname_key(value: str) -> str:
    return unicodedata.normalize("NFKC", value.strip()).casefold()


def validate_nickname(value: str) -> str:
    value = value.strip()
    if len(value) < 3:
        raise ValueError("Никнейм должен содержать не менее 3 символов")
    if any(unicodedata.category(char).startswith("C") for char in value):
        raise ValueError("Никнейм содержит недопустимые символы")
    return value


def validate_new_password(value: str) -> str:
    if len(value) < 6:
        raise ValueError("Пароль должен содержать не менее 6 символов")
    if not value.strip():
        raise ValueError("Пароль не может состоять только из пробелов")
    if "\x00" in value:
        raise ValueError("Пароль содержит недопустимый символ")
    if len(value.encode("utf-8")) > 72:
        # New passwords must not be silently truncated by legacy bcrypt hashing.
        raise ValueError("Пароль слишком длинный")
    return value
