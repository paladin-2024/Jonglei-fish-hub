import { useState, useMemo, useEffect, useRef } from 'react'
import AppLayout from '../components/AppLayout'
import { Truck, MapPin, Search, ArrowRight, Map, X } from 'lucide-react'
import api from '../api/axios'
import ShipmentTrackingMap from '../components/ShipmentTrackingMap'

const CARD_S = {
  background: 'var(--bg-elevated)',
  border: '1px solid var(--border)',
  borderRadius: 'var(--radius)',
}

const STATUS_CFG = {
  'IN TRANSIT': { color: '#60A5FA', bg: 'rgba(96,165,250,0.12)',   step: 2 },
  'CONFIRMED':  { color: '#0AB5A3', bg: 'rgba(10,181,163,0.12)',  step: 1 },
  'PENDING':    { color: '#F59E0B', bg: 'rgba(245,158,11,0.12)',   step: 0 },
  'CLEARED':    { color: '#10B981', bg: 'rgba(16,185,129,0.12)',   step: 4 },
  'FLAGGED':    { color: '#EF4444', bg: 'rgba(239,68,68,0.12)',    step: -1 },
}

const STEPS = ['Booked', 'Confirmed', 'In Transit', 'At Border', 'Cleared']


const STATUSES = ['ALL', 'IN TRANSIT', 'CONFIRMED', 'PENDING', 'CLEARED', 'FLAGGED']

const fmtSSP = (n) => `SSP ${n.toLocaleString()}`

function normalizeShipment(j) {
  const order = j.order_detail ?? j.order ?? {}
  const listing = order.listing_detail ?? order.listing ?? {}
  return {
    id:          j.id?.toString().toUpperCase().slice(0, 12) ?? j.id,
    fish:        listing.species ?? j.cargo ?? '—',
    origin:      j.origin ?? j.pickup_location ?? '—',
    dest:        j.destination ?? j.delivery_location ?? '—',
    qty:         Number(j.quantity_kg ?? order.quantity_kg ?? 0),
    price:       Number(j.total_price ?? order.total_price ?? 0),
    status:      (j.status ?? 'PENDING').replace('_', ' ').toUpperCase(),
    date:        j.created_at
      ? new Date(j.created_at).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
      : '—',
    transporter: j.transporter_detail?.username ?? '—',
  }
}

function ProgressStepper({ status }) {
  const cfg = STATUS_CFG[status] ?? STATUS_CFG['PENDING']
  const step = cfg.step

  if (step < 0) {
    return (
      <div className="flex items-center gap-2">
        <span className="w-2 h-2 rounded-full" style={{ background: cfg.color }} />
        <span className="text-[11px] font-bold" style={{ color: cfg.color, fontFamily: 'JetBrains Mono' }}>
          FLAGGED
        </span>
      </div>
    )
  }

  return (
    <div className="flex items-center gap-1 w-full">
      {STEPS.map((label, i) => {
        const done   = i <= step
        const active = i === step
        return (
          <div key={label} className="flex items-center flex-1 min-w-0">
            <div className="flex flex-col items-center gap-1" style={{ minWidth: 0 }}>
              <div
                className="w-2 h-2 rounded-full flex-shrink-0 transition-all duration-300"
                style={{
                  background: done ? cfg.color : 'var(--bg-glass)',
                  border: `1px solid ${done ? cfg.color : 'var(--border)'}`,
                  boxShadow: active ? `0 0 8px ${cfg.color}60` : 'none',
                }}
              />
              <span
                className="text-[9px] whitespace-nowrap truncate"
                style={{ color: done ? cfg.color : 'var(--text-muted)', fontFamily: 'JetBrains Mono' }}
              >
                {label}
              </span>
            </div>
            {i < STEPS.length - 1 && (
              <div
                className="flex-1 h-[1px] mx-0.5 mb-3 transition-all duration-300"
                style={{ background: i < step ? cfg.color : 'var(--border)' }}
              />
            )}
          </div>
        )
      })}
    </div>
  )
}

