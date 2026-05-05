import { useState, useMemo, useEffect } from 'react'
import AppLayout from '../components/AppLayout'
import { ShieldCheck, Search, Filter, CheckCircle2, XCircle, ArrowUpRight, RefreshCw } from 'lucide-react'
import api from '../api/axios'

const SAMPLE_DATA = [
  { id: 'CLR-0031', shipment: 'SHP-0041', cargo: 'Nile Perch (120 kg)',          checkpoint: 'Bor Checkpoint',   officer: 'L. Mabior',   status: 'PENDING', date: '03 May 2026' },
  { id: 'CLR-0030', shipment: 'SHP-0040', cargo: 'Tilapia Fresh (45 kg)',         checkpoint: 'Juba Gate',        officer: 'A. Kuol',     status: 'CLEARED', date: '03 May 2026' },
  { id: 'CLR-0029', shipment: 'SHP-0039', cargo: 'Catfish (200 kg)',              checkpoint: 'Renk Border',      officer: 'P. Gai',      status: 'HELD',    date: '02 May 2026' },
  { id: 'CLR-0028', shipment: 'SHP-0038', cargo: 'Nile Perch Smoked (300 kg)',   checkpoint: 'Malakal Gate',     officer: 'T. Deng',     status: 'CLEARED', date: '02 May 2026' },
  { id: 'CLR-0027', shipment: 'SHP-0037', cargo: 'Lungfish (80 kg)',              checkpoint: 'Bor Checkpoint',   officer: 'L. Mabior',   status: 'PENDING', date: '01 May 2026' },
  { id: 'CLR-0026', shipment: 'SHP-0036', cargo: 'Tilapia Smoked (60 kg)',        checkpoint: 'Juba Gate',        officer: 'A. Kuol',     status: 'HELD',    date: '01 May 2026' },
  { id: 'CLR-0025', shipment: 'SHP-0035', cargo: 'Nile Perch (150 kg)',           checkpoint: 'Renk Border',      officer: 'P. Gai',      status: 'CLEARED', date: '30 Apr 2026' },
  { id: 'CLR-0024', shipment: 'SHP-0034', cargo: 'Catfish (90 kg)',               checkpoint: 'Torit Crossing',   officer: 'M. Chol',     status: 'PENDING', date: '30 Apr 2026' },
]

function normalizeClearance(j) {
  return {
    id:         j.id?.toString().toUpperCase().slice(0, 12)      ?? j.id,
    shipment:   j.shipment?.toString().toUpperCase().slice(0, 10) ?? '—',
    cargo:      j.cargo ?? j.description ?? '—',
    checkpoint: j.checkpoint ?? j.location ?? '—',
    officer:    j.officer ?? j.officer_name ?? '—',
    status:     (j.status ?? 'PENDING').toUpperCase(),
    date:       j.date ?? (j.created_at
      ? new Date(j.created_at).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
      : '—'),
  }
}

const STATUS_CFG = {
  PENDING: { dot: 'bg-amber-500', pill: 'bg-amber-50 text-amber-800 ring-amber-100' },
  CLEARED: { dot: 'bg-teal-500',  pill: 'bg-teal-50 text-teal-800 ring-teal-100'   },
  HELD:    { dot: 'bg-red-500',   pill: 'bg-red-50 text-red-800 ring-red-100'       },
}

const FILTERS = ['ALL', 'PENDING', 'CLEARED', 'HELD']

function SkeletonRow() {
  return (
    <tr className="border-b border-stone-50">
      {[...Array(8)].map((_, i) => (
        <td key={i} className="px-5 py-4">
          <div className="h-3 bg-stone-100 rounded animate-pulse" style={{ width: `${45 + (i % 3) * 20}%` }} />
        </td>
      ))}
    </tr>
  )
}

