local methods = {}
local buttons = {}

local component = require("component")
if component.isAvailable("gpu") then local gpu = component.gpu end
local term = require("term")
local event = require("event")
local screen = component.screen

if not component.isAvailable("gpu") then return methods end
gpu = component.gpu

local function checkArg(value, expectedType)
  if type(value) == expectedType then return true else return false end
end

function methods.clear()
  buttons = {}
  return true
end

function methods.draw(buttonID)
  if checkArg(buttonID, "number") then
    temp = {gpu.getForeground(), gpu.getBackground()}
    do -- This is where buttons are being drawn
      if buttons[buttonID].state then gpu.setBackground(buttons[buttonID].buttonOnColor) else gpu.setBackground(buttons[buttonID].buttonOffColor) end
      gpu.fill(buttons[buttonID].buttonXOffset, buttons[buttonID].buttonYOffset, buttons[buttonID].buttonXSize, buttons[buttonID].buttonYSize, " ")
      gpu.setForeground(buttons[buttonID].buttonTextColor)
      if buttons[buttonID].buttonTextXOffset < 0 then
        --center the text
        local l = buttons[buttonID].buttonText:len()
        local centerY = buttons[buttonID].buttonYOffset + math.floor(buttons[buttonID].buttonYSize/2)
        gpu.set(buttons[buttonID].buttonXOffset, centerY, buttons[buttonID].buttonText)
      else
        --just print
        if buttons[buttonID].buttonTextXOffset < buttons[buttonID].buttonXSize and buttons[buttonID].buttonTextYOffset < buttons[buttonID].buttonYSize then
          local leftOverSpace = buttons[buttonID].buttonXSize - buttons[buttonID].buttonTextXOffset
          gpu.set(buttons[buttonID].buttonXOffset + buttons[buttonID].buttonTextXOffset, buttons[buttonID].buttonYOffset + buttons[buttonID].buttonTextYOffset, buttons[buttonID].buttonText:sub(1, leftOverSpace))
        end
      end
    end
    gpu.setForeground(temp[1])
    gpu.setBackground(temp[2])
  elseif checkArg(buttonID, "table") then
    for i = 1, #buttonID do
      methods.draw(buttonID[i])
    end
  end
  return false
end

function methods.drawAll()
  for k, _ in ipairs(buttons) do
    methods.draw(k)
  end
end

function methods.makeButton(buttonXOffset, buttonYOffset, buttonXSize, buttonYSize, buttonText, buttonOnColor, buttonOffColor, buttonTextColor, buttonTextXOffset, buttonTextYOffset, isToggle, state)
  if state == nil then state = true end
  if isToggle == nil then isToggle = false end
  local buttonTextXOffset = buttonTextXOffset or -1
  local buttonTextYOffset = buttonTextYOffset or -1
  local buttonOnColor = buttonOnColor or 0x00ff00
  local buttonOffColor = buttonOffColor or 0xff0000
  local buttonTextColor = buttonTextColor or 0xffffff
  local buttonText = buttonText or ""
  
  if buttonText:len() > buttonXSize then
    --text is too big -> shrink
    local offset = (buttonText:len() - buttonXSize)/2
    buttonText = buttonText:sub(1+math.floor(offset),-(1+math.ceil(offset)))
  else
    local toAdd = (buttonXSize - buttonText:len())/2
    buttonText = string.rep(" ", math.floor(toAdd)) .. buttonText .. string.rep(" ", math.ceil(toAdd))
  end
  
  if not checkArg(buttonXOffset, "number") or not checkArg(buttonYOffset, "number") or not checkArg(buttonXSize, "number") or not checkArg(buttonYSize, "number") or not checkArg(tostring(buttonText), "string") or not checkArg(state, "boolean") or not checkArg(isToggle, "boolean") then return nil end
  buttons[#buttons + 1] = {
    buttonXOffset = buttonXOffset,
    buttonYOffset = buttonYOffset,
    buttonXSize = buttonXSize,
    buttonYSize = buttonYSize,
    buttonText = buttonText,
    buttonOnColor = buttonOnColor,
    buttonOffColor = buttonOffColor,
    buttonTextColor = buttonTextColor,
    buttonTextXOffset = buttonTextXOffset,
    buttonTextYOffset = buttonTextYOffset,
    isToggle = isToggle,
    state = state
  }
  return #buttons
end

function methods.updateAll(e, _, x, y, _, _)
  if e ~= "touch" then return nil end
  local buttonsHit = {}
  for buttonID, _ in ipairs(buttons) do
    if x >= buttons[buttonID].buttonXOffset and x<= buttons[buttonID].buttonXOffset + buttons[buttonID].buttonXSize and y >= buttons[buttonID].buttonYOffset and y <= buttons[buttonID].buttonYOffset + buttons[buttonID].buttonYSize then
      if buttons[buttonID].isToggle then buttons[buttonID].state = not buttons[buttonID].state end
      table.insert(buttonsHit, {id=buttonID, state=buttons[buttonID].state})
    end
  end
  if #buttonsHit == 0 then return nil end
  return table.unpack(buttonsHit)
end

function methods.update(buttonID, e, _, x, y, _, _)
  if e ~= "touch" then return nil end
  if checkArg(buttonID, "table") then
    local buttonsHit = {}
    for _, i in pairs(buttonID) do
      if x >= buttons[i].buttonXOffset and x<= buttons[i].buttonXOffset + buttons[i].buttonXSize and y >= buttons[i].buttonYOffset and y <= buttons[i].buttonYOffset + buttons[i].buttonYSize then
        if buttons[i].isToggle then buttons[i].state = not buttons[i].state end
        table.insert(buttonsHit, {id=i, state=buttons[i].state})
      end
    end
    if #buttonsHit == 0 then return nil end
    return table.unpack(buttonsHit)
  end
  if checkArg(buttonID, "number") then
    if x >= buttons[buttonID].buttonXOffset and x<= buttons[buttonID].buttonXOffset + buttons[buttonID].buttonXSize and y >= buttons[buttonID].buttonYOffset and y <= buttons[buttonID].buttonYOffset + buttons[buttonID].buttonYSize then
      if buttons[buttonID].isToggle then buttons[buttonID].state = not buttons[buttonID].state end
      return {id=buttonID, state=buttons[buttonID].state}
    else
      return nil
    end
  end
  return nil
end

function methods.list(value)
  local toReturn = {}
  if value == nil then
    for i = 1, #buttons do
      table.insert(toReturn, buttons[i])
    end
  else
    for i = 1, #buttons do
      table.insert(toReturn, {id = buttons[i][tostring(value)]})
    end
  end
  return table.unpack(toReturn)
end

return methods
