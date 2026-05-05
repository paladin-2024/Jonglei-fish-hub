import { useState, useMemo, useEffect } from 'react'
import AppLayout from '../components/AppLayout'
import {
  ShoppingBag, Search, Filter, TrendingUp,
  ChevronDown, MoreHorizontal, ArrowUpRight, RefreshCw,
} from 'lucide-react'
import api from '../api/axios'

const FALLBACK_ORDERS = [
  { id: 'ORD-0091', fish: 'Nile Perch',          qty: '120 kg', buyer: 'Juba Market',         seller: 'B. Deng (Bor)',       price: 294000, status: 'CONFIRMED',  date: '02 May 2026', route: 'Bor → Juba'       },
  { id: 'ORD-0090', fish: 'Tilapia (Fresh)',      qty: '45 kg',  buyer: 'K. Akol',             seller: 'P. Chol (Panyagoor)', price: 81000,  status: 'IN TRANSIT', date: '02 May 2026', route: 'Panyagoor → Bor'  },
  { id: 'ORD-0089', fish: 'Catfish',              qty: '200 kg', buyer: 'Malakal Cold Store',  seller: 'T. East Traders',     price: 420000, status: 'PENDING',    date: '01 May 2026', route: 'Twic East → Juba' },
  { id: 'ORD-0088', fish: 'Nile Perch (Smoked)',  qty: '300 kg', buyer: 'Upper Nile Co.',      seller: 'B. Deng (Bor)',       price: 960000, status: 'CLEARED',    date: '30 Apr 2026', route: 'Bor → Renk'       },
  { id: 'ORD-0087', fish: 'Lungfish',             qty: '80 kg',  buyer: 'A. Koang',            seller: 'Fangak Hub',          price: 128000, status: 'CLEARED',    date: '29 Apr 2026', route: 'Fangak → Malakal' },
  { id: 'ORD-0086', fish: 'Tilapia (Smoked)',     qty: '60 kg',  buyer: 'Renk Supply Ltd',     seller: 'K. Thon (Renk)',      price: 126000, status: 'FLAGGED',    date: '28 Apr 2026', route: 'Renk → Juba'      },
  { id: 'ORD-0085', fish: 'Nile Perch',           qty: '90 kg',  buyer: 'P. Majok',            seller: 'Bor Fisheries',       price: 220500, status: 'CONFIRMED',  date: '27 Apr 2026', route: 'Bor → Juba'       },
  { id: 'ORD-0084', fish: 'Catfish',              qty: '150 kg', buyer: 'Wau Fish Market',     seller: 'N. Dau (Twic East)',  price: 315000, status: 'IN TRANSIT', date: '26 Apr 2026', route: 'Twic East → Wau'  },
  { id: 'ORD-0083', fish: 'Tilapia (Fresh)',      qty: '30 kg',  buyer: 'G. Awel',             seller: 'Panyagoor Co-op',     price: 54000,  status: 'CLEARED',    date: '25 Apr 2026', route: 'Panyagoor → Bor'  },
  { id: 'ORD-0082', fish: 'Nile Perch (Smoked)',  qty: '180 kg', buyer: 'Torit Distributors',  seller: 'B. Deng (Bor)',       price: 576000, status: 'PENDING',    date: '24 Apr 2026', route: 'Bor → Torit'      },
]

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
    date:   o.created_at ? new Date(o.created_at).toLocaleDateString('en-GB', { day:'2-digit', month:'short', year:'numeric' }) : '—',
    route:  listing.location ? `${listing.location} → ?` : '—',
  }
}

const STATUS_STYLES = {
  CONFIRMED:    { dot: 'bg-green-500',  badge: 'text-green-700 bg-green-50'  },
  'IN TRANSIT': { dot: 'bg-blue-500',   badge: 'text-blue-700 bg-blue-50'    },
  'IN_TRANSIT': { dot: 'bg-blue-500',   badge: 'text-blue-700 bg-blue-50'    },
  PENDING:      { dot: 'bg-amber-500',  badge: 'text-amber-700 bg-amber-50'  },
  CLEARED:      { dot: 'bg-teal-600',   badge: 'text-teal-700 bg-teal-50'    },
  FLAGGED:      { dot: 'bg-red-500',    badge: 'text-red-700 bg-red-50'      },
  CANCELLED:    { dot: 'bg-stone-400',  badge: 'text-stone-500 bg-stone-100' },
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
  return <ChevronDown size={11} className={`inline ml-0.5 transition-transform duration-150 ${dir === 'asc' ? 'rotate-180' : ''}`} />
}

