local mod = peripheral.find("modem")
local mon = peripheral.find("monitor")

function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function config_val(name)
    return trim(fs.open(name..".txt", "r").readAll())
end

local loads = {}

local my_q = {}

local function pendEvents()
    os.queueEvent("empty")
    local done = false
    while not done do
        ev = {os.pullEvent()}
        done = ev[1] == "empty"
        if not done then
            table.insert(my_q, 1, ev)
        end
    end
end

local left_station = config_val("left_station")
local right_station = config_val("right_station")
local channel = tonumber(config_val("channel"))

mod.open(channel)

local function pullEvent()
    pendEvents()
    if #my_q == 0 then
        return os.pullEvent()
    end
    return unpack(table.remove(my_q))
end

local function yield()
    os.queueEvent("")
    pendEvents()
end

local timers = {}

local dispatch_log = {left="", right=""}

local function dispatch(side, reason)
    if side == "" then return; end
    print("Dispatch", side)
    redstone.setAnalogOutput(side, 6)
    timers[os.startTimer(2)] = {task="side", sides={[side]=0}}
    local newlog = dispatch_log[side] .. "," .. reason
    dispatch_log[side] = string.sub(newlog, math.max(0, string.len(newlog)-20))
    if string.sub(dispatch_log[side], 1, 1) == "," then
        dispatch_log[side] = string.sub(dispatch_log[side], 2)
    end
end

local function station_string(station_name)
    local station = loads[station_name]
    if station == nil then return " ??"; end
    return string.format(" %3d%% load (%s)", station.load, station.mode)
end

local function render_gui()
    mon.clear()
    mon.setCursorPos(1,1)
    mon.write(station_string(right_station))
    mon.setCursorPos(1,2)
    mon.write("====================")
    mon.setCursorPos(1,3)
    mon.write("      [][][][]      ")
    mon.setCursorPos(1,4)
    mon.write("====================")
    mon.setCursorPos(1,5)
    mon.write(station_string(left_station))
    mon.setCursorPos(1,7)
    mon.write("Dispatch reason log:")
    mon.setCursorPos(1,8)
    mon.write("  Right: "..dispatch_log["right"])
    mon.setCursorPos(1,9)
    mon.write("  Left: "..dispatch_log["left"])
    mon.setCursorPos(1,10)
    mon.write("Key: P=Purge Em=Empty Fu=Full")
    mon.setCursorPos(1,11)
    mon.write("     NS=No space to unload")
    mon.setCursorPos(1,12)
    mon.write("     NL=Nothing more to load")
end

local first_poll = true

local function set_empty_poll()
    local time = 300
    if first_poll then
        time = 30
        first_poll = false
    end
    timers[os.startTimer(time)] = {task="poll_empty"}
end

set_empty_poll()

render_gui()

while true do
    ev = {pullEvent()}
    if ev[1] == "modem_message" then
        local message = ev[5]
        local side = message.side
        local props = {load=message.load, mode=message.mode, time=os.clock()}
        local load = props.load
        loads[side] = props
        local mode = props.mode
        local time = props.time
        local output = ""
        if side == right_station then output = "right"; end
        if side == left_station then output = "left"; end
        if mode == "fill" then
            if load >= 100 then
                dispatch(output, "Fu")
            else
                timers[os.startTimer(15)] = {task="check_load", load=load, side=side}
            end
        end
        if mode == "drain" then
            if load <= 0 and ((os.clock() - time) > 3) then
                dispatch(output, "Em") -- very unlikely path
            else
                -- re-check time is lower for unload, because it's more consistent
                timers[os.startTimer(3)] = {task="check_load", load=load, side=side}
            end
        end
        render_gui()
    end
    if ev[1] == "timer" then
        local t = timers[ev[2]]
        timers[ev[2]] = nil
        if t ~= nil then
            if t.task == "side" then
                for side, value in pairs(t.sides) do
                    redstone.setAnalogOutput(side, value)
                end
            end
            if t.task == "poll_empty" then
                if loads[right_station] == nil then dispatch("right", "P"); end
                if loads[left_station] == nil then dispatch("left", "P"); end
                for side, props in pairs(loads) do
                    if props.mode == "drain" and props.load <= 0 then
                        local output = ""
                        if side == right_station then output = "right"; end
                        if side == left_station then output = "left"; end
                        dispatch(output, "Em")
                    end
                end
                set_empty_poll()
            end
            if t.task == "check_load" then
                local cur_load = loads[t.side]["load"]
                local mode = loads[t.side]["mode"]
                if mode == "fill" then
                    if cur_load > 0 and cur_load == t.load then
                        local output = ""
                        if t.side == right_station then output = "right"; end
                        if t.side == left_station then output = "left"; end
                        dispatch(output, "NL")
                    else
                        timers[os.startTimer(3)] = {task="check_load", load=cur_load, side=t.side}
                    end
                end
                if mode == "drain" then
                    if cur_load == t.load then
                        local output = ""
                        if t.side == right_station then output = "right"; end
                        if t.side == left_station then output = "left"; end
                        if cur_load <= 0 then
                            dispatch(output, "Em")
                        else
                            dispatch(output, "NS")
                        end
                    else
                        timers[os.startTimer(3)] = {task="check_load", load=cur_load, side=t.side}
                    end               
                end
            end
        end
        render_gui()
    end
end
