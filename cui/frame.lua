--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: frame.lua,v 1.3 2004/05/23 21:19:29 tngd Exp $
--------------------------------------------------------------------------]]

-- dependencies
require 'cui'

-- locals
local _cui, cui = cui, nil  -- make sure we don't use 'cui' directly
local class = _cui.class
local tevent = _cui.tevent
local tview = _cui.tview

--[[ tframe ]---------------------------------------------------------------
TODO: bounds check (probable truncate) title and print window number

tframe: tview

Members:
    tframe.title
    tframe.attr

Methods:
    tframe:tframe(bounds, title, attr)
    tframe:set_title(title, attr)
    tframe:draw_window()
    tframe:handle_event(event)

draws a border around (inside) the window
--]]------------------------------------------------------------------------
local tframe = class('tframe', tview)

function tframe:tframe(bounds, title, attr)
    self:tview(bounds)
    -- grow
    self.grow.hix = true
    self.grow.hiy = true
    -- event mask
    self.event[tevent.ev_broadcast] = true

    self:set_title(title, attr)
end

function tframe:set_title(title, attr)
    self.title = title
    self.attr = attr or _cui.A_NORMAL
    self:refresh()
end

function tframe:draw_window()
    local w = self:window()
    local focused = self.parent and self.parent.state.focused
    local attr = self.attr + (focused and _cui.A_BOLD or 0)

    w:attrset(attr)
    w:clear()
    w:border()
    if (self.title) then
        local len = string.len(self.title)
        local title = _cui.new_chstr(len + 4)
        title:set_str(1, ' '..self.title..' ', attr)
        if (focused) then
            title:set_ch(0, _cui.ACS_RTEE, attr)
            title:set_ch(len+3, _cui.ACS_LTEE, attr)
        else
            title:set_ch(0, _cui.ACS_HLINE, attr)
            title:set_ch(len+3, _cui.ACS_HLINE, attr)
        end
        local x = math.floor((self.size.x - len - 4) / 2)
        w:mvaddchstr(0, x > 0 and x or 0, title)
    end
end

function tframe:handle_event(event)
    self.inherited.tview.handle_event(self, event)

    if (event.type == tevent.ev_broadcast) then
        if (event.command == tevent.be_focused and event.extra.window == self.parent) then
            self:refresh()
        end
    end
end

-- exported names
_cui.tframe = tframe
