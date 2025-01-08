const std = @import("std");
const stdout = std.io.getStdOut().writer();
const Connection = std.net.Server.Connection;

pub fn send_200(conn: Connection) !void {
    const cwd = try std.fs.cwd().realpathAlloc(std.heap.page_allocator, ".");
    defer std.heap.page_allocator.free(cwd);
    try stdout.print("Current working directory: {s}\n", .{cwd});

    var file = try std.fs.cwd().openFile("src/static/index.html", .{});
    defer file.close();

    const file_size = try file.getEndPos();

    const content = try std.heap.page_allocator.alloc(u8, file_size);
    defer std.heap.page_allocator.free(content);
    _ = try file.readAll(content);

    const response = try std.fmt.allocPrint(std.heap.page_allocator, "HTTP/1.1 200 OK\r\n" ++
        "Content-Length: {d}\r\n" ++
        "Content-Type: text/html\r\n" ++
        "Connection: keep-alive\r\n" ++
        "\r\n" ++
        "{s}", .{
        content.len,
        content,
    });
    defer std.heap.page_allocator.free(response);

    _ = try conn.stream.write(response);
}

pub fn send_404(conn: Connection) !void {
    try stdout.print("Sending 404 response\n", .{});

    const message = ("HTTP/1.1 404 Not Found\nContent-Length: 50" ++
        "\nContent-Type: text/html\n" ++
        "Connection: Closed\n\n<html><body>" ++
        "<h1>File not found!</h1></body></html>");

    _ = try conn.stream.write(message);
}
