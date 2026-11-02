class_name ThreatDirector
extends RefCounted
## O ritmo dos ataques (GDD: A IA, ameaças e crises; MVP: só saqueadores e a IA BALANÇA fixa).
## Marca o próximo ataque, avisa com fumaça no horizonte 1,5 dia antes, compra o grupo com os
## pontos de ameaça, traz os saqueadores pela borda e, no fim, dá a calma proporcional às perdas.

const _ENTRY_ATTEMPTS := 60
## Chance de cada compra ser um arqueiro, quando os pontos dão.
const _ARCHER_CHANCE := 0.35


## A cada hora: aviso e chegada.
static func hour_passed(state: WorldState) -> void:
	var threats := state.threats
	var now := state.clock.tick
	var raid := threats.raid
	if raid == null:
		if now >= threats.next_raid_tick - Balance.RAID_WARNING_TICKS:
			warn(state, maxi(threats.next_raid_tick, now + Balance.TICKS_PER_HOUR))
	elif raid.phase == Raid.Phase.WARNED and now >= raid.arrival_tick:
		arrive(state, raid)


## Fim do ataque: quando nenhum saqueador dele resta no mapa.
static func check_raid_over(state: WorldState) -> void:
	var raid := state.threats.raid
	if raid == null or raid.phase != Raid.Phase.ACTIVE:
		return
	for raider: Raider in state.threats.raiders.values():
		if raider.raid_id == raid.id:
			return
	end_raid(state, raid)


## Virada do dia: +0,01 de adaptação se ninguém morreu.
static func day_passed(state: WorldState) -> void:
	var threats := state.threats
	if threats.colonists_lost_today == 0:
		threats.adaptation = minf(threats.adaptation + Balance.ADAPTATION_DAILY_GAIN, Balance.ADAPTATION_CAP)
	threats.colonists_lost_today = 0


## Pontos = (P_riqueza + P_colonos) × M_IA × M_adaptação × M_início, entre o mínimo e o teto.
## fighters: peso de cada colono (1 = capaz de lutar, 0,25 = ferido).
static func points_for(wealth_value: float, fighters: Array[float], day: int, adaptation: float) -> int:
	var start_factor := minf(1.0, Balance.START_FACTOR_BASE + Balance.START_FACTOR_PER_DAY * day)
	var total := (wealth_points(wealth_value) + colonist_points(fighters)) * Balance.AI_MULTIPLIER * adaptation * start_factor
	return clampi(roundi(total), Balance.THREAT_POINTS_MIN, Balance.THREAT_POINTS_CAP)


## P_riqueza: interpolação linear na tabela do GDD.
static func wealth_points(wealth_value: float) -> float:
	var table: Array = Balance.WEALTH_POINTS
	var first: Vector2 = table[0]
	if wealth_value <= first.x:
		return first.y
	for i in range(1, table.size()):
		var high: Vector2 = table[i]
		if wealth_value <= high.x:
			var low: Vector2 = table[i - 1]
			return lerpf(low.y, high.y, (wealth_value - low.x) / (high.x - low.x))
	var last: Vector2 = table[-1]
	return last.y


## Valor marginal: os 5 primeiros valem 25, do 6º ao 10º 45, e assim por diante. Os capazes
## de lutar ocupam as primeiras vagas.
static func colonist_points(fighters: Array[float]) -> float:
	var sorted := fighters.duplicate()
	sorted.sort()
	sorted.reverse()
	var total := 0.0
	for index in sorted.size():
		total += sorted[index] * _slot_value(index + 1)
	return total


static func _slot_value(position: int) -> float:
	for band in Balance.COLONIST_POINTS:
		if position <= band[0]:
			return band[1]
	return Balance.COLONIST_POINTS[-1][1]


## Riqueza = valor dos itens + 0,5 × valor das construções (no MVP não há animais da colônia).
static func wealth(state: WorldState) -> float:
	var total := 0.0
	for definition in Defs.items():
		var count := state.total_count(definition.id)
		if count > 0:
			total += count * definition.value
	for structure: Structure in state.structures.values():
		if structure.def.buildable:
			total += 0.5 * structure_value(structure.def)
	return total


