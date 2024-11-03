const rl = @import("raylib");
const color = rl.Color.magenta;
const line_thickness = 1.5;

pub fn drawGizmo(pos: rl.Vector2) void {
    const gizmo_line_len: f32 = 25;
    rl.drawLineEx(
        pos.subtract(.{ .y = gizmo_line_len, .x = 0 }),
        pos.add(.{ .y = gizmo_line_len, .x = 0 }),
        line_thickness,
        color,
    );
    rl.drawLineEx(
        pos.subtract(.{ .y = 0, .x = gizmo_line_len }),
        pos.add(.{ .y = 0, .x = gizmo_line_len }),
        line_thickness,
        color,
    );
    drawDot(pos);
}

pub fn drawMarqueeSelectionBox(pos: rl.Vector2, size: rl.Vector2) void {
    rl.drawRectangleLinesEx(
        rl.Rectangle.init(pos.x, pos.y, size.x, size.y),
        line_thickness,
        color,
    );
    drawDot(pos);
    drawDot(pos.add(.{ .x = size.x, .y = 0 }));
    drawDot(pos.add(.{ .x = size.x, .y = size.y }));
    drawDot(pos.add(.{ .x = 0, .y = size.y }));
}

fn drawDot(pos: rl.Vector2) void {
    rl.drawCircleV(pos, 3.5, rl.Color.white);
    rl.drawCircleV(pos, 2, color);
}
