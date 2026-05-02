import AppLayout from '../components/AppLayout'
import { ShoppingBag, Plus } from 'lucide-react'

export default function Orders() {
  return (
    <AppLayout title="Orders" subtitle="Fish purchase transactions across the platform">
      <div className="max-w-6xl mx-auto">
        <div className="bg-white rounded-2xl border border-gray-100 flex flex-col items-center justify-center py-24 px-8 text-center">
          <div className="w-14 h-14 bg-amber-50 rounded-2xl flex items-center justify-center mb-5">
            <ShoppingBag size={24} className="text-amber-500" />
          </div>
          <h2 className="text-base font-bold text-gray-800 mb-1.5">No orders yet</h2>
          <p className="text-[13px] text-gray-400 max-w-xs leading-relaxed">
            Orders will appear here once traders post fish listings and buyers place purchases through the platform.
          </p>
          <div className="mt-6 flex items-center gap-2 text-[12px] text-gray-400 bg-gray-50 border border-gray-100 px-4 py-2.5 rounded-xl">
            <Plus size={13} className="text-gray-400" />
            Connect the listings API to populate this page
          </div>
        </div>
      </div>
    </AppLayout>
  )
}
