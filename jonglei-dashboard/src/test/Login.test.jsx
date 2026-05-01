import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi } from 'vitest'
import Login from '../pages/Login'
import { AuthContext } from '../context/AuthContext'

function renderLogin(loginFn = vi.fn()) {
  return render(
    <AuthContext.Provider value={{ login: loginFn, isAuthenticated: false }}>
      <MemoryRouter>
        <Login />
      </MemoryRouter>
    </AuthContext.Provider>
  )
}

test('renders phone and password fields', () => {
  renderLogin()
  expect(screen.getByLabelText(/phone number/i)).toBeInTheDocument()
  expect(screen.getByLabelText(/password/i)).toBeInTheDocument()
})

test('calls login with entered credentials', async () => {
  const mockLogin = vi.fn().mockResolvedValue({ role: 'ADMIN' })
  renderLogin(mockLogin)

  fireEvent.change(screen.getByLabelText(/phone number/i), {
    target: { value: '+211911111111' },
  })
  fireEvent.change(screen.getByLabelText(/password/i), {
    target: { value: 'securepass' },
  })
  fireEvent.click(screen.getByRole('button', { name: /sign in/i }))

  await waitFor(() =>
    expect(mockLogin).toHaveBeenCalledWith('+211911111111', 'securepass')
  )
})
