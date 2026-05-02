import { useState, useMemo } from 'react'
import AppLayout from '../components/AppLayout'
import {
  Fish, Search, Filter, TrendingUp,
  ChevronDown, X, Eye, Trash2, Star,
  MapPin, Package, Calendar, ArrowUpRight,
} from 'lucide-react'

const LISTINGS = [
  { id: 'LST-0051', fish: 'Nile Perch',          seller: 'B. Deng (Bor)',       location: 'Bor',       qty: 250, price: 2450, unit: 'KG',   status: 'ACTIVE',  date: '02 May 2026', photo: null },
  { id: 'LST-0050', fish: 'Tilapia (Fresh)',      seller: 'Panyagoor Co-op',     location: 'Panyagoor', qty: 80,  price: 1800, unit: 'KG',   status: 'ACTIVE',  date: '02 May 2026', photo: null },
  { id: 'LST-0049', fish: 'Catfish',              seller: 'N. Dau (Twic East)',  location: 'Twic East', qty: 300, price: 2100, unit: 'KG',   status: 'DRAFT',   date: '01 May 2026', photo: null },
  { id: 'LST-0048', fish: 'Nile Perch (Smoked)', seller: 'B. Deng (Bor)',       location: 'Bor',       qty: 180, price: 3200, unit: 'KG',   status: 'SOLD',    date: '30 Apr 2026', photo: null },
  { id: 'LST-0047', fish: 'Lungfish',             seller: 'Fangak Hub',          location: 'Fangak',    qty: 60,  price: 1600, unit: 'KG',   status: 'ACTIVE',  date: '29 Apr 2026', photo: null },
  { id: 'LST-0046', fish: 'Tilapia (Smoked)',     seller: 'K. Thon (Renk)',      location: 'Renk',      qty: 120, price: 2100, unit: 'KG',   status: 'ACTIVE',  date: '28 Apr 2026', photo: null },
  { id: 'LST-0045', fish: 'Nile Perch',           seller: 'Bor Fisheries',       location: 'Bor',       qty: 500, price: 2350, unit: 'KG',   status: 'REMOVED', date: '27 Apr 2026', photo: null },
  { id: 'LST-0044', fish: 'Catfish',              seller: 'T. East Traders',     location: 'Twic East', qty: 200, price: 2000, unit: 'KG',   status: 'DRAFT',   date: '26 Apr 2026', photo: null },
  { id: 'LST-0043', fish: 'Tilapia (Fresh)',      seller: 'P. Chol (Panyagoor)', location: 'Panyagoor', qty: 40,  price: 1750, unit: 'KG',   status: 'SOLD',    date: '25 Apr 2026', photo: null },
  { id: 'LST-0042', fish: 'Nile Perch (Smoked)', seller: 'B. Deng (Bor)',       location: 'Bor',       qty: 90,  price: 3100, unit: 'CRATE', status: 'ACTIVE',  date: '24 Apr 2026', photo: null },
]

