-- Wild encounter rate scaling.
--
-- src/world/Encounter.lua rolls the map's rate ITSELF (`rng(0, 255) >=
-- grass.rate`), and OverworldState:rollEncounter wraps that whole call in the
-- encounter.roll chain -- so a wrapper here is handed the map's encounter def
-- BEFORE the gate and can scale the rate exactly.  Suppressing rolls after the
-- fact could only ever thin them out; scaling the rate is what makes DOUBLE
-- possible at all.
--
-- Gold is deliberately out of scope for now: World:tryWildEncounter runs its
-- rate gate (Encounter.triggers) BEFORE it calls World:rollEncounter, so the
-- same hook there only ever sees encounters that already triggered -- enough
-- to suppress, not to amplify.  Doubling on Gold has to wrap
-- World.musicEncounterRate instead, and `games` keeps this file off that boot
-- until it does.

local RATE_KEY = "qol_encounter_rate"

-- Encounter.roll compares `rng(0, 255)` against the rate, so 255 is the
-- saturating maximum and the byte width the cart's own rates arrive in.  Gold's
-- ApplyMusicEffectOnEncounterRate doubles with `sla b` and lets the result WRAP
-- at a byte; clamping instead is a deliberate difference, because wrapping
-- would turn DOUBLE into FEWER encounters on any map above rate 127.
local MAX_RATE = 255

local feature = {
  -- Gold's rate gate runs ahead of the hook this rides; see the note above.
  games = { "gen1" },
  option = {
    key = RATE_KEY,
    label = "RANDOM BATTLES",
    type = "choice",
    -- NORMAL is `false` -- the schema default and a no-op -- rather than a
    -- separate OFF entry, because a 1x multiplier and a disabled feature are
    -- the same state.  It is also FIRST on purpose: qol_options' modeIndex
    -- falls back to index 1 for any value it cannot match, so a save carrying
    -- a stale value lands on vanilla behaviour rather than on NONE.
    default = false,
    choices = {
      { "NORMAL", false },
      { "HALF", 0.5 },
      { "DOUBLE", 2 },
      { "NONE", 0 },
    },
  },
  menu = {
    label = "RANDOM BATTLES",
    key = RATE_KEY,
    description = "HOW OFTEN WILD\nBATTLES START.\f"
      .. "NONE TURNS THEM\nOFF COMPLETELY.",
  },
}

function feature.install(mod, services)
  local optionValue = services.options.value

  -- Registered eagerly, the way every other feature in this mod installs its
  -- wrappers.  What that costs while the option sits on NORMAL is one 3-field
  -- ctx table per grass step, since OverworldState:rollEncounter builds it
  -- whenever anything at all wants the hook -- and unwrapping later would not
  -- reclaim it anyway: the remover Hooks:wrap returns empties the chain but
  -- never deletes chains[name], which is the only thing Runtime.wantsHook
  -- tests.
  mod.hooks:wrap("encounter.roll", function(nextRoll, encDef, ctx)
    -- mod.game rather than mod.world.game: the loader resolves it on every
    -- touch (Loader:_game) and it is the reference a mod is meant to hold, so
    -- this reads the live save without building the WorldAPI facade first.
    local multiplier = optionValue(mod.game, RATE_KEY)
    -- NORMAL (false), and anything unrecognised, falls straight through --
    -- which is every roll for a player who never touches the option.
    if type(multiplier) ~= "number" then return nextRoll(encDef, ctx) end
    if multiplier == 0 then return nil end

    local grass = encDef and encDef.grass
    -- A rate of 0 means "this map has no wild encounters" (Encounter.roll
    -- returns early on it), and it has to stay 0 however it is scaled.
    if not grass or not grass.rate or grass.rate == 0 then
      return nextRoll(encDef, ctx)
    end

    -- COPY, never mutate.  The grass path is handed
    -- Game.data.encounters[mapId] straight out of the loaded dataset, so
    -- scaling in place would corrupt that map's real rate for the rest of the
    -- session and compound on every step.  (The water path builds a fresh
    -- table per step, which is exactly why an in-place bug there would look
    -- fine while grass quietly rotted.)
    local scaled = {}
    for key, value in pairs(encDef) do scaled[key] = value end
    local scaledGrass = {}
    for key, value in pairs(grass) do scaledGrass[key] = value end
    -- math.floor matches the engine's own halving (World.musicEncounterRate
    -- uses it for POKEMON LULLABY), floor-to-zero on a rate of 1 included.
    scaledGrass.rate = math.min(MAX_RATE, math.floor(grass.rate * multiplier))
    scaled.grass = scaledGrass
    return nextRoll(scaled, ctx)
  end)
end

return feature
