class_name Schedule
extends RefCounted
## Agenda por hora (GDD: Agenda). No MVP: Dormir, Trabalhar e Livre.

enum Block { SLEEP, WORK, FREE }

const BLOCK_NAMES := {
	Block.SLEEP: "Dormir",
	Block.WORK: "Trabalhar",
	Block.FREE: "Livre",
}

## Bloco de cada hora do dia (0 a 23).
var blocks: Array[int] = []


func _init() -> void:
	for hour in Balance.HOURS_PER_DAY:
		blocks.append(default_block(hour))


## Padrão: dormir das 22 às 6, livre das 20 às 22, trabalhar no resto.
static func default_block(hour: int) -> Block:
	if hour >= Balance.SCHEDULE_SLEEP_START or hour < Balance.SCHEDULE_SLEEP_END:
		return Block.SLEEP
	if hour >= Balance.SCHEDULE_FREE_START:
		return Block.FREE
	return Block.WORK


func block_at(hour: int) -> Block:
	return blocks[hour % Balance.HOURS_PER_DAY] as Block


func set_block(hour: int, block: Block) -> void:
	blocks[hour % Balance.HOURS_PER_DAY] = block


static func name_of(block: int) -> String:
	return BLOCK_NAMES.get(block, "?")
