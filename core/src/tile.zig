/// the tile struct that represent a tile in the world
const Tile = struct {
    type: Type,

    pub const Type = enum {
        grass,
    };
};
