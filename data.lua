data:extend{{
    type = "custom-input",
    name = "te-up",
    key_sequence = "",
    linked_game_control = "move-up",
},{
    type = "custom-input",
    name = "te-down",
    key_sequence = "",
    linked_game_control = "move-down",
},{
    type = "custom-input",
    name = "te-left",
    key_sequence = "",
    linked_game_control = "move-left",
},{
    type = "custom-input",
    name = "te-right",
    key_sequence = "",
    linked_game_control = "move-right",
},{
    type = "custom-input",
    name = "te-block-toggle",
    key_sequence = "ALT + T",
},{
    type = "custom-input",
    name = "te-rotate",
    key_sequence = "",
    linked_game_control = "rotate",
},{
    type = "custom-input",
    name = "te-reverse-rotate",
    key_sequence = "",
    linked_game_control = "reverse-rotate",
},{
    type = "custom-input",
    name = "te-toggle-automatic",
    key_sequence = "ALT + A",
},{
    type = "custom-input",
    name = "te-remove-invalid-signals",
    key_sequence = "SHIFT + ALT + D",
    action = "spawn-item",
    item_to_spawn = "te-remove-invalid-signals"
}}

---@type SelectionToolPrototype
data:extend{{
    type = "selection-tool",
    name = "te-toggle-manual",
    icon = "__base__/graphics/icons/deconstruction-planner.png",
    icon_size = 64, icon_mipmaps = 4,
    flags = {"only-in-cursor", "hidden", "not-stackable"},
    subgroup = "tool",
    stack_size = 1,
    draw_label_for_cursor_render = true,
    selection_color = {0, 1, 0},
    alt_selection_color = {1, 0, 0},
    reverse_selection_color = {1, 1, 0},
    selection_mode = {"entity-with-health"},
    alt_selection_mode = {"entity-with-health"},
    entity_type_filters = {"locomotive"},
    alt_entity_type_filters = {"locomotive"},
    reverse_entity_type_filters = {"locomotive"},
    selection_cursor_box_type = "entity",
    alt_selection_cursor_box_type = "entity",
},{
    type = "selection-tool",
    name = "te-remove-invalid-signals",
    icon = "__base__/graphics/icons/deconstruction-planner.png",
    icon_size = 64, icon_mipmaps = 4,
    flags = {"only-in-cursor", "hidden", "not-stackable"},
    subgroup = "tool",
    stack_size = 1,
    draw_label_for_cursor_render = true,
    selection_color = {1, 0, 0},
    alt_selection_color = {1, 0.5, 0},
    selection_mode = {"entity-with-health"},
    alt_selection_mode = {"entity-with-health"},
    entity_type_filters = {"rail-signal", "rail-chain-signal"},
    alt_entity_type_filters = {"rail-signal", "rail-chain-signal"},
    selection_cursor_box_type = "entity",
    alt_selection_cursor_box_type = "entity",
}}

local styles = data.raw["gui-style"].default
styles.te_rename_button = {
    type = "button_style",
    parent = "list_box_item",
    height = 36,
    font = "default-bold",
    default_font_color = bold_font_color,
}