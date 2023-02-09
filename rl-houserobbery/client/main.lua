local robando = false
local entradaCoords = nil
local cerradura = true
local coordsx, coordsy, coordsz, t
local coord = false
local alarma = false
local timer = false
local modelo
local casacoords
local items = {}
local trabajando = false
local interior = {}
local ruido = 0
local dentro = false
local cargando = false
local PlayerJob
local QBCore = exports['qb-core']:GetCoreObject()

Citizen.CreateThread(function()
	if Config.Framework == 'QBCORE' then
		QBCore.Functions.TriggerCallback('rl_houserobbery:entrada', function(x,y,z,a)
			coordsx, coordsy, coordsz, t = x,y,z,a
			coord = true
		end)
	end
end)



function loadAnimDict(dict)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
	 Citizen.Wait(5)
	end
end

RegisterCommand("rob1", function()
	loadAnimDict('amb@prop_human_bum_bin@idle_b')
	TaskPlayAnim(PlayerPedId(), "amb@prop_human_bum_bin@idle_b", "idle_d", 1.0, 1.0, 1.0, 1, 0.0, 0, 0, 0)
  	QBCore.Functions.Progressbar("search_", "Searching ", 20000, false, true, {}, {}, {}, {}, function()
	
		---Citizen.Wait(20000)
		EnableAllControlActions(0)
		---TriggerServerEvent('houseRobberies:searchItem')
	 	ClearPedTasks(PlayerPedId())
	end)
end)


Citizen.CreateThread(function()
	while not robando do
		Citizen.Wait(1000)
	end
	while true do
		local w = 500
		if robando then
			w = 3			
			if PlayerJob ~= Config.PoliceJobName then
				for i = 1, #items do
					local objCoords = GetEntityCoords(items[i].objeto)
					if #(GetEntityCoords(PlayerPedId()) - objCoords) <= items[i].dist and not items[i].robado then
						DrawText3D(objCoords.x, objCoords.y, objCoords.z+0.45, Config.Lang['search'])
						if IsControlJustPressed(0,38) and not cargando then
							loadAnimDict('amb@prop_human_bum_bin@idle_b')
							TaskPlayAnim(PlayerPedId(), "amb@prop_human_bum_bin@idle_b", "idle_d", 1.0, 1.0, 1.0, 1, 0.0, 0, 0, 0)
							QBCore.Functions.Progressbar("search_", "Searching..", 1000, false, true, {}, {}, {}, {}, function()
							
								---Citizen.Wait(20000)
								EnableAllControlActions(0)
								---TriggerServerEvent('houseRobberies:searchItem')
								ClearPedTasks(PlayerPedId())
							end)
							items[i].robado = true
							if items[i].anim == 'cajafuerte' then
								TriggerEvent('safecracker:start',false,2,function(res)
									if res then
										TriggerServerEvent('rl_houserobbery:item','cajafuerte',t)
									else
										items[i].robado = false
									end
								end)
							else
								TriggerEvent('rl_houserobbery:anim',items[i].anim,items[i].borrar,i)
							end
						end
					end
				end
			end
			if #(GetEntityCoords(PlayerPedId()) - vector3(casacoords.x, casacoords.y, casacoords.z)) < 1.5 then
				DrawText3D(casacoords.x, casacoords.y, casacoords.z, Config.Lang['exit'])
				if IsControlJustPressed(0,74) then
					if PlayerJob ~= Config.PoliceJobName then	
						if esNoche() then
							salir()
						else
							salir(true)
						end
					else
						salir(true)
					end
				end
			end
		end
		Citizen.Wait(w)
	end
end)

Citizen.CreateThread(function()
	local w
	while not coord do
		Citizen.Wait(0)
	end
	while true do
		w = 1000
		local playercoords = GetEntityCoords(PlayerPedId())
		local dist = #(vector3(playercoords.x, playercoords.y, playercoords.z) - vector3(coordsx, coordsy, coordsz))
			if dist < 2 then
				w = 5
				--DrawText3D(coordsx, coordsy, coordsz, Config.Lang['knock'])	
				if IsControlJustPressed(0, 38) then
					LoadAnim("timetable@jimmy@doorknock@")
					FreezeEntityPosition(PlayerPedId(),true)
					TaskPlayAnim(PlayerPedId(), "timetable@jimmy@doorknock@", 'knockdoor_idle', 2.0, 2.0, 3000, 1, 0, true, true, true)						
					FreezeEntityPosition(PlayerPedId(),false)
					TriggerEvent('qb-menu:client:openMenu', {
						{
							id = 1,
							header = Config.Lang['getjob'],
							txt = Config.Lang['waitcall'],
							params = {
								event = "rl_houserobbery:iniciar",
								args = {}
							}
						},
					})						
				end
			end
		Citizen.Wait(w)
	end
end)



