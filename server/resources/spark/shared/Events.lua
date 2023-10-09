Spark.Events = {}

--- Register a event with the Spark wrapper
--- @param name string
--- @param callback function
function Spark.Events:Register(name, callback)
    RegisterNetEvent(name)
    self:Handle(name, callback)
end

--- Handle a event with the Spark wrapper
--- @param name string
--- @param callback function
function Spark.Events:Handle(name, callback)
    AddEventHandler(name, function(...)
        if IsDuplicityVersion() then
            local player, source = nil, source
            if source ~= "" then
                player = Spark.Players:Get('source', source)
            end

            pcall(function(...)
                return callback(...)
            end, player, ...)
        else
            callback(...)
        end
    end)
end