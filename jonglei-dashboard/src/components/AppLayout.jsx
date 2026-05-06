import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import api from '../api/axios'
import Sidebar from './Sidebar'
import { Search, Bell, X, Menu, LayoutDashboard, Users, ShoppingBag, Truck, BarChart3, TrendingUp, Tag, ShieldCheck } from 'lucide-react'

const SEARCH_SHORTCUTS = [
  { label: 'Dashboard',    to: '/dashboard',     Icon: LayoutDashboard },
  { label: 'Users',        to: '/users',          Icon: Users           },
  { label: 'Listings',     to: '/listings',       Icon: Tag             },
  { label: 'Orders',       to: '/orders',         Icon: ShoppingBag     },
  { label: 'Shipments',    to: '/shipments',      Icon: Truck           },
  { label: 'Clearance',    to: '/clearance',      Icon: ShieldCheck     },
  { label: 'Market Prices',to: '/market-prices',  Icon: TrendingUp      },
  { label: 'Analytics',    to: '/analytics',      Icon: BarChart3       },
]

function CommandPalette({ open, onClose }) {
  const [query, setQuery] = useState('')
  const navigate = useNavigate()
  const inputRef = useRef(null)

  useEffect(() => {
    if (open) { setQuery(''); setTimeout(() => inputRef.current?.focus(), 50) }
  }, [open])

  useEffect(() => {
    const handler = (e) => { if (e.key === 'Escape') onClose() }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [onClose])

  const results = SEARCH_SHORTCUTS.filter(s =>
    !query || s.label.toLowerCase().includes(query.toLowerCase())
  )

  const go = (to) => { navigate(to); onClose() }

  if (!open) return null

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center pt-[18vh]"
      onClick={onClose}
    >
      <div className="absolute inset-0 backdrop-blur-[4px]" style={{ background: 'rgba(28,25,20,0.45)' }} />
      <div
        className="relative w-full max-w-[460px] rounded-2xl overflow-hidden shadow-[0_24px_80px_rgba(0,0,0,0.5)]"
        style={{
          background: 'var(--bg-elevated)',
          border: '1px solid var(--border)',
        }}
        onClick={e => e.stopPropagation()}
      >
        {/* Amber accent top */}
        <div className="h-[2px]" style={{ background: 'linear-gradient(90deg, var(--primary), var(--secondary))' }} />

        <div
          className="flex items-center gap-3 px-4 py-3.5"
          style={{ borderBottom: '1px solid var(--border)' }}
        >
          <Search size={15} style={{ color: 'var(--text-muted)', flexShrink: 0 }} />
          <input
            ref={inputRef}
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder="Jump to page…"
            className="flex-1 text-[14px] outline-none bg-transparent"
            style={{ color: 'var(--text-primary)', fontFamily: 'Outfit' }}
          />
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg transition-colors"
            style={{ color: 'var(--text-muted)' }}
            onMouseEnter={e => e.currentTarget.style.background = 'var(--bg-glass)'}
            onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
          >
            <X size={13} />
          </button>
        </div>

        <div className="py-2 max-h-72 overflow-y-auto">
          {results.length === 0 ? (
            <p className="text-center text-[13px] py-6" style={{ color: 'var(--text-muted)' }}>
              No results
            </p>
          ) : results.map(({ label, to, Icon }) => (
            <button
              key={to}
              onClick={() => go(to)}
              className="w-full flex items-center gap-3 px-4 py-2.5 text-[13px] text-left transition-all duration-150"
              style={{ color: 'var(--text-secondary)', transition: 'all 0.15s ease' }}
              onMouseEnter={e => {
                e.currentTarget.style.background = 'rgba(10,181,163,0.08)'
                e.currentTarget.style.color = 'var(--primary)'
              }}
              onMouseLeave={e => {
                e.currentTarget.style.background = 'transparent'
                e.currentTarget.style.color = 'var(--text-secondary)'
              }}
            >
              <div
                className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0"
                style={{ background: 'var(--bg-glass)', border: '1px solid var(--border)' }}
              >
                <Icon size={13} style={{ color: 'var(--secondary)' }} strokeWidth={1.75} />
              </div>
              {label}
            </button>
          ))}
        </div>

        <div
          className="px-4 py-2.5 flex items-center gap-4 text-[11px]"
          style={{ borderTop: '1px solid var(--border)', color: 'var(--text-muted)' }}
        >
          <span>
            <kbd
              className="px-1.5 py-0.5 rounded text-[10px]"
              style={{ background: 'var(--bg-base)', border: '1px solid var(--border)', fontFamily: 'JetBrains Mono', color: 'var(--text-secondary)' }}
            >↵</kbd>
            {' '}select
          </span>
          <span>
            <kbd
              className="px-1.5 py-0.5 rounded text-[10px]"
              style={{ background: 'var(--bg-base)', border: '1px solid var(--border)', fontFamily: 'JetBrains Mono', color: 'var(--text-secondary)' }}
            >esc</kbd>
            {' '}close
          </span>
        </div>
      </div>
    </div>
  )
}

