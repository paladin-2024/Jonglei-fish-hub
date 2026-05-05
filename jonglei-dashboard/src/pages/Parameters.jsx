import { useState } from 'react'
import AppLayout from '../components/AppLayout'
import api from '../api/axios'
import { Save, CheckCircle, AlertTriangle, ToggleLeft, ToggleRight, Settings2 } from 'lucide-react'

function SectionCard({ title, description, accent = 'bg-teal-800', children }) {
  return (
    <div className="bg-white rounded-2xl overflow-hidden">
      <div className={`h-[3px] ${accent}`} />
      <div className="px-5 py-4 border-b border-stone-100">
        <h2 className="text-[13px] font-bold uppercase tracking-widest text-stone-500">{title}</h2>
        {description && <p className="text-[12px] text-stone-400 mt-0.5">{description}</p>}
      </div>
      <div className="p-5 space-y-4">{children}</div>
    </div>
  )
}

function NumberField({ label, value, onChange, unit, min, max, hint }) {
  return (
    <div>
      <label className="block text-[11px] font-bold uppercase tracking-wider text-stone-400 mb-1.5">
        {label}{hint && <span className="ml-2 font-normal normal-case text-stone-300">{hint}</span>}
      </label>
      <div className="flex items-center gap-0">
        <input
          type="number"
          value={value}
          min={min}
          max={max}
          onChange={e => onChange(e.target.value)}
          className="w-full px-3.5 py-2.5 text-[13px] border border-stone-200 rounded-l-xl
                     outline-none focus:border-teal-400 focus:ring-2 focus:ring-teal-100
                     bg-white text-stone-800"
        />
        {unit && (
          <span className="px-3.5 py-2.5 text-[12px] text-stone-500 bg-stone-50 border border-l-0
                           border-stone-200 rounded-r-xl font-mono whitespace-nowrap">
            {unit}
          </span>
        )}
      </div>
    </div>
  )
}

function Toggle({ label, sublabel, checked, onChange }) {
  return (
    <div className="flex items-center justify-between py-2">
      <div>
        <p className="text-[13px] font-semibold text-stone-800">{label}</p>
        {sublabel && <p className="text-[11px] text-stone-400">{sublabel}</p>}
      </div>
      <button onClick={() => onChange(!checked)} className="flex-shrink-0">
        {checked
          ? <ToggleRight size={28} className="text-teal-700" />
          : <ToggleLeft  size={28} className="text-stone-300" />
        }
      </button>
    </div>
  )
}

function SaveBar({ onSave, saving, saved, error }) {
  return (
    <div className="flex items-center gap-3 pt-2">
      <button
        onClick={onSave}
        disabled={saving}
        className="flex items-center gap-2 px-4 py-2.5 bg-teal-800 hover:bg-teal-700
                   text-white text-[13px] font-semibold rounded-xl transition-all disabled:opacity-50"
      >
        {saved ? <CheckCircle size={14} /> : <Save size={14} />}
        {saving ? 'Saving…' : saved ? 'Saved' : 'Save'}
      </button>
      {error && (
        <span className="flex items-center gap-1.5 text-[12px] text-red-600">
          <AlertTriangle size={12} /> {error}
        </span>
      )}
    </div>
  )
}

