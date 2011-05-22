--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: __core.lua,v 1.6 2004/08/27 08:19:45 tngd Exp $
----------------------------------------------------------------------------
conventions:
    curses convention is to place y before x in function parameters, cui
  will use x before y

-- NOTES -------------------------------------------------------------------
-- TODO --------------------------------------------------------------------
cgroup:make_vis(pox, posy)
    scroll if needed to make position visible
cgroup:make_vis(window)
    scroll if needed to make window (or part of it) visible

//  Standard command codes

    cmValid         = 0,
    cmQuit          = 1,
    cmError         = 2,
    cmMenu          = 3,
    cmClose         = 4,
    cmZoom          = 5,
    cmResize        = 6,
    cmNext          = 7,
    cmPrev          = 8,
    cmHelp          = 9,

// TWindow Flags masks

    wfMove          = 0x01,
    wfGrow          = 0x02,
    wfClose         = 0x04,
    wfZoom          = 0x08,

-- LOW P. --
* handle interrupt signal?
* know when terminal window has been resized, and resize (at least) the main
  window
* handle process suspend/resume signals? believe this is done by the curses
driver (screen state)
--------------------------------------------------------------------------]]


--[[ localized functions from other libraries ]---------------------------]]
--[[
local math = math
local string = string
local io = io
local table = table

local require = require
local assert = assert
local type = type
local error = error
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local tostring = tostring
local unpack = unpack
--]]
local max = math.max
local min = math.min

assert(not cui, 'cui already loaded?')


--[[ object oriented interface ]--------------------------------------------
Syntax:
    <var> = class(name: string [, parent1 [, parent2 [, ...] ] ])

Example:
    c = class('test')

    -- constructor: constructor has the name of the class
    function c:test(x)
        self.x = x
    end

    -- new (always! virtual) method
    function c:call()
        print('test:call()')
    end

    -- implement the metamethod __tostring
    -- methametods are initialized at first instantiation of the class, so
    -- they cannot be defined after instantiation
    function c:__tostring()
        return "my test object ("..self.x..")"
    end

    -- __call
    function c:__call(...)
        print('function c:__call('..table.concat(arg, ', ')..')')
    end

    -- create a new instance of our class
    v = c:new(19)

    -- try __tostring
    print(v)
    v(10, 20)

    -- derive our class!
    d = class('derived', c)

    -- constructor
    function d:derived(x)
        self:test(x)
    end

    function d:__tostring()
        return "derived!"
    end

    function d:call()
        print('d:call()')
        self.inherited['test'].call(self)
    end

    v = d:new(10)

    -- try __tostring
    print(tostring(v))
    v('hello world!', ':)')
    v:call()
--------------------------------------------------------------------------]]
-- class definition function
local class

local class_metas = {
    "__add", "__sub", "__mul", "__div",
    "__pow", "__unm",
    "__eq", "__lt", "__le",
    "__concat", "__call", "__tostring"
}

function class(name, ...)
    local __parent  = arg
    local members = {
        __parent    = __parent,
        __name      = name,
    }
    local mt = {
        __metatable = members,
        __index     = members
    }

    -- function used to create a new instance of the function
    local init = false
    members.new = function(self, ...)
        -- initialize metatable metamethods
        if (not init) then
            for _, v in pairs(class_metas) do
                mt[v] = members[v]
            end
            init = true
        end

        -- set metatable
        local o = setmetatable({}, mt)
        -- call constructor
        o[name](o, unpack(arg))
        return o
    end

    -- function used to access parent
    local function inherit(t,name)
        -- recurse over the parent list
        local function inh(p)
            if (p.__name == name) then return p end
            p = p.__parent
            local b
            for i = 1, p.n do
                b = inh(p[i])
                if (b) then return b end
            end
        end
        return inh(members)
    end

    members.super = __parent[1]
    members.inherited = {}
    local imt = { __metatable = inherit, __index = inherit }
    setmetatable(members.inherited, imt)

    -- set metatable
    if (arg.n == 1) then
        -- default constructor - pass the parameters to the parent constructor
        local p = __parent[1]
        members[name] = function(self, ...)
            p[p.__name](self, unpack(arg))
        end
        -- only one parent class
        setmetatable(members, {__metatable = p, __index = p})
    elseif (arg.n > 1) then
        -- default constructor - pass the parameters to the parent constructors
        members[name] = function(self, ...)
            for i = 1, __parent.n do
                local p = __parent[i]
                p[p.__name](self, unpack(arg))
            end
        end
        -- several parent classes
        setmetatable(members, {
            __index = function(_, key)
                -- slow. need to go through all parents manualy
                for i = 1, arg.n do
                    local parentmethod = __parent[i][key]
                    if parentmethod then
                        return parentmethod
                    end
                end
            end,

            __metatable = __parent
        })
    end

    return members
end

--[[ load curses binding ]------------------------------------------------]]

require('requirelib')
local curses = requirelib('lcurses', 'luaopen_curses', true)


--[[ local utils ]--------------------------------------------------------]]
local function range(value, _min, _max)
    return min(_max, max(value, _min))
end

