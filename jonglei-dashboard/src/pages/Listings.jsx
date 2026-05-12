import { useState, useMemo, useEffect } from 'react'
import AppLayout from '../components/AppLayout'
import {
  Fish, Search, Filter, TrendingUp,
  ChevronDown, X, Eye, Trash2, Star,
  MapPin, Package, Calendar, ArrowUpRight,
} from 'lucide-react'
import api from '../api/axios'

const CARD_S = {
  background: 'var(--bg-elevated)',
  border: '1px solid var(--border)',
  borderRadius: 'var(--radius)',
}

function normalizeListing(l) {
  const seller = l.seller_detail ?? l.seller ?? {}
  return {
    id:           l.id?.toString().toUpperCase().slice(-8) ?? l.id,
    fish:         l.species ?? '—',
    seller:       typeof seller === 'object' ? (seller.username ?? seller.phone_number ?? '—') : seller,
    location:     l.location ?? '—',
    qty:          Number(l.quantity_kg ?? 0),
    price:        Number(l.price_ssp ?? 0),
    unit:         l.unit ?? 'KG',
    status:       l.status ?? 'DRAFT',
    date:         l.created_at
      ? new Date(l.created_at).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
      : '—',
    photo:        l.photo_url || null,
    avg_rating:   typeof seller === 'object' ? (seller.avg_rating ?? 0) : 0,
    rating_count: typeof seller === 'object' ? (seller.rating_count ?? 0) : 0,
  }
}

const STATUS_STYLES = {
  ACTIVE:  { color: 'var(--primary)',    bg: 'var(--primary-glow)'        },
  DRAFT:   { color: 'var(--secondary)',  bg: 'rgba(245,158,11,0.12)'      },
  SOLD:    { color: 'var(--text-muted)', bg: 'rgba(71,85,105,0.18)'       },
  REMOVED: { color: 'var(--danger)',     bg: 'rgba(239,68,68,0.12)'       },
}

const FILTERS = ['ALL', 'ACTIVE', 'DRAFT', 'SOLD', 'REMOVED']

const COLS = [
  { col: 'id',       label: 'LISTING ID' },
  { col: 'fish',     label: 'SPECIES'    },
  { col: 'seller',   label: 'SELLER'     },
  { col: 'location', label: 'LOCATION'   },
  { col: 'qty',      label: 'QTY'        },
  { col: 'price',    label: 'PRICE / KG' },
  { col: 'status',   label: 'STATUS'     },
  { col: 'date',     label: 'LISTED'     },
]

const SPECIES_COLORS = {
  'Nile Perch': '#0F766E',
  'Tilapia':    '#1E5C8A',
  'Catfish':    '#6B4226',
  'Lungfish':   '#4A7C59',
  'Smoked':     '#92400E',
}

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

function SpeciesAvatar({ species, photo }) {
  if (photo) {
    return (
      <img
        src={photo}
        className="w-9 h-9 rounded-lg object-cover flex-shrink-0"
        alt=""
      />
    )
  }
  const key = Object.keys(SPECIES_COLORS).find(k => species.includes(k)) ?? 'Nile Perch'
  const color = SPECIES_COLORS[key]
  return (
    <div
      className="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0 text-[12px] font-bold"
      style={{ background: color + '22', color }}
    >
      {species[0]}
    </div>
  )
}

function StarRating({ value, count }) {
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map(i => (
        <span
          key={i}
          style={{
            color: i <= Math.round(value || 0) ? '#F59E0B' : 'var(--border)',
            fontSize: 11,
            lineHeight: 1,
          }}
        >
          ★
        </span>
      ))}
      <span style={{ color: 'var(--text-muted)', fontSize: 10, marginLeft: 3 }}>
        ({count || 0})
      </span>
    </div>
  )
}

