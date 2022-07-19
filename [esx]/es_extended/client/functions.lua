ESX = {}
Core = {}
ESX.PlayerData = {}
ESX.PlayerLoaded = false
Core.CurrentRequestId = 0
Core.ServerCallbacks = {}
Core.TimeoutCallbacks = {}
ESX.Input = {}
ESX.UI = {}
ESX.UI.HUD = {}
ESX.UI.HUD.RegisteredElements = {}
ESX.UI.Menu = {}
ESX.UI.Menu.RegisteredTypes = {}
ESX.UI.Menu.Opened = {}

ESX.Game = {}
ESX.Game.Utils = {}

ESX.Scaleform = {}
ESX.Scaleform.Utils = {}

ESX.Streaming = {}

function ESX.SetTimeout(msec, cb)
    table.insert(Core.TimeoutCallbacks, {
        time = GetGameTimer() + msec,
        cb = cb
    })
    return #Core.TimeoutCallbacks
end

function ESX.ClearTimeout(i)
    Core.TimeoutCallbacks[i] = nil
end

function ESX.IsPlayerLoaded()
    return ESX.PlayerLoaded
end

function ESX.GetPlayerData()
    return ESX.PlayerData
end

function ESX.SearchInventory(items, count)
    if type(items) == 'string' then
        items = {items}
    end

    local returnData = {}
    local itemCount = #items

    for i = 1, itemCount do
        local itemName = items[i]
        returnData[itemName] = count and 0

        for _, item in pairs(ESX.PlayerData.inventory) do
            if item.name == itemName then
                if count then
                    returnData[itemName] = returnData[itemName] + item.count
                else
                    returnData[itemName] = item
                end
            end
        end
    end

    if next(returnData) then
        return itemCount == 1 and returnData[items[1]] or returnData
    end
end

function ESX.SetPlayerData(key, val)
    local current = ESX.PlayerData[key]
    ESX.PlayerData[key] = val
    if key ~= 'inventory' and key ~= 'loadout' then
        if type(val) == 'table' or val ~= current then
            TriggerEvent('esx:setPlayerData', key, val, current)
        end
    end
end

function ESX.Progressbar(message, length, Options)
    exports["esx_progressbar"]:Progressbar(message, length, Options)
end

function ESX.ShowNotification(message, type, length)
    if Config.NativeNotify then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(0, 1)
    else
        exports["esx_notify"]:Notify(type, length, message)
    end
end

function ESX.TextUI(message, type)
    exports["esx_textui"]:TextUI(message, type)
end

function ESX.HideUI()
    exports["esx_textui"]:HideUI()
end

function ESX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    if saveToBrief == nil then
        saveToBrief = true
    end
    AddTextEntry('esxAdvancedNotification', msg)
    BeginTextCommandThefeedPost('esxAdvancedNotification')
    if hudColorIndex then
        ThefeedSetNextPostBackgroundColor(hudColorIndex)
    end
    EndTextCommandThefeedPostMessagetext(textureDict, textureDict, false, iconType, sender, subject)
    EndTextCommandThefeedPostTicker(flash or false, saveToBrief)
end

function ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
    AddTextEntry('esxHelpNotification', msg)

    if thisFrame then
        DisplayHelpTextThisFrame('esxHelpNotification', false)
    else
        if beep == nil then
            beep = true
        end
        BeginTextCommandDisplayHelp('esxHelpNotification')
        EndTextCommandDisplayHelp(0, false, beep, duration or -1)
    end
end

function ESX.ShowFloatingHelpNotification(msg, coords)
    AddTextEntry('esxFloatingHelpNotification', msg)
    SetFloatingHelpTextWorldPosition(1, coords)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp('esxFloatingHelpNotification')
    EndTextCommandDisplayHelp(2, false, false, -1)
end

ESX.HashString = function(str)
    local format = string.format
    local upper = string.upper
    local gsub = string.gsub
    local hash = GetHashKey(str)
    local input_map = format("~INPUT_%s~", upper(format("%x", hash)))
    input_map = string.gsub(input_map, "FFFFFFFF", "")

    return input_map
end

if GetResourceState("esx_context") ~= "missing" then

    function ESX.OpenContext(...)
        exports["esx_context"]:Open(...)
    end

    function ESX.PreviewContext(...)
        exports["esx_context"]:Preview(...)
    end

    function ESX.CloseContext(...)
        exports["esx_context"]:Close(...)
    end
else 
    function ESX.OpenContext()
        print("[ERROR] ESX Context Not Found")
    end

    function ESX.PreviewContext()
        print("[ERROR] ESX Context Not Found")
    end

    function ESX.CloseContext()
        print("[ERROR] ESX Context Not Found")
    end
end


ESX.RegisterInput = function(command_name, label, input_group, key, on_press, on_release)
    RegisterCommand(on_release ~= nil and "+" .. command_name or command_name, on_press)
    ESX.Input[command_name] = on_release ~= nil and ESX.HashString("+" .. command_name) or ESX.HashString(command_name)
    if on_release then
        RegisterCommand("-" .. command_name, on_release)
    end
    RegisterKeyMapping(on_release ~= nil and "+" .. command_name or command_name, label, input_group, key)
end

