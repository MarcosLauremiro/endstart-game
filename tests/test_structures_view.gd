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
	var wall := view.sprite_of("s%d" % state.buildings_by_cell[Vector2i(10, 10)].id)
	var tile := Balance.TILE_SIZE
	var behind_y := Vector2(Vector2i(10, 9) * tile).y + tile / 2.0
	var front_y := Vector2(Vector2i(10, 11) * tile).y + tile / 2.0
	expect(behind_y < wall.position.y and front_y > wall.position.y, "Colono atrás fica escondido, na frente passa por cima")
	expect_equal(wall.region_rect, AssetCatalog.frame_region("structures/wall_wood", StructureArt.EAST, 0), "Parede ligada ao vizinho")
	expect_equal(wall.position + wall.offset, Vector2(10 * tile, 10 * tile - 8), "Topo da parede sobe 8 px acima do tile")
	var bed := view.sprite_of("s%d" % state.buildings_by_cell[Vector2i(14, 10)].id)
	expect(bed.position.y < Vector2(Vector2i(14, 10) * tile).y + tile / 2.0, "Quem deita na cama fica por cima dela")
	expect_equal(bed.position + bed.offset, Vector2(14 * tile, 10 * tile), "Cama 16×32 cobre os 2 tiles")
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


static func _build(state: WorldState, id: StringName, origin: Vector2i) -> void:
	state.add_structure(Structure.new(state.next_id(), Defs.structure(id), origin))
