RegisterNetEvent('Spark:Spawned', function(source, first)
    local player = Spark.Players:Get("source", source)
    local coords = player.Data:Get('Coords')
    if first then
        player.Set:Position(coords.x, coords.y, coords.z)

        player.Set:Customization(player.Data:Get('Customization')) -- set the player's skin
        player.Set:Weapons(player.Data:Get('Weapons')) -- set the player's weapon

        player.Set:Health(player.Data:Get('Health')) -- set the player's health

        CreateThread(function() -- save weapons
            while true do
                if not player.Is:Loaded() then
                    return
                end

                local data = player.Client:Callback('Spark:State')
                player.Data:Set('Customization', data.customization)
                player.Data:Set('Weapons', data.weapons)

                Wait(5 * 1000) -- 5 seconds
            end
        end)
    else
        coords = Spark.Players.Default.Coords
        player.Set:Position(coords.x, coords.y, coords.z)

        player.Set:Customization(player.Data:Get('Customization'))
        player.Set:Health(player.Get:Max())

        player.Data:Set('Weapons', {})
    end

    print(player, first)
end)

RegisterNetEvent('Spark:Dropped', function(steam)
    local player = Spark.Players:Get("source", player)
    if player.Get:Source() == 0 then
        return
    end

    local coords = player.Get:Position()


    --print(coords)

    player.Data:Set('Coords', {x = coords.x, y = coords.y, z = coords.z})
    player.Data:Set('Health', player.Get:Health())

    --Wait(250)
    --print(json.encode(Spark.Players.Players[player.Get:Steam()].data))
    --print("SET DATA?")
end)