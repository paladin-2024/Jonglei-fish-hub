import { useState, useMemo, useEffect } from 'react'
import AppLayout from '../components/AppLayout'
import {
  ShoppingBag, Search, Filter, TrendingUp,
  ChevronDown, ChevronRight, RefreshCw, ArrowUpRight,
} from 'lucide-react'
import api from '../api/axios'

const CARD_S = {
  background: 'var(--bg-elevated)',
  border: '1px solid var(--border)',
  borderRadius: 'var(--radius)',
}


function normalizeOrder(o) {
  const listing = o.listing_detail ?? o.listing ?? {}
  const buyer   = o.buyer_detail   ?? o.buyer   ?? {}
  const seller  = listing.seller_detail ?? listing.seller ?? {}
  return {
    id:     o.id?.toString().slice(0, 12).toUpperCase() ?? o.id,
    fish:   listing.species ?? '—',
    qty:    `${o.quantity_kg ?? '?'} kg`,
    buyer:  typeof buyer === 'object' ? (buyer.username ?? buyer.phone_number ?? '—') : buyer,
    seller: typeof seller === 'object' ? (seller.username ?? seller.phone_number ?? '—') : seller,
    price:  Number(o.total_price ?? 0),
    status: (o.status ?? 'PENDING').replace('_', ' '),
    date:   o.created_at
      ? new Date(o.created_at).toLocaleDateString('en-GB', { day:'2-digit', month:'short', year:'numeric' })
      : '—',
    route:  listing.location ? `${listing.location} → ?` : '—',
  }
}

const STATUS_STYLES = {
  CONFIRMED:    { color: '#0AB5A3', bg: 'rgba(10,181,163,0.12)'  },
  'IN TRANSIT': { color: '#60A5FA', bg: 'rgba(96,165,250,0.12)'  },
  'IN_TRANSIT': { color: '#60A5FA', bg: 'rgba(96,165,250,0.12)'  },
  PENDING:      { color: '#F59E0B', bg: 'rgba(245,158,11,0.12)'  },
  CLEARED:      { color: '#10B981', bg: 'rgba(16,185,129,0.12)'  },
  FLAGGED:      { color: '#EF4444', bg: 'rgba(239,68,68,0.12)'   },
  CANCELLED:    { color: '#475569', bg: 'rgba(71,85,105,0.2)'    },
}

const FILTERS = ['ALL', 'PENDING', 'IN TRANSIT', 'CONFIRMED', 'CLEARED', 'FLAGGED']
const COLS = [
  { col: 'id',     label: 'ORDER ID' },
  { col: 'fish',   label: 'FISH'     },
  { col: 'buyer',  label: 'BUYER'    },
  { col: 'qty',    label: 'QTY'      },
  { col: 'price',  label: 'VALUE'    },
  { col: 'route',  label: 'ROUTE'    },
  { col: 'status', label: 'STATUS'   },
  { col: 'date',   label: 'DATE'     },
]

function fmtSSP(n) { return 'SSP ' + n.toLocaleString() }

function SortChevron({ active, dir }) {
  if (!active) return null
  return (
    <ChevronDown
      size={11}
      className={`inline ml-0.5 transition-transform duration-150 ${dir === 'asc' ? 'rotate-180' : ''}`}
    />
  )
}

function SkeletonRow() {
  return (
    <tr style={{ borderBottom: '1px solid var(--border)' }}>
      {[...Array(9)].map((_, i) => (
        <td key={i} className="px-5 py-4">
          <div className="shimmer h-3 rounded" style={{ width: `${50 + (i % 3) * 20}%` }} />
        </td>
      ))}
    </tr>
  )
}

