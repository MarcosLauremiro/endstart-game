class_name TestUiTheme
extends TestCase
## Fonte da interface: tamanho escolhido pela escala inteira da janela, sempre na grade da fonte
## (tamanho × escala múltiplo de 12) e perto do alvo.


func test_font_size_stays_on_the_pixel_grid() -> void:
	expect_equal(UiTheme.font_size_for(2), 6, "Janela ×2 (1280×720 ou maximizada em 1080p): 6 px = 12 px na tela")
	expect_equal(UiTheme.font_size_for(3), 8, "Tela cheia 1080p (×3): 8 px = 24 px na tela")
	for scale in range(1, 7):
		var size := UiTheme.font_size_for(scale)
		expect_equal(size * scale % UiTheme.FONT_GRID, 0, "Escala %d: tamanho %d cai na grade da fonte" % [scale, size])


func test_screen_scale_matches_integer_stretch() -> void:
	expect_equal(UiTheme.screen_scale(Vector2i(1920, 1080)), 3, "1920×1080 é ×3")
	expect_equal(UiTheme.screen_scale(Vector2i(1920, 1009)), 2, "Maximizada com barra de tarefas: ×2")
	expect_equal(UiTheme.screen_scale(Vector2i(500, 300)), 1, "Nunca abaixo de ×1")
