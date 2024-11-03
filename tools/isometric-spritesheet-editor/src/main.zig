const std = @import("std");
const core = @import("core");
const rl = @import("raylib");
const rgui = @import("raygui");

pub fn main() !void {
    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(
        1000,
        1000,
        "isometric-spritesheet-editor",
    );
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    rl.setExitKey(.key_null);

    // TODO: load tex from file picker
    const tile = rl.loadTexture("./../../game/assets/tiles_spritesheet.png");
    rl.setTextureFilter(tile, .texture_filter_trilinear);
    defer tile.unload();

    // Camera
    var camera: rl.Camera2D = .{
        .offset = rl.Vector2.zero(),
        .target = rl.Vector2.zero(),
        .rotation = 0,
        .zoom = 1.0,
    };

    while (!rl.windowShouldClose()) {
        // ---LOGIC HERE
        { // Translate based on mouse middle click
            // or space + left_mouse_drag
            // TODO: cursor icon
            const is_space_dragging = rl.isKeyDown(.key_space) and rl.isMouseButtonDown(.mouse_button_left);
            const is_middle_mouse_dragging = rl.isMouseButtonDown(.mouse_button_middle);
            if (is_space_dragging or is_middle_mouse_dragging) {
                var delta = rl.getMouseDelta();
                delta = delta.scale(-1.0 / camera.zoom);
                camera.target = camera.target.add(delta);
            }
        }
        { // Zoom based on mouse wheel
            const wheel = rl.getMouseWheelMove();
            if (wheel != 0) {
                // Get the world point that is under the mouse
                const mouseWorldPos = rl.getScreenToWorld2D(
                    rl.getMousePosition(),
                    camera,
                );

                // Set the offset to where the mouse is
                camera.offset = rl.getMousePosition();

                // Set the target to match, so that the camera maps the world space point
                // under the cursor to the screen space point under the cursor at any zoom
                camera.target = mouseWorldPos;

                // Zoom increment

                var scaleFactor = 1.0 + (0.25 * @abs(wheel));
                if (wheel < 0) scaleFactor = 1.0 / scaleFactor;
                camera.zoom = rl.math.clamp(
                    camera.zoom * scaleFactor,
                    0.125,
                    64.0,
                );
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.dark_gray);
        // ---RENDER HERE
        { // INSIDE CAMERA
            const center_point = rl.Vector2.init(
                @as(f32, @floatFromInt(rl.getScreenWidth())) / 2.0,
                @as(f32, @floatFromInt(rl.getScreenHeight())) / 2.0,
            );
            camera.begin();
            defer camera.end();
            drawTileWithCheckerboard(&tile, center_point);
        }

        { // UI
            _ = rgui.guiLabel(
                rl.Rectangle.init(10, 10, 200, 50),
                "Tab 1",
            );
        }
    }
}
// TODO: move all utils func to core.rlx
fn tileSize(tile: *const rl.Texture) rl.Vector2 {
    return rl.Vector2.init(
        @as(f32, @floatFromInt(tile.width)),
        @as(f32, @floatFromInt(tile.height)),
    );
}

fn drawTileWithCheckerboard(tile: *const rl.Texture, pos: rl.Vector2) void {
    drawCheckerboardV(pos, tileSize(tile), 10);
    tile.drawV(
        pos,
        rl.Color.white,
    );
}

fn drawCheckerboard(posX: f32, posY: f32, width: f32, height: f32, resolution: comptime_int) void {
    // TODO: use divCeil for covering the case of exact match
    // const cols: usize = @intFromFloat(std.math.divCeil(f32, width, res_f32));
    const cols: usize = @as(usize, @intFromFloat(width / resolution)) + 1;
    const rows: usize = @as(usize, @intFromFloat(height / resolution)) + 1;
    for (0..cols) |x| {
        const x_float: f32 = @floatFromInt(x);
        for (0..rows) |y| {
            const y_float: f32 = @floatFromInt(y);
            const color = if ((x + y) % 2 == 0) rl.Color.white else rl.Color.light_gray;
            const x_offset: f32 = resolution * x_float;
            const x_diff_width = width - x_offset;
            const y_offset: f32 = resolution * y_float;
            const y_diff_height = height - y_offset;
            rl.drawRectangleRec(
                rl.Rectangle.init(
                    posX + x_offset,
                    posY + y_offset,
                    if (x_diff_width >= resolution) resolution else x_diff_width,
                    if (y_diff_height >= resolution) resolution else y_diff_height,
                ),
                color,
            );
        }
    }
    // {
    //     const drawn_width: f32 = @floatFromInt(cols * resolution);
    //     if (drawn_width < width) {
    //         rl.drawRectangleRec(
    //             rl.Rectangle.init(
    //                 posX + drawn_width,
    //                 posY,
    //                 width - drawn_width,
    //                 height,
    //             ),
    //             rl.Color.magenta,
    //         );
    //     }
    // }
}

fn drawCheckerboardV(pos: rl.Vector2, size: rl.Vector2, resolution: comptime_int) void {
    return drawCheckerboard(
        pos.x,
        pos.y,
        size.x,
        size.y,
        resolution,
    );
}
