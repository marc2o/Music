--[[
                                    ___
       ______    ___    ___   ___  /    \ ___
    _/       \_/    \_/ _  \_/   \_--   /-   \
   /   /  /  /   /  /   /__/  /__/   __/   / /
  /___/__/__/\__/\_/___/   \____/      \____/
  (c) 2020 – 2022 marc2o        \______/
  https://marc2o.github.io

--]]

-- WORK IN PROGRESS
function math.clamp(low, n, high)
  return math.min(math.max(n, low), high)
end

function math.numberToBytes(number, numberOfBytes)
  local byteChars = ""
  local bytes = {}
  if numberOfBytes == 4 then
      table.insert(bytes, math.floor((number % 2^32) / 2^24))
  end
  if numberOfBytes >= 3 then
      table.insert(bytes, math.floor((number % 2^24) / 2^16))
  end
  if numberOfBytes >= 2 then
      table.insert(bytes, math.floor((number % 2^16) / 2^8))
  end
  if numberOfBytes >= 1 then
      table.insert(bytes, math.floor((number % 2^8)))
  end
  for i = 1, #bytes do
      byteChars = byteChars .. string.char(bytes[i])
  end
  return byteChars
end


aiff = {}

function aiff:createFile(filename)
  --return io.open(filename .. ".aiff", "w")
  return love.filesystem.newFile(filename .. ".aiff", "w")
end

function aiff:writeFile(file, args, ...)
  local soundData = args.soundData
  local sampleRate = soundData:getSampleRate()
  local sampleSize = soundData:getBitDepth()
  local numChannels = soundData:getChannelCount()
  local numSampleFrames = soundData:getSampleCount() / numChannels
  local dataSize = soundData:getDuration() * sampleRate * sampleSize / 8
  file:write("FORM????AIFF")

  file:write(self:getChunk({
    ID = "COMM",
    dataSize = 18,
    numChannels = numChannels,
    numSampleFrames = numSampleFrames,
    sampleSize = sampleSize,
    sampleRate = sampleRate
  }))
  
  file:write(self:getChunk({
    ID = "SSND",
    dataSize = dataSize
  }))
  
  self:writePCM({
    file = file,
    soundData = soundData,
    sampleSize = sampleSize
  })

  file:write(self:getChunk({
    ID = "NAME",
    text = args.title
  }))
  
  file:write(self:getChunk({
    ID = "AUTH",
    text = args.composer
  }))

  local fileInfo = love.filesystem.getInfo(file:getFilename())
  local fileSize = fileInfo.size
  file:seek(4)
  --local fileSize = file:seek()
  --file:seek("set", 4)
  file:write(math.numberToBytes(fileSize - 8, 4))
end

function aiff:closeFile(file)
  file:close()
  file = nil
end

function aiff:writePCM(args, ...)
  local size = 2^args.sampleSize / 2
  for i = 0, args.soundData:getSampleCount() - 1 do
    local sample = args.soundData:getSample(i) * size
    sample = math.clamp(-size, sample, size - 1)
    sample = math.numberToBytes(sample, args.sampleSize / 8)
    args.file:write(sample)
  end
end

function aiff:getChunk(args, ... )
  if args.ID == "FORM" then
    return
      "FORM" ..
      math.numberToBytes(args.dataSize, 4) ..
      "AIFF"
  end
  
  if args.ID == "COMM" then
    local nfreq = string.char(0x40)
    if args.sampleRate == 11025 then
      nfreq = nfreq .. string.char(0x0c)
    elseif args.sampleRate == 22050 then
      nfreq = nfreq .. string.char(0x0d)
    else
      nfreq = nfreq .. string.char(0x0e)
    end
    nfreq = nfreq .. string.char(0xac) .. string.char(0x44)
    for i = 1, 6 do
      nfreq = nfreq .. string.char(0)
    end
    return
      "COMM" ..
      math.numberToBytes(args.dataSize, 4) ..
      math.numberToBytes(args.numChannels, 2) ..
      math.numberToBytes(args.numSampleFrames, 4) ..
      math.numberToBytes(args.sampleSize, 2) ..
      nfreq --..
      --"NONE" ..
      --"not compressed"
  end
  
  if args.ID == "SSND" then
    return
      "SSND" ..
      math.numberToBytes(args.dataSize, 4) ..
      math.numberToBytes(0, 4) .. -- offset
      math.numberToBytes(0, 4) -- block size
  end

  if args.ID == "NAME" then
    return
      "NAME" ..
      math.numberToBytes(string.len(args.text), 4) ..
      args.text
  end

  if args.ID == "AUTH" then
    return
      "AUTH" ..
      math.numberToBytes(string.len(args.text), 4) ..
      args.text
  end
end

