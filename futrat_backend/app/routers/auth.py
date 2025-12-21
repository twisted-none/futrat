from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_ # <-- Для поиска по ИЛИ
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt

from app import models, schemas, security, database, config

router = APIRouter(prefix="/auth", tags=["Auth"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(database.get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, config.settings.SECRET_KEY, algorithms=[config.settings.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
        
    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None:
        raise credentials_exception
    return user

@router.post("/register", response_model=schemas.Token)
def register(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    # Проверка на существование почты ИЛИ никнейма
    if db.query(models.User).filter(
        or_(
            models.User.email == user.email,
            models.User.username == user.username
        )
    ).first():
        # Текст ошибки на русском
        raise HTTPException(status_code=400, detail="Пользователь уже зарегистрирован (Email или Никнейм занят)")
    
    hashed_pwd = security.get_password_hash(user.password)
    new_user = models.User(email=user.email, username=user.username, hashed_password=hashed_pwd)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    access_token = security.create_access_token(data={"sub": new_user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login", response_model=schemas.Token)
def login(user_data: schemas.UserLogin, db: Session = Depends(database.get_db)):
    # Ищем пользователя, у которого совпадает Email ИЛИ Username
    # Примечание: поле user_data.email здесь используется как универсальное поле "логин"
    user = db.query(models.User).filter(
        or_(
            models.User.email == user_data.email, 
            models.User.username == user_data.email
        )
    ).first()
    
    if not user or not security.verify_password(user_data.password, user.hashed_password):
        # Текст ошибки на русском
        raise HTTPException(status_code=400, detail="Неправильный логин или пароль")
    
    access_token = security.create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=schemas.UserResponse)
def read_users_me(current_user: models.User = Depends(get_current_user)):
    return current_user