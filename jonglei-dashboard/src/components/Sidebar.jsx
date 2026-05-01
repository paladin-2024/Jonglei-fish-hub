import { NavLink } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import {
  Fish, LayoutDashboard, Users, ShoppingBag, Truck, BarChart3, LogOut, ChevronRight,
} from 'lucide-react'

const links = [
  { to: '/dashboard', label: 'Dashboard', Icon: LayoutDashboard },
  { to: '/users',     label: 'Users',     Icon: Users },
  { to: '/orders',    label: 'Orders',    Icon: ShoppingBag },
  { to: '/shipments', label: 'Shipments', Icon: Truck },
  { to: '/analytics', label: 'Analytics', Icon: BarChart3 },
]

export default function Sidebar() {
  const { logout, user } = useAuth()

  return (
    <aside className="w-64 flex flex-col min-h-screen" style={{ background: 'linear-gradient(180deg, #002b27 0%, #004d40 100%)' }}>

      {/* Logo */}
      <div className="p-6 pb-4">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 bg-teal-400 rounded-xl flex items-center justify-center flex-shrink-0">
            <Fish size={18} className="text-teal-950" strokeWidth={2.5} />
          </div>
          <div>
            <div className="text-white font-bold text-sm leading-tight">Jonglei Fish Hub</div>
            <div className="text-teal-400 text-xs">Admin Console</div>
          </div>
        </div>
      </div>

      <div className="mx-4 h-px bg-teal-800 mb-4" />

      {/* Nav */}
      <nav className="flex-1 px-3 space-y-0.5">
        {links.map(({ to, label, Icon }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all group ${
                isActive
                  ? 'bg-teal-500/20 text-teal-300 border border-teal-500/30'
                  : 'text-teal-100/70 hover:text-teal-100 hover:bg-white/5'
              }`
            }
          >
            {({ isActive }) => (
              <>
                <Icon size={17} strokeWidth={isActive ? 2.5 : 2} />
                <span className="flex-1">{label}</span>
                {isActive && <ChevronRight size={13} className="text-teal-400" />}
              </>
            )}
          </NavLink>
        ))}
      </nav>

      {/* Footer */}
      <div className="mx-4 h-px bg-teal-800 mb-4 mt-4" />
      <div className="p-4 pt-0">
        <div className="bg-teal-900/50 rounded-xl p-3 mb-3">
          <div className="text-teal-300 text-xs font-semibold truncate">{user?.username || 'Admin'}</div>
          <div className="text-teal-500 text-xs font-mono-data truncate">{user?.phone_number}</div>
        </div>
        <button
          onClick={logout}
          className="w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-sm text-teal-100/60 hover:text-red-400 hover:bg-red-500/10 transition-all font-medium"
        >
          <LogOut size={16} />
          Sign out
        </button>
      </div>
    </aside>
  )
}
