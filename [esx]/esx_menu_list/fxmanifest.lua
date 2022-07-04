--#### FX Information ####--
fx_version   'cerulean'
lua54        'yes'
game         'gta5'

--#### Resource Information ####--
name         'esx_menu_list'
version      '1.7.5'
description  'ESX Menu List'

client_scripts {
	'@es_extended/imports.lua',
	'@es_extended/client/wrapper.lua',
	'client/main.lua'
}

ui_page 'html/ui.html'

files {
	'html/ui.html',

	'html/css/app.css',

	'html/js/mustache.min.js',
	'html/js/app.js',

	'html/fonts/pdown.ttf',
	'html/fonts/bankgothic.ttf'
}

dependency 'es_extended'
