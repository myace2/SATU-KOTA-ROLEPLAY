
local logger = require '@qbx_core.modules.logger'
local spawningVehicles = {}

---@param player table
---@param garage GarageConfig
---@return boolean
local function canAccessGarage(player, garage)
    if garage.groups and not exports.qbx_core:HasPrimaryGroup(
        player.PlayerData.source,
        garage.groups
    ) then
        return false
    end

    if garage.canAccess ~= nil and not garage.canAccess(
        player.PlayerData.source
    ) then
        return false
    end

    return true
end

---@param vehicleId integer
---@param vehicle number
---@param modelName string
local function setVehicleStateToOut(vehicleId, vehicle, modelName)
    local depotPrice = Config.calculateImpoundFee(vehicleId, modelName) or 0

    return exports.qbx_vehicles:SaveVehicle(vehicle, {
        state = VehicleState.OUT,
        depotPrice = depotPrice
    })
end

---@param player table
---@param depotPrice integer
---@return string?
local function payDepotPrice(player, depotPrice)
    local cashBalance = player.PlayerData.money.cash
    local bankBalance = player.PlayerData.money.bank

    if cashBalance >= depotPrice then
        return player.Functions.RemoveMoney(
            'cash',
            depotPrice,
            'paid-depot'
        ) and 'cash'
    elseif bankBalance >= depotPrice then
        return player.Functions.RemoveMoney(
            'bank',
            depotPrice,
            'paid-depot'
        ) and 'bank'
    end
end

