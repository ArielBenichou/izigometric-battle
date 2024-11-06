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

/// This is a set of 4 points to describe any type of isometric 2.5d tile
pub const IsometricBox = struct {
    // TODO: chagne data struct to be an [4]rl.Vector2 array
    // TODO: create an enum for all 8 points names, for easier access - read write
    //      - meaning the array should be abstracted be an enum
    // then we can remove the meta programming and just use an array to loop and access stuff
    //      - making the extension of 3 more handles possible easily
    top_front: rl.Vector2,
    bottom_front: rl.Vector2,
    top_left: rl.Vector2,
    top_right: rl.Vector2,

    pub fn init(
        top_front: rl.Vector2,
        bottom_front: rl.Vector2,
        top_left: rl.Vector2,
        top_right: rl.Vector2,
    ) IsometricBox {
        // should we assert coordinates?
        return .{
            .top_front = top_front,
            .bottom_front = bottom_front,
            .top_left = top_left,
            .top_right = top_right,
        };
    }

    const FieldAccessError = error{FieldNameInvalid};

    pub fn setField(self: *@This(), field_name: []const u8, value: rl.Vector2) FieldAccessError!void {
        if (std.mem.eql(u8, field_name, "top_front")) {
            self.top_front = value;
        } else if (std.mem.eql(u8, field_name, "bottom_front")) {
            self.bottom_front = value;
        } else if (std.mem.eql(u8, field_name, "top_left")) {
            self.top_left = value;
        } else if (std.mem.eql(u8, field_name, "top_right")) {
            self.top_right = value;
        } else {
            return FieldAccessError.FieldNameInvalid;
        }
    }

    pub fn getField(self: *@This(), field_name: []const u8) FieldAccessError!rl.Vector2 {
        if (std.mem.eql(u8, field_name, "top_front")) {
            return self.top_front;
        } else if (std.mem.eql(u8, field_name, "bottom_front")) {
            return self.bottom_front;
        } else if (std.mem.eql(u8, field_name, "top_left")) {
            return self.top_left;
        } else if (std.mem.eql(u8, field_name, "top_right")) {
            return self.top_right;
        }
        return FieldAccessError.FieldNameInvalid;
    }

    pub fn directionX(self: IsometricBox) rl.Vector2 {
        return self.top_right.subtract(self.top_front);
    }

    /// Y is UP!
    pub fn directionY(self: IsometricBox) rl.Vector2 {
        return self.bottom_front.subtract(self.top_front);
    }

    pub fn directionZ(self: IsometricBox) rl.Vector2 {
        return self.top_front.subtract(self.top_left);
    }

    pub fn center(self: IsometricBox) rl.Vector2 {
        return self.top_left
            .add(self.directionX().scale(0.5))
            .add(self.directionY().scale(0.5))
            .add(self.directionZ().scale(0.5));
    }

    pub fn topBack(self: IsometricBox) rl.Vector2 {
        return self.top_left.add(self.directionX());
    }

    pub fn bottomBack(self: IsometricBox) rl.Vector2 {
        return self.topBack().add(self.directionY());
    }

    pub fn bottomLeft(self: IsometricBox) rl.Vector2 {
        return self.top_left.add(self.directionY());
    }

    pub fn bottomRight(self: IsometricBox) rl.Vector2 {
        return self.top_right.add(self.directionY());
    }

    pub fn add(self: IsometricBox, v: rl.Vector2) IsometricBox {
        return IsometricBox.init(
            self.top_front.add(v),
            self.bottom_front.add(v),
            self.top_left.add(v),
            self.top_right.add(v),
        );
    }

    // RENDER
    // TODO: general question: should we always thrive to pass self and other stuff by ref?
    pub fn drawHandles(
        iso_box: IsometricBox,
        position: rl.Vector2,
        color: rl.Color,
    ) void {
        const ib = iso_box.add(position);
        drawPointHandle(ib.top_front, color);
        drawPointHandle(ib.bottom_front, color);
        drawPointHandle(ib.top_left, color);
        drawPointHandle(ib.top_right, color);
        drawCrossHandle(ib.center(), color);
    }

    pub fn drawBoundingBoxEx(
        iso_box: IsometricBox,
        position: rl.Vector2,
        thick: f32,
        color: rl.Color,
    ) void {
        const opacity = 0.3;
        const ib = iso_box.add(position);
        // Top Plane
        rl.drawLineEx(
            ib.top_front,
            ib.top_left,
            thick,
            color,
        );
        rl.drawLineEx(
            ib.top_left,
            ib.topBack(),
            thick,
            color,
        );
        rl.drawLineEx(
            ib.topBack(),
            ib.top_right,
            thick,
            color,
        );
        rl.drawLineEx(
            ib.top_right,
            ib.top_front,
            thick,
            color,
        );

        // Heights
        rl.drawLineEx(
            ib.top_front,
            ib.bottom_front,
            thick,
            color,
        );
        rl.drawLineEx(
            ib.top_left,
            ib.bottomLeft(),
            thick,
            color,
        );
        rl.drawLineEx(
            ib.top_right,
            ib.bottomRight(),
            thick,
            color,
        );
        rl.drawLineEx(
            ib.topBack(),
            ib.bottomBack(),
            thick,
            color.alpha(opacity),
        );

        // Bottom Plane
        rl.drawLineEx(
            ib.bottom_front,
            ib.bottomLeft(),
            thick,
            color,
        );
        rl.drawLineEx(
            ib.bottomLeft(),
            ib.bottomBack(),
            thick,
            color.alpha(opacity),
        );
        rl.drawLineEx(
            ib.bottomBack(),
            ib.bottomRight(),
            thick,
            color.alpha(opacity),
        );
        rl.drawLineEx(
            ib.bottomRight(),
            ib.bottom_front,
            thick,
            color,
        );
    }

    pub fn drawBoundingBox(
        iso_box: IsometricBox,
        position: rl.Vector2,
        color: rl.Color,
    ) void {
        return drawBoundingBoxEx(
            iso_box,
            position,
            1,
            color,
        );
    }
};

pub fn drawPointHandle(position: rl.Vector2, color: rl.Color) void {
    rl.drawCircleV(position, 2, rl.Color.white);
    rl.drawCircleLinesV(position, 3, color);
}

pub fn drawCrossHandle(position: rl.Vector2, color: rl.Color) void {
    rl.drawCircleV(position, 1, color);
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
}
