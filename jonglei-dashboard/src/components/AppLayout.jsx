import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import api from '../api/axios'
import Sidebar from './Sidebar'
import { Search, Bell, X, Menu, LayoutDashboard, Users, ShoppingBag, Truck, BarChart3, TrendingUp, Tag, ShieldCheck } from 'lucide-react'

const SEARCH_SHORTCUTS = [
  { label: 'Overview',      to: '/dashboard',     Icon: LayoutDashboard },
  { label: 'Users',         to: '/users',          Icon: Users           },
  { label: 'Listings',      to: '/listings',       Icon: Tag             },
  { label: 'Orders',        to: '/orders',         Icon: ShoppingBag     },
  { label: 'Shipments',     to: '/shipments',      Icon: Truck           },
  { label: 'Clearance',     to: '/clearance',      Icon: ShieldCheck     },
  { label: 'Market Prices', to: '/market-prices',  Icon: TrendingUp      },
  { label: 'Analytics',     to: '/analytics',      Icon: BarChart3       },
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
      <div className="absolute inset-0 bg-stone-900/30 backdrop-blur-[3px]" />
      <div
        className="relative w-full max-w-[440px] bg-white rounded-2xl shadow-[0_24px_80px_rgba(0,31,26,0.18)] overflow-hidden"
        onClick={e => e.stopPropagation()}
      >
        <div className="h-[3px]" style={{ background: '#005440' }} />

        <div className="flex items-center gap-3 px-4 py-3.5 border-b border-stone-100">
          <Search size={15} className="text-stone-400 flex-shrink-0" />
          <input
            ref={inputRef}
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder="Jump to page…"
            className="flex-1 text-[14px] text-stone-800 placeholder-stone-400 outline-none bg-transparent"
          />
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg hover:bg-stone-100 text-stone-400 transition-colors"
          >
            <X size={13} />
          </button>
        </div>

        <div className="py-2 max-h-72 overflow-y-auto">
          {results.length === 0 ? (
            <p className="text-center text-[13px] text-stone-400 py-6">No results</p>
          ) : results.map(({ label, to, Icon }) => (
            <button
              key={to}
              onClick={() => go(to)}
              className="w-full flex items-center gap-3 px-4 py-2.5 text-[13px] text-stone-700
                         hover:bg-teal-50 hover:text-teal-800 transition-colors text-left"
            >
              <div className="w-7 h-7 rounded-lg bg-stone-100 flex items-center justify-center flex-shrink-0">
                <Icon size={13} className="text-stone-500" strokeWidth={1.75} />
              </div>
              {label}
            </button>
          ))}
        </div>

        <div className="px-4 py-2.5 border-t border-stone-100 bg-stone-50/60 flex items-center gap-4 text-[11px] text-stone-400">
          <span>
            <kbd className="px-1.5 py-0.5 bg-white border border-stone-200 rounded font-mono text-[10px] text-stone-500">↵</kbd>
            {' '}select
          </span>
          <span>
            <kbd className="px-1.5 py-0.5 bg-white border border-stone-200 rounded font-mono text-[10px] text-stone-500">esc</kbd>
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
      // no-op — keep previous count
    }
  }, [])

  useEffect(() => {
    fetchUnread()
    const id = setInterval(fetchUnread, 60_000)
    return () => clearInterval(id)
  }, [fetchUnread])

  // Desktop: collapsed sidebar state, persisted
  const [collapsed, setCollapsed] = useState(() => {
    try { return localStorage.getItem('sidebar_collapsed') === 'true' }
    catch { return false }
  })

  // Mobile: drawer open state
  const [drawerOpen, setDrawerOpen] = useState(false)

  const toggleCollapsed = () => {
    setCollapsed(v => {
      const next = !v
      try { localStorage.setItem('sidebar_collapsed', String(next)) } catch {}
      return next
    })
  }

  // Close drawer on route change (handled via onClose prop passed to Sidebar)
  // Close drawer on resize to desktop
  useEffect(() => {
    const onResize = () => { if (window.innerWidth >= 768) setDrawerOpen(false) }
    window.addEventListener('resize', onResize)
    return () => window.removeEventListener('resize', onResize)
  }, [])

  // ⌘K shortcut
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
    <div className="flex min-h-screen bg-canvas">

      {/* ── Desktop sidebar (hidden on mobile) ── */}
      <div className="hidden md:flex flex-shrink-0">
        <Sidebar
          collapsed={collapsed}
          onToggle={toggleCollapsed}
        />
      </div>

      {/* ── Mobile drawer overlay ── */}
      {drawerOpen && (
        <div
          className="fixed inset-0 z-40 md:hidden"
          onClick={() => setDrawerOpen(false)}
        >
          <div className="absolute inset-0 bg-stone-900/50 backdrop-blur-[2px]" />
        </div>
      )}

      {/* ── Mobile drawer panel ── */}
      <div
        className={`fixed inset-y-0 left-0 z-50 md:hidden
                    transition-transform duration-300 ease-in-out
                    ${drawerOpen ? 'translate-x-0' : '-translate-x-full'}`}
      >
        <Sidebar
          collapsed={false}
          mobile
          onClose={() => setDrawerOpen(false)}
        />
      </div>

      {/* ── Main content ── */}
      <div className="flex-1 flex flex-col min-w-0">

        {/* Topbar */}
        <header className="h-[52px] bg-white border-b border-stone-200/60 flex items-center justify-between px-4 md:px-6 sticky top-0 z-20">
          <div className="flex items-center gap-3">
            {/* Hamburger — mobile only */}
            <button
              className="md:hidden w-8 h-8 flex items-center justify-center rounded-xl
                         hover:bg-stone-100 transition-colors text-stone-500"
              onClick={() => setDrawerOpen(true)}
              aria-label="Open menu"
            >
              <Menu size={17} strokeWidth={2} />
            </button>

            {/* Search / command palette trigger */}
            <button
              onClick={() => setCmdOpen(true)}
              className="hidden sm:flex items-center gap-2 pl-3 pr-4 py-2 text-[13px] bg-stone-50
                         border border-stone-200 rounded-xl text-stone-400 w-52
                         hover:border-teal-300 hover:bg-teal-50/40
                         transition-all duration-200 ease-spring group"
            >
              <Search size={13} className="group-hover:text-teal-600 transition-colors flex-shrink-0" />
              <span className="flex-1 text-left">Search…</span>
              <span className="font-mono text-[10px] bg-white border border-stone-200 text-stone-400 px-1.5 py-0.5 rounded">
                ⌘K
              </span>
            </button>

            {/* Search icon-only for very small screens */}
            <button
              onClick={() => setCmdOpen(true)}
              className="sm:hidden w-8 h-8 flex items-center justify-center rounded-xl
                         hover:bg-stone-100 transition-colors text-stone-500"
              aria-label="Search"
            >
              <Search size={15} strokeWidth={1.75} />
            </button>
          </div>

          <div className="flex items-center gap-1.5">
            <button
              onClick={() => navigate('/notifications')}
              className="relative w-8 h-8 flex items-center justify-center rounded-xl hover:bg-stone-100 transition-colors"
              title="Notifications"
            >
              <Bell size={15} className="text-stone-500" strokeWidth={1.75} />
              {unreadCount > 0 && (
                <span className="absolute top-1 right-1 min-w-[14px] h-[14px] px-0.5
                                 flex items-center justify-center rounded-full
                                 bg-amber-500 text-white text-[8px] font-bold">
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
              <h1 className="font-display text-[22px] md:text-[26px] text-stone-900 leading-tight tracking-tight">
                {title}
              </h1>
            )}
            {subtitle && (
              <p className="text-[13px] text-stone-500 mt-1">{subtitle}</p>
            )}
          </div>
        )}

        <main className="flex-1 p-4 md:p-6 pt-4 md:pt-5">{children}</main>
      </div>

      <CommandPalette open={cmdOpen} onClose={() => setCmdOpen(false)} />
    </div>
  )
}