function ESX.TriggerServerCallback(name, cb, ...)
    Core.ServerCallbacks[Core.CurrentRequestId] = cb

    TriggerServerEvent('esx:triggerServerCallback', name, Core.CurrentRequestId, ...)

    if Core.CurrentRequestId < 65535 then
        Core.CurrentRequestId = Core.CurrentRequestId + 1
    else
        Core.CurrentRequestId = 0
    end
end

function ESX.UI.HUD.SetDisplay(opacity)
    SendNUIMessage({
        action = 'setHUDDisplay',
        opacity = opacity
    })
end

function ESX.UI.HUD.RegisterElement(name, index, priority, html, data)
    local found = false

    for i = 1, #ESX.UI.HUD.RegisteredElements, 1 do
        if ESX.UI.HUD.RegisteredElements[i] == name then
            found = true
            break
        end
    end

    if found then
        return
    end

    ESX.UI.HUD.RegisteredElements[#ESX.UI.HUD.RegisteredElements + 1] = name

    SendNUIMessage({
        action = 'insertHUDElement',
        name = name,
        index = index,
        priority = priority,
        html = html,
        data = data
    })

    ESX.UI.HUD.UpdateElement(name, data)
end

function ESX.UI.HUD.RemoveElement(name)
    for i = 1, #ESX.UI.HUD.RegisteredElements, 1 do
        if ESX.UI.HUD.RegisteredElements[i] == name then
            table.remove(ESX.UI.HUD.RegisteredElements, i)
            break
        end
    end

    SendNUIMessage({
        action = 'deleteHUDElement',
        name = name
    })
end

function ESX.UI.HUD.Reset()
    SendNUIMessage({
        action = 'resetHUDElements'
    })
    ESX.UI.HUD.RegisteredElements = {}
end

function ESX.UI.HUD.UpdateElement(name, data)
    SendNUIMessage({
        action = 'updateHUDElement',
        name = name,
        data = data
    })
end

function ESX.UI.Menu.RegisterType(type, open, close)
    ESX.UI.Menu.RegisteredTypes[type] = {
        open = open,
        close = close
    }
end

function ESX.UI.Menu.Open(type, namespace, name, data, submit, cancel, change, close)
    local menu = {}

    menu.type = type
    menu.namespace = namespace
    menu.name = name
    menu.data = data
    menu.submit = submit
    menu.cancel = cancel
    menu.change = change

    menu.close = function()

        ESX.UI.Menu.RegisteredTypes[type].close(namespace, name)

        for i = 1, #ESX.UI.Menu.Opened, 1 do
            if ESX.UI.Menu.Opened[i] then
                if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and
                    ESX.UI.Menu.Opened[i].name == name then
                    ESX.UI.Menu.Opened[i] = nil
                end
            end
        end

        if close then
            close()
        end

    end

    menu.update = function(query, newData)

        for i = 1, #menu.data.elements, 1 do
            local match = true

            for k, v in pairs(query) do
                if menu.data.elements[i][k] ~= v then
                    match = false
                end
            end

            if match then
                for k, v in pairs(newData) do
                    menu.data.elements[i][k] = v
                end
            end
        end

    end

    menu.refresh = function()
        ESX.UI.Menu.RegisteredTypes[type].open(namespace, name, menu.data)
    end

    menu.setElement = function(i, key, val)
        menu.data.elements[i][key] = val
    end

    menu.setElements = function(newElements)
        menu.data.elements = newElements
    end

    menu.setTitle = function(val)
        menu.data.title = val
    end

    menu.removeElement = function(query)
        for i = 1, #menu.data.elements, 1 do
            for k, v in pairs(query) do
                if menu.data.elements[i] then
                    if menu.data.elements[i][k] == v then
                        table.remove(menu.data.elements, i)
                        break
                    end
                end

            end
        end
    end

    ESX.UI.Menu.Opened[#ESX.UI.Menu.Opened + 1] = menu
    ESX.UI.Menu.RegisteredTypes[type].open(namespace, name, data)

    return menu
end

function ESX.UI.Menu.Close(type, namespace, name)
    for i = 1, #ESX.UI.Menu.Opened, 1 do
        if ESX.UI.Menu.Opened[i] then
            if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and
                ESX.UI.Menu.Opened[i].name == name then
                ESX.UI.Menu.Opened[i].close()
                ESX.UI.Menu.Opened[i] = nil
            end
        end
    end
end

function ESX.UI.Menu.CloseAll()
    for i = 1, #ESX.UI.Menu.Opened, 1 do
        if ESX.UI.Menu.Opened[i] then
            ESX.UI.Menu.Opened[i].close()
            ESX.UI.Menu.Opened[i] = nil
        end
    end
end

function ESX.UI.Menu.GetOpened(type, namespace, name)
    for i = 1, #ESX.UI.Menu.Opened, 1 do
        if ESX.UI.Menu.Opened[i] then
            if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and
                ESX.UI.Menu.Opened[i].name == name then
                return ESX.UI.Menu.Opened[i]
            end
        end
    end
end

function ESX.UI.Menu.GetOpenedMenus()
    return ESX.UI.Menu.Opened
end

function ESX.UI.Menu.IsOpen(type, namespace, name)
    return ESX.UI.Menu.GetOpened(type, namespace, name) ~= nil
end

function ESX.UI.ShowInventoryItemNotification(add, item, count)
    SendNUIMessage({
        action = 'inventoryNotification',
        add = add,
        item = item,
        count = count
    })
end

function ESX.Game.GetPedMugshot(ped, transparent)
    if DoesEntityExist(ped) then
        local mugshot

        if transparent then
            mugshot = RegisterPedheadshotTransparent(ped)
        else
            mugshot = RegisterPedheadshot(ped)
        end

        while not IsPedheadshotReady(mugshot) do
            Wait(0)
        end

        return mugshot, GetPedheadshotTxdString(mugshot)
    else
        return
    end
end

function ESX.Game.Teleport(entity, coords, cb)
    local vector = type(coords) == "vector4" and coords or type(coords) == "vector3" and vector4(coords, 0.0) or
                       vec(coords.x, coords.y, coords.z, coords.heading or 0.0)

    if DoesEntityExist(entity) then
        RequestCollisionAtCoord(vector.xyz)
        while not HasCollisionLoadedAroundEntity(entity) do
            Wait(0)
        end

        SetEntityCoords(entity, vector.xyz, false, false, false, false)
        SetEntityHeading(entity, vector.w)
    end

    if cb then
        cb()
    end
end

function ESX.Game.SpawnObject(object, coords, cb, networked)
    local model = type(object) == 'number' and object or GetHashKey(object)
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    networked = networked == nil and true or networked

    CreateThread(function()
        ESX.Streaming.RequestModel(model)

        local obj = CreateObject(model, vector.xyz, networked, false, true)
        if cb then
            cb(obj)
        end
    end)
end

function ESX.Game.SpawnLocalObject(object, coords, cb)
    ESX.Game.SpawnObject(object, coords, cb, false)
end

function ESX.Game.DeleteVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, false, true)
    DeleteVehicle(vehicle)
end

function ESX.Game.DeleteObject(object)
    SetEntityAsMissionEntity(object, false, true)
    DeleteObject(object)
end

function ESX.Game.SpawnVehicle(vehicle, coords, heading, cb, networked)
    local model = (type(vehicle) == 'number' and vehicle or GetHashKey(vehicle))
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    networked = networked == nil and true or networked
    CreateThread(function()
        ESX.Streaming.RequestModel(model)

        local vehicle = CreateVehicle(model, vector.xyz, heading, networked, false)

        if networked then
            local id = NetworkGetNetworkIdFromEntity(vehicle)
            SetNetworkIdCanMigrate(id, true)
            SetEntityAsMissionEntity(vehicle, true, false)
        end
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetModelAsNoLongerNeeded(model)
        SetVehRadioStation(vehicle, 'OFF')

        RequestCollisionAtCoord(vector.xyz)
        while not HasCollisionLoadedAroundEntity(vehicle) do
            Wait(0)
        end

        if cb then
            cb(vehicle)
        end
    end)
end

function ESX.Game.SpawnLocalVehicle(vehicle, coords, heading, cb)
    ESX.Game.SpawnVehicle(vehicle, coords, heading, cb, false)
end

function ESX.Game.IsVehicleEmpty(vehicle)
    local passengers = GetVehicleNumberOfPassengers(vehicle)
    local driverSeatFree = IsVehicleSeatFree(vehicle, -1)

    return passengers == 0 and driverSeatFree
end

function ESX.Game.GetObjects() -- Leave the function for compatibility
    return GetGamePool('CObject')
end

function ESX.Game.GetPeds(onlyOtherPeds)
    local peds, myPed, pool = {}, ESX.PlayerData.ped, GetGamePool('CPed')

    for i = 1, #pool do
        if ((onlyOtherPeds and pool[i] ~= myPed) or not onlyOtherPeds) then
            peds[#peds + 1] = pool[i]
        end
    end

    return peds
end

function ESX.Game.GetVehicles() -- Leave the function for compatibility
    return GetGamePool('CVehicle')
end

function ESX.Game.GetPlayers(onlyOtherPlayers, returnKeyValue, returnPeds)
    local players, myPlayer = {}, PlayerId()

    for k, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)

        if DoesEntityExist(ped) and ((onlyOtherPlayers and player ~= myPlayer) or not onlyOtherPlayers) then
            if returnKeyValue then
                players[player] = ped
            else
                players[#players + 1] = returnPeds and ped or player
            end
        end
    end

    return players
end

function ESX.Game.GetClosestObject(coords, modelFilter)
    return ESX.Game.GetClosestEntity(ESX.Game.GetObjects(), false, coords, modelFilter)
end

function ESX.Game.GetClosestPed(coords, modelFilter)
    return ESX.Game.GetClosestEntity(ESX.Game.GetPeds(true), false, coords, modelFilter)
end

function ESX.Game.GetClosestPlayer(coords)
    return ESX.Game.GetClosestEntity(ESX.Game.GetPlayers(true, true), true, coords, nil)
end

function ESX.Game.GetClosestVehicle(coords, modelFilter)
    return ESX.Game.GetClosestEntity(ESX.Game.GetVehicles(), false, coords, modelFilter)
end

local function EnumerateEntitiesWithinDistance(entities, isPlayerEntities, coords, maxDistance)
    local nearbyEntities = {}

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        local playerPed = ESX.PlayerData.ped
        coords = GetEntityCoords(playerPed)
    end

    for k, entity in pairs(entities) do
        local distance = #(coords - GetEntityCoords(entity))

        if distance <= maxDistance then
            nearbyEntities[#nearbyEntities + 1] = isPlayerEntities and k or entity
        end
    end

    return nearbyEntities
end

function ESX.Game.GetPlayersInArea(coords, maxDistance)
    return EnumerateEntitiesWithinDistance(ESX.Game.GetPlayers(true, true), true, coords, maxDistance)
end

function ESX.Game.GetVehiclesInArea(coords, maxDistance)
    return EnumerateEntitiesWithinDistance(ESX.Game.GetVehicles(), false, coords, maxDistance)
end

function ESX.Game.IsSpawnPointClear(coords, maxDistance)
    return #ESX.Game.GetVehiclesInArea(coords, maxDistance) == 0
end

function ESX.Game.GetClosestEntity(entities, isPlayerEntities, coords, modelFilter)
    local closestEntity, closestEntityDistance, filteredEntities = -1, -1, nil

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        local playerPed = ESX.PlayerData.ped
        coords = GetEntityCoords(playerPed)
    end

    if modelFilter then
        filteredEntities = {}

        for k, entity in pairs(entities) do
            if modelFilter[GetEntityModel(entity)] then
                filteredEntities[#filteredEntities + 1] = entity
            end
        end
    end

    for k, entity in pairs(filteredEntities or entities) do
        local distance = #(coords - GetEntityCoords(entity))

        if closestEntityDistance == -1 or distance < closestEntityDistance then
            closestEntity, closestEntityDistance = isPlayerEntities and k or entity, distance
        end
    end

    return closestEntity, closestEntityDistance
end

function ESX.Game.GetVehicleInDirection()
    local playerPed = ESX.PlayerData.ped
    local playerCoords = GetEntityCoords(playerPed)
    local inDirection = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(playerCoords, inDirection, 10, playerPed, 0)
    local numRayHandle, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)

    if hit == 1 and GetEntityType(entityHit) == 2 then
        local entityCoords = GetEntityCoords(entityHit)
        return entityHit, entityCoords
    end

    return nil
end

function ESX.Game.GetVehicleProperties(vehicle)
    if DoesEntityExist(vehicle) then
        local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
        local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
        local hasCustomPrimaryColor = GetIsVehiclePrimaryColourCustom(vehicle)
        local customPrimaryColor = nil
        if hasCustomPrimaryColor then
            local r, g, b = GetVehicleCustomPrimaryColour(vehicle)
            customPrimaryColor = {r, g, b}
        end

        local hasCustomSecondaryColor = GetIsVehicleSecondaryColourCustom(vehicle)
        local customSecondaryColor = nil
        if hasCustomSecondaryColor then
            local r, g, b = GetVehicleCustomSecondaryColour(vehicle)
            customSecondaryColor = {r, g, b}
        end
        local extras = {}

        for extraId = 0, 12 do
            if DoesExtraExist(vehicle, extraId) then
                local state = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
                extras[tostring(extraId)] = state
            end
        end

        local doorsBroken, windowsBroken, tyreBurst = {}, {}, {}
        local numWheels = tostring(GetVehicleNumberOfWheels(vehicle))

        local TyresIndex = { -- Wheel index list according to the number of vehicle wheels.
            ['2'] = {0, 4}, -- Bike and cycle.
            ['3'] = {0, 1, 4, 5}, -- Vehicle with 3 wheels (get for wheels because some 3 wheels vehicles have 2 wheels on front and one rear or the reverse).
            ['4'] = {0, 1, 4, 5}, -- Vehicle with 4 wheels.
            ['6'] = {0, 1, 2, 3, 4, 5} -- Vehicle with 6 wheels.
        }

        if TyresIndex[numWheels] then
            for tyre, idx in pairs(TyresIndex[numWheels]) do
                if IsVehicleTyreBurst(vehicle, idx, false) then
                    tyreBurst[tostring(idx)] = true
                else
                    tyreBurst[tostring(idx)] = false
                end
            end
        end

        for windowId = 0, 7 do -- 13
            if not IsVehicleWindowIntact(vehicle, windowId) then
                windowsBroken[tostring(windowId)] = true
            else
                windowsBroken[tostring(windowId)] = false
            end
        end

        local numDoors = GetNumberOfVehicleDoors(vehicle)
        if numDoors and numDoors > 0 then
            for doorsId = 0, numDoors do
                if IsVehicleDoorDamaged(vehicle, doorsId) then
                    doorsBroken[tostring(doorsId)] = true
                else
                    doorsBroken[tostring(doorsId)] = false
                end
            end
        end

        return {
            model = GetEntityModel(vehicle),
            doorsBroken = doorsBroken,
            windowsBroken = windowsBroken,
            tyreBurst = tyreBurst,
            plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)),
            plateIndex = GetVehicleNumberPlateTextIndex(vehicle),

            bodyHealth = ESX.Math.Round(GetVehicleBodyHealth(vehicle), 1),
            engineHealth = ESX.Math.Round(GetVehicleEngineHealth(vehicle), 1),
            tankHealth = ESX.Math.Round(GetVehiclePetrolTankHealth(vehicle), 1),

            fuelLevel = ESX.Math.Round(GetVehicleFuelLevel(vehicle), 1),
            dirtLevel = ESX.Math.Round(GetVehicleDirtLevel(vehicle), 1),
            color1 = colorPrimary,
            color2 = colorSecondary,
            customPrimaryColor = customPrimaryColor,
            customSecondaryColor = customSecondaryColor,

            pearlescentColor = pearlescentColor,
            wheelColor = wheelColor,

            wheels = GetVehicleWheelType(vehicle),
            windowTint = GetVehicleWindowTint(vehicle),
            xenonColor = GetVehicleXenonLightsColor(vehicle),

            neonEnabled = {IsVehicleNeonLightEnabled(vehicle, 0), IsVehicleNeonLightEnabled(vehicle, 1),
                           IsVehicleNeonLightEnabled(vehicle, 2), IsVehicleNeonLightEnabled(vehicle, 3)},

            neonColor = table.pack(GetVehicleNeonLightsColour(vehicle)),
            extras = extras,
            tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicle)),

            modSpoilers = GetVehicleMod(vehicle, 0),
            modFrontBumper = GetVehicleMod(vehicle, 1),
            modRearBumper = GetVehicleMod(vehicle, 2),
            modSideSkirt = GetVehicleMod(vehicle, 3),
            modExhaust = GetVehicleMod(vehicle, 4),
            modFrame = GetVehicleMod(vehicle, 5),
            modGrille = GetVehicleMod(vehicle, 6),
            modHood = GetVehicleMod(vehicle, 7),
            modFender = GetVehicleMod(vehicle, 8),
            modRightFender = GetVehicleMod(vehicle, 9),
            modRoof = GetVehicleMod(vehicle, 10),

            modEngine = GetVehicleMod(vehicle, 11),
            modBrakes = GetVehicleMod(vehicle, 12),
            modTransmission = GetVehicleMod(vehicle, 13),
            modHorns = GetVehicleMod(vehicle, 14),
            modSuspension = GetVehicleMod(vehicle, 15),
            modArmor = GetVehicleMod(vehicle, 16),

            modTurbo = IsToggleModOn(vehicle, 18),
            modSmokeEnabled = IsToggleModOn(vehicle, 20),
            modXenon = IsToggleModOn(vehicle, 22),

            modFrontWheels = GetVehicleMod(vehicle, 23),
            modBackWheels = GetVehicleMod(vehicle, 24),

            modPlateHolder = GetVehicleMod(vehicle, 25),
            modVanityPlate = GetVehicleMod(vehicle, 26),
            modTrimA = GetVehicleMod(vehicle, 27),
            modOrnaments = GetVehicleMod(vehicle, 28),
            modDashboard = GetVehicleMod(vehicle, 29),
            modDial = GetVehicleMod(vehicle, 30),
            modDoorSpeaker = GetVehicleMod(vehicle, 31),
            modSeats = GetVehicleMod(vehicle, 32),
            modSteeringWheel = GetVehicleMod(vehicle, 33),
            modShifterLeavers = GetVehicleMod(vehicle, 34),
            modAPlate = GetVehicleMod(vehicle, 35),
            modSpeakers = GetVehicleMod(vehicle, 36),
            modTrunk = GetVehicleMod(vehicle, 37),
            modHydrolic = GetVehicleMod(vehicle, 38),
            modEngineBlock = GetVehicleMod(vehicle, 39),
            modAirFilter = GetVehicleMod(vehicle, 40),
            modStruts = GetVehicleMod(vehicle, 41),
            modArchCover = GetVehicleMod(vehicle, 42),
            modAerials = GetVehicleMod(vehicle, 43),
            modTrimB = GetVehicleMod(vehicle, 44),
            modTank = GetVehicleMod(vehicle, 45),
            modDoorR = GetVehicleMod(vehicle, 47),
            modLivery = GetVehicleLivery(vehicle),
            modLightbar = GetVehicleMod(vehicle, 49)
        }
    else
        return
    end
