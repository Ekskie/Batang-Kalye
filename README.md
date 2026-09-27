# 🎮 Taya-Tayaan: Batang Kalye
**DOST Level Up 3.0 Esports Game Dev Challenge Entry**  
**Team**: Fiery Fox  
**Engine**: Godot Engine 4.7.2 (Mobile Renderer + Jolt Physics)  
**Target Platform**: Android / iOS (Mobile Hotspot Multiplayer up to 8 Players) + Desktop (PC Testing)

---

## 📖 Overview & Gameplay Mechanics
*Batang Kalye* is a fast-paced 3D third-person multiplayer action game inspired by nostalgic Philippine street games (*Laro ng Lahi*) and Filipino kids' wild imaginations:
1. **The Match Format**: Free-for-all / infection-based PvP tag supporting up to 8 players via local Wi-Fi / Android Hotspot.
2. **"Maiba Taya" Hand Gesture Ritual**: At the start of the round, players chant *"Ma-i-ba... TAYA!"* and choose Palm UP (🖐️ Puti/Ibabaw) or Palm DOWN (🤚 Itim/Ilalim). The odd player out becomes the initial **TAYA** (Chaser)!
3. **Roles & Scoring**:
   - **Runners**: Earn survival points continuously for every second alive without being tagged.
   - **Taya (Chaser)**: Adrenaline speed burst, fiery aura, and scores points for each successful tag.
4. **Kalye (Street) Arena**: Includes iconic Philippine barangay staples like the Sari-Sari store, makeshift wooden crates, basketball hoop on an electric utility post, and perimeter walls.

---

## 🕹️ Controls & Advanced Movement

### 📱 Mobile Controls (Touchscreen)
- **Movement**: Floating virtual thumbstick on the bottom-left of the screen.
- **Camera Orbit**: Swipe / drag with thumb on the right half of the screen.
- **🦘 TALON (Jump)**: Tap once to jump; tap again in mid-air for **Double Jump**!
- **🏂 DULAS (Slide)**: Tap while running to slide under barriers and dodge chasers with lower hitbox.
- **⚡ DASH**: Tap for a rapid burst of forward evasive speed.
- **🏃 SPRINT**: Toggle sprint for high-speed running with dynamic FOV kick.
- **🔥 HAMPAS (Tag)**: Tap to tag runners when target reticle says `[TAG READY!]`.

### 💻 Desktop Testing Controls (Keyboard & Mouse)
- **WASD / Arrow Keys**: Smooth 3rd-person movement relative to camera.
- **Mouse Motion**: 360-degree camera orbit (`ESC` captures/releases mouse).
- **Spacebar**: Jump + **Double Jump** in mid-air (with coyote time & jump buffering).
- **C Key**: Slide while running (squashes model/hitbox and preserves momentum).
- **Q / Left Ctrl**: Dash forward burst with speed lines.
- **Left Shift**: Sprint (expands FOV).
- **Left Mouse Click or F**: Tag slap action (lunges forward if target is locked).
- **T Key (Debug / Practice)**: Instantly toggle role between Runner and Taya.

---

## 🎯 Tag Pointer & Targeting System
- **For the TAYA (Chaser)**:
  - **3D Lock-On Reticle**: Floats directly over the nearest runner with live distance in meters (`🎯 Chris: 4.2m`).
  - **Tag Ready Indicator**: Reticle pulses red & gold `[🔥 HAMPASIN MO!]` when inside tag reach (<= 3.5m).
  - **Off-Screen Compass**: Arrow pinned to the edge of your screen points toward fleeing runners so they cannot easily hide in the barangay streets.
- **For the RUNNER**:
  - **Danger Radar**: Warning pointer reveals which direction the Taya is approaching from (`⚠️ TAYA: 12m`).
  - **Proximity Alert Banner**: Warning banner appears if the Taya gets dangerously close (`⚠️ DELIKADO! MALAPIT ANG TAYA: 4.5m`).

---

## 📡 Mobile Hotspot Multiplayer (Up to 8 Players)
1. **Host (Player 1)**:
   - Turn on your phone's **Personal Hotspot** (or connect everyone to the same Wi-Fi router).
   - Launch the game, click **GUMAWA NG ROOM (Host Hotspot)**.
   - The lobby shows your phone's Hotspot IP (e.g. `192.168.43.1`).
2. **Clients (Players 2 to 8)**:
   - Connect Wi-Fi to the Host phone's hotspot.
   - Enter your name and the Host IP address.
   - Click **SUMALI SA ROOM (Join)**.
3. **Start**: The Host presses **SIMULAN ANG LARO** to initiate the "Maiba Taya" ritual and launch the match!
4. **Solo Practice**: You can also click **SOLO PRACTICE** to immediately jump into the 3D Kalye map alone to test movement and mechanics.

---

## 📁 Project Architecture
```text
res://
├── assets/
│   ├── materials/           # PBR & stylized materials (asphalt, sidewalk, wood, taya glow, yero)
│   └── models/              # Destination for 3D model exports (.glb / .gltf)
├── scenes/
│   ├── main/
│   │   └── Main.tscn        # Main game coordinator, lobby UI, round state machine
│   ├── maps/
│   │   └── KalyeMap.tscn    # 3D Street environment with sari-sari store & basketball post
│   ├── player/
│   │   ├── CharacterModel.tscn # Procedural 3D kid character model with walk/run/tag animations
│   │   └── Player.tscn      # CharacterBody3D, SpringArm3D camera & Tag detection
│   └── ui/
│       ├── HUD.tscn         # In-game score, survival timer, and live leaderboard
│       ├── MaibaTayaUI.tscn # Nostalgic hand-gesture chant UI
│       └── MobileControlsUI.tscn # Dual-stick mobile touch controls
└── scripts/
    ├── gameplay/
    │   ├── GameManager.gd   # Authoritative match timer, player spawning, state management
    │   └── MaibaTayaManager.gd # Maiba Taya arbitration logic and RPCs
    ├── network/
    │   └── NetworkManager.gd # ENetMultiplayerPeer 8-player hotspot manager
    ├── player/
    │   ├── CharacterAnimator.gd # Procedural walking, sprinting, jumping, and tag slap anims
    │   └── PlayerController.gd  # Third-person movement, Jolt physics, camera, and tagging
    └── ui/
        ├── HUD.gd
        ├── MaibaTayaUI.gd
        ├── MobileControls.gd
        └── VirtualJoystick.gd # Custom drawn 2D analog thumbstick
```

---

## 👥 Team Fiery Fox Collaboration Guide
- **Dennrick Agustin (Developer)**: Core networking, state machine, physics, and gameplay mechanics.
- **Chris Cajipe & Ralph Vener Esmillo (3D Artists)**: Drop low-poly 3D models (`.glb`) into `assets/models/`. You can replace `CharacterModel.tscn` or plug new street props into `KalyeMap.tscn`.
- **Daniel Jimenez (Sound Engineer)**: Add audio clips (street ambiences, footsteps, *"Maiba Taya"* voice chants, and slap SFX) in `scenes/main/Main.tscn` or `Player.tscn`.
- **Josh De Belen (Multimedia)**: Record 3-5 minute demo video clips directly from desktop/mobile for the competition submission.
