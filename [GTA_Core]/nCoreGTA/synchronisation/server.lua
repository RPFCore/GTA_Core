CurrentWeather = "EXTRASUNNY"
local baseTime = 0
local timeOffset = 0
local freezeTime = false
local blackout = false

RegisterServerEvent('GTA:requestSync')
AddEventHandler('GTA:requestSync', function()
    TriggerClientEvent('GTA:updateWeather', -1, CurrentWeather, blackout)
    TriggerClientEvent('GTA:updateTime', -1, baseTime, timeOffset, freezeTime)
end)

function ShiftToMinute(minute)
    timeOffset = timeOffset - (((baseTime+timeOffset)%60) - minute)
end

function ShiftToHour(hour)
    timeOffset = timeOffset - ((((baseTime+timeOffset)/60)%24) - hour) * 60
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local newBaseTime = os.time(os.date("!*t"))/2 + 360
        if freezeTime then
            timeOffset = timeOffset + baseTime - newBaseTime			
        end
        baseTime = newBaseTime
    end
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        TriggerClientEvent('GTA:updateTime', -1, baseTime, timeOffset, freezeTime)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000)
        TriggerClientEvent('GTA:updateWeather', -1, CurrentWeather, blackout)
    end
end)