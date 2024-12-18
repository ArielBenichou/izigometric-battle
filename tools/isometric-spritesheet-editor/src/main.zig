const std = @import("std");
const core = @import("core");
const rl = @import("raylib");
const rgui = @import("raygui");

pub fn main() !void {
    // TODO: when quit app with window X, lots of leaks...
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(
        1000,
        1000,
        "isometric-spritesheet-editor",
    );
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    rl.setExitKey(.key_null);

    // TODO: open file select dialog to chose a file
    // FIXME: handle error
    const config_path: []const u8 = try allocator.dupe(u8, "../../game/assets/config.json");
    defer allocator.free(config_path);
    var config = try core.config.readConfig(allocator, config_path);
    defer config.deinit(allocator);

    // TODO: load tex from the config file, in the config file you should have a relative to the config file, or absolute to system
    const tile = rl.loadTexture("./../../game/assets/tiles_spritesheet.png");
    rl.setTextureFilter(tile, .texture_filter_point);
    defer tile.unload();

    var state = State.init(allocator);
    state.deinit();

    state.spirtesheet_iso_box = core.rlx.IsometricBox.init(
        config.prespective_points[0],
        config.prespective_points[1],
        config.prespective_points[2],
        config.prespective_points[3],
    );
    for (config.tags.items) |tag| {
        try state.objects.append(tag.position);
    }

    while (!rl.windowShouldClose()) {
        // TODO: move all cursor stuff to render
        { // Cleanup
            rl.setMouseCursor(.mouse_cursor_default);
        }

        try logic(&state, &config, allocator, &config_path);

        render(state, tile);
    }
}

// HELPERS

pub fn isMouseHoveringAroundPosition(position: rl.Vector2, radius: f32, camera: rl.Camera2D) bool {
    const mouse_world_pos = rl.getScreenToWorld2D(rl.getMousePosition(), camera);
    return @abs(mouse_world_pos.distance(position)) < radius;
}

// STATE

const State = struct {
    const Self = State;
    history: History,
    // call this IsometricMesh
    spirtesheet_iso_box: core.rlx.IsometricBox = undefined,
    objects: Objects,
    /// index to objects
    selected_object: ?usize = null,

    camera: rl.Camera2D = undefined,

    is_dragging: bool = false,
    last_mouse_click: ?rl.Vector2 = null,
    last_clicked_vertex: ?core.rlx.IsometricBox.VertexName = null,

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .history = History.init(allocator),
            .objects = Objects.init(allocator),
            .camera = .{
                .offset = rl.Vector2.zero(),
                .target = rl.Vector2.zero(),
                .rotation = 0,
                .zoom = 1.0,
            },
        };
    }

    pub fn deinit(self: *Self) void {
        self.history.deinit();
        self.objects.deinit();
    }
};
const History = std.ArrayList(DesiredAction);
const Objects = std.ArrayList(rl.Vector2);

const DesiredAction = union(enum) {
    // EDIT MESH
    mesh_vertex_move: struct { vertex_name: core.rlx.IsometricBox.VertexName, delta: rl.Vector2 },

    // GLOBAL
    undo,
    repeat,

    // DEBUG
    debug_print,
};

