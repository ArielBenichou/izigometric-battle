/// This is functionlity that is built on top of raylib, x stand for extended
const std = @import("std");
const rl = @import("raylib");

pub const Texture = struct {
    pub fn size(tex: *const rl.Texture) rl.Vector2 {
        return rl.Vector2.init(
            @as(f32, @floatFromInt(tex.width)),
            @as(f32, @floatFromInt(tex.height)),
        );
    }
    pub fn drawWithCheckerboard(tex: *const rl.Texture, pos: rl.Vector2) void {
        drawCheckerboardV(pos, Texture.size(tex), 16);
        tex.drawV(
            pos,
            rl.Color.white,
        );
    }
};

pub fn drawCheckerboard(posX: f32, posY: f32, width: f32, height: f32, resolution: comptime_int) void {
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
}

pub fn drawCheckerboardV(pos: rl.Vector2, size: rl.Vector2, resolution: comptime_int) void {
    return drawCheckerboard(
        pos.x,
        pos.y,
        size.x,
        size.y,
        resolution,
    );
}

pub const IsometricBox = struct {
    /// This is a set of 4 points to describe any type of isometric 2.5d tile
    /// The order of the points are: top_front, bottom_front, top_left, top_right
    points: [4]rl.Vector2,

    pub fn init(
        top_front: rl.Vector2,
        bottom_front: rl.Vector2,
        top_left: rl.Vector2,
        top_right: rl.Vector2,
    ) IsometricBox {
        // should we assert coordinates?
        return IsometricBox{
            .points = .{
                top_front,
                bottom_front,
                top_left,
                top_right,
            },
        };
    }

    pub fn add(self: IsometricBox, v: rl.Vector2) IsometricBox {
        var points: [4]rl.Vector2 = undefined;
        for (&points, 0..) |*p, i| {
            p.* = self.points[i].add(v);
        }
        return .{ .points = points };
    }

    pub const Axis = enum { x, y, z };

    fn direction(self: IsometricBox, axis: Axis) rl.Vector2 {
        return switch (axis) {
            .x => self.getVertex(.top_right).subtract(self.getVertex(.top_front)),
            .y => self.getVertex(.bottom_front).subtract(self.getVertex(.top_front)),
            .z => self.getVertex(.top_front).subtract(self.getVertex(.top_left)),
        };
    }

    pub const VertexName = enum {
        top_front,
        top_back,
        top_left,
        top_right,
        bottom_front,
        bottom_back,
        bottom_left,
        bottom_right,
    };

    pub fn getVertex(self: IsometricBox, vertex_name: VertexName) rl.Vector2 {
        return switch (vertex_name) {
            .top_front => self.points[0],
            .top_back => self.getVertex(.top_left)
                .add(self.direction(.x)),
            .top_left => self.points[2],
            .top_right => self.points[3],
            .bottom_front => self.points[1],
            .bottom_back => self.getVertex(.top_back).add(self.direction(.y)),
            .bottom_left => self.getVertex(.top_left).add(self.direction(.y)),
            .bottom_right => self.getVertex(.top_right).add(self.direction(.y)),
        };
    }

    pub fn setVertex(self: *IsometricBox, vertex_name: VertexName, value: rl.Vector2) void {
        const offset = value.subtract(self.getVertex(vertex_name));
        _ = switch (vertex_name) {
            .top_front => self.points[0] = value,
            .top_back => self.setVertex(.top_front, self.getVertex(.top_front).add(offset.scale(-1))),
            .top_left => self.points[2] = value,
            .top_right => self.points[3] = value,
            .bottom_front => self.points[1] = value,
            .bottom_back => self.setVertex(.top_back, value.subtract(self.direction(.y))),
            .bottom_left => self.setVertex(.top_front, self.getVertex(.top_front).add(offset.scale(-1))),
            .bottom_right => self.setVertex(.top_front, self.getVertex(.top_front).add(offset.scale(-1))),
        };
    }

    pub fn center(self: IsometricBox) rl.Vector2 {
        return self.getVertex(.top_left)
            .add(self.direction(.x).scale(0.5))
            .add(self.direction(.y).scale(0.5))
            .add(self.direction(.z).scale(0.5));
    }

    pub fn getBoundingBox(self: IsometricBox) rl.Rectangle {
        var min_x: f32 = std.math.inf(f32);
        var min_y: f32 = std.math.inf(f32);
        var max_x: f32 = -std.math.inf(f32);
        var max_y: f32 = -std.math.inf(f32);

        for (std.enums.values(VertexName)) |v_name| {
            const p = self.getVertex(v_name);
            if (p.x < min_x) min_x = p.x;
            if (p.x > max_x) max_x = p.x;
            if (p.y < min_y) min_y = p.y;
            if (p.y > max_y) max_y = p.y;
        }

        return rl.Rectangle.init(min_x, min_y, max_x - min_x, max_y - min_y);
    }

    // RENDER
    pub fn drawHandles(
        self: IsometricBox,
        position: rl.Vector2,
        color: rl.Color,
    ) void {
        const ib = self.add(position);
        drawPointHandle(ib.getVertex(.top_front), color);
        drawPointHandle(ib.getVertex(.top_back), color);
        drawPointHandle(ib.getVertex(.bottom_left), color);
        drawPointHandle(ib.getVertex(.bottom_right), color);

        drawSquareHandle(ib.getVertex(.top_right), color);
        drawSquareHandle(ib.getVertex(.bottom_front), color);
        drawSquareHandle(ib.getVertex(.top_left), color);

        drawCrossHandle(ib.center(), color);
    }

    pub fn drawMeshEx(
        self: IsometricBox,
        position: rl.Vector2,
        thick: f32,
        color: rl.Color,
    ) void {
        const opacity = 0.3;
        const ib = self.add(position);
        // Top Plane
        rl.drawLineEx(
            ib.getVertex(.top_front),
            ib.getVertex(.top_left),
            thick,
            color,
        );
        rl.drawLineEx(
            ib.getVertex(.top_left),
            ib.getVertex(.top_back),
            thick,
            color,
        );
        rl.drawLineEx(
            ib.getVertex(.top_back),
            ib.getVertex(.top_right),
            thick,
            color,
        );
        rl.drawLineEx(
            ib.getVertex(.top_right),
            ib.getVertex(.top_front),
            thick,
            color,
        );

        // Heights
        rl.drawLineEx(
            ib.getVertex(.top_front),
            ib.getVertex(.bottom_front),
            thick,
            color,
        );
        rl.drawLineEx(
            ib.getVertex(.top_left),
            ib.getVertex(.bottom_left),
            thick,
            color,
        );
        rl.drawLineEx(
            ib.getVertex(.top_right),
            ib.getVertex(.bottom_right),
            thick,
            color,
        );
        rl.drawLineEx(
            ib.getVertex(.top_back),
            ib.getVertex(.bottom_back),
            thick,
            Color.multiply(color, opacity),
        );

        // Bottom Plane
        rl.drawLineEx(
            ib.getVertex(.bottom_front),
            ib.getVertex(.bottom_left),
            thick,
            color,
        );
        rl.drawLineEx(
            ib.getVertex(.bottom_left),
            ib.getVertex(.bottom_back),
            thick,
            Color.multiply(color, opacity),
        );
        rl.drawLineEx(
            ib.getVertex(.bottom_back),
            ib.getVertex(.bottom_right),
            thick,
            Color.multiply(color, opacity),
        );
        rl.drawLineEx(
            ib.getVertex(.bottom_right),
            ib.getVertex(.bottom_front),
            thick,
            color,
        );
    }

    pub fn drawMesh(
        self: IsometricBox,
        position: rl.Vector2,
        color: rl.Color,
    ) void {
        return drawMeshEx(
            self,
            position,
            1,
            color,
        );
    }
    pub fn drawBoundingBox(
        self: IsometricBox,
        position: rl.Vector2,
        color: rl.Color,
    ) void {
        var bbox = self.getBoundingBox();
        bbox.x += position.x;
        bbox.y += position.y;
        rl.drawRectangleLinesEx(bbox, 1, color);
        drawSquareHandle(rl.Vector2.init(bbox.x, bbox.y), color);
        drawSquareHandle(rl.Vector2.init(bbox.x + bbox.width, bbox.y), color);
        drawSquareHandle(rl.Vector2.init(bbox.x, bbox.y + bbox.height), color);
        drawSquareHandle(rl.Vector2.init(bbox.x + bbox.width, bbox.y + bbox.height), color);
    }
};

