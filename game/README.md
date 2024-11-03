# Izigometric Battle
A Simple Turn-Based Isometric Game with a Retro Menu Battle


## Build

To build and run, it will build for your native platform.

```sh
zig build run
```

## Release

TODO: it should build all binary files for all platforms supported, and tag the the folder name with the version, bring in all the assets in the expected folder structure, and zip it, ready to put on a github release.

```sh
zig build release
```

## TODO
- [ ] Main Menu (Play Game button)
- [ ] Level Selector
  - Loads all files from `/levels` directory, display their name
  - Check in the `/saves` folder, if a save exist, if yes, load and parse, and display score
  for each level.
  - Select will load the file content, parse the JSON, and go to the Level Scene
- [ ] Level:
  - [ ] Display level
  - [ ] be able to hide layers of the map to see underground levels
  - [ ] Spawn Player
  - [ ] Turn Based Loop
  - [ ] Player Actions
    - [ ] Walk
      - [ ] Terrain Effect
    - [ ] Pick Up Item - unlock action
      - [ ] sword
      - [ ] spell
- [ ] UI
  - [ ] Show current turn and max turn for this level
  - [ ] Menu Button
    - [ ] Pause Game
    - [ ] Exit
    - [ ] Back to Main Menu



- [ ] Tile Drawing Engine
  - [ ] make it as seperate build, other build file
- [ ] Isometric Tiles Sprite Sheet Tools
  - [ ] Configure 3-axis point
  - [ ] tag tile with name
  - [ ] can have other scale of tiles (same prespective)
- [ ] Level Editor
  - [ ] Save to file that the game can read
