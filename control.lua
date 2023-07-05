local const = require("const")
local events = require("events")
local glib = require("glib")
local gui = require("gui")
local e = defines.events
local handlers = {}

---@param player LuaPlayer
local function setup_player(player)
    local index = player.index
    if not global.players[index] then
        ---@class PlayerData
        global.players[index] = {
            ---@type LuaPlayer
            player = player,
            ---@type table<string, boolean>
            flags = {},
            ---@type LuaEntity[]
            rename = {},
            ---@type uint|nil
            default_train_limit = 1,
            ---@type boolean
            restore_automatic = true,
            ---@type uint?
            train_id = nil
        }
    end
    gui.create_gui(player)
end

local function setup_force(force)
    local index = force.index
    if not global.forces[index] then
        ---@class ForceData
        global.forces[index] = {
            ---@type table<string, any>
            stops = {}
        }
    end
end

local function setup_globals()
    ---@type table<uint, LuaPermissionGroup[]>
    global.ticks = global.ticks or {}
    ---@type table<uint, PlayerData>
    global.players = global.players or {}
    ---@type table<uint, ForceData>
    global.forces = global.forces or {}
    for _, player in pairs(game.players) do
        setup_player(player)
    end
    for _, force in pairs(game.forces) do
        setup_force(force)
    end
end

events.on_init(setup_globals)
events.on_configuration_changed(setup_globals)

events.on_event(e.on_player_created, function(event)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    setup_player(player)
end)

events.on_event(e.on_player_removed, function (event)
    local index = event.player_index
    global.ticks[index] = nil
    global.players[index] = nil
end)

events.on_event(e.on_force_created, function(event)
    global.forces[event.force.index] = {}
end)

---@param vehicle LuaEntity?
---@return LuaTrain?
local function get_train(vehicle)
    if not (vehicle and vehicle.valid) then return end
    return vehicle.train
end

---@param train LuaTrain
---@param manual? boolean
local function toggle_manual_mode(train, manual)
    local locomotives = train.locomotives
    if #locomotives.front_movers == 0 and #locomotives.back_movers == 0 then return end
    if manual ~= nil then
        train.manual_mode = manual
    else
        train.manual_mode = not train.manual_mode
    end
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

events.on_event({"te-up", "te-down", "te-left", "te-right"}, function(event)
    local index = event.player_index
    local data = global.players[index]
    local player = data.player
    if player.render_mode ~= defines.render_mode.game then return end
    local train = get_train(player.vehicle)
    if not train then return end
    if train.manual_mode then return end
    train.manual_mode = true
    global.players[index].train_id = train.id
    manual_mode_text(train, player, true)

    local schedule = train.schedule
    if not schedule then return end
    if not schedule.records[schedule.current].temporary then return end
    table.remove(schedule.records, schedule.current)
    if schedule.current > #schedule.records then schedule.current = 1 end
    if #schedule.records == 0 then
        train.schedule = nil
        return
    end
    train.schedule = schedule
end)

events.on_event(e.on_player_driving_changed_state, function(event)
    local index = event.player_index
    local data = global.players[index]
    if not data.restore_automatic then return end
    local player = data.player
    local entity = event.entity
    if player.vehicle == entity then return end
    local train = get_train(entity)
    if not (train and train.manual_mode) then return end
    if train.id ~= data.train_id then return end
    train.manual_mode = false
    data.train_id = nil
    manual_mode_text(train, player)
end)

-- Toggle Selected / Planner --

events.on_event("te-toggle-automatic", function(event)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    local train = get_train(player.selected)
    local create_at_cursor = false
    if not train and player.render_mode == defines.render_mode.game then
        local cursor = player.cursor_stack
        if cursor and cursor.valid_for_read and cursor.name == "te-toggle-manual-tool" then
            train = get_train(player.vehicle)
            create_at_cursor = true
        end
    end
    if train then
        train.manual_mode = not train.manual_mode
        manual_mode_text(train, player, create_at_cursor)
    else
        if not player.clear_cursor() then return end
        player.cursor_stack.set_stack("te-toggle-manual-tool")
        player.play_sound{path = "utility/item_spawned"}
    end
end)

---@param event EventData.on_player_selected_area|EventData.on_player_alt_selected_area|EventData.on_player_reverse_selected_area
---@param manual boolean|nil
local function selected_area(event, manual)
    if event.item ~= "te-toggle-manual" then return end
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    local checked = {}
    for _, entity in pairs(event.entities) do
        local train = entity.train --[[@as LuaTrain]]
        if checked[train.id] then goto continue end
        toggle_manual_mode(train, manual)
        manual_mode_text(train, player)
        checked[train.id] = true
        ::continue::
    end
end

events.on_event(e.on_player_selected_area, function(event) selected_area(event, false) end)
events.on_event(e.on_player_alt_selected_area, function(event) selected_area(event, true) end)
events.on_event(e.on_player_reverse_selected_area, function(event) selected_area(event, nil) end)

-- Temporary Stop Overwrite / Wait Conditions --

