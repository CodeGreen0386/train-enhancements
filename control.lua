local glib = require("gui")
local const = require("const")
local e = defines.events
local handlers = {}

local function setup_globals()
    global.flags = global.flags or {}
    global.stops = global.stops or {}
    for index in pairs(game.players) do
        global.flags[index] = {}
    end
end

script.on_init(setup_globals)
script.on_configuration_changed(setup_globals)

script.on_event(e.on_player_created, function(event)
    global.flags[event.player_index] = {}
end)

script.on_event(e.on_player_removed, function (event)
    global.flags[event.player_index] = nil
end)

local function get_player_setting(player, setting)
    return settings.get_player_settings(player)[setting].value
end

---@param vehicle LuaEntity?
---@return LuaTrain?
local function get_train(vehicle)
    if not vehicle then return end
    return vehicle.train
end

---@param train LuaTrain
---@param manual? boolean
local function toggle_manual_mode(train, manual)
    if #train.locomotives == 0 then return end
    train.manual_mode = manual or not train.manual_mode
end

---@param train LuaTrain
---@param player? LuaPlayer
---@param create_at_cursor? boolean
local function manual_mode_text(train, player, create_at_cursor)
    local fun = player and player.create_local_flying_text or train.front_stock.surface.create_entity
    fun{
        name = "flying-text",
        text = train.manual_mode and {"gui-train.manual-mode"} or {"gui-train.automatic-mode"},
        position = train.front_stock.position,
        create_at_cursor = create_at_cursor,
    }
end

-- Manual Override --

---@diagnostic disable-next-line
script.on_event({"te-up", "te-down", "te-left", "te-right"}, function(event)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    if player.render_mode ~= defines.render_mode.game then return end
    local train = get_train(player.vehicle)
    if not train then return end
    if train.manual_mode then return end
    train.manual_mode = true
    global[event.player_index] = train.id
    manual_mode_text(train, player, true)
end)

script.on_event(e.on_player_driving_changed_state, function(event)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    if not get_player_setting(player, "te_restore_automatic") then return end
    local entity = event.entity
    if player.vehicle == entity then return end
    local train = get_train(entity)
    if not train then return end
    if not train.manual_mode then return end
    if train.id ~= global[event.player_index] then return end
    train.manual_mode = false
    global[event.player_index] = nil
    manual_mode_text(train, player)
end)

-- Toggle Selected / Planner --

script.on_event("te-toggle-automatic", function(event)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    local train = get_train(player.selected)
    local create_at_cursor = false
    -- if not train and player.render_mode == defines.render_mode.game then
    --     train = get_train(player.vehicle)
    --     create_at_cursor = true
    -- end
    if train then
        train.manual_mode = not train.manual_mode
        manual_mode_text(train, player, create_at_cursor)
    else
        if not player.clear_cursor() then return end
        player.cursor_stack.set_stack("te-selection-tool")
        player.play_sound{path = "utility/item_spawned"}
    end
end)

---@param event EventData.on_player_selected_area|EventData.on_player_alt_selected_area|EventData.on_player_reverse_selected_area
---@param mnanual boolean|nil
local function selected_area(event, mnanual)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    if event.item ~= "te-selection-tool" then return end
    local checked = {}
    for _, entity in pairs(event.entities) do
        local train = entity.train --[[@as LuaTrain]]
        if checked[train.id] then goto continue end
        toggle_manual_mode(train, mnanual)
        manual_mode_text(train, player)
        checked[train.id] = true
        ::continue::
    end
end

script.on_event(e.on_player_selected_area, function(event) selected_area(event, false) end)
script.on_event(e.on_player_alt_selected_area, function(event) selected_area(event, true) end)
script.on_event(e.on_player_reverse_selected_area, function(event) selected_area(event, nil) end)

-- Temporary Stop Overwrite / Wait Conditions --

script.on_event(e.on_train_changed_state, function(event)
    -- if not settings.global["te-temporary-manual"].value then return end
    local train = event.train
    if not train.valid then return end
    if train.state ~= defines.train_state.wait_station then return end
    local schedule = train.schedule
    if not schedule then return end
    local records, current = schedule.records, schedule.current
    if not records[current].temporary then return end
    if false then -- switch to manual at temp stops
        train.manual_mode = true
        table.remove(records, current)
        if #records == 0 then schedule = nil end
        manual_mode_text(train)
    end
    train.schedule = schedule
end)

local function temporary_conditions(record)
    if not record.temporary then return end
    record.wait_conditions = {{
        type = "time",
        compare_type = "and",
        ticks = 60 * 5,
    },{
        type = "passenger_present",
        compare_type = "and",
    }}
end