function SkeletonRow() {
  return (
    <tr className="border-b border-stone-50">
      {[...Array(9)].map((_, i) => (
        <td key={i} className="px-5 py-4">
          <div className="h-3 bg-stone-100 rounded animate-pulse" style={{ width: `${50 + (i % 3) * 20}%` }} />
        </td>
      ))}
    </tr>
  )
}

export default function Orders() {
  const [orders, setOrders]           = useState(FALLBACK_ORDERS)
  const [loading, setLoading]         = useState(true)
  const [liveData, setLiveData]       = useState(false)
  const [activeFilter, setActiveFilter] = useState('ALL')
  const [search, setSearch]           = useState('')
  const [sortCol, setSortCol]         = useState('id')
  const [sortDir, setSortDir]         = useState('desc')

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

  // Initial fetch
  useEffect(() => {
    fetchOrders().finally(() => setLoading(false))
  }, [])

  // Polling — only when active orders exist
  const hasActive = orders.some(o => ACTIVE_STATUSES.includes(o.status))
  const [polling, setPolling] = useState(false)

  useEffect(() => {
    if (!hasActive) { setPolling(false); return }
    setPolling(true)
    const id = setInterval(() => { fetchOrders() }, 5000)
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
    { label: 'TOTAL ORDERS',         val: orders.length,                                                                      bar: '#005440' },
    { label: 'CLEARED',              val: orders.filter(o => o.status === 'CLEARED').length,                                  bar: '#1A6B3C' },
    { label: 'IN TRANSIT',           val: orders.filter(o => ['IN TRANSIT','IN_TRANSIT'].includes(o.status)).length,          bar: '#1E5C8A' },
    { label: 'CONF + CLEARED VALUE', val: fmtSSP(orders.filter(o => ['CLEARED','CONFIRMED'].includes(o.status)).reduce((s,o) => s + o.price, 0)), bar: '#B45309' },
  ], [orders])

  function toggleSort(col) {
    if (sortCol === col) setSortDir(d => d === 'asc' ? 'desc' : 'asc')
    else { setSortCol(col); setSortDir('asc') }
  }

  return (
    <AppLayout title="Orders" subtitle="Fish purchase transactions across the platform">
      <div className="max-w-7xl mx-auto space-y-5">

        {/* KPI strip */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          {kpiItems.map((k, i) => (
            <div key={i} className={`bg-white rounded-xl shadow-card overflow-hidden flex flex-col animate-fade-up stagger-${i + 1}`}>
              <div className="h-[3px] w-full flex-shrink-0" style={{ background: k.bar }} />
              <div className="p-4 flex flex-col gap-1.5">
                <p className="text-[10px] font-semibold uppercase tracking-widest text-stone-400">{k.label}</p>
                <span className="font-mono text-2xl font-semibold leading-none text-stone-900">
                  {loading ? <span className="inline-block h-7 w-16 bg-stone-100 rounded animate-pulse" /> : k.val}
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* Toolbar */}
        <div className="bg-white rounded-xl shadow-card p-4 flex flex-col gap-3 animate-fade-up stagger-5">
          <div className="flex items-center gap-3 flex-wrap">
            <div className="relative flex-1 min-w-[200px]">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-400 pointer-events-none" />
              <input
                type="text"
                placeholder="Search order ID, fish, buyer…"
                value={search}
                onChange={e => setSearch(e.target.value)}
                className="w-full pl-9 pr-4 py-2 text-[13px] bg-stone-50 rounded-lg border border-stone-100 focus:outline-none focus:border-teal-700 focus:ring-1 focus:ring-teal-700/20 transition font-sans"
              />
            </div>
            <div className="flex items-center gap-2 text-[12px] text-stone-400">
              <Filter size={12} />
              <span>{filtered.length} of {orders.length} orders</span>
            </div>
            {liveData && (
              <div className="flex items-center gap-1.5 text-[11px] font-semibold text-teal-600 bg-teal-50 px-2.5 py-1 rounded-lg">
                <RefreshCw size={10} strokeWidth={2.5} />
                LIVE
              </div>
            )}
            {polling && (
              <div className="flex items-center gap-1.5 text-[11px] font-semibold text-green-700 bg-green-50 px-2.5 py-1 rounded-lg">
                <span className="relative flex h-2 w-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75" />
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500" />
                </span>
                LIVE
              </div>
            )}
            {filteredRevenue > 0 && (
              <div className="flex items-center gap-1.5 bg-teal-50 text-teal-700 text-[11px] font-semibold px-3 py-1.5 rounded-lg">
                <TrendingUp size={11} strokeWidth={2.5} />
                {fmtSSP(filteredRevenue)}
              </div>
            )}
          </div>

          <div className="flex gap-2 flex-wrap">
            {FILTERS.map(f => (
              <button
                key={f}
                onClick={() => setActiveFilter(f)}
                className={`text-[11px] font-semibold uppercase tracking-wide px-3 py-1.5 rounded-full transition-colors ${
                  activeFilter === f
                    ? 'bg-amber-100 text-amber-700'
                    : 'bg-stone-100 text-stone-500 hover:bg-stone-200'
                }`}
              >
                {f}
              </button>
            ))}
          </div>
        </div>

        {/* Table */}
        <div className="bg-white rounded-xl shadow-card overflow-hidden animate-fade-up stagger-6">
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="border-b border-stone-100">
                  {COLS.map(({ col, label }) => (
                    <th
                      key={col}
                      onClick={() => toggleSort(col)}
                      className="px-5 py-3 text-[10px] font-semibold uppercase tracking-widest text-stone-400 cursor-pointer select-none whitespace-nowrap hover:text-stone-700 transition-colors"
                    >
                      {label}
                      <SortChevron active={sortCol === col} dir={sortDir} />
                    </th>
                  ))}
                  <th className="px-4 py-3 w-10" />
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  [...Array(5)].map((_, i) => <SkeletonRow key={i} />)
                ) : filtered.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="text-center py-16 text-stone-400 text-[13px]">
                      <ShoppingBag size={28} className="mx-auto mb-3 opacity-25" />
                      No orders match this filter
                    </td>
                  </tr>
                ) : filtered.map((o) => {
                  const s = STATUS_STYLES[o.status] ?? STATUS_STYLES.PENDING
                  return (
                    <tr
                      key={o.id}
                      className="border-b border-stone-50 hover:bg-stone-50/70 transition-colors group"
                    >
                      <td className="px-5 py-3.5">
                        <span className="font-mono text-[12px] font-semibold text-teal-700">{o.id}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="text-[13px] font-semibold text-stone-800">{o.fish}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="text-[13px] text-stone-700">{o.buyer}</div>
                        <div className="text-[11px] text-stone-400">{o.seller}</div>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="font-mono text-[12px] text-stone-600">{o.qty}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="font-mono text-[13px] font-semibold text-stone-900">{fmtSSP(o.price)}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="text-[12px] text-stone-500 whitespace-nowrap">{o.route}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className={`inline-flex items-center gap-1.5 text-[11px] font-semibold px-2.5 py-1 rounded-full ${s.badge}`}>
                          <span className={`w-1.5 h-1.5 rounded-full ${s.dot}`} />
                          {o.status}
                        </span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="text-[12px] text-stone-400 whitespace-nowrap">{o.date}</span>
                      </td>
                      <td className="px-4 py-3.5">
                        <button className="opacity-0 group-hover:opacity-100 transition-opacity p-1 rounded-lg hover:bg-stone-100 text-stone-400">
                          <MoreHorizontal size={15} />
                        </button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>

          {!loading && filtered.length > 0 && (
            <div className="border-t border-stone-100 px-5 py-3 flex items-center justify-between">
              <span className="text-[11px] text-stone-400">
                Showing {filtered.length} orders {liveData ? '· live data' : '· sample data'}
              </span>
              <button className="text-[11px] font-semibold text-teal-700 flex items-center gap-1 hover:underline">
                Export CSV <ArrowUpRight size={11} />
              </button>
            </div>
          )}
        </div>

      </div>
    </AppLayout>
  )
}
