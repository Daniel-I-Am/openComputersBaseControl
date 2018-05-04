--[[------------------
  //  Authors:
  //  ========
  //  Program: Base Control
  //  Version: 3.0
  //  By: Daniel_I_Am & Plazter
  //  
  //  GUI Design: Plazter
  //  Original Idea & Execution: Plazter
  //  Recoding and improvements: Daniel_I_Am
  //  
  //  Description:
  //  ============
  //  This program can be used to control all kinds of things in and around you base. You can hook up anything to redstone i/o blocks and add them to a
  //  config file to automatically let it make buttons for you. If you hook up an adapater to a draconic evolution energy storage ball, statistics will
  //  be displayed as well. Even a draconic reactor can be hooked up (requires an adapter to 2 flux gates, in and out, and 1 to a reactor stabilizer).
  //  
  //  Configuration:
  //  ==============
  //  All config files are located in `/usr/config/baseControl/`. There are two files, `main.conf` and `component.conf`. In the main.conf, you must leave the keys intact, the values can be changed. In the component.conf, you can add your components as the format states.
  //  
  //  Installation:
  //  =============
  //  The program can be installed with the following command:
  //  `wget https://raw.githubusercontent.com/Daniel-I-Am/openComputersBaseControl/master/home/baseControl.lua /home/baseControl.lua;baseControl`
  //  This does require an internet connection.
  //  You are then able to start the program with `baseControl` (if located in the home directory). To switch to the home directory, you can just type `cd /home`.
  //  
  //  Updates:
  //  ========
  //  If you want to update the program, you can do so by running the program with the -u option. WARNING: This will reset your configuration, this is done, in case config flags are added/removed/changed. DO NOT COPY IN OLD CONFIG FILES.
  //  
--]]------------------

---------- IMPORT ----------
do --import
  component = require("component")
  term = require("term")
  event = require("event")
  sides = require("sides")
  computer = require("computer")
  os = require("os")
  keyboard = require("keyboard")
  shell = require("shell")
  fs = require("filesystem")
end

do --configure from import
  if component.isAvailable("internet") then internet = component.internet end
  if component.isAvailable("screen") then screen = component.screen end
  if component.isAvailable("gpu") then gpu = component.gpu end
end

