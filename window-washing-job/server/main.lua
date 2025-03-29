local QBCore = exports['qb-core']:GetCoreObject()
local activeJobs = {}

-- Start a window washing job
RegisterNetEvent('qb-windowwashing:server:startJob', function(building, playerId)
    local src = source
    
    if not activeJobs[building] then
        activeJobs[building] = {
            team = {playerId},
            progress = 0,
            windows = {}
        }
    else
        -- Building already being cleaned
        TriggerClientEvent('QBCore:Notify', src, "This building is already being cleaned by another team!", "error")
        return
    end
    
    -- Reset windows cleaned status
    for i, window in ipairs(Config.Buildings[building].windows) do
        activeJobs[building].windows[i] = false
    end
end)

-- Window cleaned event
RegisterNetEvent('qb-windowwashing:server:windowCleaned', function(building, windowId, completed, total)
    local src = source
    
    if not activeJobs[building] then return end
    
    activeJobs[building].windows[windowId] = true
    activeJobs[building].progress = completed
    
    -- Notify all team members about progress
    for _, playerId in ipairs(activeJobs[building].team) do
        if playerId ~= src then
            TriggerClientEvent('qb-windowwashing:client:updateProgress', playerId, windowId, completed, total)
        end
    end
end)

-- Finish job and pay all team members
RegisterNetEvent('qb-windowwashing:server:finishJob', function(building, payment, team)
    if not activeJobs[building] then return end
    
    -- Pay each team member
    for _, playerId in ipairs(team) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            Player.Functions.AddMoney("bank", payment, "window-washing-payment")
            TriggerClientEvent('QBCore:Notify', playerId, "You received $" .. payment .. " for window washing!", "success")
        end
    end
    
    -- Clear job data
    activeJobs[building] = nil
end)

-- Request to join a team
RegisterNetEvent('qb-windowwashing:server:requestJoinTeam', function(targetId)
    local src = source
    TriggerClientEvent('qb-windowwashing:client:requestJoinTeam', targetId, src)
end)

-- Accept team request
RegisterNetEvent('qb-windowwashing:server:acceptTeamRequest', function(requesterId, building)
    local src = source
    
    if not activeJobs[building] then return end
    
    -- Add player to team
    table.insert(activeJobs[building].team, requesterId)
    
    -- Send current job info to new team member
    TriggerClientEvent('qb-windowwashing:client:joinTeam', requesterId, building, activeJobs[building].progress, activeJobs[building].team)
    
    -- Notify team leader
    TriggerClientEvent('QBCore:Notify', src, "Player has joined your team!", "success")
end)

-- Reject team request
RegisterNetEvent('qb-windowwashing:server:rejectTeamRequest', function(requesterId)
    TriggerClientEvent('qb-windowwashing:client:teamRequestRejected', requesterId)
end)

-- Callback to get player name
QBCore.Functions.CreateCallback('qb-windowwashing:server:getPlayerName', function(source, cb, playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if Player then
        local charInfo = Player.PlayerData.charinfo
        cb(charInfo.firstname .. " " .. charInfo.lastname)
    else
        cb("Unknown")
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    activeJobs = {}
end)

-- Add event for stopping job
RegisterNetEvent('qb-windowwashing:server:stopJob', function()
    local src = source
    
    -- Find and remove player from any active jobs
    for building, jobData in pairs(activeJobs) do
        for i, playerId in ipairs(jobData.team) do
            if playerId == src then
                table.remove(activeJobs[building].team, i)
                
                -- If team is empty, remove the job
                if #activeJobs[building].team == 0 then
                    activeJobs[building] = nil
                end
                
                break
            end
        end
    end
end)

