
local inService = {
    ["police"] = {},
    ["medic"] = {},
}

local callActive = {
    ["police"] = {taken = false},
    ["medic"] =  {taken = false},
}

RegisterServerEvent("player:serviceOn")
AddEventHandler("player:serviceOn", function(job)
local source = source
    table.insert(inService[job], source)	
end)

RegisterServerEvent("player:serviceOff")
AddEventHandler("player:serviceOff", function(job)
local source = source
    if job == nil then
        for _,v in pairs(inService) do
            removeService(v)
        end
    end
    removeService(source, job)
end)

-- Receive call event
RegisterServerEvent("call:makeCall")
AddEventHandler("call:makeCall", function(job, pos, message)
local source = source
	 -- Players can't call simultanously the same service
    if callActive[job].taken then
        TriggerClientEvent("target:call:taken", callActive[job].target, 2)
        CancelEvent()
    end

    callActive[job].target = source
    callActive[job].taken = true
    for _, player in pairs(inService[job]) do
        TriggerClientEvent("call:callIncoming", player, job, pos, message)
    end


    SetTimeout(60000, function()
        if callActive[job].taken then
            TriggerClientEvent("target:call:taken", callActive[job].target, 0)
        end
        callActive[job].taken = false
    end)
end)

RegisterServerEvent("call:getCall")
AddEventHandler("call:getCall", function(job)
    callActive[job].taken = false

    for _, player in pairs(inService[job]) do
        if player ~= source then
            TriggerClientEvent("call:taken", player)
        end
    end

    if not callActive[job].taken then
        TriggerClientEvent("target:call:taken", callActive[job].target, 1)
    end
end)

function removeService(player, job)
    for i,val in pairs(inService[job]) do
        if val == player then
            table.remove(inService[job], i)
            return
        end
    end
end