script.on_event(e.on_train_schedule_changed, function(event)
    if not event.player_index then return end
    local flags = global.flags[event.player_index]
    local train = event.train
    local schedule = train.schedule
    if not schedule then return end
    local records = schedule.records
    local current = schedule.current
    local next_record = records[current+1]
    if next_record and next_record.temporary and records[current].temporary then
        if flags.temporary then
            flags.temporary = nil
            table.remove(records, current)
        else
            flags.temporary = true
        end
    end
    temporary_conditions(records[current])
    train.schedule = schedule
end)

-- Mass Station Rename --

function handlers.rename_button(event)
    local index = event.player_index
    local player = game.get_player(index) --[[@as LuaPlayer]]
    local name = player.opened.backer_name
    for _, stop in pairs(global.stops[index]) do
        if not stop.valid then break end
        stop.backer_name = name
    end
    player.gui.relative.te_rename.destroy()
end

glib.add_handlers(handlers)

script.on_event(e.on_entity_renamed, function(event)
    local entity = event.entity
    if entity.type ~= "train-stop" then return end
    if event.by_script then return end
    local index = event.player_index ---@cast index -nil
    local player = game.get_player(index) --[[@as LuaPlayer]]
    if player.opened ~= entity then return end
    global.flags[index].rename = true
    if player.gui.relative.te_rename then return end
    local stops = game.get_train_stops{name = event.old_name, force = player.force}
    if #stops == 0 then return end
    global.stops[index] = stops
    glib.add(player.gui.relative, {
        args = {type = "frame", name = "te_rename", style = "quick_bar_window_frame", anchor = {
            gui = defines.relative_gui_type.train_stop_gui,
            position = defines.relative_gui_position.top,
        }},
        children = {{
            args = {type = "frame", style = "inside_deep_frame"},
            children = {{
                args = {type = "button", caption = "Rename all \"" .. event.old_name .. "\"", style = "te_rename_button"},
                handlers = {[e.on_gui_click] = handlers.rename_button}
            }}
        }}
    })
end)

script.on_event(e.on_gui_closed, function (event)
    if event.gui_type ~= defines.gui_type.entity then return end
    if event.entity.type ~= "train-stop" then return end
    local index = event.player_index
    local player = game.get_player(index) --[[@as LuaPlayer]]
    if player.opened == event.entity then return end
    if global.flags[index].rename then
        global.flags[index].rename = nil
        return
    end
    local element = player.gui.relative.te_rename
    if not element then return end
    element.destroy()
end)

-- Auto Mine Signals --

local signal_positions = const.signal_positions
script.on_event(e.on_player_mined_entity, function(event)
    local entity = event.entity
    if not signal_positions[entity.type] then return end
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    local signals = {}
    for _, signal_data in pairs(signal_positions[entity.type][entity.direction]) do
        local offset = {entity.position.x + signal_data.x, entity.position.y + signal_data.y}
        signals[#signals+1] = entity.surface.find_entities_filtered{
            type = {"rail-signal", "rail-chain-signal"},
            position = offset,
            direction = signal_data.direction,
            limit = 1,
        }[1]
    end
    for _, signal in pairs(signals) do
        local rails = signal.get_connected_rails()
        if #rails < 2 then
            player.mine_entity(signal)
        end
    end
end)

-- Toggle Block Visualization --

script.on_event("te-block-toggle", function(event)
    local gvs = game.get_player(event.player_index).game_view_settings
    gvs.show_rail_block_visualisation = not gvs.show_rail_block_visualisation
end)

-- Rolling Stock Rotation --

script.on_event("te-rotate", function(event)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    local selected = player.selected
    if not (selected and selected.train) then return end
    if #selected.train.carriages == 1 then return end
    if not selected.rotatable then return end
    selected.disconnect_rolling_stock(defines.rail_direction.front)
    selected.disconnect_rolling_stock(defines.rail_direction.back)
    selected.rotate{by_player = player}
    selected.connect_rolling_stock(defines.rail_direction.front)
    selected.connect_rolling_stock(defines.rail_direction.back)
end)

-- Default Train Limit --

script.on_event(e.on_built_entity, function(event)
    local entity = event.created_entity
    if entity.name ~= "train-stop" then return end
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    entity.trains_limit = get_player_setting(player, "te_default_limit") --[[@as uint]]
end)

-- TODO: default temp stop wait conditions | manual
-- * ^ this train only | all trains | train groups
-- TODO: default wait conditions (https://mods.factorio.com/mod/default-wait-conditions)
-- TODO: change station name in schedule (https://mods.factorio.com/mod/TrainScheduleEditor)
-- TODO: duplicate station in schedule (https://mods.factorio.com/mod/TrainScheduleHelper)
-- TODO: robot build automatic
-- quick schedule?
-- train limit loop saturation resolution?
-- default train limit