## GDD (Valor dos itens): materiais + horas de trabalho × 4.
static func structure_value(def: StructureDef) -> float:
	var total := def.work_hours * 4.0
	for item in def.costs:
		total += Defs.item(item).value * def.costs[item]
	return total


static func fighter_weights(state: WorldState) -> Array[float]:
	var weights: Array[float] = []
	for colonist in state.colonists:
		var wounded := colonist.health.is_downed() or colonist.health.damage() >= Balance.REST_DAMAGE
		weights.append(Balance.WOUNDED_FIGHTER_SHARE if wounded else 1.0)
	return weights


## Compra o grupo com os pontos: lanceiros (50) e arqueiros (65). Sempre vem ao menos um.
static func compose(points: int, rng: RandomNumberGenerator) -> Array[StringName]:
	var group: Array[StringName] = []
	var left := points
	var spear := Raider.cost_of(&"spear")
	var archer := Raider.cost_of(&"archer")
	while left >= spear:
		var kind: StringName = &"archer" if left >= archer and rng.randf() < _ARCHER_CHANCE else &"spear"
		group.append(kind)
		left -= Raider.cost_of(kind)
	if group.is_empty():
		group.append(&"spear")
	return group


## Dias de calma depois do ataque = (2 + 10 × perdidos ÷ total) × fator de recuperação.
static func calm_days(lost: int, total: int) -> float:
	var share := float(lost) / float(maxi(total, 1))
	return (Balance.CALM_BASE_DAYS + Balance.CALM_DAYS_PER_LOSS_SHARE * share) * Balance.RECOVERY_FACTOR


## Marca o ataque e mostra o aviso: fumaça no horizonte do lado por onde vão chegar.
static func warn(state: WorldState, arrival_tick: int) -> Raid:
	var threats := state.threats
	var raid := Raid.new()
	raid.id = state.next_id()
	raid.warned_tick = state.clock.tick
	raid.arrival_tick = arrival_tick
	var day := arrival_tick / Balance.TICKS_PER_DAY + 1
	raid.points = points_for(wealth(state), fighter_weights(state), day, threats.adaptation)
	raid.group = compose(raid.points, state.rng)
	_choose_entry(state, raid)
	threats.raid = raid
	state.post_message("Fumaça no horizonte %s: saqueadores devem chegar em cerca de %s. Prepare armas e convoque os colonos (V)." % [
		raid.side_towards(), time_text(arrival_tick - state.clock.tick)])
	return raid


## Os saqueadores entram pela borda do aviso.
static func arrive(state: WorldState, raid: Raid) -> void:
	raid.phase = Raid.Phase.ACTIVE
	raid.started_tick = state.clock.tick
	raid.colonists_at_start = state.colonists.size()
	var used := {}
	for raider_kind in raid.group:
		var cell := _spawn_cell(state, raid.entry, used)
		used[cell] = true
		var raider := Raider.new(state.next_id(), raider_kind, cell)
		raider.raid_id = raid.id
		raider.melee_level = state.rng.randi_range(Balance.RAIDER_MELEE_MIN, Balance.RAIDER_MELEE_MAX)
		raider.strength = state.rng.randi_range(Balance.ATTRIBUTE_AVERAGE - 1, Balance.ATTRIBUTE_AVERAGE + 2)
		state.threats.raiders[raider.id] = raider
	state.post_message("Saqueadores chegaram pelo %s: %s!" % [raid.side_name(), group_text(raid.group)])
	var branch := state.research.fire_trigger(&"first_hunt")
	if not branch.is_empty():
		state.post_message("Primeiro ataque! Novo ramo de pesquisa: %s" % branch)


