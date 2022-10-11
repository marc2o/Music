--[[
                                    ___
       ______    ___    ___   ___  /    \ ___
    _/       \_/    \_/ _  \_/   \_--   /-   \
   /   /  /  /   /  /   /__/  /__/   __/   / /
  /___/__/__/\__/\_/___/   \____/      \____/
  (c) 2020 – 2022 marc2o        \______/
  https://marc2o.github.io

--]]

music = {
  tracks = {
    current_track = "A",
    info = {
      A = {},
      B = {},
      C = {},
      D = {},
      E = {}
    },
    data = {
      A = {}, -- pulse wave (with duty cycle)
      B = {}, -- pulse wave (with duty cycle)
      C = {}, -- triangle wave (no volume control, only v0 or v1)
      D = {}, -- sawtooth wave
      E = {}  -- white noise  
    }
  },
  meta = {
    title = "",
    composer = "",
    programmer = "",
    copyright = "",  
  },
  timebase = 480,
  tempo = 80, -- beats per minute
  base_frequency = 440,
  sample_rate = 11025,
  bits = 8,
  channels = 1,
  amplitude = 1.0,
  envelopes = {
    default = {
      a = 1 / 60 * 11025, -- duration * sample_rate
      d = 32 / 60 * 11025,
      s = 80 / 0x7F, -- volume 0..127 -> 0.0..1.0
      r = 48 / 60 * 11025   
    }
  },
  audio = {
    source = nil,
    sound_data = nil
  },
  mml = {}
}
  
-- pulse wave
function music:PULSE(sample_rate, frequency, duty_cycle) --> function()
  -- number of points in dataset
  local npoints = sample_rate / frequency
  local duty_cycle = duty_cycle or 0.5

  return function(i)
    i = i % npoints + 1
    return i < (npoints * duty_cycle) and -1 or 1
  end
end

function music:TRIANGLE(sample_rate, frequency) --> function()
  local npoints = sample_rate / frequency
  
  return function(i)
    i = i % npoints + 1
    local step = 4 / npoints
    return i < (npoints / 2) and step * (i - 1) - 1 or step * ((i - 1) - npoints / 2)
  end
end

function music:SAWTOOTH(sample_rate, frequency) --> function()
  local npoints = sample_rate / frequency

  return function(i)
    i = i % npoints + 1
    local step = 4 / npoints
    return i < npoints - 1 and step * (i - 1) - 1 or -1
  end
end

function music:NOISE(sample_rate, frequency) --> function()
  local npoints = sample_rate / frequency

  return function()
    i = i % npoints + 1
    return i < npoints - 1 and math.random(-1.0, 1.0)
  end
end

function music:init()
  if self.audio.source then self:stop() end
  self.audio = { source = nil, sound_data = nil }
  self.meta.title = ""
  self.meta.composer = ""
  self.meta.programer = ""
  self.meta.copyright = ""
  self.tracks.data.A = {}
  self.tracks.info.A = {}
  self.tracks.data.B = {}
  self.tracks.info.B = {}
  self.tracks.data.C = {}
  self.tracks.info.C = {}
  self.tracks.data.D = {}
  self.tracks.info.D = {}
  self.tracks.data.E = {}
  self.tracks.info.E = {}
end
function music:play()
  if self.audio.source then love.audio.play(self.audio.source) end
end
function music:stop()
  love.audio.stop()
end
function music:is_playing() --> bool
  if self.audio.source then
    return self.audio.source:isPlaying()
  else
    return false
  end
end
function music:pause()
  if self:is_playing() and self.audio.source then
    love.audio.pause(self.audio.source)
  elseif not self:is_playing() and self.audio.source then
    love.audio.play(self.audio.source)
  end
end
function music:get_current_sample() --> value
  local position = self.audio.source:tell("seconds")
  position = math.floor(position * self:get_sample_rate())
  return self.audio.sound_data:getSample(position)
end

