-- WORK IN PROGRESS
function math.clamp(low, n, high) return math.min(math.max(n, low), high) end

aiff = {
    FORM = "",
    COMM = "",
    SNDD = "",
    NAME = "",
    AUTH = "",

    createFile = function (filename)
        return io.open(filename .. ".aiff", "w")
    end,
    writeFile = function (file, args, ...)
        local soundData = args.soundData
        local sampleRate = soundData:getSampleRate()
        local sampleSize = soundData:getBitDepth()
        local numChannels = soundData:getChannelCount()
        local numSampleFrames = soundData:getSampleCount() / numChannels
        local dataSize = soundData:getDuration() * sampleRate * sampleSize / 8

        file:write("FORM????AIFF")

        file:write(aiff.getChunk({
            ID = "COMM",
            dataSize = dataSize,
            numChannels = numChannels,
            numSampleFrames = numSampleFrames,
            sampleSize = sampleSize,
            sampleRate = sampleRate
        }))
        file:write(aiff.getChunk({
            ID = "SNDD",
            dataSize = dataSize,
            sampleSize = sampleSize,
            soundData = soundData
        }))
        file:write(aiff.getChunk({
            ID = "NAME",
            text = args.title
        }))
        file:write(aiff.getChunk({
            ID = "AUTH",
            text = args.composer
        }))

        local fileSize = file:seek()
        file:seek("set", 4)
        file:write(aiff.numberToBytes(fileSize - 8, 4))
        --file:seek("set", 40)
        --file:write(aiff.numberToBytes(fileSize - 44, 4))
    end,
    closeFile = function (file)
        file:close()
        file = nil
    end,

    numberToBytes = function (number, numberOfBytes)
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
    end,

    getChunk = function (args, ... )
        if args.ID == "FORM" then
            return
                "FORM" ..
                aiff.numberToBytes(args.dataSize, 4) ..
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
                aiff.numberToBytes(args.dataSize, 4) ..
                aiff.numberToBytes(args.numChannels, 2) ..
                aiff.numberToBytes(args.numSampleFrames, 4) ..
                aiff.numberToBytes(args.sampleSize, 2) ..
                nfreq ..
                "NONE" ..
                "not compressed"
        end
        if args.ID == "SNDD" then
            local soundData = ""
            local size = 2^args.sampleSize / 2
            --for i = 0, args.soundData:getSampleCount() - 1 do
            for i = 0, 150000 do
                local sample = args.soundData:getSample(i) * size
                sample = math.clamp(-size, sample, size - 1)
                sample = aiff.numberToBytes(sample, args.sampleSize / 8)
                soundData = soundData .. sample
            end

            return
                "SNDD" ..
                aiff.numberToBytes(args.dataSize, 4) ..
                aiff.numberToBytes(0, 4) .. -- offset
                aiff.numberToBytes(0, 4) .. -- block size
                soundData
        end
        if args.ID == "NAME" then
            return
                "NAME" ..
                aiff.numberToBytes(string.len(args.text), 4) ..
                args.text
        end
        if args.ID == "AUTH" then
            return
                "AUTH" ..
                aiff.numberToBytes(string.len(args.text), 4) ..
                args.text
        end
    end
}

