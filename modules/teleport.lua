-- Teleport Modul mit Failsafe
-- Automatisches Teleportieren zu Maps mit Retry-Logik

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Teleport = {}

-- Settings
Teleport.SelectedMode = "Story"
Teleport.SelectedMap = "ConchStreet"
Teleport.SelectedChapter = 1
Teleport.SelectedDiff = 1  -- 1=Normal, 2=Hard, 3=Nightmare, 4=DavyJones

-- Failsafe State
local isRetrying = false
local attemptCount = 0
local onTeleportConnection = nil

-- Maps und Difficulty
local MAPS = {"ChumBucket", "ConchStreet", "JellyfishFields", "KampKoral", "KrustyKrab", "RockBottom", "SandysTreedome"}
local MODES = {"Story", "Challenge", "Raid"}
local DIFF_NAMES = {[1] = "Normal", [2] = "Hard", [3] = "Nightmare", [4] = "DavyJones"}
local DIFF_TO_NUM = {Normal = 1, Hard = 2, Nightmare = 3, DavyJones = 4}

-- Services
local Knit = nil
local FastTravel = nil
local ReplicaCreate = nil
local ReplicaSignal = nil

-- Initialize Services
local function InitializeServices()
    local success = pcall(function()
        Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"))
        FastTravel = Knit.GetController("FastTravelController")
        ReplicaCreate = ReplicatedStorage:WaitForChild("ReplicaRemoteEvents"):WaitForChild("Replica_ReplicaCreate")
        ReplicaSignal = ReplicatedStorage:WaitForChild("ReplicaRemoteEvents"):WaitForChild("Replica_ReplicaSignal")
    end)

    if success then
        print("[TELEPORT] Services initialisiert")
        return true
    else
        warn("[TELEPORT] Fehler beim Initialisieren der Services")
        return false
    end
end

-- Story Sequence mit Failsafe
local function RunStorySequence()
    if isRetrying then
        print("[TELEPORT] Failsafe läuft bereits")
        return
    end

    isRetrying = true
    attemptCount = 0

    task.spawn(function()
        local successState = false

        while isRetrying and not successState do
            attemptCount = attemptCount + 1
            print(string.format("[TELEPORT] Versuch #%d - Starte Map...", attemptCount))

            -- 1. Teleport zu leerer Queue
            if not FastTravel then break end

            local tpSuccess = pcall(function()
                FastTravel:_attemptTeleportToEmptyQueue()
            end)

            if not tpSuccess then
                warn("[TELEPORT] Fehler beim Teleport zur Queue")
                task.wait(2)
                continue
            end

            local connection
            local attemptStart = os.clock()

            -- 2. Queue Event Listener
            connection = ReplicaCreate.OnClientEvent:Connect(function(id, data)
                if data and type(data) == "table" and data[1] and tostring(data[1]):find("Queue") then
                    task.wait(0.8)

                    -- Map-Daten modifizieren (Deep Clone)
                    local modifiedData = {data[1], data[2], table.clone(data[3] or {}), data[4]}
                    if modifiedData[3] then
                        modifiedData[3]["Stage"] = Teleport.SelectedMap
                        modifiedData[3]["Chapter"] = Teleport.SelectedChapter
                        modifiedData[3]["Difficulty"] = Teleport.SelectedDiff
                        modifiedData[3]["confirmedMap"] = true
                    end

                    -- Firesignal mit modifizierten Daten
                    if type(firesignal) == "function" then
                        firesignal(ReplicaCreate.OnClientEvent, id, modifiedData)
                        print("[TELEPORT] Queue-Daten modifiziert und Signal gefeuert")
                    else
                        warn("[TELEPORT] firesignal nicht verfügbar!")
                    end

                    task.wait(0.6)

                    -- Map bestätigen
                    local confirmSuccess = pcall(function()
                        ReplicaSignal:FireServer(id, "ConfirmMap", {
                            ["Difficulty"] = tonumber(Teleport.SelectedDiff),
                            ["Chapter"] = tonumber(Teleport.SelectedChapter),
                            ["Endless"] = false,
                            ["World"] = tostring(Teleport.SelectedMap)
                        })
                    end)

                    if confirmSuccess then
                        print("[TELEPORT] Map bestätigt")
                    end

                    task.wait(0.8)

                    -- Spiel starten
                    local startSuccess = pcall(function()
                        ReplicaSignal:FireServer(id, "StartGame")
                    end)

                    if startSuccess then
                        print("[TELEPORT] StartGame gesendet")
                        successState = true
                        -- Connection sofort disconnecten bei Erfolg
                        if connection then
                            connection:Disconnect()
                        end
                    end
                end
            end)

            -- Timeout nach 8 Sekunden (checkt auch successState)
            repeat
                task.wait(0.5)
            until os.clock() - attemptStart > 8 or successState or not isRetrying

            if connection then
                connection:Disconnect()
            end

            -- Check ob erfolgreich
            if not successState and isRetrying then
                print("[TELEPORT] Versuch fehlgeschlagen, wiederhole...")
                task.wait(1)
            end

            -- Max 30 Versuche
            if attemptCount >= 30 then
                warn("[TELEPORT] Maximale Versuche erreicht (30)")
                isRetrying = false
            end
        end

        if successState then
            print(string.format("[TELEPORT] ✓ Erfolgreich nach %d Versuchen!", attemptCount))
        end

        isRetrying = false
    end)
