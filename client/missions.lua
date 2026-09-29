local currentMission = nil
local animalBrought = false
local missionVehicle = nil

if Config.HuntMaster.blip.enable then
    Config.HuntMaster.blip.pos = Config.HuntMaster.coords.xyz
    utils.createBlip(Config.HuntMaster.blip)
    utils.debug("Mission Blip Created")
end

local function stopMission()
    if not currentMission then return end

    SendNUIMessage({ action = "hide" })
    currentMission = nil
    animalBrought = false

    for entity, entry in pairs(Hunting.entities) do
        if entry.mission then
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end

            Hunting.entities[entity] = nil
        end
    end

    DeleteEntity(missionVehicle)
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        stopMission()
    end
end)

local function dragAnimal(entity, attach, vehicle, vehicleAttach)
    animalBrought = false
    Hunting.entities[entity] = { entity = entity, mission = true }

    lib.requestAnimDict('combat@drag_ped@')

    SetNewWaypoint(GetEntityCoords(entity))

    local playerPed = cache.ped
    AttachEntityToEntity(entity, playerPed, 11816, attach.pos.x, attach.pos.y, attach.pos.z, attach.rot.x, attach.rot.y, attach.rot.z, false, false, false, true, 2, true)
    TaskPlayAnim(playerPed, 'combat@drag_ped@', 'injured_drag_plyr', 2.0, 2.0, -1, 1, 0, false, false, false)

    if Config.Target == "ox_target" then
        exports.ox_target:addLocalEntity(vehicle, {
            {
                name = "put_animal",
                label = locale('put_animal_vehicle'),
                icon = 'fa-solid fa-knife',
                onSelect = function()
                    AttachEntityToEntity(entity, vehicle, 3, vehicleAttach.pos.x, vehicleAttach.pos.y, vehicleAttach.pos.z, vehicleAttach.rot.x, vehicleAttach.rot.y, vehicleAttach.rot.z, false, false, false, false, 2, true)
                end
            },
        })
    elseif Config.Target == "qb-target" then
        exports['qb-target']:AddTargetEntity(vehicle, {
            options = {
                {
                    num = 1,
                    type = "client",
                    icon = 'fas fa-knife',
                    label = locale('put_animal_vehicle'),
                    action = function()
                        AttachEntityToEntity(entity, vehicle, 3, vehicleAttach.pos.x, vehicleAttach.pos.y, vehicleAttach.pos.z, vehicleAttach.rot.x, vehicleAttach.rot.y, vehicleAttach.rot.z, false, false, false, false, 2, true)
                    end,
                }
            },
            distance = 2.5,
        })
    end

    while not IsEntityAttachedToAnyVehicle(entity) do
        if IsControlPressed(0, 35) then
            FreezeEntityPosition(playerPed, false)
            SetEntityHeading(playerPed, GetEntityHeading(playerPed) + 1.0)
        elseif IsControlPressed(0, 34) then
            FreezeEntityPosition(playerPed, false)
            SetEntityHeading(playerPed, GetEntityHeading(playerPed) - 1.0)
        elseif IsControlPressed(0, 32) or IsControlPressed(0, 33) then
            FreezeEntityPosition(playerPed, false)
        else
            FreezeEntityPosition(playerPed, true)
            TaskPlayAnim(playerPed, 'combat@drag_ped@', 'injured_drag_plyr', 0.0, 0.0, -1, 2, 7, false, false, false)
        end

        if not Config.Target then
            local playerCoords = GetEntityCoords(cache.ped)
            local vehicleCoords = GetEntityCoords(vehicle)
            local dist = #(playerCoords - vehicleCoords)

            if dist <= 3.0 then
                utils.drawText3D(vehicleCoords, locale("put_animal_vehicle"), 1, 0)
                if IsControlJustPressed(0, 38) then
                    AttachEntityToEntity(entity, vehicle, 3, vehicleAttach.pos.x, vehicleAttach.pos.y, vehicleAttach.pos.z, vehicleAttach.rot.x, vehicleAttach.rot.y, vehicleAttach.rot.z, false, false, false, false, 2, true)
                end
            end
        end

        Wait(1)
    end

    FreezeEntityPosition(playerPed, false)
    ClearPedTasksImmediately(playerPed)
    utils.showNotification(locale("take_animal_to_huntmaster"))
    SetNewWaypoint(Config.HuntMaster.vehicleDeposit.x, Config.HuntMaster.vehicleDeposit.y)

    while DoesEntityExist(entity) do
        local sleep = 1500

        local playerCoords = GetEntityCoords(cache.ped)
        local dist = #(playerCoords - Config.HuntMaster.vehicleDeposit)

        if dist <= 10 then
            sleep = 1
            DrawMarker(1, Config.HuntMaster.vehicleDeposit.x, Config.HuntMaster.vehicleDeposit.y, Config.HuntMaster.vehicleDeposit.z - 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.2, 3.0, 1.0, 10, 255, 10, 155, false, true, 2, false, nil, nil, false)

            if dist <= 5 then
                if cache.vehicle == vehicle then
                    if IsControlJustPressed(0, 38) then
                        TaskLeaveVehicle(cache.ped, vehicle, 64)

                        while cache.vehicle do Wait(100) end

                        DeleteEntity(vehicle)
                        Hunting.removeEntity(entity)

                        animalBrought = true
                    end
                end
            end
        end

        Wait(sleep)
    end
    utils.showNotification(locale("talk_to_finish_mission"))
