from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import or_
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from datetime import datetime, timezone
import hashlib
import secrets

from app import models, schemas, security, database, config
from app.credentials import nickname_key

router = APIRouter(prefix="/auth", tags=["Auth"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(database.get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Сессия истекла. Войдите снова",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, config.settings.SECRET_KEY, algorithms=[config.settings.ALGORITHM])
        subject = payload.get("sub")
        if not isinstance(subject, str) or not subject:
            raise credentials_exception
        if payload.get("subject_type") == "user_id":
            if not subject.isascii() or not subject.isdecimal():
                raise credentials_exception
            user = db.get(models.User, int(subject))
        elif "subject_type" not in payload:
            # Existing email-based tokens remain valid until their normal expiry.
            user = db.query(models.User).filter(models.User.email == subject).first()
        else:
            raise credentials_exception
    except (JWTError, ValueError):
        raise credentials_exception
    if user is None:
        raise credentials_exception
    session_id = payload.get("sid")
    if session_id is not None:
        if not isinstance(session_id, str):
            raise credentials_exception
        session = db.get(models.AuthSession, session_id)
        if session is None or session.revoked_at is not None or session.user_id != user.id:
            raise credentials_exception
    return user


def nickname_taken(db, username, exclude_id=None):
    query = db.query(models.User.id).filter(models.User.username_key == nickname_key(username))
    if exclude_id is not None:
        query = query.filter(models.User.id != exclude_id)
    return query.first() is not None


def token_pair(session, refresh_token):
    access_token = security.create_access_token(data={
        "sub": str(session.user_id), "subject_type": "user_id", "sid": session.id})
    return {"access_token": access_token, "token_type": "bearer",
            "refresh_token": refresh_token,
            "expires_in": config.settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60}


def user_token(user, db):
    refresh_token = secrets.token_urlsafe(48)
    now = datetime.now(timezone.utc)
    session = models.AuthSession(id=secrets.token_hex(16), user_id=user.id,
        token_hash=hashlib.sha256(refresh_token.encode()).hexdigest(),
        created_at=now, last_used_at=now)
    db.add(session)
    db.commit()
    return token_pair(session, refresh_token)


def session_for_key(db, refresh_token):
    digest = hashlib.sha256(refresh_token.encode()).hexdigest()
    return db.query(models.AuthSession).filter_by(token_hash=digest).with_for_update().first()


@router.post("/refresh", response_model=schemas.Token)
def refresh_session(data: schemas.SessionKey, db: Session = Depends(database.get_db)):
    key = data.refresh_token.get_secret_value()
    session = session_for_key(db, key)
    if session is None or session.revoked_at is not None or db.get(models.User, session.user_id) is None:
        raise HTTPException(status_code=401, detail="Сессия недействительна. Войдите снова")
    # A revocable device key has no inactivity timeout. Keeping it stable makes
    # retries safe when a response is lost; only hashes are stored server-side.
    session.last_used_at = datetime.now(timezone.utc)
    db.commit()
    return token_pair(session, key)


@router.post("/logout", status_code=204)
def revoke_session(data: schemas.SessionKey, db: Session = Depends(database.get_db)):
    session = session_for_key(db, data.refresh_token.get_secret_value())
    if session is not None and session.revoked_at is None:
        session.revoked_at = datetime.now(timezone.utc)
        db.commit()


def raise_unique_conflict(error):
    constraint = getattr(getattr(error.orig, "diag", None), "constraint_name", "") or ""
    message = str(error.orig)
    if constraint == "ix_users_email" or "users.email" in message:
        raise HTTPException(status_code=409, detail="Эта почта уже используется") from error
    if constraint in {"ix_users_username", "ix_users_username_key"} or "users.username" in message:
        raise HTTPException(status_code=409, detail="Этот никнейм уже занят") from error
    raise error


@router.post("/register", response_model=schemas.Token)
def register(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    if nickname_taken(db, user.username):
        raise HTTPException(status_code=409, detail="Этот никнейм уже занят")
    if user.email and db.query(models.User.id).filter(models.User.email == user.email).first():
        raise HTTPException(status_code=409, detail="Эта почта уже используется")
    new_user = models.User(email=user.email, username=user.username,
                           hashed_password=security.get_password_hash(user.password))
    db.add(new_user)
    try:
        db.commit()
    except IntegrityError as error:
        db.rollback()
        raise_unique_conflict(error)
    db.refresh(new_user)
    return user_token(new_user, db)


@router.post("/login", response_model=schemas.Token)
def login(user_data: schemas.UserLogin, db: Session = Depends(database.get_db)):
    candidates = db.query(models.User).filter(or_(
        models.User.username_key == nickname_key(user_data.username),
        models.User.email == user_data.username,
    )).all()
    user = candidates[0] if len(candidates) == 1 else None
    try:
        valid = security.verify_password(user_data.password, user.hashed_password) if user else False
    except (ValueError, TypeError):
        valid = False
    if not valid:
        raise HTTPException(status_code=401, detail="Неверный никнейм или пароль")
    return user_token(user, db)


@router.get("/me", response_model=schemas.UserResponse)
def read_users_me(current_user: models.User = Depends(get_current_user)):
    return current_user
