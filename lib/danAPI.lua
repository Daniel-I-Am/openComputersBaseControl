methods = {}

local component = require("component")
local term = require("term")
local os = require("os")
local fs = require("filesystem")

local gpu = component.gpu

methods.info = {
	"throwError(errorMessage) --stops the program with an error message",
	"addRect(x1, y1, x2, y2, color) --sets a block of pixels to a certain color",
	"addProgressBar(x1,y1,x2,y2,sideWidth,sideHeight,borderColor,filledBarColor,emptyBarColor,textColor,headerText,filledPercentage,isSideways,isInverted) --adds a progressbar to your screen, needs to be called every value update",
	"centerText(str, x1, x2, y, FGCol, BGCol) --centers text based on certain outer points",
	"fileWrite(fileLocation, str, isOverwrite) --adds some text to a file, use isOverwrite false to append",
	"fileRead(fileLocation) --reads the text of a file, returns a table of lines",
	"comma_value(n) --converts a number into a string with commas",
	"listToPages(list,entriesPerPage) --turns a list into multiple lists of length entriesPerPage, returns list of lists",
	"sortList(array, mode) --sorts a list based on value",
	"sortArray(array, mode) --sorts an array, respecting original index",
	"info --gives this list of instructions"
}

function methods.textInRect(x1, y1, x2, y2, text, boxColor, textColor)
	if not component.isAvailable("gpu") then return end
	boxColor = boxColor or 0x303030
	textColor = textColor or 0xffffff
	local temp = {gpu.getForeground(), gpu.getBackground()}
	if x1 == nil or y1 == nil or x2 == nil or y2 == nil then return end
	methods.addRect(x1, y1, x2, y2, boxColor)
	if text == nil then return end
	text = tostring(text)
	methods.centerText(text, x1, x2, math.floor((y2 + y1)/2)+1, textColor, boxColor)
	gpu.setForeground(temp[1])
	gpu.setBackground(temp[2])
end

function methods.plazGUI(xSize, ySize, headerHeight, textColor, backgroundColor, borderColor, titleText)
	gpu.setResolution(xSize, ySize)
	gpu.setBackground(backgroundColor)
	term.clear()
	methods.addRect(1, 1, 1, ySize, borderColor)
	methods.addRect(1, 1, xSize, 1, borderColor)
	methods.addRect(xSize, 1, xSize, ySize, borderColor)
	methods.addRect(1, ySize, xSize, ySize, borderColor)
	methods.addRect(1, headerHeight + 2, xSize, headerHeight + 2, borderColor)
	methods.textInRect(2, 2, xSize - 1, headerHeight - 1, titleText, backgroundColor, textColor)
end

function methods.throwError(errorMessage)
  if component.isAvailable("gpu") then
    gpu.setResolution(gpu.maxResolution())
    gpu.setForeground(0xff0000)
    gpu.setBackground(0x000000)
  end
  term.clear()
  print("The program ran into a serious error during execution.")
  print(errorMessage)
  if component.isAvailable("gpu") then
    gpu.setForeground(0xffffff)
  end
  os.exit()
end

function methods.addToLog(toLog)
	methods.fileWrite("debug.log", toLog, false)
end

function methods.addRect(x1,y1,x2,y2,color)
  if not component.isAvailable("gpu") then return end
  color = color or 0x303030
  prevCol = gpu.getBackground()
  gpu.setBackground(color)
  gpu.fill(x1,y1,x2-x1+1,y2-y1+1," ")
  gpu.setBackground(prevCol)
end

