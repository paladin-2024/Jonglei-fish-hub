# Jonglei Fish Hub — Sprint Roadmap

> **Product:** Jonglei Fish Hub — a fish trading, logistics, and border-clearance platform for South Sudan's Jonglei State  
> **Stack:** Django 6 · DRF · PostgreSQL | Flutter (Provider) | React + Vite + Tailwind  
> **Design System:** Resilient Ledger — Teal `#005440` primary, Amber `#B45309` secondary, DM Serif Display / Outfit / JetBrains Mono  
> **Total sprints:** 6  
> **Start date:** 2026-05-02

---

## Sprint 1 — Foundation
**Goal:** Close the critical gap between the auth skeleton and a working trade flow. Three parallel tracks.

### Track A — Backend Core Models & URLs
| ID | Task |
|----|------|
| A1 | `marketplace`: `FishListing` model (UUID, seller FK, species, quantity_kg, price_ssp, unit, location, description, status `[DRAFT/ACTIVE/SOLD/REMOVED]`, created_at/updated_at) |
| A2 | `marketplace`: `Order` model (UUID, listing FK, buyer FK, quantity_kg, total_price, status `[PENDING/CONFIRMED/IN_TRANSIT/CLEARED/CANCELLED]`, note, timestamps) |
| A3 | `marketplace`: `ListingViewSet` + `OrderViewSet` with full CRUD + `confirm`, `cancel`, `ship` custom actions |
| A4 | `marketplace`: serializers + `apps/marketplace/urls.py` registered via DefaultRouter |
| A5 | `transport`: `Shipment` model (UUID, order FK, carrier name, origin, destination, status, progress 0–1, estimated_date) |
| A6 | `transport`: `TrackingEvent` model (shipment FK, stage `[LOADED/DEPARTED/EN_ROUTE/AT_CHECKPOINT/ARRIVED/DELIVERED]`, note, timestamp) |
| A7 | `transport`: `ShipmentViewSet` + `add_event` action + `apps/transport/urls.py` |
| A8 | `clearance`: `BorderClearance` model (UUID, shipment FK, checkpoint, officer FK, status `[PENDING/CLEARED/HELD]`, qr_code, cleared_at) |
| A9 | `clearance`: `BorderClearanceViewSet` + `scan_clear` POST action (takes `clearance_id`, marks CLEARED) + QR code generation on create |
| A10 | `clearance`: `apps/clearance/urls.py` |
| A11 | Expose `TokenRefreshView` at `api/v1/auth/token/refresh/` in `apps/accounts/urls.py` |
| A12 | Wire all 3 new apps into `core/urls.py` |

### Track B — Flutter Profile Screen Redesign
| ID | Task |
|----|------|
| B1 | Remove `LinearGradient` from `SliverAppBar` — replace with flat `AppColors.surface` header |
| B2 | Remove all hardcoded `Color(0xFF...)` and `TextStyle()` — apply `AppColors.*` and `AppTextStyles.*` throughout |
| B3 | Replace `SliverAppBar(expandedHeight: 200)` with a static `SliverToBoxAdapter` header block |
| B4 | Add DM Serif Display editorial heading + LABEL sub-caption |
| B5 | Add `_StatRow` — 3 horizontal stat chips (Total Trades, Rating, Member Since) |
| B6 | Convert `_InfoCard` border to shadowless `AppColors.surfaceHigh` background, no `Border.all` |
| B7 | Style Edit Profile button as outlined teal; Sign Out as danger-tinted flat surface button |

### Track C — Dashboard Listings Page
| ID | Task |
|----|------|
| C1 | Create `src/pages/Listings.jsx` — fish listings management page |
| C2 | 4 KPI cards: Total Listings, Active, Sold Out, Total Value (same card pattern as Orders.jsx) |
| C3 | Search + filter pills (`ALL / ACTIVE / DRAFT / SOLD / REMOVED`) |
| C4 | Dense table: Fish species, Qty (kg), Price (SSP/kg), Seller, Location, Status badge, Listed date |
| C5 | Slide-out detail panel (right side, 320px) showing full listing info + FEATURE / REMOVE actions |
| C6 | Register `/listings` route in `App.jsx` and add sidebar link |

