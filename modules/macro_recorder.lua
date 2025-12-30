local MacroRecorder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

print("[MACRO DEBUG] Loading services...")

local TowerService, GameService
local spyModeEnabled = false

local success1 = pcall(function()
    TowerService = ReplicatedStorage.Packages._Index["acecateer_knit@1.7.1"].knit.Services.TowerService.RF
end)

if success1 and TowerService then
    print("[MACRO DEBUG] TowerService loaded:", tostring(TowerService))

    local pathSuccess, pathResult = pcall(function() return TowerService:GetFullName() end)
    print("[MACRO DEBUG] TowerService path:", pathSuccess and pathResult or "N/A")

    print("[MACRO DEBUG] TowerService RemoteFunctions:")
    local childSuccess = pcall(function()
        for _, v in pairs(TowerService:GetChildren()) do
            if v:IsA("RemoteFunction") then
                local vPathSuccess, vPath = pcall(function() return v:GetFullName() end)
                print("  - RemoteFunction:", v.Name, "|", vPathSuccess and vPath or "N/A")
            end
        end
    end)

    if TowerService.PlaceTower then
        print("[MACRO DEBUG] PlaceTower type:", typeof(TowerService.PlaceTower))
        local ptPathSuccess, ptPath = pcall(function() return TowerService.PlaceTower:GetFullName() end)
        print("[MACRO DEBUG] PlaceTower path:", ptPathSuccess and ptPath or "N/A")
        print("[MACRO DEBUG] PlaceTower.InvokeServer:", tostring(TowerService.PlaceTower.InvokeServer))
    else
        print("[MACRO DEBUG] TowerService.PlaceTower: nil")
    end
else
    print("[MACRO DEBUG] ERROR: Failed to load TowerService")
    TowerService = nil
end

local success2 = pcall(function()
    GameService = ReplicatedStorage.Packages._Index["acecateer_knit@1.7.1"].knit.Services.GameService.RF
end)

if success2 and GameService then
    print("[MACRO DEBUG] GameService loaded:", tostring(GameService))

    local pathSuccess, pathResult = pcall(function() return GameService:GetFullName() end)
    print("[MACRO DEBUG] GameService path:", pathSuccess and pathResult or "N/A")

    print("[MACRO DEBUG] GameService RemoteFunctions:")
    local childSuccess = pcall(function()
        for _, v in pairs(GameService:GetChildren()) do
            if v:IsA("RemoteFunction") then
                local vPathSuccess, vPath = pcall(function() return v:GetFullName() end)
                print("  - RemoteFunction:", v.Name, "|", vPathSuccess and vPath or "N/A")
            end
        end
    end)

    if GameService.UpgradeTower then
        print("[MACRO DEBUG] UpgradeTower type:", typeof(GameService.UpgradeTower))
        local utPathSuccess, utPath = pcall(function() return GameService.UpgradeTower:GetFullName() end)
        print("[MACRO DEBUG] UpgradeTower path:", utPathSuccess and utPath or "N/A")
        print("[MACRO DEBUG] UpgradeTower.InvokeServer:", tostring(GameService.UpgradeTower.InvokeServer))
    else
        print("[MACRO DEBUG] GameService.UpgradeTower: nil")
    end
else
    print("[MACRO DEBUG] ERROR: Failed to load GameService")
    GameService = nil
end

local currentMacro = nil
local isRecording = false
local recordConnection = nil
local savedMacros = getgenv().SavedMacros or {}
getgenv().SavedMacros = savedMacros

local currentMacroName = "Macro1"
local statusLabel = nil
local macroListSection = nil
local recordToggle = nil

local towerInstanceCounts = {}
local playbackTowerMap = {}
local isPlaying = false
local playbackConnection = nil

-- Notification helper
local function SendNotification(title, content)
    local success = pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = content,
            Duration = 3,
        })
    end)

    if not success then
        print(string.format("[MACRO] %s: %s", title, content))
    end
end

