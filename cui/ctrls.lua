--[[ Console User Interface (_cui) - load all controls ]--------------------
Author: Tiago Dionizio (tngd@mega.ist.utl.pt)
$Id: ctrls.lua,v 1.3 2004/05/24 19:29:01 tngd Exp $
----------------------------------------------------------------------------
Available controls:
    label           tlabel:new(bounds, text, attr)
                    tlabel:set_text(text, attr)

    frame           tframe:new(bounds, title, attr)

-- NOTES -------------------------------------------------------------------


--[ todo ]------------------------------------------------------------------
* tstatusbar
    * push state - push list to change key bindings temporarily
    * update conditions to show/hide/enable/disable shortcuts
* twindow
    * resize/move

--[ todo ]------------------------------------------------------------------
* menus

* message box
    * message_box(text, title, buttons = { { title, command [, default|cancel = true/false] }, ... })

--]]------------------------------------------------------------------------

require 'cui'
require 'cui/app'
require 'cui/button'
require 'cui/clock'
require 'cui/desktop'
require 'cui/dialog'
require 'cui/edit'
require 'cui/frame'
require 'cui/label'
require 'cui/listbox'
require 'cui/memory'
require 'cui/menubar'
require 'cui/scrollbar'
require 'cui/statusbar'
require 'cui/window'
