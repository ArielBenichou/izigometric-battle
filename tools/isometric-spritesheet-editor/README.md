# Isometric Sprite Sheet Editor
A tool to generate a JSON configuration file, to know what are the Prespective Points (TODO: see doc) of the tile system used, and tag each tile with a name.


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
- [ ] UI
  - [ ] Bottom footer with shortcut
  - [ ] right-side properties panel for project/sprite
    - [ ] export/save button at the bottom
  - [x] zoom in and out with middle mouse scroll
  - [x] move camera with middle mouse drag OR space + right mouse drag
  - [x] transparent grid for sprite, grey background.
- [ ] highlight tagged spirte with isometric bounding box
  - [ ] and sprite bounding box
    - [ ] resize by the sprite box
  - [ ] double click to enter "master prespective edit", affect the prespective points used for this project
  - [ ] show in right side editor panel properties of this box
- [ ] small name on top (world space)
- [ ] easy tagger - click on a point and it should snap to the grid with a new tag
- [ ] Configure 4-axis point (Prespective Points) (on double click)
  - [ ] add 'phantom' handle point just for qol.
  - [ ] make it draggable by it's center point
- [ ] tag tile with name
- [ ] can have other scale of tiles (same prespective)
- [ ] Read, Write, Validate projets files
- [ ] Think about extending/reusing a config with a new/modified spritesheet

