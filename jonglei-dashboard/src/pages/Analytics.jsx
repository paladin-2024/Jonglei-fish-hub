import { useEffect, useState } from 'react'
import AppLayout from '../components/AppLayout'
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, Tooltip, ResponsiveContainer,
} from 'recharts'
import { Fish, Users, Truck, BarChart3, TrendingUp } from 'lucide-react'
import api from '../api/axios'

const CARD_S = {
  background: 'var(--bg-elevated)',
  border: '1px solid var(--border)',
  borderRadius: 'var(--radius)',
}

const REVENUE_DATA = [
  { week: 'W1 Apr', revenue: 3720000,  orders: 42 },
  { week: 'W2 Apr', revenue: 5670000,  orders: 67 },
  { week: 'W3 Apr', revenue: 4680000,  orders: 53 },
  { week: 'W4 Apr', revenue: 6300000,  orders: 71 },
  { week: 'W1 May', revenue: 5340000,  orders: 61 },
  { week: 'W2 May', revenue: 7020000,  orders: 84 },
]

const ORDER_STATUS_DATA = [
  { name: 'Cleared',    value: 47, color: '#10B981' },
  { name: 'Confirmed',  value: 31, color: '#0AB5A3' },
  { name: 'In Transit', value: 18, color: '#60A5FA' },
  { name: 'Pending',    value: 23, color: '#F59E0B' },
  { name: 'Flagged',    value: 8,  color: '#EF4444' },
]

const TOP_ROUTES = [
  { route: 'Bor → Juba',       trips: 34, value: 8200000  },
  { route: 'Malakal → Renk',   trips: 27, value: 6100000  },
  { route: 'Fangak → Malakal', trips: 19, value: 3800000  },
  { route: 'Bor → Wau',        trips: 14, value: 2700000  },
  { route: 'Pibor → Juba',     trips: 11, value: 2100000  },
]

const DarkTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null
  return (
    <div
      className="px-3 py-2.5 rounded-xl text-[12px] shadow-xl"
      style={{ background: 'var(--bg-deep)', border: '1px solid var(--border)', color: 'var(--text-primary)' }}
    >
      {label && (
        <p className="mb-2 text-[10px]" style={{ fontFamily: 'JetBrains Mono', color: 'var(--text-muted)' }}>{label}</p>
      )}
      {payload.map((p, i) => (
        <div key={i} className="flex items-center justify-between gap-5 mb-0.5">
          <span style={{ color: p.color ?? 'var(--primary)', fontWeight: 600 }}>{p.name}</span>
          <span style={{ fontFamily: 'JetBrains Mono', color: 'var(--text-primary)', fontWeight: 600 }}>
            {typeof p.value === 'number' ? p.value.toLocaleString() : p.value}
          </span>
        </div>
      ))}
    </div>
  )
}

const DonutTooltip = ({ active, payload }) => {
  if (!active || !payload?.length) return null
  const p = payload[0]
  return (
    <div
      className="px-3 py-2 rounded-xl text-[12px] shadow-xl"
      style={{ background: 'var(--bg-deep)', border: '1px solid var(--border)' }}
    >
      <span style={{ color: p.payload.color, fontWeight: 700 }}>{p.name} </span>
      <span style={{ fontFamily: 'JetBrains Mono', color: 'var(--text-primary)' }}>{p.value}</span>
    </div>
  )
}

