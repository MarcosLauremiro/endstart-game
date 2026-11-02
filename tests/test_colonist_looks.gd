class_name TestColonistLooks
extends TestCase
## Aparência dos colonos (ColonistLooks): cabelo pela idade, variedade de pele, cabelo e roupa,
## quadros alinhados entre base, cabelo e roupa nas 4 direções, troca de paleta, composição,
## a camada do mapa e o arquivo salvo.

const _SEED := 12345


func test_hair_matches_age() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for age in range(Balance.COLONIST_MIN_AGE, Balance.COLONIST_MAX_AGE + 1):
		expect(not ColonistLooks.styles_for_age(age).is_empty(), "Toda idade tem cabelo possível (%d anos)" % age)
		for _i in 20:
			var looks := ColonistLooks.generate(rng, age)
			var style: Dictionary = ColonistLooks.HAIR_STYLES[looks.hair_style]
			if age < style["min_age"] or age > style["max_age"]:
				failures.append("%s com %d anos" % [style["name"], age])
			if age < 40 and looks.hair_color in [ColonistLooks.GRAY, ColonistLooks.WHITE]:
				failures.append("Cabelo %s com %d anos" % [ColonistLooks.HAIR_COLORS[looks.hair_color]["name"], age])
	expect(not ColonistLooks.styles_for_age(20).has(_style("Calvo")), "Jovem não fica calvo")
	expect(not ColonistLooks.styles_for_age(65).has(_style("Moicano")), "Moicano não aparece aos 65")
	expect(ColonistLooks.styles_for_age(65).has(_style("Calvo")), "Calvo é possível aos 65")


func test_variety() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var seen := {"skin": {}, "style": {}, "hair_color": {}, "top": {}, "bottom": {}, "cloth_color": {}}
	var gray := 0
	for i in 400:
		var age := 16 + i % 55
		var looks := ColonistLooks.generate(rng, age)
		seen["skin"][looks.skin_tone] = true
		seen["style"][looks.hair_style] = true
		seen["hair_color"][looks.hair_color] = true
		seen["top"][looks.top] = true
		seen["bottom"][looks.bottom] = true
		seen["cloth_color"][looks.top_color] = true
		if age >= 60 and looks.hair_color in [ColonistLooks.GRAY, ColonistLooks.WHITE]:
			gray += 1
		expect(looks.top < ColonistLooks.FIRST_BOTTOM_ROW and looks.bottom >= ColonistLooks.FIRST_BOTTOM_ROW, "Peça de cima em cima e de baixo embaixo")
	expect_equal(seen["skin"].size(), ColonistLooks.SKIN_TONES.size(), "Todos os tons de pele aparecem")
	expect_equal(seen["style"].size(), ColonistLooks.HAIR_STYLES.size(), "Todos os 20 cabelos aparecem")
	expect_equal(seen["hair_color"].size(), ColonistLooks.HAIR_COLORS.size(), "Todas as cores de cabelo aparecem")
	expect_equal(seen["top"].size(), ColonistLooks.FIRST_BOTTOM_ROW, "As 4 peças de cima aparecem")
	expect_equal(seen["bottom"].size(), ColonistLooks.CLOTHING_NAMES.size() - ColonistLooks.FIRST_BOTTOM_ROW, "As 3 de baixo aparecem")
	expect_equal(seen["cloth_color"].size(), ColonistLooks.CLOTHING_COLORS.size(), "Todas as cores de roupa aparecem")
	expect(gray > 0, "Há grisalhos e brancos entre os mais velhos")


func test_layers_use_the_same_pose_as_the_body() -> void:
	var base := AssetCatalog.texture(ColonistLooks.BASE_SHEET).get_size()
	var hair := AssetCatalog.texture(ColonistLooks.HAIR_SHEET).get_size()
	expect_equal(Vector2i(hair) / ColonistLooks.FRAME_SIZE, Vector2i(1 + 4 * ColonistLooks.WALK_FRAMES, ColonistLooks.HAIR_STYLES.size()),
		"Cabelo: 33 quadros por estilo, um estilo por linha")
	var clothing := AssetCatalog.texture(ColonistLooks.CLOTHING_SHEET).get_size()
	expect_equal(int(clothing.y) / ColonistLooks.FRAME_SIZE.y, ColonistLooks.CLOTHING_NAMES.size(), "Uma linha por peça de roupa")
	for facing in ColonistLooks.Facing.values():
		for frame in ColonistLooks.WALK_FRAMES:
			for moving in [true, false]:
				var body := ColonistLooks.base_region(facing, frame, moving)
				expect(Rect2(Vector2.ZERO, base).encloses(body), "Quadro do corpo dentro da folha")
				var layer := ColonistLooks.layer_region(ColonistLooks.HAIR_STYLES.size() - 1, facing, frame, moving)
				expect(Rect2(Vector2.ZERO, hair).encloses(layer), "Quadro do cabelo dentro da folha")
				# A coluna da camada é a posição do quadro da base na sequência (parado + 4 × 8).
				var body_index := 0 if body.position.y == 0 else 1 + (int(body.position.y) / 24 - 1) * 8 + int(body.position.x) / 16
				expect_equal(int(layer.position.x) / 16, body_index, "Mesma pose em todas as camadas")
	expect_equal(ColonistLooks.layer_region(0, ColonistLooks.Facing.RIGHT, 7, true).position.x, 32.0 * 16, "Último quadro da direita é a coluna 32")
	expect_equal(ColonistLooks.facing_of(Vector2i(5, 5), Vector2i(6, 5)), ColonistLooks.Facing.RIGHT, "Passo para a direita")
	expect_equal(ColonistLooks.facing_of(Vector2i(5, 5), Vector2i(5, 4)), ColonistLooks.Facing.BACK, "Passo para cima mostra as costas")
	expect_equal(ColonistLooks.facing_of(Vector2i(5, 5), Vector2i(4, 6)), ColonistLooks.Facing.LEFT, "Diagonal vale o lado")
	expect(ColonistLooks.facing_of(Vector2i(5, 5), Vector2i(5, 5)) == null, "Parado mantém o lado")


