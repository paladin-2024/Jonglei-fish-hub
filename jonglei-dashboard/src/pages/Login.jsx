import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { Fish, Phone, Lock, ArrowRight, Loader2 } from 'lucide-react'

export default function Login() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const [phoneNumber, setPhoneNumber] = useState('+211')
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
    <div className="min-h-screen flex" style={{ background: 'linear-gradient(135deg, #002b27 0%, #004d40 50%, #00695c 100%)' }}>

      {/* Left panel — branding */}
      <div className="hidden lg:flex lg:w-1/2 flex-col justify-between p-14">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-teal-400 rounded-xl flex items-center justify-center">
            <Fish size={22} className="text-teal-950" strokeWidth={2.5} />
          </div>
          <span className="text-white font-bold text-xl tracking-tight">Jonglei Fish Hub</span>
        </div>

        <div>
          <p className="text-teal-300 text-sm font-medium uppercase tracking-widest mb-4">Admin Dashboard</p>
          <h1 className="text-white font-bold leading-tight mb-6" style={{ fontSize: '3.5rem', lineHeight: 1.1 }}>
            Connecting<br />
            <span className="text-teal-400">Nile markets</span><br />
            to the world.
          </h1>
          <p className="text-teal-200 text-lg font-light max-w-sm leading-relaxed">
            Manage fish trade, transport routes, border clearance and market listings across Jonglei state.
          </p>
        </div>

        <div className="flex gap-8">
          {[['Traders', '200+'], ['Markets', '14'], ['Routes', '38']].map(([label, val]) => (
            <div key={label}>
              <div className="text-teal-400 font-bold text-2xl font-mono-data">{val}</div>
              <div className="text-teal-300 text-sm">{label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Right panel — form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center p-8">
        <div className="w-full max-w-md">
          {/* Mobile logo */}
          <div className="flex items-center gap-3 mb-10 lg:hidden">
            <div className="w-9 h-9 bg-teal-400 rounded-xl flex items-center justify-center">
              <Fish size={18} className="text-teal-950" strokeWidth={2.5} />
            </div>
            <span className="text-white font-bold text-lg">Jonglei Fish Hub</span>
          </div>

          <div className="bg-white rounded-3xl p-10 shadow-2xl">
            <h2 className="text-2xl font-bold text-gray-900 mb-1">Welcome back</h2>
            <p className="text-gray-500 text-sm mb-8">Sign in to your admin account</p>

            <form onSubmit={handleSubmit} className="space-y-5">
              <div>
                <label htmlFor="phone" className="block text-sm font-semibold text-gray-700 mb-2">
                  Phone Number
                </label>
                <div className="relative">
                  <Phone size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
                  <input
                    id="phone"
                    type="tel"
                    value={phoneNumber}
                    onChange={(e) => setPhoneNumber(e.target.value)}
                    required
                    className="w-full pl-11 pr-4 py-3 border-2 border-gray-100 rounded-xl text-sm font-medium focus:outline-none focus:border-teal-500 transition-colors bg-gray-50 focus:bg-white"
                    placeholder="+211 9XX XXX XXX"
                  />
                </div>
              </div>

              <div>
                <label htmlFor="password" className="block text-sm font-semibold text-gray-700 mb-2">
                  Password
                </label>
                <div className="relative">
                  <Lock size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
                  <input
                    id="password"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    className="w-full pl-11 pr-4 py-3 border-2 border-gray-100 rounded-xl text-sm font-medium focus:outline-none focus:border-teal-500 transition-colors bg-gray-50 focus:bg-white"
                    placeholder="••••••••"
                  />
                </div>
              </div>

              {error && (
                <div className="bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
                  {error}
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl font-semibold text-white text-sm transition-all disabled:opacity-60"
                style={{ background: loading ? '#4db6ac' : 'linear-gradient(135deg, #00897b, #004d40)' }}
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
