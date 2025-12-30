-- Auto Crates Opener Modul
-- Automatisches Öffnen von Treasure Chests mit Notifications

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local CratesOpener = {}
CratesOpener.Enabled = false
CratesOpener.OpenDelay = 0.5  -- Verzögerung zwischen jedem Öffnen

-- Whitelist für die Kisten
local ITEM_WHITELIST = {
    ["EpicTreasureChest"] = true,
    ["LegendaryTreasureChest"] = true,
    ["MythicTreasureChest"] = true,
    ["ExoticTreasureChest"] = true
}

-- RNGRolls zur Whitelist hinzufügen
local function UpdateWhitelist()
    local rngRolls = ReplicatedStorage:FindFirstChild("RNGRolls")
    if rngRolls then
        for _, item in pairs(rngRolls:GetChildren()) do
            ITEM_WHITELIST[item.Name] = true
        end
        print("[CRATES OPENER] RNGRolls zur Whitelist hinzugefügt")
    end
end

-- Hilfsfunktion: Anzahl der Items ermitteln
local function GetItemAmount(item)
    local amountObj = item:FindFirstChild("Content")
        and item.Content:FindFirstChild("Info")
        and item.Content.Info:FindFirstChild("Amount")

    if not amountObj then return 0 end

    local rawValue = ""
    if amountObj:IsA("TextLabel") or amountObj:IsA("TextBox") then
        rawValue = amountObj.Text
    elseif amountObj:IsA("StringValue") then
        rawValue = amountObj.Value
    end

    -- Formatierung: "x11" -> 11
    local cleanAmountStr = string.gsub(rawValue, "x", "")
    return tonumber(cleanAmountStr) or 0
end

-- Hilfsfunktion: Alle verfügbaren Crates zählen
local function CountTotalCrates()
    local success, binPath = pcall(function()
        return LocalPlayer.PlayerGui.Items.Main.Content.Bin
    end)

    if not success or not binPath then return 0 end

    local total = 0
    for _, item in pairs(binPath:GetChildren()) do
        if ITEM_WHITELIST[item.Name] then
            total = total + GetItemAmount(item)
        end
    end

    return total
end

-- Hilfsfunktion: In-Game Notification senden
local function SendNotification(title, text, duration)
    local success = pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3,
        })
    end)

    if not success then
        -- Fallback auf Console-Print
        print(string.format("[NOTIFICATION] %s: %s", title, text))
    end
end

-- Haupt-Öffnungs-Funktion (öffnet EINE Kiste)
local function OpenNextCrate()
    local success, result = pcall(function()
        local binPath = LocalPlayer.PlayerGui.Items.Main.Content.Bin
        local treasureRemote = ReplicatedStorage.Packages._Index["acecateer_knit@1.7.1"]
            .knit.Services.TreasureService.RF.Open

        for _, item in pairs(binPath:GetChildren()) do
            if ITEM_WHITELIST[item.Name] then
                local currentAmount = GetItemAmount(item)

                if currentAmount > 0 then
                    -- Remote aufrufen
                    treasureRemote:InvokeServer(item.Name)

                    local remaining = currentAmount - 1
                    local totalRemaining = CountTotalCrates() - 1

                    -- Console Output
                    print(string.format("[CRATES OPENER] ✓ %s geöffnet | Verbleibend: %d (Total: %d)",
                        item.Name, remaining, totalRemaining))

                    -- In-Game Notification
                    SendNotification(
                        "Crate Opened",
                        string.format("%s geöffnet\n%d übrig (Total: %d)", item.Name, remaining, totalRemaining),
                        2
                    )

                    return {
                        success = true,
                        crateName = item.Name,
                        remaining = remaining,
                        totalRemaining = totalRemaining
                    }
                end
            end
        end

        return { success = false, message = "Keine Crates gefunden" }
    end)

    if success then
        return result
    else
        warn("[CRATES OPENER] Fehler:", result)
        return { success = false, message = result }
    end
end

-- Haupt-Loop für Auto-Opening
local function OpeningLoop()
    while CratesOpener.Enabled do
        local totalCrates = CountTotalCrates()

        if totalCrates == 0 then
            print("[CRATES OPENER] 🎉 Inventory cleared - Alle Crates geöffnet!")
            SendNotification("Inventory Cleared", "Alle Crates wurden geöffnet! 🎉", 4)
            CratesOpener.Enabled = false
            break
        end

        print(string.format("[CRATES OPENER] Öffne Crates... (Total übrig: %d)", totalCrates))

        local result = OpenNextCrate()

        if not result.success then
            warn("[CRATES OPENER] Keine weiteren Crates zum Öffnen")
            CratesOpener.Enabled = false
            break
        end

        task.wait(CratesOpener.OpenDelay)
    end

    if not CratesOpener.Enabled then
        print("[CRATES OPENER] Auto-Open gestoppt.")
    end
end

-- Modul-Initialisierung
function CratesOpener:Init(window, automationTab)
    print("[CRATES OPENER] Modul wird initialisiert...")

    -- Whitelist updaten
    UpdateWhitelist()

    -- Verwende den übergebenen Automation Tab
    local AutomationTab = automationTab

    -- Crates Section erstellen
    local CratesSection = AutomationTab:Section({
        Title = "Treasure Chests"
    })

    -- Toggle für Auto-Open
    CratesSection:Toggle({
        Title = "Auto Open Crates",
        Description = "Öffnet automatisch alle Treasure Chests im Inventar",
        Default = false,
        Callback = function(value)
            CratesOpener.Enabled = value

            if value then
                local totalCrates = CountTotalCrates()
                print(string.format("[CRATES OPENER] Auto-Open aktiviert! (%d Crates gefunden)", totalCrates))

                if totalCrates > 0 then
                    task.spawn(OpeningLoop)
                else
                    warn("[CRATES OPENER] Keine Crates im Inventar gefunden!")
                    CratesOpener.Enabled = false
                end
            else
                print("[CRATES OPENER] Auto-Open deaktiviert!")
            end
        end
    })

    -- Info Sektion
    local InfoSection = AutomationTab:Section({
        Title = "ℹ️ Crates Info"
    })

    InfoSection:Section({
        Title = "Öffnet: Epic, Legendary, Mythic, Exotic & RNG Rolls",
        TextSize = 14,
        TextTransparency = 0.35,
    })

    InfoSection:Section({
        Title = "Notification bei jeder geöffneten Chest",
        TextSize = 14,
        TextTransparency = 0.35,
    })

    print("[CRATES OPENER] Modul erfolgreich geladen!")
end

-- Cleanup Funktion
function CratesOpener:Cleanup()
    CratesOpener.Enabled = false
    print("[CRATES OPENER] Modul wurde entladen")
end

return CratesOpener
