-- @DOC_REQUIRE_SECTION@
-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
local vicious = require("vicious")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
-- Enable VIM help for hotkeys widget when client with matching name is opened:
require("awful.hotkeys_popup.keys.vim")

-- {{{ Error handling
-- @DOC_ERROR_HANDLING@
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- @DOC_LOAD_THEME@
-- Themes define colours, icons, font and wallpapers.
beautiful.init("/home/elliot/.config/awesome/zenburn/theme.lua")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

-- @DOC_DEFAULT_APPLICATIONS@
-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- @DOC_LAYOUT@
-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

-- {{{ Menu
-- @DOC_MENU@
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end}
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Memory usage bar
membar = wibox.widget.progressbar()
membar:set_width(dpi(20))
membar:set_height(dpi(8))
membar:set_background_color("#171717")
membar:set_border_color(nil)
membar:set_color({ type = "linear", from = { 0, 0 }, to = { 20, 0 }, stops = {
    { 0, "#0033aa" }, { 0.5, "#88A175" }, { 1, "#FF5656" }
}})
vicious.register(membar, vicious.widgets.mem, "$1", 1)
memwidget = {
    membar,
    direction = 'east',
    widget    = wibox.container.rotate
}

-- CPU flamegraph
cpuwidget = wibox.widget.graph()
cpuwidget:set_width(dpi(50))
cpuwidget:set_background_color("#171717")
cpuwidget:set_color({ type = "linear", from = { 0, 0 }, to = { 0, 20 }, stops = {
    { 0, "#FF5656" }, { 0.5, "#C8B04A" }, { 1, "#AECF96" }
}})
vicious.register(cpuwidget, vicious.widgets.cpu, "$1")

-- Volume
volwidget_text = wibox.widget.textbox()
vicious.register(volwidget_text, vicious.widgets.volume, " $1% ", 1, "Master")
volwidget = wibox.widget {
    {
        {widget = volwidget_text},
        left = 16,
        right = 16,
        widget = wibox.container.margin
    },
    bg = "#586E58",
    fg = beautiful.fg_focus,
    widget = wibox.container.background,
    shape = function(cr, w, h, ...)
        local f = gears.shape.transform(gears.shape.powerline):rotate_at(w/2, h/2, math.pi)
        f(cr, w, h, ...)
    end
}

-- Network

function get_network_ifaces()
    local i, ifaces = 0, {}
    local netdir = io.popen('ls /sys/class/net/')
    for iface in netdir:lines() do
        i = i + 1
        ifaces[i] = iface
    end
    netdir:close()
    return ifaces
end

netwidget_list = {}
for k, iface in pairs(get_network_ifaces()) do
    if iface ~= "lo" then
        local netWidgetTextSrc = iface .. ': <span color="#CC9393">${' .. iface .. ' up_kb}</span> <span color="#7F9F7F">${' .. iface ..' down_kb}</span>'
        local netWidgetText = wibox.widget.textbox()
        vicious.register(netWidgetText, vicious.widgets.net, netWidgetTextSrc, 1)
        table.insert(netwidget_list, wibox.widget {
            {
                {widget = netWidgetText},
                left = 16,
                right = 16,
                widget = wibox.container.margin
            },
            bg = "#4C4C66",
            fg = beautiful.fg_focus,
            widget = wibox.container.background,
            shape = function(cr, w, h, ...)
                local f = gears.shape.transform(gears.shape.powerline):rotate_at(w/2, h/2, math.pi)
                f(cr, w, h, ...)
            end
        })
    end
end

-- {{{ CPU temperature
thermalwidget_text = wibox.widget.textbox()
vicious.register(thermalwidget_text, vicious.widgets.thermal, "$1°C", 20, {"coretemp.0", "core"})
thermalwidget = wibox.widget {
    {
        {widget = thermalwidget_text},
        left = 16,
        right = 16,
        widget = wibox.container.margin
    },
    bg = "#4B696D",
    fg = beautiful.fg_focus,
    widget = wibox.container.background,
    shape = function(cr, w, h, ...)
        local f = gears.shape.transform(gears.shape.powerline):rotate_at(w/2, h/2, math.pi)
        f(cr, w, h, ...)
    end
}

-- {{{ Battery

function battery_exists(battery)
    local f = io.open('/sys/class/power_supply/' .. battery)
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

bat0widget = wibox.widget.textbox()
if battery_exists('BAT0') then
    vicious.register(bat0widget, vicious.widgets.bat, " $1$2%", 12, "BAT0")
end
bat1widget = wibox.widget.textbox()
if battery_exists('BAT1') then
    vicious.register(bat1widget, vicious.widgets.bat, " $1$2%", 12, "BAT1")
end

--- {{{ MPD
mpdWidgetText = wibox.widget.textbox()
vicious.register(mpdWidgetText, vicious.widgets.mpd,
    function(mpdWidgetText, args)
        if args["{state}"] == "Stop" then
            return ""
        else
            return args["{Artist}"]..' - '.. args["{Title}"]
        end
    end, 10)
mpdWidget = wibox.widget {
    {
        {widget = mpdWidgetText},
        left = 16,
        right = 16,
        widget = wibox.container.margin
    },
    bg = "#6E5151",
    fg = beautiful.fg_focus,
    widget = wibox.container.background,
    shape = function(cr, w, h, ...)
        local f = gears.shape.transform(gears.shape.powerline):rotate_at(w/2, h/2, math.pi)
        f(cr, w, h, ...)
    end
}

-- Create a wibox for each screen and add it
-- @TAGLIST_BUTTON@
local taglist_buttons = awful.util.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

-- @TASKLIST_BUTTON@
local tasklist_buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

-- @DOC_WALLPAPER@
local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

-- @DOC_FOR_EACH_SCREEN@
awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- @DOC_WIBAR@
    -- Create the wibox
    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
        height = dpi(25)
    })

    local widgetList = {
        layout = wibox.layout.fixed.horizontal,
        mykeyboardlayout,
    }

    for _, widgetItem in ipairs(netwidget_list) do
        table.insert(widgetList, widgetItem)
    end

    local restWidgets = {
        mpdWidget,
        volwidget,
        thermalwidget,
        bat0widget, bat1widget,
        memwidget, cpuwidget,
        wibox.widget.systray(),
        mytextclock,
        s.mylayoutbox,
    }

    for _, widgetItem in ipairs(restWidgets) do
        table.insert(widgetList, widgetItem)
    end

    -- @DOC_SETUP_WIDGETS@
    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        widgetList,
    }
end)
-- }}}

-- {{{ Mouse bindings
-- @DOC_ROOT_BUTTONS@
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
-- @DOC_GLOBAL_KEYBINDINGS@
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    --- awful.key({ modkey }, "p", function() menubar.show() end,
    ---           {description = "show the menubar", group = "launcher"}),

    -- Volume
    awful.key({ }, "XF86AudioRaiseVolume",    function () awful.util.spawn("amixer set Master 5%+") end),
    awful.key({ }, "XF86AudioLowerVolume",    function () awful.util.spawn("amixer set Master 5%-") end),
    awful.key({ }, "XF86AudioMute",           function () awful.util.spawn("amixer set Master toggle") end),

    awful.key({ modkey }, "p", function () awful.util.spawn("mpc toggle") end),

    -- Backlight
    awful.key({ },  "XF86MonBrightnessUp", function () awful.util.spawn("t430s-backlight-up") end),
    awful.key({ },  "XF86MonBrightnessDown", function () awful.util.spawn("t430s-backlight-down") end),

    -- Touchpad management
    awful.key({ }, "XF86TouchpadToggle",      function () awful.util.spawn("touchctl toggle") end),

    -- Rapid shutdown
    awful.key({ modkey, "Control" }, "Escape", function () awful.util.spawn("sudo -n /sbin/poweroff") end),

    --Misc. Shortcuts
    awful.key({ modkey, "Shift" }, "n",      function () awful.util.spawn("nemo --no-desktop") end),
    awful.key({ modkey, "Shift" }, "u",      function () awful.util.spawn("sudo pm-suspend") end),
    awful.key({ modkey, "Shift", "Control" }, "k",      function () awful.util.spawn("xkill") end),

    awful.key({ modkey, "Control" }, "l",      function ()
        awful.util.spawn("i3lock -c000000 -i /home/elliot/.config/awesome/lockscreen.png")
    end),
    awful.key({ }, "Pause",      function ()
        awful.util.spawn("i3lock -c000000 -i /home/elliot/.config/awesome/lockscreen.png")
    end),

     awful.key({ }, "Print",                  function ()
        awful.util.spawn("scrot")
        awful.util.spawn("notify-send -u critical -t 2000 \"Screenshot Saved\"")
    end)

)

-- @DOC_CLIENT_KEYBINDINGS@
clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "maximize", group = "client"})
)

-- @DOC_NUMBER_KEYBINDINGS@
-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

-- @DOC_CLIENT_BUTTONS@
clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
-- @DOC_RULES@
awful.rules.rules = {
    -- @DOC_GLOBAL_RULE@
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- @DOC_FLOATING_RULE@
    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- @DOC_DIALOG_RULE@
    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
-- @DOC_MANAGE_HOOK@
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- @DOC_TITLEBARS@
-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = awful.util.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

-- @DOC_BORDER@
client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- startup
awful.util.spawn("redshift-somerville")
