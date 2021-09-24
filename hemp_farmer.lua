
local clutch = "back"
local shift = "right"
local enable = "left"

local function yield()
    os.queueEvent("")
    os.pullEvent()
end

local function high(side)
    redstone.setOutput(side, true)
end

local function low(side)
    redstone.setOutput(side, false)
end

local function pulse(side, time)
    low(side)
    os.sleep(time)
    yield()
    high(side)
    os.sleep(0)
    yield()
end

local function steps(side, n, time)
    for i=1,n do
        pulse(side, time)
    end
end

local width = 1
while true do
    if redstone.getInput(enable) then
        low(shift)
        steps(clutch, 9, width)
        yield()
        high(shift)
        steps(clutch, 9, width)
        yield()
    else
        os.sleep(3)
        yield()
    end
end
