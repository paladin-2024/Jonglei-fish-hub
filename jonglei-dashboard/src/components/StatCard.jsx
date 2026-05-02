import { TrendingUp, TrendingDown, Minus } from 'lucide-react'

const ACCENT = {
  teal:   { bar: '#005440', icon: 'text-teal-700',   iconBg: 'bg-teal-50'   },
  green:  { bar: '#1A6B3C', icon: 'text-green-700',  iconBg: 'bg-green-50'  },
  amber:  { bar: '#B45309', icon: 'text-amber-700',  iconBg: 'bg-amber-50'  },
  indigo: { bar: '#1E5C8A', icon: 'text-blue-700',   iconBg: 'bg-blue-50'   },
  red:    { bar: '#B91C1C', icon: 'text-red-700',    iconBg: 'bg-red-50'    },
}

export default function StatCard({ title, value, Icon, color = 'teal', trend, note }) {
  const c = ACCENT[color] ?? ACCENT.teal

  const trendDir = trend
    ? trend.startsWith('+') ? 'up' : trend.startsWith('-') ? 'down' : 'flat'
    : null

  const TrendIcon  = trendDir === 'up' ? TrendingUp : trendDir === 'down' ? TrendingDown : Minus
  const trendColor = trendDir === 'up'
    ? 'text-green-700 bg-green-50'
    : trendDir === 'down'
    ? 'text-red-600 bg-red-50'
    : 'text-stone-400 bg-stone-100'

  return (
    <div
      className="bg-white rounded-xl shadow-card hover:shadow-card-hover transition-shadow duration-300 ease-spring overflow-hidden flex flex-col"
      style={{ '--accent': c.bar }}
    >
      {/* 3px top accent bar — category indicator, NOT side stripe */}
      <div className="h-[3px] w-full flex-shrink-0" style={{ background: c.bar }} />

      <div className="p-5 flex flex-col gap-3 flex-1">
        <div className="flex items-start justify-between gap-2">
          <p className="text-[11px] font-semibold uppercase tracking-widest text-stone-400 leading-tight">
            {title}
          </p>
          {Icon && (
            <div className={`w-8 h-8 rounded-lg ${c.iconBg} flex items-center justify-center flex-shrink-0`}>
              <Icon size={14} className={c.icon} strokeWidth={2} />
            </div>
          )}
        </div>

        <div className="flex items-end justify-between gap-2">
          <span className="font-mono text-[2rem] font-semibold leading-none tracking-tight text-stone-900">
            {value ?? <span className="text-stone-300 text-2xl">—</span>}
          </span>
          {trend && (
            <span className={`inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-1 rounded-lg ${trendColor} flex-shrink-0`}>
              <TrendIcon size={10} strokeWidth={2.5} />
              {trend}
            </span>
          )}
        </div>

        {note && (
          <p className="text-[11px] text-stone-400 leading-snug pt-1 border-t border-stone-100">
            {note}
          </p>
        )}
      </div>
    </div>
  )
}
