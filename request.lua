local mod = peripheral.find("modem")

local channel = 30

local function yield()
    os.queueEvent("")
    os.pullEvent()
end

local items = {apple="right", hemp="left"}

local states = {apple=false, hemp=false}

while true do
    for name, side in pairs(items) do
        local state = states[name]
        local level = redstone.getAnalogInput(side)
        if state and level >= 15 then
            state = false
        elseif not state and level < 7 then
            state = true
        end
        states[name] = state
        mod.transmit(channel, channel, {msg="produce_ctrl", name=name, state=state})
        print(name, level, state)
    end
    os.sleep(10)
    yield()
end