function music:set_info(keyword, value)
  if string.lower(keyword) == "title" then
    self.meta.title = value
  elseif string.lower(keyword) == "composer" then
    self.meta.composer = value
  elseif string.lower(keyword) == "programmer" or string.lower(keyword) == "programer" then
    self.meta.programmer = value
  elseif string.lower(keyword) == "copyright" then
    self.meta.copyright = value
  elseif string.lower(keyword) == "timebase" then
    self.timebase = tonumber(value)
  else
    -- keyword not recognized
    -- ignore
  end
end

function music:get_used_voices()
  return {
    A = next(self.tracks.data.A) and true or false,
    B = next(self.tracks.data.B) and true or false,
    C = next(self.tracks.data.C) and true or false,
    D = next(self.tracks.data.D) and true or false,
    E = next(self.tracks.data.E) and true or false,
  }
end

function music:get_title() --> string
  return self.meta.title
end

function music:get_composer() --> string
  return self.meta.composer
end

function music:get_programmer() --> string
  return self.meta.programmer
end

function music:get_copyright() --> string
  return self.meta.copyright
end

function music:get_timebase() --> number
  return self.timebase
end

function music:get_sample_rate() --> number
  return self.sample_rate
end

function music:define_envelope(name, attack, decay, sustain, release)
  self.envelopes[name] = {
    a = attack / 60 * self.sample_rate,
    d = decay / 60 * self.sample_rate,
    s = sustain / 0x7F,
    r = release / 60 * self.sample_rate
  }
end
function music:set_envelope(name)
  local track = track or self:get_track()
  self.tracks.info[track].envelope = name
end
function music:get_envelope(track) --> string
  local envelope = self.tracks.info[track].envelope or "default"
  return envelope
end

function music:set_track(letter)
  self.tracks.current_track = letter
end
function music:get_track() --> string
  return self.tracks.current_track
end

function music:set_tempo(bpm)
  self.tempo = bpm
end
function music:get_tempo() --> number
  return self.tempo
end

function music:set_volume(volume, track)
  local track = track or self:get_track()
  if track == "C" then
    volume = tostring(volume / volume) == tostring(0/0) and 0 or 0.9
  else
    volume = volume / 0x7F
  end
  self.tracks.info[track].volume = volume
end
function music:get_volume(track) --> number 0..127
  local volume = self.tracks.info[track].volume or 80 / 0x7F
  if track == "C" then
    volume = tostring(volume / volume) == tostring(0/0) and 0 or 0.9
  end
  return volume
end

function music:shift_octave(shift, track)
  local track = track or self:get_track()
  local octave = self:get_octave(track)
  octave = octave + shift
  self:set_octave(octave)
end
function music:set_octave(octave, track)
  local track = track or self:get_track()
  self.tracks.info[track].octave = octave
end
function music:get_octave(track) --> number
  local octave = self.tracks.info[track].octave or 4
  return octave
end

function music:set_length(length, track)
  local track = track or self:get_track()
  self.tracks.info[track].length = length
end
function music:get_length(track) --> number
  local length = self.tracks.info[track].length or 4
  return length
end

function music:set_quantization(q, track)
  local track = track or self:get_track()
  self.tracks.info[track].quantization = q
end
function music:get_quantization(track) --> number
  local q = self.tracks.info[track].quantization or 8
  return q
end

function music:get_track_duration(track)
  local track = track or self:get_track()
  local track_duration = self.tracks.info[track].track_duration or 0
  return track_duration
end
function music:set_track_duration(duration, track)
  local track = track or self:get_track()
  local track_duration = self:get_track_duration(track)
  track_duration = track_duration + duration
  self.tracks.info[track].track_duration = track_duration
end

function music:note(note, accident, value, dot)
  local track = self:get_track()
  local duration = 0

  if value then
    duration = 4 / value
  else
    duration = 4 / self:get_length(track)
  end
  duration = duration * (60 / self:get_tempo())
  if dot then duration = duration * 1.5 end

  self:set_track_duration(duration, track)

  self:send({
    note = note,
    accident = accident,
    duration = duration,
    octave = self:get_octave(track),
    volume = self:get_volume(track),
    dcycle = self.tracks.info[track].dcycle,
    envelope = self:get_envelope(track),
    quantization = self:get_quantization(track),
    track = track
  })
