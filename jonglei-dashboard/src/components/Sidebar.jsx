import { NavLink } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import {
  Fish, LayoutDashboard, Users, ShoppingBag,
  Truck, BarChart3, TrendingUp, LogOut, Tag,
} from 'lucide-react'

const links = [
  { to: '/dashboard',    label: 'Overview',      Icon: LayoutDashboard },
  { to: '/users',        label: 'Users',          Icon: Users           },
  { to: '/listings',     label: 'Listings',       Icon: Tag             },
  { to: '/orders',       label: 'Orders',         Icon: ShoppingBag     },
  { to: '/shipments',    label: 'Shipments',      Icon: Truck           },
  { to: '/market-prices',label: 'Market Prices',  Icon: TrendingUp      },
  { to: '/analytics',    label: 'Analytics',      Icon: BarChart3       },
]

export default function Sidebar() {
  const { logout, user } = useAuth()

  return (
    <aside
      className="w-[220px] flex-shrink-0 flex flex-col min-h-screen"
      style={{ background: 'linear-gradient(175deg, #001F1A 0%, #002B25 40%, #004D3C 100%)' }}
    >
      {/* Logo wordmark */}
      <div className="px-5 pt-6 pb-5">
        <div className="flex items-center gap-3">
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
            style={{ background: 'rgba(180,83,9,0.9)' }}
          >
            <Fish size={17} className="text-white" strokeWidth={2} />
          </div>
          <div>
            <div className="font-display text-white text-[15px] leading-tight tracking-tight">
              Jonglei
            </div>
            <div className="text-[10px] tracking-widest uppercase text-teal-400 font-medium">
              Fish Hub
            </div>
          </div>
        </div>
      </div>

      <div className="mx-5 h-px" style={{ background: 'rgba(255,255,255,0.06)' }} />

      {/* Nav label */}
      <p className="px-5 pt-5 pb-2 text-[9px] font-bold uppercase tracking-[0.18em] text-white/25">
        Navigation
      </p>

      {/* Links */}
      <nav className="flex-1 px-3 space-y-0.5">
        {links.map(({ to, label, Icon }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) =>
              `group flex items-center gap-3 px-3 py-[9px] rounded-xl text-[13px] font-medium
               transition-all duration-200 ease-spring outline-none
               focus-visible:ring-2 focus-visible:ring-amber-400/60
               ${isActive
                 ? 'bg-white/[0.08] text-white'
                 : 'text-white/45 hover:text-white/80 hover:bg-white/[0.04]'
               }`
            }
          >
            {({ isActive }) => (
              <>
                <Icon
                  size={14}
                  strokeWidth={isActive ? 2.5 : 1.75}
                  className={isActive ? 'text-amber-400' : 'group-hover:text-white/70 transition-colors'}
                />
                <span className="flex-1">{label}</span>
                {isActive && (
                  <span className="w-1.5 h-1.5 rounded-full bg-amber-400 flex-shrink-0" />
                )}
              </>
            )}
          </NavLink>
        ))}
      </nav>

      {/* Footer */}
      <div className="p-3 mt-2">
        <div className="mx-2 h-px mb-3" style={{ background: 'rgba(255,255,255,0.06)' }} />

        <div className="flex items-center gap-2.5 px-2 py-2 mb-1 rounded-xl hover:bg-white/[0.04] transition-colors">
          <div
            className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 font-bold text-[11px]"
            style={{ background: 'rgba(180,83,9,0.25)', color: '#FBB347' }}
          >
            {user?.username ? user.username[0].toUpperCase() : 'A'}
          </div>
          <div className="min-w-0 flex-1">
            <div className="text-white/75 text-[12px] font-semibold truncate">
              {user?.username || 'Admin'}
            </div>
            <div className="font-mono text-white/25 text-[10px] truncate">
              {user?.phone_number || 'Admin'}
            </div>
          </div>
        </div>

        <button
          onClick={logout}
          className="w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-[12px]
                     text-white/35 hover:text-red-400 hover:bg-red-500/10
                     transition-all duration-200 font-medium outline-none
                     focus-visible:ring-2 focus-visible:ring-red-400/60"
        >
          <LogOut size={13} strokeWidth={1.75} />
          Sign out
        </button>
      </div>
    </aside>
  )
}