local function clog(...)
    local f = io.open('cui.log', 'a')
    for i = 1, arg.n do
        if (i > 1) then f:write('\t') end
        f:write(tostring(arg[i]))
    end
    f:write('\n')
    f:close()
    return unpack(arg)
end

--[[ util: enums ]--------------------------------------------------------]]
local function enum(t, list)
    local index = t[list[table.getn(list)]] or 0
    for i = 1, table.getn(list) - 1 do
        t[list[i]] = i + index
    end
end

--[[ NOTE ]-----------------------------------------------------------------
when using event enums, if one wishes to add new event names, first make
sure the name is not already defined. then use the enum function like shown
in the example:

    enum(tevent, { 'cm_resize', 'cm_max' })

the last item in the list is used as a 'tail' to increment indexes gradualy
--------------------------------------------------------------------------]]

--[[ Rect metatable ]-------------------------------------------------------
Members
    tpoint.x    -- number
    tpoint.y    -- number
Methods
    tpoint:tpoint(x, y)
    tpoint:tpoint(point)
    tpoint:assign(x, y)
    tpoint:assign(point)
    tpoint:clone()          -- return tpoint
    tpoint:add(x, y)
    tpoint:add(point)
    tpoint:sub(x, y)
    tpoint:sub(point)
    tpoint:equal(point)
--------------------------------------------------------------------------]]
local tpoint = class('tpoint')

function tpoint:tpoint(x, y)
    self:assign(x, y)
end

function tpoint:assign(x, y)
    if (not y) then
        self.x = x.x
        self.y = x.y
    else
        self.x = x
        self.y = y
    end
    return self
end

function tpoint:clone()
    return tpoint:new(self)
end

function tpoint:add(x, y)
    if (not y) then
        self.x = self.x + x.x
        self.y = self.y + x.y
    else
        self.x = self.x + x
        self.y = self.y + y
    end
    return self
end

function tpoint:sub(x, y)
    if (not y) then
        return self:add(-x.x, -x.y)
    else
        return self:add(-x, -y)
    end
end

function tpoint:equal(p)
    return self.x == p.x and self.y == p.y
end

--[[ Rect metatable ]-------------------------------------------------------
Members:
    trect.s -- tpoint (start)
    trect.e -- tpoint (end)
Methods:
    trect:assign(x1, y1, x2, y2)
    trect:assign(rect)
    trect:size()    -- return tpoint
    trect:clone()   -- return trect
    trect:move(deltax, deltay)
    trect:grow(deltax, deltay)
    trect:intersect(rect)
    trect:union(rect)
    trect:equal(rect)
    trect:contains(point)
    trect:empty()
    trect:nempty()
--------------------------------------------------------------------------]]
local trect = class('trect')

function trect:trect(x1, y1, x2, y2)
    self:assign(x1, y1, x2, y2)
end

function trect:assign(x1, y1, x2, y2)
    if (not y1) then
        self.s = x1.s:clone()
        self.e = x1.e:clone()
    else
        self.s = tpoint:new(x1, y1)
        self.e = tpoint:new(x2, y2)
    end
    return self
end

function trect:size()
    return self.e:clone():sub(self.s)
end

function trect:clone()
    return trect:new(self)
end

function trect:move(deltax, deltay)
    self.s:add(deltax, deltay)
    self.e:add(deltax, deltay)
    return self
end

function trect:grow(deltax, deltay)
    self.s:sub(deltax, deltay)
    self.e:add(deltax, deltay)
    return self
end

function trect:intersect(r)
    local s, e = self.s, self.e

    s.x = max(s.x, r.s.x)
    s.y = max(s.y, r.s.y)
    e.x = min(e.x, r.e.x)
    e.y = min(e.y, r.e.y)
    return self
end

function trect:union(r)
    local s, e = self.s, self.e

    s.x = min(s.x, r.s.x)
    s.y = min(s.y, r.s.y)
    e.x = max(e.x, r.e.x)
    e.y = max(e.y, r.e.y)
    return self
end

function trect:equal(r)
    return self.s:equal(r.s) and self.e:equal(r.e)
end

function trect:contains(x, y)
    return x >= self.s.x and x < self.e.x and y >= self.s.y and y < self.e.y
end

function trect:empty()
    return self.s.x >= self.e.x or self.s.y >= self.e.y
end

function trect:nempty()
    return not self:empty()
end

--[[ test trect ]----------------------------------------------------------]]
function tpoint:tostring()
    return '(' .. self.x .. ',' .. self.y ..')'
end

function trect:tostring()
    if (self:empty()) then
        return 'rect (empty)'
    else
        return 'rect (' .. self.s:tostring() .. ',' .. self.e:tostring() .. ')'
    end
end
--[[------------------------------------------------------------------------
a = trect:new(0, 0, 7, 7)
b = trect:new(2, 2, 4, 4)
c = trect:new(5, 5, 8, 9)

print('a', a:tostring())
print('b', b:tostring())
print('c', c:tostring())

print('b union c', b:clone():union(c):tostring())
print('b intersect c', b:clone():intersect(c):tostring())
print('a intersect c', a:clone():intersect(c):tostring())

os.exit()
--------------------------------------------------------------------------]]


--[[ local vairables ]------------------------------------------------------
--------------------------------------------------------------------------]]
local _cui                      -- private variable to access cui members

