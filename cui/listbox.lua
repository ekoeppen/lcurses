--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: listbox.lua,v 1.4 2004/07/22 20:08:45 tngd Exp $
--------------------------------------------------------------------------]]

-- dependencies
require 'cui'

-- locals
local _cui, cui = cui, nil  -- make sure we don't use 'cui' directly
local class = _cui.class
local tevent = _cui.tevent
local tview = _cui.tview

--[[ tlistbox ]-------------------------------------------------------------
list selection from table

members:
    tlistbox.columns
    tlistbox.list
    tlistbox.position
    tlistbox.scrollbar
methods:
    tlistbox:tlistbox(bounds, columns, list, scollbar)
    tlistbox:draw_window()
    tlistbox:handle_event(event)
    tlistbox:set_list(list)
    tlistbox:set_scrollbar(scrollbar)
    tlistbox:set_columns(columns)
    tlistbox:set_position(index)
    tlistbox:get_str(index, width)          returns list[index][1]
    tlistbox:get_selected(index)            returns list[index].selected
    tlistbox:select_item(index, select)     list[index].selected = select


list format: { item, item, ..., item }
item format: { [1] = text, selected = true/false/nil }

Keys:
    Up              -- current = current - 1
    Down            -- current = current + 1
    Left, PageUp    -- current = current - self.size.x
    Right, PageDown -- current = current + self.size.x
    Space           -- select current

HOWTO:
    * virtual list:
        call listbox:set_list({ n = size })
        override
            tlistbox:get_str(index)
            tlistbox:select_item(index, selected)
            tlistbox:get_selected(index)
        [ listbox:set_count(count) -> listbox:set_list({n = count}) ]
--]]------------------------------------------------------------------------
local tlistbox = class('tlistbox', tview)

function tlistbox:tlistbox(bounds, columns, list, sbar)
    self:tview(bounds)
    -- new options
    self.options.single_selection   = true  -- single item selection

    -- options
    self.options.selectable = true
    -- grow
    self.grow.hix = true
    self.grow.hiy = true
    -- event mask
    self.event[tevent.ev_keyboard]  = true
    self.event[tevent.ev_broadcast] = true

    -- initialize
    self.list = {}
    self.position = 1
    self.top_item = 1

    self.nattr = _cui.make_color(_cui.COLOR_BLACK, _cui.COLOR_CYAN)
    self.sattr = _cui.make_color(_cui.COLOR_WHITE, _cui.COLOR_GREEN) + _cui.A_BOLD

    self:set_columns(columns)
    self:set_list(list)
    self:set_scrollbar(sbar)
end

function tlistbox:set_scrollbar(sbar)
    self.scrollbar = sbar
    if (sbar) then
        sbar:set_limit(table.getn(self.list), self.size.y)
        sbar:set_position(self.position)
    end
end

function tlistbox:set_columns(columns)
    self.columns = columns
    self.column_width = math.max(0, math.ceil((self.size.x - columns + 1) / columns))
end

function tlistbox:set_list(list)
    self.list = list or {}
    self:set_position(1)
end

function tlistbox:set_position(index)
    -- range check
    if (index < 1) then
        index = 1
    end
    if (index > table.getn(self.list)) then
        index = table.getn(self.list)
    end

    self.position = index
    -- make sure current item is visible
    local top = self.top_item
    if (index > 0) then
        if (self.columns > 1) then
            if (top > index) then
                top = math.floor((index - 1) / self.size.y) * self.size.y + 1
            elseif (index >= top + self.size.y * self.columns) then
                top = (math.floor((index - 1) / self.size.y) - self.columns + 1) * self.size.y + 1
            end
        else
            if (top > index) then
                top = index
            elseif (index >= top + self.size.y) then
                top = index - self.size.y + 1
            end
        end
    else
        top = 1
    end
    self.top_item = top

    -- update cursor
    self:set_state('cursor_visible', index > 0)
    if (index > 0) then
        local item = index - top
        local colw = self.column_width
        local col = math.floor((item) / self.size.y) + 1
        self:goto(col * (colw + 1) - colw, math.mod(item, self.size.y))
    end

    -- update scrollbar
    local sbar = self.scrollbar
    if (sbar) then
        sbar:set_position(index)
        sbar:refresh()
    end
end

function tlistbox:get_str(index, width)
    local list = self.list
    if (index > 0 and index <= table.getn(list)) then
        local str = list[index][1]
        do return string.sub(str..string.rep(' ', width), 1, width) end
        if (string.len(str) >= width) then
            return string.sub(str, 1, width)
        end
        return str .. string.rep(' ', width - string.len(str))
    else
        return string.rep(' ', width)
    end
end

function tlistbox:select_item(index, select)
    if (self.options.single_selection) then return end

    local list = self.list
    if (index > 0 and index <= table.getn(list)) then
        list[index].selected = select
    end
end

function tlistbox:selected(index)
    local list = self.list
    if (index > 0 and index <= table.getn(list)) then
        return list[index].selected
    end
end

function tlistbox:draw_window()
    local w = self:window()
    local item = self.top_item
    local index = self.position
    local cols = self.columns
    local colw = self.column_width
    local str = _cui.new_chstr(colw+1)
    local a_normal = self.nattr
    local a_select = self.sattr
    local attr
    local selected

    str:set_ch(colw, _cui.ACS_VLINE, a_normal)
    -- columns cicle
    for col = 1, cols do
        -- line cicle
        for line = 1, self.size.y do
            if (self.options.single_selection) then
                selected = item == index
            else
                selected = self:selected(item)
            end
            if (selected) then
                attr = a_select
                str:set_str(0, '<', attr)
                str:set_str(colw - 1, '>', attr)
            else
                attr = a_normal
                str:set_str(0, ' ', attr)
                str:set_str(colw - 1, ' ', attr)
            end

            str:set_str(1, self:get_str(item, colw-2), attr)
            w:mvaddchstr(line-1, col * (colw + 1) - colw - 1, str)

            item = item + 1
        end
    end
end

function tlistbox:handle_event(event)
    self.inherited.tview.handle_event(self, event)
    if (event.type == tevent.ev_broadcast) then
        if (event.command == tevent.be_scrollbar_changed) then
            if (self.scrollbar and event.extra == self.scrollbar) then
                self:set_position(self.scrollbar.position)
                self:refresh()
            end
        end
    elseif (event.type == tevent.ev_keyboard) then
        local key = event.key_name
        if (key == "Up") then
            self:set_position(self.position-1)
        elseif (key == "Down") then
            self:set_position(self.position+1)
        elseif (key == "PageUp" or key == "Left") then
            self:set_position(self.position-self.size.y)
        elseif (key == "PageDown" or key == "Right") then
            self:set_position(self.position+self.size.y)
        elseif (key == " ") then
            self:select_item(self.position, not self:selected(self.position))
        elseif (key == "Home" or key == "h" or key == "H") then
            self:set_position(1)
        elseif (key == "End" or key == "e" or key == "E") then
            self:set_position(table.getn(self.list))
        else
            return
        end
        self:refresh()
    end
end

-- exported names
_cui.tlistbox = tlistbox
