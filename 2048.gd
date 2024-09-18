extends Control

var numbers = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
var numbers_back = []
var score = 0
var score_back = 0
var best_score = 0
const colors = ["#75878a", "#70f3ff", "#44cef6", "#3eede7", "#1685a9", "#177cb0", "#065279", "#003472", "#4b5cc4", "#4c8dae", "#2e4e7e", "#3b2e7e", "#4a4266", "#426666", "#425066", "#574266", "#8d4bbb", "#815463", "#815476", "#4c221b", "#003371", "#56004f", "#801dae"]
const npos = [-1, -1]
var game_over = false
var swipe_start = null

func new_pos():
    var free = []
    for i in 4:
        for j in 4:
            if numbers[i][j] == 0:
                free.append([i, j])

    if free.size() == 0:
        return npos
    return free[randi() % free.size()]


func merge(a, b, c, d):
    var out = [a, b, c, d]
    var i = 0;
    for j in 4:
        if out[j] != 0:
            out[i] = out[j]
            i += 1

    while i < 4:
        out[i] = 0
        i += 1

    if out[0] == out[1]:
        out[0] *= 2
        score += out[0]
        out[1] = out[2]
        out[2] = out[3]
        out[3] = 0
        if out[1] == out[2]:
            out[1] *= 2
            score += out[1]
            out[2] = 0
    else:
        if out[1] == out[2]:
            out[1] *= 2
            score += out[1]
            out[2] = out[3]
            out[3] = 0
        else:
            if out[2] == out[3]:
                out[2] *= 2
                score += out[2]
                out[3] = 0
    return out

func _ready() -> void:
    $body/GridContainer.set_columns(4)
    for i in 16:
        var label = Label.new()
        label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
        label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
        label.set_h_size_flags(SIZE_EXPAND_FILL)
        label.set_v_size_flags(SIZE_EXPAND_FILL)
        label.set("theme_override_font_sizes/font_size", 72)

        $body/GridContainer.add_child(label)
    restart()
    load_data("user://2048_autosave.json")

func move(direction):
    var old = numbers.duplicate(true)
    var old_score = score
    if direction == "up":
        for i in 4:
            var out = merge(numbers[0][i], numbers[1][i], numbers[2][i], numbers[3][i])
            numbers[0][i] = out[0]
            numbers[1][i] = out[1]
            numbers[2][i] = out[2]
            numbers[3][i] = out[3]
    elif direction == "down":
        for i in 4:
            var out = merge(numbers[3][i], numbers[2][i], numbers[1][i], numbers[0][i])
            numbers[3][i] = out[0]
            numbers[2][i] = out[1]
            numbers[1][i] = out[2]
            numbers[0][i] = out[3]
    elif direction == "left":
        for i in 4:
            var out = merge(numbers[i][0], numbers[i][1], numbers[i][2], numbers[i][3])
            numbers[i][0] = out[0]
            numbers[i][1] = out[1]
            numbers[i][2] = out[2]
            numbers[i][3] = out[3]
    elif direction == "right":
        for i in 4:
            var out = merge(numbers[i][3], numbers[i][2], numbers[i][1], numbers[i][0])
            numbers[i][3] = out[0]
            numbers[i][2] = out[1]
            numbers[i][1] = out[2]
            numbers[i][0] = out[3]
    best_score = max(best_score, score)
    if old != numbers: # change
        numbers_back = old.duplicate(true)
        score_back = old_score
        var pos = new_pos() # can not be npos
        var wait_list = [2, 2, 2, 2, 2, 4] # 5:1
        numbers[pos[0]][pos[1]] = wait_list[randi() % wait_list.size()]
    check_game_over()

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            swipe_start = event.position
        else:
            var swipe_end = event.position
            if swipe_start == null || swipe_end == null:
                return
            var swipe = swipe_end - swipe_start
            if abs(swipe.x) > abs(swipe.y) and abs(swipe.x) > 50:
                if swipe.x > 0:
                    move("right")
                else:
                    move("left")
            elif abs(swipe.y) > abs(swipe.x) and abs(swipe.y) > 50:
                if swipe.y > 0:
                    move("down")
                else:
                    move("up")
    if event.is_action_pressed("up"):
        move("up")
    elif event.is_action_pressed("down"):
        move("down")
    elif event.is_action_pressed("left"):
        move("left")
    elif event.is_action_pressed("right"):
        move("right")

func _process(delta: float) -> void:
    for i in 4:
        for j in 4:
            var label = $body/GridContainer.get_child(i * 4 + j)
            if numbers[i][j] > 0:
                label.set_text(str(numbers[i][j]))
            else:
                label.set_text("")
            var style = StyleBoxFlat.new()
            style.bg_color = Color(colors[color_index(numbers[i][j])])
            label.add_theme_stylebox_override("normal", style)
    $body/HBoxContainer/score.set_text(str(score))
    $body/HBoxContainer/VBoxContainer/HBoxContainer/best_score.set_text("Best\n" + str(best_score))
    if game_over:
        $body/HBoxContainer/VBoxContainer/HBoxContainer/best_score.set_text("Game\nOver !")

func _on_exit_pressed() -> void:
    get_tree().quit()


func _on_back_pressed() -> void:
    if numbers != numbers_back:
        numbers = numbers_back.duplicate(true)
        score = score_back
        game_over = false


func _on_restart_pressed() -> void:
    restart()

func restart():
    game_over = false
    score = 0
    numbers = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
    var pos = new_pos()
    numbers[pos[0]][pos[1]] = 2
    var pos2 = new_pos()
    numbers[pos2[0]][pos2[1]] = 2
    numbers_back = numbers.duplicate(true)

func _on_save_pressed() -> void:
    save("user://2048.json")

func _on_load_pressed() -> void:
    load_data("user://2048.json")

func load_data(file) -> void:
    var json_string = FileAccess.get_file_as_string(file)
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    if parse_result == OK:
        var data = json.data
        numbers = trans_numbers(data["numbers"])
        numbers_back = trans_numbers(data["numbers_back"])
        score = int(data["score"])
        best_score = int(data["best_score"])
    check_game_over()

func trans_numbers(arr):
    var ret = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
    for i in 4:
        for j in 4:
            ret[i][j] = int(arr[i][j])
    return ret

func color_index(value):
    if value == 0:
        return 0
    var idx = int(log(value) / log(2))
    if idx >= colors.size():
        return 0
    return idx

func check_game_over():
    game_over = false
    for i in 4:
        for j in 4:
            if numbers[i][j] == 0:
                return
    for i in 4:
        if numbers[i][0] == numbers[i][1] || numbers[i][1] == numbers[i][2] ||numbers[i][2] == numbers[i][3]:
            return
    for i in 4:
        if numbers[0][i] == numbers[1][i] || numbers[1][i] == numbers[2][i] ||numbers[2][i] == numbers[3][i]:
            return
    game_over = true


func _on_timer_timeout() -> void:
    save("user://2048_autosave.json")

func save(file):
    var save_file = FileAccess.open(file, FileAccess.WRITE)
    if save_file:
        var json_string = JSON.stringify({
            "numbers": numbers,
            "numbers_back": numbers, # can not back
            "score": score,
            "best_score": best_score
        })
        save_file.store_line(json_string)
