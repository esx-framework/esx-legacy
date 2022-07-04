--#### FX Information ####--
fx_version   'cerulean'
lua54        'yes'
game         'gta5'

--#### Resource Information ####--
name         'esx_progressbar'
version      '1.7.5'
description  'ESX Progressbar'

client_scripts { 'Progress.lua' }
shared_script '@es_extended/imports.lua'
ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/js/*.js',
    'nui/css/*.css',
    'nui/img/*.png',
}