function ShipmentCard({ s, delay = 0 }) {
  const cfg = STATUS_CFG[s.status] ?? STATUS_CFG['PENDING']
  return (
    <div
      className="p-5 flex flex-col gap-4 transition-all duration-200 hover-glow animate-fade-up"
      style={{ ...CARD_S, animationDelay: `${delay}ms` }}
    >
      {/* Header row */}
      <div className="flex items-start justify-between gap-3">
        <div>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--text-muted)' }}>{s.id}</span>
          <p className="text-[15px] font-semibold mt-0.5" style={{ color: 'var(--text-primary)' }}>{s.fish}</p>
          <p className="text-[12px] mt-0.5" style={{ color: 'var(--text-muted)' }}>{s.transporter}</p>
        </div>
        <span
          className="text-[10px] font-bold uppercase tracking-wide px-2.5 py-1 rounded-full flex-shrink-0 flex items-center gap-1.5"
          style={{ color: cfg.color, background: cfg.bg }}
        >
          <span className="w-1.5 h-1.5 rounded-full" style={{ background: cfg.color }} />
          {s.status}
        </span>
      </div>

      {/* Route */}
      <div className="flex items-center gap-2">
        <div
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg"
          style={{ background: 'var(--bg-glass)', border: '1px solid var(--border)' }}
        >
          <MapPin size={11} style={{ color: 'var(--secondary)' }} />
          <span className="text-[12px] font-semibold" style={{ color: 'var(--text-primary)' }}>{s.origin}</span>
        </div>
        <ArrowRight size={14} style={{ color: 'var(--text-muted)', flexShrink: 0 }} />
        <div
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg"
          style={{ background: 'var(--bg-glass)', border: '1px solid var(--border)' }}
        >
          <MapPin size={11} style={{ color: 'var(--primary)' }} />
          <span className="text-[12px] font-semibold" style={{ color: 'var(--text-primary)' }}>{s.dest}</span>
        </div>
      </div>

      {/* Progress stepper */}
      <ProgressStepper status={s.status} />

      {/* Footer */}
      <div className="flex items-center justify-between pt-1" style={{ borderTop: '1px solid var(--border)' }}>
        <div>
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: 600, color: 'var(--primary)' }}>
            {fmtSSP(s.price)}
          </span>
          <span className="ml-2 text-[11px]" style={{ color: 'var(--text-muted)', fontFamily: 'JetBrains Mono' }}>
            · {s.qty} kg
          </span>
        </div>
        <div className="flex items-center gap-2">
          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--text-muted)' }}>
            {s.date}
          </span>
          <button
            className="flex items-center gap-1.5 text-[11px] font-semibold px-2.5 py-1.5 rounded-lg transition-all duration-200"
            style={{ background: 'var(--secondary-glow)', color: 'var(--secondary)', border: '1px solid rgba(10,181,163,0.2)' }}
            onClick={() => {
              setTrackingId(s.id)
              setTimeout(() => mapRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' }), 50)
            }}
          >
            <Map size={11} />
            Track
          </button>
        </div>
      </div>
    </div>
  )
}

