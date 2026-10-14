extends RefCounted

const Dados := preload("res://dados.gd")
const Visual := preload("res://visual.gd")

const LINHAS := [
	{"chave": "corpo", "rotulo": "Corpo", "tipo": "texto", "valores": ["Masculino", "Feminino"]},
	{"chave": "pele", "rotulo": "Tom de pele", "tipo": "cor", "lista": "pele"},
	{"chave": "cabelo", "rotulo": "Cabelo", "tipo": "texto", "valores": ["Curto", "Longo", "Moicano", "Cacheado", "Coque", "Careca", "Social", "Rabo"]},
	{"chave": "cor_cabelo", "rotulo": "Cor do cabelo", "tipo": "cor", "lista": "cabelo"},
	{"chave": "roupa", "rotulo": "Roupa", "tipo": "texto", "valores": ["Camiseta", "Camisa", "Regata"]},
	{"chave": "cor_roupa", "rotulo": "Cor da roupa", "tipo": "cor", "lista": "roupa"},
	{"chave": "olhos", "rotulo": "Olhar", "tipo": "texto", "valores": ["Normal", "Feliz", "Focado"]},
]

var aparencia: Dictionary = {"corpo": 0, "pele": 1, "cabelo": 0, "cor_cabelo": 0, "roupa": 0, "cor_roupa": 0, "olhos": 0}
var equipados: Dictionary = {}
var itens: Array = []
var origem := Vector2(160, 150)


func cores(lista: String) -> Array:
	match lista:
		"pele":
			return Dados.CORES_PELE
		"cabelo":
			return Dados.CORES_CABELO
	return Dados.CORES_ROUPA


func alvos() -> Array:
	var lista: Array = []
	var x0 := origem.x + 330.0
	for i in LINHAS.size():
		var linha: Dictionary = LINHAS[i]
		var y := origem.y + 30.0 + i * 56.0
		if linha["tipo"] == "cor":
			var paleta := cores(linha["lista"])
			for k in paleta.size():
				lista.append({"rect": Rect2(x0 + k * 38, y + 6, 30, 30), "chave": linha["chave"], "valor": k, "cor": paleta[k]})
		else:
			var valores: Array = linha["valores"]
			for k in valores.size():
				lista.append({"rect": Rect2(x0 + k * 92, y + 6, 86, 30), "chave": linha["chave"], "valor": k, "texto": valores[k]})
	var y_itens := origem.y + 30.0 + LINHAS.size() * 56.0
	var x := x0
	for id in itens:
		if Dados.ITENS[id]["tipo"] == "reforco":
			continue
		lista.append({"rect": Rect2(x, y_itens + 6, 120, 30), "item": id, "texto": Dados.ITENS[id]["nome"]})
		x += 126.0
	return lista


func clicar(pos: Vector2) -> bool:
	for a in alvos():
		if a["rect"].has_point(pos):
			if a.has("item"):
				var tipo: String = Dados.ITENS[a["item"]]["tipo"]
				equipados[tipo] = "" if equipados.get(tipo, "") == a["item"] else a["item"]
			else:
				aparencia[a["chave"]] = a["valor"]
			return true
	return false


func desenhar(ci: CanvasItem, tempo: float, mouse: Vector2) -> void:
	var palco := Rect2(origem, Vector2(300, 420))
	Visual.palco(ci, palco)
	Visual.avatar(ci, palco.position + Vector2(150, 360), 4.0, aparencia, equipados, tempo, false)
	if equipados.get("pet", "") != "":
		Visual.pet(ci, palco.position + Vector2(240, 372), equipados["pet"], tempo, -1, 2.4)
	var x0 := origem.x + 330.0
	for i in LINHAS.size():
		var linha: Dictionary = LINHAS[i]
		Visual.texto(ci, Vector2(x0, origem.y + 30.0 + i * 56.0), linha["rotulo"], 13, Visual.TEXTO_SUAVE)
	if not itens.is_empty():
		Visual.texto(ci, Vector2(x0, origem.y + 30.0 + LINHAS.size() * 56.0), "Itens da Loja Tech (toque para vestir)", 13, Visual.TEXTO_SUAVE)
	for a in alvos():
		var r: Rect2 = a["rect"]
		var hover := r.has_point(mouse)
		if a.has("cor"):
			var selecionado: bool = int(aparencia.get(a["chave"], 0)) == a["valor"]
			ci.draw_circle(r.get_center(), 13.0, a["cor"], true, -1.0, true)
			if selecionado:
				ci.draw_arc(r.get_center(), 17.0, 0.0, TAU, 28, Visual.TEXTO, 2.0, true)
			elif hover:
				ci.draw_arc(r.get_center(), 16.0, 0.0, TAU, 28, Visual.BORDA_HOVER, 1.5, true)
		else:
			var ativo: bool = (a.has("item") and equipados.get(Dados.ITENS[a["item"]]["tipo"], "") == a["item"]) or (a.has("chave") and int(aparencia.get(a["chave"], 0)) == a["valor"])
			Visual.caixa(ci, r, Visual.com_alfa(Visual.DESTAQUE, 0.18) if ativo else Visual.CARTAO, 10, Visual.DESTAQUE if ativo else (Visual.BORDA_HOVER if hover else Visual.BORDA), 1)
			Visual.texto(ci, Vector2(r.position.x, r.position.y + 20), a["texto"], 12, Visual.TEXTO if ativo else Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
