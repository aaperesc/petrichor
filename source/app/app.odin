package app

import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"

import rl "vendor:raylib"

app_name : cstring = "Petrichor"
font_size : i32 = 18
initial_window_width : i32 = 1280
initial_window_height : i32 = 720

/* */
font : rl.Font
lines : []string
file_lines_digits : int

visible_rows := initial_window_height/font_size

/* user interaction */
row_offset : i32 = 0
cursor_width : i32 // figure this out based on the font
cursor_position : rl.Vector2 = { 0, 0 } // measured in char slots not pixels

/* file information */
file_lines := 0

run :: proc() {
    fmt.println("Running app")

    rl.SetTargetFPS(120)

    rl.SetConfigFlags({ .WINDOW_RESIZABLE })
    rl.InitWindow(initial_window_width, initial_window_height, app_name)
    fmt.println("Visible rows:", visible_rows)

    font = rl.LoadFontEx("resources/fonts/CascadiaMono.ttf", font_size, nil, 250)
    rl.GenTextureMipmaps(&font.texture)
    rl.SetTextureFilter(font.texture, rl.TextureFilter.TRILINEAR);
    font_measures := rl.MeasureTextEx(font, " ", f32(font_size), 0)
    cursor_width = i32(font_measures.x)

    data, ok := os.read_entire_file("source/app/app.odin", context.allocator)
//    data, ok := os.read_entire_file("resources/examples/plrabn12.txt", context.allocator)
    if !ok {
        fmt.println("could not read file")
        return
    }

    data_as_string := string(data)
    lines = strings.split_lines(data_as_string)
    file_lines = len(lines)
    file_lines_digits = int(math.floor(math.log10_f32(f32(file_lines))) + 1);

    for !rl.WindowShouldClose() {
        input()
        draw()
    }

    delete(data, context.allocator)
    rl.CloseWindow()
}

draw :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    rl.DrawFPS(initial_window_width - 100, 0)

    line_number : i32 = 0
    for index in row_offset..<visible_rows + row_offset {
        if int(index) >= file_lines {
            continue
        }

        line := lines[index]

        sb := strings.builder_make()
        fmt.sbprintf(&sb, "%0*[1][0]i", int(index + 1), file_lines_digits)
        strings.write_string(&sb, "    ")
        strings.write_string(&sb, line)

        result := strings.to_string(sb)
        cs := strings.clone_to_cstring(result, context.temp_allocator)

        rl.DrawTextEx(font, cs, { 0, f32(line_number * font_size) }, f32(font_size), 0, rl.WHITE)

        line_number += 1
    }

    draw_cursor()

    rl.EndDrawing()
}

draw_cursor :: proc() {
    rl.DrawRectangleLines(
        i32(cursor_position.x + 4 + f32(file_lines_digits)) * cursor_width,
        i32(cursor_position.y) * font_size,
        cursor_width,
        font_size,
        { 255, 255, 255, 100 }
    )
}

row_over_cursor :: proc() -> int {
    return clamp(int(cursor_position.y) + int(row_offset), 0, len(lines) - 1)
}

right_limit :: proc() -> f32 {
    return f32(math.max(len(lines[row_over_cursor()]) - 1, 0))
}

input :: proc() {
    if rl.IsKeyPressed(.DOWN) || rl.IsKeyPressedRepeat(.DOWN) {
        if (rl.IsKeyDown(.LEFT_SUPER)) {
            offset_buffer(1, update_cursor = true)
        }
        else {
            move_cursor_vertically(1)
        }
    }

    if rl.IsKeyPressed(.UP) || rl.IsKeyPressedRepeat(.UP) {
        if (rl.IsKeyDown(.LEFT_SUPER)) {
            offset_buffer(-1, update_cursor = true)
        }
        else {
            move_cursor_vertically(-1)
        }
    }

    if rl.IsKeyPressed(.LEFT) || rl.IsKeyPressedRepeat(.LEFT) {
        move_cursor_horizontally(-1)
    }

    if rl.IsKeyPressed(.RIGHT) || rl.IsKeyPressedRepeat(.RIGHT) {
        move_cursor_horizontally(1)
    }
}

offset_buffer :: proc(offset : int, update_cursor : bool = false) {
    row_offset += i32(offset)

    if row_offset > i32(file_lines) - 1 {
        row_offset = i32(file_lines) - 1
    }

    if row_offset < 0 {
        row_offset = 0
    }

    if update_cursor {
        if int(i32(cursor_position.y) + row_offset) < len(lines) {
            move_cursor_vertically(0)
        }
        else {
            move_cursor_vertically(-1)
        }
    }
}

move_cursor_vertically :: proc(offset : int) {
    cursor_position.y += f32(offset)

    if cursor_position.y < 0 {
        cursor_position.y = 0
        offset_buffer(-1)
    }

    max_cursor_position_y := math.min(int(visible_rows), len(lines) - int(row_offset))
    if cursor_position.y > f32(max_cursor_position_y - 1) {
        cursor_position.y = f32(max_cursor_position_y - 1)
        if row_offset < i32(len(lines) - int(visible_rows)) {
            offset_buffer(1)
        }
    }

    if right_limit() != 0 {
        move_cursor_horizontally(0) // update horizontal limits
    }
}

move_cursor_horizontally :: proc(offset : int) {
    cursor_position.x += f32(offset)

    if cursor_position.x < 0 {
        cursor_y_before := cursor_position.y
        row_offset_before := row_offset

        cursor_position.x = 0
        move_cursor_vertically(-1)

        if cursor_y_before != cursor_position.y || row_offset_before != row_offset_before {
            cursor_position.x = math.max(right_limit(), 0)
        }
        else {
            cursor_position.x = 0
        }
    }
    else if cursor_position.x > right_limit() {
        cursor_position.x = 0
        move_cursor_vertically(1)
    }
}
