local missionActive = false
local spawnedVehicle, missionVehiclePlate, vehicleBlip, depositBlip = nil, nil, nil, nil

local trackersLeft = 0
local hackCooldown = false

local function canStartMethRun(cb)
    lib.callback('arkeo-methRun:canStart', false, function(allowed, msg)
        cb(allowed, msg)
    end)
end

exports('UseDrugPhone', function(data, slot)
    canStartMethRun(function(allowed, msg)
        if not allowed then
            lib.notify({title = 'Meth Run', description = msg or "Run is on cooldown.", type = 'error'})
            return
        end
        local meth = exports.ox_inventory:Search('count', Config.RequiredBrick)
        if meth < Config.RequiredBrickAmount then
            lib.notify({title = 'Meth Run', description = "You need exactly 10 meth bricks to start a run!", type = 'error'})
            return
        end
        if missionActive then
            lib.notify({title = 'Meth Run', description = "You already have an active meth run!", type = 'error'})
            return
        end
        exports.ox_inventory:useItem(data, function(used)
            if used then
                TriggerEvent('arkeo-methRun:startMission')
            end
        end)
    end)
end)

exports('UseMethLaptop', function(data, slot)
    trackersLeft = trackersLeft or 0
    if not spawnedVehicle or not missionActive or not IsPedInVehicle(cache.ped, spawnedVehicle, false) then
        lib.notify({title = 'Meth Run', description = "You must be in the getaway vehicle!", type = 'error'})
        return
    end
    if GetPedInVehicleSeat(spawnedVehicle, 0) ~= cache.ped then
        lib.notify({title = 'Meth Run', description = "Only the front passenger can hack!", type = 'error'})
        return
    end
    if trackersLeft <= 0 then
        lib.notify({title = 'Meth Run', description = "All trackers are already disabled!", type = 'error'})
        return
    end
    if hackCooldown then
        lib.notify({title = 'Meth Run', description = "You must wait before trying another hack!", type = 'error'})
        return
    end
    hackCooldown = true
    local success = exports['arkeo-hack']:StartHack('Pcb', 'easy') -- change to Packet or Decrypt | easy, medium, hard
    if success then
        TriggerServerEvent('arkeo-methRun:removeTracker', missionVehiclePlate)
        exports['arkeo-ui']:ShowMissionCard("Meth Run", ("Disable all vehicle trackers: %d/%d disabled"):format((Config.TotalTrackers or 7) - trackersLeft, Config.TotalTrackers or 7))
        if trackersLeft <= 0 then
            exports['arkeo-ui']:ShowMissionCard("Meth Run", "All trackers disabled! Lose the cops and deliver the vehicle.")
        end
    else
        lib.notify({title = 'Meth Run', description = "Hack failed! Try again in 30 seconds.", type = 'error'})
    end
    Citizen.SetTimeout((Config.HackCooldown or 30000), function()
        hackCooldown = false
        lib.notify({title = 'Meth Run', description = "You can now try hacking again.", type = 'info'})
    end)
end)

RegisterNetEvent('arkeo-methRun:syncTrackers', function(plate, newCount)
    if missionVehiclePlate and plate and missionVehiclePlate == plate then
        trackersLeft = newCount
    end
end)

