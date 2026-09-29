local nextAnimalId = 0
local huntingAnimals = {}
local zonePlayers = {}
local zoneBusy = {}

local function flagCheater(src, detail)
    print(("ARS HUNTING >> PLAYER MIGHT BE CHEATING ID: %s%s"):format(src, detail and (" (" .. detail .. ")") or ""))
end

local function getRarity(items)
    if not items then return end

    local pool, maxChance = {}, 0
    for _, item in pairs(items) do
        pool[#pool + 1] = item
        if item.chance > maxChance then maxChance = item.chance end
    end

    if #pool == 0 then return end
    if maxChance < 1 then return pool[math.random(#pool)] end

    local roll = math.random(1, math.floor(math.min(maxChance, 100)))
    local eligible = {}
    for i = 1, #pool do
        if pool[i].chance >= roll then
            eligible[#eligible + 1] = pool[i]
        end
    end

    return eligible[math.random(#eligible)]
end

local function isInZone(src, zoneName)
    return zonePlayers[zoneName] and zonePlayers[zoneName][src] or false
end

local function animalPayload(id, animal)
    return { id = id, zoneName = animal.zoneName, animalIndex = animal.animalIndex }
end

local function triggerZone(zoneName, event, ...)
    local players = zonePlayers[zoneName]
    if not players then return end

    for src in pairs(players) do
        TriggerClientEvent(event, src, ...)
    end
end

local function countZoneAnimals(zoneName)
    local count = 0
    for _, animal in pairs(huntingAnimals) do
        if animal.zoneName == zoneName then
            count += 1
        end
    end
    return count
end

local function pickAnimalIndex(zoneData)
    for _ = 1, 25 do
        local index = math.random(1, #zoneData.animals)
        if zoneData.animals[index].chance >= math.random(1, 100) then
            return index
        end
    end
    return 1
end

local function despawnAnimal(id)
    local animal = huntingAnimals[id]
    if not animal then return end

    huntingAnimals[id] = nil

    if animal.entity and DoesEntityExist(animal.entity) then
        DeleteEntity(animal.entity)
    end

    triggerZone(animal.zoneName, "Yusi_hunting:animalDespawned", id)
end

local function getRandomZonePlayer(zoneName)
    local players = zonePlayers[zoneName]
    if not players then return end

    local list = {}
    for src in pairs(players) do
        list[#list + 1] = src
    end

    if #list == 0 then return end

    return list[math.random(#list)]
end

local function leaveZone(src, zoneName)
    local players = zonePlayers[zoneName]
    if not players then return end

    players[src] = nil
    if next(players) then return end

    zonePlayers[zoneName] = nil
    for id, animal in pairs(huntingAnimals) do
        if animal.zoneName == zoneName then
            despawnAnimal(id)
        end
    end
end

local function giveRandomItem(src, item)
    if not item then return end

    framework.addItems({
        target = src,
        items = { { item = item.item, quantity = math.random(1, item.maxQuantity) } }
    })
end

RegisterNetEvent("Yusi_hunting:enterZone", function(zoneName)
    local src = source
    if not Config.HuntingZones[zoneName] then return end

    zonePlayers[zoneName] = zonePlayers[zoneName] or {}
    zonePlayers[zoneName][src] = true

    local list = {}
    for id, animal in pairs(huntingAnimals) do
        if animal.zoneName == zoneName and animal.netId then
            list[#list + 1] = { netId = animal.netId, data = animalPayload(id, animal) }
        end
    end

    TriggerClientEvent("Yusi_hunting:syncAnimals", src, list)
end)

RegisterNetEvent("Yusi_hunting:leaveZone", function(zoneName)
    leaveZone(source, zoneName)
end)

AddEventHandler("playerDropped", function()
    local src = source
    for zoneName in pairs(zonePlayers) do
        leaveZone(src, zoneName)
    end
end)

RegisterNetEvent("Yusi_hunting:createAnimal", function(zoneName, coords)
    local src = source
    local zoneData = Config.HuntingZones[zoneName]
    if not zoneData or not coords then return end
    if not isInZone(src, zoneName) or zoneBusy[zoneName] then return end
    if countZoneAnimals(zoneName) >= zoneData.maxSpawns then return end
    if #(vector3(coords.x, coords.y, coords.z) - zoneData.coords) > zoneData.radius then return end

    zoneBusy[zoneName] = true

    local animalIndex = pickAnimalIndex(zoneData)
    local model = joaat(zoneData.animals[animalIndex].model)

    nextAnimalId += 1
    local id = nextAnimalId

    local ped = CreatePed(5, model, coords.x, coords.y, coords.z, 0.0, true, true)

    local timeout = GetGameTimer() + 5000
    while ped and ped ~= 0 and not DoesEntityExist(ped) and GetGameTimer() < timeout do
        Wait(0)
    end

    local animal = { zoneName = zoneName, animalIndex = animalIndex, spawnedAt = os.time() }
    huntingAnimals[id] = animal

    if not ped or ped == 0 or not DoesEntityExist(ped) then
        local payload = animalPayload(id, animal)
        payload.coords = coords

        TriggerClientEvent("Yusi_hunting:spawnAnimalLocal", src, payload)
        zoneBusy[zoneName] = nil
        return
    end

    animal.entity = ped
    animal.netId = NetworkGetNetworkIdFromEntity(ped)

    local payload = animalPayload(id, animal)
    Entity(ped).state:set("huntingAnimal", payload, true)
    triggerZone(zoneName, "Yusi_hunting:animalSpawned", animal.netId, payload)

    zoneBusy[zoneName] = nil
end)

RegisterNetEvent("Yusi_hunting:registerSpawnedAnimal", function(id, netId)
    local animal = huntingAnimals[id]
    if not animal or not netId then return end
    if not isInZone(source, animal.zoneName) then return end

    animal.netId = netId

    local payload = animalPayload(id, animal)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 then
        animal.entity = entity
        Entity(entity).state:set("huntingAnimal", payload, true)
    end

    triggerZone(animal.zoneName, "Yusi_hunting:animalSpawned", netId, payload)
end)

RegisterNetEvent("Yusi_hunting:despawnAnimal", function(id)
    local animal = huntingAnimals[id]
    if not animal or not isInZone(source, animal.zoneName) then return end

    despawnAnimal(id)
end)

CreateThread(function()
    while true do
        Wait((Config.SpawnDelay or 5) * 1000)

        for zoneName, players in pairs(zonePlayers) do
            local zoneData = Config.HuntingZones[zoneName]
            local canSpawn = zoneData and next(players) and not zoneBusy[zoneName]
                and countZoneAnimals(zoneName) < zoneData.maxSpawns

            if canSpawn then
                local picker = getRandomZonePlayer(zoneName)
                if picker then
                    TriggerClientEvent("Yusi_hunting:requestSpawnPoint", picker, zoneName)
                end
            end
        end
    end
end)

local function anyoneNear(zoneName, coords)
    local players = zonePlayers[zoneName]
    if not players then return false end

    for src in pairs(players) do
        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 and #(GetEntityCoords(ped) - coords) <= Config.DeleteEntityRadius then
            return true
        end
    end

    return false
end

local function checkAnimal(id, animal)
    if animal.harvestUntil and os.time() < animal.harvestUntil then return end

    local zoneData = Config.HuntingZones[animal.zoneName]
    if not zoneData then return despawnAnimal(id) end

    if not animal.entity or not DoesEntityExist(animal.entity) then
        local streamed = animal.netId and NetworkGetEntityFromNetworkId(animal.netId)

        if streamed and streamed ~= 0 and DoesEntityExist(streamed) then
            animal.entity = streamed
        elseif not animal.spawnedAt or os.time() - animal.spawnedAt >= Config.SpawnGraceTime then
            despawnAnimal(id)
        end

        return
    end

    local coords = GetEntityCoords(animal.entity)
    if #(coords - zoneData.coords) > zoneData.radius or not anyoneNear(animal.zoneName, coords) then
        despawnAnimal(id)
    end
end

CreateThread(function()
    while true do
        Wait(Config.CleanupInterval * 1000)

        for id, animal in pairs(huntingAnimals) do
            checkAnimal(id, animal)
        end
    end
end)

RegisterNetEvent("Yusi_hunting:harvestStart", function(id)
    local animal = huntingAnimals[id]
    if not animal or not isInZone(source, animal.zoneName) then return end

    animal.harvestUntil = os.time() + Config.HarvestLockTime
end)

RegisterNetEvent("Yusi_hunting:harvestAnimal", function(id)
    local src = source
    local animal = huntingAnimals[id]

    if not animal or not isInZone(src, animal.zoneName) then
        return TriggerClientEvent("Yusi_hunting:harvestFailed", src)
    end

    local maxDist = Config.HarvestMaxDistance or 0
    if maxDist > 0 and animal.entity and DoesEntityExist(animal.entity) then
        local dist = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(animal.entity))
        if dist > maxDist then
            flagCheater(src, "harvest distance " .. math.floor(dist))
            return TriggerClientEvent("Yusi_hunting:harvestFailed", src)
        end
    end

    local items = Config.HuntingZones[animal.zoneName].animals[animal.animalIndex].items
    despawnAnimal(id)

    giveRandomItem(src, getRarity(items.skins))
    giveRandomItem(src, getRarity(items.meat))

    if math.random() <= Config.ExtraItemChance then
        giveRandomItem(src, getRarity(items.extra))
    end

    TriggerEvent("xp:addHuntingXP", src, Config.HuntingXPPerHarvest)
end)

RegisterNetEvent("Yusi_hunting:cookItem", function(data)
    local src = source

    for _, item in pairs(data.required) do
        framework.removeItem({ target = src, item = item.item, count = item.quantity })
    end

    framework.addItems({ target = src, items = data.give })
end)

RegisterNetEvent("Yusi_hunting:takeCampfire", function(data)
    local src = source

    if #(GetEntityCoords(GetPlayerPed(src)) - data.coords) > 4.0 then
        return flagCheater(src, "campfire distance")
    end

    framework.addItems({ target = src, items = Config.Campfire.campfireItem })
end)

RegisterNetEvent("Yusi_hunting:sellBuyItem", function(data)
    local src = source
    local stack = { { item = data.item, quantity = data.quantity } }

    if data.buy then
        if framework.hasMoney(src) < data.price then
            return TriggerClientEvent("Yusi_hunting:showNotification", src, locale("not_enough_money"))
        end

        framework.removeMoney({ target = src, amount = data.price })
        framework.addItems({ target = src, items = stack })
        return
    end

    if not framework.hasItems({ target = src, items = stack }) then
        return TriggerClientEvent("Yusi_hunting:showNotification", src, locale("not_enough_item"))
    end

    framework.removeItem({ target = src, item = data.item, count = data.quantity })
    framework.addMoney({ target = src, amount = data.price })
end)

local function grantReward(src, reward)
    if reward.item == "money" then
        framework.addMoney({ target = src, amount = reward.quantity or 0 })
    else
        framework.addItems({ target = src, items = { { item = reward.item, quantity = reward.quantity or 1 } } })
    end
end

RegisterNetEvent("Yusi_hunting:finishMission", function(data)
    local src = source

    if #(GetEntityCoords(GetPlayerPed(src)) - Config.HuntMaster.coords.xyz) > 3.0 then
        return flagCheater(src, "mission distance")
    end

    for _, reward in pairs(data.rewards or {}) do
        grantReward(src, reward)
    end

    if data.rewardPool and #data.rewardPool > 0 then
        local picked = getRarity(data.rewardPool)
        if picked then grantReward(src, picked) end
    end

    for _, item in pairs(data.requirements or {}) do
        framework.removeItem({ target = src, item = item.item, count = item.quantity })
    end

    TriggerEvent("xp:addHuntingXP", src, Config.HuntingXPPerMission)
end)

local function missionKey(src, id)
    return id .. "_" .. GetPlayerIdentifierByType(src, "license")
end

RegisterNetEvent("Yusi_hunting:missionTime", function(data)
    if data.method == "set" then
        SetResourceKvp(missionKey(source, data.id), tostring(os.time()))
    end
end)

lib.callback.register("Yusi_hunting:canDoMission", function(src, id, delay)
    local startedAt = tonumber(GetResourceKvpString(missionKey(src, id))) or 0
    local cooldown = delay * 60
    local elapsed = os.time() - startedAt

    if elapsed >= cooldown then return true end

    return cooldown - elapsed
end)

lib.callback.register("Yusi_hunting:hasItems", function(src, items)
    return framework.hasItems({ target = src, items = items })
end)
