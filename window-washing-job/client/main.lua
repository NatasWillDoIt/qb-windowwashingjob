local QBCore = exports['qb-core']:GetCoreObject()
local isDoingJob = false
local activeTeam = {}
local jobBlips = {}
local currentBuilding = nil
local currentWindow = nil
local windowsCompleted = 0
local totalWindows = 0
local jobVehicle = nil
local hasJobVehicle = false

-- Load animations
local function LoadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

-- Add these functions after the LoadAnimDict function

-- Spawn job vehicle
local function SpawnJobVehicle(coords)
    local vehicleHash = GetHashKey(Config.JobVehicle)
    RequestModel(vehicleHash)
    while not HasModelLoaded(vehicleHash) do
        Wait(0)
    end
    
    local vehicle = CreateVehicle(vehicleHash, coords.x, coords.y, coords.z, coords.w, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleNumberPlateText(vehicle, "WASH"..tostring(math.random(1000, 9999)))
    SetVehicleColours(vehicle, 0, 0) -- Black
    SetVehicleDirtLevel(vehicle, 0.0)
    
    -- Give keys to player (using qb-vehiclekeys)
    TriggerEvent('vehiclekeys:client:SetOwner', QBCore.Functions.GetPlate(vehicle))
    
    return vehicle
end

-- Spawn job ped
local function SpawnJobPed()
    for k, v in pairs(Config.PedLocations) do
        local pedModel = GetHashKey(v.model)
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do
            Wait(0)
        end
        
        local ped = CreatePed(4, pedModel, v.coords.x, v.coords.y, v.coords.z - 1.0, v.coords.w, false, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        
        -- Add target interaction for the ped
        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                {
                    type = "client",
                    event = "qb-windowwashing:client:getJobVehicle",
                    icon = "fas fa-car",
                    label = "Request Work Vehicle",
                    canInteract = function()
                        return isDoingJob and not hasJobVehicle
                    end
                }
            },
            distance = 2.5
        })
    end
end

-- Stop the job
local function StopJob(notify)
    if not isDoingJob then return end
    
    -- Remove window target zones
    if currentBuilding then
        for i, window in ipairs(currentBuilding.windows) do
            exports['qb-target']:RemoveZone("window_"..currentBuilding.name.."_"..i)
        end
    end
    
    -- Delete job vehicle if it exists
    if jobVehicle and DoesEntityExist(jobVehicle) then
        DeleteVehicle(jobVehicle)
    end
    
    -- Reset variables
    isDoingJob = false
    hasJobVehicle = false
    jobVehicle = nil
    currentBuilding = nil
    currentWindow = nil
    windowsCompleted = 0
    totalWindows = 0
    
    -- Hide UI
    SendNUIMessage({
        action = "hideUI"
    })
    
    -- Notify server to remove from active jobs
    TriggerServerEvent("qb-windowwashing:server:stopJob")
    
    -- Notify player
    if notify then
        QBCore.Functions.Notify("You've stopped working.", "primary")
    end
end

-- Initialize job locations
local function SetupJobLocations()
    for k, v in pairs(Config.Buildings) do
        local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
        SetBlipSprite(blip, 486)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 46)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Window Washing")
        EndTextCommandSetBlipName(blip)
        table.insert(jobBlips, blip)
    end
end

-- Remove all job blips
local function RemoveJobBlips()
    for i = 1, #jobBlips do
        RemoveBlip(jobBlips[i])
    end
    jobBlips = {}
end

-- Setup qb-target interactions
local function SetupTargetInteractions()
    -- Job start points
    for k, v in pairs(Config.Buildings) do
        exports['qb-target']:AddBoxZone("windowwash_"..k, v.coords, 2.0, 2.0, {
            name = "windowwash_"..k,
            heading = v.coords.w,
            debugPoly = false,
            minZ = v.coords.z - 1.0,
            maxZ = v.coords.z + 1.0,
        }, {
            options = {
                {
                    type = "client",
                    event = "qb-windowwashing:client:startJob",
                    icon = "fas fa-spray-can",
                    label = "Start Window Washing",
                    building = k,
                },
            },
            distance = 2.5
        })
    end
end