local function getNextInstanceIndex(towerName)
    if not towerInstanceCounts[towerName] then
        towerInstanceCounts[towerName] = 0
    end
    towerInstanceCounts[towerName] = towerInstanceCounts[towerName] + 1
    return towerInstanceCounts[towerName]
end

local function updateStatus(text)
    if statusLabel then
        pcall(function()
            statusLabel:Set({
                Title = "Recording Status",
                Content = text
            })
        end)
    end
    print("[MACRO STATUS] " .. text)
end

local function startRecording()
    if isRecording then
        print("[MACRO DEBUG] Already recording, ignoring start request")
        return
    end

    print("[MACRO DEBUG] Starting recording process...")
    print("[MACRO DEBUG] hookfunction available:", hookfunction ~= nil)
    print("[MACRO DEBUG] hookmetamethod available:", hookmetamethod ~= nil)

    isRecording = true
    towerInstanceCounts = {}

    currentMacro = {
        name = currentMacroName,
        actions = {}
    }

    updateStatus("Recording... Place towers and upgrade them")
    SendNotification("Macro Recording", "Started recording " .. currentMacroName)

    if not TowerService or not GameService then
        print("[MACRO DEBUG] ERROR: Services not loaded!")
        SendNotification("Recording Error", "Services not available")
        isRecording = false
        return
    end

    local oldPlaceTower = nil
    local oldUpgradeTower = nil
    local namecallHook = nil

    if hookfunction then
        print("[MACRO DEBUG] Using hookfunction method...")

        print("[MACRO DEBUG] Attempting to hook TowerService.PlaceTower.InvokeServer...")
        local hookSuccess1 = pcall(function()
            oldPlaceTower = hookfunction(TowerService.PlaceTower.InvokeServer, function(self, cframe, slot)
                print("[MACRO DEBUG] HOOK CALLED: PlaceTower (hookfunction)")
                print("[MACRO DEBUG] - CFrame:", cframe)
                print("[MACRO DEBUG] - Slot:", slot)
                print("[MACRO DEBUG] - isRecording:", isRecording)

                local result = oldPlaceTower(self, cframe, slot)
                print("[MACRO DEBUG] - PlaceTower result:", result)

                if isRecording and result then
                    print("[MACRO DEBUG] Recording tower placement...")
                    task.spawn(function()
                        task.wait(0.1)

                        local friendlies = workspace:FindFirstChild("Friendlies")
                        print("[MACRO DEBUG] - Friendlies folder:", friendlies)
                        if not friendlies then
                            print("[MACRO DEBUG] - ERROR: No Friendlies folder found!")
                            return
                        end

                        local newestTower = nil
                        local newestTime = 0

                        for _, tower in ipairs(friendlies:GetChildren()) do
                            if tower:IsA("Model") and tower.PrimaryPart then
                                local towerTime = tick()
                                if towerTime > newestTime then
                                    newestTime = towerTime
                                    newestTower = tower
                                end
                            end
                        end

                        if newestTower then
                            local towerName = newestTower.Name
                            local instanceIndex = getNextInstanceIndex(towerName)

                            table.insert(currentMacro.actions, {
                                type = "place",
                                towerName = towerName,
                                cframe = cframe,
                                slot = slot,
                                instanceIndex = instanceIndex
                            })

                            print("[MACRO DEBUG] - Tower recorded:", towerName, "#" .. instanceIndex)
                            print("[MACRO DEBUG] - Total actions:", #currentMacro.actions)
                            SendNotification("Tower Recorded", towerName .. " #" .. instanceIndex)
                        else
                            print("[MACRO DEBUG] - ERROR: Could not find newest tower!")
                        end
                    end)
                end

                return result
            end)
            print("[MACRO DEBUG] PlaceTower hook successful!")
        end)

        if not hookSuccess1 then
            print("[MACRO DEBUG] ERROR: Failed to hook PlaceTower!")
        end

        print("[MACRO DEBUG] Attempting to hook GameService.UpgradeTower.InvokeServer...")
        local hookSuccess2 = pcall(function()
            oldUpgradeTower = hookfunction(GameService.UpgradeTower.InvokeServer, function(self, towerId)
                print("[MACRO DEBUG] HOOK CALLED: UpgradeTower (hookfunction)")
                print("[MACRO DEBUG] - Tower ID:", towerId)
                print("[MACRO DEBUG] - isRecording:", isRecording)

                if isRecording then
                    print("[MACRO DEBUG] Recording tower upgrade...")
                    local friendlies = workspace:FindFirstChild("Friendlies")
                    if friendlies then
                        for _, tower in ipairs(friendlies:GetChildren()) do
                            if tower:IsA("Model") then
                                local idValue = tower:FindFirstChild("Id")
                                if idValue and idValue.Value == towerId then
                                    local towerName = tower.Name

                                    local instanceIndex = 0
                                    for _, action in ipairs(currentMacro.actions) do
                                        if action.type == "place" and action.towerName == towerName then
                                            instanceIndex = action.instanceIndex
                                        end
                                    end

                                    table.insert(currentMacro.actions, {
                                        type = "upgrade",
                                        towerName = towerName,
                                        instanceIndex = instanceIndex
                                    })

                                    print("[MACRO DEBUG] - Upgrade recorded:", towerName, "#" .. instanceIndex)
                                    print("[MACRO DEBUG] - Total actions:", #currentMacro.actions)
                                    SendNotification("Upgrade Recorded", towerName .. " #" .. instanceIndex)
                                    break
                                end
                            end
                        end
                    else
                        print("[MACRO DEBUG] - ERROR: No Friendlies folder found!")
                    end
                end

                return oldUpgradeTower(self, towerId)
            end)
            print("[MACRO DEBUG] UpgradeTower hook successful!")
        end)

        if not hookSuccess2 then
            print("[MACRO DEBUG] ERROR: Failed to hook UpgradeTower!")
        end

        print("[MACRO DEBUG] hookfunction setup complete")
    end

    if hookmetamethod then
        print("[MACRO DEBUG] Setting up __namecall metamethod hook...")

        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if method == "InvokeServer" then
                if spyModeEnabled then
                    local spyPath = "unknown"
                    pcall(function() spyPath = self:GetFullName() end)
                    print("[MACRO SPY] InvokeServer called on:", spyPath)
                    print("[MACRO SPY] Arguments:", ...)
                end

                local selfPath = "unknown"
                pcall(function() selfPath = self:GetFullName() end)
                local selfName = self.Name

                if selfName == "PlaceTower" or string.find(selfPath, "PlaceTower") then
                    print("[MACRO DEBUG] __namecall DETECTED PlaceTower!")
                    print("[MACRO DEBUG] - Path:", selfPath)
                    print("[MACRO DEBUG] - Args count:", select("#", ...))
                    print("[MACRO DEBUG] - Arg1 (CFrame):", args[1])
                    print("[MACRO DEBUG] - Arg2 (Slot):", args[2])
                    print("[MACRO DEBUG] - isRecording:", isRecording)

                    if isRecording then
                        local cframe = args[1]
                        local slot = args[2]

                        task.spawn(function()
                            local result = oldNamecall(self, ...)
                            print("[MACRO DEBUG] - PlaceTower result:", result)

                            if result then
                                task.wait(0.1)

                                local friendlies = workspace:FindFirstChild("Friendlies")
                                if friendlies then
                                    local newestTower = nil
                                    local newestTime = 0

                                    for _, tower in ipairs(friendlies:GetChildren()) do
                                        if tower:IsA("Model") and tower.PrimaryPart then
                                            local towerTime = tick()
                                            if towerTime > newestTime then
                                                newestTime = towerTime
                                                newestTower = tower
                                            end
                                        end
                                    end

                                    if newestTower then
                                        local towerName = newestTower.Name
                                        local instanceIndex = getNextInstanceIndex(towerName)

                                        table.insert(currentMacro.actions, {
                                            type = "place",
                                            towerName = towerName,
                                            cframe = cframe,
                                            slot = slot,
                                            instanceIndex = instanceIndex
                                        })

                                        print("[MACRO DEBUG] - Tower recorded via __namecall:", towerName, "#" .. instanceIndex)
                                        print("[MACRO DEBUG] - Total actions:", #currentMacro.actions)
                                        SendNotification("Tower Recorded", towerName .. " #" .. instanceIndex)
                                    end
                                end
                            end

                            return result
                        end)

                        return oldNamecall(self, ...)
                    end
                end

                if selfName == "UpgradeTower" or string.find(selfPath, "UpgradeTower") then
                    print("[MACRO DEBUG] __namecall DETECTED UpgradeTower!")
                    print("[MACRO DEBUG] - Path:", selfPath)
                    print("[MACRO DEBUG] - Args count:", select("#", ...))
                    print("[MACRO DEBUG] - Arg1 (TowerID):", args[1])
                    print("[MACRO DEBUG] - isRecording:", isRecording)

                    if isRecording then
                        local towerId = args[1]

                        local friendlies = workspace:FindFirstChild("Friendlies")
                        if friendlies then
                            for _, tower in ipairs(friendlies:GetChildren()) do
                                if tower:IsA("Model") then
                                    local idValue = tower:FindFirstChild("Id")
                                    if idValue and idValue.Value == towerId then
                                        local towerName = tower.Name

                                        local instanceIndex = 0
                                        for _, action in ipairs(currentMacro.actions) do
                                            if action.type == "place" and action.towerName == towerName then
                                                instanceIndex = action.instanceIndex
                                            end
                                        end

                                        table.insert(currentMacro.actions, {
                                            type = "upgrade",
                                            towerName = towerName,
                                            instanceIndex = instanceIndex
                                        })

                                        print("[MACRO DEBUG] - Upgrade recorded via __namecall:", towerName, "#" .. instanceIndex)
                                        print("[MACRO DEBUG] - Total actions:", #currentMacro.actions)
                                        SendNotification("Upgrade Recorded", towerName .. " #" .. instanceIndex)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end

            return oldNamecall(self, ...)
        end)

        namecallHook = oldNamecall
        print("[MACRO DEBUG] __namecall hook installed successfully!")
    else
        print("[MACRO DEBUG] WARNING: hookmetamethod not available!")
    end

    print("[MACRO DEBUG] Recording setup complete")
    if spyModeEnabled then
        SendNotification("Spy Mode Active", "All RemoteFunction calls will be logged")
    end
end

local function stopRecording()
    if not isRecording then
        print("[MACRO DEBUG] Not recording, ignoring stop request")
        return
    end

    print("[MACRO DEBUG] Stopping recording...")
    print("[MACRO DEBUG] Current macro actions:", currentMacro and #currentMacro.actions or 0)

    isRecording = false

    if currentMacro and #currentMacro.actions > 0 then
        savedMacros[currentMacro.name] = currentMacro

        print("[MACRO DEBUG] Macro saved:", currentMacro.name, "with", #currentMacro.actions, "actions")
        SendNotification("Macro Saved", currentMacro.name .. " (" .. #currentMacro.actions .. " actions)")
        updateStatus("Saved: " .. currentMacro.name)
        refreshMacroList()
    else
        print("[MACRO DEBUG] WARNING: No actions recorded!")
        updateStatus("Recording stopped (no actions recorded)")
    end

    currentMacro = nil
end

local function playMacro(macro)
    if isPlaying then
        SendNotification("Playback Error", "Already playing a macro")
        return
    end

    isPlaying = true
    playbackTowerMap = {}

    updateStatus("Playing: " .. macro.name)

    task.spawn(function()
        for i, action in ipairs(macro.actions) do
            if not isPlaying then break end

            if action.type == "place" then
                local success, result = pcall(function()
                    return TowerService.PlaceTower:InvokeServer(action.cframe, action.slot)
                end)

                if success and result then
                    task.wait(0.2)

                    local friendlies = workspace:FindFirstChild("Friendlies")
                    if friendlies then
                        local newestTower = nil
                        local newestTime = 0

                        for _, tower in ipairs(friendlies:GetChildren()) do
                            if tower:IsA("Model") and tower.Name == action.towerName then
                                local towerTime = tick()
                                if towerTime > newestTime then
                                    newestTime = towerTime
                                    newestTower = tower
                                end
                            end
                        end

                        if newestTower then
                            local idValue = newestTower:FindFirstChild("Id")
                            if idValue then
                                if not playbackTowerMap[action.towerName] then
                                    playbackTowerMap[action.towerName] = {}
                                end
                                playbackTowerMap[action.towerName][action.instanceIndex] = idValue.Value
                            end
                        end
                    end
                end

                task.wait(0.3)

            elseif action.type == "upgrade" then
                if playbackTowerMap[action.towerName] and playbackTowerMap[action.towerName][action.instanceIndex] then
                    local towerId = playbackTowerMap[action.towerName][action.instanceIndex]

                    pcall(function()
                        GameService.UpgradeTower:InvokeServer(towerId)
                    end)

                    task.wait(0.2)
                end
            end
        end

        isPlaying = false
        updateStatus("Playback complete: " .. macro.name)
        SendNotification("Playback Complete", macro.name)
    end)
end

local function deleteMacro(macroName)
    savedMacros[macroName] = nil
    refreshMacroList()
    SendNotification("Macro Deleted", macroName)
end

function refreshMacroList()
    if not macroListSection then return end

    local macroCount = 0
    for _ in pairs(savedMacros) do
        macroCount = macroCount + 1
    end

    if macroCount == 0 then
        macroListSection:Paragraph({
            Title = "No Saved Macros",
            Content = "Record a macro to get started"
        })
    else
        for macroName, macro in pairs(savedMacros) do
            local actionCount = #macro.actions

            macroListSection:Button({
                Title = macroName,
                Desc = actionCount .. " actions - Click to play",
                Callback = function()
                    playMacro(macro)
                end
            })

            macroListSection:Button({
                Title = "Delete " .. macroName,
                Desc = "Remove this macro",
                Callback = function()
                    deleteMacro(macroName)
                end
            })
        end
    end
end

function MacroRecorder:Init(window)
    print("[MACRO RECORDER] Modul wird initialisiert...")

    local MacroTab = window:Tab({
        Title = "Macro Recorder",
        Icon = "rbxassetid://10734950309"
    })

    MacroTab:Toggle({
        Title = "Remote Spy Mode",
        Desc = "Log ALL RemoteFunction calls for debugging",
        Value = false,
        Callback = function(value)
            spyModeEnabled = value
            if value then
                print("[MACRO SPY] Spy Mode ENABLED - All RemoteFunction calls will be logged")
                SendNotification("Spy Mode", "Enabled - Check console for remote calls")
            else
                print("[MACRO SPY] Spy Mode DISABLED")
                SendNotification("Spy Mode", "Disabled")
            end
        end
    })

    MacroTab:Input({
        Title = "Macro Name",
        Placeholder = "Enter macro name",
        Callback = function(value)
            currentMacroName = value
            print("[MACRO] Name set to:", value)
        end
    })

    recordToggle = MacroTab:Toggle({
        Title = "Record Macro",
        Desc = "Toggle to start/stop recording",
        Value = false,
        Callback = function(value)
            if value then
                startRecording()
            else
                stopRecording()
            end
        end
    })

    statusLabel = MacroTab:Paragraph({
        Title = "Recording Status",
        Content = "Idle"
    })

    macroListSection = MacroTab:Section({
        Title = "Saved Macros"
    })

    refreshMacroList()

    print("[MACRO RECORDER] Modul erfolgreich geladen!")
    return self
end

function MacroRecorder:Cleanup()
    isRecording = false
    isPlaying = false

    if recordConnection then
        recordConnection:Disconnect()
        recordConnection = nil
    end

    if playbackConnection then
        playbackConnection:Disconnect()
        playbackConnection = nil
    end

    print("[MACRO RECORDER] Modul entladen")
end

return MacroRecorder
