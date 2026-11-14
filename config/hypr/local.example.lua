-- ~/.config/hypr/local.lua: settings for this machine only (not tracked by git).
-- install.sh creates local.lua from this file. Everything here is optional and
-- is applied after the defaults in hyprland.lua, so it overrides them.
-- Find names with `hyprctl monitors` and `hyprctl devices`.

-- Monitors: name, mode, position, scale.
-- hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.5 })
-- hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@60", position = "auto", scale = 1.5 })

-- Pin workspaces to monitors, e.g. 1-5 on the external screen and 6-10 on the laptop.
-- for i = 1, 10 do
--     hl.workspace_rule({
--         workspace = tostring(i),
--         monitor = i <= 5 and "HDMI-A-1" or "eDP-1",
--         default = i == 1 or i == 6,
--     })
-- end

-- Keyboard layouts (Super+Z cycles through them) and options.
-- hl.config({ input = { kb_layout = "us,de", kb_options = "caps:ctrl_shifted_capslock" } })

-- Per-device pointer speed (-1.0 to 1.0).
-- hl.device({ name = "your-touchpad-name", sensitivity = 0.0 })
-- hl.device({ name = "your-mouse-name", sensitivity = -0.5, natural_scroll = true })

-- Opacity for ordinary application windows; Super+O updates this line.
-- window_opacity = 0.8
