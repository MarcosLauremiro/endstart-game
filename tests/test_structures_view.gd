class_name TestStructuresView
extends TestCase
## Construções na tela: paredes escolhem o quadro pelos vizinhos (e ligam a portas, plantas e à
## prévia), ficam ordenadas com os colonos (quem está atrás some atrás do topo), toda construção
## sólida bloqueia o caminho e o botão do meio copia a construção do tile.

const _SEED := 12345


func test_walls_pick_the_frame_by_neighbors() -> void:
	var state := Simulation.new(_SEED, 1).state
	var wall := Defs.structure(&"wall_stone")
	expect_equal(AssetCatalog.frame_grid(wall.asset), Vector2i(16, 1), "16 quadros de parede")
	_build(state, &"wall_stone", Vector2i(10, 10))
	expect_equal(StructureArt.wall_mask(state, Vector2i(10, 10)), 0, "Parede sozinha")
	_build(state, &"wall_stone", Vector2i(11, 10))
	_build(state, &"wall_stone", Vector2i(10, 11))
	expect_equal(StructureArt.wall_mask(state, Vector2i(10, 10)), StructureArt.EAST | StructureArt.SOUTH, "Canto: leste e sul")
	expect_equal(StructureArt.region(state, wall, Vector2i(10, 10)), AssetCatalog.frame_region(wall.asset, 6, 0), "Quadro 6 = L 2 + S 4")
	_build(state, &"door_simple", Vector2i(12, 10))
	expect_equal(StructureArt.wall_mask(state, Vector2i(11, 10)), StructureArt.EAST | StructureArt.WEST, "Liga na porta")
	Construction.place(state, Defs.structure(&"wall_wood"), Vector2i(9, 10))
	expect(StructureArt.wall_mask(state, Vector2i(10, 10)) & StructureArt.WEST != 0, "Liga na planta de parede")
	expect_equal(StructureArt.wall_mask(state, Vector2i(10, 12), {Vector2i(10, 13): true}), StructureArt.NORTH | StructureArt.SOUTH,
		"A prévia liga às paredes prontas e entre si")
	var table := Defs.structure(&"table")
	expect_equal(StructureArt.region(state, table, Vector2i(20, 20)).size, AssetCatalog.texture(table.asset).get_size(), "Móvel usa a arte inteira")
	expect_equal(StructureArt.wall_mask(state, Vector2i(20, 19)), 0, "Mesa não liga paredes")


func test_built_things_sort_with_colonists() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var view := StructuresView.new()
	view._ready()
	view.sync(state)
	var ruins := view.sprite_count()
	_build(state, &"wall_wood", Vector2i(10, 10))
	_build(state, &"wall_wood", Vector2i(11, 10))
	_build(state, &"bed_rustic", Vector2i(14, 10))
	_build(state, &"floor_wood", Vector2i(16, 10))
	state.add_container(&"crate", Vector2i(18, 10))
	view.sync(state)
	expect_equal(view.sprite_count() - ruins, 4, "Paredes, cama e caixote viram sprites; piso não")
	var wall_key := "s%d" % state.buildings_by_cell[Vector2i(10, 10)].id
	var wall := view.sprite_of(wall_key)
	var tile := Balance.TILE_SIZE
	var behind_y := Vector2(Vector2i(10, 9) * tile).y + tile / 2.0
	var front_y := Vector2(Vector2i(10, 11) * tile).y + tile / 2.0
	var wall_sort := view.sort_position(wall_key).y
	expect(behind_y < wall_sort and front_y > wall_sort, "Colono atrás fica escondido, na frente passa por cima")
	expect_equal(wall.region_rect, AssetCatalog.frame_region("structures/wall_wood", StructureArt.EAST, 0), "Parede ligada ao vizinho")
	expect_equal(_top_left(view, wall_key), Vector2(10 * tile, 10 * tile - 8), "Topo da parede sobe 8 px acima do tile")
	var bed_key := "s%d" % state.buildings_by_cell[Vector2i(14, 10)].id
	expect(view.sort_position(bed_key).y < Vector2(Vector2i(14, 10) * tile).y + tile / 2.0, "Quem deita na cama fica por cima dela")
	expect_equal(_top_left(view, bed_key), Vector2(14 * tile, 10 * tile), "Cama 16×32 cobre os 2 tiles")
	state.remove_structure(state.buildings_by_cell[Vector2i(11, 10)])
	view.sync(state)
	expect_equal(wall.region_rect, AssetCatalog.frame_region("structures/wall_wood", 0, 0), "Vizinha desmontada: a parede fecha a ponta")
	expect_equal(view.sprite_count() - ruins, 3, "O sprite da desmontada sai")
	view.free()


