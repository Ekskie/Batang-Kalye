# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

Custom-rendered game UI (no native OS design language applies). Mobile-first landscape (Android / iOS phones and tablets over local hotspot), with desktop (keyboard + mouse) fully supported. Built in Godot 4.7.2 (Mobile renderer, `canvas_items` stretch, 1280×720 base, `expand` aspect). UI is Godot `Control` scenes, not web.

## Users

A broad audience, including non-Filipinos discovering Pinoy street games, plus Filipino players gathering a barkada over a phone hotspot. Players are mid-session, thumbs on a touchscreen, glancing at UI between sprints; menus are visited briefly between rounds.

## Product Purpose

Batang Kalye turns the Filipino childhood street game *tayaan* (tag) into a 3D multiplayer game for up to 8 (hotspot) / 24 (online) players. Success: a newcomer instantly reads "kids playing tag in a Filipino neighborhood," understands who is Taya, and wants another round.

## Positioning

The only multiplayer tag game built from *Laro ng Lahi*: the "Maiba Taya" hand-gesture ritual decides the chaser, rounds play out in a barangay (sari-sari store, eskinita, basketball court), and progression lives in Tindahan ni Aling Nena with Barya and Street Rep.

## Operating Context

- Flow: Title → Lobby (name, character showroom, browse/create/hotspot) → 3D Social Lobby (walk, vote mode, emotes) → Maiba Taya ritual → Match HUD → Game Over (MVP, awards, earnings) → back to barangay.
- Modes: Pasa-Taya (elimination), Hawaan/Infection, Classic Tag (Walang Bawian).
- Touch controls (joystick, Talon, Dulas, Dash, Sprint, Hampas), pause + settings, Store, Quick Guide.

## Capabilities and Constraints

- Node paths in `scenes/main/Main.tscn` and `scenes/ui/*.tscn` are referenced by `GameManager.gd`, UI scripts, and 22 automated tests; restyling must keep paths, node types, and tested label text working.
- Touch targets ≥ 44 px (swatches), ≥ 50 px (char nav), CTA ≥ 54 px are tested invariants.
- Mobile performance budget: low-end Android (Realme 6, Honor Pad 10); avoid heavy shaders and per-frame UI allocations.
- Copy is Tagalog/Taglish; the user allows rewriting and restructuring as long as everything keeps working.

## Brand Commitments

- Name: **Batang Kalye** (Taya-Tayaan). Team Fiery Fox. DOST Level Up 3.0 entry.
- Filipino identity must come from world, details, and craft — not flags, not generic tropical, not Fortnite/Roblox/cheap-mobile looks.
- Avoid: excessive gradients, neon, glassmorphism, giant rounded cards, generic AI UI, overly colorful kids'-game UI.
- User confirmed (2026-10-16): nothing visual is sacred — logo, font, layouts, and copy may all be redesigned.

## Evidence on Hand

- Logo raster used on title screen; Lilita One font (`assets/fonts/LilitaOne-Regular.ttf`).
- MVP portrait art in GameOverUI; in-game 3D lobby and match maps for live backdrops.
- No real player counts, reviews, or press; do not fabricate.

## Product Principles

1. Read at a glance mid-chase: role, timer, and danger beat decoration.
2. Filipino by craft, not by costume.
3. Thumb-first: every action reachable and big enough on a phone.
4. Welcoming to newcomers: Tagalog flavor with clear meaning for non-Filipinos.
5. Never break the game: UI changes preserve networking, flow, and tests.

## Accessibility & Inclusion

Role states (Taya / Hawa / Safe) must not rely on color alone — pair with icon and text. Legible at phone distance; high contrast over a moving 3D scene.