---

## Sprint 2 — Trade Flow
**Goal:** End-to-end listing creation → order placement flow functional on mobile.

### Track A — Backend Enhancements
| ID | Task |
|----|------|
| A1 | SMS OTP via Africa's Talking API (phone verification on register) |
| A2 | `django-storages` + Cloudflare R2 for listing photo uploads |
| A3 | `FishListing` photo field (image URL stored after R2 upload) |
| A4 | Pagination: `LimitOffsetPagination` default 20/page on all ViewSets |
| A5 | Search + filter params: listings by species, location, price range |
| A6 | `OrderViewSet.my_orders` action — buyer's own orders filtered by status |

### Track B — Flutter New Screens
| ID | Task |
|----|------|
| B1 | `CreateListingScreen` — multi-step: (1) Fish details (species, qty, price) → (2) Location → (3) Photo → (4) Review & publish |
| B2 | `BrowseListingsScreen` (Buyer) — card grid with species image, price/kg chip, seller info, distance |
| B3 | `OrderPlacementSheet` — bottom modal: quantity slider, total SSP preview, "Place Order" CTA |
| B4 | `OrdersScreen` (Buyer) — list view of buyer's orders with status |
| B5 | JWT refresh interceptor in `ApiService` — on 401, call `/auth/token/refresh/`, store new token, retry original request |
| B6 | `connectivity_plus` offline banner — persistent amber bar when no network |

### Track C — Dashboard Enhancements
| ID | Task |
|----|------|
| C1 | Wire `Listings.jsx` to real API (`GET /api/v1/marketplace/listings/`) |
| C2 | Wire `Orders.jsx` to real API (`GET /api/v1/marketplace/orders/`) |
| C3 | Add `Users.jsx` page — user management table with role filter, verification toggle |
| C4 | Dashboard `Overview.jsx` — pull real aggregate stats from API |

---

## Sprint 3 — Logistics & Clearance
**Goal:** Transport jobs flow; border clearance with QR scanning fully operational.

### Track A — Backend
| ID | Task |
|----|------|
| A1 | `TransportJob` model — open jobs that transporters can claim (linked to confirmed Order) |
| A2 | `TransportJobViewSet` with `accept_job`, `start_transit`, `deliver` actions |
| A3 | FCM push notification on order status change (Celery task) |
| A4 | QR code image endpoint: `GET /api/v1/clearance/{id}/qr/` returns PNG |
| A5 | `django-filter` FilterBackend on all ViewSets |

### Track B — Flutter New Screens
| ID | Task |
|----|------|
| B1 | `AvailableJobsScreen` (Transporter) — list of open transport jobs with route, cargo, pay |
| B2 | `ActiveJobScreen` (Transporter) — live progress tracker, "Mark Delivered" CTA |
| B3 | `ClearanceQueueScreen` (Border Official) — pending clearances at checkpoint |
| B4 | `ScanClearScreen` (Border Official) — QR scanner → confirm clearance modal |
| B5 | In-app notification center — `NotificationScreen` with unread badge on nav tab |
| B6 | FCM token registration in app init |

### Track C — Dashboard
| ID | Task |
|----|------|
| C1 | `Shipments.jsx` page — table matching mobile shipments data |
| C2 | `Clearance.jsx` page — border clearance queue with CLEAR action button |
| C3 | `PriceMonitor.jsx` — species price history chart (Recharts AreaChart) with date range selector |
| C4 | Real-time order status update via polling (5-second interval on active orders) |

---

## Sprint 4 — Full API Integration
**Goal:** Replace every static `const` data array in Flutter and Dashboard with live API calls.

### Track A — Backend
| ID | Task |
|----|------|
| A1 | `GET /api/v1/marketplace/prices/` — aggregated price data per species per date |
| A2 | `GET /api/v1/dashboard/stats/` — admin aggregate endpoint (total users, listings, orders, revenue) |
| A3 | Redis cache layer on stats and price endpoints (5-minute TTL) |
| A4 | `UserActivity` logging middleware |

