"""
API エンドポイントのテスト

カバレッジ:
  GET  /health
  POST /register
  POST /login
  GET  /posts
  POST /posts
  DELETE /posts/{id}
"""


class TestHealth:
    def test_returns_200(self, client):
        res = client.get("/health")
        assert res.status_code == 200

    def test_bypasses_origin_verify_middleware(self, client):
        """ヘルスチェックは X-Origin-Verify ヘッダーなしでも通過する"""
        res = client.get("/health", headers={})
        assert res.status_code == 200


class TestRegister:
    def test_success(self, client):
        res = client.post("/register", json={"email": "new@example.com", "password": "pass123"})
        assert res.status_code == 200
        assert res.json()["email"] == "new@example.com"
        assert "id" in res.json()

    def test_duplicate_email_returns_400(self, client):
        client.post("/register", json={"email": "dup@example.com", "password": "pass"})
        res = client.post("/register", json={"email": "dup@example.com", "password": "pass"})
        assert res.status_code == 400

    def test_invalid_email_returns_422(self, client):
        res = client.post("/register", json={"email": "not-an-email", "password": "pass"})
        assert res.status_code == 422


class TestLogin:
    def test_success_returns_token(self, client, registered_user):
        res = client.post("/login", data={
            "username": registered_user["email"],
            "password": registered_user["password"],
        })
        assert res.status_code == 200
        body = res.json()
        assert "access_token" in body
        assert body["token_type"] == "bearer"

    def test_wrong_password_returns_401(self, client, registered_user):
        res = client.post("/login", data={
            "username": registered_user["email"],
            "password": "wrong-password",
        })
        assert res.status_code == 401

    def test_unknown_user_returns_401(self, client):
        res = client.post("/login", data={
            "username": "nobody@example.com",
            "password": "pass",
        })
        assert res.status_code == 401


class TestPosts:
    def test_get_posts_returns_empty_list(self, client):
        res = client.get("/posts")
        assert res.status_code == 200
        assert res.json() == []

    def test_create_post_authenticated(self, client, auth_headers):
        res = client.post("/posts", json={"title": "Hello", "content": "World"}, headers=auth_headers)
        assert res.status_code == 200
        body = res.json()
        assert body["title"] == "Hello"
        assert body["content"] == "World"
        assert "id" in body

    def test_create_post_unauthenticated_returns_401(self, client):
        res = client.post("/posts", json={"title": "Hello", "content": "World"})
        assert res.status_code == 401

    def test_created_post_appears_in_list(self, client, auth_headers):
        client.post("/posts", json={"title": "Test", "content": "Body"}, headers=auth_headers)
        res = client.get("/posts")
        assert len(res.json()) == 1


class TestDeletePost:
    def _create_post(self, client, auth_headers):
        res = client.post("/posts", json={"title": "To Delete", "content": "..."}, headers=auth_headers)
        return res.json()["id"]

    def test_owner_can_delete(self, client, auth_headers):
        post_id = self._create_post(client, auth_headers)
        res = client.delete(f"/posts/{post_id}", headers=auth_headers)
        assert res.status_code == 200

    def test_other_user_cannot_delete(self, client, auth_headers):
        post_id = self._create_post(client, auth_headers)

        # 別ユーザーを作成してログイン
        client.post("/register", json={"email": "other@example.com", "password": "pass"})
        login = client.post("/login", data={"username": "other@example.com", "password": "pass"})
        other_headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

        res = client.delete(f"/posts/{post_id}", headers=other_headers)
        assert res.status_code == 403

    def test_admin_can_delete_any_post(self, client, auth_headers):
        """ADMIN_EMAIL に設定されたユーザーは他人の投稿も削除できる"""
        post_id = self._create_post(client, auth_headers)

        # admin ユーザーを作成（conftest で ADMIN_EMAIL=admin@example.com に設定済み）
        client.post("/register", json={"email": "admin@example.com", "password": "adminpass"})
        login = client.post("/login", data={"username": "admin@example.com", "password": "adminpass"})
        admin_headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

        res = client.delete(f"/posts/{post_id}", headers=admin_headers)
        assert res.status_code == 200

    def test_delete_nonexistent_post_returns_404(self, client, auth_headers):
        res = client.delete("/posts/99999", headers=auth_headers)
        assert res.status_code == 404

    def test_unauthenticated_delete_returns_401(self, client, auth_headers):
        post_id = self._create_post(client, auth_headers)
        res = client.delete(f"/posts/{post_id}")
        assert res.status_code == 401
