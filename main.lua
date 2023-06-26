--[[
                                    ___
       ______    ___    ___   ___  /    \ ___
    _/       \_/    \_/ _  \_/   \_--   /-   \
   /   /  /  /   /  /   /__/  /__/   __/   / /
  /___/__/__/\__/\_/___/   \____/      \____/
  (c) 2020 – 2022 marc2o        \______/
  https://marc2o.github.io

]]

VERSION = "0.5.0"

--[[
  0.5.0
  - simple gui added
  - noise synth bug fix
  
  0.4.0
  - loops implemented
  - bug fixes

  0.3.1
  - simple lowpass filter

  0.3.0
  - basic lfo support implemented
  - @vib macro implemented

  0.2.2
  - corrected song length so that it now loops cleanly

  0.2.1
  - audio volume of channel C (triangle) fine-tuned
  - some changes to the player code

  0.2.0 (09.10.2022)
  - complete rewrite of synthesizer and parser
  - refactored aiff exporter
  - new app screen
]]

require("Modules.NamedColorPalette")
require("Modules.Music")
require("Modules.WriteAiff")
require("Modules.Gui")

Font = nil
Colors = nil
local visualizer = ""
local t_ui = {
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
    text = "",
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
    text = "",
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
    text = "",
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
    text = "",
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

--[[
function export_button.action()
  write_aiff()
end
]]

function write_aiff()
  local content = ""
  local file = aiff:createFile(Music.meta.title .. " by " .. Music.meta.composer)
  aiff:writeFile(file, {
    soundData = Music.audio.sound_data,
    title = Music.meta.title,
    composer = Music.meta.composer
  })
  aiff:closeFile(file)

  local path = {
    macOS   = "~/Library/Application Support/LOVE/Music/",
    Windows = "%appdata%\\LOVE\\Music\\",
    Linux   = "~/.local/share/love/"
  }
  local os = love.system.getOS()
  if os == "OS X" then os = "macOS" end
  local success = love.window.showMessageBox("AIFF-Export", "Saved to " .. path[os], "info", true)
end

----------------------------------
-- LÖVE BASE FUNCTIONS
----------------------------------

function love.update(dt)
  if dt < 1/60 then
    love.timer.sleep(1/60 - dt)
  end

  NEXT_t = NEXT_t + MIN_dt

  ---

  Gui.buttons["play_pause"].is_active = Music:is_ready()
  Gui.buttons["export"].is_active = Music:is_ready()

  if Music:is_playing() then
    local value = Music:get_current_sample()
    visualizer = visualizer .. string.char(math.floor(math.abs(value * 100)))
    if visualizer:len() > 80 then
      visualizer = visualizer:sub(2, 81)
    end
  end
end

function love.draw()
  love.graphics.clear(Colors:get_color("background"))

  if 1 == 1 then
    for i = visualizer:len() - 1, 0, -1 do
      local height = visualizer:sub(i + 1, i + 1):byte()
      local width = (love.graphics.getWidth() - 32) / visualizer:len()

      if height == nil or height == 0 then
        height = 2
      end

      if i == 0 then
        love.graphics.setColor(Colors:get_color("cursor"))
      else
        love.graphics.setColor(1, 1, 1, 0.1)
      end

      love.graphics.rectangle("fill", 16 + i * width, 250 - height, 5, height * 2)
    end
  end

  for _, element in pairs(t_ui) do
    love.graphics.setColor(Colors:get_color(element.color))
    love.graphics.print(element.text, element.x, element.y)
  end

  Gui:draw_buttons()

  ---

  local current_time = love.timer.getTime()
  if NEXT_t <= current_time then
    NEXT_t = current_time
    return
  end
  love.timer.sleep(NEXT_t - current_time)
end

function love.load()
  --print("v"..VERSION)

  Font = love.graphics.newFont("Assets/FiraCode-Medium.ttf", 16)
  love.graphics.setFont(Font)
  -- see Assets/FiraCode-LICENSE.txt for more info
  -- https://github.com/tonsky/FiraCode
  love.window.setMode(
    800,
    400,
    {
      fullscreen = false,
      vsync = true,
      resizable = false,
      centered = true
    }
  )
  love.window.setTitle("Music v" .. VERSION)
  Colors = NamedColorPalette:new()
  Colors:create(require("Assets.colors"))

  Gui:init()

  Gui:add_button(
    "play_pause",
    "Play/Pause",
    Font:getHeight(),
    love.graphics.getHeight() - 3 * Font:getHeight(),
    true
  )
  Gui:add_button_toggle_actions("play_pause", function () Music:play() end, function () Music:pause() end)
  Gui:add_hotkey("play_pause","tab")

  Gui:add_button(
    "export",
    "Export AIFF",
    Gui.buttons["play_pause"].rect.x + Gui.buttons["play_pause"].rect.w + Font:getHeight(),
    love.graphics.getHeight() - 3 * Font:getHeight(),
    false
  )
  Gui:add_button_action("export", function () write_aiff() end)

  Gui:add_button(
    "quit",
    "Quit",
    Gui.buttons["export"].rect.x + Gui.buttons["export"].rect.w + 2 * Font:getHeight(),
    love.graphics.getHeight() - 3 * Font:getHeight(),
    false
  )
  Gui:add_button_action("quit", function () love.event.quit() end)
  Gui:add_hotkey("quit", "escape")


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

    Music:init()

    local success = Music:parse_mml(content)
    if success then
      t_ui.title_text.text = Music.meta.title
      t_ui.composer_text.text = Music.meta.composer
      t_ui.programmer_text.text = Music.meta.programmer
      t_ui.copyright_text.text = Music.meta.copyright

      local used_voices = Music:get_used_voices()
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

