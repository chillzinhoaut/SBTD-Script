local MacroRecorder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local TowerService = ReplicatedStorage.Packages._Index["acecateer_knit@1.7.1"].knit.Services.TowerService.RF
local GameService = ReplicatedStorage.Packages._Index["acecateer_knit@1.7.1"].knit.Services.GameService.RF

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
        statusLabel:Set({ Title = "Status: " .. text })
    end
    print("[MACRO STATUS] " .. text)
end

local function startRecording()
    if isRecording then return end

    isRecording = true
    towerInstanceCounts = {}

    currentMacro = {
        name = currentMacroName,
        actions = {}
    }

    updateStatus("Recording... Place towers and upgrade them")
    SendNotification("Macro Recording", "Started recording " .. currentMacroName)

    local oldPlaceTower = nil
    local oldUpgradeTower = nil

    -- Hook PlaceTower
    oldPlaceTower = hookfunction(TowerService.PlaceTower.InvokeServer, function(self, cframe, slot)
        local result = oldPlaceTower(self, cframe, slot)

        if isRecording and result then
            task.spawn(function()
                task.wait(0.1)

                local friendlies = workspace:FindFirstChild("Friendlies")
                if not friendlies then return end

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

                    SendNotification("Tower Recorded", towerName .. " #" .. instanceIndex)
                end
            end)
        end

        return result
    end)

    -- Hook UpgradeTower
    oldUpgradeTower = hookfunction(GameService.UpgradeTower.InvokeServer, function(self, towerId)
        if isRecording then
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

                            SendNotification("Upgrade Recorded", towerName .. " #" .. instanceIndex)
                            break
                        end
                    end
                end
            end
        end

        return oldUpgradeTower(self, towerId)
    end)
end

local function stopRecording()
    if not isRecording then return end

    isRecording = false

    if currentMacro and #currentMacro.actions > 0 then
        savedMacros[currentMacro.name] = currentMacro

        SendNotification("Macro Saved", currentMacro.name .. " (" .. #currentMacro.actions .. " actions)")
        updateStatus("Saved: " .. currentMacro.name)
        refreshMacroList()
    else
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
        macroListSection:Label({
            Title = "No saved macros"
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

    statusLabel = MacroTab:Label({
        Title = "Status: Idle"
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
