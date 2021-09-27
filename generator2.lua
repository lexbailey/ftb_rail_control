local cap_inputs = {"left", "right"}
local generator_output = "top"

local function cap_total()
    local t = 0
    for k, v in pairs(cap_inputs) do
        local x = redstone.getAnalogInput(v)
        t = t + x
    end
    return t
end

local function cap_min()
    local m = 15
    for k, v in pairs(cap_inputs) do
        local x = redstone.getAnalogInput(v)
        m = math.min(m, x)
    end
    return m
end


local function yield()
    os.queueEvent("")
    os.pullEvent()
end

local on = false

while true do
    local t = cap_total()
    print("Charge level:", t)
    if on and t >= 25 then
        on = false
    elseif not on and t < 10 or cap_min() <= 0 then
        on = true
    end
    redstone.setOutput(generator_output, on)
    os.sleep(2)
    yield()
end
