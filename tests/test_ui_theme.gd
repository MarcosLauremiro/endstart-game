class_name TestUiTheme
extends TestCase
## Interface: escala própria na tela (independente do mapa) e fonte pixel Dogica sempre na grade
## de 8 px dela.


func test_ui_scale_and_font_stay_on_the_pixel_grid() -> void:
	expect_equal(UiTheme.ui_scale_for(2), 2, "Janela maximizada em 1080p (mapa ×2): interface ×2")
	expect_equal(UiTheme.ui_scale_for(3), 2, "Tela cheia 1080p (mapa ×3): interface continua ×2")
	expect_equal(UiTheme.ui_scale_for(6), 4, "4K: interface ×4")
	expect_equal(UiTheme.font_size_for(2), 4, "Em ×2 a fonte usa 4 unidades = 8 px na tela, o tamanho nativo")
	for screen in range(1, 7):
		var ui := UiTheme.ui_scale_for(screen)
		var size := UiTheme.font_size_for(ui)
		expect_equal(size * ui % UiTheme.FONT_GRID, 0, "Tela ×%d: fonte %d × interface ×%d cai na grade" % [screen, size, ui])


func test_screen_scale_matches_integer_stretch() -> void:
	expect_equal(UiTheme.screen_scale(Vector2i(1920, 1080)), 3, "1920×1080 é ×3")
	expect_equal(UiTheme.screen_scale(Vector2i(1920, 1009)), 2, "Maximizada com barra de tarefas: ×2")
	expect_equal(UiTheme.screen_scale(Vector2i(500, 300)), 1, "Nunca abaixo de ×1")
