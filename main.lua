--[[
  (c) 2021 marc2o
--]]

require("modules.synth")

prettyTime = ""
time = 0
startTime = 0

lines = {
  width = love.graphics.getWidth(),
  height = love.graphics.getHeight(),
  number = 16,
  delay = 60,
  timer = 60,
  limit = 0,
  speed = 240,
  counter = 240,
  side = 1,
  sides = { "top", "right", "bottom", "left" },
  getSide = function (n)
    if n > #lines.sides then n = #lines.sides - n end
    if n < 1 then n = #lines.sides + n end
    return lines.sides[n]
  end,
  draw = function (side, mode)
    side = lines.getSide(side)
    for i = 1, lines.number do
      if mode == "draw" then
        if i <= lines.limit then
          love.graphics.setColor(0.8, 0.8, 0.8)
        else
          love.graphics.setColor(0.1, 0.1, 0.1)
        end
      else
        if i <= lines.limit then
          love.graphics.setColor(0.2, 0.2, 0.2)
        else
          love.graphics.setColor(0.6, 0.6, 0.6)
        end
      end
      local x1, y1, x2, y2
      if side == "top" then
        x1 = 1 + (i - 1) * lines.width / lines.number
        y1 = 1
        x2 = lines.width
        y2 = 1 + (i - 1) * lines.height / lines.number
      elseif side == "right" then
        x1 = lines.width
        y1 = 1 + (i - 1) * lines.height / lines.number
        x2 = lines.width - (i - 1) * lines.width / lines.number
        y2 = lines.height
      elseif side == "bottom" then
        x1 = lines.width - (i - 1) * lines.width / lines.number
        y1 = lines.height
        x2 = 1
        y2 = lines.height - (i - 1) * lines.height / lines.number
      elseif side == "left" then
        x1 = 1
        y1 = lines.height - (i - 1) * lines.height / lines.number
        x2 = 1 + (i - 1) * lines.width / lines.number
        y2 = 1
      end
      love.graphics.line(x1, y1, x2, y2)
      if mode == "draw" then lines.timer = lines.timer - 1 end
      if lines.timer < 1 then
        lines.timer = lines.delay
        if lines.limit < lines.number then lines.limit = lines.limit + 1 end
      end
    end
  end
}

totalSamples = 0
currentSample = 0
timeElapsed = 0


Mode = {
  playing = {},
  finished = {}
}
function Mode.set(mode)
  local mode = mode or "loading"
  u, d = Mode[mode].update, Mode[mode].draw
end

function Mode.playing.update(dt)
  time = love.timer.getTime() - startTime
  local minutes = math.floor(time / 60)
  local seconds = time - minutes * 60
  if seconds < 10 then
    seconds = "0" .. string.format("%.2f", seconds)
  else
    seconds = string.format("%.2f", seconds)
  end
  if minutes < 10 then minutes = "0" .. minutes end
  prettyTime =  minutes .. ":" .. seconds
  --time = string.format("%.2f", love.timer.getTime() - startTime)

  if not synth.isPlaying() then
    Mode.set("finished")
  end
end

function Mode.playing.draw()
  love.graphics.setColor(0.8, 0.8, 0.8)

  love.graphics.print(
    "playing…\n" .. prettyTime .. "\n\npress [ESC] to quit",
    love.graphics.getWidth() / 4,
    love.graphics.getHeight() / 2 - 12
  )

  lines.draw(lines.side - 1, "erase")
  lines.draw(lines.side, "draw")

  lines.counter = lines.counter - 1
  if lines.counter < 1 then
    lines.counter = lines.speed
    lines.limit = 0
    lines.side = lines.side + 1
    if lines.side > #lines.sides then
      lines.side = 1
    end
  end

  if timeElapsed <= 0 then
    currentSample = math.floor(time * synth.sampleRate)
    timeElapsed = 5
  end
  timeElapsed = timeElapsed - 1
  for i = 0, love.graphics.getWidth(), 4 do
    local sample = 0
    if currentSample + i + 20 < totalSamples then
      for s = i, i + 20 do
        sample = sample + math.abs(synth.audioData:getSample(currentSample + s))
      end
      sample = sample / 20
    end
    love.graphics.setColor(0.8, 0.8, 0.8, 0.15)
    love.graphics.rectangle(
      "fill",
      i,
      love.graphics.getHeight() - love.graphics.getHeight() / 3,
      2,
      -sample * love.graphics.getHeight() / 2
    )
    love.graphics.setColor(0.8, 0.8, 0.8, 0.05)
    love.graphics.rectangle(
      "fill",
      i,
      love.graphics.getHeight() - love.graphics.getHeight() / 3 + 2,
      2,
      (sample * love.graphics.getHeight() / 3) + 2
    )
  end
end

function Mode.finished.update(dt)
end

function Mode.finished.draw()
  love.graphics.setColor(0.8, 0.8, 0.8)

  love.graphics.print(
    "finished.\n" .. prettyTime .. "\n\npress [ESC] to quit",
    love.graphics.getWidth() / 4,
    love.graphics.getHeight() / 2 - 12
  )
end

function love.update(dt)
  if dt < 1/50 then
    love.timer.sleep(1/50 - dt)
  end

  if love.keyboard.isDown("escape") then
    love.event.quit()
  end

  u(dt)
end

function love.draw()
  love.graphics.clear(0.1, 0.1, 0.1)
  
  d()
end

function love.quit()
end

function love.load()
  synth.load("assets/test.mml")
  synth.play()
  Mode.set("playing")
  startTime = love.timer.getTime()
  totalSamples = synth.audioData:getSampleCount()
end
