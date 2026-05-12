import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { Fish, Phone, Lock, ArrowRight, Loader2 } from 'lucide-react'

export default function Login() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const [phoneNumber, setPhoneNumber] = useState('+256')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await login(phoneNumber, password)
      navigate('/dashboard')
    } catch {
      setError('Invalid phone number or password.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex" style={{ background: 'var(--bg-base)' }}>

      {/* Left panel — branding */}
      <div
        className="hidden lg:flex lg:w-1/2 flex-col justify-between p-14"
        style={{ background: 'var(--bg-elevated)', borderRight: '1px solid var(--border)' }}
      >
        <div className="flex items-center gap-3">
          <div
            className="w-10 h-10 rounded-xl flex items-center justify-center"
            style={{ background: 'var(--primary)' }}
          >
            <Fish size={22} style={{ color: 'var(--bg-deep)' }} strokeWidth={2.5} />
          </div>
          <span className="font-bold text-xl tracking-tight" style={{ color: 'var(--text-primary)' }}>
            Jonglei Fish Hub
          </span>
        </div>

        <div>
          <p
            className="text-sm font-medium uppercase tracking-widest mb-4"
            style={{ color: 'var(--secondary)', fontFamily: 'JetBrains Mono' }}
          >
            Admin Dashboard
          </p>
          <h1
            className="font-bold leading-tight mb-6"
            style={{
              fontSize: '3.5rem',
              lineHeight: 1.1,
              fontFamily: "'DM Serif Display', serif",
              color: 'var(--text-primary)',
            }}
          >
            Connecting<br />
            <span style={{ color: 'var(--primary)' }}>Nile markets</span><br />
            to the world.
          </h1>
          <p
            className="text-lg font-light max-w-sm leading-relaxed"
            style={{ color: 'var(--text-muted)' }}
          >
            Manage fish trade, transport routes, border clearance and market listings across Jonglei state.
          </p>
        </div>

        <div className="flex gap-8">
          {[['Traders', '200+'], ['Markets', '14'], ['Routes', '38']].map(([label, val]) => (
            <div key={label}>
              <div
                className="font-bold text-2xl"
                style={{ fontFamily: 'JetBrains Mono', color: 'var(--primary)' }}
              >
                {val}
              </div>
              <div className="text-sm" style={{ color: 'var(--text-muted)' }}>{label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Right panel — form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center p-8">
        <div className="w-full max-w-md">
          {/* Mobile logo */}
          <div className="flex items-center gap-3 mb-10 lg:hidden">
            <div
              className="w-9 h-9 rounded-xl flex items-center justify-center"
              style={{ background: 'var(--primary)' }}
            >
              <Fish size={18} style={{ color: 'var(--bg-deep)' }} strokeWidth={2.5} />
            </div>
            <span className="font-bold text-lg" style={{ color: 'var(--text-primary)' }}>
              Jonglei Fish Hub
            </span>
          </div>

          <div
            className="rounded-3xl p-10 shadow-lg"
            style={{
              background: 'var(--bg-elevated)',
              border: '1px solid var(--border)',
            }}
          >
            {/* Top accent bar */}
            <div
              className="h-[3px] rounded-full mb-8"
              style={{ background: 'var(--primary)', width: 40 }}
            />

            <h2
              className="text-2xl font-bold mb-1"
              style={{ fontFamily: "'DM Serif Display', serif", color: 'var(--text-primary)' }}
            >
              Welcome back
            </h2>
            <p className="text-sm mb-8" style={{ color: 'var(--text-muted)' }}>
              Sign in to your admin account
            </p>

            <form onSubmit={handleSubmit} className="space-y-5">
              <div>
                <label
                  htmlFor="phone"
                  className="block text-sm font-semibold mb-2"
                  style={{ color: 'var(--text-secondary)', fontFamily: 'Outfit' }}
                >
                  Phone Number
                </label>
                <div className="relative">
                  <Phone
                    size={15}
                    className="absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none"
                    style={{ color: 'var(--text-muted)' }}
                  />
                  <input
                    id="phone"
                    type="tel"
                    value={phoneNumber}
                    onChange={(e) => setPhoneNumber(e.target.value)}
                    required
                    className="w-full pl-11 pr-4 py-3 rounded-xl text-sm font-medium outline-none transition-all duration-200"
                    style={{
                      background: 'var(--bg-glass)',
                      border: '1px solid var(--border)',
                      color: 'var(--text-primary)',
                      fontFamily: 'Outfit',
                    }}
                    placeholder="+256 7XX XXX XXX"
                    onFocus={e => e.target.style.borderColor = 'rgba(10,181,163,0.4)'}
                    onBlur={e => e.target.style.borderColor = 'var(--border)'}
                  />
                </div>
              </div>

              <div>
                <label
                  htmlFor="password"
                  className="block text-sm font-semibold mb-2"
                  style={{ color: 'var(--text-secondary)', fontFamily: 'Outfit' }}
                >
                  Password
                </label>
                <div className="relative">
                  <Lock
                    size={15}
                    className="absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none"
                    style={{ color: 'var(--text-muted)' }}
                  />
                  <input
                    id="password"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    className="w-full pl-11 pr-4 py-3 rounded-xl text-sm font-medium outline-none transition-all duration-200"
                    style={{
                      background: 'var(--bg-glass)',
                      border: '1px solid var(--border)',
                      color: 'var(--text-primary)',
                      fontFamily: 'Outfit',
                    }}
                    placeholder="••••••••"
                    onFocus={e => e.target.style.borderColor = 'rgba(10,181,163,0.4)'}
                    onBlur={e => e.target.style.borderColor = 'var(--border)'}
                  />
                </div>
              </div>

              {error && (
                <div
                  className="text-sm rounded-xl px-4 py-3"
                  style={{
                    background: 'rgba(239,68,68,0.08)',
                    border: '1px solid rgba(239,68,68,0.25)',
                    color: 'var(--danger)',
                  }}
                >
                  {error}
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl font-semibold text-sm transition-all disabled:opacity-60"
                style={{
                  background: loading ? 'var(--primary-glow)' : 'var(--primary)',
                  color: 'var(--bg-deep)',
                  fontFamily: 'Outfit',
                }}
              >
                {loading ? (
                  <><Loader2 size={16} className="animate-spin" /> Signing in…</>
                ) : (
                  <>Sign In <ArrowRight size={16} /></>
                )}
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
  )
}
