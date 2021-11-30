--[[Thanks to Kiminaze for his snippet code on the camera rotation.]]

local isDead = false
local EarlyRespawnTimer = 60000 * 1 --> 60 SECONDES
local BleedoutTimer = 60000 * 10
local cam = nil
local angleY = 0.0
local angleZ = 0.0
local radius = 1.7

local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

--> Gére le system de control une fois que le joueur est dans le coma on bloque toute les touches :
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
		if (isDead) then
            HidAllHudFrame() --> Remove all hud from GTA.
        end

		if (cam) then 
			ProcessCamControls() --> Can now rotate around.
		end
    end
end)

--> Gére le system d'affichage : 
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if (not isDead and NetworkIsPlayerActive(PlayerId()) and IsPedFatallyInjured(PlayerPedId())) then
            BeginDeathScreen()

        elseif (isDead and NetworkIsPlayerActive(PlayerId()) and not IsPedFatallyInjured(PlayerPedId())) then
            EndDeathScreen()
        end
    end
end)


--------||DEATH SCREEN||---------
function drawHelpTxt(x,y ,width,height,scale, text, r,g,b,a,font)
	SetTextFont(font)
	SetTextProportional(0)
	SetTextScale(scale, scale)
	SetTextColour(r, g, b, a)
	SetTextDropShadow(0, 0, 0, 0,255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x - width/2, y - height/2 + 0.005)
end


function HidAllHudFrame()
	HideHelpTextThisFrame()
	HideHudAndRadarThisFrame()
	HideHudComponentThisFrame(1)
	HideHudComponentThisFrame(2)
--	HideHudComponentThisFrame(3)
--	HideHudComponentThisFrame(4)
	HideHudComponentThisFrame(6)
	HideHudComponentThisFrame(7)
	HideHudComponentThisFrame(8)
	HideHudComponentThisFrame(9)
	HideHudComponentThisFrame(13)
	HideHudComponentThisFrame(17)
	HideHudComponentThisFrame(20)
end

-- process camera controls @Kiminaze thanks to you buddy.
function ProcessCamControls()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    DisableFirstPersonCamThisFrame()
    
    -- calculate new position
    local newPos = ProcessNewPosition()
    SetFocusArea(newPos.x, newPos.y, newPos.z, 0.0, 0.0, 0.0)
    SetCamCoord(cam, newPos.x, newPos.y, newPos.z)
    PointCamAtCoord(cam, playerCoords.x, playerCoords.y, playerCoords.z + 0.5)
end

function ProcessNewPosition()
    local mouseX = 0.0
    local mouseY = 0.0
    
    -- keyboard
    if (IsInputDisabled(0)) then
        mouseX = GetDisabledControlNormal(1, 1) * 8.0
        mouseY = GetDisabledControlNormal(1, 2) * 8.0
    else
        mouseX = GetDisabledControlNormal(1, 1) * 1.5
        mouseY = GetDisabledControlNormal(1, 2) * 1.5
    end

    angleZ = angleZ - mouseX -- around Z axis (left / right)
    angleY = angleY + mouseY -- up / down
    if (angleY > 89.0) then angleY = 89.0 elseif (angleY < -89.0) then angleY = -89.0 end
    
    local pCoords = GetEntityCoords(PlayerPedId())
    local behindCam = {
        x = pCoords.x + ((Cos(angleZ) * Cos(angleY)) + (Cos(angleY) * Cos(angleZ))) / 2 * (radius + 0.5),
        y = pCoords.y + ((Sin(angleZ) * Cos(angleY)) + (Cos(angleY) * Sin(angleZ))) / 2 * (radius + 0.5),
        z = pCoords.z + ((Sin(angleY))) * (radius + 0.5)
    }
    local rayHandle = StartShapeTestRay(pCoords.x, pCoords.y, pCoords.z + 0.5, behindCam.x, behindCam.y, behindCam.z, -1, PlayerPedId(), 0)
    local a, hitBool, hitCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
    
    local maxRadius = radius
    if (hitBool and Vdist(pCoords.x, pCoords.y, pCoords.z + 0.5, hitCoords) < radius + 0.5) then
        maxRadius = Vdist(pCoords.x, pCoords.y, pCoords.z + 0.5, hitCoords)
    end
    
    local offset = {
        x = ((Cos(angleZ) * Cos(angleY)) + (Cos(angleY) * Cos(angleZ))) / 2 * maxRadius,
        y = ((Sin(angleZ) * Cos(angleY)) + (Cos(angleY) * Sin(angleZ))) / 2 * maxRadius,
        z = ((Sin(angleY))) * maxRadius
    }
    
    local pos = {
        x = pCoords.x + offset.x,
        y = pCoords.y + offset.y,
        z = pCoords.z + offset.z
    }
    
    return pos