local cui_app                   -- application object
local main_window               -- main curses window
local screen_lock = 0           -- screen lock/update counter
local colors = {}               -- color pair list
local cursor_visibility         -- cursor state
local cursor = tpoint:new(0,0)  -- cursor position in screen
local event_queue = {}          -- event queue

-- defined later
local make_color
local get_key
local esc_delay
local init_keymap
local key_map

--[[ Basic Event class ]----------------------------------------------------
Members:
    tevent.type
    tevent.command
    tevent.extra
Methods:
    tevent:tevent(type, command, extra)

Other:
    message(receiver, type, command, extra)
--------------------------------------------------------------------------]]
local tevent = class('tevent')

function tevent:tevent(type, command, extra)
    self.type = type
    self.command = command
    self.extra = extra
end

-- send a message to a window
local function message(receiver, type, command, extra)
    if (receiver and receiver.inherited.tview) then
        local event = tevent:new(type, command, extra)
        receiver:handle_event(event)
        return event.extra
    end
end

--[[ Keyboard event ]-------------------------------------------------------
PLANS:

Members:
    tkeyboard_event.type        -- tevent.ev_keyboard
    tkeyboard_event.key_name    -- key name
    tkeyboard_event.key_code    -- key code
    tkeyboard_event.key_meta    -- ALT key was pressed
Methods:
    tkeyboard_event:tkeyboard_event(type, key, extra)
--------------------------------------------------------------------------]]
local tkeyboard_event = class('tkeyboard_event', tevent)

function tkeyboard_event:tkeyboard_event(type, key_code, key_name, key_meta)
    self.type = type
    self.key_code = key_code
    self.key_name = key_name
    self.key_meta = key_meta
end

--[[ Event defines ]--------------------------------------------------------
enumerated *constants*
--------------------------------------------------------------------------]]
-- event types
enum(tevent, {
    'ev_keyboard',
    'ev_command',
    'ev_broadcast',
    'ev_idle',
    'ev_max' })
-- known command event (ev_command)
enum(tevent, {
    -- application
    'cm_quit',      -- quit application

    -- window
    'cm_prev',      -- previous window
    'cm_next',      -- next window
    'cm_new',       -- new window
    'cm_close',     -- close window

    -- general commands
    'cm_ok',
    'cm_cancel',
    'cm_yes',
    'cm_no',

    -- view selection TODO
    'cm_leave',     -- unselect view
    'cm_enter',     -- select view

    --
    'cm_max' })
-- known broadcast events (ev_broadcast)
enum(tevent, {
    -- view
    'be_selected',  -- after select view
    'be_focused',   -- after focus view

    -- window
    'be_resize',    -- resize window
    'be_select_window_number',  -- send to select window number

    -- scroll bar
    'be_scrollbar_changed', -- extra = scrollbar

    --
    'be_max' })
--  known keyboard events (ev_keyboard)
enum(tevent, { 'ke_max' })

--[[ Base window object ]---------------------------------------------------
tview private members:
    tview._tag          -- internal/debug

    tview._bounds       -- trect
    tview._cursor       -- tpoint
    tview._window       -- curses window
    tview._full_redraw  -- [used internaly for drawing operations]
    tview._next
    tview._previous

tview public members:
    tview.size      -- tpoint

    -- flags
    tview.state.visible
    tview.state.cursor_visible
    tview.state.block_cursor
    tview.state.selected
    tview.state.focused
    tview.state.disabled
    tview.state.modal

    -- grow flags
    tview.grow.lox
    tview.grow.loy
    tview.grow.hix
    tview.grow.hiy

    -- options
    tview.options.selectable
    tview.options.top_select
    tview.options.pre_event
    tview.options.post_event
    tview.options.centerx
    tview.options.centery
    tview.options.validate

    -- event mask - wich commands to process
    tview.event[type]


tview methods:
    tview:tview(bounds)
    tview:close()
    tview:set_bounds(bounds)
    tview:bounds()          -- return _bounds:clone()
    tview:size_limits()     -- return tpoint, tpoint
    tview:calc_bounds(delta)    -- return trect
    tview:change_bounds(bounds)
    tview:handle_event(event)
    tview:get_event(event)
    tview:put_event(event)
    tview:is_valid(data)
    tview:end_modal(data)
    tview:window()
    tview:draw_window()
    tview:refresh()
    tview:redraw(onparent)
    tview:lock()
    tview:unlock()
    tview:goto(x, y)
    tview:cursor()  -- return tpoint
    tview:reset_cursor()
    tview:show(visible)
    tview:set_state(state_name, enable)
    tview:get_data(table)
    tview:set_data(table)


tgroup: tview

tgroup private members:
    tgroup._current
    tgroup._first

tgroup members:
    tgroup.scroll   -- tpoint

tgroup private methods:
    tgroup:draw_child(window)

tgroup public methods:
    tgroup:tgroup(bounds)
    tgroup:close()
    tgroup:foreach(function(window))
    tgroup:change_bounds(bounds)
    tgroup:max_bounds()     -- return bounds transformation where all windows will fit
    tgroup:scroll_to(x, y)
    tgroup:insert_before(window, next)
    tgroup:insert(window)
    tgroup:remove(child)
    tgroup:handle_event(event)
    tgroup:is_valid(data)
    tgroup:execute()
    tgroup:exec_view(window)
    tgroup:draw_window()
    tgroup:redraw(onparent)
    tgroup:refresh()
    tgroup:set_state(state_name, enable)
    tgroup:select_next(forward [, start])
    tgroup:select(child [, send_to_back])   -- send_to_back is used by select_next
    tgroup:get_data(data)
    tgroup:set_data(data)

--------------------------------------------------------------------------]]
local tview = class('tview')
local tgroup = class('tgroup', tview)