pub fn drawPointHandle(position: rl.Vector2, color: rl.Color) void {
    rl.drawCircleV(position, 1.5, color);
    rl.drawCircleV(
        position,
        1,
        Color.copyAlpha(color, rl.Color.white),
    );
}

pub fn drawSquareHandle(position: rl.Vector2, color: rl.Color) void {
    rl.drawRectangleV(
        position.subtractValue(1.25),
        rl.Vector2.one().scale(2.5),
        color,
    );
    rl.drawRectangleV(
        position.subtractValue(1),
        rl.Vector2.one().scale(2),
        Color.copyAlpha(color, rl.Color.white),
    );
}

pub fn drawCrossHandle(position: rl.Vector2, color: rl.Color) void {
    rl.drawLineEx(
        position.subtract(rl.Vector2.init(0, 3)),
        position.add(rl.Vector2.init(0, 3)),
        0.5,
        color,
    );
    rl.drawLineEx(
        position.subtract(rl.Vector2.init(3, 0)),
        position.add(rl.Vector2.init(3, 0)),
        0.5,
        color,
    );
    rl.drawCircleV(
        position,
        1,
        Color.copyAlpha(color, rl.Color.white),
    );
}
pub const Color = struct {
    pub fn multiply(color: rl.Color, s: f32) rl.Color {
        return rl.Color.init(
            color.r,
            color.g,
            color.b,
            @as(u8, @intFromFloat(@as(f32, @floatFromInt(color.a)) * s)),
        );
    }

    pub fn copyAlpha(from: rl.Color, to: rl.Color) rl.Color {
        return rl.Color.init(
            to.r,
            to.g,
            to.b,
            from.a,
        );
    }
};