end


function BeginDeathScreen()
	isDead = true
	ClearFocus()
    local playerPed = PlayerPedId()

    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", GetEntityCoords(playerPed), 0, 0, 0, GetGameplayCamFov())
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, false)

	TriggerEvent('EnableDisableHUDFS', false)
    BeginTimerDeath()
	__nSaveNewPosition()
	SendSignalEMS()
    PlaySoundFrontend(-1, "MP_Flash", "WastedSounds", true)
end

function EndDeathScreen()
    isDead = false
    local playerPed = PlayerPedId()

	SetCamEffect(0)
	StopGameplayCamShaking()
	StopScreenEffect("DeathFailMPIn")
	SetCinematicModeActive(false)
	NetworkSetInSpectatorMode(false, playerPed)
	NetworkSetOverrideSpectatorMode(false)
	SetFocusEntity(playerPed)
	PlaySoundFrontend(-1, "Hit", "RESPAWN_ONLINE_SOUNDSET", true)

	TriggerEvent('EnableDisableHUDFS', true)
	ClearFocus()
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
    cam = nil
end

function SendSignalEMS()
	local plyPos = GetEntityCoords(GetPlayerPed(-1), true)
	TriggerServerEvent("call:makeCall", "medic", {x=plyPos.x,y=plyPos.y,z=plyPos.z}, "~h~[URGENCE] Une personne à été signalé au sol, inconscient !")
	TriggerEvent("NUI-Notification", {"Urgence envoyé !."})
end

__RoundNumber = function(value, numDecimalPlaces)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", value))
end

__nSaveNewPosition = function()
    local pPed = GetPlayerPed(-1)
	local pCoords = GetEntityCoords(pPed)
	TriggerServerEvent("GTA:SavePos", pCoords)
end

