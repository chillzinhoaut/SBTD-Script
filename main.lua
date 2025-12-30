-- ============================================================
-- SPONGEBOB TOWER DEFENSE - MASTER SCRIPT
-- Multi-Modular System mit WindUI
-- ============================================================

print("=== SPONGEBOB TD SCRIPT WIRD GELADEN ===")

-- WindUI Bibliothek laden
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Hauptfenster erstellen
local Window = WindUI:CreateWindow({
    Title = "Spongebob Tower Defense",
    Folder = "SpongebobTD",
})

-- ============================================================
-- MODULE CONFIGURATION
-- ============================================================

local GITHUB_CONFIG = {
    Username = "chillzinhoaut",
    Repository = "SBTD-Script",
    Branch = "main",
    Version = "1.2.0",  -- WICHTIG: Erhöhe diese Nummer bei jedem Update für sofortige Änderungen!
}

-- Basis-URL für Module mit Cache-Busting
local MODULE_BASE_URL = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/modules/",
    GITHUB_CONFIG.Username,
    GITHUB_CONFIG.Repository,
    GITHUB_CONFIG.Branch
)

-- Cache-Busting Parameter
local CACHE_BUSTER = "?v=" .. GITHUB_CONFIG.Version

-- ============================================================
-- MODULE LOADER
-- ============================================================

local Modules = {}

-- Hilfsfunktion: Modul von GitHub laden (mit Cache-Busting)
local function LoadModule(moduleName)
    local url = MODULE_BASE_URL .. moduleName .. ".lua" .. CACHE_BUSTER
    print(string.format("[MODULE LOADER] Lade Modul: %s (Version: %s)", moduleName, GITHUB_CONFIG.Version))
    print(string.format("[MODULE LOADER] URL: %s", url))

    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)

    if success then
        print(string.format("[MODULE LOADER] ✓ Modul '%s' erfolgreich geladen!", moduleName))
        return result
    else
        warn(string.format("[MODULE LOADER] ✗ Fehler beim Laden von '%s':", moduleName), result)
        return nil
    end
end

-- ============================================================
-- MAIN TAB - Script Info
-- ============================================================

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "rbxassetid://10734923549"
})

local InfoSection = MainTab:Section({
    Title = "Script Information",
})

InfoSection:Section({
    Title = "Welcome to Spongebob Tower Defense Script",
    TextSize = 16,
    TextTransparency = 0.35,
})

InfoSection:Section({
    Title = "Version: " .. GITHUB_CONFIG.Version .. " | Multi-Modular System",
    TextSize = 14,
    TextTransparency = 0.35,
})

InfoSection:Section({
    Title = "Module werden von GitHub geladen...",
    TextSize = 12,
    TextTransparency = 0.35,
})

-- ============================================================
-- AUTOMATION TAB (Shared by all automation modules)
-- ============================================================

local AutomationTab = Window:Tab({
    Title = "Automation",
    Icon = "rbxassetid://10734950309"
})

-- ============================================================
-- MODULE LOADING
-- ============================================================

print("[MASTER] Lade Module von GitHub...")

-- Reward Claimer Modul laden
Modules.RewardClaimer = LoadModule("reward_claimer")

if Modules.RewardClaimer then
    Modules.RewardClaimer:Init(Window, AutomationTab)
else
    warn("[MASTER] Reward Claimer Modul konnte nicht geladen werden!")
    warn("[MASTER] Überprüfe die GitHub-Konfiguration und stelle sicher, dass modules/reward_claimer.lua existiert!")
end

-- Crates Opener Modul laden
Modules.CratesOpener = LoadModule("crates_opener")

if Modules.CratesOpener then
    Modules.CratesOpener:Init(Window, AutomationTab)
else
    warn("[MASTER] Crates Opener Modul konnte nicht geladen werden!")
end

-- Lobby Features Modul laden
Modules.LobbyFeatures = LoadModule("lobby_features")

if Modules.LobbyFeatures then
    Modules.LobbyFeatures:Init(Window, AutomationTab)
else
    warn("[MASTER] Lobby Features Modul konnte nicht geladen werden!")
end

-- Hier können weitere Module geladen werden:
-- Modules.TowerHelper = LoadModule("tower_helper")
-- if Modules.TowerHelper then Modules.TowerHelper:Init(Window, AutomationTab) end

print("=== SPONGEBOB TD SCRIPT ERFOLGREICH GELADEN ===")
print("Module aktiv:", #Modules, "| Viel Spaß!")
