# Project: Taya-Tayaan: Batang Kalye (Mass-Market Flagship Upgrade)

## Architecture
Batang Kalye is a multiplayer 3D tag game built on Godot 4.7.
- **Network Layer**: ENet / WebRTC host-server star topology via `scripts/network/NetworkManager.gd`. Peer 1 is Host/Server.
- **Client Synchronization**: Position, rotation, velocity, and state broadcast via unreliable RPCs on `PlayerController.gd` with client-side snapshot buffering and Cubic Hermite Spline interpolation. 3-tier distance and role prioritization culls and throttles packets.
- **Match Gameplay & Rules**: `scripts/gameplay/GameManager.gd` and `scripts/gameplay/MaibaTayaManager.gd` coordinate game modes (Pasa-Taya Elimination, Infection Outbreak, Classic Tag) with dynamic multi-Taya ratio balancing (1 Taya per 4-5 players).
- **Economy & Meta-Game**: `scripts/gameplay/EconomyManager.gd` persists wallet (`barya`, `street_rep`) and unlocked inventory (`user://player_customization.cfg`). "Tindahan ni Aling Nena" (`scenes/ui/StoreUI.tscn`) provides cosmetic unlocks for archetypes, modular accessories, and titles.
- **Mobile UX & Juice**: `scripts/ui/MobileControls.gd` supports layout presets (Default, Left-Handed, Compact), dynamic scaling/opacity, touch spectator cycling, and visual tag range cues. `QuickGuideUI.tscn` provides an interactive 4-tab onboarding overlay.
- **Audio & Feedback**: `scripts/audio/AudioManager.gd` (`class_name AudioManager`) provides acoustic tag hits, whiffs, dings, and UI sounds.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Throttled Network Sync | Replace 60Hz per-frame broadcast with 25Hz tick accumulator (interval 0.04s) | M1 | R1 / Survey 1 |
| 2 | Cubic Hermite Spline Interpolator | Ring snapshot buffer with velocity tangents and Hermite curve interpolation | M1 | R1 / Survey 1 |
| 3 | Distance-Based Network Culling | 3-tier priority (<=20m/Taya @ 25Hz, 20-45m @ 12.5Hz, >45m @ 6.25Hz) + delta suppression | M1 | R1 / Survey 1 |
| 4 | 16–24 Player Lobby & Spawn Scaling | MAX_PLAYERS = 24, LobbyUI slider/slots scroll, KalyeMap procedural spawn scatter, HUD scroll | M1 | R1 / Survey 1 |
| 5 | Dynamic Multi-Taya Balancing | Ratio: 1 Taya per 4-5 players; multi-elimination in Pasa-Taya, multi-Patient Zero in Infection | M1 | R1 / Survey 1 |
| 6 | Persistent Economy (Barya / Street Rep) | Currency awarded for match participation, tags, trash segregation, and tournament victory | M2 | R2 / Survey 2 |
| 7 | Tindahan ni Aling Nena Store UI & Catalog | Full catalog modal with live 3D preview for archetypes, accessories, and titles | M2 | R2 / Survey 2 |
| 8 | Safe Local Persistence & Transactions | ConfigFile serialization to user://player_customization.cfg without negative/duplicate bugs | M2 | R2 / Survey 2 |
| 9 | Multiplayer Cosmetic & Title Sync | Outfit dictionary sync with equipped title, 3D NameLabel billboard display, scoreboard titles | M2 | R2 / Survey 2 |
| 10 | Interactive Onboarding / Quick-Guide Overlay | 4-tab guide (Maiba Taya, Stamina, Street Items, Segregation) in QuickGuideUI | M3 | R3 / Survey 3 |
| 11 | Customizable Mobile Touch Controls | Presets (Default, Left-Handed, Compact), slider scale/opacity, settings persistence | M3 | R3 / Survey 3 |
| 12 | Tag Action Audio & Visual Juice | AudioManager tag hit/whiff audio, floating combat text, tag button range glow & cooldown | M3 | R3 / Survey 3 |
| 13 | Enhanced Mobile Spectator Flow | Eliminated player touch cycling ([PREV] / [NEXT]), SpectatorCard with target stats & alive count | M3 | R3 / Survey 3 |
| 14 | E2E Test Suite (Tiers 1-4) | Headless test runner exercising netcode, lobby scaling, economy, store, mobile UX, spectator | E2E Track | ORIGINAL_REQUEST |
| 15 | Adversarial Coverage Hardening (Tier 5) | White-box stress testing, boundary condition verification, and gap elimination | M4 | Project Pattern |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | High-Density Netcode & 16-24 Match Scaling | Features 1, 2, 3, 4, 5 | none | DONE |
| M2 | Sari-Sari Store Progression & Customization Meta-Loop | Features 6, 7, 8, 9 | none | PLANNED |
| M3 | Mass-Market Mobile UX & Retention Polish | Features 10, 11, 12, 13 | none | PLANNED |
| M4 | Final E2E Integration & Adversarial Hardening | Phase 1: 100% E2E tests pass (Tiers 1-4); Phase 2: Tier 5 hardening | M1, M2, M3, E2E Track | PLANNED |
| E2E | E2E Testing Suite (Dual Track) | Comprehensive requirement-driven opaque-box test harness & test cases | none | PLANNED |

