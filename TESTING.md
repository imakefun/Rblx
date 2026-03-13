# Testing & Validation Guide

## Prerequisites

### 1. Install Roblox Studio
- Download from https://www.roblox.com/create
- Sign in with your Roblox account
- Open Roblox Studio

### 2. Install Rojo (Filesystem Sync Tool)
Rojo lets us write code in VS Code / any editor and sync it into Roblox Studio.

**Option A: Aftman (recommended tool manager)**
```bash
# Install Aftman (Roblox tool manager)
cargo install aftman  # or download from https://github.com/LPGhatguy/aftman/releases

# Then in project root:
aftman install        # Installs rojo from aftman.toml
```

**Option B: Direct install**
```bash
# macOS
brew install rojo

# Windows (with cargo)
cargo install rojo

# Or download binary from https://github.com/rojo-rbx/rojo/releases
```

**Option C: Foreman (alternative tool manager)**
```bash
cargo install foreman
foreman install       # Reads foreman.toml
```

### 3. Install Rojo Plugin in Roblox Studio
1. Open Roblox Studio
2. Go to Plugins → Manage Plugins → Search "Rojo"
3. Install the **Rojo** plugin (by Lucien Greathouse)
4. You'll see a Rojo button in the Plugins toolbar

---

## How to Test the Game

### Step 1: Build the Rojo project
```bash
cd /path/to/Rblx
rojo build -o game.rbxlx
```
This creates a `.rbxlx` file you can open directly in Roblox Studio.

### Step 2: Open in Roblox Studio
- Double-click `game.rbxlx` OR
- Open Roblox Studio → File → Open → select `game.rbxlx`

### Step 3: Live Sync (recommended for iteration)
Instead of rebuilding each time, use live sync:

**Terminal:**
```bash
rojo serve
```

**Roblox Studio:**
1. Click the Rojo plugin button in the toolbar
2. Click "Connect" (it connects to localhost:34872 by default)
3. Now any file changes sync instantly into Studio!

### Step 4: Playtest
- **F5** = Play (test as a single player in-game)
- **F8** = Play Here (spawn at camera position)
- Press **F5** again or click Stop to end the test
- **Shift+F5** = Start a local server test (multiplayer testing)

### Step 5: Multiplayer Testing (Local)
1. Go to **Test** tab in Roblox Studio
2. Set "Players" to 2-4
3. Click **Start** (creates a local server + multiple client windows)
4. Each window is a different player — test co-op mechanics!

---

## Validation Checklist (Phase 1 MVP)

### Day/Night Cycle
- [ ] Sky transitions smoothly from day to night
- [ ] Lighting changes (warm day → cold purple night)
- [ ] Sol counter increments each cycle
- [ ] Night sky has wrong constellations / alien tint
- [ ] Cycle timing: ~6 min day, ~4 min night

### Player Character
- [ ] WASD movement works smoothly
- [ ] Sprint with Shift (stamina drains)
- [ ] Third-person camera follows correctly
- [ ] Health bar visible and functional
- [ ] Hunger depletes over time
- [ ] O2 depletes (faster at night)

### Signal Fire
- [ ] Fire visible at spawn point
- [ ] Fuel can be added (walk up + interact)
- [ ] Dampening field visible (circle/dome)
- [ ] Field blocks enemies (test with Stalker later)
- [ ] Upgrading expands the field radius
- [ ] Health/O2 regen inside field

### Resource Gathering
- [ ] Trees can be chopped → get Wood
- [ ] Rocks can be mined → get Stone
- [ ] Bushes → Berries
- [ ] Crash debris → Scrap
- [ ] Resources appear in inventory

### Inventory & HUD
- [ ] Items show in hotbar
- [ ] Can select items with 1-8 keys
- [ ] Stats bars (HP, Hunger, O2, Stamina) visible
- [ ] Sol counter visible
- [ ] Fuel gauge visible

---

## Debugging Tools

### Output Window
- In Studio: View → Output
- All `print()` and `warn()` statements show here
- Errors show in red with stack traces

### Server vs Client
- When playtesting, the Output shows both Server and Client logs
- Server logs prefixed with [Server]
- Client logs prefixed with [Client]
- Use this to debug replication issues

### Explorer + Properties
- Explorer panel (View → Explorer) shows the full instance tree
- Properties panel shows selected instance's properties
- Use these to verify Rojo synced correctly

### Command Bar
- View → Command Bar
- Type Luau code to execute immediately
- Great for testing: `print(game.Lighting.ClockTime)`

---

## Common Issues

| Issue | Fix |
|-------|-----|
| Rojo won't connect | Check `rojo serve` is running, check port 34872 |
| Scripts not running | Check script is in correct service (ServerScriptService, etc.) |
| RemoteEvents missing | They must exist in ReplicatedStorage before client references them |
| Changes not syncing | Reconnect Rojo plugin, or rebuild with `rojo build` |
| "Infinite yield" warning | You're waiting for something that doesn't exist — check names |
| Multiplayer desynced | Ensure game state is server-authoritative, not client-side |
