# Stranded: The Forest Beyond
## A Roblox Survival Sci-Fi Horror Game

---

## Vision

You crash-land on what appears to be Earth — familiar trees, rivers, wildlife, a normal sky. But something is *wrong*. The stars aren't right. The animals behave strangely. Ancient ruins dot the landscape with symbols that look almost — but not quite — like human writing.

As you survive night after night, the truth slowly reveals itself: **you are not on Earth.** This is an alien world that mimics terrestrial environments. The forest is alive, intelligent, and studying you. The creatures that hunt at night aren't supernatural — they're the planet's apex predators. The "cultists" are another stranded species that went mad trying to escape.

Your ship is scattered across the map in pieces. Find the components, rebuild it, and escape — before the forest decides you belong to it.

**Art Style:** Low-poly stylized Roblox aesthetic (starts Earth-like, alien elements creep in)
**Players:** Up to 25 co-op
**Platform:** Roblox (Luau)

---

## The Revelation Arc (How the truth unfolds)

### Days 1-10: "This is just a forest"
- Everything looks and feels Earth-like
- Normal trees, rocks, berries, rabbits
- Subtle wrongness: two moons barely visible at dusk, slightly off star patterns
- The Stalker (our "Deer") appears at night — seems supernatural/horror

### Days 11-25: "Something isn't right"
- Alien flora starts appearing — bioluminescent mushrooms, pulsing vines
- Found journal entries from previous crash survivors describe the same confusion
- Ruins with alien glyphs that your scanner slowly learns to translate
- Wildlife reveals alien biology (strange blood color, extra joints when examined closely)
- The "cultists" are revealed as another stranded alien species (the Kethari)

### Days 26-50: "We're not on Earth"
- Alien biomes unlock: crystalline caves, spore forests, bioluminescent swamps
- Scanner translates enough glyphs to reveal planet's name and history
- The Stalker is revealed as the planet's guardian entity — not evil, territorial
- Kethari lore: they crashed centuries ago, worship the forest now, lost their minds
- Ship component locations revealed through translated maps

### Days 50-99: "How do we get home?"
- Ship components guarded by evolved Kethari and planetary defenses
- The forest actively resists your departure (new enemy types, environmental hazards)
- Final components require venturing to the planet's most alien zones
- Endgame: rebuild the ship while defending it from the forest's final assault
- Escape sequence: launch cutscene — or stay and become like the Kethari?

---

## Core Mechanics

### The Signal Fire (Campfire equivalent)
- Your ship's emergency beacon, repurposed as a heat/light source
- Powered by organic fuel (wood) + ship battery cells
- Creates a dampening field that repels the Stalker and native predators
- Upgrading expands the field, pushing back the fog/atmosphere boundary
- Levels 1-5: each level reveals more of the map and unlocks new zones

### The Scanner (Unique mechanic)
- Handheld device salvaged from the crash
- Scans alien objects to build a translation database
- Scanned items reveal crafting recipes, lore, and map markers
- Battery-powered — must be recharged at the Signal Fire
- Higher scan levels unlock deeper lore and hidden locations

### Survival Meters
| Meter | Description |
|-------|-------------|
| **Health** | Damage from enemies and hazards. Heal with medkits, food, Signal Fire |
| **Hunger** | Drains over time. Eat berries, cooked meat, alien fruit. Empty = HP drain |
| **Oxygen** | The atmosphere is *almost* breathable. O2 depletes faster at night and in alien biomes. Signal Fire purifies air in its radius |
| **Exposure** | Alien spores/radiation in deep zones. Too much = hallucinations, stat debuffs |

---

## Phase 1: Core Survival Loop (MVP)
*Goal: Spawn, gather, survive night, discover something is wrong.*

### 1.1 Day/Night Cycle
- [ ] Time system: ~6 min day / ~4 min night
- [ ] Sky/lighting transitions with alien tint at night (slightly purple sky, wrong stars)
- [ ] Day counter HUD (Sol 1, Sol 2... up to Sol 99)
- [ ] Ambient audio: Earth-like by day, subtly alien by night

### 1.2 Signal Fire System
- [ ] Central fire with fuel meter (emergency beacon visual)
- [ ] Dampening field radius (visible energy dome on ground)
- [ ] Fuel types: Wood (basic), Battery Cells (medium), Plasma Cores (best)
- [ ] Fire levels 1-5: expands field + pushes atmospheric fog back
- [ ] Health + O2 regen inside field
- [ ] Visual scaling: small flame → roaring energy beacon

### 1.3 Player Character
- [ ] Third-person controller with sprint (stamina meter)
- [ ] Health bar
- [ ] Hunger meter
- [ ] Oxygen meter (drains slightly faster at night)
- [ ] Inventory system (backpack from crash, upgradeable)
- [ ] Equipment slots: primary tool, offhand (scanner/flashlight), armor