RegisterNetEvent('rl_houserobbery:iniciar')
AddEventHandler('rl_houserobbery:iniciar', function()
	if Config.Framework == 'QBCORE' then
		QBCore.Functions.TriggerCallback('rl_houserobbery:trabajos', function(puedeRobar)	
			if puedeRobar then
				if not trabajando then
					limpiar()
					trabajando = true
					entradaCoords = Casas()
					QBCore.Functions.Notify("The boss is gonna assign you a house, wait for his call.", "primary")
					Citizen.Wait(Config.CoordsWait * 60 * 1000)
					PlaySoundFrontend(-1, "Menu_Accept", "Phone_SoundSet_Default", true)
					SetNewWaypoint(entradaCoords.x,entradaCoords.y)
					QBCore.Functions.Notify("The boss sent you the house coords, rob the house during night", "primary")
					Entrada()
				else
					QBCore.Functions.Notify("Chill, the boss is looking for a house", "error")
				end
			else
				QBCore.Functions.Notify("Chill, the boss is looking for a house", "error")
			end
		end)
	end
end)



if Config.PoliceRaidWithCommand then
	RegisterCommand(Config.PoliceRaidCommand, function()
		if PlayerJob == Config.PoliceJobName then
			TriggerEvent('rl_houserobbery:policeRaid')
		end
	end)
end

RegisterNetEvent('rl_houserobbery:policeRaid')
AddEventHandler('rl_houserobbery:policeRaid', function()
	if PlayerJob == Config.PoliceJobName then
		for i = 1, #Config.Casas do
			local casa = Config.Casas[i]
			if #(GetEntityCoords(PlayerPedId()) - vector3(casa.x, casa.y, casa.z)) < 5 then
				entradaCoords = casa
				entrar(true)
			end
		end
	end
end)


