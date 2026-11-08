--[[
    ============================================================================
    NSR HUD ULTIMATE — MASTER CONFIGURATION FILE (config.lua)
    Commercial Release v1.0.0 | NSR Store
    ============================================================================
    IMPORTANT NOTES:
    1. Language selection is controlled EXCLUSIVELY via `Config.Locale` below.
       There is NO language selector inside the NUI by design.
    2. Framework detection supports: 'auto', 'qbcore', 'qbox', 'esx', 'standalone'.
    3. All optional integrations fail safely if the target resource is absent.
]]

Config = Config or {}

-- ============================================================================
-- 1. CORE FRAMEWORK & LOCALIZATION
-- ============================================================================

-- Supported values: 'auto' | 'qbcore' | 'qbox' | 'esx' | 'standalone'
Config.Framework = 'auto'

-- Supported values: 'en' | 'ar' | 'fr' | 'de' | 'es' | 'pt' | 'tr' | 'it'
-- Selecting 'ar' automatically activates Right-to-Left (RTL) layout across the entire HUD.
Config.Locale = 'en'

-- Enable verbose diagnostic logs in client F8 and server console
Config.Debug = false

-- ============================================================================
-- 2. PERSISTENCE & STORAGE
-- ============================================================================

Config.Persistence = {
    -- Supported values:
    -- 'auto'    : Uses 'oxmysql' if started, otherwise falls back to server JSON file storage
    -- 'oxmysql' : Stores player profiles in MySQL table `nsr_hud_profiles` via oxmysql
    -- 'json'    : Stores player profiles in server file `data/player_profiles.json`
    -- 'kvp'     : Stores preferences in client ResourceKvp with server validation
    Provider = 'auto',

    -- SQL table name used when Provider resolves to 'oxmysql'
    TableName = 'nsr_hud_profiles',

    -- Automatically execute `CREATE TABLE IF NOT EXISTS` on server startup when using oxmysql
    AutoCreateTable = true,

    -- JSON file path inside resource folder when Provider resolves to 'json'
    JsonFilePath = 'data/player_profiles.json',

    -- Minimum cooldown in milliseconds between player profile save requests (anti-spam)
    SaveCooldownMs = 2000,

    -- Maximum number of named personal presets each player may store
    MaxPersonalPresets = 5
}

-- ============================================================================
-- 3. COMMANDS & KEYBINDS
-- ============================================================================

Config.Commands = {
    HUD = 'hud',                 -- Opens the Drag-and-Drop HUD Editor & Customization menu
    ToggleHUD = 'togglehud',     -- Quickly toggles master HUD visibility
    VehicleHUD = 'vehiclehud',   -- Cycles or opens Vehicle HUD settings when inside a vehicle
    CarPlay = 'carplay',         -- Opens the NSR CarPlay in-vehicle infotainment tablet
    Seatbelt = 'seatbelt',       -- Toggles seatbelt (when built-in seatbelt is active)
    Cruise = 'cruise',           -- Toggles cruise control limiter (driver only)
    ResetHUD = 'resethud'        -- Immediately resets HUD layout to server defaults
}

Config.Keybinds = {
    EnableKeymapping = true,
    OpenEditor = 'F7',           -- Default keybind to open HUD Editor
    OpenCarPlay = 'U',           -- Default keybind to open NSR CarPlay in a vehicle
    ToggleSeatbelt = 'B',        -- Default keybind to buckle/unbuckle seatbelt
    ToggleCruise = 'Y',          -- Default keybind to toggle cruise control
    IndicatorLeft = 'LEFT',      -- Left turn signal keybind (optional)
    IndicatorRight = 'RIGHT',    -- Right turn signal keybind (optional)
    IndicatorHazard = 'BACK'     -- Hazard lights keybind (optional)
}

-- ============================================================================
-- 4. APPEARANCE & THEME PRESETS
-- ============================================================================

Config.DefaultTheme = 'midnight' -- 'midnight' | 'neon' | 'minimal' | 'sport' | 'luxury' | 'tactical'

