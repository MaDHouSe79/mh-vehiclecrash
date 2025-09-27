local isCrashed = false
local currentHeight = nil
local showHits = false

local function Draw3DText(x, y, z, txt, font, scale, num)
    local _x, _y, _z = table.unpack(GetGameplayCamCoords())
    local distance = 1 / GetDistanceBetweenCoords(_x, _y, _z, x, y, z, true) * 20
    local value = distance * 1 / GetGameplayCamFov() * 100
    SetTextScale(scale * value, num * value)
    SetTextFont(font)
    SetTextProportional(1)
    SetTextDropshadow(1, 1, 1, 1, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(txt)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do Wait(1) end
end

local function CheckVehicleRotation(vehicle)
    local ped = PlayerPedId()
    local rotation = GetEntityRotation(vehicle)
    if (rotation.x > 75.0 or rotation.x < -75.0 or rotation.y > 75.0 or rotation.y < -75.0) then
        isCrashed = true
    else
        isCrashed = false
    end
end

local function GetVehicleAngle(vehicle)
    if not vehicle then return false end
    local vx, vy, vz = table.unpack(GetEntityVelocity(vehicle))
    local modV = math.sqrt(vx * vx + vy * vy)
    local rx, ry, rz = table.unpack(GetEntityRotation(vehicle, 0))
    local sn, cs = -math.sin(math.rad(rz)), math.cos(math.rad(rz))
    if GetEntitySpeed(vehicle) * 3.6 < 5 or GetVehicleCurrentGear(vehicle) == 0 then return 0, modV end
    local cosX = (sn * vx + cs * vy) / modV
    if cosX > 0.966 or cosX < 0 then return 0, modV end
    return math.deg(math.acos(cosX)) * 0.5, modV
end

local function LossControl(vehicle)
    SetVehicleReduceGrip(vehicle, true)
    Wait(math.random(1, 3) * 1000)
    SetVehicleReduceGrip(vehicle, false)
end

local function GetWheelHit(vehicle)
    local coords = GetEntityCoords(vehicle)
    local wheelIndex, location, heading = GetClosestVehicleNodeWithHeading(coords.x, coords.y, coords.z, 0, 3, 0)
    return wheelIndex
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsUsing(ped)
            if (GetPedInVehicleSeat(vehicle, -1) == ped) and GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDragCoeff") < 90 then
                local angle, speed = GetVehicleAngle(vehicle)
                local wheelType = GetVehicleWheelType(vehicle)
                if speed >= Config.MinDriveSpeedChangeToCrash and angle > Config.MaxAngleForChangeToCrash and not Config.IngnoreWheelTypes[wheelType] then
                    if math.random(1, 100) < Config.ChangeToCrash then SetVehicleHandlingField(vehicle, "CHandlingData", "fRollCentreHeightFront", -2.0) end
                    Wait(1500)
                    LossControl(vehicle)
                    SetVehicleHandlingField(vehicle, "CHandlingData", "fRollCentreHeightFront", 0.0)
                end
                if not isCrashed then CheckVehicleRotation(vehicle) end
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        if isCrashed then
            DisableControlAction(0, 59)
            DisableControlAction(0, 60)
        end
        Wait(0)
    end
end)

CreateThread(function()
    LoadAnimDict("veh@low@front_ps@idle_duck")
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        if isCrashed then
            isCrashed = false
            sleep = 5
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsUsing(ped)
                if not IsEntityPlayingAnim(ped, "veh@low@front_ps@idle_duck", "sit", 3) then
                    SetVehicleEngineOn(vehicle, false, true, true)
                    SetVehicleBodyHealth(vehicle, GetVehicleBodyHealth(vehicle) - Config.ReduseVehicleHealthWhenCrashed)
                    TaskPlayAnim(ped, "veh@low@front_ps@idle_duck", "sit", 1.0, 1.0, -1, 1, 0, 0, 0, 0)
                end
                Wait(Config.WaitAfterCrashBeforePlayerCanDrive)
                local rotation = GetEntityRotation(vehicle)
                if (rotation.x > 75.0 or rotation.x < -75.0 or rotation.y > 75.0 or rotation.y < -75.0) then
                    TaskLeaveVehicle(ped, vehicle, 1)
                end
                Wait(1500)
                ClearPedTasks(ped)
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 5000
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
                sleep = 1000
                local speed = math.ceil(GetEntitySpeed(vehicle) * 3.6)
                if HasEntityCollidedWithAnything(vehicle) and speed >= Config.WheelBreakSpeed then
                    local wheelIndex = GetWheelHit(vehicle)
                    if wheelIndex ~= -1 then
                        showHits = true
                        SetVehicleWheelHealth(vehicle, wheelIndex, GetVehicleWheelHealth(vehicle, wheelIndex) - math.random(300, 500))
                        local health = math.floor(GetVehicleWheelHealth(vehicle, wheelIndex))
                        if health < 500 then SetVehicleTyreBurst(vehicle, 0, false, 1000.0) end
                    end
                    Wait(5000)
                    showHits = false
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        if showHits then
            local entity = GetVehiclePedIsIn(PlayerPedId(), true) 
            for wheelIndex, bone in pairs(Config.Wheels) do
                if GetEntityBoneIndexByName(entity, bone.name) ~= -1 then       
                    local offset = GetWorldPositionOfEntityBone(entity, GetEntityBoneIndexByName(entity, bone.name))
                    if not offset then offset = GetWorldPositionOfEntityBone(entity, GetEntityBoneIndexByName(entity, bone.suspension)) end
                    local health = math.floor(GetVehicleWheelHealth(entity, wheelIndex))
                    local color = "~w~"
                    if health > 900 then color = "~g~" end
                    if health < 900 then color = "~y~" end
                    if health < 700 then color = "~r~" end
                    Draw3DText(offset.x, offset.y, offset.z, color .. "Health:"..health .."~w~", 4, 0.06, 0.06)
                end
            end
        end
        Wait(1)
    end
end)
