import { useEffect, useState, useMemo } from 'react'
import AppLayout from '../components/AppLayout'
import { TableSkeleton } from '../components/Skeleton'
import {
  Users as UsersIcon, UserCheck, UserX,
  Phone, MapPin, Calendar, X, ChevronRight,
  Shield, ShieldCheck,
} from 'lucide-react'
import api from '../api/axios'

const ROLE_FILTERS = [
  { key: '', label: 'All' },
  { key: 'TRADER', label: 'Traders' },
  { key: 'BUYER', label: 'Buyers' },
  { key: 'TRANSPORTER', label: 'Transporters' },
  { key: 'DRIVER', label: 'Drivers' },
]

const ROLE_BADGE = {
  TRADER:      'bg-teal-50 text-teal-800 ring-teal-100',
  BUYER:       'bg-blue-50 text-blue-800 ring-blue-100',
  TRANSPORTER: 'bg-amber-50 text-amber-800 ring-amber-100',
  DRIVER:      'bg-stone-100 text-stone-700 ring-stone-200',
  BORDER_OFFICIAL: 'bg-purple-50 text-purple-800 ring-purple-100',
  ADMIN:       'bg-red-50 text-red-800 ring-red-100',
}

const ROLE_ACCENT = {
  TRADER:      '#005440',
  BUYER:       '#1E5C8A',
  TRANSPORTER: '#B45309',
  DRIVER:      '#5C6B67',
  BORDER_OFFICIAL: '#6B21A8',
  ADMIN:       '#B91C1C',
}

function timeAgo(dateStr) {
  if (!dateStr) return '—'
  const diff = Date.now() - new Date(dateStr).getTime()
  const m = Math.floor(diff / 60000)
  if (m < 1) return 'just now'
  if (m < 60) return `${m}m ago`
  const h = Math.floor(m / 60)
  if (h < 24) return `${h}h ago`
  return `${Math.floor(h / 24)}d ago`
}

