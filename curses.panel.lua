--[[------------------------------------------------------------------------
curses.panel.lua
support code for curses library
usage lua -lcurses.panel ...

Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: curses.panel.lua,v 1.2 2003/12/28 01:30:12 tngd Exp $
--]]------------------------------------------------------------------------

--[[ Documentation ---------------------------------------------------------

panel:close()

panel:make_bottom()
panel:make_top()
panel:show([boolean show])
panel:hide()
panel:hidden() (return boolean)

panel:window() (return window)
panel:replace(window)
panel:move(y, x)
panel:above() (return panel or nil)
panel:below() (return panel or nil)

panel:set_userdata(user)
panel:userdata() ( return user)

----------------------------------------------------------------------------

curses.new_panel(window)
curses.update_panels()
curses.bottom_panel() (return panel)
curses.top_panel() (return panel)

--]]------------------------------------------------------------------------
require('requireso')

requireso('lcurses', 'luaopen_panel', true)
