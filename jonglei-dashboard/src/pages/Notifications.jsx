import { useState, useEffect, useCallback } from 'react'
import AppLayout from '../components/AppLayout'
import api from '../api/axios'
import {
  Send, Bell, ShoppingBag, Truck, ShieldCheck,
  RefreshCw, CheckCheck, Users, Megaphone,
} from 'lucide-react'

// ─── Audience options ─────────────────────────────────────────────────────────
const AUDIENCES = [
  { key: 'ALL',             label: 'All Users',        Icon: Users       },
  { key: 'TRADER',          label: 'Traders',          Icon: ShoppingBag },
  { key: 'BUYER',           label: 'Buyers',           Icon: Bell        },
  { key: 'TRANSPORTER',     label: 'Transporters',     Icon: Truck       },
  { key: 'BORDER_OFFICIAL', label: 'Border Officials', Icon: ShieldCheck },
]

// ─── Inbox meta ───────────────────────────────────────────────────────────────
const TYPE_META = {
  order:     { label: 'Order',     Icon: ShoppingBag, bg: 'bg-amber-50', text: 'text-amber-700', dot: 'bg-amber-500'  },
  shipment:  { label: 'Shipment',  Icon: Truck,        bg: 'bg-teal-50',  text: 'text-teal-700',  dot: 'bg-teal-500'   },
  clearance: { label: 'Clearance', Icon: ShieldCheck,  bg: 'bg-green-50', text: 'text-green-700', dot: 'bg-green-500'  },
  system:    { label: 'System',    Icon: Bell,          bg: 'bg-blue-50',  text: 'text-blue-700',  dot: 'bg-blue-500'   },
}

const SAMPLE_INBOX = [
  { id: 'n-1', title: 'New Order Placed',         body: 'B. Chol placed an order for 50 kg Nile Perch.',    type: 'order',     is_read: false, created_at: '2026-05-03 09:14' },
  { id: 'n-2', title: 'Shipment Dispatched',       body: 'SHP-0041 departed Bor, en route to Juba.',        type: 'shipment',  is_read: false, created_at: '2026-05-03 08:30' },
  { id: 'n-3', title: 'Clearance Required',        body: 'SHP-0040 awaiting border clearance at Juba.',     type: 'clearance', is_read: false, created_at: '2026-05-02 17:45' },
  { id: 'n-4', title: 'Price Alert: Tilapia +12%', body: 'Tilapia price surged 12% in the Malakal market.', type: 'system',    is_read: true,  created_at: '2026-05-02 14:20' },
  { id: 'n-5', title: 'Order Confirmed',           body: 'ORD-0088 confirmed by Nile Logistics.',           type: 'order',     is_read: true,  created_at: '2026-05-01 11:05' },
]

const SAMPLE_HISTORY = [
  { id: 'b-1', title: 'Market closure — Bor',   body: 'Bor central fish market will be closed on 4 May.',    target: 'ALL',             sent_at: '2026-05-02 08:00', reach: 248 },
  { id: 'b-2', title: 'New price bulletin',     body: 'Updated SSP rates effective from 1 May 2026.',        target: 'TRADER',          sent_at: '2026-05-01 10:30', reach: 84  },
  { id: 'b-3', title: 'Clearance fee change',   body: 'Border clearance processing fee updated to SSP 200.', target: 'BORDER_OFFICIAL', sent_at: '2026-04-30 09:15', reach: 12  },
]

