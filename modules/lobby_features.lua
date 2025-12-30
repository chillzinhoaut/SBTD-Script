-- Lobby Features Modul
-- Auto Claim Achievements, Season Pass, Prestige

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyFeatures = {}

-- Services
local ProgressionService = nil
local SeasonPassService = nil
local StatsService = nil

-- Initialize Services
local function InitializeServices()
    local success = pcall(function()
        local knit = ReplicatedStorage.Packages._Index["acecateer_knit@1.7.1"].knit.Services
        ProgressionService = knit.ProgressionService.RF
        SeasonPassService = knit.SeasonPassService.RF
        StatsService = knit.StatsService.RF
    end)

    if success then
        print("[LOBBY FEATURES] Services erfolgreich initialisiert")
    else
        warn("[LOBBY FEATURES] Fehler beim Initialisieren der Services")
    end

    return success
end

-- Auto Claim Achievements
function LobbyFeatures.ClaimAchievements(questType)
    if not ProgressionService then return false end

    local success, result = pcall(function()
        return ProgressionService.ClaimAllQuests:InvokeServer(questType)
    end)

    if success then
        print(string.format("[LOBBY FEATURES] ✓ %s Achievements geclaimt", questType))
        return true
    else
        warn(string.format("[LOBBY FEATURES] ✗ Fehler beim Claimen von %s:", questType), result)
        return false
    end
end

-- Auto Claim Pass
function LobbyFeatures.ClaimPass()
    if not SeasonPassService then return false end

    local success, result = pcall(function()
        return SeasonPassService.ClaimAll:InvokeServer()
    end)

    if success then
        print("[LOBBY FEATURES] ✓ Season Pass geclaimt")
        return true
    else
        warn("[LOBBY FEATURES] ✗ Fehler beim Claimen des Season Pass:", result)
        return false
    end
end

-- Auto Prestige Pass
function LobbyFeatures.PrestigePass()
    if not SeasonPassService then return false end

    local success, result = pcall(function()
        return SeasonPassService.PrestigePass:InvokeServer()
    end)

    if success then
        print("[LOBBY FEATURES] ✓ Season Pass Prestige durchgeführt")
        return true
    else
        warn("[LOBBY FEATURES] ✗ Fehler beim Season Pass Prestige:", result)
        return false
    end
end

-- Auto Prestige
function LobbyFeatures.Prestige()
    if not StatsService then return false end

    local success, result = pcall(function()
        return StatsService.Prestige:InvokeServer()
    end)

    if success then
        print("[LOBBY FEATURES] ✓ Prestige durchgeführt")
        return true
    else
        warn("[LOBBY FEATURES] ✗ Fehler beim Prestige:", result)
        return false
    end
end

-- Modul-Initialisierung
function LobbyFeatures:Init(window, automationTab, lobbySection)
    print("[LOBBY FEATURES] Modul wird initialisiert...")

    -- Services initialisieren
    if not InitializeServices() then
        warn("[LOBBY FEATURES] Services konnten nicht initialisiert werden!")
        return
    end

    -- Verwende die übergebene Lobby Section
    local LobbySection = lobbySection

    -- Auto Claim ALL Achievements (kombiniert alle 4 Typen)
    LobbySection:Toggle({
        Title = "Auto Claim Achievements",
        Desc = "Claimt alle Achievements (Daily, Weekly, Infinite, Party)",
        Value = false,
        Callback = function(value)
            if value then
                LobbyFeatures.ClaimAchievements("Daily")
                task.wait(0.1)
                LobbyFeatures.ClaimAchievements("Weekly")
                task.wait(0.1)
                LobbyFeatures.ClaimAchievements("Infinite")
                task.wait(0.1)
                LobbyFeatures.ClaimAchievements("Party")
            end
        end
    })

    -- Auto Claim Season Pass
    LobbySection:Toggle({
        Title = "Auto Claim Pass",
        Desc = "Claimt automatisch alle Season Pass Belohnungen",
        Value = false,
        Callback = function(value)
            if value then
                LobbyFeatures.ClaimPass()
            end
        end
    })

    -- Auto Prestige Pass
    LobbySection:Toggle({
        Title = "Auto Prestige Pass",
        Desc = "Führt automatisch Season Pass Prestige durch",
        Value = false,
        Callback = function(value)
            if value then
                LobbyFeatures.PrestigePass()
            end
        end
    })

    -- Auto Prestige
    LobbySection:Toggle({
        Title = "Auto Prestige",
        Desc = "Führt automatisch Prestige durch",
        Value = false,
        Callback = function(value)
            if value then
                LobbyFeatures.Prestige()
            end
        end
    })

    print("[LOBBY FEATURES] Modul erfolgreich geladen!")
end

-- Cleanup Funktion
function LobbyFeatures:Cleanup()
    print("[LOBBY FEATURES] Modul wurde entladen")
end

return LobbyFeatures
