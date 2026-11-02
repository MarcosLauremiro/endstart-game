class_name Alerts
extends RefCounted
## Alertas do MVP (GDD: Interface > alertas com limite, lateral direita; Logística > alertas).
## Cada alerta é {"key", "text", "tooltip", "danger": bool, "urgency": int, "cell": Vector2i,
## "colonist_id": int}; cell (-1, -1) = sem lugar para mostrar. Um alerta por tipo: vários colonos
## com o mesmo problema viram uma linha só. Só lê o estado.

const NO_CELL := Vector2i(-1, -1)
## Comida guardada abaixo disto (em dias da colônia inteira) vira alerta.
const LOW_FOOD_DAYS := 1.0


static func compute(state: WorldState) -> Array[Dictionary]:
	var alerts: Array[Dictionary] = []
	_raid(state, alerts)
	_colonists(state, alerts, "downed", true, 90, "Caído", "Caídos",
		"Precisa de socorro: alguém com Emergência leva até uma cama e trata",
		func(c: Colonist) -> bool: return c.health.is_downed())
	_colonists(state, alerts, "bleeding", true, 80, "Sangrando", "Sangrando",
		"Sangra sem tratamento; estanca sozinho se estiver de pé e livre",
		func(c: Colonist) -> bool: return c.health.is_bleeding() and not c.health.is_downed())
	_colonists(state, alerts, "starving", true, 60, "Faminto", "Famintos",
		"Fome abaixo de %d%%: precisa de comida já" % int(Balance.FOOD_CRITICAL_THRESHOLD),
		func(c: Colonist) -> bool: return c.needs.food < Balance.FOOD_CRITICAL_THRESHOLD)
	_low_food(state, alerts)
	_colonists(state, alerts, "crisis", false, 50, "Em crise", "Em crise",
		"Humor muito baixo: veja os pensamentos na ficha do colono",
		func(c: Colonist) -> bool: return c.mood.state() <= Mood.State.CRISIS)
	_colonists(state, alerts, "exhausted", false, 40, "Exausto", "Exaustos",
		"Sono abaixo de %d%%: vai desmaiar onde estiver" % int(Balance.REST_CRITICAL_THRESHOLD),
		func(c: Colonist) -> bool: return c.needs.rest < Balance.REST_CRITICAL_THRESHOLD and not c.is_sleeping())
	_beds(state, alerts)
	_no_storage(state, alerts)
	alerts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["urgency"] > b["urgency"])
	return alerts


static func _raid(state: WorldState, alerts: Array[Dictionary]) -> void:
	var raid := state.threats.raid
	if raid == null:
		return
	if raid.phase == Raid.Phase.ACTIVE and not state.threats.raiders.is_empty():
		var first: Raider = state.threats.raiders.values()[0]
		alerts.append(_alert("raid", "Ataque! %d saqueador(es)" % state.threats.raiders.size(),
			"Convoque (V) e lute, ou deixe levarem o saque. Quem não está convocado foge.", true, 100, first.cell))
	elif raid.phase == Raid.Phase.WARNED:
		var armed := 0
		for colonist in state.colonists:
			if Combat.damage_of(colonist.weapon()) > Balance.UNARMED_ATTACK_DAMAGE:
				armed += 1
		alerts.append(_alert("raid_warned", TimePanel.threat_text(state),
			"Fumaça no horizonte. %d de %d colonos armados: faça lanças ou arcos e convoque (V) quando chegarem." % [
				armed, state.colonists.size()], false, 70, raid.smoke_cell))


## Uma linha para todos os colonos com o mesmo problema; o clique leva ao primeiro.
static func _colonists(state: WorldState, alerts: Array[Dictionary], key: String, danger: bool, urgency: int,
		singular: String, plural: String, tooltip: String, matches: Callable) -> void:
	var names := PackedStringArray()
	var first: Colonist
	for colonist in state.colonists:
		if matches.call(colonist):
			names.append(colonist.display_name)
			if first == null:
				first = colonist
	if first == null:
		return
	var text := "%s: %s" % [singular if names.size() == 1 else plural, ", ".join(names)]
	var alert := _alert(key, text, tooltip, danger, urgency, first.cell)
	alert["colonist_id"] = first.id
	alerts.append(alert)


static func _low_food(state: WorldState, alerts: Array[Dictionary]) -> void:
	if state.colonists.is_empty():
		return
	var days := state.stored_nutrition() / (Balance.DAILY_FOOD_NEED * state.colonists.size())
	if days < LOW_FOOD_DAYS:
		alerts.append(_alert("low_food", "Pouca comida: %.1f dia(s)" % days,
			"Comida guardada para menos de %d dia. Cace, colha, plante e cozinhe." % int(LOW_FOOD_DAYS), false, 55, NO_CELL))


static func _beds(state: WorldState, alerts: Array[Dictionary]) -> void:
	var missing := state.colonists.size() - state.beds().size()
	if missing > 0:
		alerts.append(_alert("beds", "Sem cama: %d colono(s)" % missing,
			"Dormir no chão pesa no humor e ferido se cura mais devagar. Construa camas (B).", false, 30, NO_CELL))


## Pilhas no chão que nenhum contêiner aceita (GDD: item sem lugar para ir).
static func _no_storage(state: WorldState, alerts: Array[Dictionary]) -> void:
	var names := PackedStringArray()
	var first := NO_CELL
	var checked := {}
	for stack: ItemStack in state.stacks.values():
		if checked.has(stack.item):
			if checked[stack.item] and first == NO_CELL:
				first = stack.cell
			continue
		var homeless := state.find_storage_for(stack.item, stack.cell) == null
		checked[stack.item] = homeless
		if homeless:
			names.append(Defs.item(stack.item).display_name.to_lower())
			if first == NO_CELL:
				first = stack.cell
	if not names.is_empty():
		alerts.append(_alert("no_storage", "Sem lugar: %s" % ", ".join(names),
			"Nenhum contêiner com espaço aceita. Construa um contêiner ou libere a categoria no Configurar.", false, 20, first))


static func _alert(key: String, text: String, tooltip: String, danger: bool, urgency: int, cell: Vector2i) -> Dictionary:
	return {"key": key, "text": text, "tooltip": tooltip, "danger": danger, "urgency": urgency, "cell": cell, "colonist_id": 0}