## Interface Contracts

### NetworkManager ↔ PlayerController
- `PlayerController` sends throttled packets via `@rpc("unreliable") sync_transform(pos: Vector3, vel: Vector3, rot_y: float, speed_val: float, floor_val: bool, remote_slide: bool, remote_dash: bool, timestamp_ms: int)`
- Target broadcast rate: 25 Hz for priority peers, 12.5 Hz for mid-range, 6.25 Hz for distant runners.

### NetworkManager ↔ Economy & Customization
- Outfit dictionary transmitted via `@rpc("any_peer", "reliable") update_outfit(outfit: Dictionary)`:
  - Keys: `base` (int), `hair` (int), `headwear` (int), `body` (int), `footwear` (int), `color` (int), `skin` (int), `title` (String).
- Applied on spawned avatars via `CharacterAnimator.apply_outfit_dict(outfit)` and `PlayerController.set_player_title(title)`.

### GameManager ↔ EconomyManager
- At match completion (`sync_game_over`, `sync_tournament_winner`, `sync_infection_game_over`):
  `EconomyManager.award_match_earnings(score: int, tags: int, recycled: int, is_winner: bool) -> Dictionary`
  Returns: `{"barya_earned": int, "rep_earned": int, "total_barya": int, "total_rep": int}`.

### MobileControls ↔ PlayerController & HUD
- `MobileControls.set_layout_preset(preset: int)`: adjusts touch joystick and button anchors.
- `MobileControls.set_spectator_mode(active: bool)`: toggles touch cycling buttons `[PREV]` / `[NEXT]` calling `PlayerController._cycle_spectate_target(step)`.
- `HUD.update_spectator_info(target_data: Dictionary)`: updates `SpectatorCard` with name, role, score, tags, held item, and alive count.

## Code Layout
- `scripts/network/NetworkManager.gd`: Network initialization, MAX_PLAYERS=24, lobby peer registry, outfit sync RPCs. (Owned by M1)
- `scripts/player/PlayerController.gd`: 25Hz tick accumulator, Hermite spline interpolation, distance culling, tag audio & feedback. (M1 netcode, M3 audio/feedback)
- `scripts/gameplay/GameManager.gd`: Dynamic multi-Taya ratio, match progression, economy hook on game over, touch settings persistence. (M1 rules, M2 economy hook, M3 settings)
- `scripts/gameplay/MaibaTayaManager.gd`: Multi-Taya gesture evaluation and assignment. (Owned by M1)
- `scenes/maps/KalyeMap.tscn`: Spawn points and procedural dispersion for 24 players. (Owned by M1)
- `scenes/ui/LobbyUI.tscn` & `scripts/ui/LobbyUI.gd`: 24-player slider & scrollable slot list, Aling Nena store entry button. (M1 scaling, M2 store link)
- `scripts/gameplay/EconomyManager.gd`: Currency balance, store catalog data, transaction safety, user:// persistence. (Owned by M2)
- `scenes/ui/StoreUI.tscn` & `scripts/ui/StoreUI.gd`: Tindahan ni Aling Nena storefront UI modal. (Owned by M2)
- `scripts/player/CharacterAnimator.gd`: Accessory catalog mapping, ownership validation in wardrobe. (Owned by M2)
- `scenes/ui/GameOverUI.tscn` & `scripts/ui/GameOverUI.gd`: Match earnings display card and store navigation. (Owned by M2)
- `scripts/audio/AudioManager.gd`: `class_name AudioManager`, tag hit/swing SFX. (Owned by M3)
- `scenes/ui/MobileControlsUI.tscn` & `scripts/ui/MobileControls.gd`: Layout presets, scale/opacity, spectator touch controls, tag button glow. (Owned by M3)
- `scenes/ui/QuickGuideUI.tscn` & `scripts/ui/QuickGuideUI.gd`: 4-tab interactive onboarding carousel. (Owned by M3)
- `scenes/ui/HUD.tscn` & `scripts/ui/HUD.gd`: SpectatorCard with live match stats, 24-player scoreboard scrolling. (M1 scoreboard scroll, M3 spectator card)
- `tests/`: Automated test suites and E2E harness scripts. (Owned by E2E Testing Track)
