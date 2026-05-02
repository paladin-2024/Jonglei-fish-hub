import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Users from './pages/Users'
import Orders from './pages/Orders'
import Shipments from './pages/Shipments'
import MarketPrices from './pages/MarketPrices'
import Analytics from './pages/Analytics'

function ProtectedRoute({ children }) {
  const { isAuthenticated } = useAuth()
  return isAuthenticated ? children : <Navigate to="/login" replace />
}

function AppRoutes() {
  const { isAuthenticated } = useAuth()
  return (
    <Routes>
      <Route path="/login" element={isAuthenticated ? <Navigate to="/dashboard" replace /> : <Login />} />
      <Route path="/dashboard"    element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
      <Route path="/users"        element={<ProtectedRoute><Users /></ProtectedRoute>} />
      <Route path="/orders"       element={<ProtectedRoute><Orders /></ProtectedRoute>} />
      <Route path="/shipments"    element={<ProtectedRoute><Shipments /></ProtectedRoute>} />
      <Route path="/market-prices" element={<ProtectedRoute><MarketPrices /></ProtectedRoute>} />
      <Route path="/analytics"    element={<ProtectedRoute><Analytics /></ProtectedRoute>} />
      <Route path="*" element={<Navigate to={isAuthenticated ? '/dashboard' : '/login'} replace />} />
    </Routes>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </AuthProvider>
  )
}
