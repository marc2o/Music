--[[
                                    ___
       ______    ___    ___   ___  /    \ ___
    _/       \_/    \_/ _  \_/   \_--   /-   \
   /   /  /  /   /  /   /__/  /__/   __/   / /
  /___/__/__/\__/\_/___/   \____/      \____/
  (c) 2020 – 2022 marc2o        \______/
  https://marc2o.github.io

]]

gui = {
  buttons = {},
  mouse = {
    x = 0,
    y = 0,
    dx = 0,
    dy = 0,
    button = 0,
    touch = false,
  }
}

function gui:draw_buttons()
  for _, button in pairs(self.buttons) do
    if button.is_toggle and button.toggled then
      love.graphics.setColor(colors:get_color("text_info"))
      love.graphics.rectangle("fill", button.rect.x, button.rect.y, button.rect.w, button.rect.h);    
    elseif button.clicked then
      love.graphics.setColor(colors:get_color("text_empty"))
      love.graphics.rectangle("fill", button.rect.x, button.rect.y, button.rect.w, button.rect.h);
    end
    if button.is_active then 
      love.graphics.setColor(colors:get_color("text_value"))
    else
      love.graphics.setColor(colors:get_color("text_empty"))
    end
    love.graphics.rectangle("line", button.rect.x, button.rect.y, button.rect.w, button.rect.h);
    love.graphics.print(button.label.text, button.label.x, button.label.y)
  end
end

function gui:check_buttons()
  for _, button in pairs(self.buttons) do
    local mx = self.mouse.x
    local my = self.mouse.y
    button.clicked = false
    button.toggle = false
    if button.is_active and mx > button.rect.x and mx < button.rect.x + button.rect.w and my > button.rect.y and my < button.rect.y + button.rect.h then
      if self.mouse.button == 1 and not button.clicked then      
        button.clicked = true
      else 
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
    end
  end
end

function gui:add_button_action(id, action)
  self.buttons[id].action = action
end

function gui:add_button_toggle_actions(id, action_on, action_off)
  self.buttons[id].action_on = action_on
  self.buttons[id].action_off = action_off
end

function gui:add_hotkey(id, hotkey)
  self.buttons[id].hotkey = hotkey
end

function gui:add_button(id, label, x, y, is_toggle)
  local button = {}
  local width = font:getWidth(label)
  local height = font:getHeight()
  width = width + 2 * height
  height = 2 * height

  button.is_toggle = is_toggle or false
  button.is_active = true
  button.label = {}
  button.label.text = label
  button.label.x = x + font:getHeight()
  button.label.y = y + font:getHeight() / 2
  button.rect = {}
  button.rect.x = x
  button.rect.y = y
  button.rect.w = width
  button.rect.h = height
  button.hotkey = ""

  self.buttons[id] = button
end

function love.mousemoved(x, y, dx, dy, istouch)
  gui.mouse.x = x
  gui.mouse.y = y
end

function love.mousepressed(x, y, button, istouch)
  if button == 1 then
    gui.mouse.x = x
    gui.mouse.y = y
    gui.mouse.button = button
    gui:check_buttons()
  end
end

function love.mousereleased(x, y, button, istouch)
  if button == 1 then
    gui.mouse.x = x
    gui.mouse.y = y
    gui.mouse.button = 0
    gui:check_buttons()
  end  
end

