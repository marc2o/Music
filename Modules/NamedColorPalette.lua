--[[
                                    ___
       ______    ___    ___   ___  /    \ ___
    _/       \_/    \_/ _  \_/   \_--   /-   \
   /   /  /  /   /  /   /__/  /__/   __/   / /
  /___/__/__/\__/\_/___/   \____/      \____/
  (c) 2020 – 2022 marc2o        \______/
  https://marc2o.github.io

]]

NamedColorPalette = {
  colors = {}
}

function NamedColorPalette:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

--- use list with hex strings such as "#ff0099"
function NamedColorPalette:create(list)
  for key, value in pairs(list) do
    self.colors[key] = {
      tonumber('0x' .. value:sub(2, 3)) / 255,
      tonumber('0x' .. value:sub(4, 5)) / 255,
      tonumber('0x' .. value:sub(6, 7)) / 255
    }
  end
end

---returns a color in a format suitable for love.graphics.setColor()
function NamedColorPalette:get_color(name)
  return {
    self.colors[name][1],
    self.colors[name][2],
    self.colors[name][3],
  }
end

--- retrieve number of colors in palette
function NamedColorPalette:get_number_of_colors()
  return #self.colors
end
