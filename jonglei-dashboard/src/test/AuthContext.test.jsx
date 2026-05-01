import { render, screen } from '@testing-library/react'
import { AuthProvider, useAuth } from '../context/AuthContext'

function TestConsumer() {
  const { isAuthenticated, user } = useAuth()
  return (
    <div>
      <span data-testid="auth">{isAuthenticated ? 'yes' : 'no'}</span>
      <span data-testid="user">{user ? user.phone_number : 'none'}</span>
    </div>
  )
}

test('starts unauthenticated with no user', () => {
  render(
    <AuthProvider>
      <TestConsumer />
    </AuthProvider>
  )
  expect(screen.getByTestId('auth').textContent).toBe('no')
  expect(screen.getByTestId('user').textContent).toBe('none')
})

test('reads user from localStorage on mount', () => {
  const fakeUser = {
    id: '1',
    phone_number: '+211912',
    username: 'u',
    role: 'ADMIN',
    role_display: 'Administrator',
  }
  localStorage.setItem('access_token', 'fake-token')
  localStorage.setItem('user', JSON.stringify(fakeUser))

  render(
    <AuthProvider>
      <TestConsumer />
    </AuthProvider>
  )
  expect(screen.getByTestId('auth').textContent).toBe('yes')
  expect(screen.getByTestId('user').textContent).toBe('+211912')
  localStorage.clear()
})