/// THIS SHOULD HANDLE THE PRIORTY ORDER given the state and the input
fn logic(state: *State, config: *core.config.Config, allocator: std.mem.Allocator, config_path: *const []const u8) !void {
    // helpers vars
    const is_mouse_left_pressed = rl.isMouseButtonPressed(.mouse_button_left);
    const is_mouse_left_released = rl.isMouseButtonReleased(.mouse_button_left);
    const is_mouse_left_down = rl.isMouseButtonDown(.mouse_button_left);
    const is_ctrl = rl.isKeyDown(.key_left_control);
    const mouse_pos = rl.getMousePosition();

    // update vars
    if (is_mouse_left_pressed) {
        state.last_mouse_click = mouse_pos;
    }

    // non-blocking action (could do anytime)
    if (rl.isKeyPressed(.key_p)) {
        try applyDesiredActionToState(state, .debug_print);
    }

    { // Zoom based on mouse wheel
        const wheel = rl.getMouseWheelMove();
        if (wheel != 0) {
            // Get the world point that is under the mouse
            const mouse_world_pos = rl.getScreenToWorld2D(
                rl.getMousePosition(),
                state.camera,
            );

            // Set the offset to where the mouse is
            state.camera.offset = rl.getMousePosition();

            // Set the target to match, so that the state.camera maps the world space point
            // under the cursor to the screen space point under the cursor at any zoom
            state.camera.target = mouse_world_pos;

            // Zoom increment

            var scale_factor = 1.0 + (0.25 * @abs(wheel));
            if (wheel < 0) scale_factor = 1.0 / scale_factor;
            state.camera.zoom = rl.math.clamp(
                state.camera.zoom * scale_factor,
                0.125,
                64.0,
            );
        }
    }

    if (is_mouse_left_down) {
        state.is_dragging = @abs(state.last_mouse_click.?.distance(mouse_pos)) > 1;
    }
    // stop the dragging
    if (is_mouse_left_released) {
        if (state.is_dragging) {
            state.is_dragging = false;

            if (state.last_clicked_vertex) |vertex| {
                defer state.last_clicked_vertex = null;

                var delta = mouse_pos.subtract(state.last_mouse_click.?);
                delta = delta.scale(1.0 / state.camera.zoom);
                try state.history.append(.{
                    .mesh_vertex_move = .{
                        .vertex_name = vertex,
                        .delta = delta,
                    },
                });
            }
        }
    } else if (state.is_dragging) {
        if (state.last_clicked_vertex) |vertex| {
            rl.setMouseCursor(.mouse_cursor_pointing_hand); // TODO: move to render
            var delta = rl.getMouseDelta();
            delta = delta.scale(1.0 / state.camera.zoom);
            try applyDesiredActionToState(state, .{
                .mesh_vertex_move = .{
                    .vertex_name = vertex,
                    .delta = delta,
                },
            });
            return;
        }
    } else if (state.selected_object) |_| {
        const force_field_radius = 3;
        const handle_verticies = [_]core.rlx.IsometricBox.VertexName{
            .top_back,
            .top_front,
            .bottom_front,
            .top_right,
            .bottom_right,
            .top_left,
            .bottom_left,
        };
        inline for (handle_verticies) |vertex| {
            const center_point = rl.Vector2.init(
                @as(f32, @floatFromInt(rl.getScreenWidth())) / 2.0,
                @as(f32, @floatFromInt(rl.getScreenHeight())) / 2.0,
            ); // screen position
            const selected_obj_pos = state.objects.items[state.selected_object.?];
            const iso_box = state.spirtesheet_iso_box.add(center_point.add(selected_obj_pos));
            if (isMouseHoveringAroundPosition(
                iso_box.getVertex(vertex),
                force_field_radius,
                state.camera,
            )) {
                rl.setMouseCursor(.mouse_cursor_pointing_hand); // TODO: move to render
                if (is_mouse_left_pressed) {
                    state.last_clicked_vertex = vertex;
                }
            }
        }
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
            delta = delta.scale(-1.0 / state.camera.zoom);
            state.camera.target = state.camera.target.add(delta);
            return;
        }
    }

    if (is_mouse_left_pressed) {
        // TODO: logic of detecteing click on box
        if (rl.isKeyDown(.key_left_shift)) {
            state.selected_object = null;
        } else {
            state.selected_object = 0;
        }
    }

    { // Save Config
        if (rl.isKeyDown(.key_left_control) and rl.isKeyPressed(.key_s)) {
            config.prespective_points = &state.spirtesheet_iso_box.points;
            config.tags.clearRetainingCapacity();
            for (state.objects.items) |obj| {
                try config.tags.append(.{
                    .name = "moo",
                    .variant = "",
                    .position = obj,
                    .scale = 1,
                });
            }
            try core.config.writeConfig(allocator, config.*, config_path.*);
            return;
        }
    }

    if (is_ctrl and rl.isKeyPressed(.key_z)) {
        try applyDesiredActionToState(state, .undo);
        return;
    }

    if (rl.isKeyPressed(.key_period)) {
        try applyDesiredActionToState(state, .repeat);
        return;
    }

    return;
}

fn applyDesiredActionToState(state: *State, action: DesiredAction) !void {
    _ = switch (action) {
        .mesh_vertex_move => |v| {
            const current_value: rl.Vector2 = state.spirtesheet_iso_box.getVertex(v.vertex_name);
            state.spirtesheet_iso_box.setVertex(v.vertex_name, current_value.add(v.delta));
        },

        .undo => {
            if (state.history.popOrNull()) |entry| {
                _ = switch (entry) {
                    .mesh_vertex_move => |v| {
                        try applyDesiredActionToState(state, .{ .mesh_vertex_move = .{
                            .vertex_name = v.vertex_name,
                            .delta = v.delta.scale(-1),
                        } });
                    },
                    else => {},
                };
            }
        },

        .repeat => {
            if (state.history.getLastOrNull()) |entry| {
                try applyDesiredActionToState(state, entry);
                switch (entry) {
                    .mesh_vertex_move => {
                        try state.history.append(entry);
                    },
                    else => {},
                }
            }
        },

        .debug_print => {
            std.debug.print(
                "[GAME] state: {}\n",
                .{state},
            );
        },
    };
}

fn render(state: State, tile: rl.Texture) void {
    const center_point = rl.Vector2.init(
        @as(f32, @floatFromInt(rl.getScreenWidth())) / 2.0,
        @as(f32, @floatFromInt(rl.getScreenHeight())) / 2.0,
    ); // screen position

    rl.beginDrawing();
    defer rl.endDrawing();
    rl.clearBackground(rl.Color.dark_gray);

    const drawing_color = drawing_color: {
        const c = rl.Color.magenta;
        if (state.last_clicked_vertex != null) {
            if (state.is_dragging) {
                break :drawing_color c.alpha(0.5);
            }
        }
        break :drawing_color c;
    };

    { // INSIDE CAMERA
        state.camera.begin();
        defer state.camera.end();

        // Sprite
        core.rlx.Texture.drawWithCheckerboard(&tile, center_point);

        for (state.objects.items, 0..) |obj, i| {
            const is_selected = state.selected_object == i;
            // Overlay
            state.spirtesheet_iso_box.drawBoundingBox(
                center_point.add(obj),
                rl.Color.dark_blue,
                is_selected,
            );
            if (is_selected) {
                state.spirtesheet_iso_box.drawMesh(
                    center_point.add(obj),
                    drawing_color,
                    is_selected,
                );
            }
        }
    }
}