function DetailPanel({ listing, onClose, onRefresh }) {
  if (!listing) return null
  const s = STATUS_STYLES[listing.status] ?? STATUS_STYLES.DRAFT
  const totalValue = listing.qty * listing.price
  const [acting, setActing] = useState(null)

  async function doAction(action) {
    setActing(action)
    try {
      await api.post(`/marketplace/listings/${listing.id}/${action}/`)
      onRefresh()
      onClose()
    } catch { /* silently ignore */ }
    finally { setActing(null) }
  }

  return (
    <div className="fixed inset-0 z-40 flex justify-end" onClick={onClose}>
      <div
        className="absolute inset-0"
        style={{ background: 'rgba(6,12,24,0.7)', backdropFilter: 'blur(4px)' }}
      />
      <aside
        className="relative w-[360px] h-full flex flex-col overflow-y-auto animate-slide-left"
        style={{
          background: 'var(--bg-elevated)',
          borderLeft: '1px solid var(--border)',
          boxShadow: '-24px 0 60px rgba(0,0,0,0.4)',
        }}
        onClick={e => e.stopPropagation()}
      >
        {/* Top accent bar */}
        <div
          className="h-[3px] w-full flex-shrink-0"
          style={{ background: 'var(--primary)' }}
        />

        <div className="flex items-start justify-between p-5 pb-4">
          <div>
            <p
              className="text-[10px] font-semibold uppercase tracking-widest mb-1"
              style={{ color: 'var(--text-muted)' }}
            >
              Listing Detail
            </p>
            <h2
              className="text-[20px] leading-tight"
              style={{ fontFamily: "'DM Serif Display', serif", color: 'var(--text-primary)' }}
            >
              {listing.fish}
            </h2>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg transition-colors mt-0.5"
            style={{ color: 'var(--text-muted)' }}
            onMouseEnter={e => e.currentTarget.style.background = 'var(--bg-glass)'}
            onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
          >
            <X size={15} />
          </button>
        </div>

        <div className="px-5 space-y-5 pb-8">
          {/* Status badge */}
          <span
            className="inline-flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wide px-2.5 py-1 rounded-full"
            style={{ color: s.color, background: s.bg }}
          >
            <span className="w-1.5 h-1.5 rounded-full" style={{ background: s.color }} />
            {listing.status}
          </span>

          {/* Key metrics grid */}
          <div className="grid grid-cols-2 gap-3">
            {[
              { label: 'QTY',          val: `${listing.qty} ${listing.unit}`, Icon: Package },
              { label: 'PRICE / KG',   val: fmtSSP(listing.price),           Icon: TrendingUp },
              { label: 'TOTAL VALUE',  val: fmtSSP(totalValue),               Icon: Star },
              { label: 'LOCATION',     val: listing.location,                 Icon: MapPin },
            ].map(({ label, val, Icon }) => (
              <div
                key={label}
                className="rounded-xl p-3"
                style={{ background: 'var(--bg-base)', border: '1px solid var(--border)' }}
              >
                <div className="flex items-center gap-1.5 mb-2">
                  <Icon size={11} style={{ color: 'var(--text-muted)' }} />
                  <span
                    className="text-[9px] font-semibold uppercase tracking-widest"
                    style={{ color: 'var(--text-muted)' }}
                  >
                    {label}
                  </span>
                </div>
                <span
                  className="text-[13px] font-semibold"
                  style={{ fontFamily: 'JetBrains Mono', color: 'var(--text-primary)' }}
                >
                  {val}
                </span>
              </div>
            ))}
          </div>

          {/* Seller block */}
          <div
            className="rounded-xl p-4 space-y-2.5"
            style={{ background: 'var(--bg-base)', border: '1px solid var(--border)' }}
          >
            {[
              { label: 'Seller', val: <span style={{ color: 'var(--text-primary)', fontWeight: 600 }}>{listing.seller}</span> },
              { label: 'Rating', val: <StarRating value={listing.avg_rating} count={listing.rating_count} /> },
              {
                label: 'Listed',
                val: <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--text-secondary)' }}>{listing.date}</span>,
              },
              {
                label: 'ID',
                val: <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--primary)', fontWeight: 600 }}>{listing.id}</span>,
              },
            ].map(({ label, val }) => (
              <div key={label} className="flex items-center justify-between">
                <span className="text-[11px]" style={{ color: 'var(--text-muted)' }}>{label}</span>
                {val}
              </div>
            ))}
          </div>

          {/* Actions */}
          <div className="space-y-2 pt-1">
            {listing.status === 'DRAFT' && (
              <button
                onClick={() => doAction('publish')}
                disabled={!!acting}
                className="w-full py-3 text-[12px] font-bold rounded-xl transition-all duration-200 disabled:opacity-60"
                style={{ background: 'var(--primary)', color: 'var(--bg-deep)' }}
              >
                {acting === 'publish' ? 'Publishing…' : 'Publish Listing'}
              </button>
            )}
            {listing.status !== 'REMOVED' && (
              <button
                onClick={() => doAction('remove')}
                disabled={!!acting}
                className="w-full flex items-center justify-center gap-2 py-3 text-[12px] font-bold rounded-xl transition-all duration-200 disabled:opacity-60"
                style={{ background: 'rgba(239,68,68,0.1)', color: 'var(--danger)', border: '1px solid rgba(239,68,68,0.2)' }}
              >
                <Trash2 size={13} />
                {acting === 'remove' ? 'Removing…' : 'Remove Listing'}
              </button>
            )}
          </div>
        </div>
      </aside>
    </div>
  )
}

