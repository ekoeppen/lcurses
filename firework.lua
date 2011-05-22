
curses = require('lcurses')

local win

win = curses.init()
assert(win, 'failed to initialize curses')

local cp = curses.color_pair
local ip = curses.init_pair
local napms = curses.napms

local rand = math.random
local max = math.max
local abs = math.abs

local bold = curses.A_BOLD
local normal = curses.A_NORMAL
local black = curses.COLOR_BLACK
local lines
local columns

math.randomseed(os.time())

local colour_table = {
    [1] = curses.COLOR_RED,
    [2] = curses.COLOR_BLUE,
    [3] = curses.COLOR_GREEN,
    [4] = curses.COLOR_CYAN,
    [5] = curses.COLOR_RED,
    [6] = curses.COLOR_MAGENTA,
    [7] = curses.COLOR_YELLOW,
    [8] = curses.COLOR_WHITE
}

local function get_colour()
    return colour_table[rand(8)] + bold * rand(0, 1)
end

local function clear()
    win:clear()
end

local function update()
    win:move(lines - 1, columns - 1)
    win:refresh()
    napms(50)
end

local function mvsend(y, x, str)
    win:mvaddstr(y, x, str)
end

local function attrset(attr)
    win:attrset(attr)
end

local function explode(row, col)
    clear()
    mvsend(row, col, '-');
    update()

    ip(1, get_colour(), black)
    attrset(cp(1))
    mvsend(row-1, col-1, ' - ')
    mvsend(row, col - 1, '-+-')
    mvsend(row + 1,col - 1, ' - ')
    update();

    ip(1, get_colour(), black)
    attrset(cp(1))
    mvsend(row-2,col-2," --- ")
    mvsend(row-1,col-2,"-+++-")
    mvsend(row,  col-2,"-+#+-")
    mvsend(row+1,col-2,"-+++-")
    mvsend(row+2,col-2," --- ")
    update();

    ip(1, get_colour(), black)
    attrset(cp(1))
    mvsend(row-2,col-2," +++ ")
    mvsend(row-1,col-2,"++#++")
    mvsend(row,  col-2,"+# #+")
    mvsend(row+1,col-2,"++#++")
    mvsend(row+2,col-2," +++ ")
    update();

    ip(1, get_colour(), black)
    attrset(cp(1))
    mvsend(row-2,col-2,"  #  ")
    mvsend(row-1,col-2,"## ##")
    mvsend(row,  col-2,"#   #")
    mvsend(row+1,col-2,"## ##")
    mvsend(row+2,col-2,"  #  ")
    update();

    ip(1, get_colour(), black)
    attrset(cp(1))
    mvsend(row-2,col-2," # # ")
    mvsend(row-1,col-2,"#   #")
    mvsend(row,  col-2,"     ")
    mvsend(row+1,col-2,"#   #")
    mvsend(row+2,col-2," # # ")
    update()
end

local function _main()
    local start, finish, row, diff, flag, direction, str

    curses.cursor_set(0)
    win:nodelay(true)
    curses.echo(false)
    if (curses.has_colors()) then curses.start_color() end
    lines = curses.lines()
    columns = curses.columns()

    repeat

        repeat
            start = max(rand(0, columns - 4), 2)
            finish = max(rand(0, columns - 4), 2)
            if (start > finish) then
                direction = -1
            else
                direction = 1
            end
            diff = abs(start-finish)
        until (diff >= 2 and diff < lines - 2)
        attrset(normal)

        row = -1
        while (row < diff) do
            row = row + 1
            if (direction < 0) then str = '\\' else str = '/' end
            mvsend(lines - row, start + row * direction, str)
            if (flag) then
                update()
                clear()
                flag = false
            else
                flag = true
            end
        end

        if (flag) then
            update()
            flag = false
        else
            flag = true
        end

        explode(lines - row, start + diff * direction)
        clear()
        update()
    until win:getch()
    while win:getch() do end
end


local ok, msg = xpcall(_main, _TRACEBACK)
curses.done()

if (not ok) then print(msg) end
