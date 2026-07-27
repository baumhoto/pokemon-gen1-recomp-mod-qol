package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Runtime = require("src.mods.Runtime")
local Screens = require("src.ui.Screens")
local Data = require("src.core.Data")
Data:load()

local Font = require("src.render.Font")
Font.load(Data)

local function read(path)
  local file = assert(io.open(path, "rb"))
  local source = file:read("*a")
  file:close()
  return source
end

local modFiles = {
  ["mods/qol_later_gen/manifest.json"] =
    read("mods/qol_later_gen/manifest.json"),
  ["mods/qol_later_gen/main.lua"] = read("mods/qol_later_gen/main.lua"),
  ["mods/qol_later_gen/transforms.lua"] =
    read("mods/qol_later_gen/transforms.lua"),
}
local run = T.sdk.loadMod("mods/qol_later_gen",
  { data = Data, fs = T.sdk.memfs(modFiles) })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")
local exports = run.loader.exports.qol_later_gen
T.check(exports and exports.screenId == "QolLaterGenMenu",
  "exports the submenu screen id")

local loadChunk = loadstring or load
local transform = assert(loadChunk(modFiles[
  "mods/qol_later_gen/transforms.lua"]))()
local transformCalls = {}
transform({
  exists = function(path) return path == "battle/balls.png" end,
  readImage = function(path) transformCalls.read = path return {} end,
  blank = function(w, h) transformCalls.blank = { w, h } return {} end,
  blit = function(_, _, dx, dy, sx, sy, w, h)
    transformCalls.blit = { dx, dy, sx, sy, w, h }
  end,
  writeImage = function(_, path) transformCalls.write = path end,
})
T.eq(transformCalls.read, "battle/balls.png", "transform reads the ball sheet")
T.check(transformCalls.blank[1] == 8 and transformCalls.blank[2] == 8
        and transformCalls.blit[5] == 8 and transformCalls.blit[6] == 8,
  "transform crops the first 8x8 ball tile")
T.eq(transformCalls.write, "ui/ball.png", "transform writes only derived art")

