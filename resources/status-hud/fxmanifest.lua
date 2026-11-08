fx_version 'cerulean'
game 'gta5'

author '.fatheris'
name 'status-hud'
description 'Status HUD (Health, Armor, Food, Water etc)'
version '1.0.0'

client_scripts {
    'config.lua',
    'client.lua'
}

server_script 'server.lua'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}