-- constructor
local _tag_num = 0
function tview:tview(bounds)
    assert(type(bounds) == 'table')

    -- flags
    self.state = {}
    self.state.visible          = false     -- window visibility
    self.state.cursor_visible   = false     -- cursor visibility
    self.state.block_cursor     = false     -- block cursor
    self.state.selected         = false     -- current selected window inside group
    self.state.focused          = false     -- true if parent is also focused
    self.state.disabled         = false     -- window state
    self.state.modal            = false     -- modal window

    -- grow flags
    self.grow = {}
    self.grow.lox               = false     --
    self.grow.loy               = false     --
    self.grow.hix               = false     --
    self.grow.hiy               = false     --

    -- options
    self.options = {}
    self.options.selectable     = false     -- true if window can be selected
    self.options.top_select     = false     -- if true, selecting window will bring it to front
    self.options.pre_event      = false     -- receive event before focused window
    self.options.post_event     = false     -- receive event after focused window
    self.options.centerx        = false     -- center horizontaly when inserting in parent
    self.options.centery        = false     -- center verticaly when inserting in parent
    self.options.validate       = false     -- validate

    -- event mask - wich commands to process
    self.event = {}

    -- cursor coords
    self._cursor = tpoint:new(0, 0)

    -- pad creation
    self:set_bounds(bounds)

    -- debug helper
    self._tag = _tag_num
    _tag_num = _tag_num + 1
end

-- constructor
function tgroup:tgroup(bounds)
    self:tview(bounds)

    -- options
    self.options.selectable     = true
    self.options.validate       = true

    -- event mask - enable by default on groups
    self.event[tevent.ev_broadcast] = true
    self.event[tevent.ev_command]   = true
    self.event[tevent.ev_keyboard]  = true
    self.event[tevent.ev_idle]      = true

    -- scroll position
    self.scroll = tpoint:new(0, 0)
end

--[[ destructor ]---------------------------------------------------------]]

function tgroup:close()
    self:show(false)
    while (self._first) do
        self._first:close()
    end
    self.inherited.tview.close(self)
end

function tview:close()
    if (self.parent) then
        self.parent:remove(self)
    end
    self._window:close()
    self._window = nil
end

--[[ helpers ]------------------------------------------------------------]]

--[[ tgroup:foreach ]-------------------------------------------------------
iterate through all child windows passing them to a callback function.
if the callback returns true, the iteration is stopped

usage:
    group:foreach(function(window)
        ...
        -- do something with the window
        ...
        -- return true
    end)
--------------------------------------------------------------------------]]
function tgroup:foreach(f)
    local first = self._first
    if (first) then
        local w = first
        repeat
            local next = w._next
            if (f(w)) then break end
            w = next
        until w == nil or w == first
    end
end


--[ bounds ]----------------------------------------------------------------

-- set window bounds
function tview:set_bounds(bounds)
    --assert(bounds.s.x >= 0 and bounds.s.y >= 0)
    --assert(bounds.e.x > bounds.s.x and bounds.e.y > bounds.s.y)

    if (self._window) then
        self._window:close()
    end
    self._bounds = bounds:clone()
    self.size = bounds:size()
    local s = self.size
    self._window = _cui.new_pad(s.y > 0 and s.y or 1, s.x > 0 and s.x or 1)
    self._window:leaveok(true)
    self._full_redraw = true
end

function tview:bounds()
    return self._bounds:clone()
end

function tview:size_limits()
    return tpoint:new(1, 1), tpoint:new(1000, 1000)
end

function tview:calc_bounds(delta)
    local bounds = self:bounds()
    local g = self.grow

    if (self.grow.lox) then bounds.s.x = bounds.s.x + delta.x end
    if (self.grow.hix) then bounds.e.x = bounds.e.x + delta.x end

    if (self.grow.loy) then bounds.s.y = bounds.s.y + delta.y end
    if (self.grow.hiy) then bounds.e.y = bounds.e.y + delta.y end

    local minl, maxl = self:size_limits()
    bounds.e.x = bounds.s.x + range(bounds.e.x-bounds.s.x, minl.x, maxl.x)
    bounds.e.y = bounds.s.y + range(bounds.e.y-bounds.s.y, minl.y, maxl.y)

    return bounds
end

function tview:change_bounds(bounds)
    self:set_bounds(bounds)
    self:refresh()
end

