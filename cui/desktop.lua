--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: desktop.lua,v 1.2 2004/05/22 17:17:26 tngd Exp $
--------------------------------------------------------------------------]]

-- dependencies
require 'cui'
require 'cui/window'
require 'cui/scrollbar'
require 'cui/listbox'

-- locals
local _cui, cui = cui, nil  -- make sure we don't use 'cui' directly
local class = _cui.class
local tevent = _cui.tevent
local trect = _cui.trect
local message = _cui.message
local tview = _cui.tview
local tgroup = _cui.tgroup
local twindow = _cui.twindow
local tscrollbar = _cui.tscrollbar
local tlistbox = _cui.tlistbox

--[[ tdesktop ]-------------------------------------------------------------

--]]------------------------------------------------------------------------
local tdesktop = class('tdesktop', tgroup)

function tdesktop:tdesktop(bounds)
    self:tgroup(bounds)
    self.grow.hix = true
    self.grow.hiy = true

    self.background = self:init_background()
    self:insert(self.background)
end

function tdesktop:init_background()
    local bg = tview:new(trect:new(0, 0, self.size.x, self.size.y))
    bg.grow.hix = true
    bg.grow.hiy = true
    function bg:draw_window()
        local w = self:window()
        local len = self.size.x
        local str = _cui.new_chstr(len)
        str:set_ch(0, _cui.ACS_BLOCK, _cui.make_color(_cui.COLOR_BLUE, _cui.COLOR_BLUE) + _cui.A_BOLD, len)
        for y = 0, self.size.y - 1 do
            w:mvaddchstr(y, 0, str)
        end
    end
    return bg
end

function tdesktop:list_windows()
    -- window size
    local size = self.size:clone():sub(20, 10)

    -- window
    local wl = twindow:new(trect:new(0, 0, size.x, size.y), 'Window list')
    wl.options.centerx = true
    wl.options.centery = true

    -- scrollbar
    local sbar = tscrollbar:new(trect:new(size.x - 1, 1, size.x, size.y - 1))

    -- create window list
    local list = {}
    self:foreach(function(w)
        if (w.inherited.twindow) then
            table.insert(list, 1, { w.title, window = w })
        end
    end)

    -- create list
    local listbox = tlistbox:new(trect:new(1, 1, size.x - 1, size.y - 1), 1, list, sbar)
    wl:insert(listbox)
    wl:insert(sbar)
    wl:select_next(true)

    -- window handler
    function wl:handle_event(event)
        self.inherited.twindow.handle_event(self, event)

        if (event.type == event.ev_keyboard) then
            local key = event.key_name
            if (key == "Enter") then
                self:end_modal(tevent.cm_ok)
            elseif (key == "Backspace" or key == "Esc") then
                self:end_modal(tevent.cm_cancel)
            end
        end
    end

    -- show window - modal
    if (self:exec_view(wl) == tevent.cm_ok) then
        local item = list[listbox.position]
        if (item and item.window) then
            self:select(item.window)
        end
    end

    -- free window
    wl:close()
end

function tdesktop:handle_event(event)
    self.inherited.tgroup.handle_event(self, event)

    if (event.type == tevent.ev_command) then
        if (event.command == tevent.cm_prev) then
            if (self._current:is_valid(tevent.cm_release_focus)) then
                self:lock()
                self:select_next(false, nil)
                self:redraw(true)
                self:unlock()
            end
        elseif (event.command == tevent.cm_next) then
            local current = self._current
            if (current and current ~= self.background._next and current:is_valid(tevent.cm_release_focus)) then
                self:lock()
                self:select_next(true, nil)
                self:redraw(true)
                self:unlock()
            end
        end
    elseif (event.type == tevent.ev_keyboard) then
        local key = event.key_name
        if (key == 'Alt0') then
            self:list_windows()
            event.type = nil
        elseif (string.find(key, "Alt", 1, true) == 1) then -- Alt-number
            local number = tonumber(string.sub(key, 4)) or -1
            if (number >= 0 and number <= 9) then
                message(self, tevent.ev_broadcast, tevent.be_select_window_number, number)
            end
        end
    end
end

-- exported names
_cui.tdesktop = tdesktop
