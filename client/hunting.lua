Hunting = {
    zone = nil,
    zoneName = nil,
    entities = {},
}

local entities = Hunting.entities
local harvesting = false
local canTrack = true
local harvestModels = {}
local registeredAnimals = {}

local NET_ENTITY_TIMEOUT = 8000
local WANDER_TIMEOUT = 10000

for _, zoneData in pairs(Config.HuntingZones) do
    for _, animal in pairs(zoneData.animals) do
        harvestModels[joaat(animal.model)] = true
    end
end

local function disableWeapon()
    while not cache.weapon do Wait(1) end

    while cache.weapon do
        DisableControlAction(0, 24, true)  -- Attack 1
        DisableControlAction(0, 257, true) -- Attack 2
        DisableControlAction(0, 25, true)  -- Aim

        Wait(1)
    end
end

lib.onCache('weapon', function(weapon)
    if not weapon then return end

    local zone = Hunting.zone

    if not zone and utils.validWeapon(Config.ZoneOnlyWeapons, weapon) then
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        utils.showNotification(locale("weapon_zone_only"))
        return
    end

    local aim = Config.AimBlock
    if aim.enable and (aim.global or zone) and utils.validWeapon(aim.weaponsToBlock, weapon) then
        Hunting.aimBlock(aim.global)
    end

    if zone and zone.allowedWeapons and not utils.validWeapon(zone.allowedWeapons, weapon) then
        lib.alertDialog({
            header = locale("weapon_not_allowed_title"),
            content = locale("weapon_not_allowed_content"),
            centered = true,
            cancel = false
        })

        disableWeapon()
    end
end)

local function initCam(entity)
    FreezeEntityPosition(cache.ped, true)
    ClearFocus()

    local playerCoords = cache.coords
    local entityCoords = GetEntityCoords(entity)

    local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", playerCoords, 0, 0, 0, GetGameplayCamFov())
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, false)

    SetCamCoord(cam, entityCoords.x, entityCoords.y + 2, entityCoords.z + 3.0)
    PointCamAtCoord(cam, playerCoords.x, playerCoords.y, playerCoords.z)

    return cam
end

local function stopCam(cam)
    ClearFocus()
    RenderScriptCams(false, true, 500, true, false)
    DestroyCam(cam, false)
    FreezeEntityPosition(cache.ped, false)
end

local function getAnimalConfig(entity)
    if not DoesEntityExist(entity) then return end

    local state = Entity(entity).state.huntingAnimal
    if not (state and state.id and state.zoneName and state.animalIndex) then return end

    local zone = Config.HuntingZones[state.zoneName]
    local animal = zone and zone.animals[state.animalIndex]

    return animal, state.id
end

local function canHarvest(entity)
    return Hunting.zone and not harvesting
        and DoesEntityExist(entity) and IsEntityDead(entity) and not IsPedAPlayer(entity)
        and getAnimalConfig(entity) ~= nil
end

local function dropEntry(entity)
    local entry = entities[entity]
    if not entry then return end

    utils.removeBlip(entry.blip)
    if entry.huntingId then
        registeredAnimals[entry.huntingId] = nil
    end

    entities[entity] = nil
end

local function removeEntity(entity)
    local state = DoesEntityExist(entity) and Entity(entity).state.huntingAnimal
    dropEntry(entity)

    if state and state.id then
        registeredAnimals[state.id] = nil
        TriggerServerEvent("Yusi_hunting:despawnAnimal", state.id)
        return
    end

    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

Hunting.removeEntity = removeEntity

local function clearZoneAnimals()
    for entity, entry in pairs(entities) do
        if entry.huntingId then
            dropEntry(entity)
        end
    end
end

local function waitForNetEntity(netId)
    local timeout = GetGameTimer() + NET_ENTITY_TIMEOUT

    while GetGameTimer() < timeout do
        if NetworkDoesNetworkIdExist(netId) then
            local entity = NetworkGetEntityFromNetworkId(netId)
            if entity and entity ~= 0 and DoesEntityExist(entity) then
                return entity
            end
        end

        Wait(50)
    end
end

