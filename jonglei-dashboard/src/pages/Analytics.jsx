import { useEffect, useState } from 'react'
import AppLayout from '../components/AppLayout'
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, Tooltip, ResponsiveContainer, Legend,
} from 'recharts'
import { Fish, Users, Truck, BarChart3 } from 'lucide-react'
import api from '../api/axios'

const ROLE_COLORS = {
  TRADER:      '#005440',
  BUYER:       '#1E5C8A',
  TRANSPORTER: '#B45309',
  DRIVER:      '#1A6B3C',
}

const VOLUME_DATA = [
  { week: 'W1 Apr', volume: 1240, value: 3720000 },
  { week: 'W2 Apr', volume: 1890, value: 5670000 },
  { week: 'W3 Apr', volume: 1560, value: 4680000 },
  { week: 'W4 Apr', volume: 2100, value: 6300000 },
  { week: 'W1 May', volume: 1780, value: 5340000 },
  { week: 'W2 May', volume: 2340, value: 7020000 },
]

const CLEARANCE_DATA = [
  { name: 'Cleared', value: 47, color: '#1A6B3C' },
  { name: 'Pending', value: 28, color: '#B45309' },
  { name: 'Flagged', value: 8,  color: '#B91C1C' },
]

const TOP_ROUTES = [
  { route: 'Bor → Juba',       count: 34, value: 'SSP 8.2M' },
  { route: 'Malakal → Renk',   count: 27, value: 'SSP 6.1M' },
  { route: 'Fangak → Malakal', count: 19, value: 'SSP 3.8M' },
  { route: 'Bor → Wau',        count: 14, value: 'SSP 2.7M' },
  { route: 'Pibor → Juba',     count: 11, value: 'SSP 2.1M' },
]

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-white shadow-card-hover border border-stone-100 rounded-xl p-3 text-[12px]">
      <p className="font-mono text-[10px] text-stone-400 mb-2">{label}</p>
      {payload.map(p => (
        <div key={p.dataKey} className="flex items-center justify-between gap-5 mb-1">
          <span style={{ color: p.color }} className="font-semibold">{p.name}</span>
          <span className="font-mono font-semibold text-stone-800">
            {typeof p.value === 'number' ? p.value.toLocaleString() : p.value}
          </span>
        </div>
      ))}
    </div>
  )
}