func test_composition_recolors_without_moving_pixels() -> void:
	var looks := ColonistAppearance.new()
	looks.hair_style = _style("Longo liso")
	var first := ColonistLooks.compose(looks, ColonistLooks.Facing.FRONT, 0, false)
	looks.hair_color = 4
	looks.skin_tone = 6
	var second := ColonistLooks.compose(looks, ColonistLooks.Facing.FRONT, 0, false)
	var same_shape := true
	var recolored := 0
	for y in first.get_height():
		for x in first.get_width():
			if (first.get_pixel(x, y).a > 0.0) != (second.get_pixel(x, y).a > 0.0):
				same_shape = false
			if first.get_pixel(x, y) != second.get_pixel(x, y):
				recolored += 1
	expect(same_shape, "Trocar cores não move nenhum pixel")
	expect(recolored > 50, "Pele e cabelo mudaram de cor (%d pixels)" % recolored)
	var hair_ramp: Array = ColonistLooks.HAIR_COLORS[4]["ramp"]
	var found := false
	for y in second.get_height():
		for x in second.get_width():
			if hair_ramp.has(second.get_pixel(x, y)):
				found = true
	expect(found, "O cabelo usa a rampa ruiva")
	var naked := ColonistLooks.compose(looks, ColonistLooks.Facing.FRONT, 0, false, false, false)
	expect(naked.get_data() != second.get_data(), "Sem camisa e calça, a roupa não aparece")


func test_colonists_get_looks_and_keep_them_when_saved() -> void:
	var simulation := Simulation.new(_SEED, 5)
	var again := Simulation.new(_SEED, 5)
	for index in 5:
		var looks := simulation.state.colonists[index].appearance
		var twin := again.state.colonists[index].appearance
		expect(looks.hair_style == twin.hair_style and looks.skin_tone == twin.skin_tone, "Mesma seed, mesma aparência")
		expect(ColonistLooks.styles_for_age(simulation.state.colonists[index].age).has(looks.hair_style), "Cabelo combina com a idade")
	var loaded := SaveGame.restore(SaveGame.snapshot(simulation.state))
	var original := simulation.state.colonists[0].appearance
	var restored := loaded.colonists[0].appearance
	expect(restored is ColonistAppearance and restored.hair_style == original.hair_style and restored.top_color == original.top_color,
		"A aparência vai para o arquivo salvo")


func test_view_builds_aligned_layers_and_turns_with_the_step() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var view := ColonistsView.new()
	view.sync(simulation.state.colonists, [] as Array[int], 0)
	var figure: Node2D = view._sprites[colonist.id]
	for layer_name in ["Base", "Bottom", "Top", "Hair"]:
		var layer: Sprite2D = figure.get_node(layer_name)
		expect_equal(layer.region_rect.size, Vector2(ColonistLooks.FRAME_SIZE), "%s no quadro de 16×24" % layer_name)
	expect_equal((figure.get_node("Base") as Sprite2D).region_rect.position, Vector2.ZERO, "Parado de frente: quadro parado")
	expect(figure.get_node("Top").visible and figure.get_node("Bottom").visible, "Começa vestido")
	colonist.path = [colonist.cell + Vector2i.RIGHT] as Array[Vector2i]
	view.sync(simulation.state.colonists, [] as Array[int], 30)
	var base: Sprite2D = figure.get_node("Base")
	var hair: Sprite2D = figure.get_node("Hair")
	expect_equal(int(base.region_rect.position.y) / 24, 1 + ColonistLooks.Facing.RIGHT, "Andando para a direita usa a linha da direita")
	expect_equal(int(hair.region_rect.position.x) / 16, 1 + ColonistLooks.Facing.RIGHT * 8 + int(base.region_rect.position.x) / 16,
		"O cabelo acompanha o quadro do corpo")
	colonist.path = [] as Array[Vector2i]
	view.sync(simulation.state.colonists, [] as Array[int], 31)
	expect_equal(int(base.region_rect.position.y) / 24, 1 + ColonistLooks.Facing.RIGHT, "Parado, continua virado para a direita")
	colonist.equipment.clear(Equipment.Slot.SHIRT)
	view.sync(simulation.state.colonists, [] as Array[int], 32)
	expect(not figure.get_node("Top").visible, "Sem camisa, sem a peça de cima")
	view.free()


static func _style(style_name: String) -> int:
	for index in ColonistLooks.HAIR_STYLES.size():
		if ColonistLooks.HAIR_STYLES[index]["name"] == style_name:
			return index
	return -1
