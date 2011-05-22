--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: statusbar.lua,v 1.2 2004/05/22 17:17:26 tngd Exp $
--------------------------------------------------------------------------]]

-- dependencies
require 'cui'

-- locals
local _cui, cui = cui, nil  -- make sure we don't use 'cui' directly
local class = _cui.class
local tevent = _cui.tevent
local message = _cui.message
local tview = _cui.tview

--[[ tstatusbar ]----------------------------------------------------------

--]]------------------------------------------------------------------------

local tstatusbar = class('tstatusbar', tview)

function tstatusbar:tstatusbar(bounds, command_table)
    self:tview(bounds)
    -- grow
    self.grow.loy = true
    self.grow.hiy = true
    self.grow.hix = true
    -- options
    self.options.pre_event = true
    -- event mask
    self.event[tevent.ev_keyboard] = true

    -- members
    self.command_table = command_table

    self.key_attr = _cui.make_color(_cui.COLOR_RED, _cui.COLOR_WHITE)
    self.text_attr = _cui.make_color(_cui.COLOR_BLACK, _cui.COLOR_WHITE)
end

function tstatusbar:draw_window()
    local w = self:window()
    local x = 0
    local tattr = self.text_attr
    local kattr = self.key_attr

    for _, e in ipairs(self.command_table) do
        if (e[5]) then
            w:attrset(kattr)
            w:addstr(' '..e[1])
            w:attrset(tattr)
            w:addstr(' '..e[2])
            x = x + string.len(e[1]) + string.len(e[2]) + 2
        end
    end

    if (x < self.size.x) then
        w:attrset(tattr)
        w:addstr(string.rep(' ', self.size.x - x))
    end
end

function tstatusbar:handle_event(event)
    self.inherited.tview.handle_event(self, event)

    if (event.type == tevent.ev_keyboard) then
        local key = event.key_name
        for _, e in ipairs(self.command_table) do
            if (e[1] == key) then
                message(self.parent, tevent[e[3]], tevent[e[4]])
                event.type = nil
            end
        end
    end
end

-- exported names
_cui.tstatusbar = tstatusbar
