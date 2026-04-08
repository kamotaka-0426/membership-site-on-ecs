import { useState, useEffect, useCallback } from 'react'
import axios from 'axios'

// --- 便利関数: JWTトークンをデコードして中身（user_id等）を取り出す ---
function parseJwt(token) {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    return JSON.parse(window.atob(base64));
  } catch (err) {
  console.error(err)
  return null
  }
}

function App() {
  // --- 状態管理 (State) ---
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [token, setToken] = useState(localStorage.getItem('token') || '')
  const [posts, setPosts] = useState([])
  const [message, setMessage] = useState('')
  const [isRegistering, setIsRegistering] = useState(false)
  const ADMIN_ID = "1";

  const API_URL = "https://api.kamotaka.net"

  // ログイン中のユーザーIDを取得
  const currentUser = token ? parseJwt(token) : null;

  // --- 記事取得処理 (useCallbackでメモ化) ---
  const fetchPosts = useCallback(async () => {
    try {
      const res = await axios.get(`${API_URL}/posts`)
      setPosts(res.data)
    } catch (err) {
      console.error("記事の取得失敗:", err)
    }
  }, [API_URL]);

  // --- 副作用 (Effect): 起動時に記事一覧を取得 ---
  useEffect(() => {
    const fetchPosts = async () => {
      try {
        const res = await axios.get(`${API_URL}/posts`)
        setPosts(res.data)
      } catch (err) {
        console.error("記事の取得失敗:", err)
      }
    }

    fetchPosts()
  }, [])


  // --- 新規登録処理 ---
  const handleRegister = async (e) => {
    e.preventDefault()
    try {
      await axios.post(`${API_URL}/register`, { email, password })
      setMessage("✅ 登録成功！ログインしてください。")
      setIsRegistering(false)
      setPassword('')
    } catch (err) {
      setMessage("❌ 登録失敗: " + (err.response?.data?.detail || err.message))
    }
  }

  // --- ログイン処理 ---
  const handleLogin = async (e) => {
    e.preventDefault()
    const formData = new FormData()
    formData.append('username', email)
    formData.append('password', password)

    try {
      const res = await axios.post(`${API_URL}/login`, formData)
      const accessToken = res.data.access_token
      setToken(accessToken)
      localStorage.setItem('token', accessToken)
      setMessage("✅ ログイン成功！")
      setEmail('')
      setPassword('')
    } catch (err) {
      setMessage("❌ ログイン失敗: " + (err.response?.data?.detail || err.message))
    }
  }

  // --- 記事投稿処理 ---
  const handlePostSubmit = async (e) => {
    e.preventDefault()
    const title = e.target.title.value
    const content = e.target.content.value

    try {
      await axios.post(
        `${API_URL}/posts`,
        { title, content },
        { headers: { Authorization: `Bearer ${token}` } }
      )
      setMessage("🚀 投稿しました！！")
      e.target.reset()
      fetchPosts()
    } catch (err) {
      setMessage("❌ 投稿失敗: " + err.message)
    }
  }

  // --- 記事削除処理 ---
  const handleDeletePost = async (postId) => {
    if (!window.confirm("本当にこの記事を削除しますか？")) return;

    try {
      await axios.delete(`${API_URL}/posts/${postId}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setMessage("🗑️ 記事を削除しました");
      fetchPosts();
    } catch (err) {
      setMessage("❌ 削除失敗: " + (err.response?.data?.detail || err.message));
    }
  }

  // --- ログアウト処理 ---
  const handleLogout = () => {
    setToken('')
    localStorage.removeItem('token')
    setMessage("ログアウトしました")
  }

  // --- UI デザイン用共通スタイル ---
  const inputStyle = { padding: '12px', borderRadius: '6px', border: '1px solid #444', backgroundColor: '#2a2a2a', color: 'white' };
  const buttonStyle = { padding: '12px', backgroundColor: '#646cff', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold' };

  return (
    <div style={{ 
      display: 'flex', flexDirection: 'column', alignItems: 'center', 
      minHeight: '100vh', backgroundColor: '#1a1a1a', color: 'white', padding: '40px', fontFamily: 'sans-serif' 
    }}>
      <h1 style={{ color: '#646cff' }}>Kotani's Diary</h1>
      
      {message && <p style={{ backgroundColor: '#333', padding: '10px', borderRadius: '5px' }}>{message}</p>}

      {!token ? (
        <section style={{ width: '100%', maxWidth: '400px', textAlign: 'center' }}>
          <h2>{isRegistering ? "新規登録" : "ログイン"}</h2>
          <form onSubmit={isRegistering ? handleRegister : handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
            <input style={inputStyle} type="email" placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} required />
            <input style={inputStyle} type="password" placeholder="Password" value={password} onChange={e => setPassword(e.target.value)} required />
            <button style={buttonStyle} type="submit">{isRegistering ? "アカウント作成" : "ログイン"}</button>
          </form>
          <p 
            style={{ marginTop: '20px', fontSize: '14px', cursor: 'pointer', color: '#646cff', textDecoration: 'underline' }} 
            onClick={() => { setIsRegistering(!isRegistering); setMessage(''); }}
          >
            {isRegistering ? "ログインへ戻る" : "新規登録はこちら！"}
          </p>
        </section>
      ) : (
        <section style={{ width: '100%', maxWidth: '400px', textAlign: 'center' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <p style={{ color: '#4caf50' }}>● ログイン中 (ID: {currentUser?.sub})</p>
            <button onClick={handleLogout} style={{ background: 'none', color: '#ff4b4b', border: '1px solid #ff4b4b', cursor: 'pointer', borderRadius: '4px', padding: '5px 10px' }}>ログアウト</button>
          </div>
          <div style={{ marginTop: '20px', padding: '20px', border: '1px solid #444', borderRadius: '8px', textAlign: 'left' }}>
            <h3>新規投稿</h3>
            <form onSubmit={handlePostSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              <input name="title" placeholder="タイトル" style={inputStyle} required />
              <textarea name="content" placeholder="本文" style={{ ...inputStyle, minHeight: '80px' }} required />
              <button style={{ ...buttonStyle, backgroundColor: '#4caf50' }} type="submit">投稿する</button>
            </form>
          </div>
        </section>
      )}

      <hr style={{ width: '100%', maxWidth: '600px', margin: '40px 0', borderColor: '#333' }} />
      
      <section style={{ width: '100%', maxWidth: '600px' }}>
        <h2 style={{ textAlign: 'center' }}>Timeline</h2>
        {posts.length === 0 ? (
          <p style={{ textAlign: 'center', color: '#888' }}>記事がまだありません。</p>
        ) : (
          posts.slice().reverse().map(post => (
            <div key={post.id} style={{ 
              backgroundColor: '#242424', padding: '20px', borderRadius: '12px', marginBottom: '20px', border: '1px solid #333',
              position: 'relative'
            }}>
              <h3 style={{ margin: '0 0 10px 0', color: '#646cff' }}>{post.title}</h3>
              <p style={{ lineHeight: '1.6' }}>{post.content}</p>
              <div style={{ fontSize: '12px', color: '#666', marginTop: '15px' }}>Author ID: {post.owner_id}</div>

              {token && currentUser && (String(post.owner_id) === String(currentUser.sub) || currentUser.sub === ADMIN_ID) && (
                <button 
                  onClick={() => handleDeletePost(post.id)}
                  style={{
                    position: 'absolute', top: '15px', right: '15px',
                    backgroundColor: '#ff4b4b', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer', padding: '5px 10px', fontSize: '12px'
                  }}
                >
                  削除
                </button>
              )}
            </div>
          ))
        )}
      </section>
    </div>
  )
}

export default App