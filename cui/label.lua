--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: label.lua,v 1.2 2004/05/22 17:17:26 tngd Exp $
--------------------------------------------------------------------------]]

-- dependencies
require 'cui'

-- locals
local _cui, cui = cui, nil  -- make sure we don't use 'cui' directly
local class = _cui.class
local tevent = _cui.tevent
local tview = _cui.tview

--[[ tlabel ]---------------------------------------------------------------
Members:
    tlabel.text
    tlabel.attr
Methods:
    tlabel:tlabel(bounds, text, attr)
    tlabel:set_text(text, attr)
    tlabel:draw_window()
--]]------------------------------------------------------------------------
local tlabel = class('tlabel', tview)

function tlabel:tlabel(bounds, text, attr)
    self:tview(bounds)
    self:set_text(text, attr)
end

function tlabel:set_text(text, attr)
    self.text = text or ''
    self.attr = tonumber(attr) or _cui.A_NORMAL
    self:refresh()
end

function tlabel:draw_window()
    local w = self:window()
    local width = self.size.x
    local str = _cui.new_chstr(width)
    local len = string.len(self.text)

    str:set_str(0, string.sub(self.text, 1, width)..string.rep(' ', width-len), self.attr)
    w:mvaddchstr(0, 0, str)
end

-- exported names
_cui.tlabel = tlabel
