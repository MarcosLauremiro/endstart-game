class_name TestStorage
extends TestCase
## Armazenamento por categoria: categorias dos itens, filtro dos contêineres, guardar uma pilha
## pelo clique (prioridade alta) e aviso quando não há onde guardar.

const _SEED := 12345


func test_every_item_has_a_named_category() -> void:
	for definition in Defs.items():
		expect(ItemDef.CATEGORY_NAMES.has(definition.category), "%s tem categoria" % definition.display_name)
	expect_equal(Defs.item(&"simple_meal").category_name(), "Alimentos", "Refeição: alimentos")
	expect_equal(Defs.item(&"wood").category_name(), "Recursos básicos", "Madeira: recurso básico")
	expect_equal(Defs.item(&"stone_block").category_name(), "Recursos avançados", "Bloco: recurso avançado")
	expect_equal(Defs.item(&"small_game_carcass").category_name(), "Carcaças", "Carcaça à parte")
	expect_equal(Defs.item(&"stone_axe").category_name(), "Ferramentas", "Machado: ferramenta")
	expect_equal(Defs.item(&"bow").category_name(), "Armas", "Arco: arma")
	expect_equal(Defs.item(&"tunic").category_name(), "Roupas", "Túnica: roupa")


func test_material_yard_holds_only_basic_resources() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var origin := SimHelpers.clear_area(simulation, Vector2i(2, 2))
	var yard := simulation.state.add_container(&"material_yard", origin)
	expect(yard.free_space(&"wood") > 0, "Pátio aceita madeira")
	expect_equal(yard.free_space(&"stone_block"), 0, "Pátio não aceita blocos")
	expect_equal(yard.free_space(&"simple_meal"), 0, "Pátio não aceita comida")
	expect(not yard.allowed.has(ItemDef.Category.FOOD), "O filtro do pátio nem mostra alimentos")


func test_filter_sends_food_elsewhere() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var crates: Array = state.containers.values()
	var pantry: StorageContainer = crates[0]
	var other: StorageContainer = crates[1]
	var meals_before := state.total_count(&"simple_meal")
	for category in ItemDef.CATEGORY_NAMES:
		simulation.set_container_filter(other.id, category, category != ItemDef.Category.FOOD)
	expect_equal(other.count_of(&"simple_meal"), 0, "Proibir alimentos tira as refeições do caixote")
	expect_equal(state.total_count(&"simple_meal"), meals_before, "Nada some: as refeições vão para o chão")
	expect_equal(other.free_space(&"berries"), 0, "O caixote não aceita mais alimentos")
	SimHelpers.run_until(simulation, func() -> bool: return state.stacks.is_empty(), 20000)
	expect(pantry.count_of(&"simple_meal") > 0, "As refeições vão para o outro caixote")
	expect(state.find_storage_for(&"simple_meal", other.cell) == pantry or state.find_storage_for(&"simple_meal", other.cell) == null,
		"Comida só procura o caixote que aceita alimentos")


func test_store_option_prioritizes_the_stack() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(1, 1))
	state.drop_items(origin, &"wood", 5)
	var stack: ItemStack = state.stacks_by_cell[origin]
	var options := ContextActions.for_cell(simulation, origin)
	var store: Array = options.filter(func(o: Dictionary) -> bool: return o["label"] == "Guardar madeira")
	expect_equal(store.size(), 1, "Clicar na pilha mostra Guardar")
	var message: String = store[0]["run"].call()
	expect_equal(message, "Madeira: será guardado primeiro", "Mensagem de confirmação")
	expect_equal(state.task_board.haul_for_stack(stack.id).urgency, Balance.URGENCY_PLAYER, "A tarefa vira prioridade alta")


func test_store_without_storage_says_why() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	for container in state.containers.values():
		simulation.set_container_filter(container.id, ItemDef.Category.WEAPON, false)
	var origin := SimHelpers.clear_area(simulation, Vector2i(1, 1))
	state.drop_items(origin, &"bow", 1)
	var stack: ItemStack = state.stacks_by_cell[origin]
	expect_equal(simulation.store_stack(stack.id),
		"Não dá para guardar arco: nenhum contêiner com espaço aceita arco (armas)", "Sem lugar, o motivo é dito")
	var messages: Array[String] = []
	state.message_posted.connect(func(text: String) -> void: messages.append(text))
	SimHelpers.run_until(simulation, func() -> bool: return false, 600)
	expect(messages.any(func(m: String) -> bool: return m.begins_with("Sem lugar para guardar")), "O jogo avisa sozinho quando o transporte trava")


func test_basic_resources_stack_to_99() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(3, 2))
	var chest := state.add_container(&"chest_rustic", origin)
	expect_equal(chest.add_items(&"wood", 150), 150, "Cabe toda a madeira")
	expect_equal(chest.slots[0]["count"], 99, "Um espaço junta até 99 madeiras")
	expect_equal(chest.slots[1]["count"], 51, "O resto vai para o espaço seguinte")
	for item in [&"stone_raw", &"fiber", &"scrap"]:
		expect_equal(Defs.item(item).stack_size, 99, "%s junta até 99" % Defs.item(item).display_name)
	var yard := state.add_container(&"material_yard", origin + Vector2i(1, 0))
	expect_equal(yard.def.stack_size_for(Defs.item(&"wood")), Balance.LARGE_SLOT_STACK, "Espaço grande continua com 300")


func test_container_view_shows_slots_and_hides_the_filter() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var origin := SimHelpers.clear_area(simulation, Vector2i(1, 1))
	var chest := state.add_container(&"chest_rustic", origin)
	chest.add_items(&"wood", 120)
	chest.add_items(&"bow", 1)
	var view := ContainerView.new()
	view._ready()
	view.show_container(simulation, chest)
	expect_equal(view._grid.get_child_count(), 10, "O baú rústico mostra 10 espaços")
	expect_equal(view._slots[0]["count"].text, "99", "Primeiro espaço: 99")
	expect_equal(view._slots[1]["count"].text, "21", "Segundo espaço: 21")
	expect_equal(view._slots[2]["count"].text, "", "Um item só não mostra número")
	expect(view._slots[0]["icon"].texture != null and view._slots[3]["icon"].texture == null, "Ícone só onde há item")
	expect_equal(ContainerView.slot_tooltip(chest, 0), "Madeira: 99 de 99", "Dica do espaço")
	expect_equal(ContainerView.slot_tooltip(chest, 5), "Espaço vazio", "Dica do espaço vazio")
	expect(not view._settings.visible, "A configuração começa fechada")
	expect(ContextActions.for_cell(simulation, origin).all(func(o: Dictionary) -> bool: return not o["label"].begins_with("[")),
		"O filtro não aparece mais nas opções soltas")
	view._configure.button_pressed = true
	expect(view._settings.visible, "Configurar abre o filtro")
	expect_equal(ContainerView.filter_entries(chest).size(), ItemDef.CATEGORY_NAMES.size(), "Baú: todas as categorias")
	view._toggle(chest.id, ItemDef.Category.FOOD, false)
	expect(not chest.allowed[ItemDef.Category.FOOD], "Desmarcar pelo filtro para de guardar alimentos")
	var other := state.add_container(&"crate", origin + Vector2i(1, 0))
	view.show_container(simulation, other)
	expect(not view._settings.visible and view._grid.get_child_count() == 6, "Outro contêiner: 6 espaços, configuração fechada")
	view.free()