export default function Analytics() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [chartLoading, setChartLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    api.get('/auth/users/')
      .then(r => setUsers(Array.isArray(r.data) ? r.data : (r.data?.results ?? [])))
      .catch(() => setError('Failed to load live data. Showing sample values.'))
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    const t = setTimeout(() => setChartLoading(false), 700)
    return () => clearTimeout(t)
  }, [])

  const byRole = [
    { role: 'TRADER',      label: 'Fish Traders',  color: '#F59E0B' },
    { role: 'BUYER',       label: 'Buyers',         color: '#0AB5A3' },
    { role: 'TRANSPORTER', label: 'Transporters',   color: '#60A5FA' },
    { role: 'DRIVER',      label: 'Drivers',        color: '#10B981' },
  ].map(r => ({ ...r, count: users.filter(u => u.role === r.role).length }))

  const total = byRole.reduce((s, r) => s + r.count, 0)

  return (
    <AppLayout title="Analytics" subtitle="Trade volume, user distribution and platform metrics">
      {/* Ambient blobs */}
      <div className="pointer-events-none fixed inset-0 overflow-hidden z-0">
        <div className="absolute top-0 right-0 w-[500px] h-[500px] rounded-full blur-[120px]"
          style={{ background: 'rgba(245,158,11,0.05)' }} />
        <div className="absolute bottom-0 left-0 w-[400px] h-[400px] rounded-full blur-[100px]"
          style={{ background: 'rgba(10,181,163,0.05)' }} />
      </div>

      <div className="relative z-10 max-w-[1280px] mx-auto space-y-5">

        {error && (
          <div
            className="px-4 py-2.5 rounded-xl text-[12px] font-medium animate-fade-up"
            style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.2)', color: 'var(--danger)' }}
          >
            {error}
          </div>
        )}

        {/* Row 1 — Revenue Area + Donut */}
        <div className="grid grid-cols-1 xl:grid-cols-[1fr_320px] gap-5">

          {/* Revenue over time */}
          <div className="p-5 animate-fade-up" style={CARD_S}>
            <div className="flex items-start justify-between mb-5">
              <div>
                <p className="text-[11px] font-bold uppercase tracking-widest" style={{ color: 'var(--text-muted)' }}>
                  Revenue Over Time
                </p>
                {chartLoading ? (
                  <div className="shimmer h-8 w-28 rounded-lg mt-1" />
                ) : (
                  <p
                    className="text-[26px] font-semibold leading-tight mt-0.5"
                    style={{ fontFamily: 'JetBrains Mono', color: 'var(--primary)' }}
                  >
                    SSP 32.7M
                  </p>
                )}
              </div>
              <span
                className="text-[11px] font-semibold px-2.5 py-1 rounded-lg"
                style={{ fontFamily: 'JetBrains Mono', background: 'rgba(16,185,129,0.1)', color: 'var(--success)' }}
              >
                +18.4% vs last month
              </span>
            </div>

            {chartLoading ? (
              <div className="shimmer h-52 rounded-xl" />
            ) : (
              <ResponsiveContainer width="100%" height={200}>
                <AreaChart data={REVENUE_DATA} margin={{ top: 4, right: 4, bottom: 0, left: 0 }}>
                  <defs>
                    <linearGradient id="gRev" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%"  stopColor="#0AB5A3" stopOpacity={0.25} />
                      <stop offset="95%" stopColor="#0AB5A3" stopOpacity={0}    />
                    </linearGradient>
                  </defs>
                  <XAxis
                    dataKey="week"
                    tick={{ fontSize: 10, fill: 'var(--text-muted)', fontFamily: 'JetBrains Mono' }}
                    axisLine={false} tickLine={false}
                  />
                  <YAxis
                    tick={{ fontSize: 10, fill: 'var(--text-muted)', fontFamily: 'JetBrains Mono' }}
                    axisLine={false} tickLine={false} width={44}
                    tickFormatter={v => `${(v / 1_000_000).toFixed(1)}M`}
                  />
                  <Tooltip content={<DarkTooltip />} cursor={{ stroke: 'rgba(10,181,163,0.2)', strokeWidth: 1 }} />
                  <Area
                    type="monotone"
                    dataKey="revenue"
                    name="Revenue (SSP)"
                    stroke="#0AB5A3"
                    strokeWidth={2.5}
                    fill="url(#gRev)"
                    dot={false}
                  />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </div>

          {/* Orders by status Donut */}
          <div className="p-5 animate-fade-up stagger-1" style={CARD_S}>
            <p className="text-[11px] font-bold uppercase tracking-widest mb-4" style={{ color: 'var(--text-muted)' }}>
              Orders by Status
            </p>
            {chartLoading ? (
              <div className="shimmer h-52 rounded-xl" />
            ) : (
              <>
                <div className="flex items-center justify-center">
                  <ResponsiveContainer width="100%" height={160}>
                    <PieChart>
                      <Pie
                        data={ORDER_STATUS_DATA}
                        cx="50%" cy="50%"
                        innerRadius={46}
                        outerRadius={72}
                        strokeWidth={2}
                        stroke="var(--bg-elevated)"
                        dataKey="value"
                      >
                        {ORDER_STATUS_DATA.map((entry, i) => (
                          <Cell key={i} fill={entry.color} />
                        ))}
                      </Pie>
                      <Tooltip content={<DonutTooltip />} />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
                <div className="space-y-2 mt-2">
                  {ORDER_STATUS_DATA.map(({ name, value, color }) => (
                    <div key={name} className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <span className="w-2 h-2 rounded-full flex-shrink-0" style={{ background: color }} />
                        <span className="text-[12px] font-medium" style={{ color: 'var(--text-secondary)' }}>{name}</span>
                      </div>
                      <span style={{ fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: 600, color: 'var(--text-primary)' }}>
                        {value}
                      </span>
                    </div>
                  ))}
                </div>
              </>
            )}
          </div>
        </div>

        {/* Row 2 — Top traders horizontal bar + Top routes */}
        <div className="grid grid-cols-1 xl:grid-cols-[1fr_340px] gap-5">

          {/* User distribution bar chart */}
          <div className="p-5 animate-fade-up stagger-2" style={CARD_S}>
            <div className="flex items-start justify-between mb-5">
              <p className="text-[11px] font-bold uppercase tracking-widest" style={{ color: 'var(--text-muted)' }}>
                Users by Role
              </p>
              <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--text-muted)' }}>
                Total <span style={{ color: 'var(--text-primary)', fontWeight: 600 }}>{total}</span>
              </span>
            </div>
            {loading ? (
              <div className="space-y-3">
                {[0,1,2,3].map(i => <div key={i} className="shimmer h-8 rounded-lg" />)}
              </div>
            ) : total === 0 ? (
              <p className="text-[13px] text-center py-8" style={{ color: 'var(--text-muted)' }}>No users registered yet</p>
            ) : (
              <ResponsiveContainer width="100%" height={200}>
                <BarChart
                  data={byRole.map(r => ({ name: r.label, count: r.count, fill: r.color }))}
                  layout="vertical"
                  margin={{ left: 88, right: 24 }}
                >
                  <XAxis
                    type="number"
                    tick={{ fontSize: 10, fill: 'var(--text-muted)', fontFamily: 'JetBrains Mono' }}
                    axisLine={false} tickLine={false}
                  />
                  <YAxis
                    type="category"
                    dataKey="name"
                    tick={{ fontSize: 12, fill: 'var(--text-secondary)', fontFamily: 'Outfit' }}
                    axisLine={false} tickLine={false} width={88}
                  />
                  <Tooltip content={<DarkTooltip />} cursor={{ fill: 'rgba(255,255,255,0.03)' }} />
                  <Bar dataKey="count" name="Users" radius={[0, 6, 6, 0]}>
                    {byRole.map((r, i) => (
                      <Cell key={i} fill={r.color} fillOpacity={0.85} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>

          {/* Top trade routes */}
          <div className="p-5 animate-fade-up stagger-3" style={CARD_S}>
            <p className="text-[11px] font-bold uppercase tracking-widest mb-4" style={{ color: 'var(--text-muted)' }}>
              Top Trade Routes
            </p>
            <div className="space-y-3.5">
              {TOP_ROUTES.map(({ route, trips, value }, i) => (
                <div key={route} className="flex items-center gap-3">
                  <span
                    className="text-[10px] w-5 flex-shrink-0 text-right"
                    style={{ fontFamily: 'JetBrains Mono', color: 'var(--text-muted)' }}
                  >
                    {String(i + 1).padStart(2, '0')}
                  </span>
                  <div className="flex-1 min-w-0">
                    <p className="text-[12px] font-semibold truncate" style={{ color: 'var(--text-primary)' }}>
                      {route}
                    </p>
                    <div
                      className="w-full h-1 rounded-full mt-1.5 overflow-hidden"
                      style={{ background: 'var(--bg-glass)' }}
                    >
                      <div
                        className="h-full rounded-full transition-all duration-700"
                        style={{
                          width: `${(trips / 34) * 100}%`,
                          background: i % 2 === 0 ? 'var(--primary)' : 'var(--secondary)',
                        }}
                      />
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--text-secondary)' }}>
                      {trips} trips
                    </span>
                    <p style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--text-muted)' }}>
                      SSP {(value / 1_000_000).toFixed(1)}M
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

      </div>
    </AppLayout>
  )
}
