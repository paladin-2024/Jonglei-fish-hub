# Napkin Runbook — Jonglei Fish Hub

## Curation Rules
- Re-prioritize on every read.
- Keep recurring, high-value notes only.
- Max 10 items per category.
- Each item includes date + "Do instead".

## Execution & Validation (Highest Priority)

1. **[2026-05-06] Django 6.0.4 CheckConstraint uses `condition=` not `check=`**
   Do instead: always write `models.CheckConstraint(condition=models.Q(...), name=...)`.

2. **[2026-05-06] PostGIS removed — use standard postgres backend**
   Do instead: ENGINE = `django.db.backends.postgresql`; use FloatField(latitude/longitude) not PointField.

3. **[2026-05-06] Migrations order: 0002 coords+price_history → 0003 SellerRating+photo**
   Do instead: never skip; run `python manage.py migrate` from jonglei-backend/.

## Shell & Command Reliability

1. **[2026-05-06] pg port is 5433 (not default 5432)**
   Do instead: always pass `-p 5433` to psql/pg_dump commands; DB_PORT=5433 in .env.

2. **[2026-05-06] DB name=jonglei_fish_hub, user=jonglei_admin, pw=jonglei2024**
   Do instead: use these creds for DBeaver / psql connections.

## Domain Behavior Guardrails

1. **[2026-05-06] Cinema Dark design system**
   bgDeep=#060C18, bgBase=#0B1629, bgElevated=#111E38; primary=teal #0DCFBA; secondary=amber #F59E0B.
   Do instead: never use light backgrounds; always apply these tokens in both Flutter and React.

2. **[2026-05-06] Font stack: DM Serif Display (headings) / Outfit (UI) / JetBrains Mono (data/prices)**
   Do instead: import all three from Google Fonts; never substitute system fonts.

## User Directives

1. **[2026-05-06] Primary brand color = electric teal #0DCFBA (NOT amber)**
   Do instead: teal is `--primary`/`AppColors.primary`, amber `#F59E0B` is `--secondary`/`AppColors.secondary`. Never swap.

2. **[2026-05-06] Use ui-ux-pro-max + 21st.dev inspiration for all UI work**
   Do instead: invoke `ui-ux-pro-max` skill for every UI overhaul; aim for top-tier demo-ready quality.

3. **[2026-05-06] Flutter CardTheme → CardThemeData in newer Flutter**
   Do instead: always use `CardThemeData(...)` inside `ThemeData`, never `CardTheme(...)`.

4. **[2026-05-06] React + Flutter color system fully corrected as of session 2**
   Do instead: index.css `--primary=#0DCFBA`, Flutter AppColors.primary=teal. All screens updated. Clearance "CLEARED" uses primary (teal), not secondary.