const STATUS_STYLES = {
  ACTIVE:  { dot: 'bg-teal-500',  badge: 'text-teal-700 bg-teal-50'   },
  DRAFT:   { dot: 'bg-amber-400', badge: 'text-amber-700 bg-amber-50' },
  SOLD:    { dot: 'bg-stone-400', badge: 'text-stone-600 bg-stone-100' },
  REMOVED: { dot: 'bg-red-400',   badge: 'text-red-700 bg-red-50'     },
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

const KPI_ITEMS = [
  { label: 'TOTAL LISTINGS', val: () => LISTINGS.length,                                       bar: '#005440' },
  { label: 'ACTIVE',         val: () => LISTINGS.filter(l => l.status === 'ACTIVE').length,     bar: '#0F766E' },
  { label: 'SOLD OUT',       val: () => LISTINGS.filter(l => l.status === 'SOLD').length,       bar: '#6B7280' },
  { label: 'ACTIVE VALUE',   val: () => {
    const total = LISTINGS.filter(l => l.status === 'ACTIVE').reduce((s, l) => s + (l.qty * l.price), 0)
    return 'SSP ' + total.toLocaleString()
  }, bar: '#B45309' },
]

function fmtSSP(n) { return 'SSP ' + n.toLocaleString() }

function SortChevron({ active, dir }) {
  if (!active) return null
  return <ChevronDown size={11} className={`inline ml-0.5 transition-transform duration-150 ${dir === 'asc' ? 'rotate-180' : ''}`} />
}

function SpeciesIcon({ species }) {
  const colors = {
    'Nile Perch': '#0F766E', 'Tilapia': '#1E5C8A', 'Catfish': '#6B4226',
    'Lungfish': '#4A7C59', 'Smoked': '#92400E',
  }
  const key = Object.keys(colors).find(k => species.includes(k)) ?? 'Nile Perch'
  const color = colors[key]
  const letter = species[0]
  return (
    <div
      className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 text-white text-[11px] font-bold"
      style={{ backgroundColor: color + '20', color }}
    >
      {letter}
    </div>
  )
}

function DetailPanel({ listing, onClose }) {
  if (!listing) return null
  const s = STATUS_STYLES[listing.status] ?? STATUS_STYLES.DRAFT
  const totalValue = listing.qty * listing.price

  return (
    <div className="fixed inset-0 z-40 flex justify-end" onClick={onClose}>
      <div className="absolute inset-0 bg-stone-900/20 backdrop-blur-[2px]" />
      <aside
        className="relative w-[340px] h-full bg-white shadow-[−24px_0_60px_rgba(0,31,26,0.12)] flex flex-col overflow-y-auto animate-slide-left"
        onClick={e => e.stopPropagation()}
      >
        {/* Top accent */}
        <div className="h-[3px] w-full flex-shrink-0" style={{ background: '#005440' }} />

        <div className="flex items-start justify-between p-5 pb-4">
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-widest text-stone-400 mb-1">
              Listing Detail
            </p>
            <h2 className="font-display text-[20px] text-stone-900 leading-tight">{listing.fish}</h2>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg hover:bg-stone-100 text-stone-400 transition-colors mt-0.5"
          >
            <X size={15} />
          </button>
        </div>

        <div className="px-5 space-y-5 pb-6">
          {/* Status */}
          <span className={`inline-flex items-center gap-1.5 text-[11px] font-semibold px-2.5 py-1 rounded-full ${s.badge}`}>
            <span className={`w-1.5 h-1.5 rounded-full ${s.dot}`} />
            {listing.status}
          </span>

          {/* Key metrics */}
          <div className="grid grid-cols-2 gap-3">
            {[
              { label: 'QTY', val: `${listing.qty} ${listing.unit}`, Icon: Package },
              { label: 'PRICE / KG', val: fmtSSP(listing.price), Icon: TrendingUp },
              { label: 'TOTAL VALUE', val: fmtSSP(totalValue), Icon: Star },
              { label: 'LOCATION', val: listing.location, Icon: MapPin },
            ].map(({ label, val, Icon }) => (
              <div key={label} className="bg-stone-50 rounded-xl p-3">
                <div className="flex items-center gap-1.5 mb-2">
                  <Icon size={11} className="text-stone-400" />
                  <span className="text-[9px] font-semibold uppercase tracking-widest text-stone-400">{label}</span>
                </div>
                <span className="font-mono text-[13px] font-semibold text-stone-900">{val}</span>
              </div>
            ))}
          </div>

          {/* Seller + date */}
          <div className="bg-stone-50 rounded-xl p-3 space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-[11px] text-stone-500">Seller</span>
              <span className="text-[12px] font-semibold text-stone-800">{listing.seller}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-[11px] text-stone-500">Listed</span>
              <span className="font-mono text-[11px] text-stone-500">{listing.date}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-[11px] text-stone-500">ID</span>
              <span className="font-mono text-[11px] text-teal-700">{listing.id}</span>
            </div>
          </div>

          {/* Actions */}
          <div className="space-y-2 pt-1">
            {listing.status === 'DRAFT' && (
              <button className="w-full py-3 bg-teal-700 hover:bg-teal-800 text-white text-[12px] font-bold rounded-xl transition-colors">
                Publish Listing
              </button>
            )}
            {listing.status === 'ACTIVE' && (
              <button className="w-full py-3 bg-amber-100 hover:bg-amber-200 text-amber-800 text-[12px] font-bold rounded-xl transition-colors">
                Feature Listing
              </button>
            )}
            {listing.status !== 'REMOVED' && (
              <button className="w-full flex items-center justify-center gap-2 py-3 bg-red-50 hover:bg-red-100 text-red-700 text-[12px] font-bold rounded-xl transition-colors">
                <Trash2 size={13} />
                Remove Listing
              </button>
            )}
          </div>
        </div>
      </aside>
    </div>
  )
}

export default function Listings() {
  const [activeFilter, setActiveFilter] = useState('ALL')
  const [search, setSearch]             = useState('')
  const [sortCol, setSortCol]           = useState('date')
  const [sortDir, setSortDir]           = useState('desc')
  const [selected, setSelected]         = useState(null)

  const filtered = useMemo(() => {
    const q = search.toLowerCase()
    return LISTINGS
      .filter(l => activeFilter === 'ALL' || l.status === activeFilter)
      .filter(l => !q || [l.id, l.fish, l.seller, l.location].some(v => v.toLowerCase().includes(q)))
      .sort((a, b) => {
        const av = a[sortCol], bv = b[sortCol]
        if (typeof av === 'number') return sortDir === 'asc' ? av - bv : bv - av
        return sortDir === 'asc' ? String(av).localeCompare(String(bv)) : String(bv).localeCompare(String(av))
      })
  }, [activeFilter, search, sortCol, sortDir])

  const activeValue = useMemo(
    () => filtered.filter(l => l.status === 'ACTIVE').reduce((s, l) => s + (l.qty * l.price), 0),
    [filtered]
  )

  function toggleSort(col) {
    if (sortCol === col) setSortDir(d => d === 'asc' ? 'desc' : 'asc')
    else { setSortCol(col); setSortDir('desc') }
  }

  return (
    <AppLayout title="Listings" subtitle="Fish listings posted by traders across the platform">
      <div className="max-w-7xl mx-auto space-y-5">

        {/* KPI strip */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          {KPI_ITEMS.map((k, i) => (
            <div key={i} className={`bg-white rounded-xl shadow-card overflow-hidden flex flex-col animate-fade-up stagger-${i + 1}`}>
              <div className="h-[3px] w-full flex-shrink-0" style={{ background: k.bar }} />
              <div className="p-4 flex flex-col gap-1.5">
                <p className="text-[10px] font-semibold uppercase tracking-widest text-stone-400">{k.label}</p>
                <span className="font-mono text-2xl font-semibold leading-none text-stone-900">{k.val()}</span>
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
                placeholder="Search species, seller, location…"
                value={search}
                onChange={e => setSearch(e.target.value)}
                className="w-full pl-9 pr-4 py-2 text-[13px] bg-stone-50 rounded-lg border border-stone-100 focus:outline-none focus:border-teal-700 focus:ring-1 focus:ring-teal-700/20 transition font-sans"
              />
            </div>
            <div className="flex items-center gap-2 text-[12px] text-stone-400">
              <Filter size={12} />
              <span>{filtered.length} of {LISTINGS.length} listings</span>
            </div>
            {activeValue > 0 && (
              <div className="flex items-center gap-1.5 bg-teal-50 text-teal-700 text-[11px] font-semibold px-3 py-1.5 rounded-lg">
                <TrendingUp size={11} strokeWidth={2.5} />
                {fmtSSP(activeValue)} active
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
                {filtered.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="text-center py-16 text-stone-400 text-[13px]">
                      <Fish size={28} className="mx-auto mb-3 opacity-25" />
                      No listings match this filter
                    </td>
                  </tr>
                ) : filtered.map((l) => {
                  const s = STATUS_STYLES[l.status] ?? STATUS_STYLES.DRAFT
                  const isSelected = selected?.id === l.id
                  return (
                    <tr
                      key={l.id}
                      onClick={() => setSelected(isSelected ? null : l)}
                      className={`border-b border-stone-50 cursor-pointer transition-colors group ${
                        isSelected ? 'bg-teal-50/60' : 'hover:bg-stone-50/70'
                      }`}
                    >
                      <td className="px-5 py-3.5">
                        <span className="font-mono text-[12px] font-semibold text-teal-700">{l.id}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-2.5">
                          <SpeciesIcon species={l.fish} />
                          <span className="text-[13px] font-semibold text-stone-800">{l.fish}</span>
                        </div>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="text-[13px] text-stone-700">{l.seller}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-1.5 text-[12px] text-stone-500">
                          <MapPin size={11} className="text-stone-300" />
                          {l.location}
                        </div>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="font-mono text-[12px] text-stone-600">{l.qty} {l.unit}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="font-mono text-[13px] font-semibold text-stone-900">{fmtSSP(l.price)}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className={`inline-flex items-center gap-1.5 text-[11px] font-semibold px-2.5 py-1 rounded-full ${s.badge}`}>
                          <span className={`w-1.5 h-1.5 rounded-full ${s.dot}`} />
                          {l.status}
                        </span>
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-1 text-[12px] text-stone-400">
                          <Calendar size={11} className="text-stone-300" />
                          <span className="whitespace-nowrap">{l.date}</span>
                        </div>
                      </td>
                      <td className="px-4 py-3.5">
                        <button className={`p-1.5 rounded-lg transition-all ${
                          isSelected
                            ? 'bg-teal-100 text-teal-700'
                            : 'opacity-0 group-hover:opacity-100 hover:bg-stone-100 text-stone-400'
                        }`}>
                          <Eye size={14} />
                        </button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>

          {filtered.length > 0 && (
            <div className="border-t border-stone-100 px-5 py-3 flex items-center justify-between">
              <span className="text-[11px] text-stone-400">
                Showing {filtered.length} listings
              </span>
              <button className="text-[11px] font-semibold text-teal-700 flex items-center gap-1 hover:underline">
                Export CSV <ArrowUpRight size={11} />
              </button>
            </div>
          )}
        </div>

      </div>

      {/* Detail panel */}
      <DetailPanel listing={selected} onClose={() => setSelected(null)} />
    </AppLayout>
  )
}
