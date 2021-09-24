function mysplit (inputstr, sep)
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function config_val(name)
    local s = trim(fs.open(name..".txt", "r").readAll())
    if s == "" then return nil end
    return s
end

local left = config_val("left")
local right = config_val("right")

local config = {}

local next_index = 1
local index_table = {}

local function add_config(s, side)
    if s == nil then return end
    scell, id, name = unpack(mysplit(s, "|"))
    cell = tonumber(scell)
    print(cell, id, name, side)
    table.insert(config, {cell=cell, id=id, name=name, side=side})
    index_table[cell] = next_index
    next_index = next_index + 1
end

add_config(left, "left")
add_config(right, "right")

local modem = peripheral.find("modem")

modem.open(50)

local function send_config()
    print("Send config")
    modem.transmit(51, 51, {msg="node_config", conf=config})
end

send_config()

while true do
    local ev = {os.pullEvent()}
    if ev[1] == "modem_message" then
        m = ev[5]
        message = m.msg
        if message == "poll" then
            send_config()
        end
        if message == "set" then
            print("set", m.cell)
            local index = index_table[m.cell]
            if index ~= nil then
                config[index].status = m.status
                local side = config[index].side
                if m.status == "on" then
                    redstone.setAnalogOutput(side, 15)
                    print("Power on", side)
                else
                    redstone.setAnalogOutput(side, 0)
                    print("Power off", side)
                end
                send_config()
            end
        end
    end
end
