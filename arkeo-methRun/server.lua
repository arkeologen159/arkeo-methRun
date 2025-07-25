local methRunActive = false
local cooldownActive = false

RegisterNetEvent('arkeo-methRun:canSpawnVehicle', function()
    local src = source
    if methRunActive or cooldownActive then
        TriggerClientEvent('arkeo-methRun:notify', src, 'A meth run is already active or on cooldown.', 'error')
        return
    end
    methRunActive = true
    cooldownActive = true 
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', 'methRun', true)
    TriggerClientEvent('arkeo-methRun:createVehicle', src, Config.Vehicle.model, Config.Vehicle.spawn)
end)

RegisterNetEvent('arkeo-methRun:packageMeth', function(plate)
    local src = source
    local item = exports.ox_inventory:GetItem(src, Config.RequiredBrick)
    local brickCount = item and item.count or 0
    if brickCount < Config.RequiredBrickAmount then
        TriggerClientEvent('arkeo-methRun:notify', src, 'You need exactly ' .. Config.RequiredBrickAmount .. ' bricks.', 'error')
        return
    end
    exports.ox_inventory:RemoveItem(src, Config.RequiredBrick, Config.RequiredBrickAmount)
    exports.ox_inventory:AddItem(src, Config.RequiredPackage, Config.PackageReward)
    TriggerClientEvent('arkeo-methRun:notify', src, 'Packaging complete. Proceed to drop-off.', 'success')
    TriggerClientEvent('arkeo-methRun:showNextMission', src)
    TriggerClientEvent('arkeo-methRun:showDepositBlip', src)
end)

RegisterNetEvent('arkeo-methRun:deliverMeth', function()
    local src = source
    exports.ox_inventory:AddItem(src, Config.RequiredBrick, Config.Delivery.bricks)
    exports.ox_inventory:AddItem(src, 'money', Config.Delivery.cash)
    if math.random(1, 100) == 1 then
        exports.ox_inventory:AddItem(src, Config.Delivery.methtable, 1)
        TriggerClientEvent('arkeo-methRun:notify', src, 'Rare methtable received!', 'success')
    end
    TriggerClientEvent('arkeo-methRun:notify', src, 'Delivery done.', 'success')
    TriggerClientEvent('arkeo-methRun:endMission', src)

    methRunActive = false
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', 'methRun', false)
    SetTimeout(Config.Cooldown or 5400000, function()
        cooldownActive = false
    end)
end)

lib.callback.register('arkeo-methRun:canStart', function(source)
    if methRunActive or cooldownActive then
        return false, 'A meth run is already active or on cooldown.'
    end
    return true
end)
