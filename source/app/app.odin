package app

import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"

import rl "vendor:raylib"

app_name : cstring = "Petrichor"
font_size : i32 = 20
initial_window_width : i32 = 1280
initial_window_height : i32 = 720

visible_rows := initial_window_height/font_size

/* user interaction */
row_offset : i32 = 0

/* file information */
file_lines := 0

run :: proc() {
    fmt.println("Running app")

    rl.SetTargetFPS(0)

    rl.SetConfigFlags({ .WINDOW_RESIZABLE })
    rl.InitWindow(initial_window_width, initial_window_height, app_name)
    fmt.println("Visible rows:", visible_rows)

    font := rl.LoadFontEx("resources/fonts/CascadiaMono.ttf", font_size, nil, 250)
    rl.SetTextureFilter(font.texture, rl.TextureFilter.BILINEAR);

//    data, ok := os.read_entire_file("source/app/app.odin", context.allocator)
    data, ok := os.read_entire_file("resources/examples/plrabn12.txt", context.allocator)
    if !ok {
        fmt.println("could not read file")
        return
    }

    data_as_string := string(data)
    lines := strings.split_lines(data_as_string)
    file_lines = len(lines)
    file_lines_digits : int = int(math.floor(math.log10_f32(f32(file_lines))) + 1);

    for !rl.WindowShouldClose() {
        input()

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

            rl.DrawTextEx(font, cs, { 0, f32(line_number * font_size) }, f32(font_size), 2, rl.WHITE)

            line_number += 1
        }

        rl.EndDrawing()
    }

    delete(data, context.allocator)
    rl.CloseWindow()
}

input :: proc() {
    if (rl.IsKeyPressed(rl.KeyboardKey.DOWN) || rl.IsKeyPressedRepeat(rl.KeyboardKey.DOWN)) {
        row_offset += 100
        if row_offset > i32(file_lines) - 1 {
            row_offset = i32(file_lines) - 1
        }
    }

    if (rl.IsKeyPressed(rl.KeyboardKey.UP) || rl.IsKeyPressedRepeat(rl.KeyboardKey.UP)) {
        row_offset -= 100
        if row_offset < 0 {
            row_offset = 0
        }
    }

    fmt.println(row_offset)
}