---@param source number
---@param vehicleId integer
---@param garageName string
---@param accessPointIndex integer
---@return number? netId
local function spawnVehicle(source, vehicleId, garageName, accessPointIndex)

    -- VALIDASI PARAMETER
    vehicleId = tonumber(vehicleId)
    accessPointIndex = tonumber(accessPointIndex)

    if not vehicleId or vehicleId <= 0 or vehicleId % 1 ~= 0 then
        print('[qbx_garages] Invalid vehicle ID:', tostring(vehicleId))
        return
    end

    if type(garageName) ~= 'string' then
        print('[qbx_garages] Invalid garage name')
        return
    end

    if not accessPointIndex or accessPointIndex % 1 ~= 0 then
        print('[qbx_garages] Invalid access point index')
        return
    end

    print('========== VEHICLE ID DEBUG ==========')
    print('Source:', source)
    print('Vehicle ID:', vehicleId)
    print('Vehicle ID Type:', type(vehicleId))
    print('Garage:', garageName)
    print('Access Point:', accessPointIndex)
    print('======================================')

    -- PLAYER DAN GARAGE
    local player = exports.qbx_core:GetPlayer(source)
    local garage = TryGetGarage(source, garageName)

    if not player or not garage or not canAccessGarage(player, garage) then
        print('[qbx_garages] Player or garage validation failed')
        return
    end

    local accessPoint = garage.accessPoints[accessPointIndex]

    if not accessPoint then
        logger.log({
            source = source,
            message = string.format(
                'Attempted to spawn a vehicle from a non-existent access point index: %d for garage: %s',
                accessPointIndex,
                garageName
            ),
            webhook = Config.logging.webhook.error,
            event = 'error',
            color = 'red'
        })

        return
    end

    -- CEK JARAK PLAYER
    local distanceBetweenPlayerAndAccessPoint =
        #(GetEntityCoords(GetPlayerPed(source)) - accessPoint.coords.xyz)

    if distanceBetweenPlayerAndAccessPoint > 3 then
        logger.log({
            source = source,
            message = string.format(
                'Player attempted to spawn a vehicle but was too far from the access point. Distance: %.2f, Access Point Index: %d, Garage: %s',
                distanceBetweenPlayerAndAccessPoint,
                accessPointIndex,
                garageName
            ),
            webhook = Config.logging.webhook.anticheat,
            event = 'suspicious',
            color = 'white'
        })

        return
    end

    local garageType = GetGarageType(garageName)
    local spawnCoords = accessPoint.spawn or accessPoint.coords

    -- CEK LOKASI SPAWN
    if Config.distanceCheck then
        local nearbyVehicle = lib.getClosestVehicle(
            spawnCoords.xyz,
            Config.distanceCheck,
            false
        )

        if nearbyVehicle then
            exports.qbx_core:Notify(
                source,
                locale('error.no_space'),
                'error'
            )
            return
        end
    end

    -- AMBIL FILTER KENDARAAN
    local filter = GetPlayerVehicleFilter(source, garageName)

    print('========== GET VEHICLE DEBUG ==========')
    print('Vehicle ID:', vehicleId)
    print('Filter:', json.encode(filter))

    -- AMBIL DATA KENDARAAN
    local successGet, playerVehicle = pcall(function()
        return exports.qbx_vehicles:GetPlayerVehicle(
            vehicleId,
            filter
        )
    end)

    print('GetPlayerVehicle Success:', successGet)
    print('Vehicle Data:', json.encode(playerVehicle))
    print('=======================================')

    if not successGet then
        lib.print.error(
            '[qbx_garages] GetPlayerVehicle error: ' ..
            tostring(playerVehicle)
        )

        exports.qbx_core:Notify(
            source,
            'Gagal mengambil data kendaraan. Periksa console server.',
            'error'
        )

        return
    end

    if not playerVehicle then
        print('[qbx_garages] Vehicle not found:', vehicleId)

        exports.qbx_core:Notify(
            source,
            locale('error.not_owned'),
            'error'
        )

        return
    end

    -- DEBUG DATA KENDARAAN
    print('========== GARAGE DEBUG ==========')
    print('Vehicle ID:', playerVehicle.id)
    print('Model Name:', playerVehicle.modelName)
    print('Model Hash:', playerVehicle.props and playerVehicle.props.model)
    print('Plate:', playerVehicle.props and playerVehicle.props.plate)
    print('State:', playerVehicle.state)
    print('Garage:', playerVehicle.garage)
    print('==================================')

    -- VALIDASI STATUS DEPOT
    if garageType == GarageType.DEPOT then
        if playerVehicle.state ~= VehicleState.OUT
            and playerVehicle.state ~= VehicleState.IMPOUNDED then

            exports.qbx_core:Notify(
                source,
                'Status kendaraan tidak valid untuk Impound.',
                'error'
            )

            return
        end
    end

    -- VALIDASI PROPERTIES
    if type(playerVehicle.props) ~= 'table'
        or type(playerVehicle.props.plate) ~= 'string'
        or type(playerVehicle.props.model) ~= 'number' then

        exports.qbx_core:Notify(
            source,
            'Data kendaraan tidak valid.',
            'error'
        )

        return
    end

    -- CEK APAKAH KENDARAAN SUDAH ADA DI MAP
    if garageType == GarageType.DEPOT
        and FindPlateOnServer(playerVehicle.props.plate) then

        exports.qbx_core:Notify(
            source,
            locale('error.not_impound'),
            'error'
        )

        return
    end

    -- GARAGE HOOK
    if not GaragesHooks('spawnVehicle', {
        source = source,
        vehicleId = vehicleId,
        garageName = garageName
    }) then
        return
    end

    -- PEMBAYARAN DEPOT
    local paidFrom
    local depotPrice

    if garageType == GarageType.DEPOT then
        OverrideFreeDepotPriceForOutVehicle(playerVehicle)

        depotPrice = tonumber(playerVehicle.depotPrice) or 0

        if depotPrice ~= depotPrice
            or depotPrice < 0
            or depotPrice > 100000000 then
            return
        end

        if depotPrice > 0 then
            paidFrom = payDepotPrice(player, depotPrice)

            if not paidFrom then
                exports.qbx_core:Notify(
                    source,
                    locale('error.not_enough'),
                    'error'
                )

                return
            end
        end
    end

    -- SET VEHICLE LOCK
    playerVehicle.props.lockState = 1

    local warpPed = Config.warpInVehicle and GetPlayerPed(source)

    -- SPAWN VEHICLE
    local success, netId, veh = pcall(qbx.spawnVehicle, {
        spawnSource = spawnCoords,
        model = playerVehicle.props.model,
        props = playerVehicle.props,
        warp = warpPed,
    })

    print('[qbx_garages] SPAWN DEBUG')
    print('Success:', success)
    print('Net ID:', netId)
    print('Entity:', veh)

    if not success then
        lib.print.error(
            ('[qbx_garages] Spawn error: %s'):format(tostring(netId))
        )

        if paidFrom then
            player.Functions.AddMoney(
                paidFrom,
                depotPrice,
                'depot-spawn-refund'
            )
        end

        exports.qbx_core:Notify(
            source,
            'Gagal mengeluarkan kendaraan. Periksa server console.',
            'error'
        )

        return
    end

    if not netId or not veh or veh == 0 or not DoesEntityExist(veh) then
        lib.print.error(
            ('[qbx_garages] Invalid spawn result. netId: %s, vehicle: %s'):format(
                tostring(netId),
                tostring(veh)
            )
        )

        if paidFrom then
            player.Functions.AddMoney(
                paidFrom,
                depotPrice,
                'depot-spawn-refund'
            )
        end

        exports.qbx_core:Notify(
            source,
            'Kendaraan gagal muncul. Periksa lokasi spawn.',
            'error'
        )

        return
    end

    -- SPAWNED VEHICLE HOOK
    if not GaragesHooks('spawnedVehicle', {
        source = source,
        vehicleId = vehicleId,
        vehicle = veh,
        garageName = garageName
    }) then

        exports.qbx_core:DeleteVehicle(veh)

        if paidFrom then
            player.Functions.AddMoney(
                paidFrom,
                depotPrice,
                'depot-spawn-refund'
            )
        end

        return
    end

    -- SIMPAN STATUS KENDARAAN
    Entity(veh).state:set('vehicleid', vehicleId, false)

    local saved, result = pcall(
        setVehicleStateToOut,
        vehicleId,
        veh,
        playerVehicle.modelName
    )

    if not saved or not result then
        lib.print.error(
            ('[qbx_garages] Failed to save vehicle state: %s'):format(
                tostring(result)
            )
        )

        exports.qbx_core:DeleteVehicle(veh)

        if paidFrom then
            player.Functions.AddMoney(
                paidFrom,
                depotPrice,
                'depot-spawn-refund'
            )
        end

        exports.qbx_core:Notify(
            source,
            'Gagal menyimpan status kendaraan.',
            'error'
        )

        return
    end

    -- KUNCI KENDARAAN
    if Config.doorsLocked then
        if GetResourceState('qbx_vehiclekeys') == 'started' then
            TriggerEvent(
                'qb-vehiclekeys:server:setVehLockState',
                netId,
                2
            )
        else
            SetVehicleDoorsLocked(veh, 2)
        end
    end

    -- VEHICLE KEYS
    TriggerClientEvent(
        'vehiclekeys:client:SetOwner',
        source,
        playerVehicle.props.plate
    )

    -- VEHICLE SPAWN EVENT
    TriggerEvent(
        'qbx_garages:server:vehicleSpawned',
        veh
    )

    return netId
