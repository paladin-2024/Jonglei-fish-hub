import AppLayout from '../components/AppLayout'
import { Truck, MapPin } from 'lucide-react'

const CITIES = ['Juba', 'Bor', 'Malakal', 'Renk', 'Wau', 'Torit']

export default function Shipments() {
  return (
    <AppLayout title="Shipments" subtitle="Fish transport routes and delivery tracking">
      <div className="max-w-6xl mx-auto space-y-4">

        {/* Route preview */}
        <div className="bg-white rounded-2xl border border-gray-100 p-5">
          <p className="text-[11px] font-semibold uppercase tracking-widest text-gray-400 mb-3">Active corridors</p>
          <div className="flex flex-wrap gap-2">
            {CITIES.map(city => (
              <div
                key={city}
                className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-50 border border-gray-100 rounded-xl text-[12px] text-gray-600 font-medium"
              >
                <MapPin size={11} className="text-teal-500" />
                {city}
              </div>
            ))}
          </div>
        </div>

        {/* Empty state */}
        <div className="bg-white rounded-2xl border border-gray-100 flex flex-col items-center justify-center py-20 px-8 text-center">
          <div className="w-14 h-14 bg-indigo-50 rounded-2xl flex items-center justify-center mb-5">
            <Truck size={24} className="text-indigo-500" />
          </div>
          <h2 className="text-base font-bold text-gray-800 mb-1.5">No active shipments</h2>
          <p className="text-[13px] text-gray-400 max-w-xs leading-relaxed">
            Transport routes and delivery tracking will populate here once transporters log shipments through the mobile app.
          </p>
        </div>
      </div>
    </AppLayout>
  )
}
