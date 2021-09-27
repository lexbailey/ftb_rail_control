local tank1 = "left"
local tank2 = "right"
local pump = "bottom"
local pump2 = "back"

local function level(side)
    return redstone.getAnalogInput(side)
end

local function yield()
    os.queueEvent("")
    os.pullEvent()
end

local on = false
local on2 = false

while true do
    local t1l = level(tank1)
    local t2l = level(tank2)
    if on and (t2l > t1l or t1l <= 12) then
        on = false
    elseif not on and (t1l == 15 or (t1l > 12 and t2l < t1l)) then
        on = true
    end
    if on2 and (t1l < 15) then
        on2 = false
    elseif not on2 and t1l == 15 then
        on2 = true
    end
    redstone.setOutput(pump, on)
    redstone.setOutput(pump2, on2)
    print("pump1 on?", on, "levels:", t1l, t2l, "pump2 on?", on2)
    os.sleep(2)
    yield()
end
