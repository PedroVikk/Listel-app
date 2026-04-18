# Design System Strategy: The Digital Atelier

## 1. Overview & Creative North Star
**Creative North Star: "The Curated Gallery"**
This design system moves away from the utilitarian "database" feel of traditional wishlist apps and moves toward an editorial, boutique experience. By combining high-end typography scales with a "soft-layering" philosophy, we transform a simple list into a personal curation. 

The system breaks the standard mobile template by utilizing **intentional asymmetry** (e.g., uneven grid heights for list categories) and **tonal depth**. We treat the mobile screen not as a flat surface, but as a series of physical, semi-translucent layers that invite the user to touch, organize, and dream.

---

## 2. Colors: Tonal Depth & Vibrancy
The palette is anchored by a vibrant, sophisticated `primary` red-pink, supported by a rich ecosystem of pastel neutrals that provide a "skin-care brand" aesthetic—clean, premium, and calming.

### The "No-Line" Rule
**Strict Mandate:** Designers are prohibited from using 1px solid borders to section off content. Structural boundaries must be defined exclusively through background color shifts. 
- A card should never have a gray border; it should be a `surface-container-lowest` element sitting on a `surface` background.
- Use the `surface-container` tiers to denote hierarchy. The deeper the content (e.g., a nested comment or secondary detail), the higher the container tier.

### The "Glass & Gradient" Rule
To move beyond "out-of-the-box" Flutter looks, floating elements—such as bottom sheets or navigation bars—must utilize **Glassmorphism**.
- **Token:** `surface-container-low` at 70% opacity with a 20px Backdrop Blur.
- **CTAs:** Main action buttons should not be flat. Apply a subtle linear gradient from `primary` (#b90034) to `primary_container` (#ff7480) at a 135-degree angle to add "soul" and dimension.

---

## 3. Typography: Editorial Authority
We utilize a dual-typeface system to balance high-end personality with extreme readability.

*   **Display & Headlines (Plus Jakarta Sans):** Chosen for its modern, slightly geometric "friendly" terminals. Use `display-lg` for empty states and `headline-md` for list titles to create a bold, editorial impact.
*   **Body & Labels (Inter):** The workhorse for the wishlist experience. Inter provides the clarity needed for item descriptions and prices.
*   **Hierarchy Note:** Always lead with high contrast. A `headline-lg` in `on_surface` should be immediately followed by a `body-md` in `on_surface_variant` to create clear visual breathing room.

---

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are often messy. This system uses **Ambient Tonal Layering**.

*   **The Layering Principle:** Place a `surface-container-lowest` (pure white) card on a `surface` background for a natural, soft lift. This "white-on-pastel" look is the hallmark of premium modern UI.
*   **Ambient Shadows:** For high-priority floating elements (like the 'Add' FAB), use a "Tinted Shadow." Instead of black, the shadow should use the `primary` color at 8% opacity with a 32px blur and a 12px Y-offset.
*   **The "Ghost Border" Fallback:** If accessibility requires a border (e.g., in high-contrast mode), use `outline_variant` at **15% opacity**. Never use a 100% opaque border.
*   **Frosted Glass:** Use `surface_bright` with semi-transparency for top app bars, allowing the colorful wishlist items to softly bleed through as the user scrolls.

---

## 5. Components: Softness & Intent

### Buttons
*   **Primary:** Rounded `full` (pill-shaped). Uses the primary gradient.
*   **Secondary:** `surface-container-high` background with `primary` text. No border.
*   **Tertiary:** Transparent background, `primary` text, bold weight.

### Input Fields
*   **Style:** Forgo the "underlined" look. Use a filled `surface-container-low` with a `lg` (2rem) corner radius. 
*   **Active State:** On focus, the background shifts to `surface-container-highest` with a "Ghost Border" of the `primary` color.

### Cards & Lists
*   **Strict Rule:** No divider lines between list items. Use `xl` (24px) vertical spacing to separate items.
*   **Wishlist Cards:** Use the `md` (1.5rem) or `lg` (2rem) corner radius. Items should feel like "objects" in a tray.

### Featured Wishlist Chips
*   Instead of standard square images, use the `xl` (3rem) corner radius for category thumbnails to create a "squircle" gallery effect that mirrors high-end mobile OS aesthetics.

---

## 6. Do's and Don'ts

### Do:
*   **Do** use asymmetrical spacing. Give your headlines more "top-room" (xxl=32px) than "bottom-room" (md=12px) to create an editorial feel.
*   **Do** use `primary_fixed_dim` for "Sale" or "Urgent" badges to ensure they pop against pastel backgrounds.
*   **Do** embrace white space. If a screen feels crowded, increase the padding to `xl` (24px) globally.

### Don't:
*   **Don't** use pure black (#000000) for text. Always use `on_surface` (#2f2f2e) to maintain the soft, premium feel.
*   **Don't** use standard Material Design "elevated" cards with harsh shadows. If it doesn't look like it's made of paper or glass, it doesn't belong.
*   **Don't** use 1px dividers. If you need to separate content, use a 8px-12px gap of the `surface` background color.