Config.Themes = {
    midnight = {
        id = 'midnight',
        labelKey = 'theme.midnight',
        primary = '#00E5FF',
        secondary = '#3B82F6',
        accent = '#38BDF8',
        surface = 'rgba(11, 15, 25, 0.86)',
        border = 'rgba(0, 229, 255, 0.24)'
    },
    neon = {
        id = 'neon',
        labelKey = 'theme.neon',
        primary = '#FF2A85',
        secondary = '#00FF9D',
        accent = '#A855F7',
        surface = 'rgba(15, 9, 24, 0.88)',
        border = 'rgba(255, 42, 133, 0.30)'
    },
    minimal = {
        id = 'minimal',
        labelKey = 'theme.minimal',
        primary = '#F8FAFC',
        secondary = '#94A3B8',
        accent = '#E2E8F0',
        surface = 'rgba(18, 19, 22, 0.84)',
        border = 'rgba(248, 250, 252, 0.18)'
    },
    sport = {
        id = 'sport',
        labelKey = 'theme.sport',
        primary = '#EF4444',
        secondary = '#F59E0B',
        accent = '#F97316',
        surface = 'rgba(17, 17, 19, 0.88)',
        border = 'rgba(239, 68, 68, 0.28)'
    },
    luxury = {
        id = 'luxury',
        labelKey = 'theme.luxury',
        primary = '#D4AF37',
        secondary = '#A67C52',
        accent = '#FDE68A',
        surface = 'rgba(20, 18, 15, 0.88)',
        border = 'rgba(212, 175, 55, 0.28)'
    },
    tactical = {
        id = 'tactical',
        labelKey = 'theme.tactical',
        primary = '#10B981',
        secondary = '#EAB308',
        accent = '#34D399',
        surface = 'rgba(10, 18, 14, 0.88)',
        border = 'rgba(16, 185, 129, 0.26)'
    }
}

-- ============================================================================
-- 5. PLAYER HUD CONFIGURATION
-- ============================================================================

Config.PlayerHUD = {
    Enabled = true,
    HideRadarOnFoot = false,     -- Set true to hide minimap when not in a vehicle
    HideNativeComponents = true, -- Hide default GTA V cash, area name, street name, and health bars
    CinematicBarsHeight = 12,    -- Percentage height of top/bottom black bars in cinematic mode
    TimeSource = 'game',         -- 'game' (in-game clock) or 'real' (player local time)
    CurrencySymbol = '$',
    CurrencyPosition = 'prefix', -- 'prefix' ($1,000) or 'suffix' (1,000$)

    -- Automatically pack visible bottom-row status rings side-by-side to the right of the minimap
    -- so there is never any overlap with the radar and never any empty gap when armor/stamina/oxygen hide.
    AutoCompactStatusRow = true,

    -- Default settings and positions (x, y in screen percentage 0.0 - 100.0) for every widget
    -- Always-visible status rings (health, hunger, thirst, voice) are placed first at 16.5%..26.4%
    -- right beside the minimap with zero gaps, followed by conditional rings (armor, stamina, oxygen, stress).
    Widgets = {
        health = {
            enabled = true,
            style = 'ring',      -- 'ring' | 'bar' | 'pill' | 'hex' | 'minimal'
            x = 16.5,
            y = 92.0,
            scale = 1.0,
            opacity = 0.95,
            color = '#EF4444',
            showIcon = true,
            showLabel = false,
            showValue = true,
            autoHideAbove = 101
        },
        hunger = {
            enabled = true,
            style = 'ring',
            x = 19.8,
            y = 92.0,
            scale = 1.0,
            opacity = 0.95,
            color = '#F59E0B',
            showIcon = true,
            showLabel = false,
            showValue = true,
            autoHideAbove = 101
        },
        thirst = {
            enabled = true,
            style = 'ring',
            x = 23.1,
            y = 92.0,
            scale = 1.0,
            opacity = 0.95,
            color = '#06B6D4',
            showIcon = true,
            showLabel = false,
            showValue = true,
            autoHideAbove = 101
        },
        voice = {
            enabled = true,
            style = 'ring',
            x = 26.4,
            y = 92.0,
            scale = 1.0,
            opacity = 0.95,
            color = '#00E5FF',
            showIcon = true,
            showLabel = false,
            showValue = true
        },
        armor = {
            enabled = true,
            style = 'ring',
            x = 29.7,
            y = 92.0,
            scale = 1.0,
            opacity = 0.95,
            color = '#3B82F6',
            showIcon = true,
            showLabel = false,
            showValue = true,
            autoHideBelow = 1
        },
        stamina = {
            enabled = true,
            style = 'ring',
            x = 33.0,
            y = 92.0,
            scale = 1.0,
            opacity = 0.95,
            color = '#10B981',
            showIcon = true,
            showLabel = false,
            showValue = true,
            autoHideAbove = 99
        },
        oxygen = {
            enabled = true,
            style = 'ring',
            x = 36.3,
            y = 92.0,
            scale = 1.0,
            opacity = 0.95,
            color = '#38BDF8',
            showIcon = true,
            showLabel = false,
            showValue = true,
            autoHideAbove = 99
        },
        stress = {
            enabled = true,
            style = 'ring',
            x = 39.6,
            y = 92.0,
            scale = 1.0,
            opacity = 0.95,
            color = '#A855F7',
            showIcon = true,
            showLabel = false,
            showValue = true,
            autoHideBelow = 1
        },
        playerid = {
            enabled = true,
            style = 'pill',
            x = 84.0,
            y = 2.2,
            scale = 1.0,
            opacity = 0.92,
            color = '#00E5FF',
            showIcon = true,
            showLabel = true,
            showValue = true
        },
        cash = {
            enabled = true,
            style = 'pill',
            x = 84.0,
            y = 6.2,
            scale = 1.0,
            opacity = 0.92,
            color = '#10B981',
            showIcon = true,
            showLabel = true,
            showValue = true
        },
        bank = {
            enabled = true,
            style = 'pill',
            x = 84.0,
            y = 10.2,
            scale = 1.0,
            opacity = 0.92,
            color = '#3B82F6',
            showIcon = true,
            showLabel = true,
            showValue = true
        },
        job = {
            enabled = true,
            style = 'pill',
            x = 84.0,
            y = 14.2,
            scale = 1.0,
            opacity = 0.92,
            color = '#F59E0B',
            showIcon = true,
            showLabel = true,
            showValue = true
        },
        compass = {
            enabled = true,
            style = 'pill',
            x = 44.0,
            y = 2.0,
            scale = 1.0,
            opacity = 0.92,
            color = '#00E5FF',
            showIcon = true,
            showLabel = true,
            showValue = true
        },
        location = {
            enabled = true,
            style = 'pill',
            x = 1.6,
            y = 74.5,
            scale = 1.0,
            opacity = 0.92,
            color = '#38BDF8',
            showIcon = true,
            showLabel = true,
            showValue = true
        },
        clock = {
            enabled = true,
            style = 'pill',
            x = 91.5,
            y = 2.2,
            scale = 1.0,
            opacity = 0.92,
            color = '#E2E8F0',
            showIcon = false,
            showLabel = false,
            showValue = true
        }
    }
}

