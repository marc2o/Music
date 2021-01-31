synth = {
    sampleRate = 11025, --44100 = HQ
    bits = 8,
    channels = 1,
    baseFrequency = 440,
    amplitude = 0.3,
  
    sequence = {
      osc = "SIN", -- default sound
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
        env1 = {
          attack = 0.02,
          -- ATTACK: time taken for initial run-up of level from nil to peak, beginning when the key is pressed
          decay = 0.80,
          -- DECAY: time taken for the subsequent run down from the attack level to the designated sustain level
          sustain = 0.60,
          -- SUSTAIN: level during the main sequence of the sound's duration, until the key is released
          release = 0.20
          -- RELEASE: time taken for the level to decay from the sustain level to zero after the key is released
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
  
    loadMML = function (path)
      synth.mml = love.filesystem.read("string", path)
    end,
    
    playSequence = function (file)
      synth.loadMML(file)
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
              lastNote = lastNote
            })
            
            for s = 1, sound:getSampleCount() - 1 do
              synth.audioData:setSample(sampleIndex, synth.audioData:getSample(sampleIndex) + sound:getSample(s) / synth.voices.number)
              sampleIndex = sampleIndex + 1
            end
          end

        end
      end
    end,
  
    parseMML = function (mml)
      local pos = 1
      local octave = 4
      local volume = 1
      local finished = false
      local waveform = synth.sequence.osc
  
      repeat
        --[[
          parser based on love-mml
          https://github.com/GoonHouse/love-mml
        ]]
        local c, args, newpos = string.match(string.sub(mml, pos), "^([%a<>])(%A-)%s-()[%a<>]")
        
        if not c then
          -- might be the last command in the string.
          c, args = string.match(string.sub(mml, pos), "^([%a<>])(%A-)")
          newpos = 0
        end
        
        if not c then
          -- probably bad syntax.
          error("Malformed MML")
        end
  
        pos = pos + (newpos - 1)
  
        if string.match(c, "%u") then -- capital letters indicate channels
          synth.voices.currentVoice = c
          local voiceExists = false
          for k, v in pairs(synth.voices) do
            if k == c then voiceExists = true end
          end
          if not voiceExists then
            synth.voices[synth.voices.currentVoice] = {}
            synth.voices[synth.voices.currentVoice].osc = "SQR"
            synth.voices[synth.voices.currentVoice].len = 0
            synth.voices[synth.voices.currentVoice].data = {}
          end
        end
  
        if c == "o" then -- set octave
          octave = tonumber(args)
    
        elseif c == "t" then -- set tempo in bpm
          synth.sequence.t = tonumber(args)
    
        elseif c == "v" then -- set volume 0 to 15
          synth.sequence.v = tonumber(args) / 15
    
        elseif c == "x" then -- set waveform 1 to 5 for current voice
          local waveforms = { "SIN", "SAW", "SQR", "TRI", "NSE" }
          waveform = waveforms[tonumber(args)]
  
        elseif c == "r" or c == "w" then -- rest (wait is treated as rest for now)
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
              volume = synth.sequence.v
            }
          })
          synth.voices[synth.voices.currentVoice].len = synth.voices[synth.voices.currentVoice].len + duration
  
        elseif c == "l" then -- set note length
          synth.sequence.l = tonumber(args)
    
        elseif c == ">" then -- increase octave
          octave = octave + 1
    
        elseif c == "<" then -- decrease octave
          octave = octave - 1
  
        elseif c:find("[a-g]") then -- play note
          local note
          local mod = string.match(args, "[+#-]")
          if mod then
            if mod == "#" or mod == "+" then
              note = c .. "+" .. octave
            elseif mod == "-" then
              note = c .. "-" .. octave
            end
          else
            note = c .. octave
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
              volume = synth.sequence.v
            }
          })
          synth.voices[synth.voices.currentVoice].len = synth.voices[synth.voices.currentVoice].len + duration
        end
  
      until newpos == 0
    end,
  
    getSound = function (args, ...)
      local note = args.note or "a"
      local lastNote = args.lastNote or ""
      local waveform = args.waveform or synth.sequence.osc
      local duration = args.duration
      local frequency = synth.baseFrequency
      local volume = args.volume or synth.sequence.v

      if note ~= "r" then
        frequency = synth.noteToFrequency(note)
        synth.oscillators.osc = synth.oscillators[waveform](frequency, ...)
      end
      if lastnote == "r" then
        synth.oscillators.osc = nil
      end

      local sample = 0
      local data = love.sound.newSoundData(duration * synth.sampleRate, synth.sampleRate, synth.bits, synth.channels)
      local envelope = 0

      for i = 0, duration * synth.sampleRate - 1 do
        local attackSamples = synth.envelopes.env1.attack * synth.sampleRate
        local decaySamples = attackSamples + synth.envelopes.env1.decay * synth.sampleRate
        local sustainVolume = synth.envelopes.env1.sustain
        local releaseSamples = synth.envelopes.env1.release * synth.sampleRate
  
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
            envelope = 0 -- no release envelope yet
          end
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
  