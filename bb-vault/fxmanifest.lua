fx_version 'bodacious'
game 'gta5'


dependencies {
    "PolyZone",
    "mka-lasers"
}

client_scripts {
    '@mka-lasers/client/client.lua',
    "@PolyZone/client.lua",
    'configs/config.lua',
    'client/mainLoop.lua',
    'client/events.lua',
    'client/nuiEvents.lua',
    'configs/languages.lua',
    'client/safeCracking.lua',
    'configs/functions.lua',
    'garbageCollector.lua',
}

server_scripts {
    'configs/config.lua',
    'server/pacificBankRobbery.lua',
    'server/events.lua',
    'server/versionCheck.lua',
    'configs/functions.lua',
    '@oxmysql/lib/MySQL.lua'
}

ui_page "client/html/index.html"

files {
    "client/html/index.html",
    "client/html/vue.min.js",
	"client/html/js/script.js",
    "client/html/css/reset.css",
    "client/html/css/style.css",
    "client/html/css/img/*.png",
}

