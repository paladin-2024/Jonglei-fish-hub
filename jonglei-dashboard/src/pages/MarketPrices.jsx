import { useState } from 'react'
import AppLayout from '../components/AppLayout'
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'
import { TrendingUp, TrendingDown, Minus, RefreshCw } from 'lucide-react'

const CITIES = [
  {
    city: 'BOR', region: 'Jonglei State', updated: '12 min ago',
    prices: [
      { fish: 'Nile Perch',   price: 2450, delta: 80  },
      { fish: 'Tilapia',      price: 1800, delta: -20  },
      { fish: 'Catfish',      price: 1200, delta: 0    },
    ],
  },
  {
    city: 'JUBA', region: 'Central Equatoria', updated: '8 min ago',
    prices: [
      { fish: 'Nile Perch',   price: 3200, delta: 150 },
      { fish: 'Tilapia',      price: 2000, delta: -50  },
      { fish: 'Catfish',      price: 1900, delta: 100  },
    ],
  },
  {
    city: 'WAU', region: 'W. Bahr el Ghazal', updated: '18 min ago',
    prices: [
      { fish: 'Nile Perch',   price: 2800, delta: -30  },
      { fish: 'Tilapia',      price: 1500, delta: 0    },
      { fish: 'Catfish',      price: 1100, delta: 60   },
    ],
  },
  {
    city: 'MALAKAL', region: 'Upper Nile', updated: '5 min ago',
    prices: [
      { fish: 'Nile Perch',   price: 3500, delta: 200  },
      { fish: 'Tilapia',      price: 1700, delta: -40  },
      { fish: 'Catfish',      price: 1050, delta: 0    },
    ],
  },
  {
    city: 'RENK', region: 'Upper Nile', updated: '31 min ago',
    prices: [
      { fish: 'Nile Perch',   price: 2950, delta: 50   },
      { fish: 'Tilapia',      price: 1650, delta: 20   },
      { fish: 'Catfish',      price: 980,  delta: -15  },
    ],
  },
  {
    city: 'TORIT', region: 'Eastern Equatoria', updated: '44 min ago',
    prices: [
      { fish: 'Nile Perch',   price: 3100, delta: -80  },
      { fish: 'Tilapia',      price: 1850, delta: 30   },
      { fish: 'Catfish',      price: 1400, delta: 0    },
    ],
  },
]

const TREND_DATA = [
  { day: 'Apr 15', BOR: 2300, JUBA: 2900, MALAKAL: 3100 },
  { day: 'Apr 18', BOR: 2350, JUBA: 2980, MALAKAL: 3200 },
  { day: 'Apr 22', BOR: 2280, JUBA: 3050, MALAKAL: 3150 },
  { day: 'Apr 25', BOR: 2400, JUBA: 3100, MALAKAL: 3350 },
  { day: 'Apr 29', BOR: 2370, JUBA: 3000, MALAKAL: 3280 },
  { day: 'May 02', BOR: 2450, JUBA: 3200, MALAKAL: 3500 },
]

const HEALTH = [
  { label: 'MARKET HEALTH', value: 'Stable',  color: '#1A6B3C' },
  { label: 'AVG DEVIATION', value: '+12.4%',  color: '#B45309' },
  { label: 'ACTIVE NODES',  value: '248',     color: '#005440' },
  { label: 'CITIES LIVE',   value: '6',       color: '#1E5C8A' },
]

function DeltaBadge({ delta }) {
  if (delta === 0) return <span className="font-mono text-[10px] text-stone-400">—</span>
  const up = delta > 0
  const Icon = up ? TrendingUp : TrendingDown
  return (
    <span className={`inline-flex items-center gap-1 font-mono text-[10px] font-semibold
                       ${up ? 'text-green-700' : 'text-red-600'}`}>
      <Icon size={9} strokeWidth={2.5} />
      {up ? `+${delta}` : delta}
    </span>
  )
}

function CityCard({ data, delay = 0 }) {
  return (
    <div
      className="bg-white rounded-xl shadow-card hover:shadow-card-hover
                 transition-shadow duration-300 ease-spring overflow-hidden animate-fade-up"
      style={{ animationDelay: `${delay}ms` }}
    >
      <div className="h-[3px]" style={{ background: '#005440' }} />
      <div className="p-5">
        <div className="flex items-start justify-between mb-4">
          <div>
            <p className="font-display text-[22px] text-stone-900 leading-none tracking-tight">
              {data.city}
            </p>
            <p className="text-[10px] font-medium text-stone-400 uppercase tracking-widest mt-1">
              {data.region}
            </p>
          </div>
          <span className="text-[10px] font-mono text-stone-400 mt-1">{data.updated}</span>
        </div>

        <div className="space-y-2.5">
          {data.prices.map(({ fish, price, delta }) => (
            <div key={fish} className="flex items-center justify-between">
              <span className="text-[12px] text-stone-600 font-medium truncate pr-2">{fish}</span>
              <div className="flex items-center gap-3 flex-shrink-0">
                <DeltaBadge delta={delta} />
                <span className="font-mono text-[13px] font-semibold text-stone-900">
                  {price.toLocaleString()}
                </span>
              </div>
            </div>
          ))}
        </div>

        <p className="font-mono text-[9px] text-stone-300 mt-3 pt-2.5 border-t border-stone-100">
          SSP / KG
        </p>
      </div>
    </div>
  )
}

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-white shadow-card-hover border border-stone-100 rounded-xl p-3 text-[12px]">
      <p className="font-mono text-[10px] text-stone-400 mb-2">{label}</p>
      {payload.map(p => (
        <div key={p.dataKey} className="flex items-center justify-between gap-6 mb-1">
          <span style={{ color: p.color }} className="font-semibold">{p.dataKey}</span>
          <span className="font-mono font-semibold text-stone-800">{p.value.toLocaleString()}</span>
        </div>
      ))}
    </div>
  )
}

