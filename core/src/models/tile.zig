const rl = @import("raylib");

/// the tile struct that represent a tile in the world
pub const Tile = struct {
    position: rl.Vector3,
    type: Type,

    // TODO: here should type that drive game mechanic not visual, e.g. toggle, etc...
    pub const Type = enum {
        grass,
    };
};
