---
name: KDMP Design System
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#5e3f3c'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#936e6a'
  outline-variant: '#e8bcb8'
  surface-tint: '#c00016'
  primary: '#ab0013'
  on-primary: '#ffffff'
  primary-container: '#d9001b'
  on-primary-container: '#ffe9e6'
  inverse-primary: '#ffb4ac'
  secondary: '#5d5f5f'
  on-secondary: '#ffffff'
  secondary-container: '#dfe0e0'
  on-secondary-container: '#616363'
  tertiary: '#705d00'
  on-tertiary: '#ffffff'
  tertiary-container: '#c9a900'
  on-tertiary-container: '#4c3f00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad6'
  primary-fixed-dim: '#ffb4ac'
  on-primary-fixed: '#410003'
  on-primary-fixed-variant: '#93000e'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c7'
  on-secondary-fixed: '#1a1c1c'
  on-secondary-fixed-variant: '#454747'
  tertiary-fixed: '#ffe16d'
  tertiary-fixed-dim: '#e9c400'
  on-tertiary-fixed: '#221b00'
  on-tertiary-fixed-variant: '#544600'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container-max: 1280px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style
The brand identity for this design system centers on trust, accessibility, and modern cooperative commerce. It bridges the gap between traditional community-based cooperatives and high-efficiency digital fintech. 

The aesthetic is **Corporate / Modern** with a heavy influence from **Minimalism**. The UI is characterized by generous whitespace, high-contrast typography, and a refined retail sensibility. The emotional goal is to evoke a sense of reliability and progress, ensuring members feel their assets are managed with professional-grade technology while remaining approachable for everyday village commerce.

## Colors
This design system utilizes a high-impact palette to drive clarity and brand recognition:
- **Primary Red (#D9001B):** Used for critical actions, branding, and primary buttons. It signals energy and urgency.
- **Pure White (#FFFFFF):** The primary surface color for cards and containers to maintain a clean "retail" look.
- **Soft Gray (#F8F9FA):** Used as the global background to provide a soft contrast against white card elements.
- **Membership Gold (#FFD700):** Reserved exclusively for loyalty status, points, and premium membership indicators.
- **Growth Green (#28A745):** Utilized for positive stock indicators, successful transaction states, and balance increases.

## Typography
The system relies on **Inter** to deliver a neutral, highly legible experience across both fintech data and retail product listings. 
- **Headlines:** Use Bold weights with slight negative letter-spacing for a modern, "app-first" feel.
- **Price Displays:** Utilize `title-lg` or `headline-md` with semi-bold weights to ensure financial figures are the first thing a user sees.
- **Accessibility:** Maintain a minimum body size of 14px for general text and 12px for secondary labels to ensure readability for all cooperative members.

## Layout & Spacing
The layout follows a **Fluid Grid** model with fixed-width constraints for desktop.
- **Mobile (up to 600px):** 4-column grid with 16px margins. Uses a **Bottom Navigation** for primary app-like reachability.
- **Tablet (601px - 1024px):** 8-column grid with 24px margins. Content reflows into dual-column cards.
- **Desktop (1025px+):** 12-column grid. Uses a **Persistent Sidebar** for navigation. The main content area has a max-width of 1280px, centered on the screen.
- **Spacing Rhythm:** Based on a 4px baseline. Components primarily use 16px (md) and 24px (lg) for internal padding to maintain the spacious "clean retail" aesthetic.

## Elevation & Depth
This design system uses **Tonal Layers** combined with **Ambient Shadows** to create a structured hierarchy.
- **Level 0 (Background):** Soft Gray (#F8F9FA). No shadow.
- **Level 1 (Cards):** Pure White (#FFFFFF). A very soft, diffused shadow (0px 4px 12px rgba(0,0,0,0.05)) is used to separate cards from the background.
- **Level 2 (Modals/Overlays):** White surface with a more pronounced shadow (0px 12px 24px rgba(0,0,0,0.08)) to indicate interaction priority.
- **Interactive Elements:** Buttons and clickable cards use a subtle "lift" effect on hover, increasing shadow depth slightly to provide tactile feedback.

## Shapes
In line with the friendly yet professional cooperative identity, the design system employs **Rounded (0.5rem / 8px)** as the base corner radius for small components like buttons and inputs. 

For larger layout containers and surface elements:
- **Cards:** Use `rounded-lg` (16px) or `rounded-xl` (24px) to create a soft, modern "fintech" container feel.
- **Buttons:** Standard buttons use 8px, while "Action Pills" (like category filters) use a full pill-shape.
- **Product Images:** Always clipped to the container's radius to maintain visual consistency.

## Components
- **Membership/Balance Cards:** The primary dashboard feature. High-contrast (Primary Red background or Gold gradients) with 24px corner radius. Includes quick-action icons for "Top Up" or "Pay."
- **Product Cards:** White background, 16px radius, subtle border (#E9ECEF). Price is displayed in `headline-md` Primary Red. CTA buttons are full-width within the card.
- **Buttons:**
  - *Primary:* Solid Primary Red, White text, 8px radius.
  - *Secondary:* White background, Primary Red border and text.
  - *Success:* Solid Green for final "Complete Transaction" steps.
- **Bottom Navigation (Mobile):** Fixed at the bottom, blurred background (glassmorphism optional) or solid white. Icons use Primary Red for active states.
- **Sidebar (Desktop):** Clean, vertical list with 16px horizontal padding. Active states use a "Left-border" indicator in Primary Red.
- **Input Fields:** 8px radius, Soft Gray background (#F1F3F5) with a 1px border that turns Primary Red on focus.
- **Chips/Status:** Small pill-shaped badges for "In Stock" (Green) or "Limited" (Gold).