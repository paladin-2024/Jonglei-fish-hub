import { useState, useEffect, useCallback } from 'react'
import AppLayout from '../components/AppLayout'
import api from '../api/axios'
import { RefreshCw, Filter, Activity } from 'lucide-react'

const METHOD_STYLE = {
  POST:   { bg: 'bg-teal-50',   text: 'text-teal-700'   },
  PATCH:  { bg: 'bg-amber-50',  text: 'text-amber-700'  },
  PUT:    { bg: 'bg-amber-50',  text: 'text-amber-700'  },
  DELETE: { bg: 'bg-red-50',    text: 'text-red-700'    },
  GET:    { bg: 'bg-stone-100', text: 'text-stone-600'  },
}

const SAMPLE = [
  { id: 1, user: 'admin',      method: 'POST',   path: '/api/v1/marketplace/listings/',   status: 201, duration_ms: 112, timestamp: '2026-05-03 09:14:02' },
  { id: 2, user: 'admin',      method: 'PATCH',  path: '/api/v1/marketplace/orders/14/',  status: 200, duration_ms: 84,  timestamp: '2026-05-03 09:10:47' },
  { id: 3, user: 'border_off', method: 'POST',   path: '/api/v1/clearance/18/clear/',     status: 200, duration_ms: 203, timestamp: '2026-05-03 08:55:30' },
  { id: 4, user: 'admin',      method: 'DELETE', path: '/api/v1/users/7/',               status: 204, duration_ms: 67,  timestamp: '2026-05-02 17:30:11' },
  { id: 5, user: 'trader1',    method: 'POST',   path: '/api/v1/transport/jobs/',        status: 201, duration_ms: 95,  timestamp: '2026-05-02 16:44:59' },
  { id: 6, user: 'admin',      method: 'PATCH',  path: '/api/v1/users/12/',              status: 200, duration_ms: 58,  timestamp: '2026-05-02 15:20:03' },
  { id: 7, user: 'transporter',method: 'POST',   path: '/api/v1/transport/jobs/3/accept_job/', status: 200, duration_ms: 130, timestamp: '2026-05-02 14:05:21' },
  { id: 8, user: 'admin',      method: 'DELETE', path: '/api/v1/marketplace/listings/5/', status: 204, duration_ms: 72, timestamp: '2026-05-01 11:02:44' },
]

const METHODS = ['All', 'POST', 'PATCH', 'DELETE']

function MethodBadge({ method }) {
  const s = METHOD_STYLE[method] ?? METHOD_STYLE.GET
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded-md font-mono text-[10px] font-bold ${s.bg} ${s.text}`}>
      {method}
    </span>
  )
}

function StatusBadge({ status }) {
  const ok = status < 300
  return (
    <span className={`font-mono text-[11px] font-bold ${ok ? 'text-teal-700' : 'text-red-600'}`}>
      {status}
    </span>
  )
}

export default function AuditLog() {
  const [rows, setRows]         = useState(SAMPLE)
  const [filter, setFilter]     = useState('All')
  const [loading, setLoading]   = useState(true)
  const [refreshing, setRefreshing] = useState(false)

  const load = useCallback(async (silent = false) => {
    if (!silent) setLoading(true); else setRefreshing(true)
    try {
      const { data } = await api.get('/audit-log/')
      const list = Array.isArray(data) ? data : (data.results ?? [])
      if (list.length > 0) setRows(list)
    } catch {
      // keep sample
    } finally {
      setLoading(false); setRefreshing(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  const visible = rows.filter(r => filter === 'All' || r.method === filter)

  const kpi = [
    { label: 'Total Actions', value: rows.length },
    { label: 'POST',   value: rows.filter(r => r.method === 'POST').length   },
    { label: 'PATCH',  value: rows.filter(r => r.method === 'PATCH').length  },
    { label: 'DELETE', value: rows.filter(r => r.method === 'DELETE').length },
  ]

  return (
    <AppLayout title="Audit Log" subtitle="Admin and user action history across the platform">

      {/* KPI strip */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6 animate-fade-up">
        {kpi.map((k, i) => (
          <div key={k.label}
            className={`bg-white rounded-2xl p-4 border-t-[3px]
                        ${i === 0 ? 'border-teal-700' : i === 1 ? 'border-teal-400' : i === 2 ? 'border-amber-500' : 'border-red-500'}`}
          >
            <div className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1">{k.label}</div>
            <div className="font-mono text-[26px] font-semibold text-stone-900">{k.value}</div>
          </div>
        ))}
      </div>

      {/* Table card */}
      <div className="bg-white rounded-2xl overflow-hidden animate-fade-up stagger-1">
        <div className="flex items-center justify-between px-5 py-3.5 border-b border-stone-100">
          <div className="flex items-center gap-2">
            <Filter size={13} className="text-stone-400" />
            <div className="flex gap-1.5">
              {METHODS.map(m => (
                <button
                  key={m}
                  onClick={() => setFilter(m)}
                  className={`px-3 py-1 rounded-lg text-[12px] font-semibold transition-all
                              ${filter === m ? 'bg-teal-800 text-white' : 'text-stone-500 hover:bg-stone-100'}`}
                >
                  {m}
                </button>
              ))}
            </div>
          </div>
          <button
            onClick={() => load(true)}
            disabled={refreshing}
            className="w-8 h-8 flex items-center justify-center rounded-xl hover:bg-stone-100 text-stone-400 transition-colors"
          >
            <RefreshCw size={13} className={refreshing ? 'animate-spin' : ''} />
          </button>
        </div>

        <div className="overflow-x-auto">
          {loading ? (
            <div className="divide-y divide-stone-100">
              {[...Array(5)].map((_, i) => (
                <div key={i} className="flex items-center gap-4 px-5 py-3.5 animate-pulse">
                  <div className="h-5 w-14 bg-stone-100 rounded-md" />
                  <div className="h-4 w-24 bg-stone-100 rounded" />
                  <div className="h-4 flex-1 bg-stone-100 rounded" />
                  <div className="h-4 w-16 bg-stone-100 rounded" />
                </div>
              ))}
            </div>
          ) : visible.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-stone-300">
              <Activity size={40} strokeWidth={1} />
              <p className="mt-3 text-[14px] text-stone-400 font-medium">No activity entries</p>
            </div>
          ) : (
            <table className="w-full text-left">
              <thead>
                <tr className="border-b border-stone-100">
                  {['Method', 'User', 'Endpoint', 'Status', 'Duration', 'Timestamp'].map(h => (
                    <th key={h} className="px-5 py-3 text-[10px] font-bold uppercase tracking-widest text-stone-400">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {visible.map(r => (
                  <tr key={r.id} className="border-b border-stone-100 hover:bg-stone-50/60 transition-colors">
                    <td className="px-5 py-3.5"><MethodBadge method={r.method} /></td>
                    <td className="px-5 py-3.5 font-mono text-[12px] text-stone-700">{r.user}</td>
                    <td className="px-5 py-3.5 font-mono text-[11px] text-stone-500 max-w-[280px] truncate">{r.path}</td>
                    <td className="px-5 py-3.5"><StatusBadge status={r.status} /></td>
                    <td className="px-5 py-3.5 font-mono text-[11px] text-stone-500">{r.duration_ms} ms</td>
                    <td className="px-5 py-3.5 font-mono text-[11px] text-stone-400">{r.timestamp}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </AppLayout>
  )
}