function ExpandedDetail({ order }) {
  const st = STATUS_STYLES[order.status] ?? STATUS_STYLES.PENDING
  return (
    <tr style={{ background: 'rgba(10,181,163,0.04)' }}>
      <td colSpan={9} className="px-6 py-4">
        <div className="flex flex-wrap gap-6">
          <div>
            <p className="text-[10px] font-bold uppercase tracking-widest mb-1" style={{ color: 'var(--text-muted)' }}>Seller</p>
            <p className="text-[13px] font-semibold" style={{ color: 'var(--text-primary)' }}>{order.seller}</p>
          </div>
          <div>
            <p className="text-[10px] font-bold uppercase tracking-widest mb-1" style={{ color: 'var(--text-muted)' }}>Route</p>
            <p className="text-[13px] font-semibold" style={{ color: 'var(--text-primary)' }}>{order.route}</p>
          </div>
          <div>
            <p className="text-[10px] font-bold uppercase tracking-widest mb-1" style={{ color: 'var(--text-muted)' }}>Quantity</p>
            <p className="text-[13px] font-semibold" style={{ fontFamily: 'JetBrains Mono', color: 'var(--text-primary)' }}>{order.qty}</p>
          </div>
          <div>
            <p className="text-[10px] font-bold uppercase tracking-widest mb-1" style={{ color: 'var(--text-muted)' }}>Total Value</p>
            <p className="text-[13px] font-semibold" style={{ fontFamily: 'JetBrains Mono', color: 'var(--primary)' }}>
              {fmtSSP(order.price)}
            </p>
          </div>
          <div>
            <p className="text-[10px] font-bold uppercase tracking-widest mb-1" style={{ color: 'var(--text-muted)' }}>Date</p>
            <p className="text-[13px] font-semibold" style={{ fontFamily: 'JetBrains Mono', color: 'var(--text-secondary)' }}>{order.date}</p>
          </div>
          <div>
            <p className="text-[10px] font-bold uppercase tracking-widest mb-1" style={{ color: 'var(--text-muted)' }}>Status</p>
            <span
              className="inline-flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wide px-2.5 py-1 rounded-full"
              style={{ color: st.color, background: st.bg }}
            >
              <span className="w-1.5 h-1.5 rounded-full" style={{ background: st.color }} />
              {order.status}
            </span>
          </div>
        </div>
      </td>
    </tr>
  )
}