export default function Shipments() {
  const [shipments, setShipments]      = useState([])
  const [loading, setLoading]          = useState(true)
  const [isLive, setIsLive]            = useState(false)
  const [statusFilter, setStatusFilter]= useState('ALL')
  const [search, setSearch]            = useState('')
  const [trackingId, setTrackingId]    = useState(null)
  const mapRef                         = useRef(null)

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

  const inTransitCount = filtered.filter(s => s.status === 'IN TRANSIT').length

  return (
    <AppLayout title="Shipments" subtitle="Fish transport routes and delivery tracking">
      <div className="max-w-[1280px] mx-auto space-y-5">

        {/* Toolbar row */}
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
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-[11px] font-bold
                              uppercase tracking-wide transition-all duration-200 outline-none"
                  style={{
                    background: active
                      ? (s === 'ALL' ? 'var(--primary)' : cfg?.bg ?? 'var(--primary-glow)')
                      : 'var(--bg-glass)',
                    color: active
                      ? (s === 'ALL' ? 'var(--bg-deep)' : cfg?.color ?? 'var(--primary)')
                      : 'var(--text-muted)',
                    border: `1px solid ${active ? 'transparent' : 'var(--border)'}`,
                  }}
                >
                  {s !== 'ALL' && cfg && (
                    <span
                      className="w-1.5 h-1.5 rounded-full flex-shrink-0"
                      style={{ background: active ? 'currentColor' : cfg.color }}
                    />
                  )}
                  {s}
                </button>
              )
            })}
          </div>

          {/* Search */}
          <div className="flex-1 min-w-[200px] relative">
            <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" style={{ color: 'var(--text-muted)' }} />
            <input
              type="text"
              placeholder="Search ID, fish, city…"
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-8 pr-3 py-2 text-[13px] rounded-xl outline-none transition-all duration-200"
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

          {isLive && (
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

          <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--text-muted)' }}>
            {filtered.length} shipments · {inTransitCount} in motion
          </span>
        </div>

        {/* Cards grid */}
        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="p-5 flex flex-col gap-4" style={CARD_S}>
                <div className="shimmer h-5 w-24 rounded" />
                <div className="shimmer h-8 w-40 rounded" />
                <div className="shimmer h-6 w-full rounded" />
                <div className="shimmer h-4 w-full rounded" />
              </div>
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div
            className="flex flex-col items-center justify-center py-20"
            style={{ ...CARD_S, color: 'var(--text-muted)' }}
          >
            <Truck size={28} className="mb-3 opacity-40" strokeWidth={1.5} />
            <p className="text-[13px] font-medium">No shipments match your filters</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            {filtered.map((s, i) => (
              <ShipmentCard key={s.id} s={s} delay={i * 40} />
            ))}
          </div>
        )}

        {/* Map section */}
        <div ref={mapRef} className="overflow-hidden animate-fade-up stagger-3" style={CARD_S}>
          <div
            className="px-5 py-4 flex items-center justify-between"
            style={{ borderBottom: '1px solid var(--border)' }}
          >
            <div className="flex items-center gap-2">
              <MapPin size={14} style={{ color: 'var(--text-muted)' }} strokeWidth={1.75} />
              <p className="text-[11px] font-bold uppercase tracking-widest" style={{ color: 'var(--text-muted)' }}>
                {trackingId ? 'Tracking Shipment' : 'Live Route Tracking'}
              </p>
              {trackingId && (
                <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--secondary)', fontWeight: 700 }}>
                  #{trackingId.slice(-6)}
                </span>
              )}
            </div>
            <div className="flex items-center gap-2">
              {trackingId ? (
                <button
                  onClick={() => setTrackingId(null)}
                  className="flex items-center gap-1 text-[10px] font-semibold px-2 py-1 rounded-lg transition-all"
                  style={{ background: 'var(--bg-glass)', color: 'var(--text-muted)', border: '1px solid var(--border)' }}
                >
                  <X size={10} /> Clear
                </button>
              ) : (
                <div className="flex items-center gap-1.5">
                  <span className="relative flex h-2 w-2">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full opacity-75" style={{ background: '#60A5FA' }} />
                    <span className="relative inline-flex rounded-full h-2 w-2" style={{ background: '#60A5FA' }} />
                  </span>
                  <span style={{ fontFamily: 'JetBrains Mono', fontSize: 10, color: 'var(--text-muted)' }}>
                    {inTransitCount} in motion
                  </span>
                </div>
              )}
            </div>
          </div>
          <div className="h-[420px]">
            <ShipmentTrackingMap
              shipments={trackingId ? filtered.filter(s => s.id === trackingId) : filtered}
            />
          </div>
        </div>

      </div>
    </AppLayout>
  )
}
