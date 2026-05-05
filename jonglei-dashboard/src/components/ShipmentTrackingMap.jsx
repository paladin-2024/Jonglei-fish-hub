import { useMemo, useState } from 'react'
import { APIProvider, Map, AdvancedMarker, Pin, useMap } from '@vis.gl/react-google-maps'
import { Truck, MapPin, X } from 'lucide-react'

const CITY_COORDS = {
  'Juba':      { lat:  4.8517, lng: 31.5825 },
  'Bor':       { lat:  6.2090, lng: 31.5581 },
  'Malakal':   { lat:  9.5334, lng: 31.6598 },
  'Renk':      { lat: 11.7787, lng: 32.7991 },
  'Wau':       { lat:  7.7010, lng: 28.0000 },
  'Fangak':    { lat:  8.7333, lng: 30.8000 },
  'Pibor':     { lat:  6.8021, lng: 33.1212 },
  'Panyagoor': { lat:  7.0500, lng: 31.5200 },
  'Twic East': { lat:  7.5000, lng: 32.2000 },
  'Torit':     { lat:  4.4131, lng: 32.5632 },
}

const STATUS_COLORS = {
  'IN TRANSIT': '#1E5C8A',
  'CONFIRMED':  '#1A6B3C',
  'PENDING':    '#B45309',
  'CLEARED':    '#005440',
  'FLAGGED':    '#B91C1C',
}

function RouteLines({ shipments }) {
  const map = useMap()

  useMemo(() => {
    if (!map || !window.google) return
    const lines = []
    shipments.forEach(s => {
      const from = CITY_COORDS[s.origin]
      const to   = CITY_COORDS[s.dest]
      if (!from || !to) return
      const color = STATUS_COLORS[s.status] ?? '#005440'
      const line = new window.google.maps.Polyline({
        path: [from, to],
        geodesic: true,
        strokeColor: color,
        strokeOpacity: s.status === 'IN TRANSIT' ? 0.9 : 0.35,
        strokeWeight: s.status === 'IN TRANSIT' ? 3 : 1.5,
        icons: s.status === 'IN TRANSIT' ? [{
          icon: { path: window.google.maps.SymbolPath.FORWARD_CLOSED_ARROW, scale: 3, strokeColor: color },
          offset: '50%',
        }] : [],
        map,
      })
      lines.push(line)
    })
    return () => lines.forEach(l => l.setMap(null))
  }, [map, shipments])

  return null
}

function CityMarker({ city, coords, shipments, onClick }) {
  const relatedShipments = shipments.filter(s => s.origin === city || s.dest === city)
  const hasActive = relatedShipments.some(s => s.status === 'IN TRANSIT')

  return (
    <AdvancedMarker position={coords} onClick={() => onClick(city, relatedShipments)}>
      <div className="relative">
        {hasActive && (
          <span className="absolute -top-1 -right-1 flex h-3 w-3 z-10">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75" />
            <span className="relative inline-flex rounded-full h-3 w-3 bg-blue-500" />
          </span>
        )}
        <Pin
          background={hasActive ? '#1E5C8A' : '#005440'}
          borderColor={hasActive ? '#1E3A5F' : '#003D2E'}
          glyphColor="white"
          scale={hasActive ? 1.2 : 0.9}
        />
      </div>
    </AdvancedMarker>
  )
}

