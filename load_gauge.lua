local function yield()
    os.queueEvent("")
    os.pullEvent()
end

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function config_val(name)
    return trim(fs.open(name..".txt", "r").readAll())
end

local mon = peripheral.find("monitor")
local mod = peripheral.find("modem")
local a = 0
local b = 0
local pa = -1
local pb = -1
local mode = config_val("mode")
local sidea = config_val("sidea")
local sideb = config_val("sideb")
local station_name =  config_val("station")
local channel = tonumber(config_val("channel"))

mon.clear()
mon.setTextScale(0.5)

while true do
    a = redstone.getAnalogInput(sidea)
    b = redstone.getAnalogInput(sideb)
    local redraw = (a ~= pa) or (b ~= pb)
    pa = a
    pb = b
    if redraw then
        local p = math.ceil((a+b)*100/30)
        mon.setBackgroundColor(colors.black)
        mon.setTextColor(colors.white)
        mon.clear()
        for l=1,5 do
            mon.setCursorPos(1,l+1)
            mon.write("[")
            mon.setBackgroundColor(colors.white) 
            mon.setTextColor(colors.black)
            for i=0,29 do
                if i < a+b then
                    mon.setBackgroundColor(colors.white)
                else
                    mon.setBackgroundColor(colors.black)
                end 
                mon.write(" ")
            end
            mon.setBackgroundColor(colors.black)
            mon.setTextColor(colors.white)
            mon.write("]")
            if l == 3 then
                mon.write(string.format("%3d", p))
                mon.write("%")
            end
        end
        mon.setCursorPos(6, 8)
        if mode == "fill" then
            if p >= 100 then
                mon.write("Ready for dispatch")
            elseif p <= 0 then
                mon.write("No load")
            else
                mon.write("Awiating greater load")
            end
        elseif mode == "drain" then
            if p > 0 then
                mon.write("Draining...")
            else
                mon.write("Empty")
            end
        end
        mod.transmit(channel, channel, {side=station_name, load=p, mode=mode})
    end
    yield()
end
