const std = @import("std");
const rl = @import("raylib");
const gui = @import("raygui");
const render = @import("./render/render.zig");

// TODO: Move to config, best to use .toml file
const SCREEN_SIZE: rl.Vector2 = .{ .x = 1000, .y = 1000 };

pub fn main() !void {
    //--------------------------------------------------------------------------------------
    rl.initWindow(
        @intFromFloat(SCREEN_SIZE.x),
        @intFromFloat(SCREEN_SIZE.y),
        "izigometric-battle",
    );
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    rl.setExitKey(.key_null);
    //--------------------------------------------------------------------------------------

    // TODO: create state
    const scale: f32 = 0.4;
    var is_debug = false;

    const tile = rl.loadTexture("./assets/tile-grass.png");
    rl.setTextureFilter(tile, .texture_filter_trilinear);
    defer tile.unload();
    const tile_size = rl.Vector2.init(
        @as(f32, @floatFromInt(tile.width)) * scale,
        @as(f32, @floatFromInt(tile.height)) * scale,
    );

    // TODO: use ArrayList of Tile
    const TILE_ROW = 10;
    const TILE_COL = 10;
    const TILE_HEI = 5;

    var tile_drawing_offset = rl.Vector2.init(106.5, 104.0).scale(scale);

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Logic
        //----------------------------------------------------------------------------------

        { // TOGGLE DEBUG
            if (rl.isKeyDown(.key_left_control) and rl.isKeyPressed(.key_d)) {
                is_debug = !is_debug;
            }
        }

        if (is_debug) {
            { // === MOVE TILE OFFSET ===
                const shift_scale: f32 = if (rl.isKeyDown(.key_left_shift)) 10 else 1;
                if (rl.isKeyPressed(.key_left)) {
                    tile_drawing_offset.x -= 1 * shift_scale;
                } else if (rl.isKeyPressed(.key_right)) {
                    tile_drawing_offset.x += 1 * shift_scale;
                }

                if (rl.isKeyPressed(.key_up)) {
                    tile_drawing_offset.y -= 1 * shift_scale;
                } else if (rl.isKeyPressed(.key_down)) {
                    tile_drawing_offset.y += 1 * shift_scale;
                }
            }

            { // PRINT DEBUG
                if (rl.isKeyPressed(.key_p)) {
                    std.debug.print("[DEBUG] Tile Offset: {}\n", .{tile_drawing_offset});
                }
            }
        }

        { // WASD to move Camera
        }
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.sky_blue);

        { // Tiles
            const screen_center = SCREEN_SIZE.scale(0.5);
            const start_pos = screen_center; // TODO: offset so world is centered
            defer render.debug.drawGizmo(start_pos);

            // TODO: move to ArrayList of Tile with a Vector3 Pos
            //          - Layers, last element will be on top - when editing take that into account
            // TODO: create function that translate Vector3 Pos to Screen Pos to Draw
            //       will be relative to 0,0 will be needed to offset with camera (start_pos)
            for (0..TILE_HEI) |y| {
                const hei_offset = rl.Vector2.init(0, tile_size.y - tile_drawing_offset.y);
                const hei_pos = start_pos.subtract(hei_offset.scale(@floatFromInt(y)));
                for (0..TILE_COL) |x| {
                    const col_offset = tile_drawing_offset.multiply(
                        rl.Vector2.init(-1, 0.5),
                    );
                    const col_pos = hei_pos.add(col_offset.scale(@floatFromInt(x)));
                    for (0..TILE_ROW) |z| {
                        const row_offset = tile_drawing_offset.multiply(
                            rl.Vector2.init(1, 0.5),
                        );
                        const row_pos = col_pos.add(row_offset.scale(@floatFromInt(z)));
                        tile.drawEx(
                            row_pos,
                            0,
                            scale,
                            rl.Color.white,
                        );
                    }
                }
            }
        }

        { // UI
            if (is_debug) {
                rl.drawFPS(10, 10);
            }

            if (gui.guiButton(
                rl.Rectangle.init(10, 40, 100, 30),
                "Button",
            ) == 1) {
                std.debug.print("Clicked!", .{});
            }
        }

        //----------------------------------------------------------------------------------
    }
}

// TODO: move to state
const Tile = struct {
    type: Type,

    pub const Type = enum {
        grass,
    };
};
