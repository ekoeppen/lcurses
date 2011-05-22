--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: memory.lua,v 1.2 2004/05/22 17:17:26 tngd Exp $
--------------------------------------------------------------------------]]

-- dependencies
require 'cui'

-- locals
local _cui, cui = cui, nil  -- make sure we don't use 'cui' directly
local class = _cui.class
local tevent = _cui.tevent
local tview = _cui.tview

--[[ tmemory ]--------------------------------------------------------------
tmemory:tview

Members:
    tmemory.last_time
    tmemory.color
Methods:
    tmemory:tmemory(bounds)
    tmemory:handle_event(event)
    tmemory:draw_window()
    tmemory:update()
--]]------------------------------------------------------------------------
local tmemory = class('tmemory', tview)

function tmemory:tmemory(bounds)
    self:tview(bounds)

    -- grow flags
    self.grow.lox = true
    self.grow.hix = true
    self.grow.loy = true
    self.grow.hiy = true

    -- event mask
    self.event[tevent.ev_idle] = true

    -- members
    self.last_time = 0
    self.color = _cui.make_color(_cui.COLOR_BLUE, _cui.COLOR_WHITE)

    self:update()
end

function tmemory:handle_event(event)
    if (event.type == tevent.ev_idle) then
        self:update()
    end
end

function tmemory:draw_window()
    local w = self:window()
    local str = _cui.new_chstr(self.size.x)
    local t, l = gcinfo()
    local info = t..':'..l
    local pad = self.size.x - string.len(info)
    str:set_str(0, ' ', self.color, pad)
    str:set_str(pad, info, self.color)
    self:window():mvaddchstr(0, 0, str)
end

function tmemory:update()
    local t = os.time()
    if (t ~= self.last_time) then
        self.last_time = t
        self:refresh()
    end
end

-- exported names
_cui.tmemory = tmemory