function Casas()
	local ubicacion = math.random(1, #Config.Casas)		
	local c = Config.Casas[ubicacion]
	return c
end

function Entrada()
	while trabajando do
		local espera = 1500
		distancia = #(GetEntityCoords(PlayerPedId()) - vector3(entradaCoords.x, entradaCoords.y, entradaCoords.z))
		if distancia < 3 and esNoche() then
			espera = 5
			DrawText3D(entradaCoords.x, entradaCoords.y, entradaCoords.z, Config.Lang['enter'])
			if IsControlJustReleased(0,74) and distancia < 3 then
				if cerradura then
					if Config.Lockpick then	
						if Config.Framework == 'QBCORE' then
							QBCore.Functions.TriggerCallback('rl_houserobbery:lockpick',function(tieneLockpick)
								local seconds = math.random(10,20)
                                local circles = 3
								local success = exports['qb-lock']:StartLockPickCircle(circles, seconds, success)
								if success then
									ganzuar(success)
									exports['qb-dispatch']:HouseRobbery()
								else
									QBCore.Functions.Notify("Lockpick false", "error")
								end
							end)
						end
					else
						ganzuar()
					end
				else
					entrar()
				end
			end	
		end
		Citizen.Wait(espera)
	end		
end
function entrar(policia)
	if not robando then
		if entradaCoords.modelo == 'HighEnd' then
			casacoords, heading, items, interior = HighEnd(entradaCoords)
		elseif entradaCoords.modelo == 'MidApt' then
			casacoords, heading, items, interior = MidApt(entradaCoords)
		end
		ClearAreaOfPeds(casacoords.x,casacoords.y,casacoords.z, 100.0, 1)
		robando = true
		if not policia then
			TriggerEvent('rl_houserobbery:ruido')
		end
	else
		DoScreenFadeOut(1000)
		Citizen.Wait(1500)
		SetEntityCoords(PlayerPedId(),casacoords.x,casacoords.y,casacoords.z)
		SetEntityHeading(PlayerPedId(),heading)
		Citizen.Wait(2500)
		DoScreenFadeIn(1500)
	end
	dentro = true
end

RegisterNetEvent('rl_houserobbery:anim')
AddEventHandler('rl_houserobbery:anim', function(anim, borrar, i)
	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)
	LoadAnim('mp_common_heist')
	LoadAnim("anim@heists@box_carry@")
	if anim == 'tv' then
		FreezeEntityPosition(ped,true)
		TaskPlayAnim(ped, "mp_common_heist", 'use_terminal_loop', 2.0, 2.0, -1, 1, 0, true, true, true)
		Citizen.Wait(10000)
		ClearPedTasksImmediately(ped)
		FreezeEntityPosition(ped,false)
		television = CreateObject(GetHashKey("prop_tv_flat_01"), coords.x, coords.y, coords.z,  true,  true, false)
		AttachEntityToEntity(television, ped, GetPedBoneIndex(ped, 57005), 0.0, 0.0, 0.0, 0.0, 20.0, 0.0, true, true, false, true, 1, true)
		RequestWalking('anim_group_move_ballistic')
		SetPedMovementClipset(ped, 'anim_group_move_ballistic', 0.2)
		DeleteEntity(items[i].objeto)
		cargando = true
		while true do
			local w = 50
			if not IsEntityPlayingAnim(ped, "anim@heists@box_carry@", "walk", 3) then
				TaskPlayAnim(ped, 'anim@heists@box_carry@', "walk", 8.0, -8, -1, 49, 0, 0, 0, 0)
			end			
			local ubicacion = GetEntityCoords(PlayerPedId())
			local vehicle = getVehicleInfront(2)
			local d1 = GetModelDimensions(GetEntityModel(vehicle))
			local vehicleCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0,d1["y"]+0.60,0.0)
			local Distance = GetDistanceBetweenCoords(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, ubicacion.x, ubicacion.y, ubicacion.z, false)
			
			if Distance < 3 then
				w = 3
				DrawText3D(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, Config.Lang['putinveh'])
			end
			if IsControlJustReleased(0, 38) then                        
				if esVanWL() then	
					Citizen.Wait(400)
					DetachEntity(television, 1, 0)
					DeleteEntity(television)
					television = nil
					ClearPedTasksImmediately(ped)
					RemoveAnimSet('anim_group_move_ballistic')
					ResetPedMovementClipset(ped)
					TriggerServerEvent('rl_houserobbery:item','tv',t)
					cargando = false
					break
				end
			end
			Citizen.Wait(w)
		end
	elseif anim == 'telescopio' then
		LoadAnim("anim@heists@narcotics@trash")
		FreezeEntityPosition(ped,true)
		TaskPlayAnim(ped, "mp_common_heist", 'use_terminal_loop', 2.0, 2.0, -1, 1, 0, true, true, true)
		Citizen.Wait(2000)
		ClearPedTasksImmediately(ped)
		FreezeEntityPosition(ped,false)
		telescopioObj = CreateObject(GetHashKey("prop_t_telescope_01b"), coords.x, coords.y, coords.z,  true,  true, false)
		AttachEntityToEntity(telescopioObj, ped, GetPedBoneIndex(ped, 57005), -0.06, 0.0, -0.31, 0.0, 20.0, 0.0, true, true, false, true, 1, true)
		DeleteEntity(items[i].objeto)
		cargando = true
		while true do
			local w = 50
			if not IsEntityPlayingAnim(ped, "anim@heists@narcotics@trash", "walk", 3) then
				TaskPlayAnim(ped, "anim@heists@narcotics@trash", "walk", 8.0, 8.0, -1, 50, 0, false, false, false)
			end
			local ubicacion = GetEntityCoords(PlayerPedId())
			local vehicle = getVehicleInfront(2)
			local d1 = GetModelDimensions(GetEntityModel(vehicle))
			local vehicleCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0,d1["y"]+0.60,0.0)
			local Distance = GetDistanceBetweenCoords(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, ubicacion.x, ubicacion.y, ubicacion.z, false)
			
			if Distance < 3 then
				w = 3
				DrawText3D(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, Config.Lang['putinveh'])
			end
			
			if IsControlJustReleased(0, 38) then                           
				if esVanWL() then	
					Citizen.Wait(400)
					DetachEntity(telescopioObj, 1, 0)
					DeleteEntity(telescopioObj)
					telescopioObj = nil
					ClearPedTasksImmediately(ped)		
					TriggerServerEvent('rl_houserobbery:item','telescopio',t)
					cargando = false
					break
				end
			end
			Citizen.Wait(w)
		end
	elseif anim == 'pintura' then
		FreezeEntityPosition(ped,true)
		TaskPlayAnim(ped, "mp_common_heist", 'use_terminal_loop', 2.0, 2.0, -1, 1, 0, true, true, true)
		Citizen.Wait(2000)
		ClearPedTasksImmediately(ped)
		Citizen.Wait(250)	
		AnimBolso()
		DeleteEntity(items[i].objeto)
		TriggerServerEvent('rl_houserobbery:item','arte',t)
		return true
	elseif anim == 'normal' then
		FreezeEntityPosition(ped,true)	
		AnimBolso()
		TriggerServerEvent('rl_houserobbery:item','random',t)
		if borrar then
			DeleteEntity(items[i].objeto)
		end
	elseif anim == 'mesa' then
		FreezeEntityPosition(ped,true)
		Citizen.Wait(1000)
		ClearPedTasksImmediately(ped)
		FreezeEntityPosition(ped,false)
		local suerte = math.random(1,10)
		TriggerServerEvent('rl_houserobbery:item','random',t)
		if borrar then
			DeleteEntity(items[i].objeto)
		end
	elseif anim == 'laptop' then
		FreezeEntityPosition(ped,true)
		AnimBolso()
		DeleteEntity(items[i].objeto)
		TriggerServerEvent('rl_houserobbery:item','laptop',t)
	else
		LoadAnim("anim@heists@box_carry@")
		FreezeEntityPosition(ped,true)
		TaskPlayAnim(ped, "mp_common_heist", 'use_terminal_loop', 2.0, 2.0, -1, 1, 0, true, true, true)
		Citizen.Wait(5000)
		ClearPedTasksImmediately(ped)
		FreezeEntityPosition(ped,false)
		local objeto = CreateObject(GetHashKey(anim), coords.x, coords.y, coords.z,  true,  true, false)
		AttachEntityToEntity(objeto, ped, GetPedBoneIndex(ped, 28422), 0.0, -0.1, -0.08, 0.0, 90.0, 0.0, true, true, false, true, 1, true)
		DeleteEntity(items[i].objeto)
		cargando = true
		while true do
			local w = 50
			if not IsEntityPlayingAnim(ped, "anim@heists@box_carry@", "idle", 3) then
				TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, 8.0, -1, 50, 0, false, false, false)
			end
			local ubicacion = GetEntityCoords(PlayerPedId())
			local vehicle = getVehicleInfront(2)
			local d1 = GetModelDimensions(GetEntityModel(vehicle))
			local vehicleCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0,d1["y"]+0.60,0.0)
			local Distance = GetDistanceBetweenCoords(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, ubicacion.x, ubicacion.y, ubicacion.z, false)
			
			if Distance < 3 then
				w = 3
				DrawText3D(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, Config.Lang['putinveh'])
			end
			
			if IsControlJustReleased(0, 38) then                           
				if esVanWL() then	
					Citizen.Wait(400)
					DetachEntity(objeto, 1, 0)
					DeleteEntity(objeto)
					objeto = nil
					ClearPedTasksImmediately(ped)		
					TriggerServerEvent('rl_houserobbery:item',anim,t)
					cargando = false
					break
				end
			end
			Citizen.Wait(w)
		end
	end
