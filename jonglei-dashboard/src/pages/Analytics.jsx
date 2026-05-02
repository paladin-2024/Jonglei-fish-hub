import { useEffect, useState } from 'react'
import AppLayout from '../components/AppLayout'
import { BarChart3, Fish, Users, Truck } from 'lucide-react'
import api from '../api/axios'

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
    { role: 'TRADER',      label: 'Fish Traders',       Icon: Fish,  color: 'bg-teal-500' },
    { role: 'BUYER',       label: 'Buyers',              Icon: Users, color: 'bg-blue-500' },
    { role: 'TRANSPORTER', label: 'Transporters',        Icon: Truck, color: 'bg-amber-500' },
    { role: 'DRIVER',      label: 'Drivers',             Icon: Truck, color: 'bg-purple-500' },
  ].map(r => ({ ...r, count: users.filter(u => u.role === r.role).length }))

  const max = Math.max(...byRole.map(r => r.count), 1)

  return (
    <AppLayout title="Analytics" subtitle="Trade volume, trends and platform metrics">
      <div className="max-w-6xl mx-auto space-y-4">

        {/* User distribution chart */}
        <div className="bg-white rounded-2xl border border-gray-100 p-5">
          <p className="text-[11px] font-semibold uppercase tracking-widest text-gray-400 mb-5">User distribution by role</p>
          {loading ? (
            <div className="space-y-4">
              {[0,1,2,3].map(i => (
                <div key={i} className="flex items-center gap-3">
                  <div className="w-24 h-3 bg-gray-100 rounded animate-pulse" />
                  <div className="flex-1 h-6 bg-gray-100 rounded animate-pulse" style={{ width: `${30 + i * 15}%`, maxWidth: '70%' }} />
                  <div className="w-6 h-3 bg-gray-100 rounded animate-pulse" />
                </div>
              ))}
            </div>
          ) : users.length === 0 ? (
            <p className="text-sm text-gray-400 text-center py-8">No data yet</p>
          ) : (
            <div className="space-y-4">
              {byRole.map(({ role, label, Icon, color, count }) => (
                <div key={role} className="flex items-center gap-3">
                  <div className="flex items-center gap-1.5 w-32 flex-shrink-0">
                    <Icon size={12} className="text-gray-400" />
                    <span className="text-[12px] text-gray-600 font-medium">{label}</span>
                  </div>
                  <div className="flex-1 h-5 bg-gray-100 rounded-lg overflow-hidden">
                    <div
                      className={`h-full ${color} rounded-lg transition-all duration-700`}
                      style={{ width: `${(count / max) * 100}%` }}
                    />
                  </div>
                  <span className="font-mono text-[12px] font-semibold text-gray-600 w-6 text-right flex-shrink-0">
                    {count}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Upcoming metrics */}
        <div className="bg-white rounded-2xl border border-gray-100 flex flex-col items-center justify-center py-16 px-8 text-center">
          <div className="w-14 h-14 bg-teal-50 rounded-2xl flex items-center justify-center mb-5">
            <BarChart3 size={24} className="text-teal-600" />
          </div>
          <h2 className="text-base font-bold text-gray-800 mb-1.5">More analytics soon</h2>
          <p className="text-[13px] text-gray-400 max-w-xs leading-relaxed">
            Trade volume charts, revenue trends, and route heat maps will appear as transaction data grows.
          </p>
        </div>
      </div>
    </AppLayout>
  )
}