export default function AppLayout({ children, title, subtitle }) {
  const navigate = useNavigate()
  const [cmdOpen, setCmdOpen] = useState(false)
  const [unreadCount, setUnreadCount] = useState(0)

  const fetchUnread = useCallback(async () => {
    try {
      const { data } = await api.get('/notifications/')
      const list = Array.isArray(data) ? data : (data.results ?? [])
      setUnreadCount(list.filter(n => !n.is_read).length)
    } catch {
      // no-op
    }
  }, [])

  useEffect(() => {
    fetchUnread()
    const id = setInterval(fetchUnread, 60_000)
    return () => clearInterval(id)
  }, [fetchUnread])

  const [collapsed, setCollapsed] = useState(() => {
    try { return localStorage.getItem('sidebar_collapsed') === 'true' }
    catch { return false }
  })

  const [drawerOpen, setDrawerOpen] = useState(false)

  const toggleCollapsed = () => {
    setCollapsed(v => {
      const next = !v
      try { localStorage.setItem('sidebar_collapsed', String(next)) } catch {}
      return next
    })
  }

  useEffect(() => {
    const onResize = () => { if (window.innerWidth >= 768) setDrawerOpen(false) }
    window.addEventListener('resize', onResize)
    return () => window.removeEventListener('resize', onResize)
  }, [])

  useEffect(() => {
    const handler = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault()
        setCmdOpen(v => !v)
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [])

  return (
    <div className="flex min-h-screen" style={{ background: 'var(--bg-base)' }}>

      {/* Desktop sidebar */}
      <div className="hidden md:flex flex-shrink-0" style={{ position: 'sticky', top: 0, height: '100vh' }}>
        <Sidebar collapsed={collapsed} onToggle={toggleCollapsed} />
      </div>

      {/* Mobile overlay */}
      {drawerOpen && (
        <div
          className="fixed inset-0 z-40 md:hidden"
          onClick={() => setDrawerOpen(false)}
        >
          <div className="absolute inset-0 backdrop-blur-[2px]" style={{ background: 'rgba(28,25,20,0.45)' }} />
        </div>
      )}

      {/* Mobile drawer */}
      <div
        className={`fixed inset-y-0 left-0 z-50 md:hidden
                    transition-transform duration-300 ease-in-out
                    ${drawerOpen ? 'translate-x-0' : '-translate-x-full'}`}
      >
        <Sidebar collapsed={false} mobile onClose={() => setDrawerOpen(false)} />
      </div>

      {/* Main content */}
      <div className="flex-1 flex flex-col min-w-0">

        {/* Topbar */}
        <header
          className="h-[54px] flex items-center justify-between px-4 md:px-6 sticky top-0 z-20 flex-shrink-0"
          style={{
            background: 'var(--bg-base)',
            borderBottom: '1px solid var(--border)',
            backdropFilter: 'blur(12px)',
          }}
        >
          <div className="flex items-center gap-3">
            {/* Hamburger — mobile */}
            <button
              className="md:hidden w-8 h-8 flex items-center justify-center rounded-xl transition-colors"
              style={{ color: 'var(--text-muted)' }}
              onClick={() => setDrawerOpen(true)}
              onMouseEnter={e => e.currentTarget.style.background = 'var(--bg-glass)'}
              onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
              aria-label="Open menu"
            >
              <Menu size={17} strokeWidth={2} />
            </button>

            {/* Search trigger */}
            <button
              onClick={() => setCmdOpen(true)}
              className="hidden sm:flex items-center gap-2 pl-3 pr-3 py-2 text-[13px] rounded-xl w-52
                         transition-all duration-200 group"
              style={{
                background: 'var(--bg-glass)',
                border: '1px solid var(--border)',
                color: 'var(--text-muted)',
              }}
              onMouseEnter={e => {
                e.currentTarget.style.borderColor = 'rgba(10,181,163,0.3)'
                e.currentTarget.style.background = 'rgba(10,181,163,0.05)'
              }}
              onMouseLeave={e => {
                e.currentTarget.style.borderColor = 'var(--border)'
                e.currentTarget.style.background = 'var(--bg-glass)'
              }}
            >
              <Search size={13} style={{ flexShrink: 0 }} />
              <span className="flex-1 text-left text-[12px]">Search…</span>
              <span
                className="text-[10px] px-1.5 py-0.5 rounded"
                style={{
                  fontFamily: 'JetBrains Mono',
                  background: 'var(--bg-base)',
                  border: '1px solid var(--border)',
                  color: 'var(--text-muted)',
                }}
              >
                ⌘K
              </span>
            </button>

            {/* Icon-only search for small screens */}
            <button
              onClick={() => setCmdOpen(true)}
              className="sm:hidden w-8 h-8 flex items-center justify-center rounded-xl transition-colors"
              style={{ color: 'var(--text-muted)' }}
              aria-label="Search"
            >
              <Search size={15} strokeWidth={1.75} />
            </button>
          </div>

          <div className="flex items-center gap-1.5">
            <button
              onClick={() => navigate('/notifications')}
              className="relative w-8 h-8 flex items-center justify-center rounded-xl transition-all duration-200"
              style={{ color: 'var(--text-muted)' }}
              onMouseEnter={e => {
                e.currentTarget.style.background = 'var(--bg-glass)'
                e.currentTarget.style.color = 'var(--text-primary)'
              }}
              onMouseLeave={e => {
                e.currentTarget.style.background = 'transparent'
                e.currentTarget.style.color = 'var(--text-muted)'
              }}
              title="Notifications"
            >
              <Bell size={15} strokeWidth={1.75} />
              {unreadCount > 0 && (
                <span
                  className="absolute top-1 right-1 min-w-[14px] h-[14px] px-0.5
                             flex items-center justify-center rounded-full
                             text-[8px] font-bold"
                  style={{ background: 'var(--primary)', color: 'var(--bg-deep)' }}
                >
                  {unreadCount > 9 ? '9+' : unreadCount}
                </span>
              )}
            </button>
          </div>
        </header>

        {/* Page heading */}
        {(title || subtitle) && (
          <div className="px-4 md:px-7 pt-7 pb-1 animate-fade-up">
            {title && (
              <h1
                className="text-[22px] md:text-[28px] leading-tight"
                style={{ fontFamily: "'DM Serif Display', serif", color: 'var(--text-primary)' }}
              >
                {title}
              </h1>
            )}
            {subtitle && (
              <p className="text-[13px] mt-1" style={{ color: 'var(--text-muted)' }}>{subtitle}</p>
            )}
          </div>
        )}

        <main className="flex-1 p-4 md:p-6 pt-4 md:pt-5">{children}</main>
      </div>

      <CommandPalette open={cmdOpen} onClose={() => setCmdOpen(false)} />
    </div>
  )
}
