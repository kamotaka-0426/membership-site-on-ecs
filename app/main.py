import logging
import json
import os
from datetime import timedelta # 追加
from fastapi import FastAPI, Depends, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

import database
import schemas
import auth

# auth.py から必要な定数や関数をインポート（環境に合わせて調整してください）
from auth import create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES 
from database import create_tables, SessionLocal, User, Post # Postを追加
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from jose import JWTError, jwt

# ロギング設定
class JsonFormatter(logging.Formatter):
    def format(self, record):
        log_record = {
            "timestamp": self.formatTime(record),
            "level": record.levelname,
            "message": record.getMessage(),
            "module": record.module
        }
        return json.dumps(log_record)

handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logger = logging.getLogger("my_app")
logger.addHandler(handler)
logger.setLevel(logging.INFO)

# 起動時にテーブルを作成
create_tables()

app = FastAPI()

# ---------------------------------------------
# CloudFront カスタムヘッダー検証ミドルウェア
# 環境変数 ORIGIN_VERIFY_SECRET が設定されている場合、
# X-Origin-Verify ヘッダーが一致しないリクエストを 403 で拒否する
# ---------------------------------------------
ORIGIN_VERIFY_SECRET = os.environ.get("ORIGIN_VERIFY_SECRET", "")

@app.middleware("http")
async def verify_origin_header(request: Request, call_next):
    # /health は ECS コンテナヘルスチェックから直接呼ばれるため検証をスキップ
    if ORIGIN_VERIFY_SECRET and request.url.path != "/health":
        header = request.headers.get("x-origin-verify", "")
        if header != ORIGIN_VERIFY_SECRET:
            logger.warning("Unauthorized direct access from %s", request.client.host)
            return JSONResponse(status_code=403, content={"detail": "Forbidden"})
    return await call_next(request)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- 認証ロジック ---
async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, auth.SECRET_KEY, algorithms=[auth.ALGORITHM])
        user_id: str = payload.get("sub") # ここには ID が入ってくる
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    # 【重要】email ではなく id で検索するように変更
    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None:
        raise credentials_exception
    return user

@app.get("/health")
async def health_check():
    return {"status": "Database Initialized"}

@app.post("/register", response_model=schemas.UserResponse)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_pwd = auth.get_password_hash(user.password)
    new_user = User(email=user.email, hashed_password=hashed_pwd)
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

# ---ログイン機能 ---
@app.post("/login", response_model=schemas.Token)
def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # トークンの sub に user.id を入れる
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, 
        expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/posts", response_model=schemas.PostResponse)
def create_post(post: schemas.PostCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    new_post = database.Post(
        title=post.title, 
        content=post.content, 
        owner_id=current_user.id
    )
    db.add(new_post)
    db.commit()
    db.refresh(new_post)
    return new_post

@app.get("/posts", response_model=list[schemas.PostResponse])
def read_posts(db: Session = Depends(get_db)):
    return db.query(database.Post).all()

# --- 削除機能 ---
ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL", "")

@app.delete("/posts/{post_id}")
def delete_post(post_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    post = db.query(database.Post).filter(database.Post.id == post_id).first()
    
    if post is None:
        raise HTTPException(status_code=404, detail="Post not found")

    # --- 権限チェックの修正 ---
    # 「投稿者本人」または「管理者（メールアドレスで判定）」なら許可
    is_owner = (post.owner_id == current_user.id)
    is_admin = (current_user.email == ADMIN_EMAIL)

    if not (is_owner or is_admin):
        raise HTTPException(status_code=403, detail="Not authorized to delete this post")
    
    db.delete(post)
    db.commit()
    return {"message": "Post deleted successfully"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)