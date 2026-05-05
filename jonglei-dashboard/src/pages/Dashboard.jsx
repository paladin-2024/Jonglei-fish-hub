import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import AppLayout from '../components/AppLayout'
import StatCard from '../components/StatCard'
import { StatSkeleton, TableSkeleton } from '../components/Skeleton'
import { Users, Fish, Truck, ArrowRight, UserCheck, UserX, TrendingUp } from 'lucide-react'
import api from '../api/axios'

const ROLE_BADGE = {
  TRADER:      'bg-teal-50 text-teal-800 ring-teal-100',
  BUYER:       'bg-blue-50 text-blue-800 ring-blue-100',
  TRANSPORTER: 'bg-amber-50 text-amber-800 ring-amber-100',
  DRIVER:      'bg-stone-100 text-stone-700 ring-stone-200',
  BORDER_OFFICIAL: 'bg-purple-50 text-purple-800 ring-purple-100',
  ADMIN:       'bg-red-50 text-red-800 ring-red-100',
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

export default function Dashboard() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState(null)
  const [statsLoading, setStatsLoading] = useState(true)

  const hour = new Date().getHours()
  const greeting =
    hour < 5 ? 'Good night' : hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening'

  useEffect(() => {
    api.get('/auth/users/')
      .then(r => setUsers(Array.isArray(r.data) ? r.data : (r.data?.results ?? [])))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    api.get('/dashboard/stats/')
      .then(r => setStats(r.data ?? null))
      .catch(() => {})
      .finally(() => setStatsLoading(false))
  }, [])

  const traders      = users.filter(u => u.role === 'TRADER').length
  const buyers       = users.filter(u => u.role === 'BUYER').length
  const transporters = users.filter(u => ['TRANSPORTER', 'DRIVER'].includes(u.role)).length
  const verified     = users.filter(u => u.is_verified).length
  const recentUsers  = [...users]
    .sort((a, b) => new Date(b.date_joined ?? 0) - new Date(a.date_joined ?? 0))
    .slice(0, 8)

  const roleBreakdown = [
    { label: 'Fish Traders', count: traders,      total: users.length, color: '#005440' },
    { label: 'Buyers',       count: buyers,       total: users.length, color: '#1E5C8A' },
    { label: 'Transporters', count: transporters, total: users.length, color: '#B45309' },
  ]

  return (
    <AppLayout>
      <div className="max-w-[1200px] mx-auto space-y-6">

        {/* Greeting — asymmetric left-aligned, not centered */}
        <div className="animate-fade-up">
          <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-teal-600 mb-1">
            {greeting}
          </p>
          <h1 className="font-display text-[2rem] text-stone-900 leading-tight">
            {user?.username || 'Admin'}
          </h1>
          <p className="text-[12px] font-mono text-stone-400 mt-1">
            {new Date().toLocaleDateString('en-GB', {
              weekday: 'long', day: 'numeric', month: 'long', year: 'numeric',
            })}
          </p>
        </div>

        {/* Stat cards — staggered reveal */}
        <div className="grid grid-cols-2 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {loading ? (
            [0,1,2,3].map(i => <StatSkeleton key={i} />)
          ) : (
            <>
              <div className="animate-fade-up stagger-1">
                <StatCard title="Registered users" value={String(users.length || 0)}
                  Icon={Users} color="teal" note={`${verified} verified`} />
              </div>
              <div className="animate-fade-up stagger-2">
                <StatCard title="Fish traders" value={String(traders || 0)}
                  Icon={Fish} color="green" note={`${buyers} buyers`} />
              </div>
              <div className="animate-fade-up stagger-3">
                <StatCard
                  title="Pending clearances"
                  value={stats?.pending_clearances != null ? String(stats.pending_clearances) : '—'}
                  Icon={UserX} color="amber"
                  note={stats?.pending_clearances != null ? `${stats.pending_clearances} pending` : 'Clearance module'}
                />
              </div>
              <div className="animate-fade-up stagger-4">
                <StatCard title="Transport operators" value={String(transporters || 0)}
                  Icon={Truck} color="indigo" note="Transporters + drivers" />
              </div>
              {statsLoading ? (
                <>
                  <StatSkeleton />
                  <StatSkeleton />
                </>
              ) : (
                <>
                  <div className="animate-fade-up stagger-5">
                    <StatCard
                      title="Active listings"
                      value={stats?.active_listings != null ? String(stats.active_listings) : '—'}
                      Icon={Fish} color="green"
                      note="Live marketplace listings"
                    />
                  </div>
                  <div className="animate-fade-up stagger-6">
                    <StatCard
                      title="Total revenue"
                      value={stats?.total_revenue ? 'SSP ' + (stats.total_revenue / 1000000).toFixed(1) + 'M' : '—'}
                      Icon={TrendingUp} color="amber"
                      note="Cumulative trade value"
                    />
                  </div>
                </>
              )}
            </>
          )}
        </div>

        {/* Main grid — asymmetric 60/40 */}
        <div className="grid grid-cols-1 xl:grid-cols-[1fr_340px] gap-5 animate-fade-up stagger-3">

          {/* Recent registrations */}
          <div className="bg-white rounded-xl shadow-card overflow-hidden">
            <div className="h-[3px]" style={{ background: '#005440' }} />
            <div className="px-5 py-4 flex items-center justify-between border-b border-stone-100">
              <div>
                <p className="text-[11px] font-bold uppercase tracking-widest text-stone-400">
                  Recent registrations
                </p>
                {!loading && (
                  <p className="font-mono text-[11px] text-stone-400 mt-0.5">
                    {recentUsers.length} of {users.length} users
                  </p>
                )}
              </div>
              <button
                onClick={() => navigate('/users')}
                className="flex items-center gap-1 text-[12px] text-teal-700 hover:text-teal-900
                           font-semibold transition-colors"
              >
                View all <ArrowRight size={11} />
              </button>
            </div>

            {loading ? (
              <TableSkeleton rows={6} cols={5} />
            ) : recentUsers.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-14 text-stone-300">
                <Users size={26} className="mb-2" />
                <p className="text-[13px] text-stone-400">No users registered yet</p>
              </div>
            ) : (
              <table className="w-full">
                <thead>
                  <tr className="border-b border-stone-50 bg-stone-50/60">
                    <th className="text-left px-5 py-3 text-[10px] font-bold uppercase tracking-widest text-stone-400">Name</th>
                    <th className="text-left px-5 py-3 text-[10px] font-bold uppercase tracking-widest text-stone-400">Phone</th>
                    <th className="text-left px-5 py-3 text-[10px] font-bold uppercase tracking-widest text-stone-400">Role</th>
                    <th className="text-left px-5 py-3 text-[10px] font-bold uppercase tracking-widest text-stone-400 hidden lg:table-cell">Joined</th>
                    <th className="text-left px-5 py-3 text-[10px] font-bold uppercase tracking-widest text-stone-400">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {recentUsers.map((u, i) => (
                    <tr
                      key={u.id}
                      className={`group hover:bg-teal-50/30 transition-colors cursor-pointer
                                  ${i < recentUsers.length - 1 ? 'border-b border-stone-50' : ''}`}
                      onClick={() => navigate('/users')}
                    >
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-2.5">
                          <div
                            className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 font-bold text-[11px]"
                            style={{ background: '#EDF8F4', color: '#005440' }}
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
                      <td className="px-5 py-3.5 hidden lg:table-cell">
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
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          {/* Right column — role breakdown + verified stat */}
          <div className="flex flex-col gap-4">

            {/* Verified ratio */}
            <div className="bg-white rounded-xl shadow-card overflow-hidden">
              <div className="h-[3px]" style={{ background: '#1A6B3C' }} />
              <div className="p-5">
                <p className="text-[11px] font-bold uppercase tracking-widest text-stone-400 mb-4">
                  Verification rate
                </p>
                {loading ? (
                  <div className="shimmer h-20 rounded-lg" />
                ) : (
                  <>
                    <div className="flex items-end gap-2 mb-3">
                      <span className="font-mono text-[2.4rem] font-semibold text-stone-900 leading-none">
                        {users.length ? Math.round((verified / users.length) * 100) : 0}
                      </span>
                      <span className="font-mono text-[1.4rem] text-stone-400 leading-none mb-1">%</span>
                    </div>
                    <div className="w-full h-2 bg-stone-100 rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all duration-700"
                        style={{
                          width: `${users.length ? (verified / users.length) * 100 : 0}%`,
                          background: '#1A6B3C',
                        }}
                      />
                    </div>
                    <p className="text-[11px] text-stone-400 mt-2">
                      <span className="font-mono font-semibold text-stone-700">{verified}</span> of{' '}
                      <span className="font-mono font-semibold text-stone-700">{users.length}</span> verified
                    </p>
                  </>
                )}
              </div>
            </div>

            {/* Role breakdown */}
            {!loading && users.length > 0 && (
              <div className="bg-white rounded-xl shadow-card overflow-hidden">
                <div className="h-[3px]" style={{ background: '#B45309' }} />
                <div className="p-5">
                  <p className="text-[11px] font-bold uppercase tracking-widest text-stone-400 mb-4">
                    Role breakdown
                  </p>
                  <div className="space-y-3.5">
                    {roleBreakdown.map(({ label, count, total, color }) => {
                      const pct = total ? Math.round((count / total) * 100) : 0
                      return (
                        <div key={label}>
                          <div className="flex items-center justify-between mb-1.5">
                            <span className="text-[12px] text-stone-600 font-medium">{label}</span>
                            <span className="font-mono text-[11px] font-semibold text-stone-700">{count}</span>
                          </div>
                          <div className="w-full h-1.5 bg-stone-100 rounded-full overflow-hidden">
                            <div
                              className="h-full rounded-full transition-all duration-700"
                              style={{ width: `${pct}%`, background: color }}
                            />
                          </div>
                        </div>
                      )
                    })}
                  </div>
                </div>
              </div>
            )}

            {/* Quick actions */}
            <div className="bg-white rounded-xl shadow-card overflow-hidden">
              <div className="h-[3px]" style={{ background: '#B45309' }} />
              <div className="p-5">
                <p className="text-[11px] font-bold uppercase tracking-widest text-stone-400 mb-3">
                  Quick actions
                </p>
                <div className="space-y-2">
                  {[
                    { label: 'View all users',     to: '/users',         color: 'text-teal-700 hover:bg-teal-50' },
                    { label: 'Check shipments',    to: '/shipments',     color: 'text-blue-700 hover:bg-blue-50' },
                    { label: 'Market prices',      to: '/market-prices', color: 'text-amber-700 hover:bg-amber-50' },
                    { label: 'Analytics report',   to: '/analytics',     color: 'text-stone-700 hover:bg-stone-50' },
                  ].map(({ label, to, color }) => (
                    <button
                      key={to}
                      onClick={() => navigate(to)}
                      className={`w-full text-left px-3 py-2 rounded-lg text-[13px] font-semibold
                                  flex items-center justify-between transition-colors ${color}`}
                    >
                      {label}
                      <ArrowRight size={12} strokeWidth={2.5} />
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </AppLayout>
  )
}
