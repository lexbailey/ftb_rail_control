local modem = peripheral.find("modem")
local mon = peripheral.find("monitor")

modem.open(51)

local cells = {}

local function index_to_coords(i)
    local pattern = {10,9,9,9,9,9,9,10}
    local x = 1
    local y = i
    while y > pattern[x] do
        y = y - pattern[x]
        x = x + 1
    end
    return x, y
end

local function coords_to_index(x, y)
    local pattern = {10,9,9,9,9,9,9,10}
    local index = 0
    for i=1, x-1 do
        local to_add = pattern[i]
        if to_add == nil then return nil; end
        index = index + to_add
    end
    return index+y
end

local function scoords_to_index(sx, sy)
    local x = math.floor((sx - 1)/7)+1
    local y = math.floor((sy - 1)/5)+1
    local index = coords_to_index(x, y)
    return index
end

local function render()
    mon.clear()
    mon.setTextScale(0.5)
    local total_off = 0
    local total_on = 0
    local total_empty = 0
    for index=1,74 do
        local x, y = index_to_coords(index)
        local sx = ((x-1) * 7) + 1
        local sy = ((y-1) * 5) + 1
        local cell = cells[index]
        local status = "empty"
        local stat_col = colors.lightBlue
        if cell ~= nil then
            status = cell.status
            if status == "on" then
                stat_col = colors.lime
                total_on = total_on + 1
            elseif status == "off" then
                stat_col = colors.orange
                total_off = total_off + 1
            else
                stat_col = colors.red
            end

            if status == "on" then status = " on  "; end
            if status == "off" then status = " off "; end
        else
            total_empty = total_empty + 1
        end
        mon.setCursorPos(sx, sy)
        mon.write("+------")
        mon.setCursorPos(sx, sy+1)
        mon.write(string.format("|%2d    ", index))
        mon.setCursorPos(sx, sy+2)
        mon.write("|")
        mon.setTextColor(colors.black)
        mon.setBackgroundColor(stat_col)
        mon.write(status)
        mon.setBackgroundColor(colors.black)
        mon.setTextColor(colors.white)
        mon.write(" ")
        mon.setCursorPos(sx, sy+3)
        mon.write("|      ")
        mon.setCursorPos(sx, sy+4)
        mon.write("|      ")
        if y == 10 or (y == 9 and (x > 1 and x < 8)) then
            mon.setCursorPos(sx, sy+5)
            mon.write("+------")
        end
        if (x == 8) or (x == 1 and y == 10) then
            mon.setCursorPos(sx+7, sy)
            mon.write("+")
            mon.setCursorPos(sx+7, sy+1)
            mon.write("|")
            mon.setCursorPos(sx+7, sy+2)
            mon.write("|")
            mon.setCursorPos(sx+7, sy+3)
            mon.write("|")
            mon.setCursorPos(sx+7, sy+4)
            mon.write("|")
            mon.setCursorPos(sx+7, sy+5)
            mon.write("+")
        end

        mon.setCursorPos(15, 49)
        mon.write(" Right click cell to toggle")
        mon.setCursorPos(60, index+2)
        if index > 37 then
            mon.setCursorPos(90, index+2-37)
        end
        mon.write(string.format("%2d: ", index))
        if cell ~= nil then
            local name = cell.name
            if name == nil then name = ""; end
            mon.write(name)
        end
    end

    mon.setCursorPos(60, 1)
    mon.write(" -----V----- Available saplings -----V-----")

    mon.setCursorPos(120, 1)
    mon.write("--V--  Totals  --V--")
    mon.setCursorPos(120, 3)
    mon.setTextColor(colors.black)
    mon.setBackgroundColor(colors.lime)
    mon.write(string.format(" %2d cells are on    ", total_on))
    mon.setCursorPos(120, 5)
    mon.setBackgroundColor(colors.orange)
    mon.write(string.format(" %2d cells are off   ", total_off))
    mon.setCursorPos(120, 7)
    mon.setBackgroundColor(colors.lightBlue)
    mon.write(string.format(" %2d cells are empty ", total_empty))
    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.white)

    mon.setCursorPos(120, 12)
    mon.write("-V- Bulk actions -V-")
    mon.setTextColor(colors.black)
    mon.setBackgroundColor(colors.lime)
    mon.setCursorPos(120, 14)
    mon.write("                    ")
    mon.setCursorPos(120, 15)
    mon.write(" Turn all cells on  ")
    mon.setCursorPos(120, 16)
    mon.write("                    ")
    mon.setBackgroundColor(colors.orange)
    mon.setCursorPos(120, 18)
    mon.write("                    ")
    mon.setCursorPos(120, 19)
    mon.write(" Turn all cells off ")
    mon.setCursorPos(120, 20)
    mon.write("                    ")
    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.white)
end

render()

local function poll()
    modem.transmit(50,50, {msg="poll"})
end

local function set(cell, status)
    modem.transmit(50, 50, {msg="set", cell=cell, status=status})
end

poll()

while true do
    local ev = {os.pullEvent()}
    if ev[1] == "modem_message" then
        m = ev[5]
        message = m.msg
        if message == "node_config" then
            for k, v in pairs(m.conf) do
                cell = v.cell
                cells[cell] = v
                if v.status == nil then
                    set(cell, "off")
                end
            end
        end
    end
    if ev[1] == "monitor_touch" then
        local x = ev[3]
        local y = ev[4]
        local index = scoords_to_index(x, y)
        if index ~= nil then
            local cell = cells[index]
            if cell ~= nil then
                local status = cell.status
                if status == "on" then
                    status = "off"
                else
                    status = "on"
                end
                set(index, status)
            end
        end
        -- x is 120 to 139
        -- y is 14 to 16 for on
        -- y is 18 to 20 for off
        if x >= 120 and x <= 139 then
            local newstate = nil
            if y >= 14 and y <= 16 then
                newstate = "on"
            elseif y >= 18 and y <= 20 then
                newstate = "off"
            else
                -- no button clicked
            end
            if newstate ~= nil then
                for index=1,74 do
                    local cell = cells[index]
                    if cell ~= nil then
                        set(index, newstate)
                    end
                end
            end
        end
    end
    print(ev[1])
    render()
end
