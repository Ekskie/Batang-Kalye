# Batang Kalye — UI Design System (`KalyeStyle` & `KalyeBox`)

## 1. Visual Direction
**Category Standard: Clean Modern Mobile Party-Game UI (Brawl Stars / Stumble Guys Craft Level), Done Straight with Filipino Copy**

Batang Kalye's interface is built around **chunky, tactile, vector-drawn surfaces** that read clearly at arm's length on a `1280×720` mobile screen in landscape while scaling crisply to any desktop resolution:

- **Single Ink Outline (`#151229`)**: Every panel, card, badge, button, input field, progress bar, and display label shares the same deep indigo-black ink outline (`3px` on surfaces/buttons, `2px` on inset fields, `3–10px` on typography).
- **Pressable 3D Lip**: Interactive buttons and elevated cards feature a darker underside lip (`lip_height = 6px` on normal/hover, `2px` with `press_sink = 4px` when pressed) and a crisp top gloss highlight band.
- **High-Contrast Color Hierarchy**:
  - **Surfaces**: Deep Midnight Navy (`#1A2142` outer panel, `#232D58` card, `#10152B` inset input/scroll well).
  - **Primary / Hero CTA (`BtnPrimary`)**: Sun Gold (`#FFD426` fill, `#C88800` lip) — Play, Start, Confirm, Active Tab, Buy/Equip.
  - **Secondary (`Button`)**: Royal Blue (`#2B7FFF` fill, `#164BB8` lip) — Standard actions, navigation, secondary options.
  - **Positive / Host / Ready (`BtnSuccess`)**: Emerald Green (`#2EE65B` fill, `#149A38` lip) — Host room, join code, ready/return.
  - **Danger / Destructive (`BtnDanger`)**: Crimson Red (`#FF3B4E` fill, `#B51629` lip) — Quit, Close, Leave, Taya alert.
  - **Accent (`BtnPurple`, `BtnOrange`)**: Violet (`#A54BFF`) and Sunset Orange (`#FF8A1F`) — Guide, Store ("Tindahan ni Aling Nena"), Practice.
- **Bold Outlined Display Typography**: `res://assets/fonts/LilitaOne-Regular.ttf` across all headers, buttons, badges, and HUD counters, paired with dark ink outlines and vertical drop shadows so Filipino copy (*"TAYAAN SA KANTO"*, *"MAIBA TAYA!"*, *"BARYA"*, *"STREET REP"*) pops over both 3D neighborhood action and dark navy cards.

---

## 2. Architecture

### [`scripts/ui/theme/KalyeBox.gd`](file:///c:/Users/Denn/Documents/GitHub/Batang-Kalye/scripts/ui/theme/KalyeBox.gd) (`class_name KalyeBox extends StyleBox`)
A custom `@tool` vector `StyleBox` that procedurally draws five layered rounded rects in a single canvas pass at any DPI:
1. **Drop Shadow** (`shadow_color`, `shadow_offset`, `shadow_size`)
2. **Outer Ink Border** (`border_color`, `border_width`)
3. **3D Bottom Lip** (`lip_color`, `lip_height`)
4. **Main Body Fill** (`bg_color`, shifted down by `press_sink` when pressed)
5. **Top Gloss Band / Inner Rim** (`gloss_color`, `gloss_height`, `inner_rim_color`)

### [`scripts/ui/theme/KalyeStyle.gd`](file:///c:/Users/Denn/Documents/GitHub/Batang-Kalye/scripts/ui/theme/KalyeStyle.gd) (`class_name KalyeStyle extends RefCounted`)
Central token registry, `Theme` builder, procedural icon generator (switches, checkboxes, slider knobs, dropdown chevrons), and runtime helper API:
- `KalyeStyle.build_theme() -> Theme`
- `KalyeStyle.apply_button(btn: Button, kind: Kind, font_size: int)`
- `KalyeStyle.apply_panel(panel: Control, surface: Surface)`
- `KalyeStyle.apply_label(label: Label, size: int, color: Color, outline: int)`

