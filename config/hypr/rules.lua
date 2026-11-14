-- ~/.config/hypr/rules.lua
-- Docs: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--
-- Each named rule needs a unique name: rules that share a name are merged.

-- Set in hyprland.lua and optionally overridden in local.lua (Super+O).
local window_opacity = window_opacity or 0.8

-- Blur behind rofi menus. ignore_alpha must stay below the rofi background alpha.
hl.layer_rule({
    match = { namespace = "rofi" },
    blur = true,
    ignore_alpha = 0.15,
})

-- Dunst uses the "notifications" layer rather than a regular window.
hl.layer_rule({
    match = { namespace = "^notifications$" },
    blur = true,
    ignore_alpha = 0.15,
})

-- Opacity for ordinary applications (Super+O changes window_opacity).
hl.window_rule({
    name = "opacity-apps",
    match = {
        class = "^(kitty|xed|thunar|brave-browser|firefox|org[.]mozilla[.]firefox|discord|codium|GeForceNOW|Spotify|org.pulseaudio.pavucontrol|com.github.johnfactotum.Foliate)$",
    },
    opacity = window_opacity .. " override " .. window_opacity .. " override 1.0 override",
})

-- Chrome and Obsidian: slightly translucent (active / inactive) so the blurred
-- wallpaper shows through, but fully opaque when fullscreen (videos).
-- Hyprland opacity applies to the whole window, so text is affected too;
-- keep these values high for readability.
hl.window_rule({
    name = "translucent-chrome-obsidian",
    match = { class = "^(google-chrome|Google-chrome|com[.]google[.]Chrome|obsidian|sioyek|code-oss|Code - OSS|com[.]visualstudio[.]code[.]oss)$" },
    opacity = "0.9 override 0.85 override 1.0 override",
})

-- Double the default mouse wheel speed in Chrome and VS Code.
local app_mouse_scroll = hl.get_config("input.scroll_factor") * 2

-- Keep Chrome's touchpad scrolling closer to other applications.
hl.window_rule({
    name = "chrome-scroll-speed",
    match = { class = "^(google-chrome|Google-chrome|com[.]google[.]Chrome)$" },
    scroll_mouse = app_mouse_scroll,
    scroll_touchpad = 0.077,
})

-- Set the touchpad scrolling speed for VS Code and Code - OSS.
hl.window_rule({
    name = "vscode-scroll-speed",
    match = { class = "^(code-oss|Code - OSS|com[.]visualstudio[.]code[.]oss|Code|code)$" },
    scroll_mouse = app_mouse_scroll,
    scroll_touchpad = 0.28,
})

-- Set terminal touchpad scrolling and keep the original mouse-wheel speed.
hl.window_rule({
    name = "kitty-scroll-speed",
    match = { class = "^kitty$" },
    scroll_mouse = 1.0,
    scroll_touchpad = 1.15,
})

-- Halve the touchpad scrolling speed in Obsidian.
hl.window_rule({
    name = "obsidian-scroll-speed",
    match = { class = "^obsidian$" },
    scroll_touchpad = 0.25,
})

-- Always float these windows.
hl.window_rule({
    name = "float-pavucontrol",
    match = { class = "^(pavucontrol)$" },
    float = true,
})

hl.window_rule({
    name = "float-nm-connection-editor",
    match = { class = "^(nm-connection-editor)$" },
    float = true,
})

hl.window_rule({
    name = "float-blueman-manager",
    match = { class = "^(blueman-manager)$" },
    float = true,
})

hl.window_rule({
    name = "float-open-file",
    match = { title = "^(Open File)$" },
    float = true,
})

hl.window_rule({
    name = "float-save-file",
    match = { title = "^(Save File)$" },
    float = true,
})
