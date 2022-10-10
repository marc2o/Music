--[[
                                    ___
       ______    ___    ___   ___  /    \ ___
    _/       \_/    \_/ _  \_/   \_--   /-   \
   /   /  /  /   /  /   /__/  /__/   __/   / /
  /___/__/__/\__/\_/___/   \____/      \____/
  (c) 2020 – 2022 marc2o        \______/
  https://marc2o.github.io

--]]

VERSION = "0.2.0"

require("Modules.NamedColorPalette")
require("Modules.Music")
require("Modules.WriteAiff")

local visualizer = ""
local font = nil
local t_ui = {
  keycode_esc = {
    color = "text_empty",
    text = "[Esc] Quit  [Tab] Play/Pause  [F1] Export AIFF",
    x = 16,
    y = 400 - 40
  },
  song_title = {
    color = "text_title",
    text = "SONG INFO",
    x = 16,
    y = 16
  },
  title_label = {
    color = "text_info",
    text = "title:",
    x = 16,
    y = 40
  },
  title_text = {
    color = "text_default",
    text = "Untitled",
    x = 144,
    y = 40
  },
  composer_label = {
    color = "text_info",
    text = "composer:",
    x = 16,
    y = 64
  },
  composer_text = {
    color = "text_default",
    text = "John Doe",
    x = 144,
    y = 64
  },
  programmer_label = {
    color = "text_info",
    text = "programmer:",
    x = 16,
    y = 88
  },
  programmer_text = {
    color = "text_default",
    text = "John Doe",
    x = 144,
    y = 88
  },
  copyright_label = {
    color = "text_info",
    text = "copyright:",
    x = 16,
    y = 112
  },
  copyright_text = {
    color = "text_default",
    text = "John Doe",
    x = 144,
    y = 112
  },
  voices_label = {
    color = "text_info",
    text = "voices:",
    x = 16,
    y = 136
  },
  voice_A_text = {
    color = "text_empty",
    text = "A",
    x = 144,
    y = 136
  },
  voice_B_text = {
    color = "text_empty",
    text = "B",
    x = 160,
    y = 136
  },
  voice_C_text = {
    color = "text_empty",
    text = "C",
    x = 176,
    y = 136
  },
  voice_D_text = {
    color = "text_empty",
    text = "D",
    x = 192,
    y = 136
  },
  voice_E_text = {
    color = "text_empty",
    text = "E",
    x = 208,
    y = 136
  },
}

----------------------------------
-- LÖVE BASE FUNCTIONS
----------------------------------

function love.update(dt)
  if dt < 1/60 then
    love.timer.sleep(1/60 - dt)
  end
  
  NEXT_t = NEXT_t + MIN_dt

  ---

  if music:is_playing() then
    local value = music:get_current_sample()
    visualizer = visualizer .. string.char(math.floor(math.abs(value * 100)))
    if visualizer:len() > 80 then
      visualizer = visualizer:sub(2, 81)
    end
  end
end

function love.draw()
  love.graphics.clear(colors:get_color("background"))

  if music:is_playing() then
    for i = 0, visualizer:len() - 1 do
      local height = visualizer:sub(i, i):byte()
      local width = love.graphics.getWidth() / visualizer:len()
      if height == nil then height = 0 end
      if i == math.floor(visualizer:len() / 2) then
        love.graphics.setColor(colors:get_color("cursor"))
      elseif i == math.floor(visualizer:len() / 2) - 1 or i == math.floor(visualizer:len() / 2) + 1 then
        love.graphics.setColor(colors:get_color("text_info"))
      else
        love.graphics.setColor(1, 1, 1, 0.125)
      end
      love.graphics.rectangle("fill", i * width, 250 - height, 8, height * 2)
    end
  end

  for _, element in pairs(t_ui) do
    love.graphics.setColor(colors:get_color(element.color))
    love.graphics.print(element.text, element.x, element.y)
  end

  ---

  local current_time = love.timer.getTime()
  if NEXT_t <= current_time then
    NEXT_t = current_time
    return
  end
  love.timer.sleep(NEXT_t - current_time)
end

function love.load()
  font = love.graphics.newFont("Assets/FiraCode-Medium.ttf", 16)
  love.graphics.setFont(font)
  -- see Assets/FiraCode-LICENSE.txt for more info
  -- https://github.com/tonsky/FiraCode
  love.window.setMode(
    800,
    400,
    {
      fullscreen = false,
      vsync = 1,
      resizable = false,
      centered = true
    }
  )
  love.window.setTitle("Music v" .. VERSION)
  colors = NamedColorPalette:new()
  colors:create(require("Assets.colors")) 

  ---

  MIN_dt = 1/60
  NEXT_t = love.timer.getTime()
end

function love.quit()
end

function love.filedropped(file)
  if file then
    file:open("r")
    --file_content = file:read()
    local content = {}

    for line in file:lines() do
      if string.len(line) > 0 then table.insert(content, line) end
    end
    
    file:close()

    music:init()

    local success = music:parse_mml(content)
    if success then
      t_ui.title_text.text = music.meta.title
      t_ui.composer_text.text = music.meta.composer
      t_ui.programmer_text.text = music.meta.programmer
      t_ui.copyright_text.text = music.meta.copyright

      local used_voices = music:get_used_voices()
      for voice, used in pairs(used_voices) do
        if used then
          t_ui["voice_" .. voice .. "_text"].color = "text_value"
        else
          t_ui["voice_" .. voice .. "_text"].color = "text_empty"
        end
      end
    end
  else
    local error = love.window.showMessageBox("Error", "Unable to open file", "info", true)
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit()
    
  elseif key == "tab" then
    music:pause()
    
  elseif key == "f1" and music.audio.sound_data then
    -- export AIFF
    local content = ""
    local file = aiff:createFile(music.meta.title .. " by " .. music.meta.composer)
    aiff:writeFile(file, {
      soundData = music.audio.sound_data,
      title = music.meta.title,
      composer = music.meta.composer
    })
    aiff:closeFile(file)

    local path = {
      macOS = "~/Library/Application Support/LOVE/Music/",
      Windows = "%appdata%\\LOVE\\Music\\",
      Linux = "~/.local/share/love/"
    }
    local os = love.system.getOS()
    if os == "OS X" then os = "macOS" end
    success = love.window.showMessageBox("AIFF-Export", "Saved to " .. path[os], "info", true)
    
  elseif key == "return" then
    -- enter
  else
    -- ...
  end
end