export default function Analytics() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.get('/auth/users/')
      .then(r => setUsers(Array.isArray(r.data) ? r.data : (r.data?.results ?? [])))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const byRole = [
    { role: 'TRADER',      label: 'Fish Traders',  Icon: Fish,     color: ROLE_COLORS.TRADER      },
    { role: 'BUYER',       label: 'Buyers',         Icon: Users,    color: ROLE_COLORS.BUYER       },
    { role: 'TRANSPORTER', label: 'Transporters',   Icon: Truck,    color: ROLE_COLORS.TRANSPORTER },
    { role: 'DRIVER',      label: 'Drivers',        Icon: Truck,    color: ROLE_COLORS.DRIVER      },
  ].map(r => ({ ...r, count: users.filter(u => u.role === r.role).length }))

  const barData = byRole.map(r => ({ name: r.label, count: r.count, fill: r.color }))
  const total = byRole.reduce((s, r) => s + r.count, 0)

  return (
    <AppLayout title="Analytics" subtitle="Trade volume, user distribution and platform metrics">
      <div className="max-w-[1200px] mx-auto space-y-5">

        {/* Row 1 — 2-col asymmetric */}
        <div className="grid grid-cols-1 xl:grid-cols-[1fr_340px] gap-5">

          {/* Trade volume trend */}
          <div className="bg-white rounded-xl shadow-card overflow-hidden animate-fade-up">
            <div className="h-[3px]" style={{ background: '#005440' }} />
            <div className="p-5">
              <div className="flex items-start justify-between mb-5">
                <div>
                  <p className="text-[11px] font-bold uppercase tracking-widest text-stone-400">
                    Weekly trade volume
                  </p>
                  <p className="font-display text-[26px] text-stone-900 leading-tight mt-0.5">
                    13,910 <span className="text-[18px] text-stone-400">kg</span>
                  </p>
                </div>
                <span className="text-[11px] font-mono px-2 py-1 bg-green-50 text-green-700 rounded-lg font-semibold">
                  +18.4% vs last month
                </span>
              </div>
              <ResponsiveContainer width="100%" height={180}>
                <AreaChart data={VOLUME_DATA} margin={{ top: 0, right: 0, bottom: 0, left: 0 }}>
                  <defs>
                    <linearGradient id="gVol" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#005440" stopOpacity={0.14} />
                      <stop offset="95%" stopColor="#005440" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <XAxis dataKey="week" tick={{ fontSize: 10, fill: '#97A8A3', fontFamily: 'JetBrains Mono' }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 10, fill: '#97A8A3', fontFamily: 'JetBrains Mono' }} axisLine={false} tickLine={false} width={40} />
                  <Tooltip content={<CustomTooltip />} />
                  <Area type="monotone" dataKey="volume" name="Volume (kg)" stroke="#005440" strokeWidth={2.5} fill="url(#gVol)" dot={false} />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Clearance status donut */}
          <div className="bg-white rounded-xl shadow-card overflow-hidden animate-fade-up stagger-1">
            <div className="h-[3px]" style={{ background: '#1A6B3C' }} />
            <div className="p-5">
              <p className="text-[11px] font-bold uppercase tracking-widest text-stone-400 mb-4">
                Clearance status
              </p>
              <div className="flex items-center justify-center">
                <ResponsiveContainer width="100%" height={160}>
                  <PieChart>
                    <Pie
                      data={CLEARANCE_DATA}
                      cx="50%" cy="50%"
                      innerRadius={45}
                      outerRadius={72}
                      strokeWidth={0}
                      dataKey="value"
                    >
                      {CLEARANCE_DATA.map((entry) => (
                        <Cell key={entry.name} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip content={<CustomTooltip />} />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <div className="space-y-2 mt-2">
                {CLEARANCE_DATA.map(({ name, value, color }) => (
                  <div key={name} className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ background: color }} />
                      <span className="text-[12px] text-stone-600 font-medium">{name}</span>
                    </div>
                    <span className="font-mono text-[12px] font-semibold text-stone-700">{value}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Row 2 — user breakdown + top routes */}
        <div className="grid grid-cols-1 xl:grid-cols-[1fr_340px] gap-5">

          {/* User distribution bar chart */}
          <div className="bg-white rounded-xl shadow-card overflow-hidden animate-fade-up stagger-2">
            <div className="h-[3px]" style={{ background: '#1E5C8A' }} />
            <div className="p-5">
              <div className="flex items-start justify-between mb-5">
                <p className="text-[11px] font-bold uppercase tracking-widest text-stone-400">
                  User distribution by role
                </p>
                <span className="font-mono text-[11px] text-stone-400">
                  Total <span className="font-semibold text-stone-700">{total}</span>
                </span>
              </div>
              {loading ? (
                <div className="space-y-3">
                  {[0,1,2,3].map(i => <div key={i} className="shimmer h-8 rounded-lg" />)}
                </div>
              ) : total === 0 ? (
                <p className="text-[13px] text-stone-400 text-center py-8">No users registered yet</p>
              ) : (
                <ResponsiveContainer width="100%" height={180}>
                  <BarChart data={barData} layout="vertical" margin={{ left: 80, right: 20 }}>
                    <XAxis type="number" tick={{ fontSize: 10, fill: '#97A8A3', fontFamily: 'JetBrains Mono' }} axisLine={false} tickLine={false} />
                    <YAxis type="category" dataKey="name" tick={{ fontSize: 12, fill: '#5C6B67', fontFamily: 'Outfit' }} axisLine={false} tickLine={false} width={80} />
                    <Tooltip content={<CustomTooltip />} />
                    <Bar dataKey="count" name="Users" radius={[0, 6, 6, 0]}>
                      {barData.map((entry, i) => (
                        <Cell key={i} fill={entry.fill} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              )}
            </div>
          </div>

          {/* Top routes */}
          <div className="bg-white rounded-xl shadow-card overflow-hidden animate-fade-up stagger-3">
            <div className="h-[3px]" style={{ background: '#B45309' }} />
            <div className="p-5">
              <p className="text-[11px] font-bold uppercase tracking-widest text-stone-400 mb-4">
                Top trade routes
              </p>
              <div className="space-y-3">
                {TOP_ROUTES.map(({ route, count, value }, i) => (
                  <div key={route} className="flex items-center gap-3">
                    <span className="font-mono text-[10px] text-stone-300 w-4 flex-shrink-0">
                      {String(i + 1).padStart(2, '0')}
                    </span>
                    <div className="flex-1 min-w-0">
                      <p className="text-[12px] font-semibold text-stone-700 truncate">{route}</p>
                      <div className="w-full h-1 bg-stone-100 rounded-full mt-1 overflow-hidden">
                        <div
                          className="h-full rounded-full transition-all duration-700"
                          style={{ width: `${(count / 34) * 100}%`, background: '#B45309' }}
                        />
                      </div>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <span className="font-mono text-[11px] text-stone-500">{count} trips</span>
                      <p className="font-mono text-[10px] text-stone-400">{value}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

      </div>
    </AppLayout>
  )
}
