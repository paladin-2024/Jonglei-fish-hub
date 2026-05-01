import { useEffect, useState } from 'react'
import Sidebar from '../components/Sidebar'
import { Users as UsersIcon, Search, Bell, UserCheck, UserX, Phone } from 'lucide-react'
import api from '../api/axios'

const ROLE_COLORS = {
  TRADER:      'bg-teal-50 text-teal-700',
  BUYER:       'bg-blue-50 text-blue-700',
  TRANSPORTER: 'bg-amber-50 text-amber-700',
  DRIVER:      'bg-purple-50 text-purple-700',
}

export default function Users() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')

  useEffect(() => {
    api.get('/auth/users/')
      .then(r => setUsers(r.data?.results ?? r.data ?? []))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const filtered = users.filter(u =>
    u.username?.toLowerCase().includes(search.toLowerCase()) ||
    u.phone_number?.includes(search)
  )

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0">
        <header className="h-16 bg-white border-b border-gray-100 flex items-center justify-between px-8 sticky top-0 z-10">
          <div className="relative">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Search users..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="pl-9 pr-4 py-2 text-sm bg-gray-50 border border-gray-200 rounded-xl w-64 focus:outline-none focus:border-teal-400 transition-colors"
            />
          </div>
          <button className="relative w-9 h-9 flex items-center justify-center rounded-xl hover:bg-gray-100 transition-colors">
            <Bell size={18} className="text-gray-500" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-teal-500 rounded-full" />
          </button>
        </header>

        <main className="flex-1 p-8">
          <div className="mb-6 flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Users</h1>
              <p className="text-gray-500 text-sm mt-0.5">All registered accounts on the platform</p>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-500 bg-white border border-gray-100 px-4 py-2 rounded-xl">
              <UsersIcon size={15} className="text-teal-500" />
              <span className="font-semibold text-gray-700">{users.length}</span> total
            </div>
          </div>

          <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
            {loading ? (
              <div className="flex items-center justify-center py-20 text-gray-400 text-sm">Loading users…</div>
            ) : filtered.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-20 text-gray-400">
                <UsersIcon size={32} className="mb-3 opacity-30" />
                <p className="text-sm">{search ? 'No users match your search' : 'No users yet'}</p>
              </div>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100 bg-gray-50/50">
                    <th className="text-left px-6 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">Name</th>
                    <th className="text-left px-6 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">Phone</th>
                    <th className="text-left px-6 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">Role</th>
                    <th className="text-left px-6 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">Location</th>
                    <th className="text-left px-6 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((u, i) => (
                    <tr key={u.id} className={`border-b border-gray-50 hover:bg-gray-50/50 transition-colors ${i === filtered.length - 1 ? 'border-0' : ''}`}>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-teal-100 flex items-center justify-center flex-shrink-0">
                            <span className="text-xs font-bold text-teal-700">{(u.username || '?')[0].toUpperCase()}</span>
                          </div>
                          <span className="font-semibold text-gray-800">{u.username || '—'}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-gray-500 font-mono text-xs">
                        <div className="flex items-center gap-1.5">
                          <Phone size={12} className="text-gray-300" />
                          {u.phone_number}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${ROLE_COLORS[u.role] ?? 'bg-gray-100 text-gray-600'}`}>
                          {u.role_display ?? u.role}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-gray-500 text-xs">{u.location || '—'}</td>
                      <td className="px-6 py-4">
                        {u.is_verified ? (
                          <div className="flex items-center gap-1.5 text-green-600 text-xs font-medium">
                            <UserCheck size={13} /> Verified
                          </div>
                        ) : (
                          <div className="flex items-center gap-1.5 text-gray-400 text-xs font-medium">
                            <UserX size={13} /> Pending
                          </div>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </main>
      </div>
    </div>
  )
}