function BeginTimerDeath()
	local earlySpawnTimer = __RoundNumber(EarlyRespawnTimer / 1000)
	local bleedoutTimer = __RoundNumber(BleedoutTimer / 1000)

	Citizen.CreateThread(function()
		while earlySpawnTimer > 0 and isDead do
			Citizen.Wait(1000)

			if earlySpawnTimer > 0 then
				earlySpawnTimer = earlySpawnTimer - 1
			end
		end

		while bleedoutTimer > 0 and isDead do
			Citizen.Wait(1000)

			if bleedoutTimer > 0 then
				bleedoutTimer = bleedoutTimer - 1
			end
		end
	end)

	Citizen.CreateThread(function()
		local timeHeld = 0
		local maxvalue = 0.001
		local width = 0.2
		local xvalue = 0.38
		local yvalue = 0.05

		while earlySpawnTimer > 0 and isDead do --> temps que le temps de spawn est sup a 0 et que le player est dead on affiche le timer.
			Citizen.Wait(0)
			local scaleform = RequestScaleformMovie("MP_BIG_MESSAGE_FREEMODE")
			local playerPed = GetPlayerName()

			SetAudioFlag("LoadMPData", true)
            RequestScriptAudioBank("mp_wasted", 1)
            StartScreenEffect("DeathFailMPIn", 0, 0)
            ShakeGameplayCam("DEATH_FAIL_IN_EFFECT_SHAKE", 1.0)
            SetCamEffect(2)
			
	        while not HasScaleformMovieLoaded(scaleform) do
	        --SetAudioFlag("LoadMPData", true)
	        --PlaySoundFrontend(-1, "MP_Flash", "WastedSounds", true)
		    Citizen.Wait(0)
	        end

	        PushScaleformMovieFunction(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
	        BeginTextCommandScaleformString("RESPAWN_W")
	        EndTextCommandScaleformString()
	       --PlaySoundFrontend(-1, "MP_Flash", "WastedSounds", true)
	        BeginTextCommandScaleformString("TICK_DIED")
            AddTextComponentSubstringPlayerName(playerPed)
            SetNotificationTextEntry("TICK_DIED")
            EndTextCommandScaleformString()
	        PopScaleformMovieFunctionVoid()
	        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
			drawHelpTxt(xvalue + (((maxvalue/2)/((maxvalue/2)/width))/2), yvalue , 0.15, 0.05, 0.5, "Réapparition ~w~possible dans ~g~"..tonumber(__RoundNumber(earlySpawnTimer)).." ~w~secondes ~w~.", 255, 255, 255, 255, 6) -- Text display of timer
			HidAllHudFrame()
		end

		Citizen.CreateThread(function()
			while isDead do
				Citizen.Wait(config.timerSignalEMS)

				if isDead then
					SendSignalEMS()
				end
			end
		end)

		while bleedoutTimer > 0 and isDead do
			Citizen.Wait(0)

			drawHelpTxt(xvalue + (((maxvalue/2)/((maxvalue/2)/width))/2), yvalue , 0.15, 0.05, 0.5, "Maintenez E pour respawn a l'hopital ou bien patientez l'arrivé des urgences", 255, 255, 255, 255, 6) -- Text display of timer

			if IsControlPressed(0, Keys['E']) then
				timeHeld = timeHeld + 1
			else
				timeHeld = 0
			end

			if IsControlPressed(0, Keys['E']) and timeHeld > 60 then
				BeginPlayerEffect()
				break
			end
		end

		if bleedoutTimer < 1 and isDead then
			BeginPlayerEffect()
		end
	end)
end



function BeginPlayerEffect()
	EndDeathScreen()

	local playerPed = PlayerPedId()
	DoScreenFadeOut(500)
	NetworkResurrectLocalPlayer(1268.3823, 1036.4148, 33.5531, 83.6203 , true, false) --> nouvel coord aprés le respawn.	
	TriggerServerEvent("item:reset")
	ClearPedBloodDamage(playerPed)
	ClearPedWetness(playerPed)

	--> Tenue une fois spawn a l'hosto :
	if GetEntityModel(playerPed) == 1885233650 then
		SetPedComponentVariation(GetPlayerPed(-1), 1, 0, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 3, 15, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 4, 61, 3, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 5, 0, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 6, 34, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 7, 0, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 8, 15, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 9, 0, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 10, 0, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 11, 15, 0, 0)
	elseif GetEntityModel(playerPed) == -1667301416 then
		SetPedComponentVariation(GetPlayerPed(-1), 1, 0, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 3, 15, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 4, 15, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 5, 0, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 6, 35, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 7, 0, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 8, 2, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 9, 0, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 10, 0, 0, 0)
		SetPedComponentVariation(GetPlayerPed(-1), 11, 15, 0, 0)
	end
	SetTimecycleModifier("Drunk")
	SetPedMotionBlur(playerPed, true)
	RequestAnimSet("MOVE_M@DRUNK@SLIGHTLYDRUNK")
	while not HasAnimSetLoaded("MOVE_M@DRUNK@SLIGHTLYDRUNK") do
	    Citizen.Wait(0)
	end
	SetPedMovementClipset(playerPed, "MOVE_M@DRUNK@SLIGHTLYDRUNK", true)
	SetPedIsDrunk(playerPed, true)	 
	Citizen.Wait(1000)	
	DoScreenFadeIn(5000)
	
	Citizen.Wait(35000) --> Time Effect
	
	DoScreenFadeOut(1000)
	Citizen.Wait(1000)			
	ClearTimecycleModifier()
	ResetPedMovementClipset(playerPed, 0)
	SetPedIsDrunk(playerPed, false)
	SetPedMotionBlur(playerPed, false)
	Citizen.Wait(1000)
	DoScreenFadeIn(1000)
	TriggerEvent("nResetStatsFood")
end