func test_every_solid_structure_blocks_the_way() -> void:
	var state := Simulation.new(_SEED, 1).state
	var origin := Vector2i(30, 30)
	for def: StructureDef in Defs.structures():
		if def.layer == StructureDef.Layer.FLOOR or def.container_def != &"":
			continue
		var structure := Structure.new(state.next_id(), def, origin)
		state.add_structure(structure)
		for cell in def.cells_at(origin):
			if def.blocks_movement == state.navigation.is_walkable(cell):
				failures.append("%s em %s: passável %s" % [def.id, cell, state.navigation.is_walkable(cell)])
		state.remove_structure(structure)
	for id in [&"door_simple", &"bed_rustic", &"floor_wood"]:
		expect(not Defs.structure(id).blocks_movement, "%s deixa passar" % id)


func test_middle_click_copies_the_exact_structure() -> void:
	var state := Simulation.new(_SEED, 1).state
	_build(state, &"wall_stone", Vector2i(10, 10))
	_build(state, &"floor_wood", Vector2i(12, 10))
	_build(state, &"table", Vector2i(12, 10))
	state.add_container(&"crate", Vector2i(15, 10))
	Construction.place(state, Defs.structure(&"wall_wood"), Vector2i(17, 10))
	expect_equal(Construction.def_at(state, Vector2i(10, 10)).id, &"wall_stone", "Parede de pedra copia pedra")
	expect_equal(Construction.def_at(state, Vector2i(13, 10)).id, &"table", "Qualquer tile da mesa")
	expect_equal(Construction.def_at(state, Vector2i(12, 10)).id, &"table", "A mesa antes do piso embaixo")
	expect_equal(Construction.def_at(state, Vector2i(15, 10)).id, &"crate", "Contêiner copia o caixote")
	expect_equal(Construction.def_at(state, Vector2i(17, 10)).id, &"wall_wood", "Planta também copia")
	expect(Construction.def_at(state, Vector2i(40, 40)) == null, "Chão vazio não copia nada")
	expect_equal(Construction.availability_problem(state, Defs.structure(&"ruin_wall")), "não se constrói", "Peça da ruína não se copia")


