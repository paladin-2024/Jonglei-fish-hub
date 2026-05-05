import { useState, useMemo, useEffect } from 'react'
import AppLayout from '../components/AppLayout'
import { Truck, MapPin, Search, Circle, RefreshCw } from 'lucide-react'
import api from '../api/axios'
import ShipmentTrackingMap from '../components/ShipmentTrackingMap'

const STATUS_CFG = {
  'IN TRANSIT': { dot: 'bg-blue-500',   pill: 'bg-blue-50 text-blue-800 ring-blue-100'   },
  'CONFIRMED':  { dot: 'bg-green-500',  pill: 'bg-green-50 text-green-800 ring-green-100' },
  'PENDING':    { dot: 'bg-amber-500',  pill: 'bg-amber-50 text-amber-800 ring-amber-100' },
  'CLEARED':    { dot: 'bg-teal-500',   pill: 'bg-teal-50 text-teal-800 ring-teal-100'   },
  'FLAGGED':    { dot: 'bg-red-500',    pill: 'bg-red-50 text-red-800 ring-red-100'       },
}

const SAMPLE = [
  { id: 'SHP-0041', fish: 'Nile Perch',      origin: 'Bor',       dest: 'Juba',    qty: 120,  price: 294000, status: 'IN TRANSIT', date: '2026-05-14' },
  { id: 'SHP-0040', fish: 'Tilapia (Fresh)', origin: 'Panyagoor', dest: 'Bor',     qty: 45,   price: 81000,  status: 'CONFIRMED',  date: '2026-05-13' },
  { id: 'SHP-0039', fish: 'Catfish',         origin: 'Twic East', dest: 'Juba',    qty: 200,  price: 240000, status: 'PENDING',    date: '2026-05-13' },
  { id: 'SHP-0038', fish: 'Nile Perch (Smoked)', origin: 'Bor',   dest: 'Renk',   qty: 300,  price: 960000, status: 'CLEARED',    date: '2026-05-12' },
  { id: 'SHP-0037', fish: 'Lungfish',        origin: 'Fangak',    dest: 'Malakal', qty: 80,   price: 128000, status: 'CLEARED',    date: '2026-05-10' },
  { id: 'SHP-0036', fish: 'Tilapia',         origin: 'Bor',       dest: 'Wau',     qty: 60,   price: 108000, status: 'FLAGGED',    date: '2026-05-09' },
  { id: 'SHP-0035', fish: 'Nile Perch',      origin: 'Malakal',   dest: 'Renk',    qty: 150,  price: 525000, status: 'IN TRANSIT', date: '2026-05-08' },
  { id: 'SHP-0034', fish: 'Catfish',         origin: 'Pibor',     dest: 'Juba',    qty: 90,   price: 171000, status: 'CONFIRMED',  date: '2026-05-07' },
]

const STATUSES = ['ALL', 'IN TRANSIT', 'CONFIRMED', 'PENDING', 'CLEARED', 'FLAGGED']

const fmtSSP = (n) => `SSP ${n.toLocaleString()}`

function normalizeShipment(j) {
  const order = j.order_detail ?? j.order ?? {}
  const listing = order.listing_detail ?? order.listing ?? {}
  return {
    id:     j.id?.toString().toUpperCase().slice(0, 12) ?? j.id,
    fish:   listing.species ?? j.cargo ?? '—',
    origin: j.origin ?? j.pickup_location ?? '—',
    dest:   j.destination ?? j.delivery_location ?? '—',
    qty:    Number(j.quantity_kg ?? order.quantity_kg ?? 0),
    price:  Number(j.total_price ?? order.total_price ?? 0),
    status: (j.status ?? 'PENDING').replace('_', ' ').toUpperCase(),
    date:   j.created_at
      ? new Date(j.created_at).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
      : j.date ?? '—',
  }
}

function SkeletonRow() {
  return (
    <tr className="border-b border-stone-50">
      {[...Array(7)].map((_, i) => (
        <td key={i} className="px-5 py-4">
          <div className="h-3 bg-stone-100 rounded animate-pulse" style={{ width: `${50 + (i % 3) * 20}%` }} />
        </td>
      ))}
    </tr>
  )
}

