--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: edit.lua,v 1.3 2004/05/23 21:19:29 tngd Exp $
--------------------------------------------------------------------------]]

-- dependencies
require 'cui'

-- locals
local _cui, cui = cui, nil  -- make sure we don't use 'cui' directly
local class = _cui.class
local tevent = _cui.tevent
local tview = _cui.tview

--[[ tedit ]----------------------------------------------------------------
Members:
    tedit.text      -- text entered
    tedit.maxlen    -- maximum length of text
    tedit.startsel  -- selection start
    tedit.endsel    -- selection end
    tedit.start     -- offset of text to draw on window
Methods:
    tedit:tedit(bounds, text, maxlen, readonly)
    tedit:get_text()
    tedit:set_text(text, startsel, endsel)
    tedit:get_maxlen()
    tedit:set_maxlen(maxlen)
    tedit:get_selection()
    tedit:set_selection(startsel, endsel)
--]]------------------------------------------------------------------------

local tedit = class('tedit', tview)

local function tedit_forward(self)
    local cursor = self:cursor()
    if (cursor.x + self.start - 1 < string.len(self.text)) then
        if (cursor.x < self.size.x - 1) then
            self:goto(cursor.x + 1, cursor.y)
        else
            self.start = self.start + 1
        end
    end
end

local function tedit_backward(self)
    local cursor = self:cursor()
    if (cursor.x > 1 or self.start > 0) then
        if (cursor.x > 1) then
            self:goto(cursor.x - 1, cursor.y)
        else
            self.start = self.start - 1
        end
    end
end

function tedit:tedit(bounds, text, maxlen, readonly)
    self:tview(bounds)
    -- options
    self.options.selectable = true
    -- events
    self.event[tevent.ev_keyboard] = true
    -- state
    self:set_state('cursor_visible', true)

    -- initialize
    self.ncolor = _cui.make_color(_cui.COLOR_WHITE, _cui.COLOR_BLUE)
    self.scolor = _cui.make_color(_cui.COLOR_CYAN, _cui.COLOR_BLUE)

    self.maxlen = maxlen or 0
    self.readonly = readonly or false
    self.start = 0
    self.position = 0
    self:set_text(text, 1, string.len(text)+1)
end

function tedit:draw_window()
    local line = _cui.new_chstr(self.size.x)
    local start = self.start
    local text = self.text
    local len = string.len(text)
    local ss = self.startsel
    local es = self.endsel
    local nattr = self.ncolor
    local sattr = self.scolor

    if (self.size.x > 0) then
        line:set_ch(0, self.start == 0 and ' ' or _cui.ACS_LARROW, nattr)
        line:set_ch(self.size.x - 1, (self.start + self.size.x - 2 >= len) and ' ' or _cui.ACS_RARROW, nattr)
    end

    for i = 1, self.size.x - 2 do
        local idx = i + start
        if (idx <= len) then
            local ch = string.sub(text, idx, idx)

            if (idx >= ss and idx < es) then
                line:set_str(i, ch, sattr)
            else
                line:set_str(i, ch, nattr)
            end
        else
            line:set_ch(i, ' ', nattr)
        end
    end

    self:window():mvaddchstr(0, 0, line)
end

function tedit:handle_event(event)
    self.inherited.tview.handle_event(self, event)

    if (event.type == tevent.ev_keyboard) then
        local key = event.key_name
        local key_code = event.key_code
        local meta = event.key_meta
        local cursor = self:cursor()

        if (key == "Left") then
            tedit_backward(self)
        elseif (key == "Right") then
            tedit_forward(self)
        elseif (key == "CtrlB") then
            self:set_selection(self.start + cursor.x, self.endsel)
        elseif (key == "CtrlE") then
            self:set_selection(self.startsel, self.start + cursor.x)
        elseif (key == "Home") then
            self.start = 0
            self:goto(1, 0)
        elseif (key == "End") then
            local len = string.len(self.text)
            local start = len - self.size.x + 2
            self.start = start < 0 and 0 or start
            self:goto(len - self.start + 1, 0)
        elseif (self.readonly) then
            -- stop processing keysif read only control
        elseif (key == "Backspace") then
            local idx = self.start + cursor.x - 1
            if (idx > 0) then
                local text = self.text
                self.text = string.sub(text, 1, idx - 1) .. string.sub(text, idx + 1)
                tedit_backward(self)
            end
            self:set_selection(0, 0)
        elseif (key == "Delete") then
            if (self.startsel ~= self.endsel) then
                local text = self.text
                self.text = string.sub(text, 1, self.startsel - 1) .. string.sub(text, self.endsel)
                if (self.startsel <= self.start) then
                    self.start = self.startsel - 1
                end
                self:goto(self.startsel - self.start, 0)
            else
                local idx = self.start + cursor.x - 1
                local text = self.text
                if (idx < string.len(text)) then
                    self.text = string.sub(text, 1, idx) .. string.sub(text, idx + 2)
                    --tedit_backward(self)
                end
            end
            self:set_selection(0, 0)
        elseif (_cui.isprint(key_code) and string.len(key) == 1 and not meta) then
            local idx = self.start + cursor.x - 1

            local text = self.text
            if (string.len(text) < self.maxlen) then
                self.text = string.sub(text, 1, idx) ..key.. string.sub(text, idx + 1)
                tedit_forward(self)
            else
                _cui.beep()
            end

            self:set_selection(0, 0)
        else
            return
        end
        self:refresh()
    end
end

function tedit.get_text()
    return self.text
end

function tedit:set_text(text, startsel, endsel)
    -- check maxlen
    if (self.maxlen > 0 and string.len(text) > self.maxlen) then
        text = string.sub(text, 1, self.maxlen)
    end
    self.text = text

    -- set visible index
    local len = string.len(text)
    if (len > self.size.x - 2) then
        self.start = len - self.size.x + 2
    else
        self.start = 0
    end
    self:goto(len - self.start + 1, 0)

    self:set_selection(startsel, endsel)
end

function tedit:get_maxlen()
    return self.maxlen
end

function tedit:set_maxlen(maxlen)
    self.maxlen = maxlen or 0
    self:set_text(self.text, self.startsel, self.endsel)
end

function tedit:get_selection()
    return self.startsel, self.endsel
end

function tedit:set_selection(startsel, endsel)
    startsel = startsel or self.startsel
    endsel = endsel or startsel or self.endsel

    local len = string.len(self.text)
    if (startsel > endsel or startsel > len or endsel > len + 1) then
        startsel = 0
        endsel = 0
    end

    self.startsel = startsel
    self.endsel = endsel
end

-- exported names
_cui.tedit = tedit
