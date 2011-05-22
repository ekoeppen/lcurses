--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: menubar.lua,v 1.2 2004/05/22 17:17:26 tngd Exp $
--------------------------------------------------------------------------]]

-- dependencies
require 'cui'

-- locals
local _cui, cui = cui, nil  -- make sure we don't use 'cui' directly
local class = _cui.class
local tevent = _cui.tevent
local tview = _cui.tview

--[[ tmenubar ]------------------------------------------------------------

--]]------------------------------------------------------------------------

local tmenubar = class('tmenubar', tview)

function tmenubar:tmenubar(bounds)
    self:tview(bounds)
    -- grow
    self.grow.hix = true
    -- options
    self.options.pre_event = true
    -- event mask
    self.event[tevent.ev_keyboard] = true

    -- members
    self.color = _cui.make_color(_cui.COLOR_RED, _cui.COLOR_WHITE)
end

function tmenubar:draw_window()
    local w = self:window()
    w:attrset(self.color)
    w:mvaddstr(0, 0, string.rep(' ', self.size.x*self.size.y))

    w:mvaddstr(0, 0, 'Menu Bar')
end

function tmenubar:handle_event(event)
    self.inherited.tview.handle_event(self, event)

end

-- exported names
_cui.tmenubar = tmenubar