end
function music:send(message)
  table.insert(self.tracks.data[message.track], message)
end


-- AUDIO RENDERER

function music:render_audio()
  local song_duration = 0
  local song_voices = 0
  local song_sample_count = 0
  local previous_sound = {}
  
  for track, _ in pairs(self.tracks.info) do
    if song_duration < self:get_track_duration(track) then
      song_duration = self:get_track_duration(track) + 1
    end
    if self:get_track_duration(track) > 0 then
      song_voices = song_voices + 1
    end
  end

  local song_samples = song_duration * self:get_sample_rate()

  self.audio.sound_data = love.sound.newSoundData(song_samples, self:get_sample_rate(), 8, 1)

  local notes = { c = -9, d = -7, e = -5, f = -4, g = -2, a = 0, b = 2, h = 2 }
  
  for key, track in pairs(self.tracks.data) do
    song_sample_count = 0
    previous_sound = {}

    for _, message in ipairs(track) do
        
      local waveform = nil
      local frequency = 0
      local envelope = 0
      local samples = 0
     

      if message.duration > 0 then
        samples = message.duration * self.sample_rate
      end

      if message.note:match("[abcdefgh]") then
        local pitch = notes[message.note]
        
        if message.accident then
          if message.accident == "#" or message.accident == "+" then
            pitch = pitch + 1
          elseif message.accident == "-" then
            pitch = pitch - 1
          end
        end
        
        pitch = pitch + 12 * (message.octave - 4)
        frequency = self.base_frequency * 2 ^ (pitch / 12)
        
      end

      if message.track:match("[AB]") then
        waveform = self:PULSE(self.sample_rate, frequency, message.dcycle)
      elseif message.track == "C" then
        waveform = self:TRIANGLE(self.sample_rate, frequency)
      elseif message.track == "D" then
        waveform = self:SAWTOOTH(self.sample_rate, frequency)
      elseif message.track == "E" then
        waveform = self:NOISE(self.sample_rate, frequency)
      end

      for i = 0, (samples - 1) do

        if message.note:match("[abcdefgh]") then
          sample = waveform(i)

          if not (message.track == "C") then
            if i <= self.envelopes[message.envelope].a then
              envelope = i / (self.envelopes[message.envelope].a - 1)
            elseif i > self.envelopes[message.envelope].a and i <= self.envelopes[message.envelope].d then
              envelope = self.envelopes[message.envelope].s + (1 - self.envelopes[message.envelope].s) * (1 - (i / self.envelopes[message.envelope].d))
            elseif i > self.envelopes[message.envelope].d then
              envelope = self.envelopes[message.envelope].s
            end
          else
            envelope = 1.0
          end
          if i >= samples / 8 * message.quantization then
            sample = 0
          end

        elseif message.note:match("[prw]") then
          if previous_sound.message and previous_sound.message.note:match("[abcdefgh]") then
            sample = previous_sound.waveform(i)
            if i <= self.envelopes[message.envelope].r then
              envelope = self.envelopes[message.envelope].s * (1 - i / self.envelopes[message.envelope].r)
            elseif i > self.envelopes[message.envelope].r then
              sample = 0
            end
          else
            sample = 0
          end
        end

        local modifiers = self.amplitude * message.volume * envelope
        if modifiers > 1.0 then modifiers = 1.0 end  

        -- filter...
        --if previous_sound.sample then
        --  sample = sample + previous_sound.sample
        --end
        
        local combined_sample = math.tanh(self.audio.sound_data:getSample(song_sample_count) + sample * modifiers / song_voices)
        self.audio.sound_data:setSample(song_sample_count, combined_sample)
        song_sample_count = song_sample_count + 1

        previous_sound.sample = sample
      end

      previous_sound = {
        message = message,
        waveform = waveform
      }
    end
  end

  self.audio.source = love.audio.newSource(self.audio.sound_data, "static")
