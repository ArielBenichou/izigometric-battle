const std = @import("std");
const fs = std.fs;
const json = std.json;
const ArrayList = std.ArrayList;
const Vector2 = @import("raylib").Vector2;

pub const Tag = struct {
    name: []const u8,
    variant: []const u8,
    position: Vector2,
    scale: f32,
};

pub const Config = struct {
    prespective_points: []Vector2,
    tags: []Tag,

    pub fn deinit(self: *Config, allocator: std.mem.Allocator) void {
        allocator.free(self.prespective_points);
        allocator.free(self.tags);
    }
};

const ConfigData = struct {
    /// a list of f32-pairs, each should be a rl.Vector2
    prespective_points: []f32,
    tags: []struct {
        name: []const u8,
        variant: []const u8,
        /// rl.Vector2
        position: []f32,
        scale: f32,
    },
};

pub fn readConfig(allocator: std.mem.Allocator, path: []const u8) !Config {
    const data = try std.fs.cwd().readFileAlloc(
        allocator,
        path,
        512,
    );
    defer allocator.free(data);
    const parsed = try std.json.parseFromSlice(
        ConfigData,
        allocator,
        data,
        .{ .allocate = .alloc_always },
    );
    defer parsed.deinit();
    const config_data = parsed.value;

    // Convert the raw data into our structured format
    var config = Config{
        .prespective_points = try allocator.alloc(Vector2, config_data.prespective_points.len / 2),
        .tags = try allocator.alloc(Tag, config_data.tags.len),
    };

    // Convert flat array of f32 into Vector2 array
    for (0..config_data.prespective_points.len / 2) |i| {
        config.prespective_points[i] = .{
            .x = config_data.prespective_points[i * 2],
            .y = config_data.prespective_points[i * 2 + 1],
        };
    }

    // Convert tags
    for (config_data.tags, 0..) |tag, i| {
        config.tags[i] = .{
            .name = try allocator.dupe(u8, tag.name),
            .variant = try allocator.dupe(u8, tag.variant),
            .position = .{
                .x = tag.position[0],
                .y = tag.position[1],
            },
            .scale = tag.scale,
        };
    }

    return config;
}

pub fn writeConfig(allocator: std.mem.Allocator, config: Config, path: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{ .read = true });
    defer file.close();

    // First, convert our data to the intermediate format that matches the JSON structure
    var prespective_points = try ArrayList(f32).initCapacity(allocator, config.prespective_points.len * 2);
    defer prespective_points.deinit();

    // Convert Vector2 array to flat f32 array
    for (config.prespective_points) |point| {
        try prespective_points.append(point.x);
        try prespective_points.append(point.y);
    }

    // Create the tags array in the format we want to write
    const JsonTag = struct {
        name: []const u8,
        variant: []const u8,
        position: [2]f32,
        scale: f32,
    };

    var tags = try ArrayList(JsonTag).initCapacity(allocator, config.tags.len);
    defer tags.deinit();

    for (config.tags) |tag| {
        try tags.append(.{
            .name = tag.name,
            .variant = tag.variant,
            .position = .{ tag.position.x, tag.position.y },
            .scale = tag.scale,
        });
    }

    // Create the root object that matches our desired JSON structure
    const root = .{
        .prespective_points = prespective_points.items,
        .tags = tags.items,
    };

    var string = std.ArrayList(u8).init(allocator);
    try std.json.stringify(root, .{ .whitespace = .indent_2 }, string.writer());

    _ = try file.writeAll(string.items);
}
