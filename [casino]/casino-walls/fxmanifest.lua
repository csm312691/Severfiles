fx_version 'cerulean'
games      { 'gta5' }


shared_scripts {
	'config.lua',
}


client_scripts{
	'@PolyZone/client.lua',
    	'@PolyZone/CircleZone.lua',
	'client/*.lua'
} 

server_script {
	'server/*.lua',
	'@oxmysql/lib/MySQL.lua'
   }