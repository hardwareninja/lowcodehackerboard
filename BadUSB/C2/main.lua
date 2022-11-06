LIB_CH9329Config("UART0",1920,1080)
LIB_ButtonConfig("BTN1","D10","L")
LIB_ButtonConfig("BTN2","D11","L")

PAYLOAD = "Payload"

done = true
capslock = 0

--[[ Reserved for use with dynamic binary conversion to payload, implementation code commented out to reduce program size in order to squeeze in the main memory size limit.

function hex(t)
  local s = ""
  for _, v in ipairs(t) do
    s = s.."\\x"..(string.format("%02x", v))
  end
  s=s:gsub("\\x(%x%x)",function (x) return string.char(tonumber(x,16)) end)
  return s
end
--]]

--[[ Reserved for use with dynamic binary conversion to payload, implementation code commented out to reduce program size in order to squeeze in the main memory size limit.

function base64(data)
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  return ((data:gsub('.', function(x)
      local r,b='',x:byte()
      for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
      return r;
  end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
      if (#x < 6) then return '' end
      local c=0
      for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
      return b:sub(c+1,c+1)
  end)..({ '', '==', '=' })[#data%3+1])
end
--]]

function utf8(t)
  local bytearr = {}
  for _, v in ipairs(t) do
    local utf8byte = v < 0 and (0xff + v + 1) or v
    table.insert(bytearr, string.char(utf8byte))
  end
  return bytearr
end

function shiftChar(c)
  local shiftset = {
    [33] = "1",
    [34] = "'",
    [35] = "3",
    [36] = "4",
    [37] = "5",
    [38] = "7",
    [40] = "9",
    [41] = "0",
    [42] = "8",
    [43] = "=",
    [58] = ";",
    [60] = ",",
    [62] = ".",
    [63] = "/",
    [64] = "2",
    [94] = "6",
    [95] = "-",
    [123] = "[",
    [124] = "\\",
    [125] = "]",
    [126] = "`"
  }

  -- override the caps lock approach for case switching in order to work around a firmware bug
  if c >= 65 and c <= 90 then
    return string.char(c)
  end

  if shiftset[c] ~= nil then
    return shiftset[c]
  end

  return nil
end

function translateChar(c)
  local charset = {
    [9] = "TAB",
    [10] = "ENTER",
    -- ignore carriage return
    -- [13] = "ENTER",
    [32] = "SPACE",
    [39] = "'",
    [44] = ",",
    [45] = "-",
    [46] = ".",
    [47] = "/",
    [59] = ";",
    [61] = "=",
    [91] = "[",
    [92] = "\\",
    [93] = "]",
    [96] = "`"
  }

  if c >= 48 and c <= 57 then
    return 0, string.char(c)
  end

  -- use caps lock to switch case in order to reduce delay between calls
  if c >= 65 and c <= 90 then
    return 1, string.char(c)
  end

  if c >= 97 and c <= 122 then
    return 0, string.char(c-32)
  end

  if charset[c] ~= nil then
    return 0, charset[c]
  end

  return -1, nil
end

function mapKey(k)
  local keyboard = {
    ["LEFT_CTRL"] = 0x01,
    ["RIGHT_CTRL"] = 0x10,
    ["LEFT_SHIFT"] = 0x02,
    ["RIGHT_SHIFT"] = 0x20,
    ["LEFT_ALT"] = 0x04,
    ["RIGHT_ALT"] = 0x40,
    ["LEFT_WIN"] = 0x08,
    ["RIGHT_WIN"] = 0x80,
    ["A"] = 0x04,
    ["B"] = 0x05,
    ["C"] = 0x06,
    ["D"] = 0x07,
    ["E"] = 0x08,
    ["F"] = 0x09,
    ["G"] = 0x0A,
    ["H"] = 0x0B,
    ["I"] = 0x0C,
    ["J"] = 0x0D,
    ["K"] = 0x0E,
    ["L"] = 0x0F,
    ["M"] = 0x10,
    ["N"] = 0x11,
    ["O"] = 0x12,
    ["P"] = 0x13,
    ["Q"] = 0x14,
    ["R"] = 0x15,
    ["S"] = 0x16,
    ["T"] = 0x17,
    ["U"] = 0x18,
    ["V"] = 0x19,
    ["W"] = 0x1A,
    ["X"] = 0x1B,
    ["Y"] = 0x1C,
    ["Z"] = 0x1D,
    ["1"] = 0x1E,
    ["2"] = 0x1F,
    ["3"] = 0x20,
    ["4"] = 0x21,
    ["5"] = 0x22,
    ["6"] = 0x23,
    ["7"] = 0x24,
    ["8"] = 0x25,
    ["9"] = 0x26,
    ["0"] = 0x27,
    ["ENTER"] = 0x28,
    ["ESC"] = 0x29,
    ["BACK_SPACE"] = 0x2A,
    ["TAB"] = 0x2B,
    ["SPACE"] = 0x2C,
    ["-"] = 0x2D,
    ["="] = 0x2E,
    ["["] = 0x2F,
    ["]"] = 0x30,
    ["\\"] = 0x31,
    [";"] = 0x33,
    ["'"] = 0x34,
    ["`"] = 0x35,
    [","] = 0x36,
    ["."] = 0x37,
    ["/"] = 0x38,
    ["CAPS_LOCK"] = 0x39,
    ["F1"] = 0x3A,
    ["F2"] = 0x3B,
    ["F3"] = 0x3C,
    ["F4"] = 0x3D,
    ["F5"] = 0x3E,
    ["F6"] = 0x3F,
    ["F7"] = 0x40,
    ["F8"] = 0x41,
    ["F9"] = 0x42,
    ["F10"] = 0x43,
    ["F11"] = 0x44,
    ["F12"] = 0x45,
    ["PRINT_SCREEN"] = 0x46,
    ["SCROLL_LOCK"] = 0x47,
    ["PAUSE"] = 0x48,
    ["INSERT"] = 0x49,
    ["HOME"] = 0x4A,
    ["PAGE_UP"] = 0x4B,
    ["DELETE"] = 0x4C,
    ["END"] = 0x4D,
    ["PAGE_DOWN"] = 0x4E,
    ["RIGHT"] = 0x4F,
    ["LEFT"] = 0x50,
    ["DOWN"] = 0x51,
    ["UP"] = 0x52,
    ["NUM_LOCK"] = 0x53
  }

  if keyboard[k] ~= nil then
    return keyboard[k]
  end
  
  return nil
end

function sendKey(t, m)
  local sData
  for k, v in ipairs(t) do
    -- number of bytes sent in a single call minus one for modifier
    local i = k % 6
    if i == 1 then
      sData = {m, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
    end
    i = (i == 0 and 6 or i)
    sData[i+1] = v
    if i == 6 or k == #t then
      LIB_CH9329KbdSend(sData)
    end
  end
end

function constructKeyTable(t)
  local pChar
  local sTable = {}
  local kTable = {}
  for _, v in ipairs(t) do
    local sChar = shiftChar(string.byte(v))
    if sChar ~= nil then
      if #kTable > 0 then
        sendKey(kTable, 0x00)
        kTable = {}
      end
      -- break repeating sequences to work around a firmware bug
      if sChar == pChar then
        sendKey(sTable, mapKey("LEFT_SHIFT"))
        sTable = {}
      end
      table.insert(sTable, mapKey(sChar))
      pChar = sChar
    else
      local case, aChar = translateChar(string.byte(v))
      if case ~= -1 then
        if #sTable > 0 then
          sendKey(sTable, mapKey("LEFT_SHIFT"))
          sTable = {}
        end
        if case ~= capslock then
          table.insert(kTable, mapKey("CAPS_LOCK"))
          capslock = case
        end
        -- break repeating sequences to work around a firmware bug
        if aChar == pChar then
          sendKey(kTable, 0x00)
          kTable = {}
        end
        table.insert(kTable, mapKey(aChar))
        pChar = aChar
      end
    end
  end
  if #sTable > 0 then
    sendKey(sTable, mapKey("LEFT_SHIFT"))
  end
  if #kTable > 0 then
    sendKey(kTable, 0x00)
  end
end

function cmdline()
  sendKey({mapKey("R")}, mapKey("LEFT_WIN"))
  LIB_DelayMs(1000)
  sendKey({mapKey("C"), mapKey("M"), mapKey("D"), mapKey("ENTER")}, 0X00)
  LIB_DelayMs(1000)
end

function exitcmd()
  LIB_DelayMs(1000)
  sendKey({mapKey("E"), mapKey("X"), mapKey("I"), mapKey("T"), mapKey("ENTER")}, 0X00)
end

--[[ Reserved for use with WiFi configuration using config file, implementation code commented out to reduce program size in order to squeeze in the main memory size limit.

function readlines(file)
  local lines = {}
  local line = {}
  local n, data = LIB_Fread(file, 0)
  if n > 0 then
    for _, v in ipairs(data) do
      if string.char(v) ~= "\n" then
        if string.char(v) ~= " " and string.char(v) ~= "\t" and string.char(v) ~= "\r" then
          table.insert(line, string.char(v))
        end
      else
        if not rawequal(next(line), nil) then
          table.insert(lines, table.concat(line))
          line = {}
        end
      end
    end
    if not rawequal(next(line), nil) then
      table.insert(lines, table.concat(line))
    end
  end
  return lines
end
--]]

--[[ Reserved for use with WiFi configuration using config file, implementation code commented out to reduce program size in order to squeeze in the main memory size limit.

function parseKV(lines)
  local kv = {}
  for _, line in ipairs(lines) do
    for k, v in string.gmatch(line, "(%w+)=(%w+)") do
      kv[k] = v
    end
  end
  return kv
end
--]]

function init()
  print("Initializing....")
end

init()

while(GC(1) == true) do
    if LIB_ButtonQuery("BTN1") == 1 then
      done = false
    end

    if not done then
      LIB_DelayMs(1000)
      cmdline()
      i = 0
      repeat
        -- size limit of 256 bytes returned by LIB_Fread API
        n, data = LIB_Fread(PAYLOAD, i*256)
        if n > 0 then
          constructKeyTable(utf8(data))
          if n < 256 then
            break
          end
          i = i + 1
        end
      until(n == 0)
      exitcmd()
      done = true
    end

    if LIB_ButtonQuery("BTN2") == 1 then
      LIB_SystemReset()
    end
end
