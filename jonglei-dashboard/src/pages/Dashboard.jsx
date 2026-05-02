import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import AppLayout from '../components/AppLayout'
import StatCard from '../components/StatCard'
import { StatSkeleton, TableSkeleton } from '../components/Skeleton'
import { Users, Fish, ShoppingBag, Truck, ArrowRight, UserCheck, UserX } from 'lucide-react'
import api from '../api/axios'

const ROLE_BADGE = {
  TRADER:      'bg-teal-50 text-teal-700',
  BUYER:       'bg-blue-50 text-blue-700',
  TRANSPORTER: 'bg-amber-50 text-amber-700',
  DRIVER:      'bg-purple-50 text-purple-700',
}

function timeAgo(dateStr) {
  const diff = Date.now() - new Date(dateStr).getTime()
  const m = Math.floor(diff / 60000)
  if (m < 1) return 'just now'
  if (m < 60) return `${m}m ago`
  const h = Math.floor(m / 60)
  if (h < 24) return `${h}h ago`
  return `${Math.floor(h / 24)}d ago`
}

export default function Dashboard() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [users, setUsers] = useState([])
  const [loadingStats, setLoadingStats] = useState(true)
  const [loadingUsers, setLoadingUsers] = useState(true)

  const hour = new Date().getHours()
  const greeting =
    hour < 5 ? 'Good night' : hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening'

  useEffect(() => {
    setLoadingStats(true)
    api.get('/auth/users/')
      .then(r => {
        const data = Array.isArray(r.data) ? r.data : (r.data?.results ?? [])
        setUsers(data)
      })
      .catch(() => {})
      .finally(() => { setLoadingStats(false); setLoadingUsers(false) })
  }, [])

  const traders      = users.filter(u => u.role === 'TRADER').length
  const buyers       = users.filter(u => u.role === 'BUYER').length
  const transporters = users.filter(u => ['TRANSPORTER', 'DRIVER'].includes(u.role)).length
  const verified     = users.filter(u => u.is_verified).length
  const recentUsers  = [...users].sort((a, b) => new Date(b.date_joined ?? 0) - new Date(a.date_joined ?? 0)).slice(0, 6)

  return (
    <AppLayout>
      <div className="max-w-6xl mx-auto space-y-7">

        {/* Greeting */}
        <div className="pt-1">
          <p className="text-[11px] font-semibold uppercase tracking-widest text-teal-600 mb-0.5">{greeting}</p>
          <h1 className="text-2xl font-bold text-gray-900 leading-tight">
            {user?.username || 'Admin'}
          </h1>
          <p className="text-[13px] text-gray-400 mt-0.5">
            {new Date().toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
          </p>
        </div>

        {/* Stats */}
        <div>
          <h2 className="text-[11px] font-semibold uppercase tracking-widest text-gray-400 mb-3">Platform overview</h2>
          {loadingStats ? (
            <div className="grid grid-cols-2 xl:grid-cols-4 gap-4">
              {[0,1,2,3].map(i => <StatSkeleton key={i} />)}
            </div>
          ) : (
            <div className="grid grid-cols-2 xl:grid-cols-4 gap-4">
              <StatCard
                title="Registered users"
                value={users.length || '0'}
                Icon={Users}
                color="teal"
                note={`${verified} verified`}
              />
              <StatCard
                title="Fish traders"
                value={traders || '0'}
                Icon={Fish}
                color="green"
                note={`${buyers} buyers registered`}
              />
              <StatCard
                title="Pending orders"
                value="—"
                Icon={ShoppingBag}
                color="amber"
                note="Orders module coming soon"
              />
              <StatCard
                title="Transport operators"
                value={transporters || '0'}
                Icon={Truck}
                color="indigo"
                note="Transporters and drivers"
              />
            </div>
          )}
        </div>

        {/* Recent registrations */}
        <div>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-[11px] font-semibold uppercase tracking-widest text-gray-400">Recent registrations</h2>
            <button
              onClick={() => navigate('/users')}
              className="flex items-center gap-1 text-xs text-teal-600 hover:text-teal-800 font-semibold transition-colors"
            >
              View all <ArrowRight size={12} />
            </button>
          </div>

          <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
            {loadingUsers ? (
              <TableSkeleton rows={5} cols={5} />
            ) : recentUsers.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-14 text-gray-300">
                <Users size={28} className="mb-2" />
                <p className="text-sm text-gray-400">No users registered yet</p>
              </div>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100">
                    <th className="text-left px-5 py-3 text-[11px] font-semibold text-gray-400 uppercase tracking-wide">Name</th>
                    <th className="text-left px-5 py-3 text-[11px] font-semibold text-gray-400 uppercase tracking-wide">Phone</th>
                    <th className="text-left px-5 py-3 text-[11px] font-semibold text-gray-400 uppercase tracking-wide">Role</th>
                    <th className="text-left px-5 py-3 text-[11px] font-semibold text-gray-400 uppercase tracking-wide hidden md:table-cell">Location</th>
                    <th className="text-left px-5 py-3 text-[11px] font-semibold text-gray-400 uppercase tracking-wide">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {recentUsers.map((u, i) => (
                    <tr
                      key={u.id}
                      className={`group hover:bg-teal-50/40 transition-colors cursor-pointer ${i < recentUsers.length - 1 ? 'border-b border-gray-50' : ''}`}
                      onClick={() => navigate('/users')}
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
                        <span className="font-mono text-[12px] text-gray-400">{u.phone_number}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full ${ROLE_BADGE[u.role] ?? 'bg-gray-100 text-gray-500'}`}>
                          {u.role_display ?? u.role}
                        </span>
                      </td>
                      <td className="px-5 py-3.5 text-[12px] text-gray-400 hidden md:table-cell">
                        {u.location || <span className="text-gray-200">—</span>}
                      </td>
                      <td className="px-5 py-3.5">
                        {u.is_verified ? (
                          <span className="inline-flex items-center gap-1 text-[11px] font-medium text-green-600">
                            <UserCheck size={12} /> Verified
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[11px] font-medium text-gray-400">
                            <UserX size={12} /> Pending
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

        {/* Role breakdown */}
        {!loadingStats && users.length > 0 && (
          <div>
            <h2 className="text-[11px] font-semibold uppercase tracking-widest text-gray-400 mb-3">Role breakdown</h2>
            <div className="bg-white rounded-2xl border border-gray-100 p-5">
              <div className="space-y-3">
                {[
                  { role: 'TRADER', label: 'Fish Traders', count: traders, color: 'bg-teal-500' },
                  { role: 'BUYER', label: 'Buyers', count: buyers, color: 'bg-blue-500' },
                  { role: 'TRANSPORTER', label: 'Transporters & Drivers', count: transporters, color: 'bg-amber-500' },
                ].map(({ label, count, color }) => {
                  const pct = users.length ? Math.round((count / users.length) * 100) : 0
                  return (
                    <div key={label} className="flex items-center gap-3">
                      <span className="text-[12px] text-gray-500 w-36 flex-shrink-0">{label}</span>
                      <div className="flex-1 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                        <div
                          className={`h-full rounded-full ${color} transition-all duration-500`}
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                      <span className="font-mono text-[12px] text-gray-400 w-8 text-right flex-shrink-0">{count}</span>
                    </div>
                  )
                })}
              </div>
            </div>
          </div>
        )}
      </div>
    </AppLayout>
  )
}
