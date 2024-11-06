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
    rl.setTextureFilter(tile, .texture_filter_point);
    defer tile.unload();

    // Camera
    var camera: rl.Camera2D = .{
        .offset = rl.Vector2.zero(),
        .target = rl.Vector2.zero(),
        .rotation = 0,
        .zoom = 1.0,
    };

    // TODO: create a big State of the program state

    // Iso Box
    var spirtesheet_iso_box = core.rlx.IsometricBox.init(
        rl.Vector2.init(0, 0),
        rl.Vector2.init(0, 50),
        rl.Vector2.init(-100, -40),
        rl.Vector2.init(100, -40),
    );
    // TODO: think of an easy system to manage world and screen positions
    const iso_box_pos = rl.Vector2.init(100, 100); // world position

    var is_dragging = false;
    var box_point_dragging: []const u8 = undefined;

    // TODO: think of a system for easier control of what action is happening
    // if we can have a list of action and define what the user does,
    // then we can render the cursor more easily without becoming unmatinable fast
    // same for render.
    // maybe we should cake it like that:
    // INPUT -> STATE (part of the state is desired_action: Action enum)
    // ----
    // ACTION -> STATE (the desired_action is applied to the state)
    // ----
    // STATE -> RENDER
    while (!rl.windowShouldClose()) {
        const center_point = rl.Vector2.init(
            @as(f32, @floatFromInt(rl.getScreenWidth())) / 2.0,
            @as(f32, @floatFromInt(rl.getScreenHeight())) / 2.0,
        ); // screen position

        const iso_box = spirtesheet_iso_box.add(center_point.add(iso_box_pos));
        // ---LOGIC HERE
        { // Cleanup
            rl.setMouseCursor(.mouse_cursor_default);
        }
        { // Translate based on mouse middle click
            // or space + left_mouse_drag
            const is_key_down_space = rl.isKeyDown(.key_space);
            const is_space_dragging = is_key_down_space and rl.isMouseButtonDown(.mouse_button_left);
            const is_middle_mouse_down = rl.isMouseButtonDown(.mouse_button_middle);
            if (is_key_down_space or is_middle_mouse_down) {
                rl.setMouseCursor(.mouse_cursor_pointing_hand);
            }
            if (is_space_dragging or is_middle_mouse_down) {
                var delta = rl.getMouseDelta();
                delta = delta.scale(-1.0 / camera.zoom);
                camera.target = camera.target.add(delta);
            }
        }
        { // Zoom based on mouse wheel
            const wheel = rl.getMouseWheelMove();
            if (wheel != 0) {
                // Get the world point that is under the mouse
                const mouse_world_pos = rl.getScreenToWorld2D(
                    rl.getMousePosition(),
                    camera,
                );

                // Set the offset to where the mouse is
                camera.offset = rl.getMousePosition();

                // Set the target to match, so that the camera maps the world space point
                // under the cursor to the screen space point under the cursor at any zoom
                camera.target = mouse_world_pos;

                // Zoom increment

                var scale_factor = 1.0 + (0.25 * @abs(wheel));
                if (wheel < 0) scale_factor = 1.0 / scale_factor;
                camera.zoom = rl.math.clamp(
                    camera.zoom * scale_factor,
                    0.125,
                    64.0,
                );
            }
        }

        { // move handle of iso_box
            if (is_dragging) {
                rl.setMouseCursor(.mouse_cursor_pointing_hand);
                var delta = rl.getMouseDelta();
                delta = delta.scale(1.0 / camera.zoom);
                const last_point_value: rl.Vector2 = try spirtesheet_iso_box.getField(box_point_dragging);
                try spirtesheet_iso_box.setField(box_point_dragging, last_point_value.add(delta));
            } else {
                const force_field_radius = 3;
                const iso_box_fields = std.meta.fields(core.rlx.IsometricBox); // try @TypeOf
                inline for (iso_box_fields) |field| {
                    if (isMouseHoveringAroundPosition(
                        @field(iso_box, field.name),
                        force_field_radius,
                        camera,
                    )) {
                        rl.setMouseCursor(.mouse_cursor_pointing_hand);
                        if (rl.isMouseButtonPressed(.mouse_button_left)) {
                            is_dragging = true;
                            box_point_dragging = field.name;
                        }
                    }
                }
            }
            if (rl.isMouseButtonReleased(.mouse_button_left)) {
                is_dragging = false;
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.dark_gray);
        // ---RENDER HERE
        { // INSIDE CAMERA
            camera.begin();
            defer camera.end();

            core.rlx.Texture.drawWithCheckerboard(&tile, center_point);
            spirtesheet_iso_box.drawBoundingBox(
                center_point.add(iso_box_pos),
                rl.Color.magenta,
            );
            // TODO: we probably want the currently dragged handle to be semi transperent to see underneath
            spirtesheet_iso_box.drawHandles(
                center_point.add(iso_box_pos),
                rl.Color.magenta,
            );
        }

        { // UI
            _ = rgui.guiLabel(
                rl.Rectangle.init(10, 10, 200, 50),
                "Tab 1",
            );
        }
    }
}

pub fn isMouseHoveringAroundPosition(position: rl.Vector2, radius: f32, camera: rl.Camera2D) bool {
    const mouse_world_pos = rl.getScreenToWorld2D(rl.getMousePosition(), camera);
    return @abs(mouse_world_pos.distance(position)) < radius;
}
