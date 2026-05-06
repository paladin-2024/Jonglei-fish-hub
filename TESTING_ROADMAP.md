# Jonglei Fish Hub — Testing Roadmap

> Test on physical device (Android). Backend at `http://<your-ip>:8000`. Dashboard at `http://localhost:5173`.

---

## Phase 1 — Authentication

### 1.1 Registration
- [ ] Open app → tap **Sign Up**
- [ ] Enter valid phone number (`+211...`), full name, password (8+ chars)
- [ ] Select a role: **Trader**, **Buyer**, **Transporter**, or **Border Official**
- [ ] Tap **Next** → map step loads with location chips
- [ ] Tap a city chip (Juba, Bor, Malakal, etc.) → chip highlights, badge appears
- [ ] Tap **Use GPS location** → nearest city auto-selects (requires GPS permission grant)
- [ ] Drag map pin → badge updates to custom location
- [ ] Tap **Create Account** → success → lands on correct home screen for role

**Edge cases:**
- [ ] Short password → inline error shown
- [ ] Duplicate phone number → server error shown in banner
- [ ] Skip location step (no chip selected) → button disabled / validation error

### 1.2 Login
- [ ] Enter registered phone + password → taps **Sign In** → routed to role home
- [ ] Wrong password → error banner "Invalid phone number or password"
- [ ] Tap **Don't have an account?** → navigates to Register

### 1.3 Session persistence
- [ ] Force-close app → reopen → stays logged in (no re-login required)
- [ ] Token expiry: wait 60 min or manually expire token → app silently refreshes using refresh token

---

## Phase 2 — Trader Flow

### 2.1 Home screen
- [ ] Market prices section shows species with price per kg
- [ ] "Post Listing" FAB opens create-listing sheet

### 2.2 Browse & create listings
- [ ] Marketplace tab: listings grid loads from backend
- [ ] Tap listing card → detail sheet with quantity, price, location
- [ ] Tap **Post Listing** → fill species, qty, price, unit → submit → listing appears in feed

### 2.3 Prices screen
- [ ] Shows live prices for 6 cities
- [ ] Pull to refresh updates data

### 2.4 Shipments (Trader view)
- [ ] Lists shipments linked to trader's orders
- [ ] Shipment status badge: PENDING / IN TRANSIT / DELIVERED
- [ ] Tap shipment → tracking modal with 5-step stepper

---

## Phase 3 — Buyer Flow

### 3.1 Browse listings
- [ ] Grid of available fish listings
- [ ] Filter chips (species, location) narrow results
- [ ] Tap listing → detail with **Place Order** button

### 3.2 Place order
- [ ] Fill quantity → confirm → order created → order appears in My Orders

### 3.3 Orders history
- [ ] Order list shows status PENDING / CONFIRMED / CANCELLED
- [ ] Tap order → detail with seller info

---

## Phase 4 — Transporter Flow

### 4.1 Available jobs
- [ ] Job cards load with route, weight, pay
- [ ] Status badge: OPEN / ACCEPTED / CLOSED
- [ ] **ACCEPT JOB** button text fully visible (not clipped)
- [ ] Tap **ACCEPT JOB** → spinner → badge changes → button becomes **VIEW ACTIVE JOB**
- [ ] Already-accepted job shows **VIEW ACTIVE JOB** in teal

### 4.2 Active job detail
- [ ] Tap **VIEW ACTIVE JOB** → detail sheet with pickup/dropoff
- [ ] Update status (PICKED UP, IN TRANSIT, DELIVERED)

---

## Phase 5 — Border Official Flow

### 5.1 Scanner
- [ ] QR scanner opens camera (requires camera permission)
- [ ] Scan a shipment QR → clearance record loads

### 5.2 Clearance dashboard
- [ ] Stats: pending, cleared, flagged counts
- [ ] List of recent clearances
- [ ] Flag/clear shipment → status updates

---

## Phase 6 — Dashboard (Admin Web)

Start: `cd jonglei-dashboard && npm run dev` → open `http://localhost:5173`

### 6.1 Auth
- [ ] Login with admin credentials → lands on Dashboard

### 6.2 Dashboard KPIs
- [ ] Revenue, Orders, Shipments, Users KPI cards populate
- [ ] Bento grid charts render (bar + line)

### 6.3 Listings page
- [ ] Table loads with species, seller, qty, price, status
- [ ] Click row → slide-out detail panel
- [ ] Sort by column header works

### 6.4 Orders page
- [ ] Table with order ID, buyer, amount, status
- [ ] Status badge colors correct (green/amber/red)

### 6.5 Shipments page
- [ ] Shipment list with tracking status
- [ ] Expand row → tracking events timeline

### 6.6 Analytics page
- [ ] Charts render with real or seeded data
- [ ] Date range selector updates chart

### 6.7 Users page
- [ ] User table with role badges
- [ ] Click user → slide-out profile panel

### 6.8 Sidebar & navigation
- [ ] Collapse sidebar → icons only, tooltips on hover
- [ ] Expand sidebar → labels visible
- [ ] Command palette: `Cmd+K` → type page name → Enter → navigates
- [ ] Notifications bell shows unread count badge
- [ ] Sign Out → redirects to login

---

## Phase 7 — API / Backend Smoke Tests

Run from terminal with backend running:

```bash
BASE=http://localhost:8000/api/v1

# Register
curl -X POST $BASE/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{"phone_number":"+211900000001","username":"TestUser","password":"pass1234","role":"TRADER","location":"Juba","preferred_language":"EN"}'

# Login
curl -X POST $BASE/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"phone_number":"+211900000001","password":"pass1234"}'
# → save access_token

# Listings (authenticated)
curl $BASE/marketplace/listings/ -H "Authorization: Bearer <access_token>"

# Orders
curl $BASE/marketplace/orders/ -H "Authorization: Bearer <access_token>"

# Shipments
curl $BASE/transport/shipments/ -H "Authorization: Bearer <access_token>"

# Notifications
curl $BASE/notifications/ -H "Authorization: Bearer <access_token>"
```

- [ ] Register returns 201 with user object
- [ ] Login returns access + refresh tokens
- [ ] Listings endpoint returns paginated results
- [ ] Token refresh: `POST /api/v1/auth/token/refresh/` with refresh token → new access token

---

## Phase 8 — Cross-Cutting Checks

### Theme consistency
- [ ] All screens use parchment `#F0EDE5` background (no leftover dark/blue screens)
- [ ] Primary teal `#0AB5A3` used for CTAs, active states, prices
- [ ] Burnt orange `#C4631A` used for secondary accents (role chips, sparklines)
- [ ] Status bar icons are dark on all screens (not invisible white-on-white)
- [ ] Fonts: DM Serif Display for headings, Outfit for UI, JetBrains Mono for prices/IDs

### Responsiveness
- [ ] Dashboard renders correctly at 1280px and 1440px widths
- [ ] Mobile app text does not overflow or clip in any card

### Error states
- [ ] No internet → app shows "Could not connect" or cached data
- [ ] Server 500 → app shows user-friendly error, not raw JSON
- [ ] Empty states → helpful message with action button

---

## Quick-Start Checklist

```
[ ] Backend:   cd jonglei-backend && python manage.py runserver 0.0.0.0:8000
[ ] Dashboard: cd jonglei-dashboard && npm run dev
[ ] Mobile:    flutter run (device connected)
[ ] Seed data: python manage.py loaddata fixtures/demo.json  (if available)
```

---

*Last updated: 2026-05-06*
