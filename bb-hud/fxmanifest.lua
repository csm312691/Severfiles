fx_version 'cerulean'
game 'gta5'


client_script 'config.lua'
client_script 'client.lua'

server_script {
	'server.lua',
	'@oxmysql/lib/MySQL.lua'
}

lua54 'yes'

ui_page 'html/index.html'

files {
	'html/index.html',
	'html/styles.css',
	'html/responsive.css',
	'html/app.js',
}