function tgroup:change_bounds(bounds)
    local size = bounds:size()
    -- verify size limits
    local minl, maxl = self:size_limits()
    if (minl.x > size.x or minl.y > size.y or maxl.x < size.x or maxl.y < size.y) then
        return
    end
    --
    local delta = size:sub(self.size)
    self:set_bounds(bounds)
    if (delta.x == 0 and delta.y == 0) then
        self:refresh()
    else
        self:lock()
        self:foreach(function(w)
            w:change_bounds(w:calc_bounds(delta))
        end)
        self:unlock()
    end
end

function tgroup:max_bounds()
    local bounds = self:bounds()
    self:foreach(function(w)
        bounds:union(w._bounds)
    end)
    return bounds
end

function tgroup:scroll_to(x, y)
    -- check bounds
    local mb = self:max_bounds()
    if (x < 0 or y < 0 or x > mb.e.x - mb.s.x - self.size.x or y > mb.e.y - mb.s.y - self.size.y) then
        return false
    end

    if (x ~= self.scroll.x or y ~= self.scroll.y) then
        self.scroll:assign(x,y)
    end
    return true
end

--[[ window management ]--------------------------------------------------]]

local function remove_view(g, w)
    if (w._next == w) then
        -- the only window in the list
        g._first = nil
    else
        w._previous._next = w._next
        w._next._previous = w._previous
        if (g._first == w) then
            g._first = w._next
        end
    end

    w._next = nil
    w._previous = nil
    w.parent = nil
end

local function insert_view(g, w, next)
    if (g._first == nil) then
        w._next = w
        w._previous = w

        g._first = w
    elseif (next == nil) then
        next = g._first

        w._previous = next._previous
        w._next = next
        next._previous._next = w
        next._previous = w

        g._first = w
    else
        w._previous = next._previous
        w._next = next
        next._previous._next = w
        next._previous = w
    end
    w.parent = g
end

function tgroup:insert_before(window, next)
    assert(not window.parent or window.parent == self)

    self:lock()

    if (window.parent == self) then self:remove(window) end

    -- center if options are set
    local bounds = window._bounds
    local org = bounds.s:clone()
    if (window.options.centerx) then
        org.x = math.floor((self.size.x - window.size.x) / 2)
    end
    if (window.options.centery) then
        org.y = math.floor((self.size.y - window.size.y) / 2)
    end
    bounds:move(org:sub(bounds.s))

    insert_view(self, window, next)

    if (window.options.selectable) then
        self:select(window)
    end

    window:draw_window()
    window:show(true)

    self:unlock()
end

function tgroup:insert(window)
    self:insert_before(window, self._first)
end

function tgroup:remove(window)
    window:show(false)

    remove_view(self, window)

    if (self._current == window) then
        self._current = nil
        self:select_next()
    end
end

--[[ event handling ]-----------------------------------------------------]]

-- abstract function -- handle an event
function tview:handle_event(event)
end

function tview:get_event()
    return self.parent:get_event()
end

function tview:put_event(event)
    return self.parent:put_event(event)
end

local function do_handle_event(group, event, phase)
    if (not group or not group._first) then return end

    if (phase < 0) then
        event.pre_event = true
        group:foreach(function(w)
            if (w.options.pre_event and w.event[event.type]) then
                w:handle_event(event)
            end
        end)
        event.pre_event = nil
    elseif (phase == 0) then
        if (event.type ~= tevent.ev_broadcast and event.type ~= tevent.ev_idle) then
            local current = group._current
            if (current and current.event[event.type]) then
                current:handle_event(event)
            end
        else
            group:foreach(function(w)
                if (w.event[event.type]) then
                    w:handle_event(event)
                end
            end)
        end
    elseif (phase > 0) then
        event.post_event = true
        group:foreach(function(w)
            if (w.options.post_event and w.event[event.type]) then
                w:handle_event(event)
            end
        end)
        event.post_event = nil
    end
end


function tgroup:handle_event(event)
    do_handle_event(self, event, -1)
    do_handle_event(self, event, 0)
    do_handle_event(self, event, 1)
end

function tview:is_valid(data)
    return true
end

function tgroup:is_valid(data)
    local current = self._current
    if (current and current.options.validate) then
        return current:is_valid(data)
    end
    return true
end

function tview:end_modal(data)
    -- try to find modal window, else, use the top window
    local w = self
    while (not w.state.modal and w.parent) do
        w = w._next
    end
    if (not w.state.modal) then
        w = self
    end
    if (w:is_valid(data)) then
        w.modal_state = data
    end
end

local function exec_view(window, parent, modal)
    assert(window)

    local save_current
    modal = modal or false
    --
    window:set_state('modal', modal)
    if (parent) then
        save_current = parent._current
        parent:insert(window)
    else
        window:show(true)
    end
    --
    local event
    local will_sleep
    window.modal_state = nil
    repeat
        event = window:get_event()
        if (event) then
            window:handle_event(event)
            will_sleep = false
        else
            -- idle action
            will_sleep = not message(cui_app, tevent.ev_idle)
        end

        --
        if (will_sleep and not window.modal_state) then
            _cui.napms(50)
        end
    until window.modal_state
    --
    if (parent) then
        window:lock()
        window:show(false)
        parent:remove(window)
        parent._current = save_current
        window:unlock()
    else
        window:show(false)
    end
    window:set_state('modal', not modal)
    --
    return window.modal_state
