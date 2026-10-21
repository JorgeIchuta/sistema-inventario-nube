---
name: Inventario Cloud System
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#444651'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#757682'
  outline-variant: '#c5c5d3'
  surface-tint: '#4059aa'
  primary: '#00236f'
  on-primary: '#ffffff'
  primary-container: '#1e3a8a'
  on-primary-container: '#90a8ff'
  inverse-primary: '#b6c4ff'
  secondary: '#0058be'
  on-secondary: '#ffffff'
  secondary-container: '#2170e4'
  on-secondary-container: '#fefcff'
  tertiary: '#00311f'
  on-tertiary: '#ffffff'
  tertiary-container: '#004a31'
  on-tertiary-container: '#27c38a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b6c4ff'
  on-primary-fixed: '#00164e'
  on-primary-fixed-variant: '#264191'
  secondary-fixed: '#d8e2ff'
  secondary-fixed-dim: '#adc6ff'
  on-secondary-fixed: '#001a42'
  on-secondary-fixed-variant: '#004395'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-xl:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 14px
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style
The brand personality is professional, efficient, and reliable. It aims to evoke a sense of organized control and technological modernization for businesses managing physical assets.

The design style follows a **Corporate / Modern** aesthetic. It prioritizes clarity and functional density without feeling cluttered. The interface utilizes a "Safe & Secure" visual language: high legibility, structured layouts, and purposeful use of color to indicate status and action. The emotional response should be one of confidence and ease, transforming a complex task like inventory management into a streamlined digital experience.

## Colors
This design system utilizes a structured hierarchy of blues to establish authority and trust.

- **Primary (#1E3A8A):** Used for navigation backgrounds (sidebar), primary actions, and brand identification.
- **Secondary (#3B82F6):** Used for interactive elements, links, and highlighting active states.
- **Success (#10B981):** Reserved for "In Stock" indicators, completed transactions, and positive growth metrics.
- **Warning (#F59E0B):** Used for "Low Stock" alerts and pending actions.
- **Danger (#EF4444):** Used for "Out of Stock" alerts, deletions, and critical errors.
- **Neutrals:** A range of Slate grays are used for text and borders to maintain a soft, professional contrast against the white surfaces.

## Typography
The system uses **Hanken Grotesk** as the primary typeface for its clean, contemporary grotesk look that performs exceptionally well in data-heavy SaaS environments.

- **Headlines:** Use Bold or SemiBold weights to create clear information hierarchy.
- **Body:** Regular weight for standard text; Medium weight for emphasis within data rows.
- **Labels (SKUs/Data):** **JetBrains Mono** is introduced for specific technical identifiers like SKU numbers, quantities, and barcodes to ensure character distinction (e.g., distinguishing between '0' and 'O').
- **Spanish Localization:** Ensure line heights account for common Spanish diacritics (á, é, í, ó, ú, ñ) to prevent clipping in dense tables.

## Layout & Spacing
The layout relies on a **Fluid Grid** for content areas and a **Fixed Sidebar** for desktop navigation.

- **Desktop (1280px+):** 12-column grid. Features a 280px persistent left sidebar. Data is primarily displayed in high-density tables with 12px vertical padding per row.
- **Tablet (600px - 960px):** 8-column grid. Sidebar collapses into an icon-only rail or hidden drawer.
- **Mobile (<600px):** 4-column grid. Navigation shifts to a **Bottom Navigation Bar** for primary views and a **Bottom Drawer** for secondary actions. Content shifts from tables to "Data Cards" to ensure legibility.
- **Rhythm:** All spacing must be multiples of 8px to maintain a strict visual alignment.

## Elevation & Depth
This design system uses **Tonal Layers** supplemented by **Ambient Shadows** to define the z-axis.

1.  **Level 0 (Canvas):** The background (#F8FAFC).
2.  **Level 1 (Surface):** White cards and table containers. Uses a very soft, diffused shadow: `0px 4px 12px rgba(30, 58, 138, 0.05)`.
3.  **Level 2 (Interaction/Hover):** Applied to cards on hover or active dropdowns. The shadow intensifies: `0px 8px 24px rgba(30, 58, 138, 0.1)`.
4.  **Level 3 (Modals/Drawers):** Highest elevation. Uses a backdrop blur (8px) on the canvas and a deep shadow: `0px 12px 32px rgba(0, 0, 0, 0.15)`.

Borders are used sparingly, primarily as low-contrast dividers (#E2E8F0) in tables and lists.

## Shapes
The shape language is "Approachable Professional." 

- **Standard Elements:** Buttons, Input Fields, and Cards use a **8px (0.5rem)** radius to feel modern but structured.
- **Large Containers:** Dashboard widgets and main content areas use **16px (1rem)** for `rounded-lg`.
- **Search Bars:** Utilize a semi-pill shape (24px radius) to distinguish them from data entry fields.
- **Badges/Status Indicators:** Fully pill-shaped for immediate recognition as a non-clickable status label.

## Components

- **Buttons:** 
  - *Primary:* Solid #1E3A8A with white text.
  - *Secondary:* Outline #3B82F6 with 1px border.
  - *Ghost:* No background, neutral text for "Cancelar" or "Cerrar" actions.
- **Search Bars:** High-visibility, positioned at the top of every list. Include a persistent "Magnifying Glass" icon and a "Filtrar" (Filter) button.
- **Data Tables (Desktop):** Sticky headers, zebra-striping (very faint gray), and right-aligned numerical columns. Use JetBrains Mono for SKU and Quantity columns.
- **Inventory Cards (Mobile):** Replace table rows. Header shows Product Name, Sub-header shows SKU. A prominent "Badge" in the top right shows stock status (Green/Yellow/Red).
- **Status Chips:** Small, pill-shaped labels. Example: "En Stock" (Green), "Stock Bajo" (Yellow), "Agotado" (Red).
- **Input Fields:** Focused state uses a 2px #3B82F6 border with a soft blue outer glow. Labels are always visible above the field (not floating) for speed of data entry.
- **Bottom Navigation (Mobile):** 4-5 items: Inicio, Inventario, Escáner (Center Highlighted), Pedidos, Más.