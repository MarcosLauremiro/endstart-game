class_name TestMultiSelect
extends TestCase
## Seleção por arraste: colonos no retângulo, convocar e mandar o grupo, árvores, rochas e plantas
## do retângulo com Cortar, Minerar e Colher, opções juntas de uma área (uma por alvo, mesmo em
## construções de vários tiles) e o painel de seleção.

const _SEED := 12345


func test_drag_picks_the_colonists_inside() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var state := simulation.state
	var area := _around(state.colonists.map(func(c: Colonist) -> Vector2i: return c.cell))
	expect_equal(MultiSelect.colonists_in(state, area).size(), 3, "Os três colonos estão no retângulo")
	var first := state.colonists[0]
	expect_equal(MultiSelect.colonists_in(state, Rect2i(first.cell, Vector2i.ONE)), [first.id] as Array[int], "Um tile só pega quem está nele")


func test_group_drafts_and_dispenses_together() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var ids := _ids(simulation)
	expect_equal(MultiSelect.colonist_options(simulation, ids)[0]["label"], "Convocar todos (V)", "Primeira opção: convocar todos")
	expect_equal(MultiSelect.draft_group(simulation, ids), "3 colono(s) convocados", "Convoca o grupo")
	expect(simulation.state.colonists.all(func(c: Colonist) -> bool: return c.drafted), "Todos convocados")
	expect_equal(MultiSelect.colonist_options(simulation, ids)[0]["label"], "Dispensar todos (V)", "Agora dispensar")
	MultiSelect.draft_group(simulation, ids)
	expect(simulation.state.colonists.all(func(c: Colonist) -> bool: return not c.drafted), "Todos dispensados")


func test_group_move_spreads_around_the_point() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var state := simulation.state
	var target := SimHelpers.clear_area(simulation, Vector2i(3, 3)) + Vector2i.ONE
	MultiSelect.order_group(simulation, _ids(simulation), target)
	var destinations := {}
	for colonist in state.colonists:
		expect(colonist.direct_order != null and colonist.direct_order.kind == Action.Kind.MOVE, "%s recebeu a ordem de ir" % colonist.display_name)
		if colonist.direct_order:
			destinations[colonist.direct_order.target_cell] = true
			expect(Vector2(colonist.direct_order.target_cell).distance_to(Vector2(target)) <= 2.0, "Destino perto do ponto clicado")
	expect_equal(destinations.size(), 3, "Cada um vai para um tile diferente")
	expect(destinations.has(target), "Um deles vai ao ponto exato")
	MultiSelect.colonist_options(simulation, _ids(simulation))
	var cancel := MultiSelect.colonist_options(simulation, _ids(simulation)).filter(
		func(o: Dictionary) -> bool: return o["label"] == "Cancelar ordens")
	expect_equal(cancel.size(), 1, "Com ordens, aparece cancelar ordens")
	cancel[0]["run"].call()
	expect(state.colonists.all(func(c: Colonist) -> bool: return c.direct_order == null), "Cancelar ordens limpa o grupo")


func test_area_options_join_every_target() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var cells: Array = state.trees.values().slice(0, 4).map(func(t: WildTree) -> Vector2i: return t.cell)
	var area := _around(cells)
	var trees := 0
	for tree in state.trees.values():
		if area.has_point(tree.cell):
			trees += 1
	var resources := MultiSelect.resources_in(state, area)
	expect(resources.all(func(cell: Vector2i) -> bool: return MultiSelect.is_resource(state, cell)), "Só árvores, rochas e plantas")
	var options := MultiSelect.options_for_cells(simulation, resources, true)
	var allowed := options.all(func(o: Dictionary) -> bool:
		return MultiSelect.RESOURCE_LABELS.any(func(l: String) -> bool: return o["label"] == l or (o["label"] as String).begins_with(l + " (")))
	expect(allowed, "Só Cortar, Minerar e Colher (havia %s)" % [options.map(func(o: Dictionary) -> String: return o["label"])])
	var cut := _find(options, "Cortar")
	expect_equal(cut.get("label", ""), "Cortar (%d)" % trees, "Uma opção para todas as árvores selecionadas")
	expect(MultiSelect.summary(state, resources).contains("%d árvores" % trees), "O resumo conta as árvores")
	expect_equal(cut["run"].call(), "Cortar: %d" % trees, "Executa em todas")
	for tree in state.trees.values():
		if area.has_point(tree.cell):
			var task := state.task_board.designation_at(tree.cell)
			expect(task != null and task.kind == Task.Kind.CUT, "Árvore em (%d, %d) marcada" % [tree.cell.x, tree.cell.y])
	expect_equal(_find(MultiSelect.options_for_cells(simulation, resources, true), "Cancelar corte").get("label", ""), "Cancelar corte (%d)" % trees,
		"Depois, cancelar todas")