-- Modify the 'qb-windowwashing:client:startJob' event to include the job ped info
RegisterNetEvent('qb-windowwashing:client:startJob', function(data)
    if isDoingJob then
        QBCore.Functions.Notify("You're already working!", "error")
        return
    end
    
    local building = data.building
    currentBuilding = Config.Buildings[building]
    totalWindows = #currentBuilding.windows
    windowsCompleted = 0
    
    -- Create window target zones
    for i, window in ipairs(currentBuilding.windows) do
        exports['qb-target']:AddBoxZone("window_"..building.."_"..i, window.coords, 2.0, 3.0, {
            name = "window_"..building.."_"..i,
            heading = window.coords.w,
            debugPoly = false,
            minZ = window.coords.z - 1.5,
            maxZ = window.coords.z + 1.5,
        }, {
            options = {
                {
                    type = "client",
                    event = "qb-windowwashing:client:washWindow",
                    icon = "fas fa-spray-can",
                    label = "Wash Window",
                    windowId = i,
                    canInteract = function()
                        -- Check if player is in a vehicle
                        return not IsPedInAnyVehicle(PlayerPedId(), false)
                    end
                },
            },
            distance = 3.0
        })
    end
    
    isDoingJob = true
    activeTeam = {GetPlayerServerId(PlayerId())}
    TriggerServerEvent("qb-windowwashing:server:startJob", building, GetPlayerServerId(PlayerId()))
    
    SendNUIMessage({
        action = "showUI",
        progress = "0/" .. totalWindows,
        team = {GetPlayerName(PlayerId())}
    })
    
    QBCore.Functions.Notify("Window washing job started! Talk to the job coordinator to get a work vehicle.", "success")
    QBCore.Functions.Notify("You can use /quitjob to stop working at any time.", "info")
end)

-- Add event for getting job vehicle
RegisterNetEvent('qb-windowwashing:client:getJobVehicle', function()
    if not isDoingJob then
        QBCore.Functions.Notify("You need to start a job first!", "error")
        return
    end
    
    if hasJobVehicle and DoesEntityExist(jobVehicle) then
        QBCore.Functions.Notify("You already have a work vehicle!", "error")
        return
    end
    
    -- Find closest ped location
    local playerPos = GetEntityCoords(PlayerPedId())
    local closestPed = nil
    local closestDistance = 9999.0
    
    for k, v in pairs(Config.PedLocations) do
        local distance = #(playerPos - vector3(v.coords.x, v.coords.y, v.coords.z))
        if distance < closestDistance then
            closestDistance = distance
            closestPed = v
        end
    end
    
    if closestPed and closestPed.vehicleSpawn then
        jobVehicle = SpawnJobVehicle(closestPed.vehicleSpawn)
        hasJobVehicle = true
        QBCore.Functions.Notify("Work vehicle ready! Remember to exit the vehicle before washing windows.", "success")
    else
        QBCore.Functions.Notify("Could not spawn work vehicle!", "error")
    end
end)

