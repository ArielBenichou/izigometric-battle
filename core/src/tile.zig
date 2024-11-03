const rl = @import("raylib");

/// the tile struct that represent a tile in the world
pub const Tile = struct {
    position: rl.Vector3,
    type: Type,

    pub const Type = enum {
        grass,
    };
};