end

-- main loop!
function tgroup:execute()
    return exec_view(self)
end

-- run a modal window (dialog)
function tgroup:exec_view(window)
    return exec_view(window, self, true)
end

--[[ drawing members ]----------------------------------------------------]]

function tview:window()
    return self._window
end

-- return the focused window
local function top_window()
    local w = cui_app
    while (w._current) do
        w = w._current
    end
    return w
end

local function update_screen()
    if (cui_app and cui_app.state.visible) then
        --io.stderr:write(_TRACEBACK('update screen'), '\n')

        -- update screen
        cui_app._window:copy(main_window, 0, 0, 0, 0, cui_app.size.y-1, cui_app.size.x-1)

        local topw = top_window()
        local cvis

        if (not topw.state.cursor_visible) then
            cvis = 0
        elseif (topw.state.block_cursor) then
            cvis = 2
        else
            cvis = 1
        end

        local cursor = topw:cursor()
        local tcursor
        if (cvis ~= 0) then
            local w = topw
            while (w.parent) do
                -- make update coords
                cursor:add(w._bounds.s)
                cursor:sub(w.parent.scroll)

                -- is cursor visible?
                if (cursor.x < 0 or cursor.y < 0 or cursor.x >= w.parent.size.x or cursor.y >= w.parent.size.y) then
                    cvis = 0
                    break
                end
                w = w.parent
            end

        end

        if (cursor_visibility ~= cvis) then
            cursor_visibility = cvis;
            _cui.cursor_set(cvis)
        end
        if (cvis ~= 0) then
            main_window:move(cursor.y, cursor.x)
        else
            main_window:move(cui_app.size.y-1, cui_app.size.x-1)
        end
        main_window:noutrefresh()

        _cui.doupdate()
    end
end

--
function tview:draw_window()
    self:window():clear()
end

-- print self in parent window
function tview:refresh()
    self:draw_window()
    self:redraw(true)
end

function tview:redraw(onparent)
    if (onparent and self.parent) then
        self:lock()
        local w = self
        while (w.parent) do
            w.parent:draw_child(w)
            w = w.parent
        end
        self:unlock()
    end
end

-- drawing interface
function tgroup:draw_window()
    -- draw sub windows
    self:foreach(function(w)
        if (w.state.visible) then
            w:draw_window()
        end
    end)
end

local function draw_child(group, window)
    -- bounds check, etc etc, draw child in pad
    local gw = group.size.x
    local gh = group.size.y
    local scroll = group.scroll
    local r = window:bounds()
    local sx = r.s.x - scroll.x sx = sx > 0 and 0 or -sx
    local sy = r.s.y - scroll.y sy = sy > 0 and 0 or -sy

    r:move(-scroll.x, -scroll.y):intersect(trect:new(0, 0, gw, gh))

    if (r.e.x > r.s.x and r.e.y - r.s.y) then
        window._window:copy(group._window, sy, sx, r.s.y, r.s.x, r.e.y-1, r.e.x-1)
    end
end

function tgroup:redraw(onparent)
    self:lock()

    -- redraw sub windows
    self:foreach(function(w)
        if (w.state.visible) then
            -- cause groups to repaint
            w:redraw(false)
            -- draw sub window on personal window
            draw_child(self, w)
        end
    end)
    self.inherited.tview.redraw(self, onparent)

    self:unlock()
end

function tgroup:refresh()
    self:lock()

    -- repaint
    self:draw_window()
    -- refresh sub windows
    self:redraw(true)

    self:unlock()
end

-- private
function tgroup:draw_child(window)
    self:lock()
    local first = self._first
    local bounds = window:bounds()
    local w = window
    if (w._full_redraw) then
        w._full_redraw = nil
        w = self._first
    end
    repeat
        -- check for overlapping areas
        if (w.state.visible and w:bounds():intersect(bounds):nempty()) then
            draw_child(self, w)
            -- if they overlap, join them. use the resulting rectangle
            -- to check for overlapping areas on the following windows
            bounds:union(w._bounds)
        end

        w = w._next
    until w == first
    self:unlock()
end

function tview:lock()
    screen_lock = screen_lock + 1
end

function tview:unlock()
    assert(screen_lock > 0)
    screen_lock = screen_lock - 1
    if (screen_lock == 0) then
        update_screen()
    end
end

--[[ cursor handling ]----------------------------------------------------]]

-- move cursor
function tview:goto(x, y)
    self._cursor:assign(range(0, x, self.size.x-1), range(y, 0, self.size.y-1))
end

function tview:cursor()
    return self._cursor:clone()
end

function tview:reset_cursor()
    self:lock()
    self:unlock()
end

--[[ window state ]-------------------------------------------------------]]

function tview:show(visible)
    if (self.state.visible ~= visible) then
        self:set_state('visible', visible)
    end
end

function tview:set_state(state, enable)
    enable = enable or false
    self.state[state] = enable
    if (state == 'visible') then
        self._full_redraw = true
        self:redraw(true)
    elseif (state == 'selected') then
        message(self.parent, tevent.ev_broadcast, tevent.be_selected, { window = self, enable = enable })
    elseif (state == 'focused') then
        message(self.parent, tevent.ev_broadcast, tevent.be_focused, { window = self, enable = enable })
        self:reset_cursor()
    elseif (state == 'cursor_visible') then
        self:reset_cursor()
    elseif (state == 'block_cursor' and self.state.cursor_visible) then
        self:reset_cursor()
    end
