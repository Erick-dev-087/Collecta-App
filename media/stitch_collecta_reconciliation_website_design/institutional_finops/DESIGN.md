---
name: Institutional FinOps
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#3f4940'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#6f7a70'
  outline-variant: '#bec9be'
  surface-tint: '#0b6d3b'
  primary: '#004d27'
  on-primary: '#ffffff'
  primary-container: '#006837'
  on-primary-container: '#8ee4a6'
  inverse-primary: '#83d99c'
  secondary: '#006c46'
  on-secondary: '#ffffff'
  secondary-container: '#3ffdae'
  on-secondary-container: '#007149'
  tertiary: '#003a9f'
  on-tertiary: '#ffffff'
  tertiary-container: '#004fd1'
  on-tertiary-container: '#c4d0ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#9ef6b6'
  primary-fixed-dim: '#83d99c'
  on-primary-fixed: '#00210e'
  on-primary-fixed-variant: '#00522a'
  secondary-fixed: '#4dffb2'
  secondary-fixed-dim: '#00e297'
  on-secondary-fixed: '#002112'
  on-secondary-fixed-variant: '#005234'
  tertiary-fixed: '#dbe1ff'
  tertiary-fixed-dim: '#b4c5ff'
  on-tertiary-fixed: '#00174b'
  on-tertiary-fixed-variant: '#003ea8'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
  emerald-deep: '#006837'
  emerald-hover: '#00522B'
  mint-neon: '#00E599'
  mint-surface: '#ECFDF5'
  slate-ink: '#0F172A'
  slate-subtle: '#64748B'
  slate-border: '#E2E8F0'
  surface-canvas: '#F8FAFC'
  surface-panel: '#FFFFFF'
  status-matched-bg: '#ECFDF5'
  status-matched-text: '#047857'
  status-pending-bg: '#EFF6FF'
  status-pending-text: '#1D4ED8'
  status-discrepancy-bg: '#FEF2F2'
  status-discrepancy-text: '#B91C1C'
  status-settled-bg: '#F8FAFC'
  status-settled-text: '#334155'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
    letterSpacing: -0.03em
  headline-xl-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.025em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.025em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.015em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
    letterSpacing: -0.01em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: -0.005em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.04em
  currency-display:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 44px
    letterSpacing: -0.03em
  tabular-mono:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.5rem
  gutter-mobile: 0.75rem
  margin: 2rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system embodies high-integrity financial operations engineered for institutions, NGOs, foundations, and community chamas. It merges the unwavering solidity and security of institutional grade banking with the responsive, high-velocity clarity of modern developer-first financial tooling. 

The aesthetic is precision-driven, functional corporate modernity paired with razor-sharp data legibility. Whitespace is deliberate and structured, signaling audit-grade transparency and control. Visual hierarchy relies on dense tabular clarity, crisp status badges, and authoritative typography rather than ornamental clutter. Users should feel complete fiduciary peace of mind, unshakeable control over multi-party receivables, and immediate operational speed during automated STK Push flows and reconciliation sweeps.

## Colors

The palette establishes an immediate fiduciary impression through deep institutional emerald (`#006837`) as the anchor of trust, reinforced by deep slate neutral tones (`#0F172A`). Energetic mint (`#00E599`) provides instantaneous operational feedback for automated triggers, active ledger sweeps, and confirmation pulses.

Reconciliation requires unequivocal clarity. Status color semantics are absolute and unmixed:
- **Matched & Reconciled:** Soft emerald surface (`#ECFDF5`) paired with deep forest green text (`#047857`).
- **Pending STK:** Trust blue backdrop (`#EFF6FF`) with indigo-cobalt text (`#1D4ED8`), signifying ongoing asynchronous verification.
- **Discrepancy / Exception:** Pale coral tint (`#FEF2F2`) with structured crimson text (`#B91C1C`), highlighting reconciliation mismatches without alarming panic.
- **Settled / Archived:** Grounded slate-tinted surface (`#F8FAFC`) with deep steel slate text (`#334155`).

Background canvas is kept clean and crisp (`#F8FAFC`) to maximize contrast against white workspace cards and deep-ink data tables.

## Typography

The type system blends the authoritative, structural presence of **Plus Jakarta Sans** for headlines and high-level financial figures with the clinical precision of **Inter** for dense transactional ledgers and operational inputs.

- **Financial figures and ledgers:** All tabular views, monetary values, and timestamp feeds must enforce `font-feature-settings: "tnum" 1, "cv05" 1` (tabular figures and slashed zero) on Inter, ensuring absolute numerical alignment across thousands of rows.
- **Headings & Key Metrics:** Plus Jakarta Sans is deployed with tight tracking (`-0.02em` to `-0.03em`) and heavy weights (700/800) to deliver unyielding institutional posture.
- **Micro-labels and Status Tags:** Defined in compact uppercase or semi-bold title case with widened letter spacing (`+0.02em` to `+0.04em`) to ensure legibility when rendered inside badges and data table column headers.

## Layout & Spacing

A disciplined 8-point baseline grid governs this design system. Dashboard layouts leverage a 12-column responsive fluid grid with fixed outer gutters and margins designed to scale seamlessly from dense executive desktops down to mobile field-audits.

