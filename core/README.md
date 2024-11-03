# Izigometric Battle - Core Library
This is the core enigne and logic for the game and tools around the game.


## Install

To add this lib to your project.

1. add this to your `build.zig.zon` file:

```zon
.{
    // ...
    .dependencies = .{
        // ...
        .core = .{
            .path = "../core", // relative path
        },
    },
    // ...
}
```

2. add this to your `build.zig` file:
```zig
// --- CORE LIB
const core_dep = b.dependency("core", .{
    .target = target,
    .optimize = optimize,
});
const core = core_dep.module("core");
exe.root_module.addImport("core", core);
```

3. Import in your zig files and use it:
```zig
const core = @import("core");
```

## Test

Run all unit tests:
```sh
zig build test --summary all
```

## TODO
- [ ] Define `Tile` struct.
- [ ] `TilesRenderer` Helpers to draw tiles from world coords, to screen coords.