### Track B — Flutter
| ID | Task |
|----|------|
| B1 | Wire `TraderHomeScreen` dashboard stats to `GET /api/v1/dashboard/stats/` |
| B2 | Wire `ShipmentsScreen` to `GET /api/v1/transport/shipments/?buyer=me` |
| B3 | Wire `PricesScreen` to `GET /api/v1/marketplace/prices/` |
| B4 | Wire `TrackingSheet` to `GET /api/v1/transport/shipments/{id}/events/` |
| B5 | Skeleton loading screens (shimmer effect) on all list/feed screens |
| B6 | `hive` local cache — store last-fetched listings + prices for offline read |

### Track C — Dashboard
| ID | Task |
|----|------|
| C1 | Wire all dashboard KPI cards to `GET /api/v1/dashboard/stats/` |
| C2 | Wire `PriceMonitor.jsx` to `GET /api/v1/marketplace/prices/` |
| C3 | Wire `Users.jsx` to `GET /api/v1/auth/users/` |
| C4 | Add loading skeletons + error states to every page |

---

## Sprint 5 — Trust, Community & Enrichment
**Goal:** Add the social/trust layer that makes the platform sticky and reliable.

### Features
| ID | Feature |
|----|---------|
| F1 | **Rating & Review system** — buyers rate sellers post-delivery; 5-star + comment |
| F2 | **Dispute Resolution** — "Flag this order" CTA → dispute ticket → admin review queue |
| F3 | **Fish Species Encyclopedia** — static data page: species name (EN/DIN), habitat, peak season, avg price |
| F4 | **Seasonal Calendar** — heatmap calendar showing best fishing months per species |
| F5 | **Cooperative Accounts** — group account type, shared wallet balance |
| F6 | **WhatsApp deep-link** — "Contact via WhatsApp" on every listing / job card |
| F7 | **Photo support** — `image_picker` on Create Listing; `cached_network_image` in listing cards |
| F8 | **Price sparklines** on Prices screen — 7-day mini chart per species tile |
| F9 | **Arabic / Dinka language toggle** — `flutter_localizations` scaffolding |
| F10 | **Dashboard Audit Log** — admin page showing all state-change events |

---

## Sprint 6 — Production Hardening
**Goal:** The app is deployable, observable, and secure.

### Infrastructure
| ID | Task |
|----|------|
| I1 | `Dockerfile` + `docker-compose.yml` (Django + PostgreSQL + Redis) |
| I2 | GitHub Actions CI — lint + test on every PR |
| I3 | `Gunicorn` + `Nginx` config for production |
| I4 | Celery + Beat worker for async tasks (FCM, SMS, cache refresh) |
| I5 | `django-ratelimit` on auth endpoints (login: 10/min, register: 5/min) |
| I6 | Env-only `SECRET_KEY`, `ALLOWED_HOSTS`, `DATABASE_URL` — no hardcoded secrets |
| I7 | `SECURE_HSTS_SECONDS`, `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE` in production settings |
| I8 | `sentry-sdk` error tracking |
| I9 | Health check endpoint `GET /api/v1/health/` → `{"status": "ok"}` |
| I10 | TimescaleDB extension — convert price history table to hypertable |
| I11 | PostGIS extension — add `Point` field to `FishListing` for geospatial queries |
| I12 | Automated DB backups via pg_dump cron |

---

## Feature Backlog (Post-MVP)
Items from the full catalog deferred beyond Sprint 6:

- **USSD gateway** — `*123#` basic menu for feature phones (no internet required)
- **WhatsApp bot** — automated listing lookup + price query via WhatsApp Business API
- **AI demand forecasting** — predict peak demand by species + location using historical order data
- **Fish Quality Grading** — photo upload → ML grade (A/B/C) suggestion
- **Cold Chain Monitoring** — temperature sensor IoT integration via MQTT
- **Auction Module** — time-limited bidding on large catches
- **Fishing Permits** — digital permit issuance by Ministry of Fisheries officials
- **Buyer Demand Posting** — reverse marketplace (buyer posts need, traders respond)
- **Price Intelligence Crowdsourcing** — field agents submit spot prices at landing sites
- **Mobile Money (MTN/Airtel)** — in-app payment disbursement
- **Landing Site Registry** — GPS-tagged database of all Jonglei fishing sites
- **Freshness Timer** — countdown on listings based on catch date + fish type
