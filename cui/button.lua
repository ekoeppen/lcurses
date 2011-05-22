--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: button.lua,v 1.3 2004/05/23 21:19:29 tngd Exp $
--------------------------------------------------------------------------]]

-- dependencies
require 'cui'

-- locals
local _cui, cui = cui, nil  -- make sure we don't use 'cui' directly
local class = _cui.class
local tevent = _cui.tevent
local message = _cui.message
local tview = _cui.tview

--[[ tbutton ]--------------------------------------------------------------
tbutton: tview

Members:
    tbutton.label
    tbutton.command

Methods:
    tbutton:tbutton(bounds, label, command)
    tbutton:draw_window()
    tbutton:handle_event(event)

on press: message(parent, ev_command, cm_xxxx, self)
--]]------------------------------------------------------------------------
local tbutton = class('tbutton', tview)

function tbutton:tbutton(bounds, label, command)
    self:tview(bounds)
    -- options
    self.options.selectable = true
    -- event mask
    self.event[tevent.ev_keyboard] = true
    -- state
    self:set_state('cursor_visible', true) -- track focus

    -- initialization
    self.label = label
    self.command = command
    self.fcolor = _cui.make_color(_cui.COLOR_YELLOW, _cui.COLOR_GREEN) + _cui.A_BOLD
    self.ncolor = _cui.make_color(_cui.COLOR_WHITE, _cui.COLOR_BLUE) + _cui.A_BOLD
    self:goto(math.floor((self.size.x - string.len(self.label)) / 2), 0)
end

function tbutton:draw_window()
    local w = self:window()
    local attr = self.state.focused and self.fcolor or self.ncolor
    local str = _cui.new_chstr(self.size.x)
    str:set_str(0, '['..string.rep(' ', self.size.x - 2)..']', attr)
    str:set_str(math.floor((self.size.x - string.len(self.label)) / 2), self.label, attr)
    w:mvaddchstr(0, 0, str)
end

function tbutton:handle_event(event)
    self.inherited.tview.handle_event(self, event)

    if (event.type == tevent.ev_keyboard) then
        local key = event.key_name
        if (key == 'Enter' or key == ' ') then
            message(self.parent, tevent.ev_command, self.command, self)
        end
    end
end

function tbutton:set_state(state, enable)
    self.inherited.tview.set_state(self, state, enable)

    if (state == "focused") then
        self:refresh()
    end
end

-- exported names
_cui.tbutton = tbutton