end

function ESX.Game.SetVehicleProperties(vehicle, props)
    if DoesEntityExist(vehicle) then
        local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
        local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
        SetVehicleModKit(vehicle, 0)

        if props.plate then
            SetVehicleNumberPlateText(vehicle, props.plate)
        end
        if props.plateIndex then
            SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
        end
        if props.bodyHealth then
            SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0)
        end
        if props.engineHealth then
            SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0)
        end
        if props.tankHealth then
            SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0)
        end
        if props.fuelLevel then
            SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
        end
        if props.dirtLevel then
            SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
        end
        if props.customPrimaryColor then
            SetVehicleCustomPrimaryColour(vehicle, props.customPrimaryColor[1], props.customPrimaryColor[2],
                props.customPrimaryColor[3])
        end
        if props.customSecondaryColor then
            SetVehicleCustomSecondaryColour(vehicle, props.customSecondaryColor[1], props.customSecondaryColor[2],
                props.customSecondaryColor[3])
        end
        if props.color1 then
            SetVehicleColours(vehicle, props.color1, colorSecondary)
        end
        if props.color2 then
            SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2)
        end
        if props.pearlescentColor then
            SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor)
        end
        if props.wheelColor then
            SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor)
        end
        if props.wheels then
            SetVehicleWheelType(vehicle, props.wheels)
        end
        if props.windowTint then
            SetVehicleWindowTint(vehicle, props.windowTint)
        end

        if props.neonEnabled then
            SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
            SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
            SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
            SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
        end

        if props.extras then
            for extraId, enabled in pairs(props.extras) do
                if enabled then
                    SetVehicleExtra(vehicle, tonumber(extraId), 0)
                else
                    SetVehicleExtra(vehicle, tonumber(extraId), 1)
                end
            end
        end

        if props.neonColor then
            SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
        end
        if props.xenonColor then
            SetVehicleXenonLightsColor(vehicle, props.xenonColor)
        end
        if props.modSmokeEnabled then
            ToggleVehicleMod(vehicle, 20, true)
        end
        if props.tyreSmokeColor then
            SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
        end
        if props.modSpoilers then
            SetVehicleMod(vehicle, 0, props.modSpoilers, false)
        end
        if props.modFrontBumper then
            SetVehicleMod(vehicle, 1, props.modFrontBumper, false)
        end
        if props.modRearBumper then
            SetVehicleMod(vehicle, 2, props.modRearBumper, false)
        end
        if props.modSideSkirt then
            SetVehicleMod(vehicle, 3, props.modSideSkirt, false)
        end
        if props.modExhaust then
            SetVehicleMod(vehicle, 4, props.modExhaust, false)
        end
        if props.modFrame then
            SetVehicleMod(vehicle, 5, props.modFrame, false)
        end
        if props.modGrille then
            SetVehicleMod(vehicle, 6, props.modGrille, false)
        end
        if props.modHood then
            SetVehicleMod(vehicle, 7, props.modHood, false)
        end
        if props.modFender then
            SetVehicleMod(vehicle, 8, props.modFender, false)
        end
        if props.modRightFender then
            SetVehicleMod(vehicle, 9, props.modRightFender, false)
        end
        if props.modRoof then
            SetVehicleMod(vehicle, 10, props.modRoof, false)
        end
        if props.modEngine then
            SetVehicleMod(vehicle, 11, props.modEngine, false)
        end
        if props.modBrakes then
            SetVehicleMod(vehicle, 12, props.modBrakes, false)
        end
        if props.modTransmission then
            SetVehicleMod(vehicle, 13, props.modTransmission, false)
        end
        if props.modHorns then
            SetVehicleMod(vehicle, 14, props.modHorns, false)
        end
        if props.modSuspension then
            SetVehicleMod(vehicle, 15, props.modSuspension, false)
        end
        if props.modArmor then
            SetVehicleMod(vehicle, 16, props.modArmor, false)
        end
        if props.modTurbo then
            ToggleVehicleMod(vehicle, 18, props.modTurbo)
        end
        if props.modXenon then
            ToggleVehicleMod(vehicle, 22, props.modXenon)
        end
        if props.modFrontWheels then
            SetVehicleMod(vehicle, 23, props.modFrontWheels, false)
        end
        if props.modBackWheels then
            SetVehicleMod(vehicle, 24, props.modBackWheels, false)
        end
        if props.modPlateHolder then
            SetVehicleMod(vehicle, 25, props.modPlateHolder, false)
        end
        if props.modVanityPlate then
            SetVehicleMod(vehicle, 26, props.modVanityPlate, false)
        end
        if props.modTrimA then
            SetVehicleMod(vehicle, 27, props.modTrimA, false)
        end
        if props.modOrnaments then
            SetVehicleMod(vehicle, 28, props.modOrnaments, false)
        end
        if props.modDashboard then
            SetVehicleMod(vehicle, 29, props.modDashboard, false)
        end
        if props.modDial then
            SetVehicleMod(vehicle, 30, props.modDial, false)
        end
        if props.modDoorSpeaker then
            SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false)
        end
        if props.modSeats then
            SetVehicleMod(vehicle, 32, props.modSeats, false)
        end
        if props.modSteeringWheel then
            SetVehicleMod(vehicle, 33, props.modSteeringWheel, false)
        end
        if props.modShifterLeavers then
            SetVehicleMod(vehicle, 34, props.modShifterLeavers, false)
        end
        if props.modAPlate then
            SetVehicleMod(vehicle, 35, props.modAPlate, false)
        end
        if props.modSpeakers then
            SetVehicleMod(vehicle, 36, props.modSpeakers, false)
        end
        if props.modTrunk then
            SetVehicleMod(vehicle, 37, props.modTrunk, false)
        end
        if props.modHydrolic then
            SetVehicleMod(vehicle, 38, props.modHydrolic, false)
        end
        if props.modEngineBlock then
            SetVehicleMod(vehicle, 39, props.modEngineBlock, false)
        end
        if props.modAirFilter then
            SetVehicleMod(vehicle, 40, props.modAirFilter, false)
        end
        if props.modStruts then
            SetVehicleMod(vehicle, 41, props.modStruts, false)
        end
        if props.modArchCover then
            SetVehicleMod(vehicle, 42, props.modArchCover, false)
        end
        if props.modAerials then
            SetVehicleMod(vehicle, 43, props.modAerials, false)
        end
        if props.modTrimB then
            SetVehicleMod(vehicle, 44, props.modTrimB, false)
        end
        if props.modTank then
            SetVehicleMod(vehicle, 45, props.modTank, false)
        end
        if props.modWindows then
            SetVehicleMod(vehicle, 46, props.modWindows, false)
        end

        if props.modLivery then
            SetVehicleLivery(vehicle, props.modLivery)
        end

        if props.windowsBroken then
            for k, v in pairs(props.windowsBroken) do
                if v then
                    SmashVehicleWindow(vehicle, tonumber(k))
                end
            end
        end

        if props.doorsBroken then
            for k, v in pairs(props.doorsBroken) do
                if v then
                    SetVehicleDoorBroken(vehicle, tonumber(k), true)
                end
            end
        end

        if props.tyreBurst then
            for k, v in pairs(props.tyreBurst) do
                if v then
                    SetVehicleTyreBurst(vehicle, tonumber(k), true, 1000.0)
                end
            end
        end
    end
