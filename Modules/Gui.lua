--[[
                                    ___
       ______    ___    ___   ___  /    \ ___
    _/       \_/    \_/ _  \_/   \_--   /-   \
   /   /  /  /   /  /   /__/  /__/   __/   / /
  /___/__/__/\__/\_/___/   \____/      \____/
  (c) 2020 – 2022 marc2o        \______/
  https://marc2o.github.io

]]

Gui = {
  buttons = {},
  mouse = {
    x = 0,
    y = 0,
    dx = 0,
    dy = 0,
    button = 0,
    touch = false,
  },
  cursors = {
    arrow = nil,
    hand = nil,
    wait = nil
  },
}

function Gui:init()
  self.cursors.arrow = love.mouse.getSystemCursor("arrow")
  self.cursors.hand  = love.mouse.getSystemCursor("hand")
  self.cursors.wait  = love.mouse.getSystemCursor("wait")
end

function Gui:draw_buttons()
  for _, button in pairs(self.buttons) do
    if button.is_toggle and button.toggled then
      love.graphics.setColor(Colors:get_color("text_info"))
      love.graphics.rectangle("fill", button.rect.x, button.rect.y, button.rect.w, button.rect.h);    
    elseif button.clicked then
      love.graphics.setColor(Colors:get_color("text_empty"))
      love.graphics.rectangle("fill", button.rect.x, button.rect.y, button.rect.w, button.rect.h);
    end
    if button.is_active then 
      love.graphics.setColor(Colors:get_color("text_value"))
    else
      love.graphics.setColor(Colors:get_color("text_empty"))
    end
    love.graphics.rectangle("line", button.rect.x, button.rect.y, button.rect.w, button.rect.h);
    love.graphics.print(button.label.text, button.label.x, button.label.y)
  end
end

function Gui:execute_action(button)
  if button.is_toggle then
    if not button.toggled then 
      button.toggled = true
      button.action_on()
    else
      button.toggled = false
      button.action_off()            
    end
  else
    button.action()
  end
end

function Gui:check_hotkeys(key)
  for _, button in pairs(self.buttons) do
    if button.hotkey ~= "" then
      if button.is_active and button.hotkey == key then
        self:execute_action(button)
      end
    end
  end
end

function Gui:check_buttons()
  for _, button in pairs(self.buttons) do
    local mx = self.mouse.x
    local my = self.mouse.y
    button.clicked = false
    button.toggle = false
    if button.is_active and mx > button.rect.x and mx < button.rect.x + button.rect.w and my > button.rect.y and my < button.rect.y + button.rect.h then
      if self.mouse.button == 1 and not button.clicked then      
        button.clicked = true
      else 
        self:execute_action(button)
      end
    end
  end
end

function Gui:hover()
  local mx = self.mouse.x
  local my = self.mouse.y
  local bcount = 0
  for _, button in pairs(self.buttons) do
    if button.is_active and mx > button.rect.x and mx < button.rect.x + button.rect.w and my > button.rect.y and my < button.rect.y + button.rect.h then
      bcount = bcount + 1
    end
  end
  if bcount > 0 then
    love.mouse.setCursor(self.cursors.hand)
  else
    love.mouse.setCursor(self.cursors.arrow)
  end
end

function Gui:add_button_action(id, action)
  self.buttons[id].action = action
end

function Gui:add_button_toggle_actions(id, action_on, action_off)
  self.buttons[id].action_on = action_on
  self.buttons[id].action_off = action_off
end

function Gui:add_hotkey(id, hotkey)
  self.buttons[id].hotkey = hotkey
end

function Gui:add_button(id, label, x, y, is_toggle)
  local button = {}
  local width = Font:getWidth(label)
  local height = Font:getHeight()
  width = width + 2 * height
  height = 2 * height

  button.is_toggle = is_toggle or false
  button.is_active = true
  button.label = {}
  button.label.text = label
  button.label.x = x + Font:getHeight()
  button.label.y = y + Font:getHeight() / 2
  button.rect = {}
  button.rect.x = x
  button.rect.y = y
  button.rect.w = width
  button.rect.h = height
  button.hotkey = ""

  self.buttons[id] = button
end

function love.mousemoved(x, y, dx, dy, istouch)
  Gui.mouse.x = x
  Gui.mouse.y = y
  Gui:hover()
end

function love.mousepressed(x, y, button, istouch)
  if button == 1 then
    Gui.mouse.x = x
    Gui.mouse.y = y
    Gui.mouse.button = button
    Gui:check_buttons()
  end
end

function love.mousereleased(x, y, button, istouch)
  if button == 1 then
    Gui.mouse.x = x
    Gui.mouse.y = y
    Gui.mouse.button = 0
    Gui:check_buttons()
  end  
end

function love.keypressed(key, scancode, isrepeat)
  Gui:check_hotkeys(key)
end

