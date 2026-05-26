-- Hammerspoon configuration for application shortcuts

-- Enable logging
hs.logger.defaultLogLevel = 'debug'
local log = hs.logger.new('myconfig', 'debug')

-- Define the keyboard shortcuts and their corresponding applications
local shortcuts = {
    -- Command + Option = hold down V on moonlander
    {mods = {"command", "alt"}, key = "u", app = "Slack"},
    {mods = {"command", "alt"}, key = "i", app = "zoom.us"},
    {mods = {"command", "alt"}, key = "o", app = "Microsoft Outlook"},
    {mods = {"command", "alt"}, key = "p", app = "Postman"},

    {mods = {"command", "alt"}, key = "j", app = "iTerm"},
    {mods = {"command", "alt"}, key = "k", app = "Visual Studio Code"},
    {mods = {"command", "alt"}, key = "l", app = "Google Chrome"},
    {mods = {"command", "alt"}, key = ";", app = "Finder"},

    {mods = {"command", "alt"}, key = "m", app = "Claude"},
    {mods = {"command", "alt"}, key = ",", app = "Spotify"},
}

-- Function to focus an application and cycle through its windows
local function focusApp(appName)
    local app = hs.application.find(appName)

    if not app then
        log.d("App not running, skipping:", appName)
        return
    end

    -- Get current focused window
    local focusedWindow = hs.window.focusedWindow()

    -- If app is already focused, cycle through its windows
    if focusedWindow and focusedWindow:application() == app then
        local windows = app:visibleWindows()

        -- Sort windows by title to maintain stable order
        table.sort(windows, function(a, b)
            return a:title() < b:title()
        end)

        log.d(string.format("Found %d visible windows for %s", #windows, appName))

        -- Debug: Print all window titles
        for i, win in ipairs(windows) do
            log.d(string.format("Window %d: %s", i, win:title()))
        end

        if #windows > 0 then
            -- Find current window index
            local currentIdx = 1
            for i, win in ipairs(windows) do
                if win == focusedWindow then
                    currentIdx = i
                    break
                end
            end

            -- Focus next window (or first if at end)
            local nextIdx = (currentIdx % #windows) + 1
            log.d(string.format("Current window index: %d, Next window index: %d", currentIdx, nextIdx))
            log.d(string.format("Focusing window: %s", windows[nextIdx]:title()))

            windows[nextIdx]:focus()
        end
    else
        -- Focus the app if it's not currently focused
        log.d("App not focused, focusing:", appName)
        app:activate()
    end
end

-- Bind the keyboard shortcuts
for _, shortcut in ipairs(shortcuts) do
    hs.hotkey.bind(shortcut.mods, shortcut.key, function()
        focusApp(shortcut.app)
    end)
end

-- Slack-specific key remapping
local function remapSlackKeys(event)
    local flags = event:getFlags()
    local keycode = event:getKeyCode()
    local app = hs.application.frontmostApplication()

    -- Check if we're in Slack and using ctrl key
    if app:name() == "Slack" and flags:containExactly({'ctrl'}) then
        -- Map ctrl+o to cmd+[
        if keycode == hs.keycodes.map["o"] then
            hs.eventtap.keyStroke({"cmd"}, "[")
            return true  -- Prevent the original keystroke
        -- Map ctrl+i to cmd+]
        elseif keycode == hs.keycodes.map["i"] then
            hs.eventtap.keyStroke({"cmd"}, "]")
            return true  -- Prevent the original keystroke
        end
    end
    return false
end

-- Create an eventtap to capture and remap keystrokes
local slackKeytap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, remapSlackKeys)
slackKeytap:start()

-- Show a notification that the configuration is loaded
hs.notify.new({title="Hammerspoon", informativeText="Configuration loaded"}):send()
log.d("Configuration loaded and logging enabled")
