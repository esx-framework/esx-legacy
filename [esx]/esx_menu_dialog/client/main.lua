local Timeouts, OpenedMenus, MenuType, OpenedMenusCount = {}, {}, "dialog", 0
local function openMenu(namespace, name, data)
    for i = 1, #Timeouts, 1 do
        ESX.ClearTimeout(Timeouts[i])
    end

    OpenedMenus[namespace .. "_" .. name] = true
    OpenedMenusCount = OpenedMenusCount + 1
    if OpenedMenusCount == 1 then
        DisableControls()
    end
    SendNUIMessage(
        {
            action = "openMenu",
            namespace = namespace,
            name = name,
            data = data
        }
    )

    local timeoutId =
        ESX.SetTimeout(
        200,
        function()
            SetNuiFocus(true, true)
        end
    )

    table.insert(Timeouts, timeoutId)
end

local function closeMenu(namespace, name)
    OpenedMenus[namespace .. "_" .. name] = nil
    OpenedMenusCount = OpenedMenusCount - 1
    SendNUIMessage(
        {
            action = "closeMenu",
            namespace = namespace,
            name = name
        }
    )

    if ESX.Table.SizeOf(OpenedMenus) == 0 then
        SetNuiFocus(false)
    end
end

ESX.UI.Menu.RegisterType(MenuType, openMenu, closeMenu)

AddEventHandler(
    "esx_menu_dialog:message:menu_submit",
    function(data)
        local menu = ESX.UI.Menu.GetOpened(MenuType, data._namespace, data._name)
        local cancel = false

        if menu.submit then
            -- is the submitted data a number?
            if tonumber(data.value) then
                data.value = ESX.Math.Round(tonumber(data.value))

                -- check for negative value
                if tonumber(data.value) <= 0 then
                    cancel = true
                end
            end

            data.value = ESX.Math.Trim(data.value)

            -- don't submit if the value is negative or if it's 0
            if cancel then
                ESX.ShowNotification("That input is not allowed!")
            else
                menu.submit(data, menu)
            end
        end
    end
)

AddEventHandler(
    "esx_menu_dialog:message:menu_cancel",
    function(data)
        local menu = ESX.UI.Menu.GetOpened(MenuType, data._namespace, data._name)

        if menu.cancel ~= nil then
            menu.cancel(data, menu)
        end
    end
)

AddEventHandler(
    "esx_menu_dialog:message:menu_change",
    function(data)
        local menu = ESX.UI.Menu.GetOpened(MenuType, data._namespace, data._name)

        if menu.change ~= nil then
            menu.change(data, menu)
        end
    end
)

function DisableControls()
    CreateThread(
        function()
            while OpenedMenusCount > 0 do
                Wait(0)

                DisableControlAction(0, 1, true) -- LookLeftRight
                DisableControlAction(0, 2, true) -- LookUpDown
                DisableControlAction(0, 142, true) -- MeleeAttackAlternate
                DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
                DisableControlAction(0, 12, true) -- WeaponWheelUpDown
                DisableControlAction(0, 14, true) -- WeaponWheelNext
                DisableControlAction(0, 15, true) -- WeaponWheelPrev
                DisableControlAction(0, 16, true) -- SelectNextWeapon
                DisableControlAction(0, 17, true) -- SelectPrevWeapon
            end
        end
    )
end
