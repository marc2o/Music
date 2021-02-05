synth = {
    --[[
      synthesizer and sequencer module for Lua/LÖVE
      written by Marc Oliver Orth
      © 2021
    ]]
    sampleRate = 11025, --44100 = HQ
    bits = 8,
    channels = 1,
    baseFrequency = 440,
    amplitude = 1,
  
    sequence = {
      osc = "TRI", -- default sound
      v = 1,
      t = 120,
      o = 4,
      l = 1
    },
    voices = {
      currentVoice = ""
    },

    mml = "",
    audioData = 0,
  
    envelopes = {
      default = {
        attack = 0,
        decay = 0,
        sustain = 1,
        release = 0
      }
    },

    lowFrequencyOscillators = {
      lfo1 = 0.5 - 0.4 * math.cos(2 * math.pi * 6 * 1), -- t = 1
    },

    oscillators = {
      osc = nil,
      --[[
        oscillators based on the denver synthesizer library
        https://love2d.org/forums/viewtopic.php?t=79499
      ]]
      SIN = function (f)
        local phase = 0
        return function()
          phase = phase + 2 * math.pi / synth.sampleRate
          if phase >= 2 * math.pi then
            phase = phase - 2 * math.pi
          end
          return math.sin(f * phase)
        end
      end,
      
      SAW = function (f)
        local dv = 2 * f / synth.sampleRate
        local v = 0
        return function()
          v = v + dv
          if v > 1 then v = v - 2 end
          return v
        end
      end,
      
      SQR = function (f, pwm)
        pwm = pwm or 0
        if pwm >= 1 or pwm < 0 then
          error('PWM must be between 0 and 1 (0 <= PWM < 1)', 2)
        end
        local saw = synth.oscillators.SAW(f)
        return function()
          return saw() < pwm and -1 or 1
        end
      end,
      
      TRI = function (f)
        local dv = 1 / synth.sampleRate
        local v = 0
        local a = 1 -- up or down
        return function()
          v = v + a * dv * 4 * f
          if v > 1 or v < -1 then
            a = a * -1
            v = math.floor(v+.5)
          end
          return v
        end
      end,
      
      NSE = function ()
        return function()
          return math.random() * 2 - 1
        end
      end    
    },
  
    load = function (path)
      synth.mml = love.filesystem.read("string", path)
    end,
    
    play = function ()
      synth.parseMML(synth.mml)
      synth.renderAudio()
  
      local music = love.audio.newSource(synth.audioData)
      love.audio.play(music)
    end,
  
    renderAudio = function ()
      local key = next(synth.voices)
      local maxLength = synth.voices[key].len
      local maxNotes = #synth.voices[key].data
      local voices = 0

      for k, v in pairs(synth.voices) do
        if string.match(tostring(k), "[ABCDEFGH]") then
          if synth.voices[k].len > maxLength then
            maxLength = synth.voices[k].len
          end
          if #synth.voices[key].data > maxNotes then
            maxNotes = #synth.voices[key].data
          end
          voices = voices + 1
        end
      end
  
      synth.voices.totalLength = maxLength
      synth.voices.maxNumberOfNotes = maxNotes
      synth.voices.number = voices
  
      synth.audioData = love.sound.newSoundData(
        synth.voices.totalLength * synth.sampleRate,
        synth.sampleRate,
        synth.bits,
        synth.channels
      )
  
      for k, v in pairs(synth.voices) do
        if string.match(tostring(k), "[ABCDEFGH]") then
          local sampleIndex = 1

          for i = 1, #synth.voices[k].data do
            local lastNote = ""
            
            if i > 1 then lastNote = synth.voices[k].data[i - 1][1].note end
            
            local sound = synth.getSound({
              waveform = synth.voices[k].data[i][1].waveform,
              note = synth.voices[k].data[i][1].note,
              duration = synth.voices[k].data[i][1].duration,
              volume = synth.voices[k].data[i][1].volume,
              envelope = synth.voices[k].data[i][1].envelope,
              lastNote = lastNote
            })
            
            if sound ~= nil then
              for s = 1, sound:getSampleCount() - 1 do
                local sample = math.tanh(synth.audioData:getSample(sampleIndex) + sound:getSample(s) / synth.voices.number)
                synth.audioData:setSample(sampleIndex, sample)
                sampleIndex = sampleIndex + 1
              end
            end
          end

        end
      end
    end,
  
    parseMML = function (mml)
      local pos = 1
      local newpos = 0
      local octave = 4
      local volume = nil
      local waveform = synth.sequence.osc
      local envelope = nil
  
      for cmd, args, next in string.gmatch(mml, "(@v%d+).-=(.-)\n()") do
        local num = string.match(cmd, "(%d+)")
        local cmd = string.match(cmd, "(@v)")
        local env = string.match(args, "{(.-)}")
        local val = {}
        for token in string.gmatch(env, "[^%s]+") do
          table.insert(val, token / 100)
        end
        synth.envelopes[num] = {}
        synth.envelopes[num].attack = val[1]
        synth.envelopes[num].decay = val[2]
        synth.envelopes[num].sustain = val[3]
        synth.envelopes[num].release = val[4]
        pos = next + 1
      end

      repeat
        --[[
          parser originally based on love-mml (https://github.com/GoonHouse/love-mml)
          but extended evaluating more commands and made compatible with various MML dialects 
        ]]
        local tie = ""
        local cmd, args, newpos = string.match(string.sub(mml, pos), "^([%a<>@&])(%A-)%s-()[%a<>@&]")
        
        if not cmd then
          -- might be the last command in the string.
          cmd, args = string.match(string.sub(mml, pos), "^([%a<>@&])(%A-)")
          newpos = 0
        end

        if not cmd then
          -- might be a comment starting with # and ends with line break
          cmd, args, newpos = string.match(string.sub(mml, pos), "^(#)(.-)\n()[%a<>@&]")
        end

        if not cmd then
          -- probably bad syntax.
          error("Malformed MML")
        end

        if string.match(cmd, "%u") then -- capital letters indicate channels
          synth.voices.currentVoice = cmd
          local voiceExists = false
          for k, v in pairs(synth.voices) do
            if k == cmd then voiceExists = true end
          end
          if not voiceExists then
            volume = nil
            synth.voices[synth.voices.currentVoice] = {}
            synth.voices[synth.voices.currentVoice].osc = "SQR"
            synth.voices[synth.voices.currentVoice].len = 0
            synth.voices[synth.voices.currentVoice].data = {}
          end
        end

        if cmd == "o" then -- set octave
          octave = tonumber(args)
    
        elseif cmd == "t" then -- set tempo in bpm
          synth.sequence.t = tonumber(args)
    
        elseif cmd == "v" then -- set volume 0 to 100
          if string.sub(mml, pos - 1, pos - 1) ~= "@" then
            volume  = tonumber(args) / 100
          end
    
        elseif cmd == "@" then -- set waveform 1 to 5 for current voice
          local test = string.match(string.sub(mml, pos), "^(@v%d+)")
          if test then
            envelope = string.match(test, "(%d+)")
          else
            local waveforms = { "SIN", "SAW", "SQR", "TRI", "NSE" }
            waveform = waveforms[tonumber(args)]
          end

        elseif cmd == "&" then -- tie notes
          table.insert(synth.voices[synth.voices.currentVoice].data, {
            {
              waveform = "",
              note = "&",
              duration = 0,
              volume = nil
            }
          })
  
        elseif cmd == "r" or cmd == "p" or cmd == "w" then -- rest, pause (wait is treated as rest for now)
          local duration
          if args ~= "" then
            duration = (1 / tonumber(args)) * (60 / synth.sequence.t)
          else
            duration = (1 / synth.sequence.l) * (60 / synth.sequence.t)
          end
  
          table.insert(synth.voices[synth.voices.currentVoice].data, {
            {
              waveform = waveform,
              note = "r",
              duration = duration,
              volume = volume,
              envelope = envelope
            }
          })
          synth.voices[synth.voices.currentVoice].len = synth.voices[synth.voices.currentVoice].len + duration
  
        elseif cmd == "l" then -- set note length
          synth.sequence.l = tonumber(args)
    
        elseif cmd == ">" then -- increase octave
          octave = octave + 1
    
        elseif cmd == "<" then -- decrease octave
          octave = octave - 1
  
        elseif cmd:find("[a-h]") then -- play note using c, d, e, f, g, a, h or b
          local note
          local mod = string.match(args, "[+#-]")
          if mod then
            if mod == "#" or mod == "+" then
              note = cmd .. "+" .. octave
            elseif mod == "-" then
              note = cmd .. "-" .. octave
            end
          else
            note = cmd .. octave
          end
    
          local duration
          local len = string.match(args, "%d+")
          if len then
            duration = (1 / tonumber(len)) * (60 / synth.sequence.t)
          else
            duration = (1 / synth.sequence.l) * (60 / synth.sequence.t)
          end
    
          if string.find(args, "%.") then -- dottet note
            duration = duration * 1.5
          end
    
          table.insert(synth.voices[synth.voices.currentVoice].data, {
            {
              waveform = waveform,
              note = note,
              duration = duration,
              volume = volume,
              envelope = envelope
            }
          })
          synth.voices[synth.voices.currentVoice].len = synth.voices[synth.voices.currentVoice].len + duration
        end

        pos = pos + (newpos - 1)
  
      until newpos == 0
    end,
  
    getSound = function (args, ...)
      local note = args.note or "a"
      local lastNote = args.lastNote or ""
      local waveform = args.waveform or synth.sequence.osc
      local volumeEnvelope = args.envelope or "default"
      local duration = args.duration
      local frequency = synth.baseFrequency
      local volume = args.volume or synth.sequence.v

      if note == "&" then
        return nil
      end

      if note ~= "r" then
        frequency = synth.noteToFrequency(note)
        synth.oscillators.osc = synth.oscillators[waveform](frequency, ...)
      end
      if note == "r" and lastNote == "r" then
        synth.oscillators.osc = nil
      end

      local sample = 0
      local data = love.sound.newSoundData(duration * synth.sampleRate, synth.sampleRate, synth.bits, synth.channels)
      local envelope = 0

      local attackSamples = synth.envelopes[volumeEnvelope].attack * synth.sampleRate
      local decaySamples = attackSamples + synth.envelopes[volumeEnvelope].decay * synth.sampleRate
      local sustainVolume = synth.envelopes[volumeEnvelope].sustain
      local releaseSamples = synth.envelopes[volumeEnvelope].release * synth.sampleRate

      for i = 0, duration * synth.sampleRate - 1 do
  
        if note ~= "r" then
          if i <= attackSamples then
            envelope = i / (attackSamples - 1)
          elseif i > attackSamples and i <= decaySamples then
            envelope = sustainVolume + (1 - sustainVolume) * (1 - (i / decaySamples))
          elseif i > decaySamples then
            envelope = sustainVolume
          end
        else
          if i <= releaseSamples then
            envelope = sustainVolume * (1 - i / releaseSamples)
          end
        end

        if lastNote == "&" then
          envelope = sustainVolume
        end
  
        if synth.oscillators.osc ~= nil then
          sample = synth.oscillators.osc(synth.baseFrequency, synth.sampleRate) * synth.amplitude * volume * envelope
        else
          sample = 0
        end

        data:setSample(i, sample)
      end

      return data
    end,
  
    noteToFrequency = function (note)
      if not note or type(note) ~= "string" then
        return
      end
      local notes = { c = -9, d = -7, e = -5, f = -4, g = -2, a = 0, b = 2, h = 2 }
      local octave = synth.sequence.o 
      local value = notes[string.sub(note, 1, 1)]
  
      if string.len(note) == 3 and string.match(string.sub(note, 3, 3), "%d")  then
        octave = string.sub(note, 3, 3)
      end
      if string.len(note) >= 2 then
        if string.match(string.sub(note, 2, 2), "%d") then
          octave = string.sub(note, 2, 2)
        end
        if string.sub(note, 2, 2) == "+" then
            value = value + 1
        end
        if string.sub(note, 2, 2) == "-" then
          value = value - 1
        end
      end
  
      value = value + 12 * (octave - 4)
      return synth.baseFrequency * math.pow(math.pow(2, 1 / 12), value)
    end
  }
  