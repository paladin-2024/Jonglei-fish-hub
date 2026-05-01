import { NavLink } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

const links = [
  { to: '/dashboard', label: 'Dashboard', icon: '📊' },
  { to: '/users', label: 'Users', icon: '👥' },
  { to: '/orders', label: 'Orders', icon: '📦' },
  { to: '/shipments', label: 'Shipments', icon: '🚚' },
  { to: '/analytics', label: 'Analytics', icon: '📈' },
]

export default function Sidebar() {
  const { logout, user } = useAuth()

  return (
    <aside className="w-64 bg-blue-900 text-white flex flex-col min-h-screen">
      <div className="p-6 border-b border-blue-800">
        <div className="text-xl font-bold">🐟 Jonglei Fish Hub</div>
        <div className="text-xs text-blue-300 mt-1">Admin Dashboard</div>
      </div>

      <nav className="flex-1 p-4 space-y-1">
        {links.map((link) => (
          <NavLink
            key={link.to}
            to={link.to}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition ${
                isActive
                  ? 'bg-blue-700 text-white'
                  : 'text-blue-200 hover:bg-blue-800 hover:text-white'
              }`
            }
          >
            <span>{link.icon}</span>
            {link.label}
          </NavLink>
        ))}
      </nav>

      <div className="p-4 border-t border-blue-800">
        <div className="text-xs text-blue-300 mb-2">{user?.phone_number}</div>
        <button
          onClick={logout}
          className="w-full text-left text-sm text-blue-200 hover:text-white"
        >
          → Logout
        </button>
      </div>
    </aside>
  )
}