export default function Clearance() {
  const [records, setRecords]         = useState(SAMPLE_DATA)
  const [loading, setLoading]         = useState(true)
  const [isLive, setIsLive]           = useState(false)
  const [error, setError]             = useState(null)
  const [activeFilter, setActiveFilter] = useState('ALL')
  const [search, setSearch]           = useState('')
  const [actionState, setActionState] = useState({}) // { [id]: 'loading' | 'done' }

  function fetchClearances() {
    setLoading(true)
    setError(null)
    api.get('/clearance/')
      .then(r => {
        const raw = Array.isArray(r.data) ? r.data : (r.data?.results ?? [])
        if (raw.length > 0) {
          setRecords(raw.map(normalizeClearance))
          setIsLive(true)
        }
      })
      .catch(() => setError('Failed to load clearances.'))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    fetchClearances()
  }, [])

  const filtered = useMemo(() => {
    const q = search.toLowerCase()
    return records
      .filter(r => activeFilter === 'ALL' || r.status === activeFilter)
      .filter(r => !q || [r.id, r.shipment, r.checkpoint, r.cargo, r.officer].some(v => String(v).toLowerCase().includes(q)))
  }, [records, activeFilter, search])

  const kpiItems = useMemo(() => [
    {
      label: 'PENDING TODAY',
      val: records.filter(r => r.status === 'PENDING').length,
      bar: '#B45309',
    },
    {
      label: 'CLEARED TODAY',
      val: records.filter(r => r.status === 'CLEARED').length,
      bar: '#0F766E',
    },
    {
      label: 'FLAGGED / HELD',
      val: records.filter(r => r.status === 'HELD').length,
      bar: '#DC2626',
    },
  ], [records])

  function handleAction(id, action) {
    setActionState(s => ({ ...s, [id]: 'loading' }))
    const endpoint = action === 'clear'
      ? `/clearance/${id}/scan_clear/`
      : `/clearance/${id}/hold/`

    api.post(endpoint)
      .catch(() => {})
      .finally(() => {
        // Optimistic update regardless of API result
        const newStatus = action === 'clear' ? 'CLEARED' : 'HELD'
        setRecords(prev => prev.map(r => r.id === id ? { ...r, status: newStatus } : r))
        setActionState(s => ({ ...s, [id]: 'done' }))
        setTimeout(() => setActionState(s => { const next = { ...s }; delete next[id]; return next }), 1500)
      })
  }

  return (
    <AppLayout title="Clearance" subtitle="Border clearance queue for fish shipments">
      <div className="max-w-7xl mx-auto space-y-5">

        {/* KPI strip */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          {kpiItems.map((k, i) => (
            <div key={i} className={`bg-white rounded-xl shadow-card overflow-hidden flex flex-col animate-fade-up stagger-${i + 1}`}>
              <div className="h-[3px] w-full flex-shrink-0" style={{ background: k.bar }} />
              <div className="p-4 flex flex-col gap-1.5">
                <p className="text-[10px] font-semibold uppercase tracking-widest text-stone-400">{k.label}</p>
                <span className="font-mono text-2xl font-semibold leading-none text-stone-900">
                  {loading
                    ? <span className="inline-block h-7 w-10 bg-stone-100 rounded animate-pulse" />
                    : k.val}
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* Error banner */}
        {error && (
          <div className="flex items-center justify-between bg-red-50 border border-red-100
                          text-red-700 text-[12px] px-4 py-2.5 rounded-xl animate-fade-up">
            <span>{error}</span>
            <button onClick={fetchClearances} className="font-semibold hover:underline">Retry</button>
          </div>
        )}

        {/* Toolbar */}
        <div className="bg-white rounded-xl shadow-card p-4 flex flex-col gap-3 animate-fade-up stagger-4">
          <div className="flex items-center gap-3 flex-wrap">
            <div className="relative flex-1 min-w-[200px]">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-400 pointer-events-none" />
              <input
                type="text"
                placeholder="Search clearance ID or checkpoint…"
                value={search}
                onChange={e => setSearch(e.target.value)}
                className="w-full pl-9 pr-4 py-2 text-[13px] bg-stone-50 rounded-lg border border-stone-100
                           focus:outline-none focus:border-teal-700 focus:ring-1 focus:ring-teal-700/20
                           transition font-sans"
              />
            </div>
            <div className="flex items-center gap-2 text-[12px] text-stone-400">
              <Filter size={12} />
              <span>{filtered.length} of {records.length} records</span>
            </div>
            {isLive && (
              <div className="flex items-center gap-1.5 text-[11px] font-semibold text-teal-600 bg-teal-50 px-2.5 py-1 rounded-lg">
                <RefreshCw size={10} strokeWidth={2.5} />
                LIVE
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
        <div className="bg-white rounded-xl shadow-card overflow-hidden animate-fade-up stagger-5">
          <div className="h-[3px]" style={{ background: '#B45309' }} />

          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="border-b border-stone-100">
                  {['CLEARANCE ID', 'SHIPMENT', 'CARGO', 'CHECKPOINT', 'OFFICER', 'STATUS', 'DATE', 'ACTIONS'].map(h => (
                    <th key={h} className="px-5 py-3 text-[10px] font-bold uppercase tracking-widest text-stone-400 whitespace-nowrap">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  [...Array(5)].map((_, i) => <SkeletonRow key={i} />)
                ) : filtered.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="text-center py-16 text-stone-400 text-[13px]">
                      <ShieldCheck size={28} className="mx-auto mb-3 opacity-25" />
                      No records match this filter
                    </td>
                  </tr>
                ) : filtered.map((r) => {
                  const cfg = STATUS_CFG[r.status] ?? STATUS_CFG.PENDING
                  const acting = actionState[r.id]
                  return (
                    <tr
                      key={r.id}
                      className="border-b border-stone-50 hover:bg-stone-50/70 transition-colors group"
                    >
                      <td className="px-5 py-3.5">
                        <span className="font-mono text-[12px] font-semibold text-amber-700">{r.id}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="font-mono text-[12px] text-stone-600">{r.shipment}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="text-[13px] font-semibold text-stone-800">{r.cargo}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="text-[12px] text-stone-600">{r.checkpoint}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="text-[12px] text-stone-500">{r.officer}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        {acting === 'done' ? (
                          <span className="inline-flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wide px-2.5 py-1 rounded-lg ring-1 bg-green-50 text-green-700 ring-green-100">
                            <CheckCircle2 size={10} />
                            UPDATED
                          </span>
                        ) : (
                          <span className={`inline-flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wide px-2.5 py-1 rounded-lg ring-1 ${cfg.pill}`}>
                            <span className={`w-1.5 h-1.5 rounded-full ${cfg.dot}`} />
                            {r.status}
                          </span>
                        )}
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="font-mono text-[11px] text-stone-400 whitespace-nowrap">{r.date}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        {r.status === 'PENDING' && (
                          <div className="flex items-center gap-1.5">
                            <button
                              onClick={() => handleAction(r.id, 'clear')}
                              disabled={!!acting}
                              className="flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-bold
                                         uppercase tracking-wide bg-teal-600 text-white hover:bg-teal-700
                                         disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                            >
                              <CheckCircle2 size={10} />
                              CLEAR
                            </button>
                            <button
                              onClick={() => handleAction(r.id, 'hold')}
                              disabled={!!acting}
                              className="flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-bold
                                         uppercase tracking-wide bg-red-500 text-white hover:bg-red-600
                                         disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                            >
                              <XCircle size={10} />
                              HOLD
                            </button>
                          </div>
                        )}
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
                Showing {filtered.length} records {isLive ? '· live data' : '· sample data'}
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
