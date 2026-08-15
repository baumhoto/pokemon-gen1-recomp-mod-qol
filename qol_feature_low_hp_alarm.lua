-- The red-HP siren, on a budget.
--
-- Vanilla mirrors the cart: wLowHealthAlarm is a latch the HUD redraw sets
-- while the player's bar is red, and both battle screens re-assert it every
-- frame -- Sound.startLoop is a no-op once the loop is already sounding, so
-- the siren simply never stops until the bar leaves the red, the mon faints or
-- the battle ends.
--
-- battle.low_health_alarm wraps exactly that toggle, and the engine documents
-- this shape of use at the call site ("force ctx.on false after some budget").
-- Both generations raise it under the same name with the same ctx.on /
-- ctx.battle keys (src/battle/BattleState.lua and src/ui/gen2/BattleState.lua),
-- so one subscription covers Red/Blue/Yellow and Gold alike -- no `games` key
-- and no per-generation fork.

local ALARM_KEY = "qol_low_hp_alarm"

local feature = {
  option = {
    key = ALARM_KEY,
    label = "LOW HP ALARM",
    type = "choice",
    -- NORMAL is `false` -- the schema default and a no-op -- and sits first so
    -- qol_options' modeIndex fallback lands an unrecognised saved value on
    -- vanilla behaviour rather than on MUTED.
    default = false,
    choices = {
      { "NORMAL", false },
      { "ONCE (1 SEC)", 1 },
      { "ONCE (2 SEC)", 2 },
      { "MUTED", 0 },
    },
  },
  menu = {
    label = "LOW HP ALARM",
    key = ALARM_KEY,
    description = "THE RED-HP SIREN\nNORMALLY LOOPS.\f"
      .. "SOUND IT BRIEFLY\nOR NOT AT ALL.",
  },
}

function feature.install(mod, services)
  local optionValue = services.options.value
  -- Keyed on the battle so two battles never share a budget, and weak so a
  -- finished one is collected rather than pinned here for the session.
  local soundingSince = setmetatable({}, { __mode = "k" })

  mod.hooks:wrap("battle.low_health_alarm", function(nextToggle, ctx)
    local limit = optionValue(mod.game, ALARM_KEY)
    -- NORMAL (false), and anything unrecognised, falls straight through.
    if type(limit) ~= "number" then return nextToggle(ctx) end

    local battle = ctx.battle
    -- ctx.on is the ENGINE's answer, read before anything below rewrites it.
    -- Its going false is the re-arm signal: the bar climbed out of the red,
    -- the mon fainted, or the battle ended -- so drop the budget and let the
    -- NEXT drop into the red sound again.  "Once" is once per visit to the
    -- red, not once per battle.
    if not ctx.on then
      if battle then soundingSince[battle] = nil end
      return nextToggle(ctx)
    end

    if limit <= 0 then
      -- MUTED.  Still hand vanilla the toggle rather than returning early:
      -- vanilla is what calls Sound.stopLoop, so skipping it would leave a
      -- siren that had already started running forever.
      ctx.on = false
      return nextToggle(ctx)
    end

    if not battle then return nextToggle(ctx) end
    local startedAt = soundingSince[battle]
    if not startedAt then
      soundingSince[battle] = love.timer.getTime()
    elseif love.timer.getTime() - startedAt >= limit then
      ctx.on = false
    end
    return nextToggle(ctx)
  end)
end

return feature
