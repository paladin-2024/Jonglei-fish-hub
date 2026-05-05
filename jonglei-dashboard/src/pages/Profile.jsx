import { useState } from 'react'
import AppLayout from '../components/AppLayout'
import { useAuth } from '../context/AuthContext'
import api from '../api/axios'
import { User, Phone, Shield, Key, Save, LogOut, CheckCircle } from 'lucide-react'

function Section({ title, children }) {
  return (
    <div className="bg-white rounded-2xl overflow-hidden">
      <div className="h-[3px] bg-teal-800" />
      <div className="px-5 py-4 border-b border-stone-100">
        <h2 className="text-[13px] font-bold uppercase tracking-widest text-stone-500">{title}</h2>
      </div>
      <div className="p-5">{children}</div>
    </div>
  )
}

function Field({ label, value, onChange, type = 'text', readOnly = false }) {
  return (
    <div>
      <label className="block text-[11px] font-bold uppercase tracking-wider text-stone-400 mb-1.5">
        {label}
      </label>
      <input
        type={type}
        value={value}
        onChange={onChange ? e => onChange(e.target.value) : undefined}
        readOnly={readOnly}
        className={`w-full px-3.5 py-2.5 text-[13px] border rounded-xl outline-none transition-all
                    ${readOnly
                      ? 'bg-stone-50 text-stone-500 border-stone-100 cursor-default'
                      : 'bg-white text-stone-800 border-stone-200 focus:border-teal-400 focus:ring-2 focus:ring-teal-100'
                    }`}
      />
    </div>
  )
}