RegisterNetEvent('arkeo-methRun:startMission', function()
    if missionActive then return end
    missionActive = true
    RequestAnimDict("cellphone@")
    while not HasAnimDictLoaded("cellphone@") do Wait(10) end
    TaskPlayAnim(cache.ped, "cellphone@", "cellphone_call_listen_base", 8.0, -8.0, 40000, 49, 0, false, false, false)
    lib.notify({title = 'Meth Run', description = "Getting location", type = 'success'})
    Wait(1000)
    ClearPedTasks(cache.ped)
    exports['arkeo-ui']:ShowMissionCard(Config.Mission.StartMissionTitle, Config.Mission.StartMissionMsg)
    if not vehicleBlip then
        vehicleBlip = AddBlipForCoord(Config.Vehicle.spawn.x, Config.Vehicle.spawn.y, Config.Vehicle.spawn.z)
        SetBlipSprite(vehicleBlip, 663)
        SetBlipColour(vehicleBlip, 1)
        SetBlipScale(vehicleBlip, 1.0)
        SetBlipAsShortRange(vehicleBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Meth Delivery Vehicle")
        EndTextCommandSetBlipName(vehicleBlip)
    end
    trackersLeft = Config.TotalTrackers or 7
    hackCooldown = false
    CreateThread(function()
        while missionActive and not spawnedVehicle do
            local dist = #(GetEntityCoords(cache.ped) - vector3(Config.Vehicle.spawn.x, Config.Vehicle.spawn.y, Config.Vehicle.spawn.z))
            if dist < Config.VehicleProximity then
                TriggerServerEvent('arkeo-methRun:canSpawnVehicle')
                break
            end
            Wait(1000)
        end
    end)
end)

RegisterNetEvent('arkeo-methRun:createVehicle', function(model, coords)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, false)
    local plate = 'METH' .. tostring(math.random(1000,9999))
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNumberPlateText(veh, plate)
    SetEntityAsMissionEntity(veh, true, true)
    spawnedVehicle = veh
    missionVehiclePlate = plate
    if vehicleBlip then RemoveBlip(vehicleBlip) vehicleBlip = nil end
    trackersLeft = Config.TotalTrackers or 7
    hackCooldown = false
    exports.ox_target:addGlobalVehicle({
        {
            name = 'methrun_package',
            icon = 'fa-solid fa-box',
            label = 'Package Meth',
            bones = { 'boot', 'trunk' },
            canInteract = function(entity)
                return entity == spawnedVehicle
            end,
            onSelect = function(entity)
                RequestAnimDict("mini@repair")
                while not HasAnimDictLoaded("mini@repair") do Wait(10) end
                TaskPlayAnim(cache.ped, "mini@repair", "fixing_a_ped", 8.0, -8.0, -1, 49, 0, false, false, false)
                lib.progressBar({
                    duration = 6500,
                    label = "Packaging Meth...",
                    useWhileDead = false,
                    canCancel = false,
                    disable = { car = true, move = true, combat = true },
                })
                ClearPedTasks(cache.ped)
                TriggerServerEvent('arkeo-methRun:packageMeth', missionVehiclePlate)
            end,
            distance = 2.0,
        }
    })
end)
RegisterNetEvent('arkeo-methRun:showNextMission', function()
    exports['arkeo-ui']:HideMissionCard()
    exports['arkeo-ui']:ShowMissionCard(Config.Mission.DeliverMissionTitle, Config.Mission.DeliverMissionMsg)
end)

RegisterNetEvent('arkeo-methRun:showDepositBlip', function()
    if depositBlip then RemoveBlip(depositBlip) depositBlip = nil end
    depositBlip = AddBlipForCoord(Config.Delivery.coords.x, Config.Delivery.coords.y, Config.Delivery.coords.z)
    SetBlipSprite(depositBlip, 514)
    SetBlipColour(depositBlip, 2)
    SetBlipScale(depositBlip, 1.0)
    SetBlipAsShortRange(depositBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Meth Drop-off")
    EndTextCommandSetBlipName(depositBlip)
    CreateThread(function()
        while missionActive and spawnedVehicle do
            local vehicleCoords = GetEntityCoords(spawnedVehicle)
            local dropCoords = vector3(Config.Delivery.coords.x, Config.Delivery.coords.y, Config.Delivery.coords.z)
            if #(vehicleCoords - dropCoords) < 6.0 and IsPedInVehicle(cache.ped, spawnedVehicle, false) then
                if trackersLeft > 0 then
                    lib.notify({title = 'Meth Run', description = ("All trackers must be disabled! %d left."):format(trackersLeft), type = 'error'})
                else
                    TriggerServerEvent('arkeo-methRun:deliverMeth')
                    Wait(1000)
                    break
                end
            end
            Wait(1000)
        end
    end)
end)

RegisterNetEvent('arkeo-methRun:endMission', function()
    if depositBlip then RemoveBlip(depositBlip) depositBlip = nil end
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        Wait(10000)
        DeleteEntity(spawnedVehicle)
    end
    spawnedVehicle = nil
    missionVehiclePlate = nil
    missionActive = false
    trackersLeft = 0
    hackCooldown = false
    exports['arkeo-ui']:HideMissionCard()
end)

RegisterNetEvent('arkeo-methRun:notify', function(msg, type)
    lib.notify({
        title = 'Meth Run',
        description = msg,
        type = type or 'info'
    })
end)