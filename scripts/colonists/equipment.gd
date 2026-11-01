class_name Equipment
extends RefCounted
## Espaços de equipamento do MVP (GDD: Equipamento; MVP: Camisa, Calça e Mão).
## Cada espaço guarda um id de item ou vazio. O item equipado existe de verdade: é contado nos
## totais e volta ao mundo se for trocado ou largado.

enum Slot { SHIRT, PANTS, HAND }

const SLOT_NAMES := {
	Slot.SHIRT: "Camisa",
	Slot.PANTS: "Calça",
	Slot.HAND: "Mão",
}
## Chave usada no ItemDef (.tres).
const SLOT_KEYS := {
	&"shirt": Slot.SHIRT,
	&"pants": Slot.PANTS,
	&"hand": Slot.HAND,
}

## Slot → id do item (&"" = vazio)
var items := {Slot.SHIRT: &"", Slot.PANTS: &"", Slot.HAND: &""}


func in_slot(slot: Slot) -> StringName:
	return items[slot]


func hand() -> StringName:
	return items[Slot.HAND]


## Veste ou empunha o item no espaço dele. Devolve o que estava lá (&"" se nada).
func equip(item: StringName) -> StringName:
	var slot := slot_of(item)
	var previous: StringName = items[slot]
	items[slot] = item
	return previous


func clear(slot: Slot) -> StringName:
	var previous: StringName = items[slot]
	items[slot] = &""
	return previous


func weight_kg() -> float:
	var total := 0.0
	for slot in items:
		if items[slot] != &"":
			total += Defs.item(items[slot]).weight_kg
	return total


func count_of(item: StringName) -> int:
	var total := 0
	for slot in items:
		if items[slot] == item:
			total += 1
	return total


static func slot_of(item: StringName) -> Slot:
	return SLOT_KEYS[Defs.item(item).equip_slot]


static func is_equippable(item: StringName) -> bool:
	return SLOT_KEYS.has(Defs.item(item).equip_slot)