### 1.4 Resource Gathering
- [ ] Trees → chop → Wood (look normal at first)
- [ ] Bushes → berries (edible, Earth-like)
- [ ] Rocks → Stone + occasional metal ore
- [ ] Crash debris scattered nearby → Scrap Metal, Wire, Components
- [ ] Salvage Processor at camp: break items into raw materials
- [ ] Resource nodes respawn each day cycle

### 1.5 Basic HUD
- [ ] Health, Hunger, O2, Stamina bars
- [ ] Sol counter + day/night indicator
- [ ] Inventory hotbar (8 slots)
- [ ] Signal Fire fuel gauge
- [ ] Ship Component tracker (0/6 found)

---

## Phase 2: Combat & Threats
*Goal: Nights are lethal. The planet fights back.*

### 2.1 The Stalker (Primary Night Threat)
- [ ] Tall, biomechanical creature — looks like a deer at first, reveals alien anatomy over time
- [ ] Spawns at nightfall, despawns at dawn
- [ ] Stalker AI: patrols outside dampening field, pursues players who leave
- [ ] Invulnerable to conventional weapons (it's the apex predator)
- [ ] Attack: charge + grab, ~33% HP damage
- [ ] Counterplay: UV Flashlight slows it, Signal Fire blocks it completely
- [ ] Audio cues: clicking/chittering sounds, ground vibration
- [ ] Cannot enter dampening field

### 2.2 The Kethari (Raid Events — "Cultists" reimagined)
- [ ] Alien species stranded centuries ago, now feral and territorial
- [ ] Wear crude armor made from ship wreckage + forest materials
- [ ] Melee warriors + spore-thrower ranged units
- [ ] Raid every ~3 sols (warning: distant war drums/horns)
- [ ] Drop Kethari Crystals (key crafting material)
- [ ] Difficulty scales: more Kethari, tougher variants per sol
- [ ] Lore: journal entries explain they were once like you

### 2.3 Native Wildlife
- [ ] Skippers: small passive creatures, drop Bio-Fiber (look like rabbits)
- [ ] Prowlers: nocturnal pack hunters, drop Prowler Hide (wolf-like)
- [ ] Alpha Prowler: larger, tougher variant
- [ ] Behemoths: territorial giants, drop Behemoth Plate (bear-like)
- [ ] Alien biology reveals over time (bioluminescence, extra limbs, camouflage)

### 2.4 Weapons & Combat
- [ ] Melee: Fists → Makeshift Axe → Crafted Blade → Plasma Edge (endgame)
- [ ] Ranged: Slingshot → Crossbow → Salvaged Pistol → Pulse Rifle
- [ ] UV Flashlight: slows Stalker, reveals hidden alien elements
- [ ] Hit detection, damage numbers, knockback
- [ ] Death → respawn at bed/Signal Fire (drop some inventory)

---

## Phase 3: Crafting & Base Building
*Goal: Build, craft, fortify. Use alien + human tech.*

### 3.1 Fabricator (Crafting Bench equivalent — 5 tiers)
- [ ] Tier 1 (crash salvage): Makeshift Axe, Bedroll, Wooden Barricade, Torch
- [ ] Tier 2 (Scrap + Wood): Traps, Upgraded Pack, Reinforced Walls, Crossbow
- [ ] Tier 3 (+ Kethari Crystals): Alloy Wall, Pulse Bow, Exo-Armor, Medkit
- [ ] Tier 4 (+ Alien Tech): Energy Shield, Auto-Turret, Atmosphere Processor
- [ ] Tier 5 (Ship Components): Required to rebuild ship systems
- [ ] Fabricator upgrade UI with recipe tree
- [ ] Crafting animation + holographic progress display

### 3.2 Base Building
- [ ] Placeable: Barricades, Alloy Walls, Doors, Platforms
- [ ] Snap-to-grid placement within dampening field
- [ ] Structures have HP, enemies attack them during raids
- [ ] Alien saplings: plantable, grow into bioluminescent barriers overnight
- [ ] Build radius tied to Signal Fire level

### 3.3 Shelter & Progression
- [ ] Craftable beds: set respawn, provide sol multiplier (time skip)
- [ ] Atmosphere Processor: expands breathable air zone
- [ ] Stacks with ship component discovery bonus

### 3.4 Alien Workshop (World Structure)
- [ ] Ancient alien structure deep in the forest, guarded by Kethari
- [ ] Contains advanced fabrication tech
- [ ] Craft unique items: Gravity Hammer, Chain-Saw, Energy Shield
- [ ] Must scan glyphs to unlock access

---

## Phase 4: Map & Exploration
*Goal: A world that slowly reveals its alien nature.*

### 4.1 Atmospheric Fog System
- [ ] Dense alien atmosphere beyond dampening field radius
- [ ] Signal Fire upgrades push fog back, revealing more terrain
- [ ] Fog reduces O2 and causes Exposure buildup
- [ ] Minimap reveals explored areas

### 4.2 Zone Progression (Fog reveals zones in order)

| Zone | Signal Fire Level | Theme | Key Content |
|------|-------------------|-------|-------------|
| **Crash Site** | 1 | Familiar forest clearing | Starting area, basic resources |
| **Deep Woods** | 2 | Dense forest, abandoned camps | Kethari outposts, first lore |
| **The Ruins** | 3 | Ancient alien structures | Scanner translations, alien tech |
| **Spore Valley** | 4 | Bioluminescent alien biome | Alien resources, Exposure hazard |
| **The Core** | 5 | Fully alien landscape | Final ship components, boss encounters |

### 4.3 Points of Interest
- [ ] Ship Components (6 total): scattered across zones, each guarded
  - Navigation Array (Zone 2)
  - Fuel Cell (Zone 2)
  - Hull Plating (Zone 3)
  - Engine Core (Zone 4)
  - Life Support Module (Zone 4)
  - Quantum Drive (Zone 5 — final piece, boss fight)
- [ ] Survivor Camps (4): previous crash survivors' camps with journals + loot
- [ ] Kethari Settlements: hostile areas with rare resources + lore
- [ ] Alien Monoliths: scannable structures that reveal map/lore
- [ ] The Trader: a lucid Kethari who trades alien pelts for human-compatible gear

---

## Phase 5: Multiplayer & Social Systems
*Goal: 25 survivors working together to escape.*

### 5.1 Networking Foundation
- [ ] Server-authoritative game state
- [ ] RemoteEvents for all client-server communication
- [ ] Mid-game join/leave handling
- [ ] Synchronized sol cycle across all clients
- [ ] Shared Signal Fire (any player can fuel)

### 5.2 Difficulty Scaling
- [ ] Enemy count scales with player count
- [ ] Resource nodes scale with player count
- [ ] Kethari raid size scales
- [ ] More ship components scattered (still 6 required, but extras for redundancy)

### 5.3 Social Features
- [ ] Proximity chat indicators
- [ ] Shared storage chests at camp
- [ ] Revive downed players
- [ ] Player nameplates + health bars
- [ ] Ping system (mark locations for teammates)

---

## Phase 6: Roles & Specialization
*Goal: Replayability through player roles.*

### 6.1 Role System (6 core roles)
- [ ] **Salvager** (Production): Faster scrap processing, starts with cutting tool
- [ ] **Scout** (Exploration): Starts with Scanner upgrade, speed boost, wider minimap
- [ ] **Marine** (Combat): Damage boost, starts with salvaged weapon
- [ ] **Medic** (Support): Can heal/revive others faster, starts with med supplies
- [ ] **Engineer** (Production): Crafting speed boost, unique turret/trap recipes
- [ ] **Xenobiologist** (Exploration): Faster scanning, animal tracking, identifies alien flora

### 6.2 Role Progression
- [ ] 3 levels per role (level by doing role-specific actions)
- [ ] Each level unlocks a new perk
- [ ] Role selection in lobby/at spawn

---

## Phase 7: Polish & Atmosphere
*Goal: Immersive alien forest horror.*

### 7.1 Audio Design
- [ ] Day: birdsong + wind (subtly off-key alien bird calls)
- [ ] Night: alien insect chirps, distant Stalker clicks, atmospheric hum
- [ ] Signal Fire: energy hum + crackling
- [ ] Combat: impact sounds, alien creature screeches
- [ ] Music: ambient synth (calm day) → tense pulsing (night)
- [ ] Revelation moments: special audio stinger when alien truths are uncovered

### 7.2 Visual Effects
- [ ] Signal Fire: energy particle effects, dampening field shimmer
- [ ] Fog: volumetric alien atmosphere (slight green/purple tint)
- [ ] Night sky: wrong constellations, two small moons
- [ ] Alien zones: bioluminescent particles, pulsing flora
- [ ] Exposure effects: visual distortions, color shifts
- [ ] Day/night: warm gold day → cold blue-purple alien night

### 7.3 UI/UX
- [ ] Lobby: crashed ship interior
- [ ] Role selection: holographic display
- [ ] Death screen with survival stats
- [ ] Victory: ship launch cinematic
- [ ] Leaderboards: fastest escape, most sols survived

---

## Technical Architecture

```
src/
├── server/                    -- ServerScriptService
│   ├── GameManager.luau              -- Master loop, sol cycle, game state
│   ├── SignalFireManager.luau        -- Fire state, fuel, dampening field
│   ├── EnemyManager.luau            -- Spawn, AI, despawn (Stalker, Kethari, wildlife)
│   ├── CraftingManager.luau         -- Fabricator recipes, validation, crafting
│   ├── BuildingManager.luau         -- Structure placement, HP, destruction
│   ├── ResourceManager.luau         -- Node spawning, respawning, salvage processor
│   ├── PlayerManager.luau           -- Stats, inventory, role, death/respawn
│   ├── RaidManager.luau             -- Kethari raid scheduling + execution
│   ├── TraderManager.luau           -- Kethari trader spawn + trade logic
│   ├── LoreManager.luau             -- Scanner data, glyph translations, journals
│   ├── ShipManager.luau             -- Component tracking, rebuild progress, endgame
│   └── NetworkManager.luau          -- RemoteEvent/Function hub
├── client/                    -- StarterPlayerScripts
│   ├── HUDController.luau           -- All UI updates
│   ├── InputController.luau         -- Keybinds, tool use, building mode
│   ├── CameraController.luau        -- Third-person camera, exposure effects
│   ├── AudioController.luau         -- Ambient, music, SFX
│   ├── ScannerUI.luau               -- Scanner interface, translation display
│   └── VisualEffects.luau           -- Fog, exposure distortions, bioluminescence
├── shared/                    -- ReplicatedStorage
│   ├── Config.luau                  -- All game constants/tuning values
│   ├── RecipeData.luau              -- Fabricator recipe definitions
│   ├── RoleData.luau                -- Role definitions + perks
│   ├── EnemyData.luau               -- Enemy stats + behavior params
│   ├── ItemData.luau                -- Item definitions + properties
│   ├── LoreData.luau                -- Journal entries, glyph translations, story beats
│   └── ZoneData.luau                -- Zone definitions, fog thresholds, spawn tables
└── assets/                    -- Workspace / ReplicatedStorage
    ├── models/                      -- 3D models (tools, enemies, structures, ship parts)
    ├── maps/                        -- Terrain, zone prefabs, POIs
    ├── ui/                          -- ScreenGuis, frames, templates
    └── audio/                       -- Sound files
```

---

## Build Priority Order

| Priority | System | Effort | Dependencies |
|----------|--------|--------|--------------|
| **P0** | Project setup + folder structure | S | None |
| **P0** | Day/Night sol cycle + lighting | S | None |
| **P0** | Player character + movement + sprint | S | None |
| **P0** | Signal Fire (fuel, dampening field, levels) | M | Sol cycle |
| **P0** | Resource gathering (trees, rocks, crash debris) | M | Player |
| **P0** | Inventory system | M | Player |
| **P0** | HUD (health, hunger, O2, sol counter) | M | Player + Inventory |
| **P1** | The Stalker AI + night spawning | M | Sol cycle + Signal Fire |
| **P1** | Melee combat system | M | Player + Inventory |
| **P1** | Fabricator Tier 1-2 | M | Inventory + Resources |
| **P1** | Base building (barricades, walls) | M | Fabricator |
| **P1** | Hunger + O2 + cooking | S | Inventory |
| **P1** | Multiplayer sync (shared fire, sol cycle) | L | All P0 |
| **P2** | Kethari raids | M | Combat + Sol cycle |
| **P2** | Wildlife (Skippers, Prowlers, Behemoths) | M | Combat + AI |
| **P2** | Fog system + zone progression | M | Signal Fire levels |
| **P2** | Fabricator Tier 3-5 | M | Tier 1-2 |
| **P2** | Ship components + objectives | M | Map + zones |
| **P2** | Scanner + lore system | M | Exploration |
| **P2** | Kethari Trader NPC | S | Wildlife + Inventory |
| **P2** | Exposure system + visual effects | M | Player + zones |
| **P3** | Role system (6 roles) | L | All core |
| **P3** | Alien Workshop POI | M | Combat + Fabricator |
| **P3** | Zone 4-5 content (Spore Valley, The Core) | L | Zone system |
| **P3** | Audio design + music | M | Parallel |
| **P3** | Lobby, menus, cinematics | M | Parallel |
| **P3** | Difficulty scaling by player count | M | Multiplayer + Enemies |
| **P3** | Endgame: ship rebuild + escape sequence | L | Ship components + all P2 |

---

## Name Ideas
- **Stranded: The Forest Beyond**
- **Wrong Stars**
- **The Borrowed Forest**
- **Terrestrial**
- **Not Earth**
- **Familiar Dark**
