local Identifiers, Groups, Jobs = {
    "steam",
    "source",
    "id"
}, Spark:Config('Groups'), Spark:Config('Jobs')

local CallbackId, MenuId, KeybindId = 0, 0, 0

--- @param method "steam" | "source" | "id"
--- @param value any
function Spark.Players:Get(method, value)
    if not Spark.Table:Contains(Identifiers, method) then
        return error("Method " .. method .. " is invalid!")
    end

    local steam, id = value, nil
    if method == "id" then
        steam, id = self.Raw:Convert(value), value
    elseif method == "source" then
        steam = self.Source:Steam(value)
    end

    id = id or self.Players[steam]?.id
    if not self.Players[steam] then
        if method == "source" then
            return false, "user_does_not_exist"
        end

        local data = self.Raw:Pull(method, value)
        if not data then
            return false, "user_cannot_be_found"
        end

        id, steam = data.id, data.steam
    end

    --- @class player
    local player = {}

    player.Data = {}

    --- @return table
    function player.Data:Raw()
        return Spark.Players.Players[steam]
    end

    --- @param key string
    --- @param value any
    --- @return boolean
    function player.Data:Set(key, value)
        if player.Is:Online() then
            self:Raw().data[key] = value
        else
            local user = Spark.Players.Raw:Data(steam)
            if not user then
                return false
            end

            user[key] = value
            Spark.Players.Raw:Dump(steam, user)
        end

        Spark.Events:Trigger('Data', player, key, value)
        return true
    end

    --- @param key string
    --- @return any
    function player.Data:Get(key)
        if player.Is:Online() then   
            return Spark.Table:Clone(self:Raw().data)[key]
        else
            local user = Spark.Players.Raw:Data(steam)

            if not user then
                return
            end

            return user[key]
        end
    end

    --- @return number
    function player:ID()
        return id
    end

    --- @return string
    function player:Steam()
        return steam
    end

    function player:Source()
        return player.Data:Raw().source
    end

    --- @return number
    function player:Ped()
        return GetPlayerPed(self:Source() or 0)
    end

    player.Is = {}

    --- @return boolean
    function player.Is:Online() return player.Data:Raw() ~= nil end

    --- @return boolean
    function player.Is:Loaded() return(player.Data:Raw()?.spawns or 0) > 0 end

    --- @param reason string
    function player:Kick(reason)
        reason = reason or ''
        DropPlayer(self:Source(), reason)
    end

    player.Client = {}

    --- @param name string
    function player.Client:Event(name, ...)
        return TriggerClientEvent(name, player:Source(), ...)
    end

    --- @param name string
    --- @return any
    function player.Client:Callback(name, ...)
        local promise = promise.new()
        local id = CallbackId + 1
        CallbackId = id

        RegisterNetEvent('Spark:Callbacks:Server:Response:'.. name .. ':' .. id, function(response)
            local source = source
            if player:Source() == source then
                promise:resolve(response)
            end
        end)

        self:Event('Spark:Callbacks:Client:Run:' .. name, id, ...)
        return Citizen.Await(promise)
    end

    player.Weapons = {}

    --- @param weapons table
    function player.Weapons:Set(weapons)
        player.Client:Callback('Spark:Update', {
            weapons = weapons
        })
    end

    --- @return table
    function player.Weapons:Get()
        return player.Client:Callback('Spark:State').weapons
    end

    player.Weapons.Attachments = {}

    --- @param attachments table
    function player.Weapons.Attachments:Set(attachments)
        player.Client:Callback('Spark:Update', {
            attachments = attachments
        })
    end

    --- @return table
    function player.Weapons.Attachments:Get()
        return player.Client:Callback('Spark:State').attachments
    end

    player.Customization = {}

    --- @param customization table
    function player.Customization:Set(customization)
        player.Client:Callback('Spark:Update', {
            customization = customization
        })
    end

    --- @return table
    function player.Customization:Get()
        return player.Client:Callback('Spark:State').customization
    end

    player.Health = {}

    --- @param health number
    function player.Health:Set(health)
        player.Client:Callback('Spark:Update', {
            health = health
        })
    end

    --- @return number
    function player.Health:Max()
        return GetEntityMaxHealth(player:Ped())
    end

    --- @return number
    function player.Health:Get()
        return GetEntityHealth(player:Ped())
    end

    player.Position = {}

    --- @param coords vector3
    function player.Position:Set(coords)
        SetEntityCoords(player:Ped(), coords.x, coords.y, coords.z, false, false, false, false)
    end

    --- @return vector3
    function player.Position:Get()
        return GetEntityCoords(player:Ped())
    end

    player.Ban = {}

    --- @param value boolean
    --- @param reason? string
    --- @return boolean
    function player.Ban:Set(value, reason)
        if not value then
            player.Data:Set('Banned', nil)
            return true
        end

        player.Data:Set('Banned', reason or '')
        if player.Is:Online() then
            player:Kick('[Banned] ' .. (reason or ''))
        end

        return true
    end

    --- @return string | boolean
    function player.Ban:Reason()
        return player.Data:Get('Banned') or false
    end

    --- @return boolean
    function player.Ban:Is()
        return player.Data:Get('Banned') ~= nil
    end

    player.Whitelist = {}

    --- @param value boolean
    function player.Whitelist:Set(value)
        return player.Data:Set('Whitelisted', value)
    end

    --- @return boolean
    function player.Whitelist:Is()
        return player.Data:Get('Whitelisted') ~= nil
    end

    --- @param text string
    function player:Notification(text)
        player.Client:Callback('Spark:Update', {
            notification = text
        })
    end

    player.Groups = {}

    --- @return table
    function player.Groups:Get()
        return player.Data:Get('Groups')
    end

    --- @param group string
    --- @return boolean
    function player.Groups:Add(group)
        local groups = self:Get()
        if self:Has(group) or not Groups[group] then -- if the user already has the group
            return false
        end

        table.insert(groups, group)
        player.Data:Set('Groups', groups)

        Spark.Events:Trigger('AddGroup', player, group)
        return true
    end

    --- @param permission string | table
    --- @return boolean
    function player.Groups:Permission(permission)
        for _, v in pairs(Groups) do
            for _, perm in pairs(type(permission) == "table" and permission or {permission}) do
                if not Spark.Table:Contains(v.permissions, perm) then
                    return false
                end
            end
        end

        return true
    end

    --- @param group string
    --- @return string
    function player.Groups:Has(group)
        return Spark.Table:Contains(self:Get(), group)
    end

    --- @param group string
    --- @return boolean
    function player.Groups:Remove(group)
        local groups = self:Get()
        if not self:Has(group) then -- if the user does not have the group
            return false
        end

        for i, v in pairs(groups) do -- find and remove the group
            if v == group then
                table.remove(groups, i)
            end
        end

        player.Data:Set('Groups', groups)
        Spark.Events:Trigger('RemoveGroup', player, group)

        return true
    end

    player.Cash = {}

    --- @return number
    function player.Cash:Get()
        return player.Data:Get('Cash')
    end

    --- @param cash number
    function player.Cash:Set(cash)
        player.Data:Set('Cash', cash)
    end

    --- @param cash number
    function player.Cash:Add(cash)
        self:Set(self:Get() + cash)
    end

    --- @param cash number
    --- @return boolean
    function player.Cash:Has(cash)
        return self:Get() >= cash
    end

    --- @param cash number
    function player.Cash:Remove(cash)
        if (self:Get() - cash) >= 0 then
            self:Set(self:Get() - cash)
        end
    end

    --- @param cash number
    --- @return boolean
    function player.Cash:Payment(cash)
        if (self:Get() - cash) < 0 then
            return false
        end

        return true, self:Set(self:Get() - cash)
    end

    player.Menu = {}

    --- @param title string
    --- @param color string
    --- @param data table
    --- @param callback fun(button: string)
    function player.Menu:Show(title, color, data, callback)
        local id = MenuId + 1
        MenuId = id

        RegisterNetEvent('Spark:Menu:' .. id, function(button)
            local source = source
            if player:Source() == source then
                callback(button)
            end
        end)

        player.Client:Callback('Spark:Menu:Show', title, color, data, id)
    end

    function player.Menu:Close()
        player.Client:Callback('Spark:Menu:Close')
    end

    --- @param name string
    --- @param key string
    --- @param callback fun()
    function player:Keybind(name, key, callback)
        local id = KeybindId + 1
        KeybindId = id

        RegisterNetEvent('Spark:Keybind:' .. id, function()
            local source = source
            if player:Source() == source then
                callback()
            end
        end)

        player.Client:Event('Spark:Keybind', name, key, id)
    end

    player.Job = {}

    --- @return table
    function player.Job:Raw()
        return player.Data:Get('Job')
    end

    --- @return string, number, number
    function player.Job:Get()
        local data = self:Raw()
        return data.job, data.grade, data.time
    end

    --- @param job string
    --- @param grade number
    --- @return boolean
    function player.Job:Set(job, grade)
        local data = Jobs[job]
        if not data then
            return false
        end

        if data.grades and not data.grades[grade] then
            return false
        end

        player.Data:Set('Job', { -- set job
            job = job,
            grade = data.grades and grade or 1,
            time = data.grades and data.grades[grade].time or data.time
        })

        Spark.Events:Trigger('Job', player, job, grade, data.grades and data.grades[grade].name or job)

        return true
    end

    return player
end