func test_big_structure_counts_once() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(2, 2))
	state.add_container(&"material_yard", origin)
	var cells := MultiSelect.area_cells(state, Rect2i(origin, Vector2i(2, 2)))
	expect(MultiSelect.resources_in(state, Rect2i(origin, Vector2i(2, 2))).is_empty(), "Sem árvores nem rochas: vale a área inteira")
	var options := MultiSelect.options_for_cells(simulation, cells)
	var labels := options.map(func(o: Dictionary) -> String: return o["label"])
	expect(labels.has("Desmontar: Pátio de materiais"), "O pátio de 4 tiles dá uma opção só, sem contagem (havia %s)" % [labels])
	expect(not labels.has("Criar plantação aqui"), "Área não oferece criar plantação tile a tile")
	expect_equal(MultiSelect.summary(state, cells), "1 pátio de materiais", "Resumo conta o pátio uma vez")


func test_spread_cells_are_walkable_and_distinct() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var center := SimHelpers.clear_area(simulation, Vector2i(3, 3)) + Vector2i.ONE
	var cells := MultiSelect.spread_cells(state, center, 5)
	expect_equal(cells.size(), 5, "Acha 5 tiles")
	expect_equal(cells[0], center, "O primeiro é o ponto clicado")
	var unique := {}
	for cell in cells:
		unique[cell] = true
		expect(state.navigation.is_walkable(cell), "Tile andável")
	expect_equal(unique.size(), 5, "Todos diferentes")


func test_selection_panel_lists_the_group() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var panel := SelectionPanel.new()
	panel._ready()
	panel.show_colonists(simulation, _ids(simulation))
	expect_equal(panel._title.text, "3 colonos selecionados", "Título do grupo")
	expect_equal(panel._list.get_child_count(), 3, "Um botão por colono")
	var chosen: Array[int] = []
	panel.colonist_chosen.connect(func(id: int) -> void: chosen.append(id))
	(panel._list.get_child(1) as Button).pressed.emit()
	expect_equal(chosen, [simulation.state.colonists[1].id] as Array[int], "Clicar no nome seleciona só ele")
	var area := Rect2i(SimHelpers.clear_area(simulation, Vector2i(2, 2)), Vector2i(2, 2))
	panel.show_area(simulation, area)
	expect_equal(panel._title.text, "Área 2×2", "Título da área")
	expect(not panel._scroll.visible and panel._summary.visible, "Área mostra o resumo, não a lista")
	var state := simulation.state
	var tree: WildTree = state.trees.values()[0]
	var rock := Vector2i(-1, -1)
	for y in state.world.size.y:
		for x in state.world.size.x:
			if rock.x < 0 and state.world.get_terrain(Vector2i(x, y)) == Terrain.Kind.ROCK:
				rock = Vector2i(x, y)
	var picked: Array[Vector2i] = [tree.cell, rock]
	panel.show_area(simulation, Rect2i(tree.cell, Vector2i.ONE), picked)
	expect_equal(panel._title.text, "2 selecionados", "Título com quantos recursos")
	var labels := panel._actions.get_children().map(func(b: Button) -> String: return b.text)
	expect_equal(labels, ["Cortar", "Minerar"], "Árvore e rocha: Cortar e Minerar, nessa ordem")
	panel.free()


func _ids(simulation: Simulation) -> Array[int]:
	var ids: Array[int] = []
	for colonist in simulation.state.colonists:
		ids.append(colonist.id)
	return ids


func _around(cells: Array) -> Rect2i:
	var area := Rect2i(cells[0], Vector2i.ONE)
	for cell: Vector2i in cells:
		area = area.expand(cell)
	area.size += Vector2i.ONE
	return area


func _find(options: Array[Dictionary], prefix: String) -> Dictionary:
	for option in options:
		if (option["label"] as String).begins_with(prefix + " (") or option["label"] == prefix:
			return option
	return {}


func test_plural_names() -> void:
	expect_equal(MultiSelect.plural("lebre"), "lebres", "lebre")
	expect_equal(MultiSelect.plural("parede antiga"), "paredes antigas", "parede antiga")
	expect_equal(MultiSelect.plural("pátio de materiais"), "pátios de materiais", "pátio de materiais")
	expect_equal(MultiSelect.plural("baú rústico"), "baús rústicos", "baú rústico")
	expect_equal(MultiSelect.plural("cama rústica"), "camas rústicas", "cama rústica")