local function drawAnimalMarker(entity, marker, zoneName)
    while DoesEntityExist(entity) and not IsEntityDead(entity) and Hunting.zoneName == zoneName do
        local sleep = 1500
        local entityCoords = GetEntityCoords(entity)
        local dist = #(cache.coords - entityCoords)
        local tracked = Config.Debug or entities[entity]?.track

        if dist <= (tracked and Config.TrackedMarkerDistance or Config.MarkerDistance) then
            sleep = 0
            DrawMarker(
                tracked and 1 or 23,
                entityCoords.x, entityCoords.y, entityCoords.z - 1,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                1.2, 2.0, tracked and 100.0 or 1.0,
                marker.color.r, marker.color.g, marker.color.b, tracked and 155 or marker.color.a,
                false, true, 2, false, nil, nil, false
            )
        end

        Wait(sleep)
    end
end

local function registerHuntingAnimal(entity, data)
    if not entity or entity == 0 or not DoesEntityExist(entity) or not data or not data.id then return end
    if registeredAnimals[data.id] then return end
    if not Hunting.zoneName or Hunting.zoneName ~= data.zoneName then return end

    local zone = Config.HuntingZones[data.zoneName]
    local animal = zone and zone.animals[data.animalIndex]
    if not animal then return end

    registeredAnimals[data.id] = entity

    SetEntityAsMissionEntity(entity, true, true)
    SetPedRelationshipGroupHash(entity, `WILD_ANIMAL`)
    SetRelationshipBetweenGroups(5, `WILD_ANIMAL`, `PLAYER`)
    SetRelationshipBetweenGroups(5, `PLAYER`, `WILD_ANIMAL`)

    CreateThread(function()
        local timeout = GetGameTimer() + WANDER_TIMEOUT

        while DoesEntityExist(entity) and not IsEntityDead(entity) and GetGameTimer() < timeout do
            if NetworkGetEntityOwner(entity) == cache.playerId then
                TaskWanderStandard(entity)
                break
            end

            Wait(500)
        end
    end)

    animal.blip.entity = entity
    local blip = animal.blip.enable and utils.createEntityBlip(animal.blip) or nil

    entities[entity] = { entity = entity, blip = blip, huntingId = data.id }
    utils.debug("entity registered: ", entity, data.id)

    local marker = animal.marker
    if marker and marker.enable then
        CreateThread(function()
            drawAnimalMarker(entity, marker, data.zoneName)
        end)
    end
end

RegisterNetEvent("Yusi_hunting:animalSpawned", function(netId, data)
    CreateThread(function()
        local entity = waitForNetEntity(netId)
        if entity then
            registerHuntingAnimal(entity, data)
        end
    end)
end)

RegisterNetEvent("Yusi_hunting:syncAnimals", function(list)
    for i = 1, #list do
        local entry = list[i]

        CreateThread(function()
            local entity = waitForNetEntity(entry.netId)
            if entity then
                registerHuntingAnimal(entity, entry.data)
            end
        end)
    end
end)

RegisterNetEvent("Yusi_hunting:animalDespawned", function(id)
    local entity = registeredAnimals[id]
    if entity then
        dropEntry(entity)
    end

    registeredAnimals[id] = nil
end)

RegisterNetEvent("Yusi_hunting:harvestFailed", function()
    utils.showNotification(locale("harvest_failed"))
end)

RegisterNetEvent("Yusi_hunting:requestSpawnPoint", function(zoneName)
    if Hunting.zoneName ~= zoneName or not Hunting.zone then return end

    local coords = utils.getSpawnPoint(Hunting.zone.coords, Hunting.zone.radius)
    TriggerServerEvent("Yusi_hunting:createAnimal", zoneName, coords)
end)

RegisterNetEvent("Yusi_hunting:spawnAnimalLocal", function(data)
    if not data or not Hunting.zone then return end

    local zone = Config.HuntingZones[data.zoneName]
    local animal = zone and zone.animals[data.animalIndex]
    if not animal then return end

    local entity = utils.createPed(animal.model, data.coords, 0.0, true, true)
    if not entity or entity == 0 then
        TriggerServerEvent("Yusi_hunting:despawnAnimal", data.id)
        return
    end

    SetEntityAsMissionEntity(entity, true, true)

    local netId = NetworkGetNetworkIdFromEntity(entity)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)

    Entity(entity).state:set("huntingAnimal", {
        id = data.id,
        zoneName = data.zoneName,
        animalIndex = data.animalIndex,
    }, true)

    registerHuntingAnimal(entity, data)
    TriggerServerEvent("Yusi_hunting:registerSpawnedAnimal", data.id, netId)