export default function Orders() {
  const [orders, setOrders]           = useState([])
  const [loading, setLoading]         = useState(true)
  const [liveData, setLiveData]       = useState(false)
  const [activeFilter, setActiveFilter] = useState('ALL')
  const [search, setSearch]           = useState('')
  const [sortCol, setSortCol]         = useState('id')
  const [sortDir, setSortDir]         = useState('desc')
  const [expandedId, setExpandedId]   = useState(null)

  const ACTIVE_STATUSES = ['PENDING', 'CONFIRMED', 'IN TRANSIT', 'IN_TRANSIT']

  const fetchOrders = () => {
    return api.get('/marketplace/orders/')
      .then(r => {
        const raw = Array.isArray(r.data) ? r.data : (r.data?.results ?? [])
        if (raw.length > 0) {
          setOrders(raw.map(normalizeOrder))
          setLiveData(true)
        }
      })
      .catch(() => {})
  }

  useEffect(() => {
    fetchOrders().finally(() => setLoading(false))
  }, [])

  const hasActive = orders.some(o => ACTIVE_STATUSES.includes(o.status))
  const [polling, setPolling] = useState(false)

  useEffect(() => {
    if (!hasActive) { setPolling(false); return }
    setPolling(true)
    const id = setInterval(() => fetchOrders(), 5000)
    return () => { clearInterval(id); setPolling(false) }
  }, [hasActive])

  const filtered = useMemo(() => {
    const q = search.toLowerCase()
    return orders
      .filter(o => activeFilter === 'ALL' || o.status === activeFilter)
      .filter(o => !q || [o.id, o.fish, o.buyer, o.seller, o.route].some(v => String(v).toLowerCase().includes(q)))
      .sort((a, b) => {
        const av = a[sortCol], bv = b[sortCol]
        if (sortCol === 'price') return sortDir === 'asc' ? av - bv : bv - av
        return sortDir === 'asc' ? String(av).localeCompare(String(bv)) : String(bv).localeCompare(String(av))
      })
  }, [orders, activeFilter, search, sortCol, sortDir])

  const filteredRevenue = useMemo(
    () => filtered.filter(o => ['CLEARED','CONFIRMED'].includes(o.status)).reduce((s, o) => s + o.price, 0),
    [filtered]
  )

  const kpiItems = useMemo(() => [
    { label: 'TOTAL ORDERS',         val: orders.length,                                                                     color: 'var(--secondary)'  },
    { label: 'CLEARED',              val: orders.filter(o => o.status === 'CLEARED').length,                                 color: 'var(--success)'    },
    { label: 'IN TRANSIT',           val: orders.filter(o => ['IN TRANSIT','IN_TRANSIT'].includes(o.status)).length,        color: '#60A5FA'            },
    { label: 'CONF + CLEARED VALUE', val: fmtSSP(orders.filter(o => ['CLEARED','CONFIRMED'].includes(o.status)).reduce((s,o) => s + o.price, 0)), color: 'var(--primary)' },
  ], [orders])

  function toggleSort(col) {
    if (sortCol === col) setSortDir(d => d === 'asc' ? 'desc' : 'asc')
    else { setSortCol(col); setSortDir('asc') }
  }

  return (
    <AppLayout title="Orders" subtitle="Fish purchase transactions across the platform">
      <div className="max-w-[1280px] mx-auto space-y-5">

        {/* KPI strip */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {kpiItems.map((k, i) => (
            <div
              key={i}
              className={`p-5 flex flex-col gap-2 animate-fade-up stagger-${i + 1}`}
              style={CARD_S}
            >
              <p className="text-[10px] font-semibold uppercase tracking-widest" style={{ color: 'var(--text-muted)' }}>
                {k.label}
              </p>
              <span
                className="text-[26px] font-semibold leading-none"
                style={{ fontFamily: 'JetBrains Mono', color: k.color }}
              >
                {loading ? <span className="shimmer inline-block h-7 w-16 rounded-lg" /> : k.val}
              </span>
            </div>
          ))}
        </div>

        {/* Toolbar */}
        <div className="p-4 flex flex-col gap-3 animate-fade-up stagger-5" style={CARD_S}>
          <div className="flex items-center gap-3 flex-wrap">
            <div className="relative flex-1 min-w-[200px]">
              <Search
                size={14}
                className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"
                style={{ color: 'var(--text-muted)' }}
              />
              <input
                type="text"
                placeholder="Search order ID, fish, buyer…"
                value={search}
                onChange={e => setSearch(e.target.value)}
                className="w-full pl-9 pr-4 py-2 text-[13px] rounded-xl outline-none transition-all duration-200"
                style={{
                  background: 'var(--bg-glass)',
                  border: '1px solid var(--border)',
                  color: 'var(--text-primary)',
                  fontFamily: 'Outfit',
                }}
                onFocus={e => e.target.style.borderColor = 'rgba(10,181,163,0.4)'}
                onBlur={e => e.target.style.borderColor = 'var(--border)'}
              />
            </div>
            <div className="flex items-center gap-2 text-[12px]" style={{ color: 'var(--text-muted)' }}>
              <Filter size={12} />
              <span>{filtered.length} of {orders.length}</span>
            </div>
            {(liveData || polling) && (
              <div
                className="flex items-center gap-1.5 text-[11px] font-semibold px-2.5 py-1 rounded-lg"
                style={{ background: 'rgba(16,185,129,0.1)', color: 'var(--success)' }}
              >
                <span className="relative flex h-2 w-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full opacity-75" style={{ background: 'var(--success)' }} />
                  <span className="relative inline-flex rounded-full h-2 w-2" style={{ background: 'var(--success)' }} />
                </span>
                LIVE
              </div>
            )}
            {filteredRevenue > 0 && (
              <div
                className="flex items-center gap-1.5 text-[11px] font-semibold px-3 py-1.5 rounded-lg"
                style={{ background: 'var(--primary-glow)', color: 'var(--primary)' }}
              >
                <TrendingUp size={11} strokeWidth={2.5} />
                {fmtSSP(filteredRevenue)}
              </div>
            )}
          </div>

          {/* Filter chips */}
          <div className="flex gap-2 flex-wrap">
            {FILTERS.map(f => {
              const st = STATUS_STYLES[f]
              const isActive = activeFilter === f
              return (
                <button
                  key={f}
                  onClick={() => setActiveFilter(f)}
                  className="text-[11px] font-semibold uppercase tracking-wide px-3 py-1.5 rounded-full transition-all duration-200"
                  style={{
                    background: isActive
                      ? (f === 'ALL' ? 'var(--primary)' : (STATUS_STYLES[f]?.bg ?? 'var(--primary-glow)'))
                      : 'var(--bg-glass)',
                    color: isActive
                      ? (f === 'ALL' ? 'var(--bg-deep)' : (STATUS_STYLES[f]?.color ?? 'var(--primary)'))
                      : 'var(--text-muted)',
                    border: `1px solid ${isActive ? 'transparent' : 'var(--border)'}`,
                  }}
                >
                  {f}
                </button>
              )
            })}
          </div>
        </div>

        {/* Table */}
        <div className="overflow-hidden animate-fade-up stagger-6" style={CARD_S}>
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border)' }}>
                  {COLS.map(({ col, label }) => (
                    <th
                      key={col}
                      onClick={() => toggleSort(col)}
                      className="px-5 py-3.5 text-[10px] font-semibold uppercase tracking-widest cursor-pointer select-none whitespace-nowrap transition-all duration-150"
                      style={{ color: sortCol === col ? 'var(--primary)' : 'var(--text-muted)' }}
                    >
                      {label}
                      <SortChevron active={sortCol === col} dir={sortDir} />
                    </th>
                  ))}
                  <th className="px-4 py-3 w-8" />
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  [...Array(5)].map((_, i) => <SkeletonRow key={i} />)
                ) : filtered.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="text-center py-16 text-[13px]" style={{ color: 'var(--text-muted)' }}>
                      <ShoppingBag size={28} className="mx-auto mb-3 opacity-30" />
                      No orders match this filter
                    </td>
                  </tr>
                ) : filtered.map((o) => {
                  const s = STATUS_STYLES[o.status] ?? STATUS_STYLES.PENDING
                  const isExpanded = expandedId === o.id
                  return [
                    <tr
                      key={o.id}
                      className="cursor-pointer transition-all duration-150"
                      style={{ borderBottom: '1px solid var(--border)' }}
                      onMouseEnter={e => !isExpanded && (e.currentTarget.style.background = 'rgba(255,255,255,0.03)')}
                      onMouseLeave={e => !isExpanded && (e.currentTarget.style.background = 'transparent')}
                      onClick={() => setExpandedId(isExpanded ? null : o.id)}
                    >
                      <td className="px-5 py-3.5">
                        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: 600, color: 'var(--primary)' }}>
                          {o.id}
                        </span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="text-[13px] font-semibold" style={{ color: 'var(--text-primary)' }}>{o.fish}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="text-[13px]" style={{ color: 'var(--text-secondary)' }}>{o.buyer}</div>
                      </td>
                      <td className="px-5 py-3.5">
                        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 12, color: 'var(--text-secondary)' }}>{o.qty}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>
                          {fmtSSP(o.price)}
                        </span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="text-[12px] whitespace-nowrap" style={{ color: 'var(--text-muted)' }}>{o.route}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span
                          className="inline-flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wide px-2.5 py-1 rounded-full"
                          style={{ color: s.color, background: s.bg }}
                        >
                          <span className="w-1.5 h-1.5 rounded-full" style={{ background: s.color }} />
                          {o.status}
                        </span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--text-muted)' }} className="whitespace-nowrap">
                          {o.date}
                        </span>
                      </td>
                      <td className="px-3 py-3.5">
                        <ChevronRight
                          size={14}
                          style={{ color: 'var(--text-muted)', transform: isExpanded ? 'rotate(90deg)' : 'none', transition: 'transform 0.2s ease' }}
                        />
                      </td>
                    </tr>,
                    isExpanded && <ExpandedDetail key={`${o.id}-detail`} order={o} />,
                  ]
                })}
              </tbody>
            </table>
          </div>

          {!loading && filtered.length > 0 && (
            <div
              className="px-5 py-3 flex items-center justify-between"
              style={{ borderTop: '1px solid var(--border)' }}
            >
              <span className="text-[11px]" style={{ color: 'var(--text-muted)' }}>
                Showing {filtered.length} orders {liveData ? '· live data' : ''}
              </span>
              <button
                className="text-[11px] font-semibold flex items-center gap-1 transition-colors duration-150"
                style={{ color: 'var(--primary)' }}
              >
                Export CSV <ArrowUpRight size={11} />
              </button>
            </div>
          )}
        </div>

      </div>
    </AppLayout>
  )
}