- **Desktop (1280px+):** Max-width containment at `1440px` with `2rem` (32px) margins and `1.5rem` (24px) gutters. Complex ledger tables span 12 columns, while split-screen reconciliation inspection views occupy an 8/4 asymmetrical split.
- **Tablet (768px – 1024px):** 8-column layout with `1.5rem` margins and `1rem` gutters. Metric cards collapse to 2x2 grids; secondary audit sidebars become sliding drawer sheets.
- **Mobile (< 768px):** 4-column layout with `1rem` margin and `0.75rem` gutter. Data tables switch to stacked card feeds, and high-frequency actions (such as "Initiate STK Push") become docked bottom sheets.

## Elevation & Depth

Visual hierarchy is maintained via clean planar surfaces and calibrated, tinted ambient shadows that eliminate harshness while maintaining clear boundary definitions between cards, overlays, and tables.

- **Base Layer (Level 0):** Background surface in `#F8FAFC`.
- **Card / Surface Layer (Level 1):** Solid white surface (`#FFFFFF`) with a 1px border (`#E2E8F0`) and an ambient, slate-tinted shadow: `0 1px 3px 0 rgba(15, 23, 42, 0.04), 0 1px 2px -1px rgba(15, 23, 42, 0.03)`.
- **Interactive Hover & Dropdowns (Level 2):** Elevated interactive elements receive `0 10px 15px -3px rgba(15, 23, 42, 0.06), 0 4px 6px -4px rgba(15, 23, 42, 0.04)` with a crisp `#CBD5E1` border stroke.
- **Modals, Drawer Panels, and STK Trigger Sheets (Level 3):** Fixed overlays float over a darkened slate veil (`rgba(15, 23, 42, 0.6)`) with `0 20px 25px -5px rgba(15, 23, 42, 0.1), 0 8px 10px -6px rgba(15, 23, 42, 0.08)`.
- **Primary Action Pulse:** Interactive primary buttons and active automation toggles use a subtle glow ring: `0 0 0 3px rgba(0, 229, 153, 0.25)`.

## Shapes

The geometric architecture uses balanced medium corner rounding (`roundedness: 2`, base `0.5rem` / `8px`). This level bridges institutional bank reliability with responsive SaaS usability.

- **Inputs, Buttons, and Table Headers:** Fixed at `0.5rem` (8px) for structural alignment and crisp form completion.
- **Container Panels, Overview Cards, & Dialogs:** `rounded-lg` (`1rem` / 16px) creates a clear distinction between internal controls and outer structural cards.
- **Status Pills, Reconciliation Chips, and Metric Badges:** Always `rounded-full` (`9999px`) to create an immediate shape-distinction between clickable rectangular controls and informative categorical badges.

## Components

### Buttons
- **Primary:** Deep institutional forest green (`#006837`) background, text in `#FFFFFF`, font weight 600. Includes an integrated rightward action icon (e.g. arrow or check). Hover state: `#00522B` with a subtle elevation shift. Focus ring: `3px solid #00E599`.
- **Secondary (Outlined):** White background, border `1.5px solid #E2E8F0`, text in slate-ink (`#0F172A`). Hover state: background `#F8FAFC`, border `#CBD5E1`.
- **Accent (STK Action):** Energetic mint (`#00E599`) background with slate-ink (`#0F172A`) bold text for real-time mobile push execution.

### Reconciliation Status Pills
Rendered as compact inline chips (`height: 24px`, padding `0.25rem 0.625rem`, `rounded-full`, typography `label-sm` with tabular figures):
- **Matched:** Background `#ECFDF5`, text `#047857`, preceded by an SVG dot or checkmark.
- **Pending STK:** Background `#EFF6FF`, text `#1D4ED8`, preceded by a rotating pulse beacon.
- **Discrepancy:** Background `#FEF2F2`, text `#B91C1C`, accompanied by an alert icon and deviation counter.
- **Settled:** Background `#F1F5F9`, text `#475569`, border `1px solid #E2E8F0`.

### Data Tables (The Reconciliation Ledger)
- **Header:** Background `#F8FAFC`, bottom border `1px solid #E2E8F0`. Column titles in `label-sm` slate `#64748B` uppercase with sort indicators.
- **Rows:** Alternating subtle hover state (`#F8FAFC`). Height `48px` default or `40px` compact mode. Numerical entries formatted with `tabular-mono`. Discrepant rows highlight with a left accent border (`3px solid #EF4444`).

### Form Inputs & Payment Link Builder
- **Text Inputs & Currency Fields:** Background `#FFFFFF`, 1px border `#CBD5E1`, border-radius `0.5rem`, padding `0.625rem 0.875rem`. Left-adorned currency labels (`KES`, `USD`) pinned inside a light slate box. Active state triggers a `#006837` border and `#00E599` ambient ring.
- **Checkboxes & Radios:** Size `18px`, border `1.5px solid #94A3B8`, rounded `4px` (checkbox) or `rounded-full` (radio). Checked state fills `#006837` with a crisp white tick.

### M-Pesa STK Push Integration Modal / Card
- Dedicated component displaying:
  1. Phone input field formatted with carrier flag and prefix (`+254`).
  2. Amount preset chips (`KES 500`, `1,000`, `5,000`, `Custom`).
  3. Real-time status pipeline showing 3-step vertical progress: *Request Dispatched* -> *PIN Handshake* -> *Ledger Matched*.
  4. Animated mint beacon ring denoting real-time socket connection.