end

-- THE PARSER

function music:parse_mml(mml) --> bool
  local success = true
  math.randomseed(os.time())

  self.mml = mml

  for _, line in pairs(mml) do
    local end_of_line = false

    local i = 1

    repeat
      local cmd = string.match(string.sub(line, i), "^[%a<>&#@/:;%[%]]")
      if cmd then

        if cmd:match(";") then
          -- ; comment
          -- do nothing
          end_of_line = true

        elseif cmd:match("#") and i == 1 then
          -- # keyword
          local keyword, value = string.match(string.sub(line, i), "#(%a+)%s+(.+)")
          value = value:gsub("(;.+)", "")
          end_of_line = true
          self:set_info(keyword, value)
        
        elseif cmd:match("@") then
          -- @ macro
          local name, args = string.match(string.sub(line, i), "@([%w]+)%s-=%s+(.+)")
          
          if name then
            -- macro definition
            name = name:lower()
            if name:match("env%d+") then
              -- envelope macro
              local attack, decay, sustain, release = args:match("(%d+)%D+(%d+)%D+(%d+)%D+(%d+)%D+")
              self:define_envelope(name, attack, decay, sustain, release)
            end
            end_of_line = true

          else
            name = string.match(string.sub(line, i), "@([%w]+)[%s%a<>&#@/:;%[%]]?")
            name = name:lower()

            if name:match("[%d%d]") and tonumber(name) then
              -- @00..03 duty cylce (only pulse wave channels A and B)
              local index = tonumber(name) + 1
              local dcycle = { 0.125, 0.25, 0.5, 0.75 }
              if index > 0 and index <= #dcycle then
                self.tracks.info[self:get_track()].dcycle = dcycle[index]
              end

            elseif name:match("env%d+") then
              -- @env envelopes
              self:set_envelope(name)

            elseif name:match("arp%d+") then
              -- @arp arpeggios
              -- to do

            elseif name:match("vib%d+") then
              -- @vib vibratos
              -- to do

            end
            i = i + name:len() 
            args = ""
          end
        
        elseif cmd:match("%u") then
          -- A..E channel name
          self:set_track(cmd)

        elseif cmd:match("[<>&]") then
          -- <, >, & octave shifts and tie
          if cmd:match("[<>]") then
            self:shift_octave(cmd == "<" and -1 or 1)
          end

        elseif cmd:match("[%[%]]") then
          -- [, ] loop
          -- to do
          if cmd == "[" then
            -- [ begin loop
          elseif cmd == "]" then
            -- ]n end loop, repeat n times, default = 2
            local ntimes =  string.match(string.sub(line, i), ":(%d+)[%D]") or "2"
          end
                
        elseif cmd:match("[abcdefghlopqrtvw]") then
          local args = string.match(string.sub(line, i + 1), "^([%+%-#%d%.]+)[%s<>&#@/:;%[%]]?") or ""
          
          local accident = args:match("[%-%+#]")
          local value = tonumber(args:match("%d+"))
          local dot = args:match("%.")
          
          if cmd:match("[abcdefgh]") then
            -- a..h notes, b can be used instead of h
            self:note(cmd, accident, value, dot)

          elseif cmd == "l" then
            -- l(ength)
            self:set_length(value)

          elseif cmd == "o" then
            -- o(ctave)
            self:set_octave(value)

          elseif cmd:match("[prw]") then
            -- p(ause), r(est)
            -- w(ait) rest without silencing previous note
            self:note(cmd, accident, value, dot)

          elseif cmd == "q" then
            -- q(uantize)
            self:set_quantization(value)

          elseif cmd == "t" then
            -- t(empo)
            self:set_tempo(value)

          elseif cmd == "v" then
            -- v(olume)
            self:set_volume(value)

          end
        end
      end

      i = i + 1
      if i > string.len(line) then end_of_line = true end
    until end_of_line

  end

  self:render_audio()

  return success
end