end)

function salir(despawn)
	dentro = false
	DoScreenFadeOut(1000)
	Citizen.Wait(1500)
	SetEntityCoords(PlayerPedId(),entradaCoords.x, entradaCoords.y, entradaCoords.z)
	if Config.UsingEasyTime then
		TriggerEvent('cd_easytime:PauseSync', false)
	else
		h,m,s = NetworkGetGlobalMultiplayerClock()
		NetworkOverrideClockTime(h,m,s)
	end
	Citizen.Wait(800)
	DoScreenFadeIn(2600)
	if despawn then
		limpiar()
	end
	SendNUIMessage({closeProgress = true})
end

function esVanWL()
	local vehicle = getVehicleInfront(2)
	local modelo = GetEntityModel(vehicle)
	if vehicle then
		if not IsThisModelABike(modelo) then
			SetVehicleDoorOpen(vehicle,2,false,false)
			SetVehicleDoorOpen(vehicle,3,false,false)
			SetVehicleDoorOpen(vehicle,5,false,false)
			SetVehicleDoorOpen(vehicle,6,false,false)
			SetVehicleDoorOpen(vehicle,7,false,false)
			return true
		end
	else
		QBCore.Functions.Notify("Not true car", "error")
	end
	return false
end

function AnimBolso()
	local playerPed = PlayerPedId()
	LoadAnim('anim@heists@ornate_bank@ig_4_grab_gold')
	local fwd, _, _, pos = GetEntityMatrix(playerPed)
	local newPos = (fwd * 0.8) + pos
	SetEntityCoords(playerPed, newPos.xy, newPos.z - 1.5)
	local rot, pos = GetEntityRotation(playerPed), GetEntityCoords(playerPed)
	SetPedComponentVariation(playerPed, 5, -1, 0, 0)
	local bag = CreateObject(GetHashKey("hei_p_m_bag_var22_arm_s"), pos.x, pos.y, pos.z,  true,  true, false)
	local entrada = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 2, false, false, 1065353216, 0, 1.3)
	local salida = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 2, false, false, 1065353216, 0, 1.3)
	SetEntityCollision(bag, 0, 1)
	NetworkAddPedToSynchronisedScene(playerPed, entrada, "anim@heists@ornate_bank@ig_4_grab_gold", "enter", 1.5, -4.0, 1, 16, 1148846080, 0)
	NetworkAddEntityToSynchronisedScene(bag, entrada, "anim@heists@ornate_bank@ig_4_grab_gold", "enter_bag", 4.0, -8.0, 1)
	NetworkAddPedToSynchronisedScene(playerPed, salida, "anim@heists@ornate_bank@ig_4_grab_gold", "exit", 1.5, -4.0, 1, 16, 1148846080, 0)
	NetworkAddEntityToSynchronisedScene(bag, salida, "anim@heists@ornate_bank@ig_4_grab_gold", "exit_bag", 4.0, -8.0, 1)
	NetworkStartSynchronisedScene(entrada)
	Citizen.Wait(1500)
	NetworkStartSynchronisedScene(salida)
	Citizen.Wait(1500)
	DeleteEntity(bag)
	SetPedComponentVariation(playerPed, 5, 45, 0, 0)
	NetworkStopSynchronisedScene(entrada)
	NetworkStopSynchronisedScene(salida)
	FreezeEntityPosition(playerPed, false)
