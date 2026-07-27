local SCREEN_ID = "QolLaterGenMenu"
local DERIVED_BALL = "save/mod-derived/quality_of_life/ui/ball.png"

local EXP_X, EXP_Y, EXP_WIDTH = 80, 89, 67
local EXP_BLUE = { 56 / 255, 144 / 255, 240 / 255, 1 }
local EXP_BLACK = { 0, 0, 0, 1 }

local MODES = {
  qol_exp_bar = {
    { id = "off", label = "OFF" },
    { id = "black", label = "ON (BLACK)" },
    { id = "blue", label = "ON (BLUE)" },
  },
  qol_caught_indicator = {
    { id = "off", label = "OFF" },
    { id = "grey", label = "ON (GREY)" },
    { id = "red", label = "ON (RED)" },
  },
}

return function(mod)
  local Growth = require("src.pokemon.Growth")
  local PaletteFX = require("src.render.PaletteFX")

  mod.options:define({
    { key = "qol_exp_bar", label = "BATTLE EXP BAR", type = "choice",
      default = "off", choices = {
        { "OFF", "off" }, { "ON (BLACK)", "black" },
        { "ON (BLUE)", "blue" },
      } },
    { key = "qol_caught_indicator", label = "POKéDEX INDICATOR", type = "choice",
      default = "off", choices = {
        { "OFF", "off" }, { "ON (GREY)", "grey" },
        { "ON (RED)", "red" },
      } },
  })

  local function optionValue(game, key)
    local options = game and game.save and game.save.options
    local bucket = options and options.modOptions
                   and options.modOptions[mod.id]
    if bucket and bucket[key] ~= nil then return bucket[key] end
    return mod.options:get(key)
  end

  local function setOption(game, key, value)
    local options = game.save.options
    options.modOptions = options.modOptions or {}
    options.modOptions[mod.id] = options.modOptions[mod.id] or {}
    options.modOptions[mod.id][key] = value

    -- Keep mod.options:get synchronized until options.lua is reloaded.
    if game.mods then
      game.mods.modOptions = game.mods.modOptions or {}
      game.mods.modOptions[mod.id] = game.mods.modOptions[mod.id] or {}
      game.mods.modOptions[mod.id][key] = value
    end
    if game.writeOptions then game:writeOptions() end
  end

  local function modeIndex(game, key)
    local value = optionValue(game, key)
    for i, mode in ipairs(MODES[key]) do
      if mode.id == value then return i end
    end
    return 1
  end

  local function stepMode(game, key, dir)
    local modes = MODES[key]
    local i = (modeIndex(game, key) - 1 + dir) % #modes + 1
    setOption(game, key, modes[i].id)
  end

  local function makeScreen(game)
    local OptionRows = require("src.ui.OptionRows")
    local rows = {
      {
        label = "EXPERIENCE BAR",
        key = "qol_exp_bar",
        description = "SHOWS EXP PROGRESS\nTOWARD THE NEXT\f"
          .. "LEVEL IN BATTLE.",
      },
      {
        label = "POKéDEX INDICATOR",
        key = "qol_caught_indicator",
        --description = "ADDS AN INDICATOR\nFOR ALREADY CAUGHT\f"
        --  .. "WILD POKéMON.",
        description = "ADDS A POKéBALL\nICON FOR ALREADY\f"
          .. "CAUGHT POKéMON\nDURING WILD\f"
          .. "ENCOUNTERS.",
      },
    }
    for _, row in ipairs(rows) do
      local key = row.key
      row.value = function(g)
        return MODES[key][modeIndex(g, key)].label
      end
    end

    local screen = {
      game = game,
      rows = rows,
      index = 1,
      scroll = 0,
      isOpaque = true,
    }

    function screen:sgbPalettes(g)
      return require("src.render.PaletteFX").wholeNamed(g.data, "MEWMON")
    end

    function screen:update()
      local input = self.game.input
      if input:wasPressed("up") then
        self.index = (self.index - 2) % #self.rows + 1
      elseif input:wasPressed("down") then
        self.index = self.index % #self.rows + 1
      elseif input:wasPressed("left") or input:wasPressed("right") then
        local dir = input:wasPressed("left") and -1 or 1
        stepMode(self.game, self.rows[self.index].key, dir)
      elseif input:wasPressed("a") then
        self.game.stack:push(mod.ui.TextBox.new(
          self.game, self.rows[self.index].description))
      elseif input:wasPressed("b") then
        self.game.stack:pop()
      end
      self.scroll = OptionRows.clampScroll(
        self.index, self.scroll, #self.rows, nil)
    end

    function screen:draw()
      OptionRows.draw(self.game, self.rows, self.index, self.scroll,
                      "A:INFO B:DONE")
    end

    return screen
  end

  mod.content.screens:register(SCREEN_ID, { new = makeScreen })

  -- The manager's schema screen cannot assign a custom A action to choices.
  -- Route only this mod to the same registered screen after loading succeeds.
  mod.events:once("mods.loaded", function()
    local ManagerState = require("src.mods.ManagerState")
    local routes = rawget(ManagerState, "__modOptionScreenRoutes")
    if not routes then
      routes = {}
      local openOptions = ManagerState.openOptions
      ManagerState.openOptions = function(self, manifest)
        local screenId = manifest and routes[manifest.id]
        if screenId then
          return require("src.ui.Screens").push(self.game, screenId)
        end
        return openOptions(self, manifest)
      end
      ManagerState.__modOptionScreenRoutes = routes
    end
    routes[mod.id] = SCREEN_ID
  end)

  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    return mod.ui.insertBefore(out, "MODS", {
      id = "qol_later_gen",
      label = "QUALITY OF LIFE",
      value = function() return "OPEN" end,
      activate = function(g) mod.ui.push(g, SCREEN_ID) end,
    })
  end)

  local ballImage, ballQuad
  local function ballAsset()
    if ballImage == false then return nil end
    if not ballImage then
      local ok, image = pcall(love.graphics.newImage, DERIVED_BALL)
      if not ok then
        ballImage = false
        mod.log:warn("caught indicator unavailable: %s", tostring(image))
        return nil
      end
      ballImage = image
      ballQuad = love.graphics.newQuad(0, 0, 8, 8,
                                       image:getDimensions())
    end
    return ballImage, ballQuad
  end

  local function shakeOffsets(battle)
    local fx = battle.fx
    local sx = fx and fx.shakeX or 0
    local sy = fx and fx.shakeY or 0
    if sx == 0 and sy == 0 and fx and fx.shake and fx.shake > 0 then
      sx = battle.frame % 4 < 2 and 2 or -2
    end
    return sx, sy
  end

  local function enemyHudVisible(battle, slide)
    return battle.enemy and not battle.showEnemyTrainer
      and not battle.enemySendingOut
      and not battle:growInScale(battle.enemy)
      and slide == 0 and not battle.enemy.fainted
  end

  local function expPixels(battle)
    local mon = battle.player and battle.player.mon
    local def = mon and battle.data.pokemon[mon.species]
    if not def then return 0 end
    local cap = battle.data.constants and battle.data.constants.levelCap or 100
    if mon.level >= cap then return EXP_WIDTH end
    local current = Growth.expForLevel(def.growthRate, mon.level,
                                       battle.data.growth_rates)
    local nextLevel = Growth.expForLevel(def.growthRate, mon.level + 1,
                                         battle.data.growth_rates)
    local needed = nextLevel - current
    if needed <= 0 then return 0 end
    local progress = math.max(0, math.min(needed, mon.exp - current))
    return math.floor(progress * EXP_WIDTH / needed)
  end

  local function drawExpBar(battle, slide, sx, sy)
    local mode = optionValue(battle.game, "qol_exp_bar")
    if mode ~= "black" and mode ~= "blue" then return end
    if not battle.player or battle.safari or battle.demo
       or battle.showPlayerBack or slide ~= 0 then return end
    local px = expPixels(battle)
    if px <= 0 then return end
    local x, y = EXP_X + EXP_WIDTH - px + sx, EXP_Y + sy
    local color = mode == "black" and EXP_BLACK or EXP_BLUE
    love.graphics.setShader()
    love.graphics.setColor(color[1], color[2], color[3], color[4])
    love.graphics.rectangle("fill", x, y, px, 2)
    PaletteFX.markTrueColor(x, y, px, 2)
  end

  local function drawCaughtIndicator(battle, state, slide, sx, sy)
    local mode = optionValue(battle.game, "qol_caught_indicator")
    if mode ~= "grey" and mode ~= "red" then return end
    if not state.ownedAtStart or battle.kind ~= "wild"
       or battle.demo or battle.ghost
       or not enemyHudVisible(battle, slide) then return end
    local image, quad = ballAsset()
    if not image then return end
    local hudShake = battle.fx and battle.fx.hudShakeX or 0
    local x, y = 7 + sx + hudShake, 7 + sy
    love.graphics.setShader()
    if mode == "red" then
      love.graphics.setColor(1, 0, 0, 1)
    else
      love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.draw(image, quad, x, y)
    PaletteFX.markTrueColor(x, y, 8, 8)
  end

  local function drawOverlays(battle, state)
    if battle.blankForAskName then return end
    local sx, sy = shakeOffsets(battle)
    local slide = (battle.introSlide or 0) * 4
    drawExpBar(battle, slide, sx, sy)
    drawCaughtIndicator(battle, state, slide, sx, sy)
    love.graphics.setColor(1, 1, 1, 1)
  end

  local wrapped = setmetatable({}, { __mode = "k" })
  mod.events:on("battle.started", function(event)
    local battle = event and event.battle
    if not battle or wrapped[battle] or type(battle.draw) ~= "function" then return end
    local dex = battle.game and battle.game.save and battle.game.save.pokedex
    local species = event.species
    local state = {
      ownedAtStart = dex and dex.owned and dex.owned[species] or false,
      failed = false,
    }
    wrapped[battle] = state
    local baseDraw = battle.draw
    battle.draw = function(self)
      baseDraw(self)
      if state.failed then return end
      love.graphics.push("all")
      local ok, err = pcall(drawOverlays, self, state)
      love.graphics.pop()
      if not ok then
        state.failed = true
        mod.log:error("battle overlay disabled: %s", tostring(err))
      end
    end
  end)

  -- Small seams for this mod's standalone SDK test.
  mod.exports.screenId = SCREEN_ID
  mod.exports.optionValue = optionValue
  mod.exports.expPixels = expPixels
end
