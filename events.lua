---@class EventLibrary
local lib = {}
---@type table<defines.events, function[]>
local events = {}
---@type function[]
local inits = {}
---@type function[]
local configs = {}
---@type function[]
local loads = {}
---@type table<int, function[]>
local nths = {}

---@param event EventData|EventData[]|string|string[]
---@param fun fun(param1: EventData)
function lib.on_event(event, fun)
    if type(event) ~= "table" then event = {event} end
    for _, id in pairs(event) do
        local handlers = events[id] or {}
        handlers[#handlers+1] = fun
        events[id] = handlers
        script.on_event(id, function(e)
            for _, handler in pairs(handlers) do
                handler(e)
            end
        end)
    end
end

---@param fun function
function lib.on_init(fun)
    inits[#inits+1] = fun
    script.on_init(function()
        for _, init in pairs(inits) do
            init()
        end
    end)
end

---@param fun function
function lib.on_configuration_changed(fun)
    configs[#configs+1] = fun
    script.on_configuration_changed(function()
        for _, config in pairs(configs) do
            config()
        end
    end)
end

---@param fun function
function lib.on_load(fun)
    loads[#loads+1] = fun
    script.on_load(function()
        for _, load in pairs(loads) do
            load()
        end
    end)
end

---@param n integer
---@param fun function
function lib.on_nth_tick(n, fun)
    handlers = nths[n] or {}
    handlers[#handlers+1] = fun
    nths[n] = handlers
    script.on_event(event, function(e)
        for _, handler in pairs(handlers) do
            handler(e)
        end
    end)
end

return lib