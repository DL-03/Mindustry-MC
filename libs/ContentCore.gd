@tool
extends Node

enum ContentType {
	ITEM,
	BLOCK,
	BULLET,
	LIQUID,
	STATUS,
	UNIT,
	WEATHER,
	SECTOR,
	PLANET,
	TEAM,
	UNIT_COMMAND,
	UNIT_STANCE,

	MOD
}

var ContentTypePath: Dictionary[ContentType, String] = {
	ContentType.ITEM: "items",
	ContentType.BLOCK: "blocks",
	ContentType.BULLET: "bullets",
	ContentType.LIQUID: "liquids",
	ContentType.STATUS: "statuses",
	ContentType.UNIT: "units",
	ContentType.WEATHER: "weather",
	ContentType.SECTOR: "sectors",
	ContentType.PLANET: "planets",
	ContentType.TEAM: "teams",
	ContentType.UNIT_COMMAND: "unitCommands",
	ContentType.UNIT_STANCE: "unitStances",
	
	ContentType.MOD: "mod"
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