end)

AddStateBagChangeHandler("huntingAnimal", nil, function(bagName, _, value)
    if not value then return end

    local entity = GetEntityFromStateBagName(bagName)
    if not entity or entity == 0 then return end

    registerHuntingAnimal(entity, value)
end)

local function harvestAnimal(animal, entity, id)
    if harvesting or not DoesEntityExist(entity) then return end

    if animal.harvestWeapons and not utils.validWeapon(animal.harvestWeapons, cache.weapon) then
        return utils.showNotification(locale("invalid_harvesting_weapon"))
    end

    harvesting = true
    TriggerServerEvent("Yusi_hunting:harvestStart", id)

    local cam = initCam(entity)
    FreezeEntityPosition(entity, true)

    lib.progressBar({
        duration = animal.harvestTime * 1000,
        label = locale("harvesting_animal"),
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true },
        anim = {
            dict = 'anim@gangops@facility@servers@bodysearch@',
            clip = 'player_search',
            flag = 1,
        },
    })

    local skinned = lib.skillCheck(Config.SkinningSkillCheck.difficulty, Config.SkinningSkillCheck.keys)

    stopCam(cam)
    ClearPedTasks(cache.ped)

    if not skinned then
        FreezeEntityPosition(entity, false)
        harvesting = false
        return utils.showNotification(locale("failed_skinning_animal"))
    end

    TriggerServerEvent("Yusi_hunting:harvestAnimal", id)
    dropEntry(entity)

    harvesting = false
end

local function tryHarvestEntity(entity)
    local animal, id = getAnimalConfig(entity)
    if not animal then return end

    harvestAnimal(animal, entity, id)
end

