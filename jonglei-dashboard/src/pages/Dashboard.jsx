import { useEffect, useState } from 'react'
import { useAuth } from '../context/AuthContext'
import Sidebar from '../components/Sidebar'
import StatCard from '../components/StatCard'
import { Users, Fish, ShoppingBag, Truck, Bell, Search } from 'lucide-react'
import api from '../api/axios'

export default function Dashboard() {
  const { user } = useAuth()
  const [stats, setStats] = useState(null)

  useEffect(() => {
    api.get('/auth/profile/')
      .then(() => {
        setStats({ users: '—', listings: '—', orders: '—', shipments: '—' })
      })
      .catch(() => {})
  }, [])

  const hour = new Date().getHours()
  const greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening'

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0">

        {/* Top bar */}
        <header className="h-16 bg-white border-b border-gray-100 flex items-center justify-between px-8 sticky top-0 z-10">
          <div className="relative">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Search..."
              className="pl-9 pr-4 py-2 text-sm bg-gray-50 border border-gray-200 rounded-xl w-64 focus:outline-none focus:border-teal-400 transition-colors"
            />
          </div>
          <button className="relative w-9 h-9 flex items-center justify-center rounded-xl hover:bg-gray-100 transition-colors">
            <Bell size={18} className="text-gray-500" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-teal-500 rounded-full" />
          </button>
        </header>

        {/* Content */}
        <main className="flex-1 p-8">

          {/* Greeting */}
          <div className="mb-8">
            <p className="text-sm text-teal-600 font-semibold uppercase tracking-widest mb-1">{greeting}</p>
            <h1 className="text-3xl font-bold text-gray-900">
              {user?.username || 'Admin'} <span className="text-gray-400 font-light">—</span>
            </h1>
            <p className="text-gray-500 mt-1">Here's what's happening in Jonglei today.</p>
          </div>

          {/* Stats grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-5 mb-8">
            <StatCard title="Total Users"          value={stats?.users}     Icon={Users}       color="teal"   trend="+12%" />
            <StatCard title="Active Listings"      value={stats?.listings}  Icon={Fish}        color="green"  trend="+5%"  />
            <StatCard title="Pending Orders"       value={stats?.orders}    Icon={ShoppingBag} color="amber"              />
            <StatCard title="Shipments in Transit" value={stats?.shipments} Icon={Truck}       color="indigo" trend="+3%" />
          </div>

          {/* Placeholder activity panel */}
          <div className="bg-white rounded-2xl border border-gray-100 p-6">
            <div className="flex items-center justify-between mb-5">
              <h2 className="font-bold text-gray-900 text-lg">Recent Activity</h2>
              <span className="text-xs text-teal-600 font-semibold bg-teal-50 px-3 py-1 rounded-full">Live</span>
            </div>
            <div className="space-y-3">
              {[
                ['New trader registered', '+211 911 000 007', '2m ago'],
                ['Fish listing posted — 50kg Nile Perch', 'Malakal Market', '14m ago'],
                ['Shipment dispatched to Bor', 'Route #38', '1h ago'],
              ].map(([title, sub, time]) => (
                <div key={title} className="flex items-center gap-4 py-3 border-b border-gray-50 last:border-0">
                  <div className="w-2 h-2 rounded-full bg-teal-400 flex-shrink-0" />
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-semibold text-gray-800 truncate">{title}</div>
                    <div className="text-xs text-gray-400">{sub}</div>
                  </div>
                  <div className="text-xs text-gray-400 font-mono-data flex-shrink-0">{time}</div>
                </div>
              ))}
            </div>
          </div>
        </main>
      </div>
    </div>
  )
}