end

function tgroup:set_state(state, enable)
    self.inherited.tview.set_state(self, state, enable)

    if (state == 'focused') then
        if (self._current) then
            self._current:set_state(state, enable)
        end
    end
end

--[[ window selection ]---------------------------------------------------]]
function tgroup:select_next(forward, start, send_to_back)
    if (not self._first) then return end

    local current = start or self._current or self._first
    if (forward) then
        local next = current._next
        while (next ~= current) do
            if (next.options.selectable and next.state.visible) then
                self:select(next, send_to_back)
                break
            end
            next = next._next
        end
    else
        local next = current._previous
        while (next ~= current) do
            if (next.options.selectable and next.state.visible) then
                self:select(next, true)
                break
            end
            next = next._previous
        end
    end
end

function tgroup:select(child, send_to_back)
    assert(child == nil or (child.parent == self and child.options.selectable))
    local current = self._current

    if (child == current) then return end

    if (current) then
        if (self.state.focused) then
            current:set_state('focused', false)
        end
        current:set_state('selected', false)

        if (current.options.top_select and send_to_back) then
            -- send current view to the back of the list
            local first = self._first
            local next
            if (first.options.selectable) then
                next = nil
            else
                next = first
                while (next ~= first._previous and not next.options.selectable) do
                    next = next._next
                end
            end

            if (current ~= next) then
                remove_view(self, current)
                insert_view(self, current, next)
            end
        end
    end

    self._current = child

    if (child) then
        if (child.options.top_select) then
            remove_view(self, child)
            insert_view(self, child, self._first)
        end

        child:set_state('selected', true)
        if (self.state.focused) then
            child:set_state('focused', true)
        end
    end
end

--[[ data get/set ]-------------------------------------------------------]]
function tview:get_data(data)
end

function tview:set_data(data)
end

function tgroup:get_data(data)
    self:foreach(function(w)
        w:get_data(data)
    end)
end

function tgroup:set_data(data)
    self:foreach(function(w)
        w:set_data(data)
    end)
end

--[[ tprogram ]-------------------------------------------------------------

tprogram: tgroup

Members:
    tprogram

Methods:
    tprogram:tprogram()
    tprogram:close()
    tprogram:set_bounds(bounds)
    tprogram:run()
    tprogram:get_event()
    tprogram:put_event()
--------------------------------------------------------------------------]]
local tprogram = class('tprogram', tgroup)

-- create main window group - should be the only group without a parent
function tprogram:tprogram()
    -- curses initialization
    main_window = assert(_cui and _cui.init())
    _cui.echo(false)
    _cui.cbreak(true)
    _cui.nl(false)
    _cui.map_output(true)
    _cui.map_keyboard(true)
    if (_cui.has_colors()) then _cui.start_color() end
    init_keymap()

    -- main window will be used to set the screen cursor and to handle
    -- keyboard events
    main_window:leaveok(false)
    main_window:keypad(true)
    main_window:nodelay(true)
    --main_window:notimeout(true)

    --[[library initialization done]]

    -- set main view object
    cui_app = self

    -- ancestor construction
    self:tgroup(trect:new(0, 0, _cui.columns(), _cui.lines()))
    self:set_state('selected', true)
    self:set_state('focused', true)
end

function tprogram:close()
    -- dispose all windows
    self.inherited.tgroup.close(self)

    -- unset main view object
    cui_app = nil

    --[[library finalization]]

    -- (attempt to) make sure the screen will be cleared
    -- if not restored by the curses driver
    main_window:clear()
    main_window:noutrefresh()
    _cui.doupdate()
    assert(not _cui.isdone())
    _cui.done()
end

function tprogram:set_bounds(bounds)
    --if (bounds:equal(trect:new(0, 0, _cui.columns(), _cui.lines()))) then
        self.inherited.tgroup.set_bounds(self, bounds)
    --else
    --    error('can not set the main application bounds')
    --end
end

function tprogram:run()
    return self:execute()
end

function tprogram:get_event()
    -- check event queue
    local event = event_queue[1]
    if (event) then
        table.remove(event_queue, 1)
        return event
    end

    -- check keyboard
    local key_code, key_name, key_meta = get_key()
    if (key_code) then
        if (key_name == "Resize" or key_name == "CtrlL") then
            self:change_bounds(trect:new(0,0,_cui.columns(),_cui.lines()))
            self:refresh()
        else
            return tkeyboard_event:new(tevent.ev_keyboard, key_code, key_name, key_meta)
        end
    end

    -- nothing to return...
    -- return
end

function tprogram:put_event(event)
    table.insert(event_queue, event)
end

--[[ lookup table to translate keys to string names ]---------------------]]
-- this is the time limit in ms within Esc-key sequences are detected as
-- Alt-letter sequences. useful when we can't generate Alt-letter sequences
-- directly. sometimes this pause may be longer than expected since the
-- curses driver may also pause waiting for another key (ncurses-5.3)
local esc_delay = 400