do --make sure dependencies exist
  if fs.exists("/autorun.lua.baseControl.old") then --check if temp autorun file exists
    os.execute("rm /autorun.lua") --remove autorun made by this program
    os.execute("mv /autorun.lua.baseControl.old /autorun.lua") --restored old autorun
  end
  if not fs.exists("/lib/ButtonAPI.lua") or not fs.exists("/lib/danAPI.lua") then --check if missing dependencies
    if not fs.exists("/autorun.lua") then --check if there's an autorun
      os.execute("echo \"\">/autorun.lua") --flash the autorun file if not
    end
    os.execute("cp /autorun.lua /autorun.lua.baseControl.old") --backup current autorun
    os.execute("echo \"os.execute(\\\"/home/baseControl.lua\\\")\">/autorun.lua") --write startup to new autorun
    os.execute("wget https://raw.githubusercontent.com/Daniel-I-Am/openComputersBaseControl/master/lib/ButtonAPI.lua /lib/ButtonAPI.lua -f") --download dependencies
    os.execute("wget https://raw.githubusercontent.com/Daniel-I-Am/openComputersBaseControl/master/lib/danAPI.lua /lib/danAPI.lua -f")
    -- ****TODO: check if there's no internet then reset the autorun, since it will fail over and over****
    os.execute("reboot") --reboot (after reboot program will be started and first part of this do-end loop will be triggered
  end
end

do --import custom libs
  BA = require("ButtonAPI")
  dan = require("danAPI")
end

_, options = shell.parse(...)
do
  if options.u then --update
    os.execute("wget https://raw.githubusercontent.com/Daniel-I-Am/openComputersBaseControl/master/home/baseControl.lua /home/baseControl.lua;baseControl -f")
    os.execute("/home/baseControl.lua -r")
    os.exit()
  end
  if options.r then --reset
    os.execute("rm -r /usr/config/baseControl")
    getMainConfig()
    getComponents()
    os.execute("edit /usr/config/baseControl/main.conf")
    os.execute("edit /usr/config/baseControl/component.conf")
    os.execute("/home/baseControl.lua")
    os.exit()
  end
end

---------- VARIABLES ----------
config = {}
listOfComponents = {}
reactorAuto = false
stepSize = 1000
defaultFluxIn = 225000
lastLogTime = 0
reactorMaxOutput = 1500000

---------- FUNCTIONS ----------
function getMainConfig()
  local defaultConfig = { --default config to load if non exists
    "--Colors--",
    "buttonColorOn=0x32cd32",
    "buttonColorOff=0xff0000",
    "buttonColorText=0x000000",
    "Border_bg=0x0fa7c7",
    "Default_bg=0x696969",
    "text_col=0x0000ff",
    "text_col_hidden=0x000040",
    "status_col=0x000000",
    "barBack=0x000000",
    "barFill=0xffffff",
    "header=0xf5c71a",
    "--Variables--",
    "headerSize=5",
    "buttonXOff=10",
    "buttonYOff=10",
    "buttonWidth=21",
    "buttonHeight=3",
    "buttonSpacingX=5",
    "buttonSpacingY=3",
    "buttonsColumn=3"
  }
  if not fs.exists("/usr/config/baseControl/") then --check if folder exists
    fs.makeDirectory("/usr/config/baseControl/") --make folder if not
  end
  if not fs.exists("/usr/config/baseControl/main.conf") then --check if config exists
    local file = io.open("/usr/config/baseControl/main.conf", "w") --make if not
    for _, v in pairs(defaultConfig) do --going through all lines off the default config
      file:write(v .. "\n") --writing it to the file
    end
    file:close() --closing the file (saving memory)
  end
  local file = io.open("/usr/config/baseControl/main.conf", "r") --reading the file regardless, there's definitely a file now
  local text = {}
  repeat
    line = file:read("*line") --read a line
      if line ~= nil then --check if it's not nil
          table.insert(text, line) --insert into text array
      end
  until line == nil
  for _, line in pairs(text) do --go through all lines
    if line:find("=") ~= nil then --check if there's an '=' in it (so config option)
      local a = line:sub(1, line:find("=") - 1) --key to a
      local b = line:sub(line:find("=") + 1, -1) --value to b
      b = tonumber(b) or b --make b a number if possible, tonumber() returns a number or nil.
      --or'ing this with b itself will turn it into a number or, if not possible, to the string value
      config[a] = b --set config key-value
    end
  end
end

function getComponents() --same story with comments here as in getMainConfig()
  local defaultConfig = {
    "#please write the following format:",
    "#redstoneID;componentName;redstoneOutputSide;invertedstate",
    "#",
    "#A number sign can be used to comment",
    "#Invalid lines will be commented out upon runtime",
    "#",
    "#redstoneID is a 32 hex char long UUID",
    "#componentName can be anything, not including a ';'",
    "#redstoneOutputSide can be north,south,east,west,top or bottom",
    "#invertedstate can be true or false",
    "#Example:",
    "#aabbccdd-eeff-gghh-iijj-kkllmmnnoopp;Some {} Name;west;false",
    "#",
    "#If adding a reactor, please uncomment the following two lines (replacing the UUID):",
    "#<flux_gate_in_UUID>;flux_gate_in;none;false",
    "#<flux_gate_out_UUID>;flux_gate_out;none;false",
    "#"
  }
  for e in component.list("redstone") do
    table.insert(defaultConfig, e)
  end
  local readFile = {}
  if fs.exists("/usr/config/baseControl/component.conf") then --read config
    local file = io.open("/usr/config/baseControl/component.conf", "r")
    repeat
      line = file:read("*line")
      if line ~= nil then
        table.insert(readFile, line)
      end
    until line == nil
  else
    readFile = defaultConfig
  end
  for k,v in pairs(readFile) do --check config
    if v:sub(1,1) ~= "#" then --not comment
      if v:match("%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x;[^;]*;[a-z]*;[tf][ra][ul][es]+") ~= v then --check if not match
        readFile[k] = "#" .. v --comment out
      end
    end
  end
  local file = io.open("/usr/config/baseControl/component.conf", "w") --write config (with comments)
  for i = 1, #readFile do
    file:write(readFile[i] .. "\n")
  end
  file:close()
  local listOfComponentsTemp = {}
  for k,v in pairs(readFile) do
    if v:match("%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x;[^;]*;[a-z]*;[tf][ra][ul][es]+") == v then
      local a = v:find(";")
      local b = a + v:sub(a+1,-1):find(";")
      local c = b + v:sub(b+1,-1):find(";")
      local t = {v:sub(1,a-1), v:sub(a+1,b-1), v:sub(b+1,c-1), v:sub(c+1,-1)}
      table.insert(listOfComponentsTemp, t)
    end
  end
  for k,v in pairs(listOfComponentsTemp) do
    if component.proxy(v[1]).type == "flux_gate" then
      if v[2] == "flux_gate_in" then fluxGateIn = component.proxy(v[1]) end
      if v[2] == "flux_gate_out" then fluxGateOut = component.proxy(v[1]) end
      listOfComponentsTemp[k]=nil
    end
  end
  for k,v in pairs(listOfComponentsTemp) do
    table.insert(listOfComponents, v)
  end
end

function showPower(xTopLeft, yTopLeft, input) --shows power IF there's a power ball
  if xTopLeft < 0 or yTopLeft < 0 then --if you supply negative xTopLeft or yTopLeft
    if xTopLeft < 0 then               --then take it as a amount from right side
      xTopLeft = xTopLeft + width
    end
    if yTopLeft < 0 then
      yTopLeft = yTopLeft + height
    end
  end
  if not component.isAvailable("draconic_rf_storage") then dan.addRect(xTopLeft,yTopLeft,xTopLeft+30,yTopLeft+3, config["Default_bg"]);return end --stop execution of function if there is no power
  local draco = component.draconic_rf_storage --find the power ball
  local powerStats =  input or {stored = draco.getEnergyStored(), max = draco.getMaxEnergyStored(), gain = draco.getTransferPerTick()} --take stats
  local tempCol = {gpu.getForeground(), gpu.getBackground()} --get backup of colors
  gpu.setForeground(config.text_col) --set colors to config option
  gpu.setBackground(config.Default_bg)
  gpu.set(xTopLeft, yTopLeft, "Energy Storage:")
  gpu.set(xTopLeft+2, yTopLeft+1, dan.suffixNumber(powerStats.stored) .. "RF/" .. dan.suffixNumber(powerStats.max) .. "RF (" .. tostring(math.floor((10000 * powerStats.stored + 0.5)/powerStats.max)/100 .. "%)    ")) --print details
  if powerStats.gain >= 0 then --if gain is positive
    gpu.set(xTopLeft, yTopLeft+2, "Power Gain:") --print gain
    gpu.setForeground(config.buttonColorOn) --set text color
    gpu.set(xTopLeft+2, yTopLeft+3, dan.suffixNumber(powerStats.gain) .. "RF/t    ") --print
  else
    gpu.set(xTopLeft, yTopLeft+2, "Power Loss") --print loss
    gpu.setForeground(config.buttonColorOff) --set text color
    gpu.set(xTopLeft+2, yTopLeft+3, dan.suffixNumber(-powerStats.gain) .. "RF/t    ") --print
  end
  gpu.setForeground(tempCol[1])
  gpu.setBackground(tempCol[2])
end

function toggleComponent(id)
  local rsIO = component.proxy(listOfComponents[id][1]) --get IO
  rsIO.setOutput(sides[listOfComponents[id][3]], 15 - rsIO.getOutput(sides[listOfComponents[id][3]])) --set output to 15-output
end

function makeButtons()
  BA.clear() --clear buttonTable
  for i, v in pairs(listOfComponents) do --go through provided components (in getComponents())
    local state = component.proxy(v[1]).getOutput(sides[v[3]]) --take the current state from IO
    if state == 15 then state = true else state = false end --turn into boolean
    if v[4] == "true" then state = not state end --invert if isInvert is set
    BA.makeButton(config["buttonXOff"] + math.floor((i-1)/3) * (config["buttonWidth"] + config["buttonSpacingX"]), config["buttonYOff"] + ((i-1)%3) * (config["buttonHeight"] + config["buttonSpacingY"]), config["buttonWidth"], config["buttonHeight"], v[2], config["buttonColorOn"], config["buttonColorOff"], config["buttonColorText"], -1, -1, true, state) --make button
  end
end

function updateCompStats(e) --e is possible touch event (can be nil)
  dan.addRect(width-4, height-7, width-2, height-2, 0x000000) --add battery body
  dan.addRect(width-3, height-8, width-3, height-8, 0x000000) --add battery tip
  dan.addProgressBar(-3,-6,-3,-3,0,0,0x000000,config.buttonColorOn,config.buttonColorOff,0x000000,"",computer.energy()/computer.maxEnergy(),false,false) --add power progress bar IN battery
  dan.addRect(width-13, height-8, width-6, height-2, 0x000000) --add main body storage display
  dan.addRect(width-12, height-7, width-12, height-7, config.Default_bg) --take out 3 dots at the top of storage display
  dan.addRect(width-10, height-7, width-10, height-7, config.Default_bg)
  dan.addRect(width-8,  height-7, width-8,  height-7, config.Default_bg)
  dan.addRect(width-6, height-8, width-6, height-8, config.Default_bg) --take out the snippets on the side of storage display
  dan.addRect(width-6, height-6, width-6, height-6, config.Default_bg)
  local storage = {used = 0, total = 0}
  for e in component.list("filesystem") do
    if e ~= nil then
      storage["used"] = storage["used"] + component.proxy(e).spaceUsed()
      storage["total"] = storage["total"] + component.proxy(e).spaceTotal()
    end
  end
  dan.addProgressBar(-12,-3,-7,-3,0,0,0x000000,config.buttonColorOn,config.buttonColorOff,0x000000,"",storage["used"]/storage["total"],true,false) --add storage progress bar IN storage display
  dan.addRect(width-18, height-8, width-15, height-2, 0x000000)
  dan.addRect(width-15, height-3, width-15, height-3, config.Default_bg)
  dan.addRect(width-15, height-5, width-15, height-5, config.Default_bg)
  dan.addRect(width-15, height-7, width-15, height-7, config.Default_bg)
  local memP =  computer.freeMemory()/computer.totalMemory()
  memP = math.floor(memP * 3 + 0.5)
  if memP >= 1 then dan.addRect(width-17, height-3, width-17, height-3, config.buttonColorOn) else dan.addRect(width-17, height-3, width-17, height-3, config.buttonColorOff) end
  if memP >= 2 then dan.addRect(width-17, height-5, width-17, height-5, config.buttonColorOn) else dan.addRect(width-17, height-5, width-17, height-5, config.buttonColorOff) end
  if memP >= 3 then dan.addRect(width-17, height-7, width-17, height-7, config.buttonColorOn) else dan.addRect(width-17, height-7, width-17, height-7, config.buttonColorOff) end
  local uptime = math.floor(computer.uptime())
  if uptime < 60 then uptime = uptime .. "s" elseif uptime < 3600 then uptime = math.floor(uptime/60) .. "m" elseif uptime < 86400 * 2 then uptime = math.floor(uptime/3600) .. "h" else uptime = math.floor(uptime/86400) .. "d" end
  dan.centerText(" uptime: " .. uptime .. " ", -13, -2, -9, config.text_col, config.Default_bg)
  local eventType, _, x, y, _, _ = table.unpack(e) --unpack event
  if eventType == "touch" then
    if x >= width - 32 and x <= width - 21 then
      if y == height - 4 then post();os.exit() end
      if y == height - 3 then post();computer.shutdown(false) end
      if y == height - 2 then post();computer.shutdown(true) end
    end
  end
  dan.centerText("[[  exit  ]]", -32, -21, -4, config.text_col, config.Default_bg)
  dan.centerText("[[shutdown]]", -32, -21, -3, config.text_col, config.Default_bg)
  dan.centerText("[[ reboot ]]", -32, -21, -2, config.text_col, config.Default_bg)
end

function init()
  screen.setTouchModeInverted(true)
  getMainConfig() --reads (and makes if need be) the main config file for this program
  getComponents() --get all configured components
  makeButtons() --make all buttons for supplied components
  os.sleep(1) --sleep (delay needed when ran from /autorun.lua)
  local maxWidth, maxHeight = gpu.maxResolution()
  width = 2 * config.buttonXOff + math.ceil(#listOfComponents / config.buttonsColumn) * (config.buttonWidth + config.buttonSpacingX) + 40 --check how wide the screen needs to be
  if width ~= tonumber(width) then width = 2 * config.buttonXOff + 40 end
  width = math.max(width, 60)
  width = math.min(width, maxWidth)
  height = config.buttonYOff + config.headerSize + config.buttonsColumn * (config.buttonSpacingY + config.buttonHeight) --check how high the screen needs to be
  height = math.max(height,33)
  height = math.min(height,maxHeight)
  dan.plazGUI(width, height, config.headerSize, config.text_col, config.Default_bg, config.Border_bg, "-- Base Control --") --draw GUI
  BA.drawAll() --draw all buttons
  if not fs.exists("/usr/logs/baseControl/") then
    fs.makeDirectory("/usr/logs/baseControl/")
  end
  if not fs.exists("/usr/logs/baseControl/reactor.log") then
    os.execute("echo \"Reactor Logging:\">/usr/logs/baseControl/reactor.log")
  end
end

function reactor(e)
  tempCol = {fore=gpu.getForeground(), back=gpu.getBackground()}
  dan.addRect(width-45,15,width-10,20,config["Default_bg"])
  if not (component.isAvailable("draconic_reactor") and component.isAvailable("flux_gate")) then return end
  if fluxGateIn == nil or fluxGateOut == nil then return end
  local reactor = component.draconic_reactor
  local reactorStats = reactor.getReactorInfo()
  dan.centerText("Reactor Control", -45, -30, 15, config["text_col"], config["Default_bg"])
  dan.centerText("Reactor Status:", -45, -30, 16, config["text_col"], config["Default_bg"])
  dan.centerText(reactorStats.status .. string.rep(" ",10 - reactorStats.status:len()), -30, -20, 16, config["text_col"], config["Default_bg"])
  
  local textCol = config["text_col_hidden"]
  if (reactorStats.status == "cold" or reactorStats.status == "cooling") and reactorStats.energySaturation/(reactorStats.maxEnergySaturation+1) < 0.60 then textCol = config["text_col"] end
  dan.centerText("[[  Charge  ]]", -45, -32, 17, textCol, config["Default_bg"])
  local textCol = config["text_col_hidden"]
  if (reactorStats.status == "warming_up" and reactorStats.temperature > 2000) or reactorStats.status == "stopping" then textCol = config["text_col"] end
  dan.centerText("[[ Activate ]]", -45, -32, 18, textCol, config["Default_bg"])
  local textCol = config["text_col_hidden"]
  if reactorStats.status == "running" or reactorStats.status == "warming_up" then textCol = config["text_col"] end
  dan.centerText("[[ Shutdown ]]", -45, -32, 19, textCol, config["Default_bg"])
  local textCol = config["buttonColorOff"]
  if reactorAuto then textCol = config["buttonColorOn"] end
  if reactorStats.status == "cold" or reactorStats.status == "cooling" then textCol = config["text_col_hidden"] end
  dan.centerText("[[   Auto   ]]", -45, -32, 20, textCol, config["Default_bg"])
  gpu.setForeground(config["text_col"])
  gpu.setBackground(config["Default_bg"])
  dan.addRect(width-45,21,width-1,22,config["Default_bg"])
  gpu.set(width-45,21,"IN flow/field: " .. dan.comma_value(tostring(math.floor(fluxGateIn.getSignalLowFlow()))) .. "/" .. dan.comma_value(tostring(math.floor(reactorStats.fieldDrainRate))) .. " RF/t")
  --TODO:fix field drain rate
  gpu.set(width-45,22,"OUT flow/generated: " .. dan.comma_value(tostring(math.floor(fluxGateOut.getSignalLowFlow()))) .. "/" .. dan.comma_value(tostring(math.floor(reactorStats.generationRate))) .. " RF/t")
  
  local battery = {stored=reactorStats.energySaturation, max=reactorStats.maxEnergySaturation, perc=reactorStats.energySaturation/reactorStats.maxEnergySaturation}
  local temperature = {stored=reactorStats.temperature, max=8000, perc=reactorStats.temperature/8000}
  local containmentField = {stored=reactorStats.fieldStrength, max=reactorStats.maxFieldStrength, perc=reactorStats.fieldStrength/reactorStats.maxFieldStrength}
  local fuel = {stored=reactorStats.fuelConversion, max=reactorStats.maxFuelConversion, perc=reactorStats.fuelConversion/reactorStats.maxFuelConversion}
  if reactorStats.maxEnergySaturation == 0 then battery.perc = 0 end
  if reactorStats.maxFieldStrength == 0 then containmentField.perc = 0 end

  if lastLogTime + 5 > computer.uptime() then
    lastLogTime = computer.uptime()
    timeStamp = {}
    dan.fileWrite("/usr/logs/baseControl/reactor.log", timeStamp .. " {battery="..battery.perc..", temperature="..temperature.perc..", containment="..containmentField.perc..", fuel="..fuel.perc.."}", false)
  end

  dan.centerText("Saturation: ", -30, -19, 17, config["text_col"], config["Default_bg"])
  dan.centerText(math.floor(battery.perc*100 + 0.5) .. "%", -18, -18+string.len(math.floor(battery.perc*100 + 0.5) .. "%"), 17, config["text_col"], config["Default_bg"])
  dan.centerText("Temperature:", -30, -19, 18, config["text_col"], config["Default_bg"])
  dan.centerText(math.floor(temperature.perc*100 + 0.5) .. "%", -18, -18+string.len(math.floor(temperature.perc*100 + 0.5) .. "%"), 18, config["text_col"], config["Default_bg"])
  dan.centerText("Containment:", -30, -19, 19, config["text_col"], config["Default_bg"])
  dan.centerText(math.floor(containmentField.perc*100 + 0.5) .. "%", -18, -18+string.len(math.floor(containmentField.perc*100 + 0.5) .. "%"), 19, config["text_col"], config["Default_bg"])
  dan.centerText("Conversion: ", -30, -19, 20, config["text_col"], config["Default_bg"])
  dan.centerText(math.floor(fuel.perc*100 + 0.5) .. "%", -18, -18+string.len(math.floor(fuel.perc*100 + 0.5) .. "%"), 20, config["text_col"], config["Default_bg"])
  
  local eventType, _, x, y, _, _ = table.unpack(e) --unpack event
  if eventType == "touch" then
    if x >= width - 45 and x <= width - 32 then
      if y == 17 and (reactorStats.status == "cold" or reactorStats.status == "cooling") and reactorStats.energySaturation/(reactorStats.maxEnergySaturation+1) < 0.60 then reactor.chargeReactor();reactor.setFailSafe(true) end
      if y == 18 and ((reactorStats.status == "warming_up" and reactorStats.temperature > 2000) or reactorStats.status == "stopping") then reactor.activateReactor() end
      if y == 19 and reactorStats.status ~= "cold" then reactor.stopReactor() end
      if y == 20 then reactorAuto = not reactorAuto end
    end
  end
  if reactorAuto then
    --do everything for auto-reactor
    if reactorStats.status == "warming_up" then
      if battery.perc > 0.55 then reactor.stopReactor() end
      --warming up, so this is between charge and activate
      local flowIn = math.floor((reactorStats.fieldDrainRate / 250000) + 1) * 2500000
      fluxGateIn.setSignalLowFlow(flowIn)
      fluxGateIn.setSignalHighFlow(flowIn)
      fluxGateOut.setSignalLowFlow(0)
      fluxGateOut.setSignalHighFlow(0)
      if reactorStats.temperature >= 1990 then
        --temperature is fine to start reactor
        reactor.activateReactor()
        local flowOut = math.floor((reactorStats.generationRate / 2500) + 1) * 2500
        fluxGateIn.setSignalLowFlow(defaultFluxIn)
        fluxGateIn.setSignalHighFlow(defaultFluxIn)
        fluxGateOut.setSignalLowFlow(flowOut)
        fluxGateOut.setSignalHighFlow(flowOut)
      end
    elseif reactorStats.status == "running" then
      --this is where the magic will have to happen...
      if battery.perc < 0.25 then
        fluxGateOut.setSignalLowFlow(math.min(reactorStats.generationRate-5*stepSize,reactorMaxOutput))
        fluxGateOut.setSignalHighFlow(math.min(reactorStats.generationRate-5*stepSize,reactorMaxOutput))
      elseif battery.perc > 0.25 then
        fluxGateOut.setSignalLowFlow(math.min(reactorStats.generationRate+5*stepSize,reactorMaxOutput))
        fluxGateOut.setSignalHighFlow(math.min(reactorStats.generationRate+5*stepSize,reactorMaxOutput))
      end
      if temperature.stored < 4000 then
        fluxGateIn.setSignalLowFlow(reactorStats.fieldDrainRate-stepSize/2)
        fluxGateIn.setSignalHighFlow(reactorStats.fieldDrainRate-stepSize/2)
      elseif temperature.stored > 4000 then
        fluxGateIn.setSignalLowFlow(reactorStats.fieldDrainRate+stepSize/2)
        fluxGateIn.setSignalHighFlow(reactorStats.fieldDrainRate+stepSize/2)
      end
      local a = -0.15
      local b = 100000
      local c = defaultFluxIn
      local d = 50
      local e = (1 + 1/(2^20))^(2^20)
      fluxGateIn.setSignalLowFlow(b*math.abs(1/(1+e^(-a*(containmentField.perc*100-d))))+c)
      fluxGateIn.setSignalHighFlow(b*math.abs(1/(1+e^(-a*(containmentField.perc*100-d))))+c)
      --[[
      if containmentField.perc < 0.25 then
        fluxGateIn.setSignalLowFlow(defaultFluxIn+(1-containmentField.perc)*100000)
        fluxGateIn.setSignalHighFlow(defaultFluxIn+(1-containmentField.perc)*100000)
      elseif containmentField.perc > 0.75 then
        fluxGateIn.setSignalLowFlow(defaultFluxIn-containmentField.perc*100000)
        fluxGateIn.setSignalHighFlow(defaultFluxIn-containmentField.perc*100000)
      else
        fluxGateIn.setSignalLowFlow(defaultFluxIn)
        fluxGateIn.setSignalHighFlow(defaultFluxIn)
      end
      --]]
      do --safety
        if fuel.perc > 0.95 or temperature.stored > 7000 or containmentField.perc < 0.25 or battery.perc < 0.1 then
          reactor.stopReactor()
        end
      end
    elseif reactorStats.status == "stopping" then
      --Bring it to a graceful stop
      local flowIn = math.floor((reactorStats.fieldDrainRate / 10000) + 1) * 10000
      local flowOut = math.floor((reactorStats.generationRate / 10000) + 1) * 10000
      fluxGateIn.setSignalLowFlow(flowIn)
      fluxGateIn.setSignalHighFlow(flowIn)
      fluxGateOut.setSignalLowFlow(flowOut)
      fluxGateOut.setSignalHighFlow(flowOut)
    elseif reactorStats.status == "cooling" then
      --just let it sit
      fluxGateIn.setSignalLowFlow(0)
      fluxGateIn.setSignalHighFlow(0)
      fluxGateOut.setSignalLowFlow(0)
      fluxGateOut.setSignalHighFlow(0)
      reactorAuto = false
    elseif reactorStats.status == "cold" then
      --just let it sit
      fluxGateIn.setSignalLowFlow(0)
      fluxGateIn.setSignalHighFlow(0)
      fluxGateOut.setSignalLowFlow(0)
      fluxGateOut.setSignalHighFlow(0)
      reactorAuto = false
    end
  end
  gpu.setForeground(tempCol.fore)
  gpu.setBackground(tempCol.back)
end

function post()
  screen.setTouchModeInverted(false)
  term.clear()
end

---------- MAIN BLOCK ----------
init() --set all initial values
repeat --start main loop
  showPower(-45,10) --display the power
  local e = table.pack(event.pull(0.1,"touch")) --wait until touch event or timeout
  reactor(e)
  updateCompStats(e) --show computer statistics
  if e.n ~= 0 then --if there was a touch event
    local buttonHit = BA.updateAll(table.unpack(e)) --utilise button API functions to process touch event
    if buttonHit ~= nil then --if a button was hit
      toggleComponent(buttonHit.id) --toggle that component
    end
    BA.drawAll() --draw all buttons
  end
until keyboard.isControlDown() --stop if ctrl is held down
post()
--[[EOF]]--
