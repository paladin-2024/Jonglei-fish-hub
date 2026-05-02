import { NavLink } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import {
  Fish, LayoutDashboard, Users, ShoppingBag, Truck, BarChart3, LogOut,
} from 'lucide-react'

const links = [
  { to: '/dashboard', label: 'Dashboard', Icon: LayoutDashboard },
  { to: '/users',     label: 'Users',     Icon: Users },
  { to: '/orders',    label: 'Orders',    Icon: ShoppingBag },
  { to: '/shipments', label: 'Shipments', Icon: Truck },
  { to: '/analytics', label: 'Analytics', Icon: BarChart3 },
]

const roleInitial = (role) => {
  const map = { TRADER: 'T', BUYER: 'B', TRANSPORTER: 'TR', DRIVER: 'D' }
  return map[role] ?? 'A'
}

export default function Sidebar() {
  const { logout, user } = useAuth()

  return (
    <aside
      className="w-56 flex-shrink-0 flex flex-col min-h-screen"
      style={{ background: 'linear-gradient(180deg, #001f1d 0%, #003832 50%, #004d40 100%)' }}
    >
      {/* Logo */}
      <div className="px-5 pt-5 pb-4">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 bg-teal-400 rounded-xl flex items-center justify-center flex-shrink-0">
            <Fish size={16} className="text-teal-950" strokeWidth={2.5} />
          </div>
          <div>
            <div className="text-white font-bold text-sm leading-tight">Jonglei</div>
            <div className="text-teal-400 text-[10px] tracking-wide">Fish Hub Admin</div>
          </div>
        </div>
      </div>

      <div className="mx-4 h-px" style={{ background: 'rgba(255,255,255,0.06)' }} />

      {/* Nav */}
      <nav className="flex-1 px-3 pt-3 space-y-0.5" aria-label="Main navigation">
        {links.map(({ to, label, Icon }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) =>
              `flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-[13px] font-medium transition-all outline-none focus-visible:ring-2 focus-visible:ring-teal-400 ${
                isActive
                  ? 'bg-white/10 text-white'
                  : 'text-white/50 hover:text-white/80 hover:bg-white/5'
              }`
            }
          >
            {({ isActive }) => (
              <>
                <Icon
                  size={15}
                  strokeWidth={isActive ? 2.5 : 1.75}
                  className={isActive ? 'text-teal-300' : ''}
                />
                {label}
                {isActive && (
                  <span className="ml-auto w-1 h-1 rounded-full bg-teal-400" />
                )}
              </>
            )}
          </NavLink>
        ))}
      </nav>

      {/* Footer */}
      <div className="p-3 pt-0">
        <div className="mx-1 h-px mb-3" style={{ background: 'rgba(255,255,255,0.06)' }} />

        {/* User info */}
        <div className="flex items-center gap-2.5 px-2 py-2 mb-1">
          <div className="w-7 h-7 rounded-lg bg-teal-500/30 flex items-center justify-center flex-shrink-0">
            <span className="text-[10px] font-bold text-teal-300">
              {user?.username ? user.username[0].toUpperCase() : 'A'}
            </span>
          </div>
          <div className="min-w-0">
            <div className="text-white/80 text-[12px] font-semibold truncate">{user?.username || 'Admin'}</div>
            <div className="text-white/30 text-[10px] font-mono truncate">{user?.phone_number}</div>
          </div>
        </div>

        <button
          onClick={logout}
          className="w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-[13px] text-white/40 hover:text-red-400 hover:bg-red-500/10 transition-all font-medium outline-none focus-visible:ring-2 focus-visible:ring-red-400"
        >
          <LogOut size={14} />
          Sign out
        </button>
      </div>
    </aside>
  )
}
