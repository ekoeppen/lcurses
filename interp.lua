curses = require 'lcurses'

local lprint = print

local function _main_fun()
curses.init()
local blines = 5
local olines = 10
local lines, columns = curses.lines(), curses.columns()
local stdscr = curses.main_window()
-- create windows
w_out = stdscr:sub(lines - blines - olines, columns, olines, 0)
w_in = stdscr:sub(blines, columns, lines - blines, 0)

-- auto refresh
w_out:immedok(true)
w_in:immedok(true)

-- scroll region
w_in:scrollok(true)
w_out:scrollok(true)
w_out:wsetscrreg(1, lines - blines - olines - 2)

-- decoration
w_out:mvhline(lines - blines - olines - 1, 0, curses.ACS_HLINE, columns)
w_out:mvhline(0, 0, curses.ACS_HLINE, columns)
w_out:move(1, 0)

--w_out:wgetch()
print = function(...)
    for i = 1, arg.n do
        w_out:addstr(tostring(arg[i])..'\t')
    end
    w_out:addstr('\n')
end


local y, x, cmd, ok, msg
while (1) do
    y, x = w_in:getyx() w_in:move(y, x) w_in:refresh()
    cmd = w_in:getstr()
    print('>'..cmd)
    if (cmd == 'exit' or string.byte(cmd, 1, 1) == 4) then break; end
    cmd, msg = loadstring(cmd)
    ok = cmd
    if (cmd) then ok, msg = pcall(cmd) end
    if (not ok) then print('*** '..msg) end
end

end

local ok, msg = pcall(_main_fun)
curses.done()
print = lprint
if (not ok) then print(msg) end