export default function Listings() {
  const [listings, setListings]         = useState([])
  const [loading, setLoading]           = useState(true)
  const [liveData, setLiveData]         = useState(false)
  const [activeFilter, setActiveFilter] = useState('ALL')
  const [search, setSearch]             = useState('')
  const [sortCol, setSortCol]           = useState('date')
  const [sortDir, setSortDir]           = useState('desc')
  const [selected, setSelected]         = useState(null)

  function fetchListings() {
    api.get('/marketplace/listings/')
      .then(r => {
        const raw = Array.isArray(r.data) ? r.data : (r.data?.results ?? [])
        if (raw.length > 0) {
          setListings(raw.map(normalizeListing))
          setLiveData(true)
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchListings() }, [])

  function exportCSV() {
    const cols = ['ID', 'Species', 'Seller', 'Qty (kg)', 'Price (SSP)', 'Unit', 'Location', 'Status', 'Date']
    const rows = filtered.map(l => [l.id, l.fish, l.seller, l.qty, l.price, l.unit ?? 'KG', l.location, l.status, l.date])
    const csv = [cols, ...rows].map(r => r.map(v => `"${v ?? ''}"`).join(',')).join('\n')
    const a = document.createElement('a')
    a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }))
    a.download = `listings-${new Date().toISOString().slice(0, 10)}.csv`
    a.click()
  }

  const filtered = useMemo(() => {
    const q = search.toLowerCase()
    return listings
      .filter(l => activeFilter === 'ALL' || l.status === activeFilter)
      .filter(l => !q || [l.id, l.fish, l.seller, l.location].some(v => String(v).toLowerCase().includes(q)))
      .sort((a, b) => {
        const av = a[sortCol], bv = b[sortCol]
        if (typeof av === 'number') return sortDir === 'asc' ? av - bv : bv - av
        return sortDir === 'asc'
          ? String(av).localeCompare(String(bv))
          : String(bv).localeCompare(String(av))
      })
  }, [listings, activeFilter, search, sortCol, sortDir])

  const activeValue = useMemo(
    () => listings.filter(l => l.status === 'ACTIVE').reduce((s, l) => s + l.qty * l.price, 0),
    [listings]
  )

  const kpiItems = useMemo(() => [
    { label: 'TOTAL LISTINGS', val: listings.length,                                    color: 'var(--primary)'   },
    { label: 'ACTIVE',         val: listings.filter(l => l.status === 'ACTIVE').length, color: 'var(--success)'   },
    { label: 'SOLD OUT',       val: listings.filter(l => l.status === 'SOLD').length,   color: 'var(--text-muted)'},
    {
      label: 'ACTIVE VALUE',
      val: 'SSP ' + listings
        .filter(l => l.status === 'ACTIVE')
        .reduce((s, l) => s + l.qty * l.price, 0)
        .toLocaleString(),
      color: 'var(--secondary)',
    },
  ], [listings])

  function toggleSort(col) {
    if (sortCol === col) setSortDir(d => d === 'asc' ? 'desc' : 'asc')
    else { setSortCol(col); setSortDir('desc') }
  }

  return (
    <AppLayout title="Listings" subtitle="Fish listings posted by traders across the platform">
      <div className="max-w-[1280px] mx-auto space-y-5">

        {/* KPI strip */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          {kpiItems.map((k, i) => (
            <div
              key={i}
              className={`overflow-hidden flex flex-col animate-fade-up stagger-${i + 1}`}
              style={CARD_S}
            >
              <div
                className="h-[3px] w-full flex-shrink-0"
                style={{ background: k.color }}
              />
              <div className="p-4 flex flex-col gap-1.5">
                <p
                  className="text-[10px] font-semibold uppercase tracking-widest"
                  style={{ color: 'var(--text-muted)' }}
                >
                  {k.label}
                </p>
                <span
                  className="text-[24px] font-semibold leading-none"
                  style={{ fontFamily: 'JetBrains Mono', color: k.color }}
                >
                  {loading
                    ? <span className="shimmer inline-block h-7 w-16 rounded-lg" />
                    : k.val}
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* Toolbar */}
        <div
          className="p-4 flex flex-col gap-3 animate-fade-up stagger-5"
          style={CARD_S}
        >
          <div className="flex items-center gap-3 flex-wrap">
            <div className="relative flex-1 min-w-[200px]">
              <Search
                size={14}
                className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"
                style={{ color: 'var(--text-muted)' }}
              />
              <input
                type="text"
                placeholder="Search species, seller, location…"
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
              <span>{filtered.length} of {listings.length} listings</span>
            </div>
            {liveData && (
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
            {activeValue > 0 && (
              <div
                className="flex items-center gap-1.5 text-[11px] font-semibold px-3 py-1.5 rounded-lg"
                style={{ background: 'var(--primary-glow)', color: 'var(--primary)' }}
              >
                <TrendingUp size={11} strokeWidth={2.5} />
                {fmtSSP(activeValue)} active
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
                      ? (f === 'ALL' ? 'var(--primary)' : (st?.bg ?? 'var(--primary-glow)'))
                      : 'var(--bg-glass)',
                    color: isActive
                      ? (f === 'ALL' ? 'var(--bg-deep)' : (st?.color ?? 'var(--primary)'))
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
        <div
          className="overflow-hidden animate-fade-up stagger-6"
          style={CARD_S}
        >
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
                  <th className="px-4 py-3 w-10" />
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  [...Array(6)].map((_, i) => (
                    <tr key={i} style={{ borderBottom: '1px solid var(--border)' }}>
                      {[...Array(9)].map((_, j) => (
                        <td key={j} className="px-5 py-4">
                          <div className="shimmer h-3 rounded" style={{ width: `${50 + (j % 3) * 20}%` }} />
                        </td>
                      ))}
                    </tr>
                  ))
                ) : filtered.length === 0 ? (
                  <tr>
                    <td
                      colSpan={9}
                      className="text-center py-16 text-[13px]"
                      style={{ color: 'var(--text-muted)' }}
                    >
                      <Fish size={28} className="mx-auto mb-3 opacity-30" />
                      {listings.length === 0 ? 'No listings yet' : 'No listings match this filter'}
                    </td>
                  </tr>
                ) : filtered.map(l => {
                  const s = STATUS_STYLES[l.status] ?? STATUS_STYLES.DRAFT
                  const isSelected = selected?.id === l.id
                  return (
                    <tr
                      key={l.id}
                      onClick={() => setSelected(isSelected ? null : l)}
                      className="cursor-pointer transition-all duration-150 group"
                      style={{
                        borderBottom: '1px solid var(--border)',
                        background: isSelected ? 'var(--primary-glow)' : 'transparent',
                      }}
                      onMouseEnter={e => { if (!isSelected) e.currentTarget.style.background = 'rgba(255,255,255,0.03)' }}
                      onMouseLeave={e => { if (!isSelected) e.currentTarget.style.background = 'transparent' }}
                    >
                      <td className="px-5 py-3.5">
                        <span
                          style={{ fontFamily: 'JetBrains Mono', fontSize: 12, color: 'var(--primary)', fontWeight: 600 }}
                        >
                          {l.id}
                        </span>
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-2.5">
                          <SpeciesAvatar species={l.fish} photo={l.photo} />
                          <span className="text-[13px] font-semibold" style={{ color: 'var(--text-primary)' }}>
                            {l.fish}
                          </span>
                        </div>
                      </td>
                      <td className="px-5 py-3.5">
                        <div>
                          <div className="text-[13px]" style={{ color: 'var(--text-secondary)' }}>
                            {l.seller}
                          </div>
                          <StarRating value={l.avg_rating} count={l.rating_count} />
                        </div>
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-1.5 text-[12px]" style={{ color: 'var(--text-muted)' }}>
                          <MapPin size={11} style={{ color: 'var(--text-muted)', opacity: 0.6 }} />
                          {l.location}
                        </div>
                      </td>
                      <td className="px-5 py-3.5">
                        <span
                          style={{ fontFamily: 'JetBrains Mono', fontSize: 12, color: 'var(--text-secondary)' }}
                        >
                          {l.qty} {l.unit}
                        </span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span
                          style={{ fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}
                        >
                          {fmtSSP(l.price)}
                        </span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span
                          className="inline-flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wide px-2.5 py-1 rounded-full"
                          style={{ color: s.color, background: s.bg }}
                        >
                          <span className="w-1.5 h-1.5 rounded-full" style={{ background: s.color }} />
                          {l.status}
                        </span>
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-1.5 text-[12px]" style={{ color: 'var(--text-muted)' }}>
                          <Calendar size={11} style={{ opacity: 0.6 }} />
                          <span className="whitespace-nowrap">{l.date}</span>
                        </div>
                      </td>
                      <td className="px-4 py-3.5">
                        <button
                          className="p-1.5 rounded-lg transition-all"
                          style={{
                            background: isSelected ? 'var(--primary-glow)' : 'transparent',
                            color: isSelected ? 'var(--primary)' : 'var(--text-muted)',
                            opacity: isSelected ? 1 : 0,
                          }}
                        >
                          <Eye size={14} />
                        </button>
                      </td>
                    </tr>
                  )
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
                Showing {filtered.length} listings {liveData ? '· live data' : ''}
              </span>
              <button
                onClick={exportCSV}
                className="text-[11px] font-semibold flex items-center gap-1 transition-colors"
                style={{ color: 'var(--primary)' }}
              >
                Export CSV <ArrowUpRight size={11} />
              </button>
            </div>
          )}
        </div>

      </div>

      <DetailPanel listing={selected} onClose={() => setSelected(null)} onRefresh={fetchListings} />
    </AppLayout>
  )
}