export default function AdminProfile() {
  const { user, logout } = useAuth()

  const [profile, setProfile] = useState({
    username: user?.username ?? '',
    phone:    user?.phone_number ?? '',
  })
  const [saving, setSaving]     = useState(false)
  const [saved, setSaved]       = useState(false)
  const [profileErr, setProfileErr] = useState('')

  const [pwd, setPwd] = useState({ current: '', next: '', confirm: '' })
  const [pwdSaving, setPwdSaving] = useState(false)
  const [pwdMsg, setPwdMsg]       = useState({ text: '', ok: false })

  const initials = (user?.username ?? 'A')[0].toUpperCase()
  const role     = user?.role ?? 'admin'

  const saveProfile = async () => {
    setSaving(true); setProfileErr(''); setSaved(false)
    try {
      await api.patch('/auth/me/', { username: profile.username })
      setSaved(true)
      setTimeout(() => setSaved(false), 3000)
    } catch (e) {
      setProfileErr(e.response?.data?.detail ?? 'Failed to save.')
    } finally {
      setSaving(false)
    }
  }

  const changePassword = async () => {
    setPwdMsg({ text: '', ok: false })
    if (pwd.next !== pwd.confirm) {
      return setPwdMsg({ text: 'Passwords do not match.', ok: false })
    }
    if (pwd.next.length < 8) {
      return setPwdMsg({ text: 'Password must be at least 8 characters.', ok: false })
    }
    setPwdSaving(true)
    try {
      await api.post('/auth/change-password/', {
        current_password: pwd.current,
        new_password: pwd.next,
      })
      setPwdMsg({ text: 'Password updated successfully.', ok: true })
      setPwd({ current: '', next: '', confirm: '' })
    } catch (e) {
      setPwdMsg({ text: e.response?.data?.detail ?? 'Failed to update password.', ok: false })
    } finally {
      setPwdSaving(false)
    }
  }

  return (
    <AppLayout title="My Profile" subtitle="Admin account settings and security">
      <div className="grid grid-cols-1 xl:grid-cols-[300px_1fr] gap-5 animate-fade-up">

        {/* ── Identity card ── */}
        <div className="flex flex-col gap-5">
          <div className="bg-white rounded-2xl overflow-hidden">
            <div className="h-[3px] bg-teal-800" />
            <div className="p-6 flex flex-col items-center text-center">
              <div
                className="w-20 h-20 rounded-2xl flex items-center justify-center text-white text-[28px] font-bold mb-4"
                style={{ background: 'rgba(0,84,64,0.9)' }}
              >
                {initials}
              </div>
              <p className="text-[18px] font-bold text-stone-900">{user?.username ?? 'Admin'}</p>
              <p className="font-mono text-[12px] text-stone-400 mt-1">{user?.phone_number ?? '—'}</p>
              <span className="mt-3 inline-flex items-center gap-1.5 px-3 py-1 rounded-lg
                               bg-teal-50 text-teal-800 text-[11px] font-bold uppercase tracking-wide">
                <Shield size={11} />
                {role.replace('_', ' ')}
              </span>
            </div>
          </div>

          {/* Quick info */}
          <div className="bg-white rounded-2xl overflow-hidden">
            <div className="h-[3px] bg-stone-200" />
            <div className="divide-y divide-stone-100">
              {[
                { Icon: User,  label: 'Username', val: user?.username ?? '—' },
                { Icon: Phone, label: 'Phone',    val: user?.phone_number ?? '—' },
                { Icon: Shield, label: 'Role',    val: role },
              ].map(({ Icon, label, val }) => (
                <div key={label} className="flex items-center gap-3 px-4 py-3.5">
                  <Icon size={14} className="text-stone-400 flex-shrink-0" />
                  <span className="text-[12px] text-stone-500 w-20 flex-shrink-0">{label}</span>
                  <span className="text-[13px] font-semibold text-stone-800 truncate">{val}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* ── Forms ── */}
        <div className="flex flex-col gap-5">

          {/* Edit profile */}
          <Section title="Edit Profile">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
              <Field
                label="Username"
                value={profile.username}
                onChange={v => setProfile(p => ({ ...p, username: v }))}
              />
              <Field
                label="Phone Number"
                value={profile.phone}
                readOnly
              />
            </div>
            {profileErr && (
              <p className="text-[12px] text-red-600 mb-3">{profileErr}</p>
            )}
            <button
              onClick={saveProfile}
              disabled={saving}
              className="flex items-center gap-2 px-4 py-2.5 bg-teal-800 hover:bg-teal-700
                         text-white text-[13px] font-semibold rounded-xl transition-all
                         disabled:opacity-50"
            >
              {saved
                ? <><CheckCircle size={14} /> Saved</>
                : <><Save size={14} /> {saving ? 'Saving…' : 'Save Changes'}</>
              }
            </button>
          </Section>

          {/* Change password */}
          <Section title="Change Password">
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-4">
              <Field
                label="Current Password"
                type="password"
                value={pwd.current}
                onChange={v => setPwd(p => ({ ...p, current: v }))}
              />
              <Field
                label="New Password"
                type="password"
                value={pwd.next}
                onChange={v => setPwd(p => ({ ...p, next: v }))}
              />
              <Field
                label="Confirm New Password"
                type="password"
                value={pwd.confirm}
                onChange={v => setPwd(p => ({ ...p, confirm: v }))}
              />
            </div>
            {pwdMsg.text && (
              <p className={`text-[12px] mb-3 ${pwdMsg.ok ? 'text-teal-700' : 'text-red-600'}`}>
                {pwdMsg.text}
              </p>
            )}
            <button
              onClick={changePassword}
              disabled={pwdSaving || !pwd.current || !pwd.next || !pwd.confirm}
              className="flex items-center gap-2 px-4 py-2.5 bg-teal-800 hover:bg-teal-700
                         text-white text-[13px] font-semibold rounded-xl transition-all
                         disabled:opacity-50"
            >
              <Key size={14} />
              {pwdSaving ? 'Updating…' : 'Update Password'}
            </button>
          </Section>

          {/* Danger zone */}
          <Section title="Session">
            <p className="text-[13px] text-stone-500 mb-4">
              Signing out will clear your session tokens from this browser.
            </p>
            <button
              onClick={logout}
              className="flex items-center gap-2 px-4 py-2.5 bg-red-50 hover:bg-red-100
                         text-red-700 text-[13px] font-semibold rounded-xl transition-all"
            >
              <LogOut size={14} />
              Sign Out
            </button>
          </Section>
        </div>
      </div>
    </AppLayout>
  )
}
