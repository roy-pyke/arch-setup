-- ~/.config/hypr/hyprland.lua
-- Docs: https://wiki.hypr.land/Configuring/Start/
--
-- This file holds the shared defaults. Machine-specific settings (monitor
-- layout, input devices, keyboard layouts, window opacity) belong in
-- local.lua next to this file; it is loaded after these defaults, so anything
-- set there wins. See local.example.lua.

---- MONITORS ----

-- Every monitor at its preferred mode, placed automatically, with automatic
-- scaling. Override per output in local.lua.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

---- PROGRAMS ----

mainMod     = "SUPER"
terminal    = "kitty"
menu        = "rofi -show drun"
fileManager = "thunar"
browser     = os.getenv("HOME") .. "/.config/hypr/scripts/preferred-browser.sh"

-- Window opacity for ordinary applications (see rules.lua). Super+O changes
-- it by writing `window_opacity = ...` into local.lua.
window_opacity = 0.8

---- AUTOSTART ----

-- hl.exec_cmd() fires immediately, so autostart commands run on the
-- hyprland.start event (the equivalent of exec-once).
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start auto-color-scheme.timer")
    hl.exec_cmd("hypridle")
    -- Lock as soon as the session starts.
    hl.exec_cmd("hyprlock --no-fade-in")
    hl.exec_cmd("fcitx5 -d")
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    -- Restores each monitor's last selected wallpaper from its cache.
    hl.exec_cmd("awww-daemon")
end)

---- ENVIRONMENT ----

hl.env("XCURSOR_SIZE", "18")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("GLFW_IM_MODULE", "ibus")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")

---- INPUT ----

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0.5,
        scroll_factor = 0.2,
        touchpad = {
            natural_scroll = true,
            -- Default speed for applications without a window-specific override.
            scroll_factor = 0.5,
            tap_to_click = true,
            tap_and_drag = false,
        },
    },
})

---- LOOK AND FEEL ----

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 5,
        -- A soft silver-blue focus outline; inactive windows stay understated.
        border_size = 3,
        col = {
            active_border = {
                colors = {"rgba(d5e4f1eb)", "rgba(93b5ced2)"},
                angle = 45,
            },
            inactive_border = "rgba(a2b2c225)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 8,
        blur = {
            enabled = true,
            size = 5,
            passes = 1,
            vibrancy = 0.2,
        },
        shadow = {
            enabled = true,
            range = 12,
            render_power = 3,
        },
    },
    animations = {
        enabled = true,
    },
})

hl.curve("easeOut", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.0} } })

hl.animation({ leaf = "windows",    enabled = true, speed = 5, bezier = "easeOut" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "easeOut" })
hl.animation({ leaf = "border",     enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "default" })

---- LAYOUT ----

hl.config({
    dwindle = { preserve_split = true },
    master = { new_status = "master" },
})

---- MISC ----

hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        on_focus_under_fullscreen = 2,
    },
})

-- Open new ordinary windows floating at 70% of the monitor, centered.
hl.on("window.open", function(window)
    if window == nil then return end

    local started_fullscreen = window.fullscreen ~= 0 or window.fullscreen_client ~= 0
    if started_fullscreen then
        hl.dispatch(hl.dsp.window.fullscreen_state({
            window = window, internal = 0, client = 0, action = "set",
        }))
    end

    -- Leave existing floating dialogs at the sizes their applications request.
    local needs_size = started_fullscreen or not window.floating
    if not window.floating then
        hl.dispatch(hl.dsp.window.float({ window = window, action = "set" }))
    end
    if needs_size and window.monitor ~= nil then
        -- mode.width/height are logical dimensions, including fractional scale.
        local mode = window.monitor.mode
        if mode ~= nil and mode.width > 0 and mode.height > 0 then
            hl.dispatch(hl.dsp.window.resize({
                window = window,
                x = math.max(1, math.floor(mode.width * 0.7)),
                y = math.max(1, math.floor(mode.height * 0.7)),
                relative = false,
            }))
            hl.dispatch(hl.dsp.window.center({ window = window }))
        end
    end
end)

---- MACHINE-SPECIFIC SETTINGS ----

-- local.lua is optional and is not tracked by git.
local ok, err = pcall(require, "local")
if not ok and not tostring(err):find("module 'local' not found", 1, true) then
    error(err)
end

---- SPLIT-OUT FILES ----

require("keybinds")
require("rules")