function UserDetailPanel({ user, onClose, onRefresh }) {
  if (!user) return null
  const accent = ROLE_ACCENT[user.role] ?? '#005440'
  const [acting, setActing] = useState(null)

  async function verify() {
    setActing('verify')
    try {
      await api.patch(`/auth/users/${user.id}/`, { is_verified: true })
      onRefresh(); onClose()
    } catch { /* ignore */ }
    finally { setActing(null) }
  }

  async function suspend() {
    if (!window.confirm(`Suspend ${user.username || user.phone_number}?`)) return
    setActing('suspend')
    try {
      await api.patch(`/auth/users/${user.id}/`, { is_active: false })
      onRefresh(); onClose()
    } catch { /* ignore */ }
    finally { setActing(null) }
  }

  return (
    <div className="fixed inset-0 z-40 flex">
      {/* Backdrop */}
      <div
        className="flex-1 bg-stone-900/20 backdrop-blur-[2px]"
        onClick={onClose}
      />

      {/* Slide-in panel */}
      <div className="w-[360px] bg-white flex flex-col shadow-[−8px_0_40px_rgba(0,31,26,0.15)] slide-in-right">
        {/* Top accent */}
        <div className="h-[3px] flex-shrink-0" style={{ background: accent }} />

        {/* Header */}
        <div className="px-6 pt-5 pb-4 border-b border-stone-100 flex items-start justify-between">
          <div className="flex items-center gap-3.5">
            <div
              className="w-11 h-11 rounded-xl flex items-center justify-center font-bold text-lg text-white flex-shrink-0"
              style={{ background: accent }}
            >
              {(user.username || '?')[0].toUpperCase()}
            </div>
            <div>
              <h2 className="font-semibold text-stone-900 text-[15px] leading-tight">
                {user.username || 'Unknown'}
              </h2>
              <span className={`text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-md ring-1 ${ROLE_BADGE[user.role] ?? 'bg-stone-100 text-stone-600 ring-stone-200'}`}>
                {user.role_display ?? user.role}
              </span>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg hover:bg-stone-100 text-stone-400 transition-colors"
          >
            <X size={14} />
          </button>
        </div>

        {/* Details */}
        <div className="flex-1 overflow-y-auto px-6 py-5 space-y-4">

          {/* Verification status */}
          <div className={`flex items-center gap-2.5 px-4 py-3 rounded-xl ${user.is_verified ? 'bg-green-50' : 'bg-amber-50'}`}>
            {user.is_verified
              ? <ShieldCheck size={16} className="text-green-600 flex-shrink-0" />
              : <Shield size={16} className="text-amber-600 flex-shrink-0" />
            }
            <span className={`text-[13px] font-semibold ${user.is_verified ? 'text-green-700' : 'text-amber-700'}`}>
              {user.is_verified ? 'Verified account' : 'Verification pending'}
            </span>
          </div>

          {/* Info rows */}
          <div className="space-y-3">
            {[
              { Icon: Phone, label: 'Phone', value: user.phone_number, mono: true },
              { Icon: MapPin, label: 'Location', value: user.location || '—' },
              { Icon: Calendar, label: 'Joined', value: user.date_joined ? new Date(user.date_joined).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' }) : '—' },
            ].map(({ Icon, label, value, mono }) => (
              <div key={label} className="flex items-start gap-3 py-2 border-b border-stone-50 last:border-0">
                <div className="w-8 h-8 rounded-lg bg-stone-100 flex items-center justify-center flex-shrink-0">
                  <Icon size={13} className="text-stone-400" strokeWidth={1.75} />
                </div>
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">{label}</p>
                  <p className={`text-[13px] text-stone-800 font-medium mt-0.5 ${mono ? 'font-mono' : ''}`}>
                    {value}
                  </p>
                </div>
              </div>
            ))}
          </div>

          {/* User ID */}
          <div className="bg-stone-50 rounded-xl p-3.5">
            <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
              User ID
            </p>
            <p className="font-mono text-[11px] text-stone-500 break-all">{user.id || '—'}</p>
          </div>
        </div>

        {/* Actions */}
        <div className="px-6 py-4 border-t border-stone-100 space-y-2.5">
          {!user.is_verified && (
            <button
              onClick={verify}
              disabled={!!acting}
              className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-[13px] font-bold bg-teal-700 text-white hover:bg-teal-800 transition-colors disabled:opacity-60"
            >
              <UserCheck size={14} />
              {acting === 'verify' ? 'Verifying…' : 'Verify account'}
            </button>
          )}
          <button
            onClick={suspend}
            disabled={!!acting}
            className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-[13px] font-semibold border border-stone-200 text-stone-600 hover:bg-stone-50 transition-colors disabled:opacity-60"
          >
            <UserX size={14} />
            {acting === 'suspend' ? 'Suspending…' : 'Suspend account'}
          </button>
        </div>
      </div>
    </div>
  )
}

export default function Users() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [selected, setSelected] = useState(null)

  function fetchUsers() {
    api.get('/auth/users/')
      .then(r => setUsers(Array.isArray(r.data) ? r.data : (r.data?.results ?? [])))
      .catch(() => {})
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchUsers() }, [])

  const filtered = useMemo(() => {
    const q = search.toLowerCase()
    return users.filter(u => {
      const matchSearch = !q || u.username?.toLowerCase().includes(q) || u.phone_number?.includes(q) || u.location?.toLowerCase().includes(q)
      const matchRole = !roleFilter || u.role === roleFilter
      const matchStatus = !statusFilter || (statusFilter === 'verified' ? u.is_verified : !u.is_verified)
      return matchSearch && matchRole && matchStatus
    })
  }, [users, search, roleFilter, statusFilter])

  const counts = useMemo(() => ({
    total:      users.length,
    verified:   users.filter(u => u.is_verified).length,
    TRADER:     users.filter(u => u.role === 'TRADER').length,
    BUYER:      users.filter(u => u.role === 'BUYER').length,
    TRANSPORTER:users.filter(u => u.role === 'TRANSPORTER').length,
    DRIVER:     users.filter(u => u.role === 'DRIVER').length,
  }), [users])

  const hasFilters = search || roleFilter || statusFilter
  const clearFilters = () => { setSearch(''); setRoleFilter(''); setStatusFilter('') }

  return (
    <AppLayout title="Users" subtitle="Manage and verify platform accounts">
      <div className="max-w-[1200px] mx-auto space-y-4">

        {/* Filter bar */}
        <div className="flex flex-wrap items-center gap-2.5 animate-fade-up">
          {ROLE_FILTERS.map(({ key, label }) => {
            const count = key ? counts[key] : counts.total
            const active = roleFilter === key
            return (
              <button
                key={key}
                onClick={() => setRoleFilter(key)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-[12px] font-bold
                            transition-all duration-200 ease-spring outline-none
                            focus-visible:ring-2 focus-visible:ring-teal-400
                            ${active
                              ? 'bg-teal-700 text-white shadow-sm'
                              : 'bg-white border border-stone-200 text-stone-600 hover:border-teal-300 hover:text-teal-700'
                            }`}
              >
                {label}
                <span className={`font-mono text-[10px] px-1 rounded ${active ? 'bg-white/25 text-white' : 'bg-stone-100 text-stone-400'}`}>
                  {count}
                </span>
              </button>
            )
          })}

          <div className="w-px h-5 bg-stone-200 mx-0.5" />

          {[{ key: '', label: 'Any status' }, { key: 'verified', label: 'Verified' }, { key: 'pending', label: 'Pending' }].map(
            ({ key, label }) => (
              <button
                key={key}
                onClick={() => setStatusFilter(key)}
                className={`px-3 py-1.5 rounded-xl text-[12px] font-bold transition-all duration-200 outline-none
                            focus-visible:ring-2 focus-visible:ring-teal-400
                            ${statusFilter === key
                              ? 'bg-stone-800 text-white'
                              : 'bg-white border border-stone-200 text-stone-600 hover:border-stone-300'
                            }`}
              >
                {label}
              </button>
            )
          )}

          <div className="flex-1 min-w-[180px] relative">
            <UsersIcon size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-400" />
            <input
              type="text"
              placeholder="Name, phone, location…"
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-8 pr-3 py-1.5 text-[13px] bg-white border border-stone-200 rounded-xl
                         focus:outline-none focus:border-teal-400 transition-colors placeholder-stone-400"
            />
          </div>

          {hasFilters && (
            <button onClick={clearFilters} className="text-[12px] text-stone-400 hover:text-stone-700 transition-colors font-medium">
              Clear
            </button>
          )}
        </div>

        {/* Table */}
        <div className="bg-white rounded-xl shadow-card overflow-hidden animate-fade-up stagger-1">
          <div className="h-[3px]" style={{ background: '#005440' }} />

          <div className="px-5 py-3.5 border-b border-stone-100 flex items-center justify-between">
            <span className="text-[12px] text-stone-500">
              {loading ? 'Loading…' : (
                <>
                  <span className="font-mono font-semibold text-stone-800">{filtered.length}</span>
                  {' '}of{' '}
                  <span className="font-mono font-semibold text-stone-800">{users.length}</span>
                  {' '}users
                </>
              )}
            </span>
            <div className="flex items-center gap-1.5 text-[11px] text-stone-400">
              <UserCheck size={12} className="text-green-500" />
              <span className="font-mono font-semibold text-stone-700">{counts.verified}</span> verified
            </div>
          </div>

          {loading ? (
            <TableSkeleton rows={7} cols={6} />
          ) : filtered.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-stone-300">
              <UsersIcon size={28} className="mb-3" strokeWidth={1.5} />
              <p className="text-[13px] text-stone-400 font-medium">
                {hasFilters ? 'No users match these filters' : 'No users registered yet'}
              </p>
              {hasFilters && (
                <button onClick={clearFilters} className="mt-3 text-[12px] text-teal-600 hover:text-teal-800 font-semibold">
                  Clear filters
                </button>
              )}
            </div>
          ) : (
            <table className="w-full">
              <thead>
                <tr className="border-b border-stone-50 bg-stone-50/60">
                  {['Name', 'Phone', 'Role', 'Location', 'Joined', 'Status', ''].map(h => (
                    <th key={h} className="text-left px-5 py-3 text-[10px] font-bold uppercase tracking-widest text-stone-400">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {filtered.map((u, i) => (
                  <tr
                    key={u.id}
                    onClick={() => setSelected(u)}
                    className={`group hover:bg-teal-50/30 transition-colors cursor-pointer
                                ${i < filtered.length - 1 ? 'border-b border-stone-50' : ''}`}
                  >
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-2.5">
                        <div
                          className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 font-bold text-[11px] text-white"
                          style={{ background: ROLE_ACCENT[u.role] ?? '#5C6B67' }}
                        >
                          {(u.username || '?')[0].toUpperCase()}
                        </div>
                        <span className="font-semibold text-stone-800 text-[13px]">{u.username || '—'}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3.5">
                      <span className="font-mono text-[11px] text-stone-400">{u.phone_number}</span>
                    </td>
                    <td className="px-5 py-3.5">
                      <span className={`text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-md ring-1 ${ROLE_BADGE[u.role] ?? 'bg-stone-100 text-stone-600 ring-stone-200'}`}>
                        {u.role_display ?? u.role}
                      </span>
                    </td>
                    <td className="px-5 py-3.5 text-[12px] text-stone-400">
                      {u.location || <span className="text-stone-200">—</span>}
                    </td>
                    <td className="px-5 py-3.5">
                      <span className="font-mono text-[11px] text-stone-400">{timeAgo(u.date_joined)}</span>
                    </td>
                    <td className="px-5 py-3.5">
                      {u.is_verified ? (
                        <span className="inline-flex items-center gap-1.5 text-[11px] font-semibold text-green-700">
                          <span className="w-1.5 h-1.5 rounded-full bg-green-500" />
                          Verified
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1.5 text-[11px] font-semibold text-stone-400">
                          <span className="w-1.5 h-1.5 rounded-full bg-stone-300" />
                          Pending
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3.5">
                      <ChevronRight size={14} className="text-stone-300 group-hover:text-teal-500 transition-colors" />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

      </div>

      {/* User detail slide-out */}
      {selected && <UserDetailPanel user={selected} onClose={() => setSelected(null)} onRefresh={fetchUsers} />}
    </AppLayout>
  )
}