export default function MarketPrices() {
  const [syncPulse, setSyncPulse] = useState(false)

  const handleSync = () => {
    setSyncPulse(true)
    setTimeout(() => setSyncPulse(false), 1000)
  }

  return (
    <AppLayout title="Market Prices" subtitle="Real-time price ledger across Jonglei trade network">
      <div className="max-w-[1200px] mx-auto space-y-6">

        {/* Live sync header */}
        <div className="flex items-center justify-between animate-fade-up">
          <div className="flex items-center gap-2.5">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75" />
              <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500" />
            </span>
            <span className="text-[12px] font-semibold text-stone-600">
              Live — last global sync <span className="font-mono">09:12 CAT</span>
            </span>
          </div>
          <button
            onClick={handleSync}
            className="flex items-center gap-2 px-3 py-1.5 text-[12px] font-semibold
                       text-teal-700 bg-teal-50 border border-teal-100 rounded-xl
                       hover:bg-teal-100 transition-colors"
          >
            <RefreshCw size={12} className={syncPulse ? 'animate-spin' : ''} />
            Sync now
          </button>
        </div>

        {/* Market health bar */}
        <div className="bg-white rounded-xl shadow-card overflow-hidden animate-fade-up stagger-1">
          <div className="h-[3px]" style={{ background: '#B45309' }} />
          <div className="grid grid-cols-2 md:grid-cols-4 divide-x divide-stone-100">
            {HEALTH.map(({ label, value, color }) => (
              <div key={label} className="px-6 py-4 text-center">
                <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1.5">
                  {label}
                </p>
                <p className="font-display text-[22px] leading-tight" style={{ color }}>
                  {value}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* City price grid — 3-col, no equal boring grid: left col wider on xl */}
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {CITIES.map((city, i) => (
            <CityCard key={city.city} data={city} delay={i * 60} />
          ))}
        </div>

        {/* 30-day Nile Perch trend chart */}
        <div className="bg-white rounded-xl shadow-card overflow-hidden animate-fade-up stagger-4">
          <div className="h-[3px]" style={{ background: '#005440' }} />
          <div className="p-5">
            <div className="flex items-start justify-between mb-6">
              <div>
                <p className="text-[11px] font-bold uppercase tracking-widest text-stone-400">
                  Nile Perch — 30-day price trend
                </p>
                <p className="text-[12px] text-stone-500 mt-1">SSP per kilogram across key markets</p>
              </div>
              <div className="flex items-center gap-4 text-[11px] font-semibold">
                {[['BOR', '#005440'], ['JUBA', '#1E5C8A'], ['MALAKAL', '#B45309']].map(([city, color]) => (
                  <div key={city} className="flex items-center gap-1.5">
                    <span className="w-3 h-1 rounded-full" style={{ background: color }} />
                    <span className="text-stone-500">{city}</span>
                  </div>
                ))}
              </div>
            </div>
            <ResponsiveContainer width="100%" height={220}>
              <AreaChart data={TREND_DATA} margin={{ top: 0, right: 0, bottom: 0, left: 0 }}>
                <defs>
                  <linearGradient id="gBOR" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#005440" stopOpacity={0.12} />
                    <stop offset="95%" stopColor="#005440" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="gJUBA" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#1E5C8A" stopOpacity={0.12} />
                    <stop offset="95%" stopColor="#1E5C8A" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="gMALAKAL" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#B45309" stopOpacity={0.12} />
                    <stop offset="95%" stopColor="#B45309" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <XAxis dataKey="day" tick={{ fontSize: 10, fill: '#97A8A3', fontFamily: 'JetBrains Mono' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 10, fill: '#97A8A3', fontFamily: 'JetBrains Mono' }} axisLine={false} tickLine={false} width={50} />
                <Tooltip content={<CustomTooltip />} />
                <Area type="monotone" dataKey="BOR"     stroke="#005440" strokeWidth={2} fill="url(#gBOR)"     dot={false} />
                <Area type="monotone" dataKey="JUBA"    stroke="#1E5C8A" strokeWidth={2} fill="url(#gJUBA)"    dot={false} />
                <Area type="monotone" dataKey="MALAKAL" stroke="#B45309" strokeWidth={2} fill="url(#gMALAKAL)" dot={false} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

      </div>
    </AppLayout>
  )
}
