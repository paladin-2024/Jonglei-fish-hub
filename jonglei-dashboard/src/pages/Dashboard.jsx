import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import AppLayout from '../components/AppLayout'
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell,
} from 'recharts'
import {
  TrendingUp, Fish, Truck, ShoppingBag, ArrowRight,
  Users, DollarSign, Package, Activity,
} from 'lucide-react'
import api from '../api/axios'

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

const CARD_S = {
  background: 'var(--bg-elevated)',
  border: '1px solid var(--border)',
  borderRadius: 'var(--radius)',
}


const STATUS_STYLE = {
  CONFIRMED:    { color: 'var(--primary)',      bg: 'var(--primary-glow)'          },
  'IN TRANSIT': { color: '#60A5FA',             bg: 'rgba(96,165,250,0.1)'         },
  PENDING:      { color: 'var(--secondary)',    bg: 'rgba(245,158,11,0.12)'        },
  CLEARED:      { color: 'var(--success)',      bg: 'rgba(16,185,129,0.1)'         },
  FLAGGED:      { color: 'var(--danger)',       bg: 'rgba(239,68,68,0.1)'          },
  CANCELLED:    { color: 'var(--text-muted)',   bg: 'rgba(71,85,105,0.2)'          },
}

function StatCard({ title, value, note, trend, Icon, iconColor, loading }) {
  return (
    <div
      className="relative overflow-hidden p-5 flex flex-col gap-3 transition-all duration-200 hover-glow"
      style={CARD_S}
    >
      <div className="flex items-start justify-between">
        <div
          className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
          style={{ background: iconColor + '18', border: `1px solid ${iconColor}28` }}
        >
          <Icon size={18} style={{ color: iconColor }} strokeWidth={1.75} />
        </div>
        {trend && (
          <span
            className="text-[11px] font-semibold px-2 py-0.5 rounded-full flex items-center gap-1"
            style={{
              color: trend.startsWith('+') ? 'var(--success)' : 'var(--danger)',
              background: trend.startsWith('+') ? 'rgba(16,185,129,0.1)' : 'rgba(239,68,68,0.1)',
              fontFamily: 'JetBrains Mono',
            }}
          >
            {trend}
          </span>
        )}
      </div>
      <div>
        <p className="text-[11px] font-semibold uppercase tracking-widest mb-1" style={{ color: 'var(--text-muted)' }}>
          {title}
        </p>
        {loading ? (
          <div className="shimmer h-8 w-24 rounded-lg" />
        ) : (
          <p
            className="text-[28px] font-semibold leading-none"
            style={{ fontFamily: 'JetBrains Mono', color: 'var(--primary)' }}
          >
            {value}
          </p>
        )}
        {note && (
          <p className="text-[11px] mt-1.5" style={{ color: 'var(--text-muted)' }}>{note}</p>
        )}
      </div>
    </div>
  )
}

const CustomBarTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null
  return (
    <div
      className="px-3 py-2 rounded-xl text-[12px] shadow-xl"
      style={{ background: 'var(--bg-elevated)', border: '1px solid var(--border)', color: 'var(--text-primary)' }}
    >
      <p style={{ color: 'var(--text-muted)', fontFamily: 'JetBrains Mono', fontSize: 10 }}>{label}</p>
      <p style={{ color: 'var(--primary)', fontFamily: 'JetBrains Mono', fontWeight: 600 }}>
        {payload[0].value.toLocaleString()} kg
      </p>
    </div>
  )
}

