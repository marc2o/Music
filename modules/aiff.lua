-- WORK IN PROGRESS

aiff = {
    COMM = {
        -- Common Chunk (required)
        ID = "COMM",
        dataSize = 0, -- long
        numChannels = 0, -- short
        numSampleFrames = 0, -- long, samples per channel
        sampleSize = 0, -- short, bits per sample
        sampleRate = 0, -- extended
        compressionType = "NONE",
        compressionName = "not compressed"
    },
    SNDD = {
        -- Sound Data Chunk (required)
        ID = "SNDD",
        dataSize = 0, -- long, size in bytes
        offset = 0, -- long, usually 0
        blockSize = 0, -- long, usually 0
        soundData = 0 -- bytes
    },
    NAME = {
        -- Name Chunk
        ID = "NAME",
        dataSize = 0, -- long
        text = "" -- bytes
    },
    AUTH = {
        -- Author Chunk
        ID = "AUTH",
        dataSize = 0, -- long
        text = "" -- bytes
    },

    createFile = function (filename)
        return io.open(filename .. ".aiff", "w")
    end,
    writeToFile = function (file, content)
        file:write(content)
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
        if args.ID == "COMM" then
            aiff[args.ID].dataSize = aiff.numberToBytes(args.dataSize, 4)
            aiff[args.ID].numChannels = aiff.numberToBytes(args.numChannels, 2)
            aiff[args.ID].numSampleFrames = aiff.numberToBytes(args.numSampleFrames, 4)
            aiff[args.ID].sampleSize = aiff.numberToBytes(args.sampleSize, 2)
            aiff[args.ID].sampleRate = aiff.numberToBytes(args.sampleRate, 4)
            
            return aiff[args.ID].ID ..
                aiff[args.ID].dataSize ..
                aiff[args.ID].numChannels ..
                aiff[args.ID].numSampleFrames ..
                aiff[args.ID].sampleSize ..
                aiff[args.ID].sampleRate..
                aiff[args.ID].compressionType ..
                aiff[args.ID].compressionName
        end
        if args.ID == "SNDD" then
            aiff[args.ID].dataSize = aiff.numberToBytes(args.dataSize, 4)
            aiff[args.ID].offset = aiff.numberToBytes(0, 4)
            aiff[args.ID].blockSize = aiff.numberToBytes(0, 4)

            return aiff[args.ID].ID ..
                aiff[args.ID].dataSize ..
                aiff[args.ID].offset ..
                aiff[args.ID].blockSize
        end
        if args.ID == "NAME" then
            aiff[args.ID].dataSize = aiff.numberToBytes(string.len(args.text), 4)
            aiff[args.ID].text = args.text
            
            return aiff[args.ID].ID .. aiff[args.ID].dataSize .. aiff[args.ID].text
        end
        if args.ID == "AUTH" then
            aiff[args.ID].dataSize = aiff.numberToBytes(string.len(args.text), 4)
            aiff[args.ID].text = args.text
            
            return aiff[args.ID].ID .. aiff[args.ID].dataSize .. aiff[args.ID].text
        end
    end
}