// ─── Inbox row ─────────────────────────────────────────────────────────────────
function InboxRow({ n, onRead }) {
  const meta = TYPE_META[n.type] ?? TYPE_META.system
  const { Icon } = meta
  return (
    <div className={`flex items-start gap-3 px-5 py-3.5 border-b border-stone-100 last:border-0 ${n.is_read ? '' : 'bg-teal-50/40'}`}>
      <div className={`w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 ${meta.bg}`}>
        <Icon size={13} className={meta.text} strokeWidth={2} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className={`text-[13px] font-semibold leading-tight ${n.is_read ? 'text-stone-500' : 'text-stone-900'}`}>
            {n.title}
          </span>
          {!n.is_read && <span className={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${meta.dot}`} />}
        </div>
        <p className="text-[11px] text-stone-400 mt-0.5 truncate">{n.body}</p>
      </div>
      <div className="flex flex-col items-end gap-1 flex-shrink-0">
        <span className="font-mono text-[10px] text-stone-300">{n.created_at?.slice(11, 16)}</span>
        {!n.is_read && (
          <button onClick={() => onRead(n.id)}
            className="text-[10px] text-teal-600 hover:text-teal-800 font-semibold">
            Mark read
          </button>
        )}
      </div>
    </div>
  )
}

// ─── Sent history row ──────────────────────────────────────────────────────────
function HistoryRow({ b }) {
  const audience = AUDIENCES.find(a => a.key === b.target)
  return (
    <div className="flex items-start gap-3 px-5 py-3.5 border-b border-stone-100 last:border-0">
      <div className="w-8 h-8 rounded-xl bg-teal-50 flex items-center justify-center flex-shrink-0">
        <Megaphone size={13} className="text-teal-700" />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-[13px] font-semibold text-stone-800">{b.title}</span>
          <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-teal-50 text-teal-700 uppercase tracking-wide">
            {audience?.label ?? b.target}
          </span>
        </div>
        <p className="text-[11px] text-stone-400 mt-0.5 truncate">{b.body}</p>
      </div>
      <div className="text-right flex-shrink-0">
        <div className="font-mono text-[10px] text-stone-400">{b.sent_at}</div>
        <div className="text-[10px] text-stone-300 mt-0.5">{b.reach} recipients</div>
      </div>
    </div>
  )
}

// ─── Main page ────────────────────────────────────────────────────────────────
export default function NotificationCenter() {
  // Broadcast form state
  const [title,    setTitle]    = useState('')
  const [body,     setBody]     = useState('')
  const [audience, setAudience] = useState('ALL')
  const [sending,  setSending]  = useState(false)
  const [feedback, setFeedback] = useState({ text: '', ok: false })

  // Inbox state
  const [inbox,   setInbox]   = useState(SAMPLE_INBOX)
  const [inboxLoading, setInboxLoading] = useState(true)
  const [refreshing,   setRefreshing]   = useState(false)

  // Sent history state
  const [history, setHistory] = useState(SAMPLE_HISTORY)

  // ── Data loading ────────────────────────────────────────────────────────────
  const loadInbox = useCallback(async (silent = false) => {
    if (!silent) setInboxLoading(true); else setRefreshing(true)
    try {
      const { data } = await api.get('/notifications/')
      const list = Array.isArray(data) ? data : (data.results ?? [])
      if (list.length > 0) setInbox(list)
    } catch { /* keep sample */ }
    finally { setInboxLoading(false); setRefreshing(false) }
  }, [])

  const loadHistory = useCallback(async () => {
    try {
      const { data } = await api.get('/notifications/sent/')
      const list = Array.isArray(data) ? data : (data.results ?? [])
      if (list.length > 0) setHistory(list)
    } catch { /* keep sample */ }
  }, [])

  useEffect(() => { loadInbox(); loadHistory() }, [loadInbox, loadHistory])
  useEffect(() => {
    const id = setInterval(() => loadInbox(true), 60_000)
    return () => clearInterval(id)
  }, [loadInbox])

  // ── Actions ─────────────────────────────────────────────────────────────────
  const sendBroadcast = async () => {
    if (!title.trim() || !body.trim()) {
      return setFeedback({ text: 'Both title and message are required.', ok: false })
    }
    setSending(true); setFeedback({ text: '', ok: false })
    try {
      await api.post('/notifications/broadcast/', {
        title:       title.trim(),
        body:        body.trim(),
        target_role: audience,
      })
      const audienceLabel = AUDIENCES.find(a => a.key === audience)?.label ?? audience
      setFeedback({ text: `Broadcast sent to ${audienceLabel}.`, ok: true })
      setTitle(''); setBody('')
      loadHistory()
    } catch (e) {
      setFeedback({ text: e.response?.data?.detail ?? 'Failed to send. Please try again.', ok: false })
    } finally {
      setSending(false)
    }
  }

  const markRead = async (id) => {
    setInbox(prev => prev.map(n => n.id === id ? { ...n, is_read: true } : n))
    try { await api.post(`/notifications/${id}/mark_read/`, {}) } catch {}
  }

  const markAllRead = async () => {
    setInbox(prev => prev.map(n => ({ ...n, is_read: true })))
    try { await api.post('/notifications/mark_all_read/', {}) } catch {}
  }

  const unread = inbox.filter(n => !n.is_read).length

  return (
    <AppLayout title="Notification Center" subtitle="Send announcements to users and monitor platform alerts">
      <div className="grid grid-cols-1 xl:grid-cols-[1fr_380px] gap-5 animate-fade-up">

        {/* ── LEFT: Broadcast compose (always visible) ── */}
        <div className="space-y-5">
          <div className="bg-white rounded-2xl overflow-hidden">
            <div className="h-[3px] bg-teal-800" />
            <div className="px-5 py-4 border-b border-stone-100 flex items-center gap-2.5">
              <div className="w-7 h-7 bg-teal-50 rounded-lg flex items-center justify-center">
                <Megaphone size={13} className="text-teal-700" />
              </div>
              <div>
                <h2 className="text-[14px] font-bold text-stone-800">Send Broadcast</h2>
                <p className="text-[11px] text-stone-400">Push a notification to users on their mobile devices</p>
              </div>
            </div>

            <div className="p-5 space-y-5">
              {/* Audience selector */}
              <div>
                <label className="block text-[10px] font-bold uppercase tracking-wider text-stone-400 mb-2">
                  Target Audience
                </label>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                  {AUDIENCES.map(({ key, label, Icon }) => {
                    const active = audience === key
                    return (
                      <button
                        key={key}
                        onClick={() => setAudience(key)}
                        className={`flex items-center gap-2 px-3 py-2.5 rounded-xl text-[12px] font-semibold
                                    border transition-all text-left
                                    ${active
                                      ? 'bg-teal-800 text-white border-teal-800 shadow-sm'
                                      : 'text-stone-500 border-stone-200 hover:border-teal-300 hover:text-teal-700 bg-white'
                                    }`}
                      >
                        <Icon size={13} className="flex-shrink-0" />
                        {label}
                      </button>
                    )
                  })}
                </div>
              </div>

              {/* Title */}
              <div>
                <label className="block text-[10px] font-bold uppercase tracking-wider text-stone-400 mb-1.5">
                  Notification Title
                </label>
                <input
                  value={title}
                  onChange={e => setTitle(e.target.value)}
                  maxLength={80}
                  placeholder="e.g. Market closure notice, New price update…"
                  className="w-full px-4 py-3 text-[14px] border border-stone-200 rounded-xl
                             outline-none focus:border-teal-400 focus:ring-2 focus:ring-teal-100
                             placeholder-stone-300 text-stone-800"
                />
                <div className="text-right text-[10px] text-stone-300 mt-1">{title.length}/80</div>
              </div>

              {/* Body */}
              <div>
                <label className="block text-[10px] font-bold uppercase tracking-wider text-stone-400 mb-1.5">
                  Message
                </label>
                <textarea
                  value={body}
                  onChange={e => setBody(e.target.value)}
                  maxLength={300}
                  rows={5}
                  placeholder="Write your message here. This will arrive as a push notification on users' phones."
                  className="w-full px-4 py-3 text-[14px] border border-stone-200 rounded-xl
                             outline-none focus:border-teal-400 focus:ring-2 focus:ring-teal-100
                             placeholder-stone-300 text-stone-800 resize-none leading-relaxed"
                />
                <div className="text-right text-[10px] text-stone-300 mt-1">{body.length}/300</div>
              </div>

              {/* Feedback */}
              {feedback.text && (
                <div className={`px-4 py-3 rounded-xl text-[13px] font-medium
                                 ${feedback.ok
                                   ? 'bg-teal-50 text-teal-800 border border-teal-100'
                                   : 'bg-red-50 text-red-700 border border-red-100'
                                 }`}>
                  {feedback.text}
                </div>
              )}

              {/* Send button */}
              <button
                onClick={sendBroadcast}
                disabled={sending || !title.trim() || !body.trim()}
                className="w-full flex items-center justify-center gap-2.5 px-5 py-3.5
                           bg-teal-800 hover:bg-teal-700 text-white text-[14px] font-bold
                           rounded-xl transition-all disabled:opacity-40 disabled:cursor-not-allowed
                           shadow-sm"
              >
                <Send size={15} />
                {sending ? 'Sending…' : `Send to ${AUDIENCES.find(a => a.key === audience)?.label}`}
              </button>
            </div>
          </div>
        </div>

        {/* ── RIGHT: Inbox + Sent history ── */}
        <div className="space-y-5">

          {/* Inbox */}
          <div className="bg-white rounded-2xl overflow-hidden">
            <div className="h-[3px] bg-amber-500" />
            <div className="px-4 py-3 border-b border-stone-100 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Bell size={13} className="text-stone-500" />
                <span className="text-[13px] font-bold text-stone-700">Platform Alerts</span>
                {unread > 0 && (
                  <span className="min-w-[18px] h-[18px] px-1 flex items-center justify-center
                                   rounded-full bg-amber-500 text-white text-[10px] font-bold">
                    {unread}
                  </span>
                )}
              </div>
              <div className="flex items-center gap-1.5">
                {unread > 0 && (
                  <button onClick={markAllRead}
                    className="flex items-center gap-1 text-[11px] text-teal-600 font-semibold hover:text-teal-800">
                    <CheckCheck size={11} /> All read
                  </button>
                )}
                <button onClick={() => loadInbox(true)} disabled={refreshing}
                  className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-stone-100 text-stone-400">
                  <RefreshCw size={11} className={refreshing ? 'animate-spin' : ''} />
                </button>
              </div>
            </div>

            {inboxLoading
              ? [...Array(3)].map((_, i) => (
                  <div key={i} className="flex items-center gap-3 px-5 py-3.5 border-b border-stone-100 animate-pulse">
                    <div className="w-8 h-8 bg-stone-100 rounded-xl flex-shrink-0" />
                    <div className="flex-1 space-y-1.5">
                      <div className="h-3 bg-stone-100 rounded w-36" />
                      <div className="h-2.5 bg-stone-100 rounded w-full" />
                    </div>
                  </div>
                ))
              : inbox.length === 0
              ? <p className="text-center text-[13px] text-stone-400 py-8">No alerts</p>
              : inbox.map(n => <InboxRow key={n.id} n={n} onRead={markRead} />)
            }
          </div>

          {/* Sent history */}
          <div className="bg-white rounded-2xl overflow-hidden">
            <div className="h-[3px] bg-teal-600" />
            <div className="px-4 py-3 border-b border-stone-100 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Megaphone size={13} className="text-teal-600" />
                <span className="text-[13px] font-bold text-stone-700">Sent Broadcasts</span>
                <span className="text-[11px] text-stone-400 font-mono">{history.length}</span>
              </div>
            </div>
            {history.length === 0
              ? <p className="text-center text-[13px] text-stone-400 py-8">No broadcasts sent yet</p>
              : history.map(b => <HistoryRow key={b.id} b={b} />)
            }
          </div>
        </div>

      </div>
    </AppLayout>
  )
}