export default function Parameters() {
  // Platform config
  const [platform, setPlatform] = useState({
    currency: 'SSP',
    commission_rate: 2.5,
    min_listing_weight_kg: 5,
    max_order_weight_kg: 5000,
  })
  const [platSaving, setPlatSaving] = useState(false)
  const [platSaved,  setPlatSaved]  = useState(false)
  const [platErr,    setPlatErr]    = useState('')

  // Price alerts
  const [alerts, setAlerts] = useState({
    price_surge_threshold_pct: 15,
    price_drop_threshold_pct: 10,
    low_stock_threshold_kg: 20,
  })
  const [alertSaving, setAlertSaving] = useState(false)
  const [alertSaved,  setAlertSaved]  = useState(false)
  const [alertErr,    setAlertErr]    = useState('')

  // Notification toggles
  const [notifs, setNotifs] = useState({
    email_on_new_order:     true,
    email_on_shipment:      true,
    push_on_clearance:      true,
    push_on_price_surge:    false,
    push_on_new_user:       false,
  })
  const [notifSaving, setNotifSaving] = useState(false)
  const [notifSaved,  setNotifSaved]  = useState(false)
  const [notifErr,    setNotifErr]    = useState('')

  // Maintenance mode
  const [maintenance, setMaintenance] = useState(false)
  const [maintSaving, setMaintSaving] = useState(false)
  const [maintErr,    setMaintErr]    = useState('')

  async function save(key, payload, setSaving, setSaved, setErr) {
    setSaving(true); setErr('')
    try {
      await api.patch(`/settings/${key}/`, payload)
      setSaved(true)
      setTimeout(() => setSaved(false), 3000)
    } catch (e) {
      setErr(e.response?.data?.detail ?? 'Save failed.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <AppLayout title="Parameters" subtitle="Platform-wide configuration and thresholds">
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-5 animate-fade-up">

        {/* Platform config */}
        <SectionCard
          title="Platform Configuration"
          description="Core trading parameters applied across the platform"
        >
          <div className="grid grid-cols-2 gap-4">
            <NumberField
              label="Commission Rate"
              value={platform.commission_rate}
              onChange={v => setPlatform(p => ({ ...p, commission_rate: v }))}
              unit="%"
              min={0} max={20}
              hint="per transaction"
            />
            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-stone-400 mb-1.5">
                Currency
              </label>
              <select
                value={platform.currency}
                onChange={e => setPlatform(p => ({ ...p, currency: e.target.value }))}
                className="w-full px-3.5 py-2.5 text-[13px] border border-stone-200 rounded-xl
                           outline-none focus:border-teal-400 bg-white text-stone-800"
              >
                <option value="SSP">SSP — South Sudanese Pound</option>
                <option value="USD">USD — US Dollar</option>
                <option value="UGX">UGX — Ugandan Shilling</option>
              </select>
            </div>
            <NumberField
              label="Min Listing Weight"
              value={platform.min_listing_weight_kg}
              onChange={v => setPlatform(p => ({ ...p, min_listing_weight_kg: v }))}
              unit="kg"
              min={1}
            />
            <NumberField
              label="Max Order Weight"
              value={platform.max_order_weight_kg}
              onChange={v => setPlatform(p => ({ ...p, max_order_weight_kg: v }))}
              unit="kg"
              min={1}
            />
          </div>
          <SaveBar
            onSave={() => save('platform', platform, setPlatSaving, setPlatSaved, setPlatErr)}
            saving={platSaving} saved={platSaved} error={platErr}
          />
        </SectionCard>

        {/* Price alert thresholds */}
        <SectionCard
          title="Price Alert Thresholds"
          description="Trigger notifications when prices cross these thresholds"
          accent="bg-amber-600"
        >
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <NumberField
              label="Surge Alert"
              value={alerts.price_surge_threshold_pct}
              onChange={v => setAlerts(a => ({ ...a, price_surge_threshold_pct: v }))}
              unit="%"
              min={1} max={100}
            />
            <NumberField
              label="Drop Alert"
              value={alerts.price_drop_threshold_pct}
              onChange={v => setAlerts(a => ({ ...a, price_drop_threshold_pct: v }))}
              unit="%"
              min={1} max={100}
            />
            <NumberField
              label="Low Stock"
              value={alerts.low_stock_threshold_kg}
              onChange={v => setAlerts(a => ({ ...a, low_stock_threshold_kg: v }))}
              unit="kg"
              min={1}
            />
          </div>
          <SaveBar
            onSave={() => save('alerts', alerts, setAlertSaving, setAlertSaved, setAlertErr)}
            saving={alertSaving} saved={alertSaved} error={alertErr}
          />
        </SectionCard>

        {/* Notification rules */}
        <SectionCard
          title="Notification Rules"
          description="Control which events generate alerts for admins"
          accent="bg-blue-700"
        >
          <div className="divide-y divide-stone-100 -mx-1">
            <Toggle
              label="Email on new order"
              sublabel="Admin email when a buyer places an order"
              checked={notifs.email_on_new_order}
              onChange={v => setNotifs(n => ({ ...n, email_on_new_order: v }))}
            />
            <Toggle
              label="Email on shipment update"
              sublabel="Admin email when shipment status changes"
              checked={notifs.email_on_shipment}
              onChange={v => setNotifs(n => ({ ...n, email_on_shipment: v }))}
            />
            <Toggle
              label="Push on clearance request"
              sublabel="Push notification when border clearance is needed"
              checked={notifs.push_on_clearance}
              onChange={v => setNotifs(n => ({ ...n, push_on_clearance: v }))}
            />
            <Toggle
              label="Push on price surge"
              sublabel="Alert when fish price crosses surge threshold"
              checked={notifs.push_on_price_surge}
              onChange={v => setNotifs(n => ({ ...n, push_on_price_surge: v }))}
            />
            <Toggle
              label="Push on new user registration"
              checked={notifs.push_on_new_user}
              onChange={v => setNotifs(n => ({ ...n, push_on_new_user: v }))}
            />
          </div>
          <SaveBar
            onSave={() => save('notifications', notifs, setNotifSaving, setNotifSaved, setNotifErr)}
            saving={notifSaving} saved={notifSaved} error={notifErr}
          />
        </SectionCard>

        {/* Maintenance mode */}
        <SectionCard
          title="Maintenance Mode"
          description="Suspend all trading activity while platform updates are applied"
          accent="bg-red-600"
        >
          <div className="p-4 rounded-xl bg-red-50 flex items-start gap-3">
            <AlertTriangle size={16} className="text-red-500 flex-shrink-0 mt-0.5" />
            <p className="text-[12px] text-red-700">
              Enabling maintenance mode will prevent traders, buyers and transporters from
              using the platform. All active sessions will see a maintenance notice.
            </p>
          </div>
          <Toggle
            label="Maintenance Mode"
            sublabel={maintenance ? 'Platform is currently offline for maintenance' : 'Platform is live'}
            checked={maintenance}
            onChange={v => {
              setMaintenance(v)
              save('maintenance', { enabled: v }, setMaintSaving, () => {}, setMaintErr)
            }}
          />
          {maintErr && (
            <p className="text-[12px] text-red-600 flex items-center gap-1.5">
              <AlertTriangle size={12} /> {maintErr}
            </p>
          )}
          {maintSaving && (
            <p className="text-[12px] text-stone-400">Updating…</p>
          )}
        </SectionCard>
      </div>
    </AppLayout>
  )
}
