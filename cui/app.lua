--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: app.lua,v 1.2 2004/05/22 17:17:26 tngd Exp $
--------------------------------------------------------------------------]]

-- dependencies
require 'cui'
require 'cui/menubar'
require 'cui/statusbar'
require 'cui/desktop'

-- locals
local _cui, cui = cui, nil  -- make sure we don't use 'cui' directly
local class = _cui.class
local tevent = _cui.tevent
local trect = _cui.trect
local tview = _cui.tview
local tgroup = _cui.tgroup
local tmenubar = _cui.tmenubar
local tstatusbar = _cui.tstatusbar
local tdesktop = _cui.tdesktop

--[[ tapp ]-----------------------------------------------------------------

* what can be accessed after initialization
cui.app
cui.app.menu_bar
cui.app.menu_bar
cui.app.desktop
cui.app.desktop.background

--]]------------------------------------------------------------------------
local tapp = class('tapp', _cui.tprogram)

function tapp:tapp(bounds)
    self:tprogram(bounds)

    -- framework interface
    _cui.app = self
    -- framework interface
    self.status_bar = self:init_status_bar()
    self.menu_bar = self:init_menu_bar()
    self.desktop = self:init_desktop()

    if (self.status_bar) then   self:insert(self.status_bar) end
    if (self.menu_bar) then     self:insert(self.menu_bar)   end
    if (self.desktop) then      self:insert(self.desktop)    end
end

function tapp:init_status_bar()
    return cui.tstatusbar:new(cui.trect:new(0, self.size.y - 1, self.size.x, self.size.y),
        {
            --Key           Description     Event type      Event command   Visible
            { "AltX",       "Exit",         "ev_command",   "cm_quit",      true  },
        }
    )
end

function tapp:init_menu_bar()
    return tmenubar:new(trect:new(0, 0, self.size.x, 1))
end

function tapp:init_desktop()
    return tdesktop:new(trect:new(0, 1, self.size.x, self.size.y - 1))
end

function tapp:handle_event(event)
    self.inherited.tprogram.handle_event(self, event)

    if (event.type == tevent.ev_command and event.command == tevent.cm_quit) then
        self:end_modal(tevent.cm_quit)
    elseif (event.type == tevent.ev_keyboard) then
        local key = event.key_name
        if (key == "AltX") then
            self:end_modal(tevent.cm_quit)
        elseif (key == "CtrlL") then
            self:refresh()
        end
    end
end

-- exported names
_cui.tapp = tapp