events.on_event(e.on_train_changed_state, function(event)
    local train = event.train
    if train.state ~= defines.train_state.wait_station then return end
    if not settings.global["te-temporary-manual"].value then return end
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

events.on_event(e.on_train_schedule_changed, function(event)
    local index = event.player_index
    if not index then return end
    local flags = global.players[index].flags
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

-- Default Train Limit --
-- ! CHANGE LIMIT WHEN RENAMING STATION AND WHEN CHANGING STATION DEFAULT

---@param entity LuaEntity
---@param index uint
local function apply_default_limit(entity, index)
    if entity.trains_limit ~= 2^32-1 then return end
    local force_data = global.forces[entity.force_index][entity.backer_name]
    if force_data then
        entity.trains_limit = force_data.default_train_limit
        return
    end
    entity.trains_limit = global.players[index].default_train_limit
end

events.on_event(e.on_built_entity, function(event)
    local entity = event.created_entity
    if entity.name ~= "train-stop" then return end
    apply_default_limit(entity, event.player_index)
end)

-- Mass Station Rename --

function handlers.rename_button(event)
    local index = event.player_index
    local player = game.get_player(index) --[[@as LuaPlayer]]
    local name = player.opened.backer_name --[[@as string]]
    for _, stop in pairs(global.players[index].rename) do
        if not stop.valid then break end
        stop.backer_name = name
    end
    player.gui.relative.te_rename.destroy()
end

events.on_event(e.on_entity_renamed, function(event)
    local entity = event.entity
    if entity.type ~= "train-stop" then return end
    if event.by_script then return end
    local index = event.player_index ---@cast index -nil
    local data = global.players[index]
    local player = data.player
    if player.opened ~= entity then return end
    apply_default_limit(entity, index)
    data.flags.rename = true
    if player.gui.relative.te_rename then return end
    local stops = game.get_train_stops{name = event.old_name, force = player.force}
    if #stops == 0 then return end
    global.rename[index] = stops
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

events.on_event(e.on_gui_closed, function (event)
    if event.gui_type ~= defines.gui_type.entity then return end
    if event.entity.type ~= "train-stop" then return end
    local index = event.player_index
    local data = global.players[index]
    local player = data.player --[[@as LuaPlayer]]
    if player.opened == event.entity then return end
    if data.flags.rename then
        data.flags.rename = nil
        return
    end
    local element = player.gui.relative.te_rename
    if not element then return end
    element.destroy()
end)

-- Auto Mine Signals --

local signal_positions = const.signal_positions
events.on_event(e.on_player_mined_entity, function(event)
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

events.on_event("te-block-toggle", function(event)
    local gvs = game.get_player(event.player_index).game_view_settings
    gvs.show_rail_block_visualisation = not gvs.show_rail_block_visualisation
end)

-- Inline Rotation --

events.on_event({"te-rotate", "te-reverse-rotate"}, function(event)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    local allows_rotate = player.permission_group.allows_action(defines.input_action.rotate_entity)
    if not allows_rotate then return end
    local selected = player.selected
    if not (selected and selected.rotatable) then return end
    if not selected.train then return end
    if #selected.train.carriages == 1 then return end
    selected.disconnect_rolling_stock(defines.rail_direction.front)
    selected.disconnect_rolling_stock(defines.rail_direction.back)
    selected.rotate{by_player = player}
    selected.connect_rolling_stock(defines.rail_direction.front)
    selected.connect_rolling_stock(defines.rail_direction.back)
    if game.tick_paused then return end
    player.permission_group.set_allows_action(defines.input_action.rotate_entity, false)
    local ticks = global.ticks[event.tick + 1] or {}
    ticks[#ticks+1] = player.permission_group
    global.ticks[event.tick + 1] = ticks
end)

events.on_event(e.on_tick, function(event)
    local ticks = global.ticks[event.tick]
    if not ticks then return end
    for _, group in pairs(ticks) do ---@cast group LuaPermissionGroup
        group.set_allows_action(defines.input_action.rotate_entity, true)
    end
end)

-- Remove Invalid Signals --

events.on_event(e.on_player_selected_area, function(event)
    if event.item ~= "te-remove-invalid-signals" then return end
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    local force = player.force
    for _, entity in pairs(event.entities) do
        if #entity.get_connected_rails() == 0 then
            entity.order_deconstruction(force, player)
        end
    end
end)

glib.add_handlers(handlers)

-- TODO: default temp stop wait conditions | manual
-- * ^ this train only | all trains | train groups
-- TODO: default wait conditions (https://mods.factorio.com/mod/default-wait-conditions)
-- TODO: change station name in schedule (https://mods.factorio.com/mod/TrainScheduleEditor)
-- TODO: duplicate station in schedule (https://mods.factorio.com/mod/TrainScheduleHelper)
-- TODO: segment deconstruction (decon planner + ctrl + alt + right click?)
-- TODO: decon planner for invalid signals
-- quick schedule? auto add next station with cycle detection