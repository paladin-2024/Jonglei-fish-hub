import { TrendingUp, TrendingDown, Minus } from 'lucide-react'

const COLOR_MAP = {
  teal:   { icon: 'text-teal-600',   bg: 'bg-teal-50',   border: 'border-teal-100'   },
  green:  { icon: 'text-green-600',  bg: 'bg-green-50',  border: 'border-green-100'  },
  amber:  { icon: 'text-amber-600',  bg: 'bg-amber-50',  border: 'border-amber-100'  },
  indigo: { icon: 'text-indigo-600', bg: 'bg-indigo-50', border: 'border-indigo-100' },
}

export default function StatCard({ title, value, Icon, color = 'teal', trend, note }) {
  const c = COLOR_MAP[color] ?? COLOR_MAP.teal

  const trendDir = trend
    ? trend.startsWith('+') ? 'up' : trend.startsWith('-') ? 'down' : 'flat'
    : null

  const TrendIcon = trendDir === 'up' ? TrendingUp : trendDir === 'down' ? TrendingDown : Minus
  const trendColor = trendDir === 'up'
    ? 'text-green-600 bg-green-50'
    : trendDir === 'down'
    ? 'text-red-500 bg-red-50'
    : 'text-gray-400 bg-gray-50'

  return (
    <div className={`bg-white rounded-2xl border ${c.border} p-5 flex flex-col gap-4`}>
      <div className="flex items-start justify-between">
        <p className="text-[13px] font-medium text-gray-500 leading-snug">{title}</p>
        <div className={`w-8 h-8 rounded-xl ${c.bg} flex items-center justify-center flex-shrink-0`}>
          {Icon && <Icon size={15} className={c.icon} strokeWidth={2} />}
        </div>
      </div>

      <div className="flex items-end justify-between gap-2">
        <span className="font-mono text-3xl font-semibold text-gray-900 leading-none tracking-tight">
          {value ?? <span className="text-gray-300 text-2xl">—</span>}
        </span>
        {trend && (
          <span className={`inline-flex items-center gap-1 text-xs font-semibold px-2 py-1 rounded-lg ${trendColor}`}>
            <TrendIcon size={11} strokeWidth={2.5} />
            {trend}
          </span>
        )}
      </div>

      {note && <p className="text-xs text-gray-400 leading-snug">{note}</p>}
    </div>
  )
}