function init_keymap()
    local _cui = _cui
    key_map =
    {
        -- ctrl-letter codes
        [ 1] = "CtrlA", [ 2] = "CtrlB", [ 3] = "CtrlC",
        [ 4] = "CtrlD", [ 5] = "CtrlE", [ 6] = "CtrlF",
        [ 7] = "CtrlG", [ 8] = "CtrlH", [ 9] = "CtrlI",
        [10] = "CtrlJ", [11] = "CtrlK", [12] = "CtrlL",
        [13] = "CtrlM", [14] = "CtrlN", [15] = "CtrlO",
        [16] = "CtrlP", [17] = "CtrlQ", [18] = "CtrlR",
        [19] = "CtrlS", [20] = "CtrlT", [21] = "CtrlU",
        [22] = "CtrlV", [23] = "CtrlW", [24] = "CtrlX",
        [25] = "CtrlY", [26] = "CtrlZ",

        [  8] = "Backspace",
        [  9] = "Tab",
        [ 10] = "Enter",
        [ 13] = "Enter",
        [ 27] = "Escape",
        [ 31] = "CtrlBackspace",
        [127] = "Backspace",

        [_cui.KEY_DOWN      ] = "Down",
        [_cui.KEY_UP        ] = "Up",
        [_cui.KEY_LEFT      ] = "Left",
        [_cui.KEY_RIGHT     ] = "Right",
        [_cui.KEY_HOME      ] = "Home",
        [_cui.KEY_END       ] = "End",
        [_cui.KEY_NPAGE     ] = "PageDown",
        [_cui.KEY_PPAGE     ] = "PageUp",
        [_cui.KEY_IC        ] = "Insert",
        [_cui.KEY_DC        ] = "Delete",
        [_cui.KEY_BACKSPACE ] = "Backspace",
        [_cui.KEY_F1        ] = "F1",
        [_cui.KEY_F2        ] = "F2",
        [_cui.KEY_F3        ] = "F3",
        [_cui.KEY_F4        ] = "F4",
        [_cui.KEY_F5        ] = "F5",
        [_cui.KEY_F6        ] = "F6",
        [_cui.KEY_F7        ] = "F7",
        [_cui.KEY_F8        ] = "F8",
        [_cui.KEY_F9        ] = "F9",
        [_cui.KEY_F10       ] = "F10",
        [_cui.KEY_F11       ] = "F11",
        [_cui.KEY_F12       ] = "F12",

        [_cui.KEY_RESIZE    ] = "Resize",

        [_cui.KEY_BTAB      ] = "ShiftTab",
        [_cui.KEY_SDC       ] = "ShiftDelete",
        [_cui.KEY_SIC       ] = "ShiftInsert",
        [_cui.KEY_SEND      ] = "ShiftEnd",
        [_cui.KEY_SHOME     ] = "ShiftHome",
        [_cui.KEY_SLEFT     ] = "ShiftLeft",
        [_cui.KEY_SRIGHT    ] = "ShiftRight",
    }
end

function get_key()
    local ch = main_window:getch()
    if (not ch) then return end

    local alt = ch == 27

    if (alt) then
        ch = main_window:getch()
        if (not ch) then
            -- since there is no way to know the time with millisecond precision
            -- we pause the the program until we get a key or the time limit
            -- is reached
            local t = 0
            repeat
                _cui.napms(10) t = t + 10
                ch = main_window:getch()
            until ch or t >= esc_delay
            -- nothing was typed... return Esc
            if (not ch) then return "Esc" end
        end
        if (ch > 96 and ch < 123) then ch = ch - 32 end
    end

    local k = key_map[ch]
    local key_name
    if (k) then
        key_name = alt and "Alt"..k or k
    elseif (ch < 256) then
        key_name = alt and "Alt"..string.char(ch) or string.char(ch)
    else
        return nil
    end
    return ch, key_name, alt
end

--[[ color assignment ]---------------------------------------------------]]
function make_color(fg, bg)
    if (not _cui.has_colors()) then return 0 end
    local n = table.getn(colors)
    local c

    -- see if we have an existing color in list
    for _, c in ipairs(colors) do
        if (c.fg == fg and c.bg == bg) then
            return c.attr
        end
    end

    n = n + 1
    if (not _cui.init_pair(n, fg, bg)) then
        error('failed to initialize color pair ('..n..','..fg..','..bg..')')
    end

    -- add new color
    c = {
        fg = fg,
        bg = bg,
        attr = _cui.color_pair(n)
    }
    table.insert(colors, c)
    return c.attr
end

--[[ exported interface ]-------------------------------------------------]]
_cui = {
    -- OO function
    class = class,

    -- objects exported
    tpoint = tpoint,
    trect = trect,
    tview = tview,
    tgroup = tgroup,
    tevent = tevent,
    tkeyboard_event = tkeyboard_event,
    tprogram = tprogram,

    -- functions
    clog = clog,
    message = message,
    make_color = make_color,
}

--[[ make curses (table) members available through cui too ]--------------]]
setmetatable(_cui, { __index = curses })

--[[ export global names ]------------------------------------------------]]
cui = _cui
