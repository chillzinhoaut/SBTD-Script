# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Multi-modular Roblox exploit script for Spongebob Tower Defense using WindUI library. Scripts are executed via Codex Executor and loaded from GitHub for easy updates.

## Critical Architecture Patterns

### Module System

**Main Entry Point:** `main.lua`
- Loads WindUI library from GitHub
- Creates Window and AutomationTab
- Dynamically loads modules from GitHub with cache-busting
- Passes `Window` and `AutomationTab` to each module's `:Init()` function

**Module Structure:**
Every module in `modules/` must follow this pattern:
```lua
local ModuleName = {}

function ModuleName:Init(window, automationTab)
    -- Use automationTab:Toggle() to create UI elements
    -- Toggles are created DIRECTLY on Tab, NOT on Section
end

function ModuleName:Cleanup()
    -- Cleanup code
end

return ModuleName
```

**CRITICAL WindUI API Rules:**
- Toggles MUST be created with `Tab:Toggle()`, NOT `Section:Toggle()`
- WindUI hierarchy: `Window → Tab → Toggle` (Sections do NOT support toggles)
- Toggle parameters: `Title`, `Desc` (NOT Description), `Value` (NOT Default), `Callback`
- Correct syntax:
  ```lua
  automationTab:Toggle({
      Title = "Feature Name",
      Desc = "Description",
      Value = false,
      Callback = function(value) end
  })
  ```

### Cache-Busting System

Updates to modules require version bump in `main.lua` GITHUB_CONFIG for instant deployment:

1. Change `Version = "1.2.3"` to next version (e.g., `"1.2.4"`)
2. Commit and push
3. Users get update immediately (bypasses GitHub's 5-minute cache)

Module URLs automatically append `?v=VERSION` query parameter.

### Game-Specific Integration

**Knit Framework Detection:**
Modules access game services via:
```lua
ReplicatedStorage.Packages._Index["acecateer_knit@1.7.1"].knit.Services.ServiceName.RF.FunctionName:InvokeServer(args)
```

**Silent UI Blocking Pattern:**
To prevent game popups/animations, override controller functions:
```lua
local Knit = require(ReplicatedStorage.Packages.Knit)
local UIController = Knit.GetController("UIController")
UIController.GuiModules.ItemRoll._doRoll = function() return end
```

See `reward_claimer.lua` SetupRewardBlocker() for full implementation.

## Development Workflow

### Adding New Features

1. Create module in `modules/new_feature.lua`
2. Implement `:Init(window, automationTab)` and `:Cleanup()` methods
3. Add to `main.lua` module loading section:
   ```lua
   Modules.NewFeature = LoadModule("new_feature")
   if Modules.NewFeature then
       Modules.NewFeature:Init(Window, AutomationTab)
   end
   ```
4. Increment version in `GITHUB_CONFIG.Version`
5. Commit with message format: `"Add [Feature] (v1.X.X)"`

### Git Workflow

**Standard commit:**
```bash
git add .
git commit -m "Description"
git push
```

**Version must be incremented in main.lua** for cache-busting to work.

**Commit message format used:**
```
[Action]: [Description] (v1.X.X)

[Detailed changes]
- Bullet points
- Technical details

Version: X.Y.Z → X.Y.Z+1

🤖 Generated with Claude Code
```

### Using the Roblox Agent

For WindUI-specific tasks, use the `roblox-windui-scripter` agent:
```
Use the Task tool with subagent_type="roblox-windui-scripter" for:
- Creating new WindUI components
- Debugging WindUI syntax errors
- Checking WindUI documentation compliance
```

## Current Modules

- **reward_claimer.lua**: Auto-claims daily timed rewards (1-9) in 60s loop with animation blocking
- **crates_opener.lua**: Opens treasure chests automatically with in-game notifications
- **lobby_features.lua**: Achievements, Season Pass, and Prestige automation

## Repository Structure

```
SBTD-Script/
├── main.lua                     # Master script - loads WindUI and modules
├── modules/
│   ├── reward_claimer.lua       # Daily rewards automation
│   ├── crates_opener.lua        # Treasure chest opener
│   └── lobby_features.lua       # Lobby automation features
└── README.md                    # User documentation
```

## Testing

Execute in Codex Executor:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/chillzinhoaut/SBTD-Script/main/main.lua"))()
```

For immediate testing after changes, increment version number first.