export default function Dashboard() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState(null)
  const [statsLoading, setStatsLoading] = useState(true)
  const [recentOrders, setRecentOrders] = useState([])
  const [ordersLoading, setOrdersLoading] = useState(true)
  const [speciesData, setSpeciesData] = useState([])
  const [activityFeed, setActivityFeed] = useState([])

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

  useEffect(() => {
    api.get('/marketplace/orders/?limit=5')
      .then(r => {
        const raw = Array.isArray(r.data) ? r.data : (r.data?.results ?? [])
        setRecentOrders(raw.slice(0, 5).map(o => {
          const listing = o.listing_detail ?? o.listing ?? {}
          const buyer   = o.buyer_detail ?? o.buyer ?? {}
          return {
            id:     '#' + String(o.id ?? '').slice(-6).toUpperCase(),
            fish:   listing.species ?? '—',
            buyer:  typeof buyer === 'object' ? (buyer.username ?? '—') : buyer,
            price:  Number(o.total_price ?? 0),
            status: (o.status ?? 'PENDING').replace('_', ' '),
            date:   o.created_at
              ? new Date(o.created_at).toLocaleDateString('en-GB', { day:'2-digit', month:'short' })
              : '—',
          }
        }))
        // Derive per-species volumes from orders
        const volumes = {}
        raw.forEach(o => {
          const sp = (o.listing_detail ?? o.listing ?? {}).species ?? 'Other'
          volumes[sp] = (volumes[sp] ?? 0) + Number(o.quantity_kg ?? 0)
        })
        setSpeciesData(
          Object.entries(volumes)
            .map(([name, volume]) => ({ name, volume }))
            .sort((a, b) => b.volume - a.volume)
            .slice(0, 5)
        )
      })
      .catch(() => {})
      .finally(() => setOrdersLoading(false))
  }, [])

  useEffect(() => {
    api.get('/marketplace/listings/?status=ACTIVE&limit=6')
      .then(r => {
        const raw = Array.isArray(r.data) ? r.data : (r.data?.results ?? [])
        setActivityFeed(raw.slice(0, 6).map(l => ({
          species: l.species ?? '—',
          city:    l.location ?? '—',
          price:   Number(l.price_ssp ?? 0).toLocaleString(),
          time:    l.updated_at
            ? timeAgo(l.updated_at)
            : '—',
        })))
      })
      .catch(() => {})
  }, [])

  const traders      = users.filter(u => u.role === 'TRADER').length
  const verified     = users.filter(u => u.is_verified).length

  const statCards = [
    {
      title: 'Total Revenue',
      value: stats?.total_revenue
        ? `SSP ${(stats.total_revenue / 1_000_000).toFixed(1)}M`
        : '—',
      note: 'Cumulative trade value',
      trend: '+12.4%',
      Icon: DollarSign,
      iconColor: 'var(--primary)',
      loading: statsLoading,
    },
    {
      title: 'Active Listings',
      value: stats?.active_listings != null ? String(stats.active_listings) : String(users.length || 0),
      note: 'Live marketplace listings',
      trend: '+8.1%',
      Icon: Package,
      iconColor: 'var(--secondary)',
      loading: statsLoading,
    },
    {
      title: 'Pending Orders',
      value: stats?.pending_clearances != null ? String(stats.pending_clearances) : '—',
      note: 'Awaiting confirmation',
      trend: '-3.2%',
      Icon: ShoppingBag,
      iconColor: '#60A5FA',
      loading: statsLoading,
    },
    {
      title: 'Registered Users',
      value: String(users.length || 0),
      note: `${verified} verified · ${traders} traders`,
      trend: '+5.7%',
      Icon: Users,
      iconColor: 'var(--success)',
      loading,
    },
  ]

  return (
    <AppLayout>
      {/* Ambient background blobs */}
      <div className="pointer-events-none fixed inset-0 overflow-hidden z-0">
        <div
          className="absolute -top-40 right-0 w-[600px] h-[600px] rounded-full blur-[120px]"
          style={{ background: 'rgba(245,158,11,0.06)' }}
        />
        <div
          className="absolute bottom-0 -left-40 w-[500px] h-[500px] rounded-full blur-[100px]"
          style={{ background: 'rgba(10,181,163,0.06)' }}
        />
      </div>

      <div className="relative z-10 max-w-[1280px] mx-auto space-y-6">

        {/* ── Greeting ── */}
        <div className="animate-fade-up">
          <p className="text-[10px] font-bold uppercase tracking-[0.25em] mb-1" style={{ color: 'var(--secondary)' }}>
            {greeting}
          </p>
          <h1
            className="text-[2rem] leading-tight"
            style={{ fontFamily: "'DM Serif Display', serif", color: 'var(--text-primary)' }}
          >
            {user?.username || 'Admin'}
          </h1>
          <p className="text-[12px] mt-1" style={{ fontFamily: 'JetBrains Mono', color: 'var(--text-muted)' }}>
            {new Date().toLocaleDateString('en-GB', {
              weekday: 'long', day: 'numeric', month: 'long', year: 'numeric',
            })}
          </p>
        </div>

        {/* ── Stat cards ── */}
        <div className="grid grid-cols-2 xl:grid-cols-4 gap-4">
          {statCards.map((card, i) => (
            <div key={card.title} className={`animate-fade-up stagger-${i + 1}`}>
              <StatCard {...card} />
            </div>
          ))}
        </div>

        {/* ── Main grid ── */}
        <div className="grid grid-cols-1 xl:grid-cols-[1fr_340px] gap-5">

          {/* Left: Recent Orders */}
          <div
            className="overflow-hidden animate-fade-up stagger-2"
            style={CARD_S}
          >
            <div
              className="px-5 py-4 flex items-center justify-between"
              style={{ borderBottom: '1px solid var(--border)' }}
            >
              <div>
                <p className="text-[11px] font-bold uppercase tracking-widest" style={{ color: 'var(--text-muted)' }}>
                  Recent Orders
                </p>
                <p className="text-[11px] mt-0.5" style={{ fontFamily: 'JetBrains Mono', color: 'var(--text-muted)' }}>
                  Last 5 transactions
                </p>
              </div>
              <button
                onClick={() => navigate('/orders')}
                className="flex items-center gap-1 text-[12px] font-semibold transition-all duration-200"
                style={{ color: 'var(--primary)' }}
              >
                View all <ArrowRight size={11} />
              </button>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--border)' }}>
                    {['ORDER ID', 'FISH', 'BUYER', 'VALUE', 'STATUS', 'DATE'].map(h => (
                      <th
                        key={h}
                        className="px-5 py-3 text-[10px] font-semibold uppercase tracking-widest whitespace-nowrap"
                        style={{ color: 'var(--text-muted)' }}
                      >
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {ordersLoading ? (
                    [...Array(5)].map((_, i) => (
                      <tr key={i} style={{ borderBottom: '1px solid var(--border)' }}>
                        {[...Array(6)].map((_, j) => (
                          <td key={j} className="px-5 py-4">
                            <div className="shimmer h-3 rounded" style={{ width: `${50 + (j % 3) * 20}%` }} />
                          </td>
                        ))}
                      </tr>
                    ))
                  ) : recentOrders.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="text-center py-10" style={{ color: 'var(--text-muted)', fontSize: 13 }}>
                        No orders yet
                      </td>
                    </tr>
                  ) : recentOrders.map((o) => {
                    const st = STATUS_STYLE[o.status] ?? STATUS_STYLE.PENDING
                    return (
                      <tr
                        key={o.id}
                        className="cursor-pointer transition-all duration-150"
                        style={{ borderBottom: '1px solid var(--border)' }}
                        onMouseEnter={e => e.currentTarget.style.background = 'rgba(255,255,255,0.03)'}
                        onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                        onClick={() => navigate('/orders')}
                      >
                        <td className="px-5 py-3.5">
                          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 12, color: 'var(--primary)', fontWeight: 600 }}>
                            {o.id}
                          </span>
                        </td>
                        <td className="px-5 py-3.5">
                          <span className="text-[13px] font-semibold" style={{ color: 'var(--text-primary)' }}>{o.fish}</span>
                        </td>
                        <td className="px-5 py-3.5">
                          <span className="text-[13px]" style={{ color: 'var(--text-secondary)' }}>{o.buyer}</span>
                        </td>
                        <td className="px-5 py-3.5">
                          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: 600, color: 'var(--text-primary)' }}>
                            SSP {o.price.toLocaleString()}
                          </span>
                        </td>
                        <td className="px-5 py-3.5">
                          <span
                            className="inline-flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wide px-2.5 py-1 rounded-full"
                            style={{ color: st.color, background: st.bg }}
                          >
                            <span className="w-1.5 h-1.5 rounded-full" style={{ background: st.color }} />
                            {o.status}
                          </span>
                        </td>
                        <td className="px-5 py-3.5">
                          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--text-muted)' }}>{o.date}</span>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>

            {/* Species volume chart */}
            <div className="p-5" style={{ borderTop: '1px solid var(--border)' }}>
              <p className="text-[11px] font-bold uppercase tracking-widest mb-4" style={{ color: 'var(--text-muted)' }}>
                Top Species by Volume (kg)
              </p>
              {speciesData.length === 0 ? (
                <div className="h-[160px] flex items-center justify-center" style={{ color: 'var(--text-muted)', fontSize: 12 }}>
                  No trade data yet
                </div>
              ) : (
                <ResponsiveContainer width="100%" height={160}>
                  <BarChart data={speciesData} margin={{ top: 0, right: 0, bottom: 0, left: 0 }}>
                    <XAxis
                      dataKey="name"
                      tick={{ fontSize: 10, fill: 'var(--text-muted)', fontFamily: 'Outfit' }}
                      axisLine={false}
                      tickLine={false}
                    />
                    <YAxis
                      tick={{ fontSize: 10, fill: 'var(--text-muted)', fontFamily: 'JetBrains Mono' }}
                      axisLine={false}
                      tickLine={false}
                      width={40}
                    />
                    <Tooltip content={<CustomBarTooltip />} cursor={{ fill: 'rgba(255,255,255,0.03)' }} />
                    <Bar dataKey="volume" radius={[6, 6, 0, 0]}>
                      {speciesData.map((entry, i) => (
                        <Cell
                          key={i}
                          fill={i % 2 === 0 ? '#0AB5A3' : '#F59E0B'}
                          fillOpacity={0.85}
                        />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              )}
            </div>
          </div>

          {/* Right: Activity Feed */}
          <div className="flex flex-col gap-4 animate-fade-up stagger-3">

            {/* Live fish activity feed */}
            <div className="overflow-hidden" style={CARD_S}>
              <div
                className="px-5 py-4 flex items-center justify-between"
                style={{ borderBottom: '1px solid var(--border)' }}
              >
                <p className="text-[11px] font-bold uppercase tracking-widest" style={{ color: 'var(--text-muted)' }}>
                  Market Activity
                </p>
                <span className="flex items-center gap-1.5">
                  <span className="relative flex h-2 w-2">
                    <span
                      className="animate-ping absolute inline-flex h-full w-full rounded-full opacity-75"
                      style={{ background: 'var(--success)' }}
                    />
                    <span className="relative inline-flex rounded-full h-2 w-2" style={{ background: 'var(--success)' }} />
                  </span>
                  <span className="text-[10px] font-semibold" style={{ color: 'var(--success)' }}>LIVE</span>
                </span>
              </div>

              <div className="divide-y" style={{ borderColor: 'var(--border)' }}>
                {activityFeed.length === 0 ? (
                  <div className="py-10 text-center" style={{ color: 'var(--text-muted)', fontSize: 12 }}>
                    No active listings yet
                  </div>
                ) : activityFeed.map((item, i) => (
                  <div
                    key={i}
                    className="px-5 py-3 flex items-center justify-between transition-all duration-150"
                    onMouseEnter={e => e.currentTarget.style.background = 'rgba(255,255,255,0.03)'}
                    onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                  >
                    <div>
                      <p className="text-[13px] font-semibold" style={{ color: 'var(--text-primary)' }}>
                        {item.species}
                      </p>
                      <p className="text-[11px]" style={{ color: 'var(--text-muted)' }}>
                        {item.city}
                      </p>
                    </div>
                    <div className="text-right">
                      <p
                        className="text-[13px] font-semibold"
                        style={{ fontFamily: 'JetBrains Mono', color: 'var(--primary)' }}
                      >
                        SSP {item.price}/kg
                      </p>
                      <p className="text-[10px]" style={{ fontFamily: 'JetBrains Mono', color: 'var(--text-muted)' }}>
                        {item.time}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Quick actions */}
            <div className="overflow-hidden" style={CARD_S}>
              <div className="px-5 py-4" style={{ borderBottom: '1px solid var(--border)' }}>
                <p className="text-[11px] font-bold uppercase tracking-widest" style={{ color: 'var(--text-muted)' }}>
                  Quick Actions
                </p>
              </div>
              <div className="p-3 space-y-1">
                {[
                  { label: 'View all listings',  to: '/listings',      color: 'var(--secondary)'     },
                  { label: 'Check shipments',    to: '/shipments',     color: '#60A5FA'              },
                  { label: 'Market prices',      to: '/market-prices', color: 'var(--primary)'       },
                  { label: 'Analytics report',   to: '/analytics',     color: 'var(--text-secondary)' },
                ].map(({ label, to, color }) => (
                  <button
                    key={to}
                    onClick={() => navigate(to)}
                    className="w-full text-left px-3 py-2.5 rounded-xl text-[13px] font-semibold
                               flex items-center justify-between transition-all duration-200"
                    style={{ color }}
                    onMouseEnter={e => e.currentTarget.style.background = 'var(--bg-glass)'}
                    onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
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
    </AppLayout>
  )
}
