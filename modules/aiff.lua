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
        local numChannels = soundData:getChannels()
        local numSampleFrames = soundData:getSampleCount() / numChannels
        local dataSize = soundData:getDuration() * sampleRate * sampleSize / 8

        -- local cjunks
        aiff.COMM = aiff.getChunk({
            ID = "COMM",
            dataSize = dataSize,
            numChannels = numChannels,
            numSampleFrames = numSampleFrames,
            sampleSize = sampleSize,
            sampleRate = sampleRate
        })        
        aiff.SNDD = aiff.getChunk({
            ID = "SNDD",
            dataSize = dataSize,
            sampleSize = sampleSize,
            soundData = soundData
        })
        aiff.NAME = aiff.getChunk({
            ID = "NAME",
            text = args.title
        })
        aiff.AUTH = aiff.getChunk({
            ID = "AUTH",
            text = args.composer
        })

        local localChunks = aiff.COMM .. aiff.SNDD .. aiff.NAME .. aiff.AUTH
        local fileSize = string.len(localChunks)
        aiff.FORM = aiff.getChunk({
            ID = "FORM",
            dataSize = fileSize,
            --dataSize = args.dataSize + string.len(args.title) + string.len(args.composer) + 4 * 8,
            type = "AIFF"
        })

        file:write(aiff.FORM .. localChunks)
    end,
    closeFile = function (file)
        file:close()
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
            return
                "COMM" ..
                aiff.numberToBytes(args.dataSize, 4) ..
                aiff.numberToBytes(args.numChannels, 2) ..
                aiff.numberToBytes(args.numSampleFrames, 4) ..
                aiff.numberToBytes(args.sampleSize, 2) ..
                aiff.numberToBytes(args.sampleRate, 4)..
                "NONE" ..
                "not compressed"
        end
        if args.ID == "SNDD" then
            local soundData = ""
            --for i = 0, args.soundData:getSampleCount() - 1 do
            local size = 2^args.sampleSize
            for i = 0, 10000 do
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

