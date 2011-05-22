--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: window.lua,v 1.2 2004/05/22 17:17:26 tngd Exp $
--------------------------------------------------------------------------]]

-- dependencies
require 'cui'
require 'cui/frame'

-- locals
local _cui, cui = cui, nil  -- make sure we don't use 'cui' directly
local class = _cui.class
local tevent = _cui.tevent
local trect = _cui.trect
local tview = _cui.tview
local tgroup = _cui.tgroup
local tframe = _cui.tframe

--[[ twindow ]--------------------------------------------------------------
TODO:
    make frame optional
    window flags (frame, move, resize)
    event handling:
        move, resize

members:
    twindow.frame
    twindow.title
    twindow.window_number

methods:
    twindow:twindow(bounds, title, number)
    twindow:handle_event(event)
    twindow:is_valid(data)
    twindow:init_frame() virtual
    twindow:set_title(title)

--]]------------------------------------------------------------------------
local twindow = class('twindow', tgroup)

function twindow:twindow(bounds, title, number)
    self:tgroup(bounds)
    -- new options
    self.options.can_move       = true  -- move window using keyboard
    self.options.can_resize     = true  -- resize window using keyboard
    -- options
    self.options.top_select     = true
    -- members
    self.title = title
    self.window_number = number

    self.frame = self:init_frame()
    if (self.frame) then self:insert(self.frame) end
end

function twindow:set_title(title)
    self.title = title
    if (self.frame) then self.frame:set_title(title) end
end

function twindow:init_frame()
    return tframe:new(
        trect:new(0, 0, self.size.x, self.size.y),
        self.title,
        _cui.make_color(_cui.COLOR_WHITE, _cui.COLOR_BLUE)
    )
end

function twindow:handle_event(event)
    self.inherited.tgroup.handle_event(self, event)

    if (event.type == tevent.ev_broadcast) then
        if (event.command == tevent.be_select_window_number) then
            if (event.extra == self.window_number) then
                self.lock()
                self.parent:select(self) self:refresh()
                self:unlock()
            end
        end
    elseif (event.type == tevent.ev_command) then
        if (event.command == tevent.cm_close) then
            if (self.state.modal) then
                self:end_modal(tevent.cm_close)
            elseif (self:is_valid(tevent.cm_close)) then
                self:close()
            end
        end
    elseif (event.type == tevent.ev_keyboard) then
        local key = event.key_name
        if (key == "Tab") then
            self:select_next(true)
        elseif (key == "ShiftTab") then
            self:select_next(false)
        end
    end
end

function twindow:is_valid(data)
    if (not self.inherited.tgroup.is_valid(self, data) or
        (self.state.modal and (data == tevent.cm_release_focus or data == tevent.cm_quit))) then
            return false
    end
    return true
end

-- exported names
_cui.twindow = twindow