static func end_raid(state: WorldState, raid: Raid) -> void:
	var threats := state.threats
	raid.phase = Raid.Phase.OVER
	threats.raid = null
	threats.raids_survived += 1
	var now := state.clock.tick
	var calm := calm_days(raid.colonists_lost, raid.colonists_at_start)
	threats.calm_until = now + roundi(calm * Balance.TICKS_PER_DAY)
	var interval := state.rng.randi_range(Balance.RAID_INTERVAL_MIN_DAYS, Balance.RAID_INTERVAL_MAX_DAYS)
	var next_day := (now + interval * Balance.TICKS_PER_DAY) / Balance.TICKS_PER_DAY
	var hour := state.rng.randi_range(Balance.RAID_EARLIEST_HOUR, Balance.RAID_LATEST_HOUR)
	threats.next_raid_tick = maxi(next_day * Balance.TICKS_PER_DAY + hour * Balance.TICKS_PER_HOUR, threats.calm_until)
	state.post_message("O ataque acabou: %d saqueador(es) morto(s), %d fugiram feridos, %d levaram itens; %d colono(s) perdido(s). Calma por %s dias." % [
		raid.raiders_killed, raid.raiders_fled, raid.raiders_looted, raid.colonists_lost, ("%.1f" % calm).replace(".", ",")])


## Uma morte de colono: M_adaptação -0,15 (mínimo 0,5) e a perda conta para a calma.
static func colonist_died(state: WorldState) -> void:
	var threats := state.threats
	threats.adaptation = maxf(threats.adaptation - Balance.ADAPTATION_DEATH_LOSS, Balance.ADAPTATION_MIN)
	threats.colonists_lost_today += 1
	if threats.raid and threats.raid.phase == Raid.Phase.ACTIVE:
		threats.raid.colonists_lost += 1


## Texto do aviso e da interface: "1 dia e 12 h", "5 h".
static func time_text(ticks: int) -> String:
	var hours := maxi(0, roundi(float(ticks) / Balance.TICKS_PER_HOUR))
	var days := hours / Balance.HOURS_PER_DAY
	hours %= Balance.HOURS_PER_DAY
	if days == 0:
		return "%d h" % hours
	var day_text := "1 dia" if days == 1 else "%d dias" % days
	return day_text if hours == 0 else "%s e %d h" % [day_text, hours]


static func group_text(group: Array[StringName]) -> String:
	var spears := group.count(&"spear")
	var archers := group.count(&"archer")
	var parts := PackedStringArray()
	if spears > 0:
		parts.append("%d com lança" % spears)
	if archers > 0:
		parts.append("%d arqueiro%s" % [archers, "s" if archers > 1 else ""])
	return " e ".join(parts)


## Borda sorteada, numa célula seca de onde se chega até os colonos.
static func _choose_entry(state: WorldState, raid: Raid) -> void:
	var size := state.world.size
	var goal := state.colonists[0].cell if not state.colonists.is_empty() else size / 2
	for _attempt in _ENTRY_ATTEMPTS:
		var side := state.rng.randi_range(0, 3)
		var along := state.rng.randi_range(0, (size.x if side < 2 else size.y) - 1)
		var cell: Vector2i
		var inward: Vector2i
		match side:
			0:
				cell = Vector2i(along, 0)
				inward = Vector2i.DOWN
			1:
				cell = Vector2i(along, size.y - 1)
				inward = Vector2i.UP
			2:
				cell = Vector2i(0, along)
				inward = Vector2i.RIGHT
			_:
				cell = Vector2i(size.x - 1, along)
				inward = Vector2i.LEFT
		if not _dry(state, cell) or not state.navigation.can_reach(cell, goal):
			continue
		raid.side = side
		raid.entry = cell
		raid.smoke_cell = cell + inward * Balance.SMOKE_INSET
		return
	# Sem borda alcançável (não acontece nos mapas gerados): entram perto da colônia.
	raid.side = 3
	raid.entry = state.nearest_walkable(goal + Vector2i(Balance.RAIDER_SIGHT, 0))
	raid.smoke_cell = raid.entry


static func _spawn_cell(state: WorldState, entry: Vector2i, used: Dictionary) -> Vector2i:
	for radius in range(0, 4):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var cell := entry + Vector2i(dx, dy)
				if state.world.contains(cell) and _dry(state, cell) and not used.has(cell):
					return cell
	return entry


static func _dry(state: WorldState, cell: Vector2i) -> bool:
	return state.navigation.is_walkable(cell) and state.world.get_terrain(cell) != Terrain.Kind.SHALLOW_WATER
