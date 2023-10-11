Spark.Players = {
    Players = {},
    Raw = {},

    Default = Spark:Config('Default')
}

Spark.Driver:Ready(function()
    Citizen.Await(Spark.Version.Loaded) -- Wait for the version to be printed

    local users = Spark.Driver:Query('SELECT * FROM users')
    print("Loaded " .. #users .. " user(s)!")
end)

--- Event when a user has connected.
--- @param source number?
--- @param def table
function Spark.Players:playerConnecting(source, def)
    local steam = Spark.Source:Steam(source)

    def.defer()
    Wait(0)

    -- Check if the steam identifier is valid
    if not steam then
        return def.done('Cannot find your steam')
    end

    -- Check if the user is already cached, if this occurs- there is an error in Spark.
    if self.Players[steam] then
        return def.done('You are already registered?')
    end

    -- Register/or gets data from the database
    local data = self:Authenticate(steam, source)
    if not data?.id then
        return def.done("Error while returning your data, please report this.")
    end

    -- Let the player join the server
    print('Player joined! ID: ' .. data.id .. " Steam: " .. steam .. " Source: " .. source)
    --print("Data: " .. data.data)

    -- Give scripts a way to reject users
    TriggerEvent('Spark:Connect', Spark.Players:Get("steam", steam), def)
    Wait(0)

    def.done()
end

--- Event when a user has spawned.
function Spark.Players:playerSpawned(source)
    local steam = Spark.Source:Steam(source)
    local player = self.Players[steam]

    if not player then -- Checks if the user is registered.
        return print("Player is not registered when spawned?")
    end

    if player.spawns == 0 then
        print("Player " .. player.id .. " has spawned! Updating source")
        player.source = source -- Update the source of the user, on spawn 
    end

    player.spawns = player.spawns + 1
    TriggerEvent('Spark:Spawned', Spark.Players:Get("steam", steam), player.spawns == 1)
    TriggerClientEvent('Spark:Loaded', source)
end

--- Event when a user has been dropped.
--- @param source number?
--- @param reason string
function Spark.Players:playerDropped(source, reason)
    local steam = Spark.Source:Steam(source)

    local data = self.Players[steam]
    if not data then -- Checks if the user is registered.
        return print("Player is not registered when dropped?")
    end

    TriggerEvent('Spark:Dropped', steam)

    Wait(500)

    print("User left! Steam " .. steam .. " id " .. data.id .. " source " .. source .. " reason " .. reason)
    --print("Data: " .. json.encode(data.data))

    self.Raw:Dump(steam, data.data)
    self.Players[steam] = nil
end

--- Create/ or retrive data from the database
--- @param steam string
--- @return table
function Spark.Players:Authenticate(steam, source)
    local data = self.Raw:Pull('steam', steam)

    if not data then -- If the user is not registered, it will create a account for the person
        if Spark.Driver:Execute('INSERT INTO users (steam) VALUES (?)', steam) == 1 then
            data = {
                id = self.Raw:Pull('steam', steam).id,
                steam = steam
            }
        end
    end

    data.data = data.data or json.encode(self.Default)

    self.Players[steam] = {
        id = data.id,
        data = json.decode(data.data),
        source = source,
        spawns = 0
    }

    return data
end

--- Get a user's data directly from the database.
--- @param method string
--- @param value any
--- @return table
function Spark.Players.Raw:Pull(method, value)
    return Spark.Driver:Query('SELECT * FROM users WHERE ' .. method .. ' = ?', value)[1]
end

--- Get a user's data in json directly from the database.
--- @param steam string
--- @return table
function Spark.Players.Raw:Data(steam)
    local data = self:Pull('steam', steam)
    return not data and false or json.decode(data.data or "{}")
end

--- Dump a user's data directly to the database.
--- @param steam string
--- @param data table
function Spark.Players.Raw:Dump(steam, data)
    return Spark.Driver:Execute('UPDATE users SET data = ? WHERE steam = ?', json.encode(data), steam)
end

--- Convert a id to a steam
--- @param id number
--- @return string | nil
function Spark.Players.Raw:Convert(id)
    for k,v in pairs(Spark.Players.Players) do
        if v.id == id then
            return k
        end
    end
end

--- Attach the event to the connecting function.
AddEventHandler('playerConnecting', function(_, __, def)
    local source = source
    Spark.Players:playerConnecting(source, def)
end)

--- Attach the event to the connecting function.
RegisterNetEvent('playerSpawned', function()
    local source = source
    Spark.Players:playerSpawned(source)
end)

--- Attach the event to the connecting function.
AddEventHandler('playerDropped', function(reason)
    local source = source
    Spark.Players:playerDropped(source, reason)
end)
