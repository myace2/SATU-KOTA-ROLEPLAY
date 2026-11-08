fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nsr-hud'
author 'NSR Store'
description 'NSR HUD Ultimate — Premium All-in-One FiveM Player HUD, Vehicle Dashboard, CarPlay & Drag-and-Drop Customization System'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'shared/constants.lua',
    'shared/utils.lua',
    'shared/validation.lua',
    'shared/locale.lua',
    'locales/en.lua',
    'locales/ar.lua',
    'locales/fr.lua',
    'locales/de.lua',
    'locales/es.lua',
    'locales/pt.lua',
    'locales/tr.lua',
    'locales/it.lua',
    'bridge/framework.lua'
}

client_scripts {
    'bridge/fuel.lua',
    'bridge/voice.lua',
    'bridge/seatbelt.lua',
    'bridge/nitro.lua',
    'bridge/vehicle_keys.lua',
    'client/modules/health.lua',
    'client/modules/status.lua',
    'client/modules/voice.lua',
    'client/modules/money.lua',
    'client/modules/job.lua',
    'client/modules/vehicle.lua',
    'client/player_hud.lua',
    'client/vehicle_hud.lua',
    'client/carplay.lua',
    'client/hud_editor.lua',
    'client/commands.lua',
    'client/main.lua'
}

server_scripts {
    'server/persistence.lua',
    'server/callbacks.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/css/main.css',
    'html/css/themes.css',
    'html/css/hud.css',
    'html/css/vehicle.css',
    'html/css/carplay.css',
    'html/css/editor.css',
    'html/js/localization.js',
    'html/js/persistence.js',
    'html/js/settings.js',
    'html/js/player-hud.js',
    'html/js/vehicle-hud.js',
    'html/js/carplay.js',
    'html/js/editor.js',
    'html/js/main.js',
    'html/assets/icons/health.svg',
    'html/assets/icons/armor.svg',
    'html/assets/icons/hunger.svg',
    'html/assets/icons/thirst.svg',
    'html/assets/icons/stamina.svg',
    'html/assets/icons/oxygen.svg',
    'html/assets/icons/stress.svg',
    'html/assets/icons/voice.svg',
    'html/assets/icons/radio.svg',
    'html/assets/icons/cash.svg',
    'html/assets/icons/bank.svg',
    'html/assets/icons/job.svg',
    'html/assets/icons/compass.svg',
    'html/assets/icons/fuel.svg',
    'html/assets/icons/engine.svg',
    'html/assets/icons/seatbelt.svg',
    'html/assets/icons/lights.svg',
    'html/assets/icons/lock.svg',
    'html/assets/icons/nitro.svg',
    'html/assets/icons/cruise.svg',
    'html/assets/icons/carplay.svg',
    'html/assets/images/nsr-logo.svg',
    'html/assets/images/car-topdown.svg'
}

escrow_ignore {
    'config.lua',
    'locales/*.lua',
    'bridge/*.lua'
}
dependency '/assetpacks'