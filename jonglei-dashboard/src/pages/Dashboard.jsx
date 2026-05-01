import { useEffect, useState } from 'react'
import Sidebar from '../components/Sidebar'
import StatCard from '../components/StatCard'
import api from '../api/axios'

export default function Dashboard() {
  const [stats, setStats] = useState(null)

  useEffect(() => {
    api.get('/auth/profile/')
      .then(() => {
        setStats({
          users: '—',
          listings: '—',
          orders: '—',
          shipments: '—',
        })
      })
      .catch(() => {})
  }, [])

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <main className="flex-1 p-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">Overview</h1>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          <StatCard title="Total Users" value={stats?.users} icon="👥" />
          <StatCard title="Active Listings" value={stats?.listings} icon="🐟" />
          <StatCard title="Pending Orders" value={stats?.orders} icon="📦" />
          <StatCard title="Shipments in Transit" value={stats?.shipments} icon="🚚" />
        </div>
      </main>
    </div>
  )
}
