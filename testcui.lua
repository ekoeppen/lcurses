curses = require('lcurses')
require 'cui'
require 'cui/ctrls'

local class = cui.class

local myview = class('myview', cui.tview)

function myview:myview(bounds, s)
    self:tview(bounds)
    -- options
    self.options.selectable = true
    self.options.validate = true
    -- event mask
    self.event[cui.tevent.ev_keyboard] = true
    -- grow
    self.grow.hix = true
    self.grow.hiy = true
    -- state
    self:set_state('cursor_visible', true)

    -- members
    self.str = ''
end

function myview:draw_window()
    local w = self:window()
    local attr = cui.make_color(cui.COLOR_WHITE, cui.COLOR_BLUE)
    local line = cui.new_chstr(self.size.x)
    line:set_str(0, ' ', attr, self.size.x)
    for l = 0, self.size.y - 1 do
        w:mvaddchstr(l, 0, line)
    end
    w:attrset(attr)
    w:mvaddstr(0, 0, self.str)
end

function myview:handle_event(event)
    if (event.type == cui.tevent.ev_keyboard) then
        if (event.key == 'x') then
            cui.message(cui.app, cui.tevent.ev_command, cui.tevent.cm_quit)
        elseif (event.key == "Insert") then
            self:set_state('block_cursor', not self.state.block_cursor)
            self.focus = not self.focus
        elseif (event.key == "F1") then
            self:set_state('cursor_visible', not self.state.cursor_visible)
        elseif (event.key == "Down") then
            local c = self:cursor():add(0, 1)
            self:goto(c.x, c.y)
            self:reset_cursor()
        elseif (event.key == "Up") then
            local c = self:cursor():add(0, -1)
            self:goto(c.x, c.y)
            self:reset_cursor()
        elseif (event.key == "Left") then
            local c = self:cursor():add(-1, 0)
            self:goto(c.x, c.y)
            self:reset_cursor()
        elseif (event.key == "Right") then
            local c = self:cursor():add(1, 0)
            self:goto(c.x, c.y)
            self:reset_cursor()
        else
            self.str = self.str .. " " .. event.key
            if (event.key == "Esc") then
                self.str = ''
            end
            self:refresh()
        end
    end
end

function myview:is_valid(command)
    if (command == cui.tevent.cm_quit) then
        --return false
    elseif (command == cui.tevent.cm_release_focus and self.focus) then
        return false
    end
    return true
end

local mylistbox = class('mylistbox', cui.tlistbox)

function mylistbox:mylistbox(bounds, columns, count, sbar)
    self:tlistbox(bounds, columns, { n = count }, sbar)
    --
    self.options.single_selection = false

end

function mylistbox:get_str(item, width)
    if (item > 0 and item <= table.getn(self.list)) then
        local str = tostring(item)
        return string.sub(item..string.rep(' ', width), 1, width)
    else
        return string.rep(' ', width)
    end
end

function mylistbox:selected(item)
    --return math.mod(item, 4) == 2
    return self.list[item]
end

function mylistbox:select_item(item, select)
    self.list[item] = select
end

local mywindow = class('mywindow', cui.twindow)

function mywindow:mywindow(bounds, title, num)
    self:twindow(bounds, title, num)

    self:insert(
        cui.tedit:new(
            cui.trect:new(1, 1, self.size.x - 1, 2),
            'wefwefwefwef398493849',
            20,
            false
        )
    )
    local sbar = cui.tscrollbar:new(cui.trect:new(self.size.x-2, 2, self.size.x-1, self.size.y-1), 15, 3)
    self:insert(
        mylistbox:new(
            cui.trect:new(1, 2, self.size.x-2, self.size.y-1),  -- bounds
            3,      -- columns
            1000,   -- size
            sbar    -- scrollbar
        )
--[[
        cui.tlistbox:new(
            cui.trect:new(1, 1, self.size.x-2, self.size.y-1),  -- bounds
            3,  -- columns
            {   -- list
                (function() local t = {} for i = 1, 1 do table.insert(t, {tostring(i)}) end return unpack(t) end)()
            },
            sbar    -- scrollbar
        )
--]]
    )
    self:insert(sbar)
    self:insert(cui.tbutton:new(cui.trect:new(5, self.size.y - 1, 5 + 11, self.size.y), 'Close', cui.tevent.cm_close))
    self:select_next(true)
end


local myblock = class('myblock', cui.tview)

function myblock:myblock(bounds)
    self:tview(bounds)
end

function myblock:draw_window()
    local d = cui.make_color(cui.COLOR_YELLOW, cui.COLOR_BLACK)

    local w = self:window()
    local ch = 0

    math.randomseed(os.time())
    local str = cui.new_chstr(self.size.x)
    for l = 0, self.size.y - 1 do
        for c = 0, self.size.x - 1 do
            str:set_ch(c, ch, d*math.random(0,1) +cui.A_BOLD*math.random(0,1))
            ch = ch == 255 and 0 or ch + 1
        end
        w:mvaddchstr(l, 0, str)
    end
end

local myapp = class('myapp', cui.tapp)

function myapp:myapp()
    self:tapp()

    local desk = self.desktop

    -- insert the clock
    self:insert(cui.tclock:new(cui.trect:new(self.size.x-8, 0, self.size.x, 1)))
    -- insert memory information
    self:insert(cui.tmemory:new(cui.trect:new(self.size.x-10, self.size.y-1, self.size.x, self.size.y)))

---[[
    local r = cui.trect:new(1, 1, 27, 10)
    desk:insert(cui.twindow:new(r, 'Window 1', 1))
    r:move(2, 2) desk:insert(cui.twindow:new(r, 'Window 2', 2))
    r:move(2, 2) desk:insert(cui.twindow:new(r, 'Window 3', 3))
    r:move(2, 2) desk:insert(cui.twindow:new(r, 'Window 4', 4))
    r:move(2, 2) desk:insert(cui.twindow:new(r, 'Window 5', 5))
    r:move(5, 5) desk:insert(mywindow:new(r, 'Window 6', 6))
--]]
end

function myapp:init_menu_bar()
    return cui.tmenubar:new(cui.trect:new(0, 0, self.size.x, 1))
end

local r = cui.trect:new(1, 1, 40, 15)
local window_number = 1
function myapp:handle_event(event)
    self.inherited.tapp.handle_event(self, event)

    if (event.type == cui.tevent.ev_command and event.command == cui.tevent.cm_new) then
        self.desktop:insert(cui.twindow:new(r, 'Window', window_number))
        r:move(2, 2) window_number = window_number + 1
    end
end

function myapp:init_status_bar()
    return cui.tstatusbar:new(cui.trect:new(0, self.size.y - 1, self.size.x, self.size.y),
        {
        --    Key           Description     Event type      Event command   Show
            { "AltX",       "Exit",         "ev_command",   "cm_quit",      true    },
            { "F3",         "New",          "ev_command",   "cm_new",       true    },
            { "F4",         "Close",        "ev_command",   "cm_close",     true    },
            { "F6",         "Previous",     "ev_command",   "cm_prev",      true    },
            { "F7",         "Next",         "ev_command",   "cm_next",      true    },
        }
    )
end

local app
local function run()
    app = myapp:new()
    app:run()
    app:close()
end

local ok, msg = xpcall(run, _TRACEBACK)

if (not ok) then
    if (not cui.isdone()) then
        cui.done()
    end
    print(msg)
end