local function stack()
  local s = { states = {} }
  function s:push(state) self.states[#self.states + 1] = state end
  function s:pop() return table.remove(self.states) end
  function s:top() return self.states[#self.states] end
  return s
end

local input = { pressed = {} }
function input:wasPressed(key) return self.pressed[key] or false end

local writes = 0
local game = {
  data = Data,
  input = input,
  stack = stack(),
  mods = run.loader,
  save = {
    options = { modOptions = {} },
    pokedex = { seen = { RATTATA = true }, owned = { RATTATA = true } },
  },
}
function game:writeOptions() writes = writes + 1 end

local vanilla = { { id = "speed", label = "GAME SPEED" },
                  { id = "mods", label = "MODS" } }
local rows = Runtime.call("ui.options.rows",
  function(_, source) return source end, game, vanilla)
T.eq(#rows, 3, "adds exactly one options row")
T.eq(rows[2].label, "QUALITY OF LIFE", "anchors the row before MODS")
T.eq(rows[3].label, "MODS", "preserves the base options row")
rows[2].activate(game)
local menu = game.stack:top()
T.check(menu and menu.screenId == exports.screenId, "opens the custom submenu")
T.eq(menu.rows[1].value(game), "OFF", "EXP bar defaults off")
T.eq(menu.rows[2].value(game), "OFF", "indicator defaults off")

input.pressed = { right = true }
menu:update(0)
input.pressed = {}
T.eq(game.save.options.modOptions.qol_later_gen.battle_exp_bar, "black",
  "right cycles the EXP bar to black")
T.eq(menu.rows[1].value(game), "ON (BLACK)", "submenu refreshes the EXP label")
menu.index = 2
input.pressed = { left = true }
menu:update(0)
input.pressed = {}
T.eq(game.save.options.modOptions.qol_later_gen.pokedex_indicator, "red",
  "left wraps the indicator from off to red")
T.eq(menu.rows[2].value(game), "ON (RED)", "submenu refreshes the indicator label")
T.eq(writes, 2, "submenu changes persist immediately")

input.pressed = { a = true }
menu:update(0)
input.pressed = {}
local description = game.stack:top()
T.check(description ~= menu and description.pages,
  "A opens the selected setting description")
T.check(#description.pages == 2 and #description.pages[1] == 2,
  "setting descriptions pause after the first two lines")
game.stack:pop()

input.pressed = { b = true }
menu:update(0)
input.pressed = {}
T.eq(game.stack:top(), nil, "B closes the shared options screen")

local ManagerState = require("src.mods.ManagerState")
ManagerState.openOptions({ game = game }, { id = "qol_later_gen" })
local managerMenu = game.stack:top()
T.check(managerMenu and managerMenu.screenId == exports.screenId,
  "Mod Manager opens the same options screen")
game.stack:pop()

local playerDef = Data.pokemon.BULBASAUR
local level = 20
local current = require("src.pokemon.Growth").expForLevel(playerDef.growthRate, level)
local nextLevel = require("src.pokemon.Growth").expForLevel(playerDef.growthRate, level + 1)
local playerMon = {
  species = "BULBASAUR", level = level,
  exp = math.floor((current + nextLevel) / 2),
}
local baseDraws = 0
local battle = {
  game = game,
  data = Data,
  kind = "wild",
  frame = 0,
  player = { mon = playerMon },
  enemy = { mon = { species = "RATTATA" }, fainted = false },
  draw = function() baseDraws = baseDraws + 1 end,
  growInScale = function() return nil end,
}

local oldDraw, oldRectangle = love.graphics.draw, love.graphics.rectangle
local ball, bar
love.graphics.draw = function(_, _, x, y)
  local r, g, b = love.graphics.getColor()
  ball = { x = x, y = y, color = { r, g, b } }
end
love.graphics.rectangle = function(mode, x, y, w, h)
  local r, g, b = love.graphics.getColor()
  bar = { mode = mode, x = x, y = y, w = w, h = h, color = { r, g, b } }
end

Runtime.emit("battle.started", {
  battle = battle, kind = "wild", species = "RATTATA", level = 5,
})
battle.fx = { shakeX = 2, shakeY = 3 }
battle:draw()
T.eq(baseDraws, 1, "wrapped draw calls the base renderer once")
T.check(bar and bar.y == 92 and bar.h == 2,
  "enabled EXP bar follows screen shake")
T.eq(bar.x, 80 + 67 - exports.expPixels(battle) + 2,
  "EXP bar fills right-to-left")
T.check(bar.color[1] == 0 and bar.color[2] == 0 and bar.color[3] == 0,
  "black EXP mode draws black")
T.check(ball and ball.x == 9 and ball.y == 10,
  "caught indicator follows screen shake")
T.check(ball.color[1] == 1 and ball.color[2] == 0 and ball.color[3] == 0,
  "red indicator mode draws red")

game.save.options.modOptions.qol_later_gen.battle_exp_bar = "blue"
game.save.options.modOptions.qol_later_gen.pokedex_indicator = "gray"
battle.fx, bar, ball = nil, nil, nil
battle:draw()
T.check(bar.color[1] == 56 / 255 and bar.color[2] == 144 / 255
        and bar.color[3] == 240 / 255, "blue EXP mode draws blue")
T.check(ball.color[1] == 1 and ball.color[2] == 1 and ball.color[3] == 1,
  "greyscale indicator applies no tint")

game.save.options.modOptions.qol_later_gen.battle_exp_bar = "off"
game.save.options.modOptions.qol_later_gen.pokedex_indicator = "off"
bar, ball = nil, nil
battle:draw()
T.eq(baseDraws, 3, "disabled overlays still call the base renderer")
T.check(bar == nil and ball == nil, "disabled options draw no overlays")

love.graphics.draw, love.graphics.rectangle = oldDraw, oldRectangle
love.graphics.setColor(1, 1, 1, 1)
run.release()
Screens.invalidate()
T.finish("qol later gen")
