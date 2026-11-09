---Represents a function that calculates a fee based on vehicle data.
---
---The function receives a vehicle identifier and a model name,
---retrieves or derives the necessary vehicle information,
---and returns a numeric fee based on custom logic.
---
---@alias FeeCalculator fun(vehicleId: number, modelName: string): number

return {
    autoRespawn = false,   -- True == auto respawn cars that are outside into your garage on script restart, false == does not put them into your garage and players have to go to the impound
    warpInVehicle = true, -- If false, player will no longer warp into vehicle upon taking the vehicle out.
    doorsLocked = true, -- If true, the doors will be locked upon taking the vehicle out.
    distanceCheck = 5.0, -- Jarak minimum area spawn harus kosong agar kendaraan tidak bertumpuk.
    defaultGarageSlots = 10, -- Kapasitas kendaraan tersimpan per pemain pada setiap garasi.
    calculateImpoundFee = require 'server.default-calculate-impound-fee',
    logging = {
        webhook = {
            error = nil,
            default = nil,
            anticheat = nil,
        },
    },

    ---@class GarageBlip
    ---@field name? string -- Name of the blip. Defaults to garage label.
    ---@field sprite? number -- Sprite for the blip. Defaults to 357
    ---@field color? number -- Color for the blip. Defaults to 3.

    ---The place where the player can access the garage and spawn a car
    ---@class AccessPoint
    ---@field coords vector4 where the garage menu can be accessed from
    ---@field blip? GarageBlip
    ---@field spawn? vector4 where the vehicle will spawn. Defaults to coords
    ---@field dropPoint? vector3 where a vehicle can be stored, Defaults to spawn or coords
    ---@field drawRadius? number draw distance for the garage marker (default: 60)
    ---@field dropDrawRadius? number draw distance for the drop-off marker (default: 60)
    ---@field useRadius? number interaction distance for the garage marker (default: 1)
    ---@field dropUseRadius? number interaction distance for the drop-off marker (default: 1.5)

    ---@class GarageConfig
    ---@field label string -- Label for the garage
    ---@field type? GarageType -- Optional special type of garage. Currently only used to mark DEPOT garages.
    ---@field vehicleType VehicleType -- Vehicle type
    ---@field groups? string | string[] | table<string, number> job/gangs that can access the garage
    ---@field shared? boolean defaults to false. Shared garages give all players with access to the garage access to all vehicles in it. If shared is off, the garage will only give access to player's vehicles which they own.
    ---@field states? VehicleState | VehicleState[] if set, only vehicles in the given states will be retrievable from the garage. Defaults to GARAGED.
    ---@field skipGarageCheck? boolean if true, returns vehicles for retrieval regardless of if that vehicle's garage matches this garage's name
    ---@field slots? integer maximum stored vehicles. Defaults to Config.defaultGarageSlots; shared garages count globally.
    ---@field canAccess? fun(source: number): boolean checks access as an additional guard clause. Other filter fields still need to pass in addition to this function.
    ---@field accessPoints AccessPoint[]

    ---@type table<string, GarageConfig>

    garages = {
        garasikota = {
            label = 'Garasi Kota',
            vehicleType = VehicleType.CAR,
            shared = false,
            accessPoints = {
                {
                    blip = { name = 'Garasi Kota', sprite = 357, color = 3 },
                    coords = vec4(-320.63, -892.4, 30.07, 166.97),
                    spawn = vec4(-320.63, -892.4, 30.07, 166.97),
                    useRadius = 2.0,
                    dropUseRadius = 3.0,
                }
            },
        },
        garasirumahsakit = {
            label = 'Garasi Rumah Sakit',
            vehicleType = VehicleType.CAR,
            shared = false,
            accessPoints = {
                {
                    blip = { name = 'Garasi Rumah Sakit', sprite = 357, color = 3 },
                    coords = vec4(1162.47, -1496.51, 33.69, 51.26),
                    spawn = vec4(1162.47, -1496.51, 33.69, 51.26),
                    useRadius = 2.0,
                    dropUseRadius = 3.0,
                }
            },
        },
        garasigovernment = {
            label = 'Garasi Government',
            vehicleType = VehicleType.CAR,
            shared = false,
            accessPoints = {
                {
                    blip = { name = 'Garasi Government', sprite = 357, color = 3 },
                    coords = vec4(-522.01, -267.64, 34.31, 204.39),
                    spawn = vec4(-522.01, -267.64, 34.31, 204.39),
                    useRadius = 2.0,
                    dropUseRadius = 3.0,
                }
            },
        },
        garasipolisi = {
            label = 'Garasi Kantor Polisi',
            vehicleType = VehicleType.CAR,
            shared = false,
            accessPoints = {
                {
                    blip = { name = 'Garasi Kantor Polisi', sprite = 357, color = 3 },
                    coords = vec4(408.29, -992.97, 28.27, 149.98),
                    spawn = vec4(408.29, -992.97, 28.27, 149.98),
                    useRadius = 2.0,
                    dropUseRadius = 3.0,
                }
            },
        },
        garasibengkel = {
            label = 'Garasi Bengkel',
            vehicleType = VehicleType.CAR,
            shared = false,
            accessPoints = {
                {
                    blip = { name = 'Garasi Bengkel', sprite = 357, color = 3 },
                    coords = vec4(1133.97, -774.62, 56.63, 1.65),
                    spawn = vec4(1133.97, -774.62, 56.63, 1.65),
                    useRadius = 2.0,
                    dropUseRadius = 3.0,
                }
            },
        },
        garasirecycle = {
            label = 'Garasi Recycle Center',
            vehicleType = VehicleType.CAR,
            shared = false,
            accessPoints = {
                {
                    blip = { name = 'Garasi Recycle Center', sprite = 357, color = 3 },
                    coords = vec4(52.38, 6462.4, 30.43, 224.29),
                    spawn = vec4(52.38, 6462.4, 30.43, 224.29),
                    useRadius = 2.0,
                    dropUseRadius = 3.0,
                }
            },
        },
        garasibusdepot = {
            label = 'Garasi Bus Depot',
            vehicleType = VehicleType.CAR,
            shared = false,
            accessPoints = {
                {
                    blip = { name = 'Garasi Bus Depot', sprite = 357, color = 3 },
                    coords = vec4(474.77, -585.17, 27.5, 348.09),
                    spawn = vec4(474.77, -585.17, 27.5, 348.09),
                    useRadius = 2.0,
                    dropUseRadius = 3.0,
                }
            },
        },
        garasiresto = {
            label = 'Garasi Resto',
            vehicleType = VehicleType.CAR,
            shared = false,
            accessPoints = {
                {
                    blip = { name = 'Garasi Resto', sprite = 357, color = 3 },
                    coords = vec4(-1319.2, -1141.29, 3.5, 49.7),
                    spawn = vec4(-1319.2, -1141.29, 3.5, 49.7),
                    useRadius = 2.0,
                    dropUseRadius = 3.0,
                }
            },
        },
        garasicarnaval = {
            label = 'Garasi Carnaval',
            vehicleType = VehicleType.CAR,
            shared = false,
            accessPoints = {
                {
                    blip = { name = 'Garasi Carnaval', sprite = 357, color = 3 },
                    coords = vec4(-1722.13, -1121.8, 12.15, 26.77),
                    spawn = vec4(-1722.13, -1121.8, 12.15, 26.77),
                    useRadius = 2.0,
                    dropUseRadius = 3.0,
                }
            },
        },
        garasidelivery = {
            label = 'Garasi DeliveryJob',
            vehicleType = VehicleType.CAR,
            shared = false,
            accessPoints = {
                {
                    blip = { name = 'Garasi DeliveryJob', sprite = 357, color = 3 },
                    coords = vec4(-497.03, -2194.2, 5.8, 271.59),
                    spawn = vec4(-497.03, -2194.2, 5.8, 271.59),
                    useRadius = 2.0,
                    dropUseRadius = 3.0,
                }
            },
        },
        impoundlot = {
            label = 'Impound Lot',
            type = GarageType.DEPOT,
            states = { VehicleState.OUT, VehicleState.IMPOUNDED },
            skipGarageCheck = true,
            vehicleType = VehicleType.CAR,
            accessPoints = {
                {
                    blip = { name = 'Impound Lot', sprite = 68, color = 3 },
                    coords = vec4(400.45, -1630.87, 29.29, 228.88),
                    spawn = vec4(407.2, -1645.58, 29.31, 228.28),
                }
            },
        },
    },
}