end

function DrawText3D(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 500
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 0, 0, 0, 80)
end

function LoadAnim(animDict)
	RequestAnimDict(animDict)
	while not HasAnimDictLoaded(animDict) do
		Citizen.Wait(10)
	end
end

function RequestWalking(set)
	RequestAnimSet(set)
	while not HasAnimSetLoaded(set) do
		Citizen.Wait(1)
	end 
end

function ganzuar()
	LoadAnim('veh@break_in@0h@p_m_one@')
	TaskPlayAnim(PlayerPedId(), "veh@break_in@0h@p_m_one@", "low_force_entry_ds", 1.0, 1.0, 1.0, 1, 0.0, 0, 0, 0)
	Citizen.Wait(1500)
	ClearPedTasks(PlayerPedId())
	cerradura = false
	if Config.RandomPoliceCall then	
		local s = math.random(1,10)
		if s == 2 then
			TriggerServerEvent('rl_houserobbery:policeCall',entradaCoords)
		end
	end
	entrar()
end

function getVehicleInfront(max)
	local p = PlayerPedId()
	local p_pos = GetEntityCoords(p)
	local p_fwd = GetEntityForwardVector(p)
	local up = vector3(0.0,0.0,1.0)
	local from = p_pos + (up*2)
	local to   = p_pos - (up*2)
	local ent_hit
	for i=0,(max or 3),1 do
		local ray = StartShapeTestRay(from.x + (p_fwd.x*i),from.y + (p_fwd.y*i),from.z + (p_fwd.z*i),to.x + (p_fwd.x*i),to.y + (p_fwd.y*i),to.z + (p_fwd.z*i),2,ignore, 0);
		_,_,_,_,ent_hit = GetShapeTestResult(ray); 
		if ent_hit and ent_hit ~= 0 and ent_hit ~= -1 then
			local type = GetEntityType(ent_hit)
			if GetEntityType(ent_hit) == 2 then
				return ent_hit
			end
		end
	end
  return false
end

function limpiar()
	cerradura = true
	robando = false
	trabajando = false
	dentro = false
	ruido = 0
	if #items > 0 then
		for i = 1, #items do
			DeleteEntity(items[i].objeto)
		end
	end
	if #interior > 0 then
		for i = 1, #interior do
			DeleteEntity(interior[i])
		end
	end
	SendNUIMessage({closeProgress = true})
end

function esNoche()
	local hora = GetClockHours()
	if hora > Config.Night[1] or hora < Config.Night[2] then
		return true
	end
	return false
end

function barra(porcentaje)
	SendNUIMessage({runProgress = true, Length = porcentaje})
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
    end)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo.name
end)