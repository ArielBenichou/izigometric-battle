const std = @import("std");
const rl = @import("raylib");

pub fn main() !void {
    //--------------------------------------------------------------------------------------
    rl.initWindow(
        1000,
        1000,
        "izigometric-battle",
    );
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    rl.setExitKey(.key_null);
    //--------------------------------------------------------------------------------------

    const scale: f32 = 0.5;

    const tile = rl.loadTexture("./assets/tile-grass.png");
    rl.setTextureFilter(tile, .texture_filter_trilinear);
    defer tile.unload();

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Logic
        //----------------------------------------------------------------------------------

        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        for (0..3) |i| {
            tile.drawEx(
                .{
                    .x = @as(f32, @floatFromInt(@as(c_int, @intCast(i)) * tile.width)) * scale,
                    .y = 500,
                },
                0,
                scale,
                rl.Color.white,
            );
        }
        //----------------------------------------------------------------------------------
    }
}