func test_benches_rotate_and_walls_do_not() -> void:
	var simulation := Simulation.new(_SEED, 1)
	simulation.state.research.unlock_all()
	var state := simulation.state
	var bench := Defs.structure(&"crafting_bench")
	expect(bench.rotatable and not Defs.structure(&"wall_stone").rotatable and not Defs.structure(&"chest_rustic").rotatable
		and not Defs.structure(&"floor_wood").rotatable, "Bancada gira; parede, baú e piso não")
	expect_equal(bench.footprint_for(1), Vector2i(1, 3), "De lado, a bancada 3×1 ocupa 1×3")
	expect_equal(bench.footprint_for(2), Vector2i(3, 1), "Virada ao contrário, o tamanho volta")
	expect_equal(Defs.structure(&"wall_stone").footprint_for(1), Vector2i.ONE, "Parede não muda")
	var origin := _free_spot(simulation, bench, 1)
	var placed: Dictionary = simulation.place_structures(bench, [origin] as Array[Vector2i], 1)
	expect_equal(placed["placed"], 1, "Bancada de lado colocada (%s)" % placed["problem"])
	var site := state.site_at(origin + Vector2i(0, 2), StructureDef.Layer.BUILDING)
	expect(site != null and site.rotation == 1, "A planta ocupa a coluna e guarda a direção")
	expect(state.site_at(origin + Vector2i(1, 0), StructureDef.Layer.BUILDING) == null, "Não ocupa ao lado")
	expect_equal(Construction.rotation_at(state, origin + Vector2i(0, 1)), 1, "A cópia sai virada igual")
	Construction.complete(state, site)
	var structure: Structure = state.buildings_by_cell[origin + Vector2i(0, 2)]
	expect_equal(structure.rotation, 1, "A bancada pronta fica de lado")
	expect(not state.navigation.is_walkable(origin + Vector2i(0, 2)), "E bloqueia as 3 células da coluna")
	expect_equal(state.workbenches[structure.id].work_cell(), origin + Vector2i(0, 1), "Trabalha no meio da bancada girada")
	var view := StructuresView.new()
	view._ready()
	view.sync(state)
	var sprite := view.sprite_of("s%d" % structure.id)
	expect(is_equal_approx(sprite.rotation, PI / 2.0), "A arte gira 90°")
	var tile := Balance.TILE_SIZE
	var center := view.sort_position("s%d" % structure.id) + sprite.position
	expect_equal(center, Vector2(origin * tile) + Vector2(tile / 2.0, 3 * tile / 2.0), "Arte no centro da coluna de 3 tiles")
	view.free()
	var wall := Structure.new(1, Defs.structure(&"wall_stone"), Vector2i.ZERO, 1)
	expect_equal(wall.rotation, 0, "O que não gira ignora a direção")


func test_floating_windows_drag_inside_the_screen() -> void:
	var screen := Control.new()
	screen.size = Vector2(640, 360)
	var window := PanelContainer.new()
	window.custom_minimum_size = Vector2(200, 100)
	screen.add_child(window)
	window.set_anchors_preset(Control.PRESET_CENTER)
	window.size = Vector2(200, 100)
	window.position = Vector2(220, 130)
	expect(not WindowDrag.is_detached(window), "Começa presa ao centro")
	WindowDrag.move_by(window, Vector2(-100, 30))
	expect(WindowDrag.is_detached(window), "Ao arrastar, sai da âncora")
	expect_equal(window.position, Vector2(120, 160), "Vai junto com o mouse")
	WindowDrag.move_by(window, Vector2(-500, -500))
	expect_equal(window.position, Vector2.ZERO, "Não sai pela esquerda nem pelo topo")
	WindowDrag.move_by(window, Vector2(2000, 2000))
	expect_equal(window.position, Vector2(440, 260), "Nem pela direita nem por baixo")
	for window_script in [WorkPriorityWindow, ScheduleWindow, ResearchWindow, StoragePanel]:
		var panel: Control = window_script.new()
		panel._ready()
		var dragging := false
		for child in panel.find_children("*", "Label", true, false):
			if (child as Label).tooltip_text == WindowDrag.HINT:
				dragging = true
		expect(dragging, "%s arrasta pelo título" % panel.get_class())
		panel.free()
	screen.free()


static func _top_left(view: StructuresView, key: String) -> Vector2:
	var sprite := view.sprite_of(key)
	return view.sort_position(key) + sprite.position - sprite.region_rect.size / 2.0


static func _free_spot(simulation: Simulation, def: StructureDef, rotation: int) -> Vector2i:
	for y in range(10, 100):
		for x in range(10, 100):
			var origin := Vector2i(x, y)
			if simulation.placement_problem(def, origin, rotation).is_empty() and not _has_tree(simulation, def, origin, rotation):
				return origin
	return Vector2i(-1, -1)


static func _has_tree(simulation: Simulation, def: StructureDef, origin: Vector2i, rotation: int) -> bool:
	for cell in def.cells_at(origin, rotation):
		if simulation.state.trees_by_cell.has(cell):
			return true
	return false


static func _build(state: WorldState, id: StringName, origin: Vector2i) -> void:
	state.add_structure(Structure.new(state.next_id(), Defs.structure(id), origin))