export default function Shipments() {
  const [shipments, setShipments]     = useState(SAMPLE)
  const [loading, setLoading]         = useState(true)
  const [isLive, setIsLive]           = useState(false)
  const [statusFilter, setStatusFilter] = useState('ALL')
  const [search, setSearch]           = useState('')

  useEffect(() => {
    api.get('/transport/shipments/')
      .then(r => {
        const raw = Array.isArray(r.data) ? r.data : (r.data?.results ?? [])
        if (raw.length > 0) {
          setShipments(raw.map(normalizeShipment))
          setIsLive(true)
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const filtered = useMemo(() => {
    const q = search.toLowerCase()
    return shipments.filter(s => {
      const matchStatus = statusFilter === 'ALL' || s.status === statusFilter
      const matchSearch = !q ||
        s.id.toLowerCase().includes(q) ||
        s.fish.toLowerCase().includes(q) ||
        s.origin.toLowerCase().includes(q) ||
        s.dest.toLowerCase().includes(q)
      return matchStatus && matchSearch
    })
  }, [shipments, statusFilter, search])

  return (
    <AppLayout title="Shipments" subtitle="Fish transport routes and delivery tracking">
      <div className="max-w-[1200px] mx-auto space-y-5">

        {/* Filter bar */}
        <div className="flex flex-wrap items-center gap-3 animate-fade-up">
          {/* Status pills */}
          <div className="flex items-center gap-1.5 flex-wrap">
            {STATUSES.map(s => {
              const active = statusFilter === s
              const cfg = STATUS_CFG[s]
              return (
                <button
                  key={s}
                  onClick={() => setStatusFilter(s)}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-[11px] font-bold
                              uppercase tracking-wide transition-all duration-200 ease-spring outline-none
                              focus-visible:ring-2 focus-visible:ring-teal-400
                              ${active
                                ? 'bg-teal-700 text-white shadow-md'
                                : 'bg-white text-stone-500 border border-stone-200 hover:border-teal-300 hover:text-teal-700'
                              }`}
                >
                  {s !== 'ALL' && cfg && (
                    <span className={`w-1.5 h-1.5 rounded-full ${active ? 'bg-white/60' : cfg.dot}`} />
                  )}
                  {s}
                </button>
              )
            })}
          </div>

          {/* Search */}
          <div className="flex-1 min-w-[200px] relative">
            <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-400" />
            <input
              type="text"
              placeholder="Search ID, fish, city…"
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-8 pr-3 py-2 text-[13px] bg-white border border-stone-200 rounded-xl
                         focus:outline-none focus:border-teal-400 transition-colors placeholder-stone-400"
            />
          </div>
        </div>

        {/* Table */}
        <div className="bg-white rounded-xl shadow-card overflow-hidden animate-fade-up stagger-1">
          <div className="h-[3px]" style={{ background: '#1E5C8A' }} />

          <div className="px-5 py-3.5 border-b border-stone-100 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Truck size={14} className="text-stone-400" strokeWidth={1.75} />
              <p className="text-[11px] font-bold uppercase tracking-widest text-stone-400">
                Shipment ledger
              </p>
              {isLive && (
                <div className="flex items-center gap-1.5 text-[11px] font-semibold text-teal-600 bg-teal-50 px-2.5 py-1 rounded-lg ml-2">
                  <RefreshCw size={10} strokeWidth={2.5} />
                  LIVE
                </div>
              )}
            </div>
            <span className="font-mono text-[11px] text-stone-400">
              <span className="font-semibold text-stone-700">{filtered.length}</span> records
              {isLive ? ' · live data' : ' · sample data'}
            </span>
          </div>

          {loading ? (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[700px]">
                <thead>
                  <tr className="border-b border-stone-50 bg-stone-50/60">
                    {['Shipment ID', 'Fish', 'Route', 'Quantity', 'Value', 'Status', 'Date'].map(h => (
                      <th key={h} className="text-left px-5 py-3 text-[10px] font-bold uppercase tracking-widest text-stone-400">
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {[...Array(5)].map((_, i) => <SkeletonRow key={i} />)}
                </tbody>
              </table>
            </div>
          ) : filtered.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-stone-300">
              <Truck size={28} className="mb-3" strokeWidth={1.5} />
              <p className="text-[13px] text-stone-400 font-medium">No shipments match your filters</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[700px]">
                <thead>
                  <tr className="border-b border-stone-50 bg-stone-50/60">
                    {['Shipment ID', 'Fish', 'Route', 'Quantity', 'Value', 'Status', 'Date'].map(h => (
                      <th key={h} className="text-left px-5 py-3 text-[10px] font-bold uppercase tracking-widest text-stone-400">
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((s, i) => {
                    const cfg = STATUS_CFG[s.status] ?? STATUS_CFG['PENDING']
                    return (
                      <tr
                        key={s.id}
                        className={`group hover:bg-teal-50/30 transition-colors
                                    ${i < filtered.length - 1 ? 'border-b border-stone-50' : ''}`}
                        style={{ animationDelay: `${i * 40}ms` }}
                      >
                        <td className="px-5 py-3.5">
                          <span className="font-mono text-[12px] font-semibold text-stone-800">{s.id}</span>
                        </td>
                        <td className="px-5 py-3.5">
                          <span className="text-[13px] font-semibold text-stone-800">{s.fish}</span>
                        </td>
                        <td className="px-5 py-3.5">
                          <div className="flex items-center gap-1.5 text-[12px] text-stone-500">
                            <MapPin size={11} className="text-teal-500 flex-shrink-0" />
                            <span>{s.origin}</span>
                            <span className="text-stone-300">→</span>
                            <span>{s.dest}</span>
                          </div>
                        </td>
                        <td className="px-5 py-3.5">
                          <span className="font-mono text-[12px] text-stone-700">{s.qty} kg</span>
                        </td>
                        <td className="px-5 py-3.5">
                          <span className="font-mono text-[12px] font-semibold text-stone-800">
                            {fmtSSP(s.price)}
                          </span>
                        </td>
                        <td className="px-5 py-3.5">
                          <span className={`inline-flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wide px-2.5 py-1 rounded-lg ring-1 ${cfg.pill}`}>
                            <span className={`w-1.5 h-1.5 rounded-full ${cfg.dot}`} />
                            {s.status}
                          </span>
                        </td>
                        <td className="px-5 py-3.5">
                          <span className="font-mono text-[11px] text-stone-400">{s.date}</span>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Live tracking map */}
        <div className="bg-white rounded-xl shadow-card overflow-hidden animate-fade-up stagger-2">
          <div className="h-[3px]" style={{ background: '#1E5C8A' }} />
          <div className="px-5 py-3.5 border-b border-stone-100 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <MapPin size={14} className="text-stone-400" strokeWidth={1.75} />
              <p className="text-[11px] font-bold uppercase tracking-widest text-stone-400">
                Live route tracking
              </p>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75" />
                <span className="relative inline-flex rounded-full h-2 w-2 bg-blue-500" />
              </span>
              <span className="text-[10px] font-mono text-stone-400">
                {filtered.filter(s => s.status === 'IN TRANSIT').length} in motion
              </span>
            </div>
          </div>
          <div className="h-[480px]">
            <ShipmentTrackingMap shipments={filtered} />
          </div>
        </div>

      </div>
    </AppLayout>
  )
}
