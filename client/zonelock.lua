-- Blocks any weapon listed in Config.ZoneOnlyWeapons from firing while the
-- player is outside a hunting zone (Hunting.zone is set/cleared in hunting.lua).
-- Runs independently of Config.AimBlock, which only cares about aiming at players.

local notifyCooldown = 0

CreateThread(function()
    while true do
        local sleep = 500

        if cache.weapon and not Hunting.zone and utils.validWeapon(Config.ZoneOnlyWeapons, cache.weapon) then
            sleep = 0

            DisableControlAction(0, 24, true)  -- Attack 1
            DisableControlAction(0, 257, true) -- Attack 2
            DisablePlayerFiring(cache.ped, true)

            if (IsControlJustPressed(0, 24) or IsControlJustPressed(0, 257) or IsDisabledControlJustPressed(0, 24)) and GetGameTimer() > notifyCooldown then
                notifyCooldown = GetGameTimer() + 4000
                utils.showNotification(locale("weapon_zone_only"))
            end
        end

        Wait(sleep)
    end
end)