### [`assets/themes/batang_kalye_theme.tres`](file:///c:/Users/Denn/Documents/GitHub/Batang-Kalye/assets/themes/batang_kalye_theme.tres)
Project-wide default `Theme` registered in `project.godot` under `[gui] theme/custom="res://assets/themes/batang_kalye_theme.tres"`. Regenerate anytime via:
```powershell
Godot --headless --path . --script res://tools/build_theme.gd
```

---

## 3. Theme Type Variations

### Buttons (`Button`)
| `theme_type_variation` | Visual Role | Fill / Lip |
|---|---|---|
| `""` (default `Button`) | Secondary action | Royal Blue (`#2B7FFF` / `#164BB8`) |
| `&"BtnPrimary"` | Hero CTA / Active Tab / Confirm | Sun Gold (`#FFD426` / `#C88800`) |
| `&"BtnSuccess"` | Host / Join / Positive CTA | Emerald (`#2EE65B` / `#149A38`) |
| `&"BtnDanger"` | Close / Quit / Leave | Crimson (`#FF3B4E` / `#B51629`) |
| `&"BtnPurple"` | Guide / Special | Violet (`#A54BFF` / `#661EB8`) |
| `&"BtnOrange"` | Store / Practice | Sunset Orange (`#FF8A1F` / `#B84B00`) |
| `&"BtnGhost"` | Back / Subtle utility | Slate Navy (`#2B3668` / `#151C3B`) |
| `&"BtnTab"` | Inactive tab pill | Deep Slate (`#1E274E` / `#10152B`) |
| `&"BtnRound"` | 3D preview arrow / icon button | Royal Blue (`corner_radius = 24`) |

### Panels (`PanelContainer` / `Panel`)
| `theme_type_variation` | Visual Role |
|---|---|
| `""` (default) | Primary modal / outer container (`#1A2142`, `3px` ink border, `5px` lip) |
| `&"PanelCard"` | Inner section card (`#232D58`, `3px` ink border, `4px` lip) |
| `&"PanelInset"` | Recessed well / stat box (`#10152B`, `2px` ink border) |
| `&"PanelPill"` | Compact status pill (`#141B38`, `18px` radius) |
| `&"PanelHUD"` | Translucent in-match HUD plate (`Color(0.08, 0.10, 0.20, 0.88)`) |
| `&"BadgeYellow"`, `&"BadgeRed"`, `&"BadgeGreen"`, `&"BadgeBlue"`, `&"BadgePurple"`, `&"BadgeLime"` | Role, timer, currency, and mode callout badges |
| `&"PanelNone"` | Transparent layout wrapper |

### Labels (`Label`)
| `theme_type_variation` | Visual Role |
|---|---|
| `""` (default) | Standard outlined UI label (`16px`, `outline_size = 4`) |
| `&"LabelTitle"` | Hero screen title (`44px`, Gold `#FFE042`, `outline_size = 9`) |
| `&"LabelHeader"` | Modal / section header (`26px`, White, `outline_size = 6`) |
| `&"LabelSubheader"` | Card title (`20px`, Gold `#FFE042`, `outline_size = 5`) |
| `&"LabelMuted"` / `&"LabelSmall"` | Secondary metadata (`13–15px`, `#CBD6FF`, `outline_size = 3`) |
| `&"LabelBadge"` | Compact uppercase pill text (`14px`, Gold, `outline_size = 4`) |
| `&"LabelHUDValue"` | Large HUD timer / score readout (`24px`, `outline_size = 6`) |

---

## 4. Mobile-First Touch & Layout Standards
- **Base Viewport**: `1280×720` (`canvas_items` stretch, `expand` aspect).
- **Minimum Touch Targets**:
  - Primary CTA buttons: `>= 54px` height
  - Character carousel nav buttons: `>= 50×50px`
  - Tab buttons & standard action buttons: `>= 44–48px` height
  - Color palette swatches: `>= 44×44px` (`46×46px` standard)