-- ============================================================================
-- 6. ADVANCED VEHICLE HUD CONFIGURATION
-- ============================================================================

Config.Vehicle = {
    Enabled = true,
    AlwaysVisibleOnFoot = false, -- Keep false so Vehicle HUD only displays while inside a vehicle
    SpeedUnit = 'kmh',           -- 'kmh' | 'mph'
    -- Supported presets: 'nfs_heat' | 'nfs_unbound' | 'nfs_mostwanted' | 'cyber_digital' | 'analog_classic' | 'sport_gt' | 'minimal_strip'
    DefaultPreset = 'aggressive', -- 'aggressive' | 'modern' | 'circle' | 'simple_racing' | 'simple' | 'sport' | 'nfs_heat'
    RedlineThreshold = 0.82,     -- RPM threshold (0.0 - 1.0) where redline shift warning activates
    EnableAnimations = true,
    EnableTurnSignalKeys = true, -- Allow arrow keys / backspace to toggle indicators

    -- Default cluster position & styling
    Position = {
        x = 82.0,
        y = 73.0,
        scale = 1.0,
        opacity = 0.96,
        primaryColor = '#00E5FF',
        secondaryColor = '#3B82F6',
        accentColor = '#EF4444'
    },

    -- Sub-module visibility flags
    ShowRPM = true,
    ShowGear = true,
    ShowFuel = true,
    ShowEngineHealth = true,
    ShowBodyHealth = true,
    ShowSeatbelt = true,
    ShowLights = true,
    ShowIndicators = true,
    ShowHandbrake = true,
    ShowLocks = true,
    ShowNitro = true,
    ShowCruise = true,
    ShowAltitude = true,         -- Automatically shown on aircraft/helicopters

    -- Built-in Seatbelt configuration (used when Integrations.Seatbelt == 'builtin' or 'auto' fallback)
    Seatbelt = {
        Enabled = true,
        PreventExitWhenBuckled = true,
        EjectSpeedThresholdKmh = 95.0,
        MinDecelerationForEject = 42.0,
        UnbuckledWarningSound = false
    },

    -- Built-in Cruise Control configuration
    CruiseControl = {
        Enabled = true,
        MinSpeedKmh = 20.0,
        MaxSpeedKmh = 240.0
    }
}

