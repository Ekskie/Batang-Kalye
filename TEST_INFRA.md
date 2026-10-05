# E2E Test Infra: Batang Kalye

## Test Philosophy
- Opaque-box, requirement-driven. Derived from ORIGINAL_REQUEST.md.
- Verification executed via Godot 4.7 headless binary:
  `& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless "res://scenes/main/Main.tscn" --run-self-test`
  and standalone headless test scripts:
  `& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless -s tests/<test_name>.gd`
- Methodology: Category-Partition + Boundary Value Analysis + Pairwise Combinatorial + Real-World Workload Testing.

## Feature Inventory & Test Mapping
| # | Feature | Requirement Source | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|---|---------|-------------------|:------:|:------:|:------:|:------:|
| 1 | Throttled Network Sync | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 2 | Cubic Hermite Spline Interpolator | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 3 | Distance-Based Culling / Prioritization | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 4 | 16–24 Player Lobby & Spawn Scaling | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 5 | Dynamic Multi-Taya Balancing | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 6 | Persistent Economy (Barya / Rep) | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ | ✓ |
| 7 | Tindahan ni Aling Nena Store & Catalog | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ | ✓ |
| 8 | Safe Transactions & Config Persistence | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ | ✓ |
| 9 | Multiplayer Cosmetic & Title Sync | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ | ✓ |
| 10 | Interactive Onboarding / Quick Guide | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ | ✓ |
| 11 | Customizable Mobile Touch Controls | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ | ✓ |
| 12 | Tag Action Audio & Visual Feedback | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ | ✓ |
| 13 | Enhanced Mobile Spectator Flow | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ | ✓ |

## Test Architecture
- **Runner**: Godot Engine headless executable running custom test runners or Main.tscn self-test suite.
- **Pass/Fail Semantics**: All assertions must evaluate true, process must exit with code 0, zero runtime exceptions or script errors logged in `%APPDATA%\Godot\app_userdata\Batang Kalye\logs\godot.log`.
- **Directory Layout**:
  - `tests/test_netcode_16_24_scaling.gd`: Validates 16-24 player lobby creation, connection of 24 peers, packet throttling <= 30Hz, outbound bandwidth < 40 KB/s, dynamic multi-Taya ratio assignment.
  - `tests/test_economy_store_persistence.gd`: Validates match currency awards, transaction safety (no duplicate/negative balance), config persistence in user://, title and cosmetic unlocking.
  - `tests/test_mobile_ux_spectator.gd`: Validates layout presets (default/left-handed/compact), quick-guide overlay open/close/tabs, tag feedback invocation, spectator target cycling & stats display.
  - `tests/test_e2e_full_suite.gd`: Master E2E runner executing all test cases across Tiers 1-4.

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | 24-Player Full Pasa-Taya Match Simulation | F1, F2, F3, F4, F5, F13 | High |
| 2 | Complete Match Economy-to-Store Purchase Cycle | F6, F7, F8, F9 | Medium |
| 3 | Mobile First-Time User Onboarding & Preset Customization | F10, F11, F12 | Medium |
| 4 | Elimination & Spectator Flow with Remote Peers | F5, F13, F9 | High |
| 5 | Network Bandwidth Under Stress (24 Peers in High Proximity) | F1, F2, F3, F4 | High |

## Coverage Thresholds
- Tier 1: ≥5 per feature (65+ tests total)
- Tier 2: ≥5 per feature (65+ tests total)
- Tier 3: pairwise coverage of major feature interactions (15+ tests)
- Tier 4: ≥5 realistic application scenarios
