--[[
  (c) 2021 marc2o
--]]

require("modules.synth")

__LOG = {}
__LOG.msg = ""
function __LOG.add(msg)
  local msg = msg or ""
  if __LOG.msg ~= "" then
    __LOG.msg = __LOG.msg .. ", " .. msg
  else
    __LOG.msg = msg
  end
end
function __LOG.clr()
  __LOG.msg = ""
end

prettyTime = ""
time = 0
startTime = love.timer.getTime()
function love.update(dt)
  if dt < 1/50 then
    love.timer.sleep(1/50 - dt)
  end

  if love.keyboard.isDown("escape") then
    love.event.quit()
  end

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
end

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

function love.draw()
  love.graphics.clear(0.1, 0.1, 0.1)
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
end

function love.quit()
end

function love.load()
  synth.playSequence("assets/music.mml")
end

function love.run()
  if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

  -- We don't want the first frame's dt to include time taken by love.load.
  if love.timer then love.timer.step() end

  local dt = 0

  -- Main loop time.
  return function()
    -- Process events.
    if love.event then
      love.event.pump()
      for name, a,b,c,d,e,f in love.event.poll() do
        if name == "quit" then
          if not love.quit or not love.quit() then
            return a or 0
          end
        end
        love.handlers[name](a,b,c,d,e,f)
      end
    end

    -- Update dt, as we'll be passing it to update
    if love.timer then dt = love.timer.step() end

    -- Call update and draw
    if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

    if love.graphics and love.graphics.isActive() then
      love.graphics.origin()
      -- don't need the following, since we're filling the whole screen
      --love.graphics.clear(love.graphics.getBackgroundColor())

      if love.draw then love.draw() end

      love.graphics.present()
    end

    if love.timer then love.timer.sleep(0.001) end
  end
end