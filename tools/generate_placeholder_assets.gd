extends SceneTree
## Cria os PNGs provisórios que faltam em res://assets e gera assets/LISTA_DE_ASSETS.md.
## Nunca sobrescreve um PNG existente: a arte que você colocar no lugar é preservada.
## Uso: godot --headless --path . -s res://tools/generate_placeholder_assets.gd


func _init() -> void:
	var created := 0
	var kept := 0
	for id in AssetCatalog.ENTRIES:
		var path := AssetCatalog.path_of(id)
		var absolute := ProjectSettings.globalize_path(path)
		DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
		if FileAccess.file_exists(path):
			kept += 1
			continue
		var error := PlaceholderPainter.paint(AssetCatalog.ENTRIES[id]).save_png(absolute)
		if error != OK:
			push_error("Falha ao salvar %s (erro %d)" % [path, error])
			quit(1)
			return
		created += 1
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AssetCatalog.FONT_DIR))
	_write_list()
	print("Assets provisórios criados: %d; existentes preservados: %d" % [created, kept])
	quit()


func _write_list() -> void:
	var lines := PackedStringArray([
		"# Lista de assets",
		"",
		"Gerado por `tools/generate_placeholder_assets.gd` a partir de `scripts/assets/asset_catalog.gd`. Não edite à mão.",
		"",
		"- Substitua o PNG mantendo **o mesmo nome e o mesmo tamanho**; o teste `test_asset_catalog.gd` confere os tamanhos.",
		"- Para um asset novo, adicione a entrada no catálogo e rode o gerador de novo: ele só cria o que falta.",
		"- Molduras `ui/frames` são 9-slice: os cantos indicados não esticam.",
		"- Folhas de sprites (coluna Quadros): grade de quadros iguais, lida da esquerda para a direita e de cima para baixo. Linhas de estação seguem primavera, verão, outono, inverno.",
		"- Fonte: coloque uma fonte pixel monoespaçada com acentos em `ui/fonts/main.ttf` (8 px lógicos). Sem ela, o jogo usa a fonte padrão.",
	])
	var current_folder := ""
	for id in AssetCatalog.ENTRIES:
		var entry: Dictionary = AssetCatalog.ENTRIES[id]
		var folder: String = id.get_base_dir()
		if folder != current_folder:
			current_folder = folder
			lines.append_array(["", "## assets/%s/" % folder, "", "| Arquivo | Tamanho (px) | Quadros | Uso |", "| --- | --- | --- | --- |"])
		var size: Vector2i = entry["size"]
		var grid: Vector2i = entry.get("frames", Vector2i.ONE)
		var frames := "—" if grid == Vector2i.ONE else "%d × %d de %d×%d" % [grid.x, grid.y, size.x / grid.x, size.y / grid.y]
		lines.append("| `%s.png` | %d×%d | %s | %s |" % [id.get_file(), size.x, size.y, frames, entry["use"]])
	var file := FileAccess.open(AssetCatalog.LIST_PATH, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