end

local function getMissionRequirementsText(mission)
    if mission.type ~= "item" or not mission.requirements then
        return locale("info_mission_content") .. " " .. (mission.content or "")
    end

    local text = locale("info_mission_item_requirements")
    for _, requirement in ipairs(mission.requirements) do
        text = text .. string.format(" - %s x%s\n", requirement.label or requirement.item, requirement.quantity)
    end
    return text
end

local function getMissionRows(mission)
    if mission.type == "item" and mission.requirements then
        local rows = {}
        for _, requirement in ipairs(mission.requirements) do
            rows[#rows + 1] = { label = requirement.label or requirement.item, amount = "x" .. requirement.quantity }
        end
        return rows
    end

    return { { label = (mission.content or ""):gsub("^%s*%-%s*", "") } }
end

local function startMission(mission)
    local canDoMission = lib.callback.await('Yusi_hunting:canDoMission', false, mission.id, mission.delay)
    if canDoMission ~= true then return utils.showNotification((locale("wait_do_another_mission")):format(canDoMission)) end

    local requiredItemsText = getMissionRequirementsText(mission)
    local alert = lib.alertDialog({
        header = mission.label,
        content = (mission.content or "") .. "  \n  \n" .. requiredItemsText,
        centered = true,
        cancel = true,
        labels = {
            cancel = locale("label_dont_start_mission"),
            confirm = locale("label_start_mission")
        }
    })

    if alert ~= "confirm" then return end
    currentMission = mission

    local data = {
        id = mission.id,
        method = "set",
    }

    TriggerServerEvent("Yusi_hunting:missionTime", data)

    utils.showNotification((locale("mission_started")):format(mission.label))
    PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)

    lib.hideTextUI()

    local vehicleData = mission.vehicle
    if vehicleData.enable then
        missionVehicle = utils.createVehicle(vehicleData.model, Config.HuntMaster.vehicleSpawn, true, false)
        TaskWarpPedIntoVehicle(cache.ped, missionVehicle, -1)
    end

    if mission.type == "animal" then
        local coords = mission.spawns[math.random(1, #mission.spawns)]
        local entity = utils.createPed(mission.animal, coords)

        SetRelationshipBetweenGroups(5, `WILD_ANIMAL`, `PLAYER`)
        SetRelationshipBetweenGroups(5, `PLAYER`, `WILD_ANIMAL`)
        SetPedRelationshipGroupHash(entity, `WILD_ANIMAL`)

        ClearPedTasks(entity)
        TaskWanderInArea(entity, coords.x, coords.y, coords.z, 10.0, 4, 1.0)

        mission.blip.entity = entity
        utils.createEntityBlip(mission.blip)

        CreateThread(function()
            while not IsEntityDead(entity) do
                local sleep = 1500
                local entityCoords = GetEntityCoords(entity)

                local playerCoords = GetEntityCoords(cache.ped)
                local dist = #(playerCoords - entityCoords)

                if dist <= 30.0 then
                    sleep = 0
                    DrawMarker(1, entityCoords.x, entityCoords.y, entityCoords.z - 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 2.0, 1.0, 155, 155, 155, 250, false, true, 2, false, nil, nil, false)
                end
                Wait(sleep)
            end

            utils.showNotification(locale("drag_animal"))

            if not Config.Target then
                while DoesEntityExist(entity) do
                    local sleep = 1500

                    local playerCoords = GetEntityCoords(cache.ped)
                    local entityCoords = GetEntityCoords(entity)
                    local dist = #(playerCoords - entityCoords)

                    if dist <= 3.0 and not cache.vehicle then
                        sleep = 0
                        utils.drawText3D(entityCoords, locale("interact_drag_animal"), 1, 0)

                        if IsControlJustPressed(0, 38) then
                            DeleteEntity(entity)
                            local entity_new = utils.createPed(mission.animal, GetEntityCoords(cache.ped))
                            SetEntityHealth(entity_new, 0)

                            dragAnimal(entity_new, mission.attach, missionVehicle, mission.vehicleAttach)
                            break
                        end
                    end

                    Wait(sleep)
                end
            else
                if Config.Target == "ox_target" then
                    exports.ox_target:addLocalEntity(entity, {
                        {
                            name = "drag_animal",
                            label = locale('interact_drag_animal'),
                            icon = 'fa-solid fa-knife',
                            onSelect = function()
                                DeleteEntity(entity)
                                local entity_new = utils.createPed(mission.animal, GetEntityCoords(cache.ped))
                                SetEntityHealth(entity_new, 0)

                                dragAnimal(entity_new, mission.attach, missionVehicle, mission.vehicleAttach)
                            end
                        },
                    })
                elseif Config.Target == "qb-target" then
                    exports['qb-target']:AddTargetEntity(entity, {
                        options = {
                            {
                                num = 1,
                                type = "client",
                                icon = 'fas fa-knife',
                                label = locale('interact_drag_animal'),
                                action = function()
                                    DeleteEntity(entity)
                                    local entity_new = utils.createPed(mission.animal, GetEntityCoords(cache.ped))
                                    SetEntityHealth(entity_new, 0)

                                    dragAnimal(entity_new, mission.attach, missionVehicle, mission.vehicleAttach)
                                end,
                            }
                        },
                        distance = 2.5,
                    })
                end
            end
        end)
    end

    SendNUIMessage({
        action = "show",
        title = mission.label,
        duration = mission.time * 60,
        rows = getMissionRows(mission),
    })

    local endTime = GetGameTimer() + mission.time * 60000
    while currentMission and GetGameTimer() < endTime do
        Wait(500)
    end

    if currentMission and currentMission.id == mission.id then
        stopMission()
        utils.showNotification(locale("mission_time_finished"))
    end
end

local function openMissions()
    local missions = {}

    if not currentMission then
        for i = 1, #Config.Missions do
            local mission = Config.Missions[i]
            local missionIndex = i
            missions[#missions + 1] = {
                title = mission.label,
                description = getMissionRequirementsText(mission),
                icon = mission.icon,
                image = mission.image,
                arrow = true,
                onSelect = function()
                    startMission(Config.Missions[missionIndex])
                end
            }
        end
    else
        missions[#missions + 1] = {
            title = locale("finish_mission"),
            icon = "fa-solid fa-check",
            onSelect = function()
                if currentMission.type == "item" then
                    local hasItems = lib.callback.await('Yusi_hunting:hasItems', false, currentMission.requirements)
                    if not hasItems then return utils.showNotification(locale("no_items")) end
                elseif currentMission.type == "animal" then
                    if not animalBrought then return utils.showNotification(locale("no_animal_brought")) end
                end

                utils.showNotification((locale("mission_finished")):format(currentMission.label))
                TriggerServerEvent("Yusi_hunting:finishMission", currentMission)

                stopMission()
            end
        }

        missions[#missions + 1] = {
            title = locale("cancel_mission"),
            icon = "fa-solid fa-xmark",
            onSelect = function()
                local alert = lib.alertDialog({
                    header = locale("cancel_mission_header"),
                    content = (locale("cancel_mission_content")):format(currentMission.label),
                    centered = true,
                    cancel = true,
                    labels = {
                        cancel = locale("label_dont_cancel_mission"),
                        confirm = locale("label_cancel_mission")
                    }
                })

                if alert ~= "confirm" then return end

                utils.showNotification((locale("mission_cancelled")):format(currentMission.label))
                stopMission()
            end
        }
    end

    lib.registerContext({
        id = 'hunting_missions',
        title = locale("hunting_missions_menu_title"),
        options = missions
    })
    lib.showContext('hunting_missions')
end

local hunter = lib.points.new({
    coords = Config.HuntMaster.coords.xyz,
    distance = 60,
})

function hunter:onEnter()
    if not self.ped then
        local ped = utils.createPed(Config.HuntMaster.model, Config.HuntMaster.coords)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        if Config.Target then
            if Config.Target == "ox_target" then
                exports.ox_target:addLocalEntity(ped, {
                    {
                        name = "harvest_animal",
                        label = locale("interact_talk_huntmaster"),
                        icon = 'fa-solid fa-knife',
                        onSelect = function(data)
                            openMissions()
                        end
                    },
                })
            elseif Config.Target == "qb-target" then
                exports['qb-target']:AddTargetEntity(ped, {
                    options = {
                        {
                            num = 1,
                            type = "client",
                            icon = 'fas fa-knife',
                            label = locale("interact_talk_huntmaster"),
                            action = function()
                                openMissions()
                            end,
                        }
                    },
                    distance = 2.5,
                })
            end
        end

        self.ped = ped
    end
end

function hunter:onExit()
    if self.ped then
        DeleteEntity(self.ped)
        self.ped = nil
    end
end

if not Config.Target then
    function hunter:nearby()
        if self.currentDistance <= 3 then
            utils.drawText3D(self.coords + vector3(0.0, 0.0, 2.0), locale("interact_talk_huntmaster"), 0.9, 0)
            if IsControlJustReleased(0, 38) then
                openMissions()
            end
        end
    end
end
