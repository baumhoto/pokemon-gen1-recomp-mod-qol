# Changelog

## v1.4.0

### Added

#### Random Battles

- **RANDOM BATTLES:** Scales how often wild encounters start. **NORMAL** (the
  default) is vanilla and changes nothing, **HALF** and **DOUBLE** scale the
  map's own encounter rate, and **NONE** turns wild encounters off entirely.
- Gen 1 only for now. Gold runs its encounter-rate check before the hook this
  rides, so the row is hidden there rather than shipped half-working.

## v1.3.0

### Tested compatibility

- gen1recomp v0.1.80
- Dramatic Shape Voxel Mod v1.8.1

### Added

- Beta support for the Gen2 Gold version. This is a test version. I don't have a far enough savegames at the moment to test everything.
- While in Gen1 you use SELECT button to get the menu for TELEPORT, DIG, etc... in Gen2, for now, you have to press and hold (shortly) START button, since SELECT button is already occupied by Gold itself. For now, REPEL items and FLASH are tested working in the menu.

## v1.2.7

### Tested compatibility

- gen1recomp v0.1.72
- Dramatic Shape Voxel Mod v1.7.2

### Added

#### Easy Interactions

- **REPEL:** Adds a **REPEL** option in the **SELECT** menu if a repel item is available. Consumes the weakest ones first. Optional setting to show a prompt whether you want to use another repel when the current one is over.

## v1.2.6

### Tested compatibility

- gen1recomp v0.1.72
- Dramatic Shape Voxel Mod v1.6.1

### Added

#### Easy Interaction Options sub menu

- **CUT GRASS:** Turn off the cutting of grass with the **A** button
- **WATER INTERACTION:** When using **A** button facing water, choose between FISH first, SURF first, FISH only, SURF only

### Fixed
 
- **A** button would prioritize cutting grass instead of interacting with NPC's in grass
- Simplified some descriptions

## v1.2.5

### Tested compatibility

- gen1recomp v0.1.69
- Dramatic Shape Voxel Mod v1.6.0

### Fixed

- XP bar rendering with different color modes/palettes
- Caught indicator rendering with different color modes/palettes
- Caught indicator adjusted to newest Voxel Mod version

## v1.2.4

### Tested compatibility

- gen1recomp v0.1.64
- Dramatic Shape Voxel Mod v1.5.4

### Added

- Animation for the XP bar when leveling up

### Fixed

- XP bar will fill up more than once now if a pokemon levels up more than one level

## v1.2.3

### Tested compatibility

- gen1recomp v0.1.60
- Dramatic Shape Voxel Mod v1.5.4

### Added

- Added faithful Gen2 icon for the caught Pokemon indicator, available in the options

## v1.2.2

### Tested compatibility

- gen1recomp v0.1.57
- Dramatic Shape Voxel Mod v1.5.1

### Added

- Easily update the mod via the recomp launcher -> Mods -> Update

### Fixed

- Can no longer fish while surfing
- XP bar and caught indicator are correctly "shaking" during wide battles
- XP bar and caught indicator are correctly positioned when using the "Voxel" Dramatic Shapes mod.

## v1.2.1

### Added

- Location banners, choose between 1, 2 or 3 seconds on screen time

### Fixed

- Location banners showing "Rock Tunnel" when entering the Route 10 Poke Center right in front of Rock Tunnel. While correct (that center has the location Rock Tunnel in the game files), we don't want that behavior.

## v1.2.0

### Added

- Location banners - Always know where you are!

### Changed

- Split features into separate modules
- Prepare repo for auto update

## v1.1.2

### Added

- Support for caught indicator in wide battle mode
- Support for xp bar indicator in wide battle mode

### Fixed

- FLASH not working from the convenience popup since since recomp version 0.1.42

## v1.1.1

### Added

- Exp bar is now animated

### Fixed

- Exp bar sometimes rendered on top of popups

## v1.1.0

### Added

- Easy interactions:
    - When a Pokemon with CUT or STRENGTH is in the party, press [A] button when facing bushes or boulders to activate automatically.
    - When facing water, pressing [A] automatically asks whether you want to FISH or SURF.
    - When FLY, DIG, FLASH or TELEPORT is available, pressing [SELECT] will let you do that directly.

## v1.0.0

### Added

- Experience bar during battle (Gen2 style)
- Indicator for already caught Pokemon during wild encounters (Gen2 style)
