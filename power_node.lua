local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function config_val(name)
    local s = trim(fs.open(name..".txt", "r").readAll())
    if s == "" then return nil end
    return s
end

local mod = peripheral.find("modem")

mod.open(80)

local side = config_val("output_side")
local str_invert = config_val("inverted")
local invert = false
if str_invert == "true" then
    invert = true
end

while true do
    ev = {os.pullEvent("modem_message")}
    m = ev[5]
    if m.msg ~= nil and m.msg == "set_power" then
        state = m.state
        if invert then
            state = not state
        end
        print(string.format("Set %s to %s", side, state))
        redstone.setOutput(side, state)
    end
end