-- ============================================================================
-- 7. NSR CARPLAY CONFIGURATION
-- ============================================================================

Config.CarPlay = {
    Enabled = true,
    AllowPassengerAccess = true,  -- Passengers can view CarPlay, Radio, and Navigation
    DriverOnlyControls = true,    -- Restrict Engine, Doors, Lights, and Locks strictly to the driver
    MaxSeatSwitchSpeedKmh = 5.0,  -- Max vehicle speed allowed when switching seats inside CarPlay

    -- Enable or disable individual CarPlay applications
    Apps = {
        home = true,
        radio = true,
        navigation = true,
        telemetry = true,
        controls = true,
        settings = true
    }
}

-- Quick GPS Waypoint presets displayed inside the CarPlay Navigation app
Config.NavigationLocations = {
    { id = 'legion',    labelKey = 'nav.loc_legion',    x = 215.76,   y = -810.12,  category = 'city' },
    { id = 'pd',        labelKey = 'nav.loc_pd',        x = 428.23,   y = -984.28,  category = 'emergency' },
    { id = 'hospital',  labelKey = 'nav.loc_hospital',  x = 298.68,   y = -584.50,  category = 'emergency' },
    { id = 'customs',   labelKey = 'nav.loc_customs',   x = -356.20,  y = -134.80,  category = 'service' },
    { id = 'airport',   labelKey = 'nav.loc_airport',   x = -1037.74, y = -2737.81, category = 'travel' },
    { id = 'sandy',     labelKey = 'nav.loc_sandy',     x = 1853.20,  y = 3686.50,  category = 'county' },
    { id = 'paleto',    labelKey = 'nav.loc_paleto',    x = -142.50,  y = 6356.10,  category = 'county' }
}

-- ============================================================================
-- 8. OPTIONAL INTEGRATIONS
-- ============================================================================

Config.Integrations = {
    -- Fuel: 'auto' | 'ox_fuel' | 'LegacyFuel' | 'cdn-fuel' | 'ps-fuel' | 'qb-fuel' | 'native'
    Fuel = 'auto',

    -- Voice: 'auto' | 'pma-voice' | 'saltychat' | 'mumble-voip' | 'native'
    Voice = 'auto',

    -- Seatbelt: 'auto' | 'builtin' | 'qbx_seatbelt' | 'qb-smallresources' | 'disabled'
    Seatbelt = 'auto',

    -- Nitro: 'auto' | 'statebag' | 'jg-mechanic' | 'qb-mechanicjob' | 'disabled'
    Nitro = 'auto',

    -- Vehicle Keys / Locks: 'auto' | 'qbx_vehiclekeys' | 'qb-vehiclekeys' | 'qs-vehiclekeys' | 'wasabi_carlock' | 'native'
    VehicleKeys = 'auto',

    -- Stress: 'auto' | 'statebag' | 'qb-hud' | 'disabled'
    Stress = 'auto'
}

-- ============================================================================
-- 9. PERFORMANCE & UPDATE INTERVALS
-- ============================================================================

Config.Performance = {
    AdaptiveUpdates = true,
    PlayerUpdateInterval = 250,       -- Active player HUD check interval (ms)
    PlayerIdleInterval = 800,         -- Interval when player values are unchanged (ms)
    VehicleUpdateInterval = 60,       -- Active vehicle dashboard telemetry interval (ms)
    VehicleSlowUpdateInterval = 500,  -- Low-frequency vehicle checks (locks, doors, lights) (ms)
    LocationUpdateInterval = 600,     -- Street name, zone, and compass update interval (ms)
    DeltaThreshold = 0.5,             -- Minimum numeric change required to trigger NUI update
    DebugOverlay = false              -- Show performance telemetry counter in debug mode
}

-- ============================================================================
-- 10. SECURITY & PERMISSIONS
-- ============================================================================

Config.Security = {
    ValidateServerVehicleActions = true,
    RestrictDriverControls = true,
    MaxPayloadLengthBytes = 32768,
    AdminAcePermission = 'nsr.hud.admin'
}
