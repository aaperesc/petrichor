package app

import "core:fmt"
import "core:os"
import "core:strings"

import rl "vendor:raylib"

app_name : cstring = "Petrichor"
font_size : i32 = 20
initial_window_height : i32 = 1080

run :: proc() {
    fmt.println("Running app")

    rl.SetConfigFlags({ .WINDOW_RESIZABLE })
    rl.InitWindow(1920, initial_window_height, app_name)

    visible_rows := initial_window_height/font_size
    fmt.println("Visible rows:", visible_rows)

    font := rl.LoadFontEx("resources/fonts/CascadiaMono.ttf", font_size, nil, 250)

    data, ok := os.read_entire_file("source/app/app.odin", context.allocator)
    if !ok {
        fmt.println("could not read file")
        return
    }

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        data_it := string(data)

        index : i32 = 0
        for line in strings.split_lines_iterator(&data_it) {
            cs := strings.clone_to_cstring(line, context.temp_allocator)
            rl.DrawTextEx(font, cs, { 0, f32(index * font_size) }, f32(font_size), 2, rl.LIGHTGRAY)
            index += 1
        }

        rl.EndDrawing()
    }

    delete(data, context.allocator)
    rl.CloseWindow()
}