end

-- CALLBACK SPAWN VEHICLE
lib.callback.register(
    'qbx_garages:server:spawnVehicle',
    function(source, vehicleId, garageName, accessPointIndex)

        print('========== SPAWN CALLBACK ==========')
        print('Source:', source)
        print('Vehicle ID:', vehicleId)
        print('Garage:', garageName)
        print('Access Point:', accessPointIndex)
        print('====================================')

        vehicleId = tonumber(vehicleId)

        if not vehicleId or vehicleId <= 0
            or vehicleId % 1 ~= 0
            or spawningVehicles[vehicleId] then
            return
        end

        spawningVehicles[vehicleId] = true

        local success, result = pcall(
            spawnVehicle,
            source,
            vehicleId,
            garageName,
            accessPointIndex
        )

        spawningVehicles[vehicleId] = nil

        if not success then
            lib.print.error(
                ('[qbx_garages] Spawn callback error: %s'):format(
                    tostring(result)
                )
            )

            exports.qbx_core:Notify(
                source,
                'Terjadi kesalahan pada sistem garasi.',
                'error'
            )

            return
        end

        return result
    end
)

-- OVERRIDE DEPOT PRICE
function OverrideFreeDepotPriceForOutVehicle(vehicle)
    if VehicleState.OUT ~= vehicle.state then
        return
    end

    if vehicle.depotPrice and vehicle.depotPrice > 0 then
        return
    end

    vehicle.depotPrice = Config.calculateImpoundFee(
        vehicle.id,
        vehicle.modelName
    )
end
