import { TrendingUp } from 'lucide-react'

export default function StatCard({ title, value, Icon, trend, color = 'teal' }) {
  const palette = {
    teal:   { bg: 'bg-teal-50',   icon: 'bg-teal-500',   text: 'text-teal-600' },
    green:  { bg: 'bg-green-50',  icon: 'bg-green-500',  text: 'text-green-600' },
    amber:  { bg: 'bg-amber-50',  icon: 'bg-amber-500',  text: 'text-amber-600' },
    indigo: { bg: 'bg-indigo-50', icon: 'bg-indigo-500', text: 'text-indigo-600' },
  }
  const p = palette[color] || palette.teal

  return (
    <div className="bg-white rounded-2xl border border-gray-100 p-6 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-4">
        <div className={`w-11 h-11 ${p.icon} rounded-xl flex items-center justify-center`}>
          {Icon && <Icon size={20} className="text-white" strokeWidth={2} />}
        </div>
        {trend && (
          <div className="flex items-center gap-1 text-green-600 bg-green-50 px-2 py-1 rounded-lg text-xs font-semibold">
            <TrendingUp size={12} />
            {trend}
          </div>
        )}
      </div>
      <div className="font-bold text-gray-900 font-mono-data mb-1" style={{ fontSize: '1.75rem' }}>
        {value ?? '—'}
      </div>
      <div className="text-sm text-gray-500 font-medium">{title}</div>
    </div>
  )
}
