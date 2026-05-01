import Sidebar from '../components/Sidebar'
import { Search, Bell, Truck, MapPin } from 'lucide-react'

export default function Shipments() {
  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0">
        <header className="h-16 bg-white border-b border-gray-100 flex items-center justify-between px-8 sticky top-0 z-10">
          <div className="relative">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Search shipments..."
              className="pl-9 pr-4 py-2 text-sm bg-gray-50 border border-gray-200 rounded-xl w-64 focus:outline-none focus:border-teal-400 transition-colors"
            />
          </div>
          <button className="relative w-9 h-9 flex items-center justify-center rounded-xl hover:bg-gray-100 transition-colors">
            <Bell size={18} className="text-gray-500" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-teal-500 rounded-full" />
          </button>
        </header>

        <main className="flex-1 p-8">
          <div className="mb-6">
            <h1 className="text-2xl font-bold text-gray-900">Shipments</h1>
            <p className="text-gray-500 text-sm mt-0.5">Fish transport routes and deliveries</p>
          </div>

          <div className="bg-white rounded-2xl border border-gray-100 flex flex-col items-center justify-center py-24">
            <div className="w-16 h-16 bg-indigo-50 rounded-2xl flex items-center justify-center mb-4">
              <Truck size={28} className="text-indigo-400" />
            </div>
            <h2 className="text-lg font-bold text-gray-800 mb-1">Shipments coming soon</h2>
            <p className="text-sm text-gray-400 text-center max-w-xs">
              Transport routes and delivery tracking will appear here once the transport API is connected.
            </p>
            <div className="flex items-center gap-1.5 mt-4 text-xs text-indigo-400 font-medium">
              <MapPin size={12} /> Juba · Bor · Malakal · Renk
            </div>
          </div>
        </main>
      </div>
    </div>
  )
}