function methods.addProgressBar(x1,y1,x2,y2,sideWidth,sideHeight,borderColor,filledBarColor,emptyBarColor,textColor,headerText,filledPercentage,isSideways,isInverted)
  if not component.isAvailable("gpu") then return end
  local width, height = gpu.getResolution()
  isSideways = isSideways or false
  isInverted = isInverted or false
  if type(x1)~="number" then methods.throwError("addProgressBar() argument 1 (x1) type int expected, "..type(x1).." found") end
  if type(x2)~="number" then methods.throwError("addProgressBar() argument 3 (x2) type int expected, "..type(x2).." found") end
  if type(y1)~="number" then methods.throwError("addProgressBar() argument 2 (y1) type int expected, "..type(y1).." found") end
  if type(y2)~="number" then methods.throwError("addProgressBar() argument 4 (y2) type int expected, "..type(y2).." found") end
  if type(sideWidth)~="number" then methods.throwError("addProgressBar() argument 5 (sideWidth) type int expected, "..type(sideWidth).." found") end
  if type(sideHeight)~="number" then methods.throwError("addProgressBar() argument 6 (sideHeight) type int expected, "..type(sideHeight).." found") end
  if type(filledPercentage)~="number" then methods.throwError("addProgressBar() argument 11 (filledPercentage) type float expected, "..type(filledPercentage).." found") end
  if filledPercentage > 1 then filledPercentage = 1 end
  if x1 < 0 then x1 = x1 + width end
  if x2 < 0 then x2 = x2 + width end
  if y1 < 0 then y1 = y1 + height end
  if y2 < 0 then y2 = y2 + height end
  if isSideways == false then
    methods.addRect(x1,y1,x2,y2,borderColor)
    methods.addRect(x1+sideWidth,y1+sideHeight,x2-sideWidth,y2-sideHeight,emptyBarColor)
    barSize = (y2-y1-2*sideHeight)
    pixelsFilled = math.floor(filledPercentage*barSize+0.5)
    if isInverted == false then
      methods.addRect(x1+sideWidth,y2-sideHeight-pixelsFilled,x2-sideWidth,y2-sideHeight,filledBarColor)
    elseif isInverted == true then
      methods.addRect(x1+sideWidth,y1+sideHeight,x2-sideWidth,y1+sideHeight+pixelsFilled,filledBarColor)
    else
      methods.throwError("addProgressBar() argument 13 (isInverted) type boolean expected, "..type(isInverted).." found")
    end
  elseif isSideways == true then
    methods.addRect(x1,y1,x2,y2,borderColor)
    methods.addRect(x1+sideWidth,y1+sideHeight,x2-sideWidth,y2-sideHeight,emptyBarColor)
    barSize = (x2-x1-2*sideWidth)
    pixelsFilled = math.floor(filledPercentage*barSize+0.5)
    if isInverted == false then
      methods.addRect(x1+sideWidth,y1+sideHeight,x1+sideWidth+pixelsFilled,y2-sideHeight,filledBarColor)
    elseif isInverted == true then
      methods.addRect(x2-sideWidth-pixelsFilled,y1+sideHeight,x2-sideWidth,y2-sideHeight,filledBarColor)
    else
      methods.throwError("addProgressBar() argument 13 (isInverted) type boolean expected, "..type(isInverted).." found")
    end
  else
    methods.throwError("addProgressBar() argument 12 (isSideways) type boolean expected, "..type(isSideways).." found")
  end
  if sideHeight>0 then
	col = {f = gpu.getForeground(),b = gpu.getBackground()}
    centerX = math.ceil((x1+x2)/2)
    centerY = math.floor(y1+sideHeight/2)
    gpu.setForeground(textColor)
    gpu.setBackground(borderColor)
    gpu.set(centerX-(string.len(tostring(headerText))/2),centerY,tostring(headerText))
    gpu.setForeground(col.f)
    gpu.setBackground(col.b)
    centerX = nil
    centerY = nil
    col = nil
  end
end

function methods.centerText(str, x1, x2, y, FGCol, BGCol)
    if not component.isAvailable("gpu") then return end
    local w,h = gpu.getResolution()
    x1 = x1 or 1
	if x1<0 then x1 = x1 + w end
    x2 = x2 or w
	if x2<0 then x2 = x2 + w end
    y = y or 1
	if y<0 then y = y + h end
    str = str or "text"
    FGCol = FGCol or 0xffffff
    BGCol = BGCol or 0x000000
    local prevFG = gpu.getForeground()
    local prevBG = gpu.getBackground()
    local l = string.len(tostring(str))
    local center = math.floor((x1+x2)/2)
    local startPos = math.ceil(center - (l-1)/2)
    gpu.setForeground(FGCol)
    gpu.setBackground(BGCol)
    gpu.set(startPos,y,str)
    gpu.setForeground(prevFG)
    gpu.setBackground(prevBG)
end