end

function ESX.Game.Utils.DrawText3D(coords, text, size, font)
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)

    local camCoords = GetFinalRenderedCamCoord()
    local distance = #(vector - camCoords)

    if not size then
        size = 1
    end
    if not font then
        font = 0
    end

    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0 * scale, 0.55 * scale)
    SetTextFont(font)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(vector.xyz, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

function ESX.ShowInventory()
    local playerPed = ESX.PlayerData.ped
    local elements, currentWeight = {}, 0

    for k, v in pairs(ESX.PlayerData.accounts) do
        if v.money > 0 then
            local formattedMoney = _U('locale_currency', ESX.Math.GroupDigits(v.money))
            local canDrop = v.name ~= 'bank'

            table.insert(elements, {
                label = ('%s: <span style="color:green;">%s</span>'):format(v.label, formattedMoney),
                count = v.money,
                type = 'item_account',
                value = v.name,
                usable = false,
                rare = false,
                canRemove = canDrop
            })
        end
    end

    for k, v in ipairs(ESX.PlayerData.inventory) do
        if v.count > 0 then
            currentWeight = currentWeight + (v.weight * v.count)

            table.insert(elements, {
                label = ('%s x%s'):format(v.label, v.count),
                count = v.count,
                type = 'item_standard',
                value = v.name,
                usable = v.usable,
                rare = v.rare,
                canRemove = v.canRemove
            })
        end
    end

    for k, v in ipairs(Config.Weapons) do
        local weaponHash = GetHashKey(v.name)

        if HasPedGotWeapon(playerPed, weaponHash, false) then
            local ammo, label = GetAmmoInPedWeapon(playerPed, weaponHash)

            if v.ammo then
                label = ('%s - %s %s'):format(v.label, ammo, v.ammo.label)
            else
                label = v.label
            end

            table.insert(elements, {
                label = label,
                count = 1,
                type = 'item_weapon',
                value = v.name,
                usable = false,
                rare = false,
                ammo = ammo,
                canGiveAmmo = (v.ammo ~= nil),
                canRemove = true
            })
        end
    end

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'inventory', {
        title = _U('inventory', currentWeight, ESX.PlayerData.maxWeight),
        align = 'bottom-right',
        elements = elements
    }, function(data, menu)
        menu.close()
        local player, distance = ESX.Game.GetClosestPlayer()
        elements = {}

        if data.current.usable then
            table.insert(elements, {
                label = _U('use'),
                action = 'use',
                type = data.current.type,
                value = data.current.value
            })
        end

        if data.current.canRemove then
            if player ~= -1 and distance <= 3.0 then
                table.insert(elements, {
                    label = _U('give'),
                    action = 'give',
                    type = data.current.type,
                    value = data.current.value
                })
            end

            table.insert(elements, {
                label = _U('remove'),
                action = 'remove',
                type = data.current.type,
                value = data.current.value
            })
        end

        if data.current.type == 'item_weapon' and data.current.canGiveAmmo and data.current.ammo > 0 and player ~= -1 and
            distance <= 3.0 then
            table.insert(elements, {
                label = _U('giveammo'),
                action = 'give_ammo',
                type = data.current.type,
                value = data.current.value
            })
        end

        table.insert(elements, {
            label = _U('return'),
            action = 'return'
        })

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'inventory_item', {
            title = data.current.label,
            align = 'bottom-right',
            elements = elements
        }, function(data1, menu1)
            local item, type = data1.current.value, data1.current.type

            if data1.current.action == 'give' then
                local playersNearby = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)

                if #playersNearby > 0 then
                    local players = {}
                    elements = {}

                    for k, playerNearby in ipairs(playersNearby) do
                        players[GetPlayerServerId(playerNearby)] = true
                    end

                    ESX.TriggerServerCallback('esx:getPlayerNames', function(returnedPlayers)
                        for playerId, playerName in pairs(returnedPlayers) do
                            table.insert(elements, {
                                label = playerName,
                                playerId = playerId
                            })
                        end

                        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'give_item_to', {
                            title = _U('give_to'),
                            align = 'bottom-right',
                            elements = elements
                        }, function(data2, menu2)
                            local selectedPlayer, selectedPlayerId = GetPlayerFromServerId(data2.current.playerId),
                                data2.current.playerId
                            playersNearby = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)
                            playersNearby = ESX.Table.Set(playersNearby)

                            if playersNearby[selectedPlayer] then
                                local selectedPlayerPed = GetPlayerPed(selectedPlayer)

                                if IsPedOnFoot(selectedPlayerPed) and not IsPedFalling(selectedPlayerPed) then
                                    if type == 'item_weapon' then
                                        TriggerServerEvent('esx:giveInventoryItem', selectedPlayerId, type, item, nil)
                                        menu2.close()
                                        menu1.close()
                                    else
                                        ESX.UI.Menu.Open('dialog', GetCurrentResourceName(),
                                            'inventory_item_count_give', {
                                                title = _U('amount')
                                            }, function(data3, menu3)
                                                local quantity = tonumber(data3.value)

                                                if quantity and quantity > 0 and data.current.count >= quantity then
                                                    TriggerServerEvent('esx:giveInventoryItem', selectedPlayerId, type,
                                                        item, quantity)
                                                    menu3.close()
                                                    menu2.close()
                                                    menu1.close()
                                                else
                                                    ESX.ShowNotification(_U('amount_invalid'))
                                                end
                                            end, function(data3, menu3)
                                                menu3.close()
                                            end)
                                    end
                                else
                                    ESX.ShowNotification(_U('in_vehicle'))
                                end
                            else
                                ESX.ShowNotification(_U('players_nearby'))
                                menu2.close()
                            end
                        end, function(data2, menu2)
                            menu2.close()
                        end)
                    end, players)
                else
                    ESX.ShowNotification(_U('players_nearby'))
                end
            elseif data1.current.action == 'remove' then
                if IsPedOnFoot(playerPed) and not IsPedFalling(playerPed) then
                    local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
                    ESX.Streaming.RequestAnimDict(dict)

                    if type == 'item_weapon' then
                        menu1.close()
                        TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
                        RemoveAnimDict(dict)
                        Wait(1000)
                        TriggerServerEvent('esx:removeInventoryItem', type, item)
                    else
                        ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'inventory_item_count_remove', {
                            title = _U('amount')
                        }, function(data2, menu2)
                            local quantity = tonumber(data2.value)

                            if quantity and quantity > 0 and data.current.count >= quantity then
                                menu2.close()
                                menu1.close()
                                TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
                                RemoveAnimDict(dict)
                                Wait(1000)
                                TriggerServerEvent('esx:removeInventoryItem', type, item, quantity)
                            else
                                ESX.ShowNotification(_U('amount_invalid'))
                            end
                        end, function(data2, menu2)
                            menu2.close()
                        end)
                    end
                end
            elseif data1.current.action == 'use' then
                TriggerServerEvent('esx:useItem', item)
            elseif data1.current.action == 'return' then
                ESX.UI.Menu.CloseAll()
                ESX.ShowInventory()
            elseif data1.current.action == 'give_ammo' then
                local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                local closestPed = GetPlayerPed(closestPlayer)
                local pedAmmo = GetAmmoInPedWeapon(playerPed, GetHashKey(item))

                if IsPedOnFoot(closestPed) and not IsPedFalling(closestPed) then
                    if closestPlayer ~= -1 and closestDistance < 3.0 then
                        if pedAmmo > 0 then
                            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'inventory_item_count_give', {
                                title = _U('amountammo')
                            }, function(data2, menu2)
                                local quantity = tonumber(data2.value)

                                if quantity and quantity > 0 then
                                    if pedAmmo >= quantity then
                                        TriggerServerEvent('esx:giveInventoryItem', GetPlayerServerId(closestPlayer),
                                            'item_ammo', item, quantity)
                                        menu2.close()
                                        menu1.close()
                                    else
                                        ESX.ShowNotification(_U('noammo'))
                                    end
                                else
                                    ESX.ShowNotification(_U('amount_invalid'))
                                end
                            end, function(data2, menu2)
                                menu2.close()
                            end)
                        else
                            ESX.ShowNotification(_U('noammo'))
                        end
                    else
                        ESX.ShowNotification(_U('players_nearby'))
                    end
                else
                    ESX.ShowNotification(_U('in_vehicle'))
                end
            end
        end, function(data1, menu1)
            ESX.UI.Menu.CloseAll()
            ESX.ShowInventory()
        end)
    end, function(data, menu)
        menu.close()
    end)
end

RegisterNetEvent('esx:serverCallback')
AddEventHandler('esx:serverCallback', function(requestId, ...)
    Core.ServerCallbacks[requestId](...)
    Core.ServerCallbacks[requestId] = nil
end)

RegisterNetEvent('esx:showNotification')
AddEventHandler('esx:showNotification', function(msg, type, length)
    ESX.ShowNotification(msg, type, length)
end)

RegisterNetEvent('esx:showAdvancedNotification')
AddEventHandler('esx:showAdvancedNotification', function(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    ESX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
end)

RegisterNetEvent('esx:showHelpNotification')
AddEventHandler('esx:showHelpNotification', function(msg, thisFrame, beep, duration)
    ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
end)

-- SetTimeout
CreateThread(function()
    while true do
        local sleep = 100
        if #Core.TimeoutCallbacks > 0 then
            local currTime = GetGameTimer()
            sleep = 0
            for i = 1, #Core.TimeoutCallbacks, 1 do
                if currTime >= Core.TimeoutCallbacks[i].time then
                    Core.TimeoutCallbacks[i].cb()
                    Core.TimeoutCallbacks[i] = nil
                end
            end
        end
        Wait(sleep)
    end
end)