end

-- Teleport zu Matchmaker (für Challenge/Raid)
local function TeleportToMatchmaker(modeName)
    local matchmakers = workspace:FindFirstChild("Matchmakers")
    if not matchmakers then
        warn("[TELEPORT] Keine Matchmakers gefunden")
        return false
    end

    for _, area in ipairs(matchmakers:GetChildren()) do
        if area:GetAttribute("Mode") == modeName and tonumber(area:GetAttribute("Difficulty")) == Teleport.SelectedDiff then
            local success, pivot = pcall(function()
                return area:GetPivot()
            end)

            if success and pivot then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = pivot
                    print(string.format("[TELEPORT] ✓ Zu %s teleportiert", modeName))
                    return true
                end
            end
        end
    end

    warn(string.format("[TELEPORT] Kein Matchmaker für %s gefunden", modeName))
    return false
end

-- Stop Failsafe
local function StopFailsafe()
    isRetrying = false
    attemptCount = 0
    print("[TELEPORT] Failsafe gestoppt")
end

-- Modul Initialisierung
function Teleport:Init(window, automationTab)
    print("[TELEPORT] Modul wird initialisiert...")

    if not InitializeServices() then
        warn("[TELEPORT] Konnte Services nicht initialisieren!")
        return
    end

    -- Teleport Tab erstellen
    local TeleportTab = window:CreateTab({
        Title = "Teleport",
        Icon = "rbxassetid://10734898355"
    })

    -- Mode Selection
    TeleportTab:Dropdown({
        Title = "Mode",
        Desc = "Wähle den Spielmodus",
        Options = MODES,
        Value = Teleport.SelectedMode,
        Callback = function(value)
            Teleport.SelectedMode = value
            print("[TELEPORT] Mode:", value)
        end
    })

    -- Story Map
    TeleportTab:Dropdown({
        Title = "Story Map",
        Desc = "Wähle die Map",
        Options = MAPS,
        Value = Teleport.SelectedMap,
        Callback = function(value)
            Teleport.SelectedMap = value
            print("[TELEPORT] Map:", value)
        end
    })

    -- Chapter
    TeleportTab:Dropdown({
        Title = "Chapter",
        Desc = "Wähle das Chapter",
        Options = {"1","2","3","4","5","6","7","8","9","10"},
        Value = tostring(Teleport.SelectedChapter),
        Callback = function(value)
            Teleport.SelectedChapter = tonumber(value)
            print("[TELEPORT] Chapter:", value)
        end
    })

    -- Difficulty
    TeleportTab:Dropdown({
        Title = "Difficulty",
        Desc = "Wähle die Schwierigkeit",
        Options = {"Normal", "Hard", "Nightmare", "DavyJones"},
        Value = DIFF_NAMES[Teleport.SelectedDiff],
        Callback = function(value)
            Teleport.SelectedDiff = DIFF_TO_NUM[value]
            print("[TELEPORT] Difficulty:", value)
        end
    })

    -- Start Button
    TeleportTab:Button({
        Title = "🚀 START TELEPORT",
        Desc = "Startet den Teleport mit Failsafe",
        Callback = function()
            if Teleport.SelectedMode == "Story" then
                -- Proper stop/wait vor neuem Start
                StopFailsafe()
                repeat task.wait(0.05) until not isRetrying
                RunStorySequence()
            else
                TeleportToMatchmaker(Teleport.SelectedMode)
            end
        end
    })

    -- Stop Button
    TeleportTab:Button({
        Title = "🛑 STOP FAILSAFE",
        Desc = "Stoppt die Retry-Schleife",
        Callback = function()
            StopFailsafe()
        end
    })

    -- OnTeleport Event (stoppt Failsafe bei PlaceId-Wechsel)
    onTeleportConnection = LocalPlayer.OnTeleport:Connect(function()
        isRetrying = false
    end)

    print("[TELEPORT] Modul erfolgreich geladen!")
end

-- Cleanup
function Teleport:Cleanup()
    StopFailsafe()
    if onTeleportConnection then
        onTeleportConnection:Disconnect()
        onTeleportConnection = nil
    end
    print("[TELEPORT] Modul entladen")
end

return Teleport