function methods.fileRead(fileLocation)
	local text = {}
	if fs.exists(tostring(fileLocation)) then
		f = io.open(tostring(fileLocation), "r")
		repeat
			line = f:read("*line")
			if line ~= nil then
				table.insert(text, line)
			end
		until line == nil
	else
		methods.throwError("File ".. fileLocation .." not found!")
	end
	f:close()
	f = nil
	return text
end

function methods.fileWrite(fileLocation, str, isOverwrite)
  if isOverwrite==true then mode = "w" else mode = "a" end
  f = io.open(tostring(fileLocation),mode)
  f:write(tostring(str).."\n")
  f:close()
end

function methods.listToPages(list,entriesPerPage)
    pageList = {}
    value = nil
    tempList = {}
    for i = 1,#list,entriesPerPage do
        tempList = {}
        for j = 1,entriesPerPage do
            value = table.remove(list, 1)
            table.insert(tempList, value)
        end
        table.insert(pageList, tempList)
    end
    return pageList
end


function methods.comma_value(n) -- credit http://richard.warburton.it
  local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
  return left..(num:reverse():gsub('(%d%d%d)','%1.'):reverse())..right
end

function methods.suffixNumber(n)
  local suffixes = {"", "k", "M", "G", "T", "P", "E"} --list of number suffixes (https://en.wikipedia.org/wiki/Metric_prefix)
  if type(n) ~= "number" then return end --stop if invalid input
  local j = 0 
  for i = 1, #suffixes do --go through the list of possible suffixes
    if n/(1000^i) >= 0.001 then j = i - 1 end --devide by the amount to check and compare to 1000^-1
  end
  return tostring(math.floor(n/(1000^(j-1)) + 0.5)/1000) .. " " .. suffixes[j+1] --return rounded number with suffix (+1 because there's "" in the suffix list)
end

function methods.randomDigitNoRep(lowerBound, upperBound, numberOfNumbers)
  lowerBound = lowerBound or 1
  upperBound = upperBound or 10
  numberOfNumbers = numberOfNumbers or 1
  if upperBound - lowerBound + 1 < numberOfNumbers then print("wrong size"); return nil end
  local hasBeenPicked = false
  local list = {}
  for i = 1, numberOfNumbers do
    repeat
      hasBeenPicked = false
      n = math.random(lowerBound, upperBound)
      for j = 1, #list do
        if n == list[j] then
          hasBeenPicked = true
        end
      end
    until hasBeenPicked == false
    table.insert(list, n)
  end
  return list
end

function methods.sortList(array, mode)
  local arrayCopy = {}
  for k,v in pairs(array) do
    arrayCopy[k] = v
  end
  
  mode = mode or "a"
  if mode == "d" then
    for i = 1, #arrayCopy do
      for j = 1, #arrayCopy - i do
        local a = arrayCopy[j]
        local b = arrayCopy[j+1]
        if a < b then
          arrayCopy[j] = b
          arrayCopy[j+1] = a
        end
      end
    end
    return arrayCopy
  else
    for i = 1, #arrayCopy do
      for j = 1, #arrayCopy - i do
        local a = arrayCopy[j]
        local b = arrayCopy[j+1]
        if a > b then
          arrayCopy[j] = b
          arrayCopy[j+1] = a
        end
      end
    end
    return arrayCopy
  end
  return nil
end

function methods.sortArray(array, mode)
  local i = 0
  local pointers = {}
  local data = {}
  local arrayCopy = {}
  for k,v in pairs(array) do
    arrayCopy[k] = v
  end
  for k,v in pairs(arrayCopy) do
    pointers[i] = k
    data[i] = v
    i = i + 1
  end
  mode = mode or "a"
  if mode == "d" then
    for i = 0, #data do
      for j = 0, #data - i - 1 do
        local a = data[j]
        local b = data[j+1]
        local c = pointers[j]
        local d = pointers[j+1]
        if a < b then
          data[j] = b
          pointers[j] = d
          data[j+1] = a
          pointers[j+1] = c
        end
      end
    end
    return pointers, data
  else
    for i = 0, #data do
      for j = 0, #data - i - 1 do
        local a = data[j]
        local b = data[j+1]
        local c = pointers[j]
        local d = pointers[j+1]
        if a > b then
          data[j] = b
          pointers[j] = d
          data[j+1] = a
          pointers[j+1] = c
        end
      end
    end
    return pointers, data
  end
  return nil
end

return methods
