if not ESX then
	SetTimeout(3000, print('[^3WARNING^7] Unable to start Multicharacter - your version of ESX is not compatible '))
elseif ESX.GetConfig().Multichar == true then
	local fetchCharacters = -1
	local IdentifierTables = {}
	
	-- enter the name of your database here
	Config.Database = 'es_extended'
	-- enter a prefix to prepend to all user identifiers (keep it short)
	Config.Prefix = 'char'
	
	RegisterCommand('varchar', function(source)
		if source == 0 then
			if next(IdentifierTables) == nil then print('	Unable to update your tables - have you defined the correct database?') return end
			for _, itable in pairs(IdentifierTables) do
				print('Setting `'..itable.table..'` column `'..itable.column..'` to VARCHAR(60)')
				MySQL.Sync.execute("ALTER TABLE "..itable.table.." MODIFY COLUMN "..itable.column.." VARCHAR(60)", {})
			end
			Citizen.Wait(100)
			print('	Updated your tables to use the correct field length - you should remove this command')
		end
	end, true)

	SetupCharacters = function(playerId)
		while fetchCharacters == -1 do Citizen.Wait(100) end
		local identifier = Config.Prefix..'%:'..ESX.GetIdentifier(playerId)
		MySQL.Async.fetchAll(fetchCharacters, {'identifier', {identifier}
		}, function(result)
			local characters = {}
			for i=1, #result, 1 do
				local job, grade = result[i].job or 'unemployed', tostring(result[i].job_grade)
				if ESX.Jobs[job] and ESX.Jobs[job].grades[grade] then
					if job ~= 'unemployed' then grade = ESX.Jobs[job].grades[grade].label else grade = '' end
					job = ESX.Jobs[job].label
				end
				local accounts = json.decode(result[i].accounts)
				local id = tonumber(string.sub(result[i].identifier, #Config.Prefix+1, string.find(result[i].identifier, ':')-1))
				characters[id] = {
					id = id,
					bank = accounts.bank,
					money = accounts.money,
					job = job,
					job_grade = grade,
					firstname = result[i].firstname,
					lastname = result[i].lastname,
					dateofbirth = result[i].dateofbirth,
					skin = json.decode(result[i].skin)
				}
				if result[i].sex == 'm' then characters[id].sex = 'Male' else characters[id].sex = 'Female' end
			end
			TriggerClientEvent('esx_multicharacter:SetupUI', playerId, characters)
		end)
	end

	DeleteCharacter = function(playerId, charid)
		local identifier = Config.Prefix..charid..':'..ESX.GetIdentifier(playerId)
		for _, itable in pairs(IdentifierTables) do
			MySQL.Async.execute("DELETE FROM "..itable.table.." WHERE "..itable.column.." = @identifier", {
				['@identifier'] = identifier
			})
		end
	end

	Citizen.CreateThread(function()
		MySQL.ready(function ()
			fetchCharacters = MySQL.Sync.store("SELECT `identifier`, `accounts`, `job`, `job_grade`, `firstname`, `lastname`, `dateofbirth`, `sex`, `skin` FROM `users` WHERE ?? LIKE ?")

			MySQL.Async.fetchAll('SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = @id AND TABLE_SCHEMA = @db', { ['@id'] = "owner", ["@db"] = Config.Database}, function(result)
				if result then
					for k, v in pairs(result) do
						IdentifierTables[#IdentifierTables+1] = {table = v.TABLE_NAME, column = 'owner'}
					end
				end
			end)
			MySQL.Async.fetchAll('SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = @id AND TABLE_SCHEMA = @db', { ['@id'] = "identifier", ["@db"] = Config.Database}, function(result)
				if result then
					for k, v in pairs(result) do
						IdentifierTables[#IdentifierTables+1] = {table = v.TABLE_NAME, column = 'identifier'}
					end
				end
			end)
		end)
		if not next(ESX.Jobs) then ESX.Jobs = GetJobs() end
	end)

	RegisterServerEvent("esx_multicharacter:SetupCharacters")
	AddEventHandler('esx_multicharacter:SetupCharacters', function()
		SetupCharacters(source)
	end)

	local awaitingRegistration = {}
	RegisterServerEvent("esx_multicharacter:CharacterChosen")
	AddEventHandler('esx_multicharacter:CharacterChosen', function(charid, isNew)
		local src = source
		if type(charid) == 'number' and string.len(charid) <= 2 and type(isNew) == 'boolean' then
			if isNew then
				awaitingRegistration[src] = charid
			else
				TriggerEvent('esx:onPlayerJoined', src, Config.Prefix..charid)
			end
		else
			-- Trigger Ban Event here to ban individuals trying to use SQL Injections
		end
	end)

	AddEventHandler('esx_identity:completedRegistration', function(playerId, data)
		TriggerEvent('esx:onPlayerJoined', playerId, Config.Prefix..awaitingRegistration[playerId], data)
		awaitingRegistration[playerId] = nil
	end)

	AddEventHandler('playerDropped', function(reason)
		awaitingRegistration[source] = nil
	end)

	RegisterServerEvent("esx_multicharacter:DeleteCharacter")
	AddEventHandler('esx_multicharacter:DeleteCharacter', function(charid)
		local src = source
		if type(charid) == "number" and string.len(charid) <= 2 then
			DeleteCharacter(src, charid)
			SetupCharacters(src)
		else
			-- Trigger Ban Event here to ban individuals trying to use SQL Injections
		end
	end)

	RegisterServerEvent("esx_multicharacter:relog")
	AddEventHandler('esx_multicharacter:relog', function()
		local src = source
		TriggerEvent('esx:playerLogout', src)
	end)

	RegisterCommand('forcelog', function(source, args, rawCommand)
		TriggerEvent('esx:playerLogout', source)
	end, true)

elseif ESX.GetConfig().Multichar == false then
	SetTimeout(3000, print('[^3WARNING^7] Multicharacter is disabled - please check your ESX configuration'))
end