import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import Sidebar from './Sidebar'
import { Search, Bell, X, LayoutDashboard, Users, ShoppingBag, Truck, BarChart3, TrendingUp, Tag } from 'lucide-react'

const SEARCH_SHORTCUTS = [
  { label: 'Overview',      to: '/dashboard',     Icon: LayoutDashboard },
  { label: 'Users',         to: '/users',          Icon: Users           },
  { label: 'Listings',      to: '/listings',       Icon: Tag             },
  { label: 'Orders',        to: '/orders',         Icon: ShoppingBag     },
  { label: 'Shipments',     to: '/shipments',      Icon: Truck           },
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
        {/* Top accent */}
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
  const [cmdOpen, setCmdOpen] = useState(false)

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
      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0">
        {/* Topbar */}
        <header className="h-[52px] bg-white border-b border-stone-200/60 flex items-center justify-between px-6 sticky top-0 z-20">
          <button
            onClick={() => setCmdOpen(true)}
            className="flex items-center gap-2 pl-3 pr-4 py-2 text-[13px] bg-stone-50
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

          <div className="flex items-center gap-1.5">
            <button className="relative w-8 h-8 flex items-center justify-center rounded-xl hover:bg-stone-100 transition-colors">
              <Bell size={15} className="text-stone-500" strokeWidth={1.75} />
              <span className="absolute top-1.5 right-1.5 w-1.5 h-1.5 rounded-full bg-amber-500" />
            </button>
          </div>
        </header>

        {/* Page heading */}
        {(title || subtitle) && (
          <div className="px-7 pt-7 pb-1 animate-fade-up">
            {title && (
              <h1 className="font-display text-[26px] text-stone-900 leading-tight tracking-tight">
                {title}
              </h1>
            )}
            {subtitle && (
              <p className="text-[13px] text-stone-500 mt-1">{subtitle}</p>
            )}
          </div>
        )}

        <main className="flex-1 p-6 pt-5">{children}</main>
      </div>

      <CommandPalette open={cmdOpen} onClose={() => setCmdOpen(false)} />
    </div>
  )
}