function CityPopup({ city, shipments, onClose }) {
  if (!city) return null
  return (
    <div className="absolute top-4 right-4 w-72 bg-white rounded-xl shadow-xl overflow-hidden z-10">
      <div className="h-[3px] bg-[#005440]" />
      <div className="p-4">
        <div className="flex items-start justify-between mb-3">
          <div>
            <div className="flex items-center gap-1.5 mb-0.5">
              <MapPin size={12} className="text-teal-600" />
              <p className="text-[11px] font-bold uppercase tracking-widest text-stone-400">{city}</p>
            </div>
            <p className="text-[13px] font-semibold text-stone-700">
              {shipments.length} shipment{shipments.length !== 1 ? 's' : ''}
            </p>
          </div>
          <button onClick={onClose} className="text-stone-400 hover:text-stone-600 transition-colors mt-0.5">
            <X size={15} />
          </button>
        </div>
        <div className="space-y-2">
          {shipments.map(s => {
            const color = STATUS_COLORS[s.status] ?? '#005440'
            const isOrigin = s.origin === city
            return (
              <div key={s.id} className="flex items-center gap-2.5 p-2 bg-stone-50 rounded-lg">
                <Truck size={13} className="text-stone-400 flex-shrink-0" />
                <div className="flex-1 min-w-0">
                  <p className="text-[12px] font-semibold text-stone-800 truncate">{s.fish}</p>
                  <p className="text-[10px] text-stone-400 font-mono">
                    {isOrigin ? `→ ${s.dest}` : `← ${s.origin}`} · {s.qty} kg
                  </p>
                </div>
                <span
                  className="text-[9px] font-bold uppercase px-1.5 py-0.5 rounded-md"
                  style={{ background: `${color}18`, color }}
                >
                  {s.status}
                </span>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}

export default function ShipmentTrackingMap({ shipments }) {
  const [selectedCity, setSelectedCity] = useState(null)
  const [popupShipments, setPopupShipments] = useState([])

  const activeCities = useMemo(() => {
    const cities = new Set()
    shipments.forEach(s => {
      if (CITY_COORDS[s.origin]) cities.add(s.origin)
      if (CITY_COORDS[s.dest])   cities.add(s.dest)
    })
    return [...cities].map(c => ({ city: c, coords: CITY_COORDS[c] }))
  }, [shipments])

  const handleMarkerClick = (city, related) => {
    setSelectedCity(city)
    setPopupShipments(related)
  }

  const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY

  if (!apiKey || apiKey === 'YOUR_WEB_MAPS_API_KEY_HERE') {
    return (
      <div className="h-full flex flex-col items-center justify-center bg-stone-50 rounded-xl text-stone-400">
        <MapPin size={28} className="mb-2" strokeWidth={1.5} />
        <p className="text-[13px] font-medium text-stone-500">Add VITE_GOOGLE_MAPS_API_KEY to .env</p>
      </div>
    )
  }

  return (
    <APIProvider apiKey={apiKey}>
      <div className="relative w-full h-full rounded-xl overflow-hidden">
        <Map
          defaultCenter={{ lat: 7.5, lng: 31.8 }}
          defaultZoom={6}
          mapId="jonglei-shipment-map"
          gestureHandling="cooperative"
          disableDefaultUI={false}
          mapTypeControl={false}
          streetViewControl={false}
          fullscreenControl={true}
          zoomControl={true}
          styles={[
            { featureType: 'water',      elementType: 'geometry', stylers: [{ color: '#c9d8e8' }] },
            { featureType: 'landscape',  elementType: 'geometry', stylers: [{ color: '#f0ece4' }] },
            { featureType: 'road',       elementType: 'geometry', stylers: [{ color: '#e8e4dc' }] },
            { featureType: 'road.highway', elementType: 'geometry', stylers: [{ color: '#d4cfc6' }] },
            { featureType: 'poi',        stylers: [{ visibility: 'off' }] },
            { featureType: 'transit',    stylers: [{ visibility: 'off' }] },
            { featureType: 'administrative', elementType: 'geometry.stroke', stylers: [{ color: '#b8b0a4' }] },
          ]}
        >
          <RouteLines shipments={shipments} />
          {activeCities.map(({ city, coords }) => (
            <CityMarker
              key={city}
              city={city}
              coords={coords}
              shipments={shipments}
              onClick={handleMarkerClick}
            />
          ))}
        </Map>

        <CityPopup
          city={selectedCity}
          shipments={popupShipments}
          onClose={() => setSelectedCity(null)}
        />

        {/* Legend */}
        <div className="absolute bottom-4 left-4 bg-white/90 backdrop-blur-sm rounded-xl p-3 shadow-md">
          <p className="text-[9px] font-bold uppercase tracking-widest text-stone-400 mb-2">Status</p>
          <div className="space-y-1.5">
            {[['IN TRANSIT', '#1E5C8A'], ['CONFIRMED', '#1A6B3C'], ['PENDING', '#B45309'], ['CLEARED', '#005440'], ['FLAGGED', '#B91C1C']].map(([label, color]) => (
              <div key={label} className="flex items-center gap-2">
                <span className="w-4 h-0.5 rounded-full" style={{ background: color }} />
                <span className="text-[10px] font-semibold text-stone-600">{label}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </APIProvider>
  )
}
