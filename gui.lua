local glib = require("glib")
local events = require("events")
local e = defines.events
local gui = {}
local handlers = {}

events.on_configuration_changed(function()
    local guis = {"te_train_settings", "te_station_settings"}
    for _, player in pairs(game.players) do
        for _, name in pairs(guis) do
            local elem = player.gui.relative[name]
            if elem then elem.destroy() end
        end
        gui.create_gui(player)
    end
end)

---@param event EventData.on_gui_click
function handlers.toggle_collapse(data, event)
    local button = event.element
    local visible = button.sprite == "utility/expand"
    local new_sprite = visible and "utility/collapse" or "utility/expand"
    local new_sprite_dark = new_sprite .. "_dark"
    button.sprite, button.hovered_sprite, button.clicked_sprite = new_sprite, new_sprite_dark, new_sprite_dark
    local parent = button.parent --[[@as LuaGuiElement]]
    parent.title.visible = visible
    parent.parent.content_frame.visible = visible
end

function handlers.toggle_restore_automatic(data, event)
    local switch = event.element
    data.restore_automatic = switch.switch_state == "right"
end

---@param textfield LuaGuiElement
local function validate_limit_text(textfield)
    local number = tonumber(textfield.text)
    if number and number > 2^32-1 then
        textfield.style = "invalid_value_short_number_textfield"
        return false
    else
        textfield.style = "short_number_textfield"
        return number
    end
end

function handlers.global_train_limit(data, event)
    local limit = validate_limit_text(event.element)
    if limit == false then return end
    data.default_train_limit = limit
end

function handlers.station_train_limit(data, event)
    local limit = validate_limit_text(event.element)
    if limit == false then return end
    local player = data.player
    local name = player.opened.backer_name
    local stops = global.forces[player.force_index].stops
    local stop_data = stops[name] or {}
    stop_data.default_train_limit = limit
    stops[name] = stop_data
end

---@param name string
---@param anchor GuiAnchor
---@param content GuiElemDef[]
---@return GuiElemDef
local function relative_settings(name, anchor, content)
    return {
        args = {type = "frame", name = name, direction = "vertical", anchor = anchor},
        style_mods = {padding = 4},
        children = {{
            args = {type = "flow", direction = "vertical"},
            style_mods = {padding = 0},
            children = {{
                args = {type = "flow", direction = "horizontal"},
                style_mods = {padding = 0, horizontal_spacing = 8, vertically_stretchable = false},
                children = {{
                    args = {
                        type = "sprite-button", style = "frame_action_button",
                        sprite = "utility/expand", hovered_sprite = "utility/expand_dark", clicked_sprite = "utility/expand_dark",
                    },
                    handlers = {[e.on_gui_click] = handlers.toggle_collapse}
                },{
                    ref = false,
                    args = {type = "label", name = "title", caption = "Train Enhancements", visible = false, style = "frame_title"},
                }}
            },{
                args = {type = "frame", name = "content_frame", direction = "vertical", visible = false, style = "inside_shallow_frame_with_padding"},
                style_mods = {horizontally_stretchable = true},
                children = content
            }}
        }}
    }
end

---@param content GuiElemDef
local function setting(content)
    return {
        args = {type = "flow", direction = horizontal},
        style_mods = {vertical_align = "center"},
        children = {{
            args = {type = "label", caption = {"te-setting-name."..content.args.name}},
        },{
            args = {type = "empty-widget"},
            style_mods = {horizontally_stretchable = true},
        },
            content,
        }
    }
end

---@type GuiElemDef
local train_gui = relative_settings("te_train_settings", {
    gui = defines.relative_gui_type.train_gui,
    position = defines.relative_gui_position.right,
},{{
    args = {type = "flow", direction = "horizontal"},
    children = {
        setting{
            args = {type = "switch", name = "restore_automatic", switch_state = "right"},
            handlers = {[e.on_gui_switch_state_changed] = handlers.toggle_restore_automatic}
        }
    }
}})

---@type GuiElemDef
local station_gui = relative_settings("te_station_settings", {
    gui = defines.relative_gui_type.train_stop_gui,
    position = defines.relative_gui_position.right,
},{{
    args = {type = "flow", direction = "vertical"},
    children = {
        setting{
            args = {
                type = "textfield", name = "global_train_limit", text = "1", style = "short_number_textfield",
                numeric = true, allow_decimal = false, allow_negative = false, lose_focus_on_confirm = true, clear_and_focus_on_right_click = true,
            },
            handlers = {[e.on_gui_text_changed] = handlers.global_train_limit}
        },
        setting{
            args = {
                type = "textfield", name = "station_train_limit", style = "short_number_textfield",
                numeric = true, allow_decimal = false, allow_negative = false, lose_focus_on_confirm = true, clear_and_focus_on_right_click = true,
            },
            handlers = {[e.on_gui_click] = handlers.station_train_limit}
        }
    }
}})

---@param player LuaPlayer
function gui.create_gui(player)
    local relative = player.gui.relative
    if relative.te_train_settings then relative.te_train_settings.destroy() end
    if relative.te_station_settings then relative.te_station_settings.destroy() end
    glib.add(relative, train_gui)
    glib.add(relative, station_gui)
end

glib.add_handlers(handlers, function(event, handler)
    local data = global.data[event.player_index]
    handler(data, event)
end)

return gui