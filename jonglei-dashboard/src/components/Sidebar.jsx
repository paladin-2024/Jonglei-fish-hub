import { NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import {
  Fish, LayoutDashboard, Users, ShoppingBag,
  Truck, BarChart3, TrendingUp, LogOut, Tag, ShieldCheck, ChevronLeft, ChevronRight,
  Bell, Settings2,
} from 'lucide-react'

const links = [
  { to: '/dashboard',      label: 'Overview',       Icon: LayoutDashboard },
  { to: '/users',          label: 'Users',           Icon: Users           },
  { to: '/listings',       label: 'Listings',        Icon: Tag             },
  { to: '/orders',         label: 'Orders',          Icon: ShoppingBag     },
  { to: '/shipments',      label: 'Shipments',       Icon: Truck           },
  { to: '/clearance',      label: 'Clearance',       Icon: ShieldCheck     },
  { to: '/market-prices',  label: 'Market Prices',   Icon: TrendingUp      },
  { to: '/analytics',      label: 'Analytics',       Icon: BarChart3       },
  { to: '/notifications',  label: 'Notifications',   Icon: Bell            },
  { to: '/parameters',     label: 'Parameters',      Icon: Settings2       },
]

export default function Sidebar({ collapsed, onToggle, onClose, mobile }) {
  const { logout, user } = useAuth()
  const navigate = useNavigate()

  return (
    <aside
      className={`flex flex-col h-full transition-all duration-300 ease-in-out
                  ${collapsed ? 'w-[64px]' : 'w-[220px]'}`}
      style={{ background: 'linear-gradient(175deg, #001F1A 0%, #002B25 40%, #004D3C 100%)' }}
    >
      {/* Logo + toggle */}
      <div className={`flex items-center px-3 pt-5 pb-4 ${collapsed ? 'justify-center' : 'justify-between pl-5 pr-3'}`}>
        {!collapsed && (
          <div className="flex items-center gap-3">
            <div
              className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
              style={{ background: 'rgba(180,83,9,0.9)' }}
            >
              <Fish size={17} className="text-white" strokeWidth={2} />
            </div>
            <div>
              <div className="font-display text-white text-[15px] leading-tight tracking-tight">Jonglei</div>
              <div className="text-[10px] tracking-widest uppercase text-teal-400 font-medium">Fish Hub</div>
            </div>
          </div>
        )}
        {collapsed && (
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
            style={{ background: 'rgba(180,83,9,0.9)' }}
          >
            <Fish size={17} className="text-white" strokeWidth={2} />
          </div>
        )}
        {/* Toggle — desktop only */}
        {!mobile && (
          <button
            onClick={onToggle}
            className="w-7 h-7 rounded-lg flex items-center justify-center
                       text-white/30 hover:text-white/70 hover:bg-white/[0.06]
                       transition-all duration-200 flex-shrink-0"
            title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          >
            {collapsed
              ? <ChevronRight size={13} strokeWidth={2.5} />
              : <ChevronLeft  size={13} strokeWidth={2.5} />
            }
          </button>
        )}
      </div>

      <div className="mx-3 h-px" style={{ background: 'rgba(255,255,255,0.06)' }} />

      {/* Nav label */}
      {!collapsed && (
        <p className="px-5 pt-4 pb-2 text-[9px] font-bold uppercase tracking-[0.18em] text-white/25">
          Navigation
        </p>
      )}
      {collapsed && <div className="pt-3" />}

      {/* Links */}
      <nav className="flex-1 px-2 space-y-0.5">
        {links.map(({ to, label, Icon }) => (
          <NavLink
            key={to}
            to={to}
            onClick={mobile ? onClose : undefined}
            title={collapsed ? label : undefined}
            className={({ isActive }) =>
              `group relative flex items-center gap-3 rounded-xl text-[13px] font-medium
               transition-all duration-200 ease-spring outline-none
               focus-visible:ring-2 focus-visible:ring-amber-400/60
               ${collapsed ? 'justify-center px-0 py-2.5 w-full' : 'px-3 py-[9px]'}
               ${isActive
                 ? 'bg-white/[0.08] text-white'
                 : 'text-white/45 hover:text-white/80 hover:bg-white/[0.04]'
               }`
            }
          >
            {({ isActive }) => (
              <>
                <Icon
                  size={collapsed ? 17 : 14}
                  strokeWidth={isActive ? 2.5 : 1.75}
                  className={isActive ? 'text-amber-400' : 'group-hover:text-white/70 transition-colors'}
                />
                {!collapsed && <span className="flex-1">{label}</span>}
                {!collapsed && isActive && (
                  <span className="w-1.5 h-1.5 rounded-full bg-amber-400 flex-shrink-0" />
                )}
                {/* Tooltip in collapsed mode */}
                {collapsed && (
                  <span className="absolute left-full ml-3 px-2.5 py-1.5 bg-stone-900 text-white text-[11px]
                                   font-semibold rounded-lg opacity-0 group-hover:opacity-100 pointer-events-none
                                   transition-opacity duration-150 whitespace-nowrap z-50 shadow-lg">
                    {label}
                  </span>
                )}
              </>
            )}
          </NavLink>
        ))}
      </nav>

      {/* Footer */}
      <div className={`p-2 mt-2 ${collapsed ? 'flex flex-col items-center' : ''}`}>
        <div className="mx-1 h-px mb-2" style={{ background: 'rgba(255,255,255,0.06)' }} />

        {!collapsed && (
          <button
            onClick={() => { navigate('/profile'); if (mobile) onClose?.() }}
            className="flex items-center gap-2.5 px-2 py-2 mb-1 rounded-xl hover:bg-white/[0.06] transition-colors w-full text-left"
          >
            <div
              className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 font-bold text-[11px]"
              style={{ background: 'rgba(180,83,9,0.25)', color: '#FBB347' }}
            >
              {user?.username ? user.username[0].toUpperCase() : 'A'}
            </div>
            <div className="min-w-0 flex-1">
              <div className="text-white/75 text-[12px] font-semibold truncate">{user?.username || 'Admin'}</div>
              <div className="font-mono text-white/25 text-[10px] truncate">{user?.phone_number || 'Admin'}</div>
            </div>
          </button>
        )}

        {collapsed && (
          <button
            onClick={() => navigate('/profile')}
            className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 font-bold text-[11px] mb-1
                       hover:opacity-80 transition-opacity"
            style={{ background: 'rgba(180,83,9,0.25)', color: '#FBB347' }}
            title={user?.username || 'Profile'}
          >
            {user?.username ? user.username[0].toUpperCase() : 'A'}
          </button>
        )}

        <button
          onClick={logout}
          title={collapsed ? 'Sign out' : undefined}
          className={`flex items-center gap-2.5 rounded-xl text-[12px]
                     text-white/35 hover:text-red-400 hover:bg-red-500/10
                     transition-all duration-200 font-medium outline-none
                     focus-visible:ring-2 focus-visible:ring-red-400/60
                     ${collapsed ? 'w-10 h-10 justify-center' : 'w-full px-3 py-2'}`}
        >
          <LogOut size={13} strokeWidth={1.75} />
          {!collapsed && 'Sign out'}
        </button>
      </div>
    </aside>
  )
}
