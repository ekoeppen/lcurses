--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: clock.lua,v 1.2 2004/05/22 17:17:26 tngd Exp $
--------------------------------------------------------------------------]]

-- dependencies
require 'cui'

-- locals
local _cui, cui = cui, nil  -- make sure we don't use 'cui' directly
local class = _cui.class
local tevent = _cui.tevent
local tview = _cui.tview

--[[ tclock ]---------------------------------------------------------------
tclock:tview

Members:
    tclock.last_time
    tclock.color
Methods:
    tclock:tclock(bounds)
    tclock:handle_event(event)
    tclock:draw_window()
    tclock:update()
--]]------------------------------------------------------------------------
local tclock = class('tclock', tview)

function tclock:tclock(bounds)
    self:tview(bounds)

    -- grow flags
    self.grow.lox = true
    self.grow.hix = true

    -- event mask
    self.event[tevent.ev_idle] = true

    -- members
    self.last_time = 0
    self.color = _cui.make_color(_cui.COLOR_BLUE, _cui.COLOR_WHITE)

    self:update()
end

function tclock:handle_event(event)
    if (event.type == tevent.ev_idle) then
        self:update()
    end
end

function tclock:draw_window()
    local w = self:window()
    local str = _cui.new_chstr(self.size.x)
    str:set_str(0, os.date('%H:%M:%S', self.last_time), self.color)
    self:window():mvaddchstr(0, 0, str)
end

function tclock:update()
    local t = os.time()
    if (t ~= self.last_time) then
        self.last_time = t
        self:refresh()
    end
end

-- exported names
_cui.tclock = tclock
