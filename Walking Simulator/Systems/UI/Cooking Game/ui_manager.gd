extends Control

signal retry_cooking
signal exit_cooking

@onready var loading_ui: Control = $LoadingOverlay
@onready var result_ui: Control = $ResultDialog
@onready var recipe_panel: Control = $RecipePanel
@onready var recipe_label: Label = $RecipePanel/Panel/Margin/VBox/ContentLabel
@onready var result_label: Label = $ResultDialog/Center/Panel/Margin/VBox/ResultLabel
@onready var retry_btn: Button = $ResultDialog/Center/Panel/Margin/VBox/Buttons/RetryButton
@onready var exit_btn: Button = $ResultDialog/Center/Panel/Margin/VBox/Buttons/ExitButton

func _ready() -> void:
    # pastikan state awal
    hide_loading()
    hide_result()
    recipe_panel.visible = true
    # connect tombol
    if not retry_btn.pressed.is_connected(_on_retry_pressed):
        retry_btn.pressed.connect(_on_retry_pressed)
    if not exit_btn.pressed.is_connected(_on_exit_pressed):
        exit_btn.pressed.connect(_on_exit_pressed)

# ---------------- Recipe
func set_recipe_text(text: String) -> void:
    if recipe_label:
        recipe_label.text = text
        recipe_panel.visible = true

func set_recipe_dict(recipe: Dictionary) -> void:
    var lines: Array[String] = []
    for k in recipe.keys():
        lines.append("- %s: %s" % [str(k), str(recipe[k])])
    set_recipe_text("\n".join(lines))

# Untuk kompatibilitas dengan cook_game_manager
func show_recipe_panel(text: String) -> void:
    set_recipe_text(text)

func hide_recipe_panel() -> void:
    recipe_panel.visible = false

# ---------------- Loading
func show_loading() -> void:
    loading_ui.visible = true
    loading_ui.mouse_filter = Control.MOUSE_FILTER_STOP

func hide_loading() -> void:
    loading_ui.visible = false
    loading_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE

# ---------------- Result
func show_result(success: bool) -> void:
    if result_label:
        if success:
            result_label.text = "Masakan Berhasil!\nResep cocok."
            result_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
        else:
            result_label.text = "Masakan Gagal!\nBahan tidak sesuai resep."
            result_label.add_theme_color_override("font_color", Color(0.95, 0.25, 0.25))
    result_ui.visible = true
    result_ui.mouse_filter = Control.MOUSE_FILTER_STOP

func hide_result() -> void:
    result_ui.visible = false
    result_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE

# ---------------- Buttons
func _on_retry_pressed() -> void:
    hide_result()        # resep tetap tampil
    emit_signal("retry_cooking")

func _on_exit_pressed() -> void:
    hide_result()
    emit_signal("exit_cooking")