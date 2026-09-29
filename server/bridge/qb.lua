local QBCore = GetResourceState('qb-core'):find('start') and exports['qb-core']:GetCoreObject() or nil

if not QBCore then return end

framework = {}

function framework.addItems(data)
    local xPlayer = QBCore.Functions.GetPlayer(data.target)

    if type(data.items) == "table" then
        for _, item in pairs(data.items) do
            xPlayer.Functions.AddItem(item.item, (item?.quantity or 1))
        end
    else
        xPlayer.Functions.AddItem(data.items, 1)
    end
end

function framework.hasMoney(target)
    local xPlayer = QBCore.Functions.GetPlayer(target)
    return xPlayer.PlayerData.money.cash
end

function framework.addMoney(data)
    local xPlayer = QBCore.Functions.GetPlayer(data.target)
    xPlayer.Functions.AddMoney('bank', data.amount)
end

function framework.removeMoney(data)
    local xPlayer = QBCore.Functions.GetPlayer(data.target)
    xPlayer.Functions.RemoveMoney('bank', data.amount)
end

function framework.hasItems(data)
    local xPlayer = QBCore.Functions.GetPlayer(data.target)

    local function itemCount(item)
        if not item then return 0 end
        return item.amount or item.count or 0
    end

    if type(data.items) == "table" then
        for _, item in pairs(data.items) do
            local hasItem = xPlayer.Functions.GetItemByName(item.item)
            if itemCount(hasItem) < (item.quantity or 1) then
                return false
            end
        end
        return true
    end

    return itemCount(xPlayer.Functions.GetItemByName(data.items)) > 0
end

function framework.removeItem(data)
    local xPlayer = QBCore.Functions.GetPlayer(data.target)
    xPlayer.Functions.RemoveItem(data.item, data.count)
end

QBCore.Functions.CreateUseableItem(Config.TrackerItem, function(source, item)
    TriggerClientEvent("Yusi_hunting:trackAnimal", source)
end)

QBCore.Functions.CreateUseableItem(Config.BaitItem, function(source)
    framework.removeItem({ target = source, item = Config.BaitItem, count = 1 })
    TriggerClientEvent("Yusi_hunting:placeBait", source)
end)

if Config.Campfire.enable then
    QBCore.Functions.CreateUseableItem(Config.Campfire.campfireItem, function(source, item)
        framework.removeItem({ target = source, item = Config.Campfire.campfireItem, count = 1 })
        TriggerClientEvent("Yusi_hunting:useCampfire", source)
    end)
end