-- Modify the 'qb-windowwashing:client:washWindow' event to check if player is in a vehicle
RegisterNetEvent('qb-windowwashing:client:washWindow', function(data)
    if not isDoingJob then return end
    
    -- Check if player is in a vehicle
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        QBCore.Functions.Notify("You need to exit the vehicle to wash windows!", "error")
        return
    end
    
    local windowId = data.windowId
    currentWindow = windowId
    
    -- Start washing animation
    local washingTime = math.random(Config.MinWashTime, Config.MaxWashTime)
    LoadAnimDict("amb@world_human_maid_clean@")
    
    TaskPlayAnim(PlayerPedId(), "amb@world_human_maid_clean@", "base", 8.0, 1.0, -1, 1, 0, false, false, false)
    
    local prop = CreateObject(GetHashKey("prop_sponge_01"), 0, 0, 0, true, true, true)
    AttachEntityToEntity(prop, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.0, 0.0, -0.01, 90.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    QBCore.Functions.Progressbar("washing_window", "Washing Window...", washingTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        DetachEntity(prop, 1, 1)
        DeleteObject(prop)
        ClearPedTasks(PlayerPedId())
        
        currentBuilding.windows[windowId].cleaned = true
        windowsCompleted = windowsCompleted + 1
        
        SendNUIMessage({
            action = "updateProgress",
            progress = windowsCompleted .. "/" .. totalWindows
        })
        
        TriggerServerEvent("qb-windowwashing:server:windowCleaned", currentBuilding.name, windowId, windowsCompleted, totalWindows)
        
        -- Check if all windows are cleaned
        if windowsCompleted >= totalWindows then
            FinishJob()
        else
            QBCore.Functions.Notify("Window cleaned! " .. windowsCompleted .. "/" .. totalWindows .. " completed.", "success")
        end
    end, function() -- Cancel
        DetachEntity(prop, 1, 1)
        DeleteObject(prop)
        ClearPedTasks(PlayerPedId())
        QBCore.Functions.Notify("Cancelled washing.", "error")
    end)
end)

-- Add command to quit job
RegisterCommand('quitjob', function()
    if not isDoingJob then
        QBCore.Functions.Notify("You're not working!", "error")
        return
    end
    
    StopJob(true)
end, false)

-- Modify the FinishJob function to handle the job vehicle
function FinishJob()
    -- Delete job vehicle if it exists
    if jobVehicle and DoesEntityExist(jobVehicle) then
        DeleteVehicle(jobVehicle)
    end
    
    isDoingJob = false
    hasJobVehicle = false
    jobVehicle = nil
    
    -- Remove window target zones
    for i, window in ipairs(currentBuilding.windows) do
        exports['qb-target']:RemoveZone("window_"..currentBuilding.name.."_"..i)
    end
    
    -- Calculate payment based on team size
    local teamSize = #activeTeam
    local basePayment = currentBuilding.payment
    local finalPayment = math.floor(basePayment / teamSize)
    
    TriggerServerEvent("qb-windowwashing:server:finishJob", currentBuilding.name, finalPayment, activeTeam)
    
    SendNUIMessage({
        action = "hideUI"
    })
    
    QBCore.Functions.Notify("Job completed! You earned $" .. finalPayment, "success")
    
    currentBuilding = nil
    currentWindow = nil
    windowsCompleted = 0
    totalWindows = 0
    activeTeam = {}
end

-- Team invitation request
RegisterNetEvent('qb-windowwashing:client:requestJoinTeam', function(requesterId)
    if not isDoingJob then return end
    
    local requesterName = QBCore.Functions.GetPlayerData().charinfo.firstname
    
    -- Show confirmation dialog
    local dialog = exports['qb-input']:ShowInput({
        header = requesterName .. " wants to join your team",
        submitText = "Accept",
        inputs = {
            {
                text = "Do you want to accept?",
                name = "accept",
                type = "radio",
                options = {
                    { value = "yes", text = "Yes" },
                    { value = "no", text = "No" }
                }
            }
        }
    })
    
    if dialog and dialog.accept == "yes" then
        TriggerServerEvent("qb-windowwashing:server:acceptTeamRequest", requesterId, currentBuilding.name)
        
        -- Update team UI
        QBCore.Functions.TriggerCallback('qb-windowwashing:server:getPlayerName', function(name)
            SendNUIMessage({
                action = "updateTeam",
                newMember = name
            })
        end, requesterId)
    else
        TriggerServerEvent("qb-windowwashing:server:rejectTeamRequest", requesterId)
    end
end)

-- Join a team
RegisterNetEvent('qb-windowwashing:client:joinTeam', function(building, progress, team)
    currentBuilding = Config.Buildings[building]
    totalWindows = #currentBuilding.windows
    windowsCompleted = progress
    isDoingJob = true
    activeTeam = team
    
    -- Get team member names
    local teamNames = {}
    for i, id in ipairs(team) do
        QBCore.Functions.TriggerCallback('qb-windowwashing:server:getPlayerName', function(name)
            table.insert(teamNames, name)
            
            if #teamNames == #team then
                SendNUIMessage({
                    action = "showUI",
                    progress = windowsCompleted .. "/" .. totalWindows,
                    team = teamNames
                })
            end
        end, id)
    end
    
    QBCore.Functions.Notify("You joined a window washing team!", "success")
end)

-- Request to join a team
RegisterNetEvent('qb-windowwashing:client:requestTeam', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    
    if player == -1 or distance > 3.0 then
        QBCore.Functions.Notify("No players nearby!", "error")
        return
    end
    
    local playerId = GetPlayerServerId(player)
    TriggerServerEvent("qb-windowwashing:server:requestJoinTeam", playerId)
    QBCore.Functions.Notify("Team join request sent.", "primary")
end)

-- Team request rejected
RegisterNetEvent('qb-windowwashing:client:teamRequestRejected', function()
    QBCore.Functions.Notify("Your team request was rejected.", "error")
end)

-- Update window progress from server (when teammate cleans a window)
RegisterNetEvent('qb-windowwashing:client:updateProgress', function(windowId, completed, total)
    if not isDoingJob then return end
    
    currentBuilding.windows[windowId].cleaned = true
    windowsCompleted = completed
    
    SendNUIMessage({
        action = "updateProgress",
        progress = completed .. "/" .. total
    })
    
    QBCore.Functions.Notify("Team member cleaned a window! " .. completed .. "/" .. total .. " completed.", "success")
end)

-- Command to request joining a team
RegisterCommand('jointeam', function()
    if isDoingJob then
        QBCore.Functions.Notify("You're already working!", "error")
        return
    end
    
    TriggerEvent('qb-windowwashing:client:requestTeam')
end, false)

-- Modify the 'QBCore:Client:OnPlayerLoaded' event to spawn job peds
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SetupJobLocations()
    SetupTargetInteractions()
    SpawnJobPed()
end)

-- Modify the 'onResourceStop' handler to include cleanup for job vehicle and peds
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    RemoveJobBlips()
    
    -- Remove all target zones
    for k, v in pairs(Config.Buildings) do
        exports['qb-target']:RemoveZone("windowwash_"..k)
        
        for i, window in ipairs(v.windows) do
            exports['qb-target']:RemoveZone("window_"..k.."_"..i)
        end
    end
    
    -- Delete job vehicle if it exists
    if jobVehicle and DoesEntityExist(jobVehicle) then
        DeleteVehicle(jobVehicle)
    end
    
    -- Hide UI
    SendNUIMessage({
        action = "hideUI"
    })
end)

-- NUI Callbacks
RegisterNUICallback('closeUI', function()
    if isDoingJob then
        QBCore.Functions.Notify("Finish the job first!", "error")
    else
        SetNuiFocus(false, false)
    end
end)

-- Add NUI callback for quit job
RegisterNUICallback('quitJob', function()
    StopJob(true)
    SetNuiFocus(false, false)
end)

