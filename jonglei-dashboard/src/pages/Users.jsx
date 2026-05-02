import { useEffect, useState, useMemo } from 'react'
import AppLayout from '../components/AppLayout'
import { TableSkeleton } from '../components/Skeleton'
import { Users as UsersIcon, UserCheck, UserX, Phone, SlidersHorizontal } from 'lucide-react'
import api from '../api/axios'

const ROLE_FILTERS = [
  { key: '', label: 'All' },
  { key: 'TRADER', label: 'Traders' },
  { key: 'BUYER', label: 'Buyers' },
  { key: 'TRANSPORTER', label: 'Transporters' },
  { key: 'DRIVER', label: 'Drivers' },
]

const ROLE_BADGE = {
  TRADER:      'bg-teal-50 text-teal-700 ring-teal-100',
  BUYER:       'bg-blue-50 text-blue-700 ring-blue-100',
  TRANSPORTER: 'bg-amber-50 text-amber-700 ring-amber-100',
  DRIVER:      'bg-purple-50 text-purple-700 ring-purple-100',
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

export default function Users() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState('')
  const [statusFilter, setStatusFilter] = useState('')

  useEffect(() => {
    api.get('/auth/users/')
      .then(r => setUsers(Array.isArray(r.data) ? r.data : (r.data?.results ?? [])))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const filtered = useMemo(() => {
    return users.filter(u => {
      const q = search.toLowerCase()
      const matchSearch = !q || u.username?.toLowerCase().includes(q) || u.phone_number?.includes(q) || u.location?.toLowerCase().includes(q)
      const matchRole = !roleFilter || u.role === roleFilter
      const matchStatus = !statusFilter || (statusFilter === 'verified' ? u.is_verified : !u.is_verified)
      return matchSearch && matchRole && matchStatus
    })
  }, [users, search, roleFilter, statusFilter])

  const counts = useMemo(() => ({
    total: users.length,
    verified: users.filter(u => u.is_verified).length,
    TRADER: users.filter(u => u.role === 'TRADER').length,
    BUYER: users.filter(u => u.role === 'BUYER').length,
    TRANSPORTER: users.filter(u => u.role === 'TRANSPORTER').length,
    DRIVER: users.filter(u => u.role === 'DRIVER').length,
  }), [users])

  const hasFilters = search || roleFilter || statusFilter

  return (
    <AppLayout title="Users" subtitle="All registered accounts on the platform">
      <div className="max-w-6xl mx-auto space-y-4">

        {/* Filter bar */}
        <div className="flex flex-wrap items-center gap-2">
          {/* Role chips */}
          <div className="flex items-center gap-1.5">
            {ROLE_FILTERS.map(({ key, label }) => {
              const count = key ? counts[key] : counts.total
              const active = roleFilter === key
              return (
                <button
                  key={key}
                  onClick={() => setRoleFilter(key)}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-[12px] font-semibold transition-all outline-none focus-visible:ring-2 focus-visible:ring-teal-400 ${
                    active
                      ? 'bg-teal-600 text-white shadow-sm'
                      : 'bg-white border border-gray-200 text-gray-600 hover:border-teal-300 hover:text-teal-700'
                  }`}
                >
                  {label}
                  <span className={`font-mono text-[10px] px-1 rounded ${active ? 'bg-white/20 text-white' : 'bg-gray-100 text-gray-500'}`}>
                    {count}
                  </span>
                </button>
              )
            })}
          </div>

          <div className="w-px h-5 bg-gray-200 mx-1" />

          {/* Status filter */}
          <div className="flex items-center gap-1.5">
            {[
              { key: '', label: 'Any status' },
              { key: 'verified', label: 'Verified' },
              { key: 'pending', label: 'Pending' },
            ].map(({ key, label }) => (
              <button
                key={key}
                onClick={() => setStatusFilter(key)}
                className={`px-3 py-1.5 rounded-xl text-[12px] font-semibold transition-all outline-none focus-visible:ring-2 focus-visible:ring-teal-400 ${
                  statusFilter === key
                    ? 'bg-gray-800 text-white'
                    : 'bg-white border border-gray-200 text-gray-600 hover:border-gray-300'
                }`}
              >
                {label}
              </button>
            ))}
          </div>

          {/* Search */}
          <div className="flex-1 min-w-40">
            <div className="relative">
              <SlidersHorizontal size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Filter by name, phone, location…"
                value={search}
                onChange={e => setSearch(e.target.value)}
                className="w-full pl-8 pr-3 py-1.5 text-[13px] bg-white border border-gray-200 rounded-xl focus:outline-none focus:border-teal-400 transition-colors placeholder-gray-400"
              />
            </div>
          </div>

          {hasFilters && (
            <button
              onClick={() => { setSearch(''); setRoleFilter(''); setStatusFilter('') }}
              className="text-[12px] text-gray-400 hover:text-gray-700 transition-colors px-2"
            >
              Clear
            </button>
          )}
        </div>

        {/* Table */}
        <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
          {/* Table header */}
          <div className="px-5 py-3.5 border-b border-gray-100 flex items-center justify-between">
            <span className="text-[12px] text-gray-400">
              {loading ? 'Loading…' : (
                <>
                  <span className="font-mono font-semibold text-gray-700">{filtered.length}</span>
                  {' '}of{' '}
                  <span className="font-mono font-semibold text-gray-700">{users.length}</span>
                  {' '}users
                </>
              )}
            </span>
            <div className="flex items-center gap-1.5 text-[11px] text-gray-400">
              <UserCheck size={12} className="text-green-500" />
              <span className="font-mono font-semibold text-gray-600">{counts.verified}</span> verified
            </div>
          </div>

          {loading ? (
            <TableSkeleton rows={6} cols={5} />
          ) : filtered.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-gray-300">
              <UsersIcon size={28} className="mb-3" />
              <p className="text-sm text-gray-500 font-medium">
                {hasFilters ? 'No users match these filters' : 'No users registered yet'}
              </p>
              {hasFilters && (
                <button
                  onClick={() => { setSearch(''); setRoleFilter(''); setStatusFilter('') }}
                  className="mt-3 text-xs text-teal-600 hover:text-teal-800 font-semibold"
                >
                  Clear filters
                </button>
              )}
            </div>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50/40">
                  <th className="text-left px-5 py-3 text-[11px] font-semibold text-gray-400 uppercase tracking-wide">Name</th>
                  <th className="text-left px-5 py-3 text-[11px] font-semibold text-gray-400 uppercase tracking-wide">Phone</th>
                  <th className="text-left px-5 py-3 text-[11px] font-semibold text-gray-400 uppercase tracking-wide">Role</th>
                  <th className="text-left px-5 py-3 text-[11px] font-semibold text-gray-400 uppercase tracking-wide hidden md:table-cell">Location</th>
                  <th className="text-left px-5 py-3 text-[11px] font-semibold text-gray-400 uppercase tracking-wide">Joined</th>
                  <th className="text-left px-5 py-3 text-[11px] font-semibold text-gray-400 uppercase tracking-wide">Status</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((u, i) => (
                  <tr
                    key={u.id}
                    className={`group hover:bg-teal-50/30 transition-colors ${i < filtered.length - 1 ? 'border-b border-gray-50' : ''}`}
                  >
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-2.5">
                        <div className="w-7 h-7 rounded-full bg-teal-100 flex items-center justify-center flex-shrink-0">
                          <span className="text-[11px] font-bold text-teal-700">
                            {(u.username || '?')[0].toUpperCase()}
                          </span>
                        </div>
                        <span className="font-semibold text-gray-800 text-[13px]">{u.username || '—'}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-1.5 text-gray-400">
                        <Phone size={11} className="text-gray-300 flex-shrink-0" />
                        <span className="font-mono text-[12px]">{u.phone_number}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3.5">
                      <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full ring-1 ${ROLE_BADGE[u.role] ?? 'bg-gray-100 text-gray-500 ring-gray-200'}`}>
                        {u.role_display ?? u.role}
                      </span>
                    </td>
                    <td className="px-5 py-3.5 text-[12px] text-gray-400 hidden md:table-cell">
                      {u.location || <span className="text-gray-200">—</span>}
                    </td>
                    <td className="px-5 py-3.5">
                      <span className="font-mono text-[11px] text-gray-400">
                        {timeAgo(u.date_joined)}
                      </span>
                    </td>
                    <td className="px-5 py-3.5">
                      {u.is_verified ? (
                        <span className="inline-flex items-center gap-1 text-[11px] font-medium text-green-600">
                          <span className="w-1.5 h-1.5 rounded-full bg-green-500 inline-block" />
                          Verified
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-[11px] font-medium text-gray-400">
                          <span className="w-1.5 h-1.5 rounded-full bg-gray-300 inline-block" />
                          Pending
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </AppLayout>
  )
}
