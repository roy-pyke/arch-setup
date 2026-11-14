-- ~/.config/hypr/keybinds.lua
-- Docs: https://wiki.hypr.land/Configuring/Basics/Binds/
--       https://wiki.hypr.land/Configuring/Basics/Dispatchers/

local home = os.getenv("HOME")

-- Launchers
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/resource-monitor.sh"))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind("SUPER + Tab", hl.dsp.exec_cmd("hyprlock --no-fade-in"))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/power-menu.sh"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("quickshell -c hyprquickpaper"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(home .. "/.config/toolbox/toolbox.sh"))  -- toolbox

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 0 }))

-- Show the current workspace's regular windows together in the tiling layout.
hl.bind(mainMod .. " + A", function()
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    if workspace == nil then return end

    local windows = hl.get_windows({ workspace = workspace })
    for _, window in ipairs(windows) do
        if window.mapped and window.fullscreen ~= 0 then
            hl.dispatch(hl.dsp.window.fullscreen_state({
                window = window, internal = 0, client = 0, action = "set",
            }))
        end
    end
    for _, window in ipairs(windows) do
        if window.mapped and window.floating and not window.pinned then
            hl.dispatch(hl.dsp.window.float({ window = window, action = "unset" }))
        end
    end
end)

hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/opacity.sh"))

-- Toggle waybar
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("sh -c 'pgrep -x waybar >/dev/null && pkill waybar || nohup waybar >/dev/null 2>&1 &'"))

-- Screenshots: copy the full screen or a selected area to the clipboard.
hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenshot.sh full"))
hl.bind("Delete", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenshot.sh area"))

-- Clipboard
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))

-- Let kitty and Code OSS handle their own selection and clipboard shortcuts,
-- since terminals use different keys from ordinary applications.
local function handles_own_clipboard(class)
    return class == "kitty" or class == "code-oss" or class == "Code - OSS"
        or class == "com.visualstudio.code.oss" or class == "Code" or class == "code"
end

-- macOS-style select all / copy / paste / undo. Z is safe here because kitty
-- is passed through, so Alt+Z never becomes Ctrl+Z (suspend) in a terminal.
for _, key in ipairs({ "A", "C", "V", "Z" }) do
    hl.bind("ALT + " .. key, function()
        local window = hl.get_active_window()
        if window == nil or handles_own_clipboard(window.class) then
            hl.dispatch(hl.dsp.pass({ window = "activewindow" }))
        else
            hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = key }))
        end
    end)
end

-- macOS-style redo: Alt+Shift+Z -> Ctrl+Shift+Z.
hl.bind("ALT + SHIFT + Z", function()
    local window = hl.get_active_window()
    if window == nil or handles_own_clipboard(window.class) then
        hl.dispatch(hl.dsp.pass({ window = "activewindow" }))
    else
        hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "Z" }))
    end
end)

-- Only Chrome gets the macOS-style tab shortcuts; pass them through elsewhere.
for _, key in ipairs({ "T", "W" }) do
    hl.bind("ALT + " .. key, function()
        local window = hl.get_active_window()
        local class = window and window.class or ""
        if class == "google-chrome" or class == "Google-chrome" or class == "com.google.Chrome" then
            hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = key }))
        else
            hl.dispatch(hl.dsp.pass({ window = "activewindow" }))
        end
    end)
end

-- Keyboard layout
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("hyprctl switchxkblayout current next"))

-- Toggle floating; a window that becomes floating is resized to 60% and centered
hl.bind(mainMod .. " + Space", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))

    local w = hl.get_active_window()
    if w ~= nil and w.floating then
        local mon = hl.get_active_monitor()
        if mon ~= nil then
            local target_w = math.floor(mon.width * 0.6)
            local target_h = math.floor(mon.height * 0.6)

            -- absolute resize (relative = false), not a delta
            hl.dispatch(hl.dsp.window.resize({ x = target_w, y = target_h, relative = false }))

            local mon_x = mon.x or 0
            local mon_y = mon.y or 0
            local target_x = mon_x + math.floor((mon.width - target_w) / 2)
            local target_y = mon_y + math.floor((mon.height - target_h) / 2)

            -- absolute move to the centered position
            hl.dispatch(hl.dsp.window.move({ x = target_x, y = target_y, relative = false }))
        end
    end
end)

-- Exit Hyprland.
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())

-- Focus (H/J/K/L = left/down/up/right, vim-style)
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

-- Move the active window within the layout.
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Resize the active window by a relative pixel delta; repeat while held.
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })

-- Workspaces 1-10, and move-to-workspace with SHIFT
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Super+U / Super+I: previous / next workspace on the current monitor
hl.bind(mainMod .. " + U", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + I", hl.dsp.focus({ workspace = "m+1" }))

-- Mouse move/resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media keys (also work on the lock screen)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
