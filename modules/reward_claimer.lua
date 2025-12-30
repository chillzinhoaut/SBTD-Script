-- Timed Rewards Auto-Claimer Modul
-- Automatisches Claimen von Daily Rewards 1-9 mit Popup/Animation Blocker

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RewardClaimer = {}
RewardClaimer.Enabled = false
RewardClaimer.ClaimDelay = 0.5
RewardClaimer.LoopConnection = nil

-- Blocker für Animationen und Popups
local function SetupRewardBlocker()
    local success, err = pcall(function()
        local Knit = require(ReplicatedStorage.Packages.Knit)

        -- Zugriff auf die identifizierten Controller
        local UIController = Knit.GetController("UIController")
        local ItemRoll = UIController.GuiModules.ItemRoll
        local FOVController = Knit.GetController("FOVController")
        local BlurController = Knit.GetController("BlurController")

        print("[REWARD BLOCKER] Aktiviere Silent Reward System...")

        -- 1. Blockiert die 'Roll'-Animation der Items komplett
        ItemRoll._doRoll = function() return end
        ItemRoll.Opened = function() return end

        -- 2. Verarbeitet Belohnungen sofort ohne UI-Wartezeit
        ItemRoll.QueueRewards = function(self, rewards)
            -- Items landen hier, werden aber nicht visuell angezeigt
            return
        end

        -- 3. Blockiert die Kamera-Zooms (FOV) und Unschärfe (Blur)
        FOVController.SetFOV = function() return end
        FOVController._tween = function() return end
        BlurController.SetBlur = function() return end
        BlurController._tween = function() return end

        -- 4. Verhindert, dass das Menü sich beim Schließen der Animation neu fokussiert
        local PlaytimePrizes = UIController.GuiModules.PlaytimePrizes
        PlaytimePrizes.Opened = function() return end

        print("[REWARD BLOCKER] Alle Animationen erfolgreich deaktiviert!")
        return true
    end)

    if not success then
        warn("[REWARD BLOCKER] Fehler beim Setup:", err)
        return false
    end

    return true
end

-- Claim Funktion für einzelne Rewards
local function ClaimReward(rewardNumber)
    local success, result = pcall(function()
        local prizeService = ReplicatedStorage.Packages._Index["acecateer_knit@1.7.1"]
            .knit.Services.PlaytimePrizeService.RF.ClaimPrize
        return prizeService:InvokeServer(rewardNumber)
    end)

    if success then
        print(string.format("[REWARD CLAIMER] ✓ Reward #%d geclaimt", rewardNumber))
        return true
    else
        warn(string.format("[REWARD CLAIMER] ✗ Fehler bei Reward #%d:", rewardNumber), result)
        return false
    end
end

-- Haupt-Loop für Auto-Claiming
local function ClaimLoop()
    while RewardClaimer.Enabled do
        print("[REWARD CLAIMER] Starte Claim-Zyklus (1-9)...")

        for i = 1, 9 do
            if not RewardClaimer.Enabled then break end
            ClaimReward(i)
            task.wait(RewardClaimer.ClaimDelay)
        end

        print("[REWARD CLAIMER] Zyklus abgeschlossen. Warte 60 Sekunden...")

        -- Warte 60 Sekunden oder bis Toggle deaktiviert wird
        local waitTime = 0
        while waitTime < 60 and RewardClaimer.Enabled do
            task.wait(1)
            waitTime = waitTime + 1
        end
    end

    print("[REWARD CLAIMER] Auto-Claim gestoppt.")
end

-- Modul-Initialisierung
function RewardClaimer:Init(window)
    print("[REWARD CLAIMER] Modul wird initialisiert...")

    -- Setup Blocker beim Start
    SetupRewardBlocker()

    -- Erstelle Automation Tab
    local AutomationTab = window:Tab({
        Title = "Automation",
        Icon = "rbxassetid://10734950309" -- Zahnrad/Gear Icon
    })

    -- Erstelle Hauptsektion
    local MainSection = AutomationTab:Section({
        Title = "Daily Rewards"
    })

    -- Toggle für Auto-Claim
    local ClaimToggle = MainSection:Toggle({
        Title = "Auto Claim Timed Rewards",
        Description = "Claimt automatisch alle Daily Rewards (1-9) im Loop",
        Default = false,
        Callback = function(value)
            RewardClaimer.Enabled = value

            if value then
                print("[REWARD CLAIMER] Auto-Claim aktiviert!")
                -- Starte Loop in neuem Thread
                task.spawn(ClaimLoop)
            else
                print("[REWARD CLAIMER] Auto-Claim deaktiviert!")
            end
        end
    })

    -- Info Sektion
    local InfoSection = AutomationTab:Section({
        Title = "ℹ️ Information"
    })

    InfoSection:Label({
        Title = "Das Script claimt alle 60 Sekunden die Rewards 1-9",
        TextSize = 14
    })

    InfoSection:Label({
        Title = "Popups und Animationen werden automatisch blockiert",
        TextSize = 14
    })

    print("[REWARD CLAIMER] Modul erfolgreich geladen!")
end

-- Cleanup Funktion
function RewardClaimer:Cleanup()
    RewardClaimer.Enabled = false
    print("[REWARD CLAIMER] Modul wurde entladen")
end

return RewardClaimer
