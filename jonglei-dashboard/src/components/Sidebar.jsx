import { NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import {
  Fish, LayoutDashboard, Users, ShoppingBag,
  Truck, BarChart3, TrendingUp, LogOut, Tag, ShieldCheck,
  ChevronLeft, ChevronRight, Bell, Settings2, FileText,
} from 'lucide-react'

const NAV_SECTIONS = [
  {
    label: 'OVERVIEW',
    links: [
      { to: '/dashboard', label: 'Dashboard', Icon: LayoutDashboard },
    ],
  },
  {
    label: 'TRADE',
    links: [
      { to: '/listings',      label: 'Listings',      Icon: Tag        },
      { to: '/orders',        label: 'Orders',         Icon: ShoppingBag },
      { to: '/market-prices', label: 'Market Prices',  Icon: TrendingUp  },
    ],
  },
  {
    label: 'LOGISTICS',
    links: [
      { to: '/shipments', label: 'Shipments', Icon: Truck      },
      { to: '/clearance', label: 'Clearance', Icon: ShieldCheck },
    ],
  },
  {
    label: 'REPORTS',
    links: [
      { to: '/analytics', label: 'Analytics', Icon: BarChart3 },
    ],
  },
  {
    label: 'ADMIN',
    links: [
      { to: '/users',         label: 'Users',         Icon: Users    },
      { to: '/notifications', label: 'Notifications',  Icon: Bell     },
      { to: '/parameters',    label: 'Parameters',     Icon: Settings2 },
    ],
  },
]

export default function Sidebar({ collapsed, onToggle, onClose, mobile }) {
  const { logout, user } = useAuth()
  const navigate = useNavigate()

  return (
    <aside
      className={`flex flex-col h-full transition-all duration-300 ease-in-out overflow-hidden
                  ${collapsed ? 'w-[64px]' : 'w-[228px]'}`}
      style={{ background: 'var(--sidebar-bg)', borderRight: '1px solid var(--sidebar-border)' }}
    >
      {/* ── Logo ── */}
      <div
        className={`flex items-center pt-5 pb-4 flex-shrink-0
                    ${collapsed ? 'justify-center px-3' : 'justify-between pl-5 pr-3'}`}
      >
        {!collapsed && (
          <div className="flex items-center gap-3">
            <div
              className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
              style={{ background: 'var(--primary-glow)', border: '1px solid rgba(10,181,163,0.3)' }}
            >
              <Fish size={17} style={{ color: 'var(--primary)' }} strokeWidth={2} />
            </div>
            <div>
              <div
                className="text-[16px] leading-tight tracking-tight"
                style={{ fontFamily: "'DM Serif Display', serif", color: 'var(--sidebar-text)' }}
              >
                JONGLEI<span style={{ color: 'var(--primary)' }}>.</span>
              </div>
              <div className="text-[9px] tracking-[0.22em] uppercase font-semibold" style={{ color: 'var(--secondary)' }}>
                Fish Hub
              </div>
            </div>
          </div>
        )}

        {collapsed && (
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
            style={{ background: 'var(--primary-glow)', border: '1px solid rgba(10,181,163,0.3)' }}
          >
            <Fish size={17} style={{ color: 'var(--primary)' }} strokeWidth={2} />
          </div>
        )}

        {!mobile && (
          <button
            onClick={onToggle}
            className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0
                       transition-all duration-200"
            style={{ color: 'var(--text-muted)' }}
            onMouseEnter={e => e.currentTarget.style.color = 'var(--text-primary)'}
            onMouseLeave={e => e.currentTarget.style.color = 'var(--text-muted)'}
            title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          >
            {collapsed
              ? <ChevronRight size={13} strokeWidth={2.5} />
              : <ChevronLeft  size={13} strokeWidth={2.5} />
            }
          </button>
        )}
      </div>

      <div className="mx-3 h-px flex-shrink-0" style={{ background: 'var(--sidebar-border)' }} />

      {/* ── Nav ── */}
      <nav className="flex-1 overflow-y-auto px-2 py-2 space-y-0.5">
        {NAV_SECTIONS.map(({ label, links }) => (
          <div key={label}>
            {!collapsed && (
              <p
                className="px-3 pt-4 pb-1.5 text-[9px] font-bold tracking-[0.2em] uppercase select-none"
                style={{ color: 'var(--sidebar-muted)' }}
              >
                {label}
              </p>
            )}
            {collapsed && <div className="pt-2" />}

            {links.map(({ to, label: linkLabel, Icon }) => (
              <NavLink
                key={to}
                to={to}
                onClick={mobile ? onClose : undefined}
                title={collapsed ? linkLabel : undefined}
                className="group relative block outline-none"
                style={{ transition: 'all 0.2s ease' }}
              >
                {({ isActive }) => (
                  <div
                    className={`relative flex items-center gap-3 rounded-xl text-[13px] font-medium
                                transition-all duration-200
                                ${collapsed ? 'justify-center px-0 py-2.5' : 'px-3 py-2.5'}`}
                    style={{
                      background: isActive ? 'var(--sidebar-active)' : 'transparent',
                      color: isActive ? 'var(--primary)' : 'var(--sidebar-muted)',
                      borderLeft: isActive && !collapsed ? '2px solid var(--primary)' : '2px solid transparent',
                    }}
                    onMouseEnter={e => {
                      if (!isActive) {
                        e.currentTarget.style.background = 'var(--sidebar-hover)'
                        e.currentTarget.style.color = 'var(--sidebar-text)'
                      }
                    }}
                    onMouseLeave={e => {
                      if (!isActive) {
                        e.currentTarget.style.background = 'transparent'
                        e.currentTarget.style.color = 'var(--sidebar-muted)'
                      }
                    }}
                  >
                    <Icon
                      size={collapsed ? 17 : 14}
                      strokeWidth={isActive ? 2.5 : 1.75}
                      style={{ color: isActive ? 'var(--primary)' : 'inherit', flexShrink: 0 }}
                    />
                    {!collapsed && (
                      <span className="flex-1 truncate">{linkLabel}</span>
                    )}
                    {!collapsed && isActive && (
                      <span
                        className="w-1.5 h-1.5 rounded-full flex-shrink-0"
                        style={{ background: 'var(--primary)' }}
                      />
                    )}

                    {/* Collapsed tooltip */}
                    {collapsed && (
                      <span
                        className="absolute left-full ml-3 px-2.5 py-1.5 text-[11px] font-semibold
                                   rounded-lg opacity-0 group-hover:opacity-100 pointer-events-none
                                   transition-opacity duration-150 whitespace-nowrap z-50 shadow-xl"
                        style={{
                          background: 'var(--bg-elevated)',
                          color: 'var(--text-primary)',
                          border: '1px solid var(--border)',
                          boxShadow: '0 4px 16px rgba(0,0,0,0.15)',
                        }}
                      >
                        {linkLabel}
                      </span>
                    )}
                  </div>
                )}
              </NavLink>
            ))}
          </div>
        ))}
      </nav>

      {/* ── Footer ── */}
      <div className="flex-shrink-0 p-2">
        <div className="h-px mx-1 mb-2" style={{ background: 'var(--sidebar-border)' }} />

        {!collapsed && (
          <button
            onClick={() => { navigate('/profile'); if (mobile) onClose?.() }}
            className="flex items-center gap-2.5 px-2 py-2 mb-1 rounded-xl w-full text-left
                       transition-all duration-200"
            style={{ color: 'var(--sidebar-text)' }}
            onMouseEnter={e => e.currentTarget.style.background = 'var(--sidebar-hover)'}
            onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
          >
            <div
              className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 font-bold text-[11px]"
              style={{ background: 'var(--primary-glow)', color: 'var(--primary)', border: '1px solid rgba(10,181,163,0.25)' }}
            >
              {user?.username ? user.username[0].toUpperCase() : 'A'}
            </div>
            <div className="min-w-0 flex-1">
              <div className="text-[12px] font-semibold truncate" style={{ color: 'var(--sidebar-text)' }}>
                {user?.username || 'Admin'}
              </div>
              <div className="text-[10px] truncate" style={{ fontFamily: 'JetBrains Mono', color: 'var(--sidebar-muted)' }}>
                {user?.phone_number || 'Admin'}
              </div>
            </div>
          </button>
        )}

        {collapsed && (
          <button
            onClick={() => navigate('/profile')}
            className="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0 font-bold text-[11px] mb-1 mx-auto
                       hover:opacity-80 transition-opacity"
            style={{ background: 'var(--primary-glow)', color: 'var(--primary)', border: '1px solid rgba(10,181,163,0.25)', display: 'flex' }}
            title={user?.username || 'Profile'}
          >
            {user?.username ? user.username[0].toUpperCase() : 'A'}
          </button>
        )}

        <button
          onClick={logout}
          title={collapsed ? 'Sign out' : undefined}
          className={`flex items-center gap-2.5 rounded-xl text-[12px] font-medium
                     transition-all duration-200 outline-none
                     ${collapsed ? 'w-10 h-10 justify-center mx-auto' : 'w-full px-3 py-2'}`}
          style={{ color: 'var(--sidebar-muted)' }}
          onMouseEnter={e => {
            e.currentTarget.style.color = '#EF4444'
            e.currentTarget.style.background = 'rgba(239,68,68,0.12)'
          }}
          onMouseLeave={e => {
            e.currentTarget.style.color = 'var(--sidebar-muted)'
            e.currentTarget.style.background = 'transparent'
          }}
        >
          <LogOut size={13} strokeWidth={1.75} />
          {!collapsed && 'Sign out'}
        </button>
      </div>
    </aside>
  )
}
