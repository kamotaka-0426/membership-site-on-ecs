import os
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

# --- 環境変数をインポート前に設定 ---
# auth.py の RuntimeError を防ぐため、app のインポートより先に設定する
os.environ["JWT_SECRET_KEY"] = "test-secret-key-do-not-use-in-production"
os.environ["ORIGIN_VERIFY_SECRET"] = ""  # テスト中はミドルウェア検証を無効化
os.environ["ADMIN_EMAIL"] = "admin@example.com"

# --- database モジュールのエンジンを SQLite に差し替え ---
# database.py はモジュールレベルで engine を作成するため、
# main.py をインポートする前にパッチを当てる必要がある
import database

_test_engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
_TestSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=_test_engine)
database.engine = _test_engine  # create_tables() が SQLite を使うように差し替え

# --- app をインポート（create_tables() が SQLite 上で実行される） ---
from main import app, get_db  # noqa: E402

# --- テーブルを作成 ---
database.Base.metadata.create_all(bind=_test_engine)


def _override_get_db():
    """テスト用 DB セッションを提供する依存関数"""
    db = _TestSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = _override_get_db


@pytest.fixture(autouse=True)
def reset_db():
    """各テスト前後にテーブルをリセットしてテストを独立させる"""
    yield
    database.Base.metadata.drop_all(bind=_test_engine)
    database.Base.metadata.create_all(bind=_test_engine)


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def registered_user(client):
    """登録済みユーザーを返すフィクスチャ"""
    client.post("/register", json={"email": "user@example.com", "password": "password123"})
    return {"email": "user@example.com", "password": "password123"}


@pytest.fixture
def auth_headers(client, registered_user):
    """認証済みユーザーの Authorization ヘッダーを返すフィクスチャ"""
    res = client.post("/login", data={
        "username": registered_user["email"],
        "password": registered_user["password"],
    })
    token = res.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