if Config.Target == "ox_target" then
    local models = {}
    for model in pairs(harvestModels) do
        models[#models + 1] = model
    end

    exports.ox_target:addModel(models, {
        {
            name = "harvest_animal",
            label = locale('interact_haverest_animal'),
            icon = 'fa-solid fa-knife',
            distance = 2.5,
            canInteract = canHarvest,
            onSelect = function(data)
                tryHarvestEntity(data.entity)
            end
        },
    })
elseif Config.Target == "qb-target" then
    for model in pairs(harvestModels) do
        exports['qb-target']:AddTargetModel(model, {
            options = {
                {
                    num = 1,
                    type = "client",
                    icon = 'fas fa-knife',
                    label = locale('interact_haverest_animal'),
                    canInteract = canHarvest,
                    action = tryHarvestEntity,
                }
            },
            distance = 2.5,
        })
    end
else
    CreateThread(function()
        while true do
            local sleep = 1000

            if Hunting.zone and not harvesting then
                local peds = GetGamePool('CPed')

                for i = 1, #peds do
                    local ped = peds[i]

                    if ped ~= cache.ped and IsEntityDead(ped) and canHarvest(ped) then
                        local pedCoords = GetEntityCoords(ped)

                        if #(cache.coords - pedCoords) <= 3.0 then
                            sleep = 0
                            utils.drawText3D(pedCoords, locale("interact_haverest_animal"), 1, 0)

                            if IsControlJustPressed(0, 38) then
                                tryHarvestEntity(ped)
                            end
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

for zoneName, zoneData in pairs(Config.HuntingZones) do
    local zone = lib.zones.sphere({
        name = zoneName,
        coords = zoneData.coords,
        radius = zoneData.radius,
        debug = Config.Debug
    })

    if zoneData.zone_radius.enable then
        utils.createZoneBlip({
            coords = zoneData.coords,
            radius = zoneData.radius,
            color = zoneData.zone_radius.color,
            alpha = zoneData.zone_radius.opacity,
        })
    end

    if zoneData.blip.enable then
        zoneData.blip.pos = zoneData.coords
        utils.createBlip(zoneData.blip)
    end

    function zone:onEnter()
        Hunting.zone = zoneData
        Hunting.zoneName = zoneName
        SetForcePedFootstepsTracks(true)
        TriggerServerEvent("Yusi_hunting:enterZone", zoneName)
    end

    function zone:onExit()
        SetForcePedFootstepsTracks(false)
        TriggerServerEvent("Yusi_hunting:leaveZone", zoneName)
        clearZoneAnimals()

        Hunting.zone = nil
        Hunting.zoneName = nil

        if cache.weapon and utils.validWeapon(Config.ZoneOnlyWeapons, cache.weapon) then
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
            utils.showNotification(locale("weapon_zone_only"))
        end
    end
end

local function trackAnimal()
    if not canTrack then return utils.showNotification(locale("wait_for_another_track")) end

    local closest, closestDist = nil, math.huge

    for _, entry in pairs(entities) do
        if entry.track then return utils.showNotification(locale("already_tracking")) end

        local dist = #(GetEntityCoords(entry.entity) - cache.coords)
        if dist < closestDist then
            closest, closestDist = entry, dist
        end
    end

    if not closest then return end

    local finished = lib.progressCircle({
        label = locale("tracking_animal"),
        duration = math.random(3500, 10000),
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, sprint = true },
        anim = {
            dict = 'cellphone@',
            clip = 'cellphone_text_read_base'
        },
        prop = {
            model = `prop_prologue_phone`,
            pos = vec3(0.0, 0.0, 0.0),
            rot = vec3(0.0, 0.0, 0.0),
            bone = 28422
        },
    })

    if not finished then return end

    if Config.TrackingFailureChance > math.random(1, 100) then
        return utils.showNotification(locale("could_not_track_animal"))
    end

    closest.track = true
    canTrack = false

    CreateThread(function()
        while not canTrack do
            DisplayRadar(true)
            Wait(1)
        end
    end)

    TaskTurnPedToFaceEntity(cache.ped, closest.entity, 1000)
    ForcePedMotionState(cache.ped, 1110276645, 0, 0, 0)

    SetTimeout(Config.DelayBetweenTracks * 1000, function()
        canTrack = true
        closest.track = nil
    end)

    SetTimeout(Config.TrackingDuration * 1000, function()
        DisplayRadar(false)
        canTrack = true
        closest.track = nil
    end)

    utils.showNotification(locale("animal_tracked"))
end

RegisterNetEvent("Yusi_hunting:trackAnimal", trackAnimal)

local function placeBait()
    lib.requestAnimDict("pickup_object")
    lib.requestModel("v_res_mpotpouri")

    local target = nil
    local notifSent = false

    TaskPlayAnim(cache.ped, "pickup_object", "pickup_low", 8.0, 8.0, 1000, 50, 0, false, false, false)
    Wait(1000)

    local coords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 0.5, 0)
    local prop = CreateObject("v_res_mpotpouri", coords.x, coords.y, coords.z, true, false, true)
    PlaceObjectOnGroundProperly(prop)

    CreateThread(function()
        while DoesEntityExist(prop) do
            local sleep = 3000

            if #(cache.coords - coords) <= 55 then
                sleep = 1
                DrawMarker(2, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.4, 0.4, 0.4, 245, 147, 66, 150, true, false, 2, false, nil, nil, false)
                utils.drawText3D(vector3(coords.x, coords.y, coords.z - 0.5), "~o~ Bait", 1, 0)
            end

            if target then
                local dist = #(GetEntityCoords(target.entity) - coords)

                if dist <= 20.0 then
                    if not notifSent then
                        notifSent = true
                        utils.showNotification(locale("animal_near_bait"))
                    end

                    if dist <= 2.0 then
                        notifSent = false
                        DeleteEntity(prop)
                        TaskWanderStandard(target.entity)
                        utils.showNotification(locale("animal_ate_bait"))
                        break
                    end
                end
            end

            Wait(sleep)
        end
    end)

    for _, entry in pairs(entities) do
        local entityCoords = GetEntityCoords(entry.entity)
        local dist = #(entityCoords - coords)

        if dist <= Config.BaitAttractionDistance then
            utils.debug("found", dist, entityCoords)

            target = entry
            ClearPedTasks(entry.entity)
            TaskWanderInArea(entry.entity, coords.x, coords.y, coords.z, 1.0, 4, 1.0)

            SetTimeout(Config.BaitTimeLimit * 60000, function()
                notifSent = false
                DeleteEntity(prop)
                TaskWanderStandard(entry.entity)
                utils.showNotification(locale("bait_despawned"))
            end)

            break
        end
    end
end

RegisterNetEvent("Yusi_hunting:placeBait", placeBait)

local function deleteAllEntities()
    for _, entry in pairs(entities) do
        if DoesEntityExist(entry.entity) then
            DeleteEntity(entry.entity)
        end
    end
end

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    deleteAllEntities()
    lib.hideTextUI()
end)
