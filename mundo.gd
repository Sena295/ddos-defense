extends Node2D

const Dados := preload("res://dados.gd")
const Textos := preload("res://textos.gd")
const Visual := preload("res://visual.gd")
const Estado := preload("res://estado.gd")

const LARGURA := 64
const ALTURA := 44
const MEIO_TILE := Vector2(32, 16)
const ORIGEM := Vector2(ALTURA * 32 + 120, 260)
const TAMANHO_TELA := Vector2((LARGURA + ALTURA) * 32 + 240, (LARGURA + ALTURA) * 16 + 330)
const VELOCIDADE := 4.8
const RAIO_INTERACAO := 1.5
const RUAS_X := [13, 14, 29, 30, 44, 45]
const RUAS_Y := [13, 14, 29, 30]
const CALCADAS_X := [12, 15, 28, 31, 43, 46]
const CALCADAS_Y := [12, 15, 28, 31]
const PRACA := Rect2i(16, 21, 12, 7)
const DISTRITO_NEON := Rect2i(47, 0, 17, 28)
const RET_MINIMAPA := Rect2(1060, 16, 204, 120)
const RET_BOTAO_MISSOES := Rect2(1064, 630, 196, 72)
const RET_BOTAO_SEDE := Rect2(856, 630, 196, 72)
const RET_PROMPT := Rect2(440, 640, 400, 54)
const RET_GUIA := Rect2(316, 145, 66, 30)
const QUANTIDADE_NPCS := 18
const QUANTIDADE_NPCS_LEVE := 7
const CONTORNO := Color("1b2233")
const PAREDES := [Color("efe6d8"), Color("e2dccf"), Color("d9cfc0"), Color("d3dbe6"), Color("ead9c8"), Color("dde6d6"), Color("e6dfe9")]
const JANELAS_NEON := [Color("22d3ee"), Color("f472b6"), Color("facc15"), Color("a78bfa"), Color("1e2235")]

const LOCAIS := [
	{"id": "missoes", "tipo": "missoes", "nome": "Central de Missões", "area": Rect2i(1, 1, 6, 3), "altura": 104.0, "cor": Color("facc15"), "parede": Color("fff3c4")},
	{"id": "academia", "tipo": "academia", "nome": "Academia Cyber", "area": Rect2i(8, 1, 3, 3), "altura": 120.0, "cor": Color("3b82f6"), "parede": Color("dbe7fb")},
	{"id": "pixelforge", "tipo": "empresa", "area": Rect2i(1, 7, 3, 3), "altura": 100.0},
	{"id": "rangoja", "tipo": "empresa", "area": Rect2i(5, 7, 3, 3), "altura": 86.0},
	{"id": "flixplay", "tipo": "empresa", "area": Rect2i(9, 7, 3, 3), "altura": 112.0},
	{"id": "mercadonet", "tipo": "empresa", "area": Rect2i(16, 1, 3, 3), "altura": 96.0},
	{"id": "shoppa", "tipo": "empresa", "area": Rect2i(20, 1, 3, 3), "altura": 90.0},
	{"id": "voaja", "tipo": "empresa", "area": Rect2i(24, 1, 3, 3), "altura": 108.0},
	{"id": "socialhub", "tipo": "empresa", "area": Rect2i(16, 7, 3, 3), "altura": 124.0},
	{"id": "loja", "tipo": "loja", "nome": "Loja Tech", "area": Rect2i(20, 7, 7, 3), "altura": 76.0, "cor": Color("ec4899"), "parede": Color("fbe1ee")},
	{"id": "laranja", "tipo": "empresa", "area": Rect2i(32, 1, 3, 3), "altura": 150.0},
	{"id": "rubro", "tipo": "empresa", "area": Rect2i(36, 1, 3, 3), "altura": 140.0},
	{"id": "prisma", "tipo": "empresa", "area": Rect2i(40, 1, 3, 3), "altura": 132.0},
	{"id": "criptovault", "tipo": "empresa", "area": Rect2i(32, 7, 3, 3), "altura": 118.0},
	{"id": "telenova", "tipo": "empresa", "area": Rect2i(36, 7, 3, 3), "altura": 104.0},
	{"id": "beco", "tipo": "beco", "nome": "Beco Hacker", "area": Rect2i(1, 17, 4, 3), "altura": 78.0, "cor": Color("22c55e"), "parede": Color("3b3f4a")},
	{"id": "cafe_dev", "tipo": "cafe", "nome": "Café Dev", "area": Rect2i(7, 17, 4, 3), "altura": 72.0, "cor": Color("f97316"), "parede": Color("f6e7d5")},
	{"id": "saudemais", "tipo": "empresa", "area": Rect2i(1, 23, 3, 3), "altura": 98.0},
	{"id": "govdigital", "tipo": "empresa", "area": Rect2i(5, 23, 3, 3), "altura": 116.0},
	{"id": "neuroai", "tipo": "empresa", "area": Rect2i(9, 23, 3, 3), "altura": 128.0},
	{"id": "sede", "tipo": "sede", "nome": "Sua Sede", "area": Rect2i(17, 16, 9, 4), "altura": 150.0, "cor": Color("2dd4bf"), "parede": Color("bfe7ef")},
	{"id": "bolsa", "tipo": "bolsa", "nome": "Bolsa Tech", "area": Rect2i(32, 17, 5, 3), "altura": 104.0, "cor": Color("10b981"), "parede": Color("e3efe6")},
	{"id": "datacenter", "tipo": "datacenter", "nome": "Data Center da Cidade", "area": Rect2i(32, 23, 11, 4), "altura": 70.0, "cor": Color("38bdf8"), "parede": Color("cdd5df")},
	{"id": "zerosec", "tipo": "zerosec", "nome": "Hub ZeroSec", "area": Rect2i(48, 2, 6, 4), "altura": 118.0, "cor": Color("22d3ee"), "parede": Color("2b3040")},
	{"id": "arena", "tipo": "arena", "nome": "Arena CTF", "area": Rect2i(56, 2, 7, 5), "altura": 92.0, "cor": Color("a855f7"), "parede": Color("30294a")},
	{"id": "res1", "tipo": "decor", "nome": "Residencial Neon", "area": Rect2i(48, 9, 4, 3), "altura": 160.0, "cor": Color("f472b6"), "parede": Color("2e2b3d")},
	{"id": "res2", "tipo": "decor", "nome": "Torre Pixel", "area": Rect2i(54, 9, 4, 3), "altura": 136.0, "cor": Color("22d3ee"), "parede": Color("272c3c")},
	{"id": "res3", "tipo": "decor", "nome": "Edifício Matrix", "area": Rect2i(59, 9, 4, 3), "altura": 176.0, "cor": Color("facc15"), "parede": Color("2a2a36")},
	{"id": "imobiliaria", "tipo": "imobiliaria", "nome": "Imobiliária", "area": Rect2i(25, 32, 3, 3), "altura": 96.0, "cor": Color("f59e0b"), "parede": Color("f5ead6")},
]

var principal
var locais: Array = []
var jogador := Vector2(21.5, 21.2)
var direcao := 1
var caminho: Array = []
var interagir_ao_chegar: Dictionary = {}
var andando := false
var camera := Vector2.ZERO
var tempo := 0.0
var npcs: Array = []
var carros: Array = []
var estaticos: Array = []
var proximo: Dictionary = {}
var balao: Dictionary = {}
var pet_pos := Vector2.ZERO
var pet_direcao := 1
var mouse := Vector2.ZERO
var ultimo_salvo := 0.0
var solidos: Dictionary = {}
var solidos_base: Dictionary = {}
var astar := AStarGrid2D.new()
var gerador_npc := RandomNumberGenerator.new()
var predio_hover := ""
var alvo
var malha_chao: ArrayMesh
var malha_minimapa: ArrayMesh
var camada_rotulos := Node2D.new()
var camada_hud := Node2D.new()
var assinatura_rotulos := ""
var malhas_predios: Dictionary = {}
var chave_cidade := ""
var estaticos_visiveis: Array = []
var camera_estaticos := Vector2(-10000, -10000)


func estado():
	return Estado.atual


func _ready() -> void:
	alvo = self
	astar.region = Rect2i(0, 0, LARGURA, ALTURA)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	montar_locais()
	for x in range(21, 23):
		for y in range(24, 26):
			solidos_base[Vector2i(x, y)] = true
	estaticos.append({"tipo": "fonte", "caixa": Rect2(21, 24, 2, 2)})
	for banco in [Vector2i(18, 23), Vector2i(25, 23), Vector2i(18, 27), Vector2i(25, 27)]:
		solidos_base[banco] = true
		estaticos.append({"tipo": "banco", "caixa": Rect2(Vector2(banco), Vector2(1, 1))})
	for d in Dados.DISPOSITIVOS:
		var pos: Vector2 = d["pos"]
		solidos_base[Vector2i(floori(pos.x), floori(pos.y))] = true
		estaticos.append({"tipo": "dispositivo", "dados": d, "caixa": Rect2(pos - Vector2(0.2, 0.2), Vector2(0.4, 0.4))})
	criar_arvores()
	for x in LARGURA:
		for y in ALTURA:
			var c := Vector2i(x, y)
			if tipo_tile(x, y) == "calcada" and (x * 3 + y * 7) % 11 == 0 and not perto_de_porta(c) and not solidos_base.has(c):
				estaticos.append({"tipo": "poste", "caixa": Rect2(x + 0.42, y + 0.42, 0.16, 0.16)})
	aplicar_solidos()
	criar_carros()
	add_child(camada_rotulos)
	add_child(camada_hud)
	camada_rotulos.draw.connect(func(): desenhar_rotulos_fixos(camada_rotulos))
	camada_hud.draw.connect(func(): desenhar_hud(camada_hud))
	construir_malhas()


func terrenos_atuais() -> Dictionary:
	if estado() == null or estado().perfil.is_empty():
		return {}
	return estado().perfil.get("terrenos", {})


func montar_locais() -> void:
	locais = []
	for l in LOCAIS:
		locais.append(l)
	var terrenos := terrenos_atuais()
	for lote in Dados.LOTES:
		var existente: Dictionary = Dados.IMOVEIS_EXISTENTES.get(lote["id"], {})
		var comprado: bool = terrenos.has(lote["id"])
		var c := String(terrenos.get(lote["id"], "" if existente.is_empty() else existente["tipo"]))
		var preco: float = float(existente.get("preco", lote["preco"]))
		var l := {"id": lote["id"], "tipo": "lote", "lote": lote["id"], "nome": lote["nome"], "area": lote["area"], "altura": 0.0, "cor": Color("a78bfa"), "parede": Color("ece6fb"), "construcao": c, "comprado": comprado, "preco": preco}
		if c == "startup":
			l["id"] = "startup"
			l["tipo"] = "startup"
			l["altura"] = 124.0
		elif Dados.CONSTRUCOES.has(c):
			var dados: Dictionary = Dados.CONSTRUCOES[c]
			l["altura"] = dados["altura"]
			l["cor"] = dados["cor"]
			l["parede"] = dados["parede"]
			l["nome"] = dados["nome"]
			if not existente.is_empty() and c == existente["tipo"] and (not comprado or lote["id"] in estado().perfil.get("imoveis_adquiridos", [])):
				l["nome"] = existente["nome"]
		locais.append(l)
	estaticos = estaticos.filter(func(e): return e["tipo"] != "predio")
	for l in locais:
		var a: Rect2i = l["area"]
		estaticos.append({"tipo": "predio", "local": l, "caixa": Rect2(Vector2(a.position), Vector2(a.size))})
	camera_estaticos = Vector2(-10000, -10000)


func bloqueia(l: Dictionary) -> bool:
	return l["tipo"] != "lote" or String(l.get("construcao", "")) != ""


func aplicar_solidos() -> void:
	solidos = solidos_base.duplicate()
	for l in locais:
		if bloqueia(l):
			var a: Rect2i = l["area"]
			for x in range(a.position.x, a.end.x):
				for y in range(a.position.y, a.end.y):
					solidos[Vector2i(x, y)] = true
	astar.fill_solid_region(astar.region, false)
	for c in solidos:
		astar.set_point_solid(c, true)


func em_lote(c: Vector2i) -> bool:
	for lote in Dados.LOTES:
		var a: Rect2i = lote["area"]
		if a.has_point(c):
			return true
	return false


func perto_de_porta(c: Vector2i) -> bool:
	for l in locais:
		var p := porta(l)
		if absf(c.x + 0.5 - p.x) <= 1.6 and c.y >= int(p.y) - 1 and c.y <= int(p.y) + 1:
			return true
	return false


func criar_arvores() -> void:
	var gerador := RandomNumberGenerator.new()
	gerador.seed = 4242
	var zonas := [Rect2i(40, 6, 3, 6), Rect2i(6, 16, 6, 6), Rect2i(0, 0, 44, 1), Rect2i(0, 27, 13, 1), Rect2i(16, 21, 1, 7), Rect2i(27, 21, 1, 7), Rect2i(0, 12, 1, 3), Rect2i(37, 21, 6, 1), Rect2i(0, 43, 64, 1), Rect2i(10, 32, 2, 11), Rect2i(41, 32, 2, 11), Rect2i(25, 36, 3, 7), Rect2i(61, 32, 3, 11), Rect2i(0, 32, 1, 11)]
	var plantadas: Array = []
	for zona in zonas:
		for x in range(zona.position.x, zona.end.x):
			for y in range(zona.position.y, zona.end.y):
				var c := Vector2i(x, y)
				var tipo := tipo_tile(x, y)
				if solidos_base.has(c) or perto_de_porta(c) or tipo != "grama" or em_lote(c) or ocupado_por_local(c):
					continue
				if gerador.randf() < 0.5:
					plantadas.append(c)
					solidos_base[c] = true
					estaticos.append({"tipo": "arvore", "caixa": Rect2(Vector2(c), Vector2(1, 1)), "escala": gerador.randf_range(0.85, 1.2), "tom": gerador.randi() % 3})
	aplicar_solidos()
	var inicio := Vector2i(porta(local_por_id("sede")))
	for l in locais:
		if astar.get_id_path(inicio, Vector2i(porta(l))).is_empty():
			for c2 in plantadas:
				solidos_base.erase(c2)
			estaticos = estaticos.filter(func(e): return e["tipo"] != "arvore")
			aplicar_solidos()
			return


func ocupado_por_local(c: Vector2i) -> bool:
	for l in locais:
		var a: Rect2i = l["area"]
		if a.has_point(c):
			return true
	return false


func criar_carros() -> void:
	var cores := [Color("ef4444"), Color("3b82f6"), Color("facc15"), Color("f8fafc"), Color("10b981"), Color("f97316"), Color("a855f7")]
	var faixas := [["y", 13.5, 1], ["y", 14.5, -1], ["y", 29.5, 1], ["y", 30.5, -1], ["x", 13.5, 1], ["x", 14.5, -1], ["y", 44.5, 1], ["y", 45.5, -1], ["x", 29.5, 1], ["x", 30.5, -1]]
	var quantidade := 6 if graficos_leves() else 14
	for i in quantidade:
		var f: Array = faixas[i % faixas.size()]
		var comprimento: float = ALTURA if f[0] == "y" else LARGURA
		carros.append({"eixo": f[0], "faixa": f[1], "sentido": f[2], "t": fmod(i * 7.3, comprimento), "comprimento": comprimento, "cor": cores[i % cores.size()], "vel": 2.2 + (i % 3) * 0.5})
		var anterior = alvo
		alvo = Malha.new()
		desenhar_carro(carros[carros.size() - 1], Vector2.ZERO)
		carros[carros.size() - 1]["malha"] = alvo.gerar()
		alvo = anterior


func graficos_leves() -> bool:
	return estado() != null and not estado().perfil.is_empty() and estado().perfil.get("graficos_leves", false)


func tipo_tile(x: int, y: int) -> String:
	if x in RUAS_X or y in RUAS_Y:
		return "rua"
	if x in CALCADAS_X or y in CALCADAS_Y:
		return "calcada"
	if PRACA.has_point(Vector2i(x, y)):
		return "praca"
	if em_lote(Vector2i(x, y)):
		return "terra"
	if DISTRITO_NEON.has_point(Vector2i(x, y)):
		return "neon"
	return "grama"


func centro_area(a: Rect2i) -> Vector2:
	return Vector2(a.position) + Vector2(a.size) * 0.5


func iso(p: Vector2) -> Vector2:
	return ORIGEM + Vector2((p.x - p.y) * MEIO_TILE.x, (p.x + p.y) * MEIO_TILE.y)


func tela_para_mundo(s: Vector2) -> Vector2:
	var d := s - ORIGEM
	return Vector2((d.x / MEIO_TILE.x + d.y / MEIO_TILE.y) * 0.5, (d.y / MEIO_TILE.y - d.x / MEIO_TILE.x) * 0.5)


func local_por_id(id: String) -> Dictionary:
	for l in locais:
		if l["id"] == id:
			return l
	return {}


func local_do_lote(id: String) -> Dictionary:
	for l in locais:
		if l.get("lote", "") == id:
			return l
	return {}


func porta(local: Dictionary) -> Vector2:
	var a: Rect2i = local["area"]
	return Vector2(a.position.x + a.size.x * 0.5, a.end.y + 0.55)


func livre(p: Vector2, raio := 0.2) -> bool:
	for canto in [Vector2(-raio, -raio), Vector2(raio, -raio), Vector2(-raio, raio), Vector2(raio, raio)]:
		var q: Vector2 = p + canto
		if q.x < 0.0 or q.y < 0.0 or q.x >= LARGURA or q.y >= ALTURA:
			return false
		if solidos.has(Vector2i(floori(q.x), floori(q.y))):
			return false
	return true


func nome_local(local: Dictionary) -> String:
	if local["tipo"] == "empresa":
		return Dados.empresa_por_id(local["id"])["nome"]
	if local["tipo"] == "startup" and not estado().perfil.get("startup", {}).is_empty():
		return estado().perfil["startup"]["nome"]
	return local["nome"]


func cor_local(l: Dictionary) -> Color:
	if l["tipo"] == "empresa":
		return Dados.empresa_por_id(l["id"])["cor"]
	if l["tipo"] == "startup" and not estado().perfil.get("startup", {}).is_empty():
		return Dados.CORES_LOGO[int(estado().perfil["startup"]["logo"]["cor"])]
	return l["cor"]


func parede_local(l: Dictionary) -> Color:
	if l.has("parede"):
		return l["parede"]
	return PAREDES[absi(hash(l["id"])) % PAREDES.size()]


func preparar() -> void:
	atualizar_cidade()
	var pos: Array = estado().perfil.get("mundo", [])
	jogador = porta(local_por_id("sede")) + Vector2(0, 0.7)
	if pos.size() == 2:
		var salvo := Vector2(float(pos[0]), float(pos[1]))
		if livre(salvo):
			jogador = salvo
	pet_pos = jogador + Vector2(-0.6, 0.3)
	caminho = []
	interagir_ao_chegar = {}
	balao = {}
	criar_npcs()
	atualizar_camera(1.0)


func criar_npcs() -> void:
	npcs = []
	var gerador := RandomNumberGenerator.new()
	gerador.seed = 777
	gerador_npc.seed = 99
	for i in (QUANTIDADE_NPCS_LEVE if graficos_leves() else QUANTIDADE_NPCS):
		var feminino := (i + 1) % 2
		var cabelos: Array = [1, 3, 4, 7] if feminino == 1 else [0, 2, 3, 5, 6]
		var aparencia := {"corpo": feminino, "pele": gerador.randi() % Dados.CORES_PELE.size(), "cabelo": cabelos[gerador.randi() % cabelos.size()], "cor_cabelo": gerador.randi() % 6, "roupa": gerador.randi() % 3, "cor_roupa": gerador.randi() % Dados.CORES_ROUPA.size(), "olhos": gerador.randi() % 3}
		var equipados := {"acessorio": ["", "", "oculos_hacker", "headset", "oculos_nerd", "fone_grande", "", "mascara_led"][gerador.randi() % 8], "chapeu": ["", "", "", "bone", "gorro", "bone_tras"][gerador.randi() % 6], "roupa": ["", "", "capuz", "jaleco", "terno", "xadrez", "camiseta_dev", "jaqueta", "capuz_hacker"][gerador.randi() % 9]}
		var pos := Vector2.ZERO
		for tentativa in 50:
			var c := Vector2i(gerador.randi() % LARGURA, gerador.randi() % ALTURA)
			if tipo_tile(c.x, c.y) in ["calcada", "praca"] and not solidos.has(c):
				pos = Vector2(c) + Vector2(0.5, 0.5)
				break
		npcs.append({"nome": Dados.NOMES_NPC[i % Dados.NOMES_NPC.size()], "pos": pos, "caminho": [], "aparencia": aparencia, "equipados": equipados, "velocidade": gerador.randf_range(1.4, 2.2), "espera": gerador.randf_range(0, 3), "dica": gerador.randi() % Textos.DICAS_NPC.size(), "direcao": 1, "andando": false})


func calcular_caminho(de: Vector2, para: Vector2) -> Array:
	var origem := Vector2i(clampi(floori(de.x), 0, LARGURA - 1), clampi(floori(de.y), 0, ALTURA - 1))
	var destino := Vector2i(clampi(floori(para.x), 0, LARGURA - 1), clampi(floori(para.y), 0, ALTURA - 1))
	if solidos.has(destino):
		return []
	var ids: Array = astar.get_id_path(origem, destino, true) if not solidos.has(origem) else []
	if ids.is_empty():
		return []
	var lista: Array = []
	for k in range(1, ids.size()):
		lista.append(Vector2(ids[k]) + Vector2(0.5, 0.5))
	if livre(para):
		if lista.is_empty():
			lista.append(para)
		else:
			lista[lista.size() - 1] = para
	return lista


func _process(delta: float) -> void:
	if not visible:
		return
	if principal.modal_aberto():
		if assinatura_cidade() != chave_cidade:
			atualizar_cidade()
		return
	tempo += delta
	mouse = get_local_mouse_position()
	if not principal.modal_aberto():
		mover_jogador(delta)
	atualizar_npcs(delta)
	atualizar_carros(delta)
	var alvo_pet := jogador + Vector2(-0.55 * direcao, 0.45 * direcao)
	if pet_pos.distance_to(alvo_pet) > 0.05:
		var novo := pet_pos.lerp(alvo_pet, minf(1.0, delta * 3.0))
		if (novo - pet_pos).x - (novo - pet_pos).y != 0.0:
			pet_direcao = 1 if (novo - pet_pos).x - (novo - pet_pos).y > 0.0 else -1
		pet_pos = novo
	atualizar_camera(delta)
	atualizar_proximo()
	if assinatura_cidade() != chave_cidade:
		atualizar_cidade()
	atualizar_hover()
	atualizar_camadas()
	if not balao.is_empty():
		balao["tempo"] -= delta
		if balao["tempo"] <= 0.0:
			balao = {}
	ultimo_salvo += delta
	if ultimo_salvo > 5.0:
		ultimo_salvo = 0.0
		guardar_posicao()
	queue_redraw()


func atualizar_camadas() -> void:
	camada_rotulos.position = -camera.round()
	var partes := [predio_hover, estado().nivel(), assinatura_cidade()]
	for e in Dados.EMPRESAS:
		partes.append(estado().eh_dono(e["id"]))
		partes.append(not estado().obter_operacao(e["id"]).is_empty())
	var assinatura := str(partes)
	if assinatura != assinatura_rotulos:
		assinatura_rotulos = assinatura
		camada_rotulos.queue_redraw()
	camada_hud.queue_redraw()


func guardar_posicao() -> void:
	if estado().perfil.is_empty():
		return
	estado().perfil["mundo"] = [jogador.x, jogador.y]


func mover_jogador(delta: float) -> void:
	var tela := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		tela.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		tela.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		tela.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		tela.y += 1
	var movimento := Vector2.ZERO
	if tela != Vector2.ZERO:
		caminho = []
		interagir_ao_chegar = {}
		movimento = Vector2(tela.x + tela.y, tela.y - tela.x).normalized() * VELOCIDADE * delta
		var tentativa := jogador + Vector2(movimento.x, 0)
		if livre(tentativa):
			jogador = tentativa
		var tentativa2 := jogador + Vector2(0, movimento.y)
		if livre(tentativa2):
			jogador = tentativa2
	elif not caminho.is_empty():
		var alvo: Vector2 = caminho[0]
		var falta := alvo - jogador
		var passo := VELOCIDADE * delta
		if falta.length() <= passo:
			jogador = alvo
			caminho.pop_front()
		else:
			jogador += falta.normalized() * passo
		movimento = falta
		if caminho.is_empty() and not interagir_ao_chegar.is_empty():
			var destino := interagir_ao_chegar
			interagir_ao_chegar = {}
			interagir(destino)
	andando = movimento != Vector2.ZERO
	if andando and absf(movimento.x - movimento.y) > 0.001:
		direcao = 1 if movimento.x - movimento.y > 0.0 else -1


func atualizar_npcs(delta: float) -> void:
	for n in npcs:
		if n["espera"] > 0.0:
			n["espera"] -= delta
			n["andando"] = false
			continue
		if n["caminho"].is_empty():
			for tentativa in 6:
				var alvo := Vector2i(clampi(floori(n["pos"].x) + gerador_npc.randi_range(-7, 7), 0, LARGURA - 1), clampi(floori(n["pos"].y) + gerador_npc.randi_range(-7, 7), 0, ALTURA - 1))
				if solidos.has(alvo) or tipo_tile(alvo.x, alvo.y) == "rua":
					continue
				var rota := calcular_caminho(n["pos"], Vector2(alvo) + Vector2(0.5, 0.5))
				if not rota.is_empty() and rota.size() < 22:
					n["caminho"] = rota
					break
			n["espera"] = gerador_npc.randf_range(1.0, 4.0) if n["caminho"].is_empty() else 0.0
			continue
		var alvo2: Vector2 = n["caminho"][0]
		var falta: Vector2 = alvo2 - n["pos"]
		var passo: float = n["velocidade"] * delta
		if falta.length() <= passo:
			n["pos"] = alvo2
			n["caminho"].pop_front()
			if n["caminho"].is_empty():
				n["espera"] = gerador_npc.randf_range(1.5, 5.0)
		else:
			n["pos"] += falta.normalized() * passo
		n["andando"] = true
		if absf(falta.x - falta.y) > 0.001:
			n["direcao"] = 1 if falta.x - falta.y > 0.0 else -1


func atualizar_carros(delta: float) -> void:
	for c in carros:
		c["t"] = fmod(c["t"] + c["vel"] * delta, c["comprimento"] + 4.0)


func posicao_carro(c: Dictionary) -> Vector2:
	var t: float = c["t"] - 2.0
	if c["sentido"] < 0:
		t = c["comprimento"] - t
	return Vector2(c["faixa"], t) if c["eixo"] == "y" else Vector2(t, c["faixa"])


func atualizar_camera(delta: float) -> void:
	var desejado := iso(jogador) - Vector2(640, 400)
	desejado.x = clampf(desejado.x, 0.0, TAMANHO_TELA.x - 1280.0)
	desejado.y = clampf(desejado.y, 0.0, TAMANHO_TELA.y - 720.0)
	camera = camera.lerp(desejado, minf(1.0, delta * 6.0))


func atualizar_proximo() -> void:
	proximo = {}
	var melhor := RAIO_INTERACAO
	for l in locais:
		if l["tipo"] == "decor":
			continue
		var d := jogador.distance_to(porta(l))
		if d < melhor:
			melhor = d
			proximo = {"tipo": "local", "local": l}
	for disp in Dados.DISPOSITIVOS:
		var d3: float = jogador.distance_to(disp["pos"])
		if d3 < 1.3 and d3 < melhor:
			melhor = d3
			proximo = {"tipo": "dispositivo", "dados": disp}
	for i in npcs.size():
		var d2: float = jogador.distance_to(npcs[i]["pos"])
		if d2 < 1.1 and d2 < melhor:
			melhor = d2
			proximo = {"tipo": "npc", "indice": i}


func silhueta(l: Dictionary) -> PackedVector2Array:
	var a: Rect2i = l["area"]
	var u := Vector2(0, -float(l["altura"]))
	var topo := iso(Vector2(a.position))
	var direita := iso(Vector2(a.end.x, a.position.y))
	var baixo := iso(Vector2(a.end))
	var esquerda := iso(Vector2(a.position.x, a.end.y))
	return PackedVector2Array([esquerda + u, topo + u, direita + u, direita, baixo, esquerda])


func predio_em(tela_mundo: Vector2) -> Dictionary:
	var achado: Dictionary = {}
	var melhor := -INF
	for l in locais:
		if Geometry2D.is_point_in_polygon(tela_mundo, silhueta(l)):
			var a: Rect2i = l["area"]
			var profundidade := float(a.end.x + a.end.y)
			if profundidade > melhor:
				melhor = profundidade
				achado = l
	return achado


func atualizar_hover() -> void:
	predio_hover = ""
	if principal.modal_aberto() or RET_MINIMAPA.has_point(mouse) or RET_BOTAO_MISSOES.has_point(mouse) or RET_BOTAO_SEDE.has_point(mouse):
		return
	var l := predio_em(mouse + camera)
	if not l.is_empty():
		predio_hover = l["id"]


func texto_prompt() -> String:
	if proximo.is_empty():
		return ""
	if proximo["tipo"] == "npc":
		return "Conversar com %s" % npcs[proximo["indice"]]["nome"]
	if proximo["tipo"] == "dispositivo":
		var disp: Dictionary = proximo["dados"]
		if estado().pentest_feito(disp["id"]):
			return "%s: já testado hoje" % disp["nome"]
		return "Pentest autorizado: %s" % disp["nome"]
	var l: Dictionary = proximo["local"]
	match l["tipo"]:
		"empresa":
			return "Entrar na %s" % nome_local(l)
		"datacenter":
			return "Visitar o Data Center"
		"startup":
			return "Abrir %s" % nome_local(l)
		"lote":
			if not l["comprado"]:
				return "%s à venda: %s" % [l["nome"], Visual.dinheiro(l["preco"])]
			if String(l["construcao"]) == "":
				return "Construir no seu terreno"
			return "Entrar: %s" % nome_local(l)
	return "Entrar: %s" % nome_local(l)


func interagir(destino: Dictionary) -> void:
	if destino.is_empty():
		return
	if destino["tipo"] == "npc":
		var n: Dictionary = npcs[destino["indice"]]
		n["dica"] = (int(n["dica"]) + 1) % Textos.DICAS_NPC.size()
		n["direcao"] = 1 if (jogador - n["pos"]).x - (jogador - n["pos"]).y > 0.0 else -1
		n["espera"] = 4.0
		n["caminho"] = []
		balao = {"indice": destino["indice"], "texto": Textos.DICAS_NPC[n["dica"]], "tempo": 6.0}
		estado().somar("conversas")
		return
	if destino["tipo"] == "dispositivo":
		guardar_posicao()
		principal.abrir_painel("pentest", {"id": destino["dados"]["id"]})
		return
	var l: Dictionary = destino["local"]
	guardar_posicao()
	estado().somar("visitou_%s" % l["tipo"])
	match l["tipo"]:
		"empresa":
			principal.abrir_painel("empresa", {"id": l["id"]})
		"datacenter":
			principal.avisar("Data Center: aqui ficam as torres de verdade. Energia redundante, refrigeração e backups fora do prédio.", Visual.DESTAQUE, "backup")
		"lote":
			if String(l.get("construcao", "")) == "cafe":
				principal.abrir_painel("cafe", {})
			else:
				principal.abrir_painel("terreno", {"id": l["lote"]})
		"decor":
			principal.avisar("%s: prédio residencial do Distrito Neon." % l["nome"], Visual.DESTAQUE)
		_:
			principal.abrir_painel(l["tipo"], {})


func _unhandled_input(event: InputEvent) -> void:
	if not visible or principal.modal_aberto():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var e := make_input_local(event) as InputEventMouseButton
		clicar(e.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E, KEY_SPACE, KEY_ENTER:
				interagir(proximo)
			KEY_M:
				principal.abrir_painel("missoes", {})
			KEY_ESCAPE:
				principal.abrir_painel("sede", {})


func clicar(pos: Vector2) -> void:
	if RET_GUIA.has_point(pos) and not estado().missoes_ativas().is_empty():
		seguir_guia()
		return
	if RET_BOTAO_MISSOES.has_point(pos):
		principal.abrir_painel("missoes", {})
		return
	if RET_BOTAO_SEDE.has_point(pos):
		principal.abrir_painel("sede", {})
		return
	if not proximo.is_empty() and RET_PROMPT.has_point(pos):
		interagir(proximo)
		return
	if RET_MINIMAPA.has_point(pos):
		ir_para(tela_para_mundo((pos - deslocamento_minimapa()) / escala_minimapa()))
		return
	var tela_mundo := pos + camera
	for i in npcs.size():
		if (iso(npcs[i]["pos"]) + Vector2(0, -28)).distance_to(tela_mundo) < 24.0:
			var vizinho: Vector2 = npcs[i]["pos"] + Vector2(0.8, 0.0)
			if not livre(vizinho):
				vizinho = npcs[i]["pos"] + Vector2(0.0, 0.8)
			ir_para(vizinho)
			interagir_ao_chegar = {"tipo": "npc", "indice": i}
			if caminho.is_empty():
				interagir(interagir_ao_chegar)
				interagir_ao_chegar = {}
			return
	var l := predio_em(tela_mundo)
	if not l.is_empty():
		if jogador.distance_to(porta(l)) < RAIO_INTERACAO:
			interagir({"tipo": "local", "local": l})
			return
		ir_para(porta(l))
		interagir_ao_chegar = {"tipo": "local", "local": l}
		return
	ir_para(tela_para_mundo(tela_mundo))


func seguir_guia() -> void:
	var ativas: Array = estado().missoes_ativas()
	if ativas.is_empty():
		principal.abrir_painel("missoes", {})
		return
	var missao: Dictionary = ativas[0]
	if estado().missao_concluida(missao):
		principal.abrir_painel("missoes", {})
		return
	var destino_por_missao := {
		"m_cidade": "missoes", "m_contrato": "mercadonet", "m_waf": "mercadonet",
		"m_licoes": "academia", "m_lab": "beco", "m_escala": "mercadonet",
		"m_loja": "loja", "m_backup": "mercadonet", "m_onda": "mercadonet",
		"m_incidente": "mercadonet", "m_compra": "bolsa", "m_startup": "imobiliaria",
		"m_terreno": "imobiliaria", "m_pentest": "zerosec", "m_auditoria": "zerosec", "m_construtor": "imobiliaria", "m_imovel": "imobiliaria"
	}
	var id: String = destino_por_missao.get(missao["id"], "missoes")
	var local := local_por_id(id)
	if local.is_empty():
		principal.abrir_painel("missoes", {})
		return
	ir_para(porta(local))
	if not caminho.is_empty():
		interagir_ao_chegar = {"tipo": "local", "local": local}
	elif jogador.distance_to(porta(local)) < RAIO_INTERACAO:
		interagir({"tipo": "local", "local": local})
	else:
		principal.avisar("Caminho bloqueado. Abra o mapa e escolha outra rota.", Visual.PERIGO)


func ir_para(destino: Vector2) -> void:
	destino = Vector2(clampf(destino.x, 0.3, LARGURA - 0.3), clampf(destino.y, 0.3, ALTURA - 0.3))
	interagir_ao_chegar = {}
	caminho = calcular_caminho(jogador, destino)
	if caminho.is_empty() and solidos.has(Vector2i(floori(destino.x), floori(destino.y))):
		var melhor := Vector2.ZERO
		var menor := INF
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var c := Vector2(floori(destino.x) + dx, floori(destino.y) + dy) + Vector2(0.5, 0.5)
				if livre(c) and c.distance_to(destino) < menor:
					menor = c.distance_to(destino)
					melhor = c
		if menor < INF:
			caminho = calcular_caminho(jogador, melhor)


func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(0, 0, 1280, 720), Color("1d2a3f"))
	draw_set_transform(-camera.round(), 0.0, Vector2.ONE)
	draw_mesh(malha_chao, null)
	desenhar_objetos()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func visivel_tela(p: Vector2, margem := 80.0) -> bool:
	return Rect2(camera - Vector2(margem, margem), Vector2(1280, 720) + Vector2(margem, margem) * 2).has_point(p)


func losango_tile(x: float, y: float, w := 1.0, d := 1.0) -> PackedVector2Array:
	return PackedVector2Array([iso(Vector2(x, y)), iso(Vector2(x + w, y)), iso(Vector2(x + w, y + d)), iso(Vector2(x, y + d))])


func construir_malhas() -> void:
	alvo = Malha.new()
	desenhar_chao()
	malha_chao = alvo.gerar()
	for e in estaticos:
		alvo = Malha.new()
		match e["tipo"]:
			"arvore":
				desenhar_arvore(e)
			"poste":
				desenhar_poste(e["caixa"].get_center())
			"banco":
				desenhar_banco(e["caixa"].position)
			_:
				continue
		e["malha"] = alvo.gerar()
	for c in carros:
		alvo = Malha.new()
		desenhar_carro(c, Vector2.ZERO)
		c["malha"] = alvo.gerar()
	alvo = self
	construir_predios()


func atualizar_cidade() -> void:
	montar_locais()
	aplicar_solidos()
	construir_predios()
	queue_redraw()
	camada_rotulos.queue_redraw()
	camada_hud.queue_redraw()
	if not livre(jogador):
		for l in locais:
			var a: Rect2i = l["area"]
			if a.has_point(Vector2i(floori(jogador.x), floori(jogador.y))):
				jogador = porta(l)
		caminho = []


func construir_predios() -> void:
	malhas_predios = {}
	for l in locais:
		alvo = Malha.new()
		desenhar_predio_base(l)
		malhas_predios[l["id"]] = alvo.gerar()
	alvo = self
	chave_cidade = assinatura_cidade()
	construir_minimapa()


func assinatura_cidade() -> String:
	if estado() == null or estado().perfil.is_empty():
		return ""
	return JSON.stringify([estado().perfil.get("startup", {}), estado().perfil.get("terrenos", {})])


func desenhar_chao() -> void:
	var bl := iso(Vector2(0, ALTURA))
	var br := iso(Vector2(LARGURA, ALTURA))
	var tr := iso(Vector2(LARGURA, 0))
	var profundidade := Vector2(0, 26)
	alvo.draw_colored_polygon(PackedVector2Array([bl, br, br + profundidade, bl + profundidade]), Color("6b4a2e"))
	alvo.draw_colored_polygon(PackedVector2Array([br, tr, tr + profundidade, br + profundidade]), Color("4f3621"))
	alvo.draw_line(bl + Vector2(0, 8), br + Vector2(0, 8), Color("4f8f33"), 3.0)
	alvo.draw_line(br + Vector2(0, 8), tr + Vector2(0, 8), Color("3f7a28"), 3.0)
	for x in LARGURA:
		for y in ALTURA:
			var centro := iso(Vector2(x + 0.5, y + 0.5))
			var tipo := tipo_tile(x, y)
			var par := (x + y) % 2 == 0
			var cor: Color
			match tipo:
				"rua":
					cor = Color("4a5061")
				"calcada":
					cor = Color("d8d4cc") if par else Color("cfcac1")
				"praca":
					cor = Color("ecdcb4") if par else Color("e2cf9f")
				"terra":
					cor = Color("b88a55") if par else Color("ad7f4b")
				"neon":
					cor = Color("2b3046") if par else Color("262a3e")
				_:
					cor = Color("6fc04a") if par else Color("66b743")
			var pontos := losango_tile(x, y)
			alvo.draw_colored_polygon(pontos, cor)
			if tipo == "calcada" or tipo == "praca":
				alvo.draw_polyline(PackedVector2Array([pontos[3], pontos[0], pontos[1]]), cor.darkened(0.1), 1.0)
			elif tipo == "grama" and (x * 7 + y * 13) % 9 == 0:
				alvo.draw_line(centro + Vector2(-6, 2), centro + Vector2(-4, -3), Color("4f9a30"), 2.0)
				alvo.draw_line(centro + Vector2(3, 3), centro + Vector2(5, -2), Color("4f9a30"), 2.0)
			elif tipo == "neon" and (x + y * 3) % 7 == 0:
				alvo.draw_polyline(PackedVector2Array([pontos[3], pontos[0], pontos[1]]), Color(0.13, 0.83, 0.93, 0.35), 1.0)
			elif tipo == "rua":
				desenhar_faixas(x, y)


func desenhar_faixas(x: int, y: int) -> void:
	if x in RUAS_X and y in RUAS_Y:
		return
	if x in RUAS_X and x % 2 == 0 and y % 2 == 0:
		alvo.draw_line(iso(Vector2(x, y + 0.15)), iso(Vector2(x, y + 0.85)), Color("f1e5a5"), 2.0)
	elif y in RUAS_Y and y % 2 == 0 and x % 2 == 0:
		alvo.draw_line(iso(Vector2(x + 0.15, y)), iso(Vector2(x + 0.85, y)), Color("f1e5a5"), 2.0)
	if x in RUAS_X and (y + 1 in RUAS_Y or y - 1 in RUAS_Y):
		for k in 4:
			var t := 0.12 + k * 0.22
			alvo.draw_colored_polygon(PackedVector2Array([iso(Vector2(x + t, y + 0.1)), iso(Vector2(x + t + 0.11, y + 0.1)), iso(Vector2(x + t + 0.11, y + 0.9)), iso(Vector2(x + t, y + 0.9))]), Color("eef0f2"))
	elif y in RUAS_Y and (x + 1 in RUAS_X or x - 1 in RUAS_X):
		for k in 4:
			var t2 := 0.12 + k * 0.22
			alvo.draw_colored_polygon(PackedVector2Array([iso(Vector2(x + 0.1, y + t2)), iso(Vector2(x + 0.9, y + t2)), iso(Vector2(x + 0.9, y + t2 + 0.11)), iso(Vector2(x + 0.1, y + t2 + 0.11))]), Color("eef0f2"))


func caixa_ponto(p: Vector2) -> Rect2:
	return Rect2(p - Vector2(0.2, 0.2), Vector2(0.4, 0.4))


func antes(a: Dictionary, b: Dictionary) -> bool:
	var ra: Rect2 = a["caixa"]
	var rb: Rect2 = b["caixa"]
	var sobre_y := ra.position.y < rb.end.y and rb.position.y < ra.end.y
	var sobre_x := ra.position.x < rb.end.x and rb.position.x < ra.end.x
	if sobre_y:
		if ra.position.x >= rb.end.x - 0.001:
			return false
		if rb.position.x >= ra.end.x - 0.001:
			return true
	if sobre_x:
		if ra.position.y >= rb.end.y - 0.001:
			return false
		if rb.position.y >= ra.end.y - 0.001:
			return true
	var ca := ra.get_center()
	var cb := rb.get_center()
	return ca.x + ca.y < cb.x + cb.y


func desenhar_objetos() -> void:
	var lista: Array = []
	if camera.distance_to(camera_estaticos) >= 24.0:
		camera_estaticos = camera
		estaticos_visiveis = []
		for e in estaticos:
			var r: Rect2 = e["caixa"]
			var tela := iso(r.get_center())
			if visivel_tela(tela, 452.0 if e["tipo"] == "predio" else 152.0):
				estaticos_visiveis.append(e)
	lista.append_array(estaticos_visiveis)
	for i in npcs.size():
		if visivel_tela(iso(npcs[i]["pos"])):
			lista.append({"tipo": "npc", "indice": i, "caixa": caixa_ponto(npcs[i]["pos"])})
	for c in carros:
		var p := posicao_carro(c)
		if visivel_tela(iso(p), 100.0):
			var tamanho := Vector2(1.1, 0.55) if c["eixo"] == "x" else Vector2(0.55, 1.1)
			lista.append({"tipo": "carro", "carro": c, "pos": p, "caixa": Rect2(p - tamanho / 2, tamanho)})
	if estado().perfil.get("equipados", {}).get("pet", "") != "":
		lista.append({"tipo": "pet", "caixa": caixa_ponto(pet_pos)})
	lista.append({"tipo": "jogador", "caixa": caixa_ponto(jogador)})
	lista.sort_custom(antes)
	if not caminho.is_empty():
		var fim: Vector2 = caminho[caminho.size() - 1]
		var c2 := iso(fim)
		var pulso := 1.0 + sin(tempo * 8.0) * 0.12
		Visual.elipse(self, c2, Vector2(14, 7) * pulso, Color(1, 1, 1, 0.35))
		Visual.elipse(self, c2, Vector2(8, 4) * pulso, Color("38bdf8"))
	for item in lista:
		desenhar_item(item)


func desenhar_item(item: Dictionary) -> void:
	if true:
		match item["tipo"]:
			"predio":
				var l: Dictionary = item["local"]
				draw_mesh(malhas_predios[l["id"]], null)
				desenhar_predio_extras(l)
			"arvore":
				draw_mesh(item["malha"], null)
			"poste":
				draw_mesh(item["malha"], null)
			"banco":
				draw_mesh(item["malha"], null)
			"dispositivo":
				desenhar_dispositivo(item["dados"])
			"fonte":
				desenhar_fonte()
			"carro":
				draw_mesh(item["carro"]["malha"], null, Transform2D(0.0, iso(item["pos"]) - iso(Vector2.ZERO)))
			"npc":
				var n: Dictionary = npcs[item["indice"]]
				Visual.avatar(self, iso(n["pos"]), 1.0, n["aparencia"], n["equipados"], tempo + item["indice"], n["andando"], n["direcao"])
			"pet":
				Visual.pet(self, iso(pet_pos), estado().perfil["equipados"]["pet"], tempo, pet_direcao)
			"jogador":
				Visual.avatar(self, iso(jogador), 1.0, estado().perfil.get("avatar", {}), estado().perfil.get("equipados", {}), tempo, andando, direcao)


func desenhar_dispositivo(d: Dictionary) -> void:
	var c := iso(d["pos"])
	var feito: bool = estado().pentest_feito(d["id"])
	var luz := Color("34d399") if feito else (Color("ef4444") if int(tempo * 2.0) % 2 == 0 else Color("7f1d1d"))
	Visual.elipse(self, c + Vector2(3, 1), Vector2(9, 4), Color(0, 0, 0, 0.22))
	match d["tipo"]:
		"camera":
			draw_line(c, c + Vector2(0, -46), CONTORNO, 4.0)
			draw_line(c, c + Vector2(0, -46), Color("64748b"), 2.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-2, -50), c + Vector2(14, -54), c + Vector2(16, -46), c + Vector2(0, -42)]), Color("e2e8f0"))
			draw_polyline(PackedVector2Array([c + Vector2(-2, -50), c + Vector2(14, -54), c + Vector2(16, -46), c + Vector2(0, -42), c + Vector2(-2, -50)]), CONTORNO, 1.0)
			draw_circle(c + Vector2(14, -50), 2.4, Color("111827"), true, -1.0, true)
			draw_circle(c + Vector2(2, -47), 1.8, luz, true, -1.0, true)
		"atm":
			caixa_iso(d["pos"] - Vector2(0.3, 0.2), 0.6, 0.4, 30.0, Color("475569"))
			var tela := iso(d["pos"] + Vector2(-0.2, 0.2)) + Vector2(0, -24)
			draw_rect(Rect2(tela - Vector2(5, 3), Vector2(10, 7)), Color("38bdf8"))
			draw_circle(tela + Vector2(0, -9), 1.8, luz, true, -1.0, true)
		_:
			draw_line(c, c + Vector2(0, -50), CONTORNO, 4.0)
			draw_line(c, c + Vector2(0, -50), Color("64748b"), 2.0)
			Visual.caixa(self, Rect2(c + Vector2(-6, -66), Vector2(12, 24)), Color("1f2937"), 3, CONTORNO, 1)
			var fase := int(tempo) % 3
			draw_circle(c + Vector2(0, -60), 2.6, Color("ef4444") if fase == 0 else Color("3f1515"), true, -1.0, true)
			draw_circle(c + Vector2(0, -54), 2.6, Color("facc15") if fase == 1 else Color("3d3410"), true, -1.0, true)
			draw_circle(c + Vector2(0, -48), 2.6, Color("22c55e") if fase == 2 else Color("10301c"), true, -1.0, true)
			draw_circle(c + Vector2(6, -66), 1.8, luz, true, -1.0, true)


func ponto_face_esquerda(a: Rect2i, u: float, v: float) -> Vector2:
	return iso(Vector2(a.position.x + u, a.end.y)) + Vector2(0, -v)


func ponto_face_direita(a: Rect2i, s: float, v: float) -> Vector2:
	return iso(Vector2(a.end.x, a.end.y - s)) + Vector2(0, -v)


func quad_esquerda(a: Rect2i, u0: float, u1: float, v0: float, v1: float) -> PackedVector2Array:
	return PackedVector2Array([ponto_face_esquerda(a, u0, v0), ponto_face_esquerda(a, u1, v0), ponto_face_esquerda(a, u1, v1), ponto_face_esquerda(a, u0, v1)])


func quad_direita(a: Rect2i, s0: float, s1: float, v0: float, v1: float) -> PackedVector2Array:
	return PackedVector2Array([ponto_face_direita(a, s0, v0), ponto_face_direita(a, s1, v0), ponto_face_direita(a, s1, v1), ponto_face_direita(a, s0, v1)])


func elipse_em(c: Vector2, raio: Vector2, cor: Color) -> void:
	var pontos := PackedVector2Array()
	for k in 20:
		var ang := TAU * k / 20.0
		pontos.append(c + Vector2(cos(ang) * raio.x, sin(ang) * raio.y))
	alvo.draw_colored_polygon(pontos, cor)


func caixa_iso(base: Vector2, w: float, d: float, h: float, cor: Color, contorno := true, elevacao := 0.0) -> void:
	var e := Vector2(0, -elevacao)
	var topo := iso(base) + e
	var direita := iso(base + Vector2(w, 0)) + e
	var baixo := iso(base + Vector2(w, d)) + e
	var esquerda := iso(base + Vector2(0, d)) + e
	var u := Vector2(0, -h)
	alvo.draw_colored_polygon(PackedVector2Array([esquerda, baixo, baixo + u, esquerda + u]), cor)
	alvo.draw_colored_polygon(PackedVector2Array([baixo, direita, direita + u, baixo + u]), cor.darkened(0.22))
	alvo.draw_colored_polygon(PackedVector2Array([topo + u, direita + u, baixo + u, esquerda + u]), cor.lightened(0.18))
	if contorno:
		alvo.draw_polyline(PackedVector2Array([esquerda, baixo, direita, direita + u, topo + u, esquerda + u, esquerda]), CONTORNO, 1.0)
		alvo.draw_line(baixo, baixo + u, CONTORNO, 1.0)
		alvo.draw_polyline(PackedVector2Array([esquerda + u, baixo + u, direita + u]), CONTORNO, 1.0)


func desenhar_predio_base(l: Dictionary) -> void:
	var a: Rect2i = l["area"]
	var tipo: String = l["tipo"]
	if tipo == "lote" and String(l["construcao"]) == "":
		desenhar_terreno(a, l["comprado"])
		return
	var h: float = l["altura"]
	var u := Vector2(0, -h)
	var acento := cor_local(l)
	var parede := parede_local(l)
	var topo := iso(Vector2(a.position))
	var direita := iso(Vector2(a.end.x, a.position.y))
	var baixo := iso(Vector2(a.end))
	var esquerda := iso(Vector2(a.position.x, a.end.y))
	var sombra := Vector2(h * 0.55, h * 0.12)
	alvo.draw_colored_polygon(PackedVector2Array([baixo, direita, direita + sombra, baixo + sombra]), Color(0, 0, 0, 0.16))
	alvo.draw_colored_polygon(PackedVector2Array([esquerda, baixo, baixo + u, esquerda + u]), parede)
	alvo.draw_colored_polygon(PackedVector2Array([baixo, direita, direita + u, baixo + u]), parede.darkened(0.2))
	alvo.draw_colored_polygon(quad_esquerda(a, 0, a.size.x, 0, 7), parede.darkened(0.25))
	alvo.draw_colored_polygon(quad_direita(a, 0, a.size.y, 0, 7), parede.darkened(0.38))
	desenhar_janelas(l, a, h, tipo)
	alvo.draw_colored_polygon(quad_esquerda(a, 0, a.size.x, h - 9, h), acento)
	alvo.draw_colored_polygon(quad_direita(a, 0, a.size.y, h - 9, h), acento.darkened(0.22))
	var escuro := parede.get_luminance() < 0.35
	alvo.draw_colored_polygon(PackedVector2Array([topo + u, direita + u, baixo + u, esquerda + u]), Color("2a2d36") if escuro else Color("a3aab8"))
	var m := 0.16
	var interno := PackedVector2Array([iso(Vector2(a.position.x + m, a.position.y + m)) + u, iso(Vector2(a.end.x - m, a.position.y + m)) + u, iso(Vector2(a.end.x - m, a.end.y - m)) + u, iso(Vector2(a.position.x + m, a.end.y - m)) + u])
	alvo.draw_colored_polygon(interno, Color("1f2229") if escuro else Color("8b93a3"))
	desenhar_telhado_base(a, h, tipo)
	desenhar_porta(a, acento, tipo)
	alvo.draw_polyline(PackedVector2Array([esquerda, baixo, direita, direita + u, topo + u, esquerda + u, esquerda]), CONTORNO, 1.2)
	alvo.draw_line(baixo, baixo + u, CONTORNO, 1.2)
	alvo.draw_polyline(PackedVector2Array([esquerda + u, baixo + u, direita + u]), CONTORNO, 1.2)


func desenhar_predio_extras(l: Dictionary) -> void:
	var a: Rect2i = l["area"]
	var tipo: String = l["tipo"]
	if tipo == "lote" and String(l["construcao"]) == "":
		desenhar_placa_terreno(l)
		return
	var h: float = l["altura"]
	var acento := cor_local(l)
	match tipo:
		"datacenter":
			for k in int(a.size.x * 2):
				var u0 := 0.25 + k * 0.5
				for led in 5:
					var aceso := int(tempo * 3.0 + k + led * 2) % 4 != 0
					var p := ponto_face_esquerda(a, u0 + 0.15, 20 + led * 7)
					draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color("34d399") if aceso else Color("fbbf24"))
			for k in 4:
				var base := Vector2(a.position.x + 1.0 + k * 2.4, a.position.y + 1.2)
				var centro := iso(base + Vector2(0.6, 0.6)) + Vector2(0, -h - 12)
				var giro := tempo * 8.0 + k
				draw_line(centro + Vector2(cos(giro) * 11, sin(giro) * 5.5), centro - Vector2(cos(giro) * 11, sin(giro) * 5.5), Color("e2e8f0"), 2.0)
		"bolsa":
			for k in 10:
				var t := fmod(tempo * 0.4 + k * 0.1, 1.0)
				var cor := Color("22c55e") if k % 3 != 1 else Color("ef4444")
				var u2 := 0.15 + t * (a.size.x - 0.5)
				draw_colored_polygon(quad_esquerda(a, u2, u2 + 0.18, 35.5, 38.5), cor)
		"missoes":
			var c := iso(centro_area(a)) + Vector2(0, -h - 30 + sin(tempo * 3.0) * 3.0)
			draw_line(c + Vector2(0, 26), c + Vector2(0, 8), Color("475569"), 3.0)
			draw_circle(c, 17.0, CONTORNO, true, -1.0, true)
			draw_circle(c, 15.0, acento, true, -1.0, true)
			Visual.texto(self, c + Vector2(-15, 8), "!", 22, Color("422006"), HORIZONTAL_ALIGNMENT_CENTER, 30)
		"sede":
			var c2 := iso(centro_area(a)) + Vector2(0, -h)
			draw_line(c2, c2 + Vector2(0, -44), Color("475569"), 3.0)
			var balanco := sin(tempo * 4.0) * 3.0
			draw_colored_polygon(PackedVector2Array([c2 + Vector2(0, -44), c2 + Vector2(26, -38 + balanco), c2 + Vector2(0, -30)]), acento)
			Visual.texto(self, iso(Vector2(a.position.x + 6.8, a.position.y + 1.6)) + Vector2(-22, -h + 6), "H", 14, Color("e2e8f0"), HORIZONTAL_ALIGNMENT_CENTER, 44)
		"zerosec":
			var pulso := 0.55 + 0.45 * sin(tempo * 3.0)
			var c4 := iso(centro_area(a)) + Vector2(0, -h - 26)
			draw_circle(c4, 19.0, Color(0.13, 0.83, 0.93, 0.18 * pulso), true, -1.0, true)
			draw_arc(c4, 15.0, 0.0, TAU, 28, Visual.com_alfa(Color("22d3ee"), 0.6 + 0.4 * pulso), 3.0, true)
			Visual.texto(self, c4 + Vector2(-30, 5), "0x5EC", 13, Visual.com_alfa(Color("22d3ee"), 0.7 + 0.3 * pulso), HORIZONTAL_ALIGNMENT_CENTER, 60)
			draw_colored_polygon(quad_esquerda(a, 0, a.size.x, h - 9, h - 6), Visual.com_alfa(Color("22d3ee"), pulso))
		"arena":
			var tela := quad_esquerda(a, 0.6, a.size.x - 0.6, 30, h - 18)
			draw_colored_polygon(tela, Color("0b0b14"))
			for k in 8:
				var altura_barra := 8.0 + 24.0 * absf(sin(tempo * 2.5 + k * 0.9))
				var u5 := 0.9 + k * (a.size.x - 1.8) / 8.0
				draw_colored_polygon(quad_esquerda(a, u5, u5 + 0.35, 34, 34 + altura_barra), Color("a855f7") if k % 2 == 0 else Color("22d3ee"))
			Visual.texto(self, iso(centro_area(a)) + Vector2(-40, -h - 12), "CTF LIVE", 14, Visual.com_alfa(Color("f0abfc"), 0.6 + 0.4 * sin(tempo * 5.0)), HORIZONTAL_ALIGNMENT_CENTER, 80)
		"decor":
			var piscar2 := int(tempo * 1.5 + a.position.x) % 3 != 0
			var u6 := 0.25
			draw_colored_polygon(quad_esquerda(a, u6, u6 + 0.2, 30, h - 14), Visual.com_alfa(acento, 0.9 if piscar2 else 0.35))
			var topo2 := iso(Vector2(a.position.x + 0.6, a.position.y + 0.6)) + Vector2(0, -h)
			draw_line(topo2, topo2 + Vector2(0, -22), Color("475569"), 2.0)
			draw_circle(topo2 + Vector2(0, -24), 3.0, Color("ef4444") if piscar2 else Color("7f1d1d"), true, -1.0, true)
		"academia":
			var c3 := iso(centro_area(a)) + Vector2(0, -h)
			draw_line(c3, c3 + Vector2(0, -36), Color("475569"), 2.0)
			draw_colored_polygon(PackedVector2Array([c3 + Vector2(0, -36), c3 + Vector2(22, -31 + sin(tempo * 5.0) * 2.0), c3 + Vector2(0, -26)]), Color("3b82f6"))
		"empresa", "startup", "lote":
			if h > 120.0:
				var antena := iso(Vector2(a.position.x + 0.8, a.position.y + 0.8)) + Vector2(0, -h)
				var piscar := int(tempo * 2.0) % 2 == 0
				draw_circle(antena + Vector2(0, -31), 3.0, Color("ef4444") if piscar else Color("7f1d1d"), true, -1.0, true)
	if predio_hover == l["id"]:
		var contorno := silhueta(l)
		contorno.append(contorno[0])
		draw_polyline(contorno, acento.lightened(0.2), 3.0)


func desenhar_janelas(l: Dictionary, a: Rect2i, h: float, tipo: String) -> void:
	var neon: bool = parede_local(l).get_luminance() < 0.35 and tipo != "beco"
	var vidro := Color("8fd3f4")
	var vidro_escuro := Color("5fa9d1")
	var espaco := 22.0
	var alto := 12.0
	if tipo == "sede":
		espaco = 16.0
		alto = 11.0
	if tipo == "beco":
		vidro = Color("4ade80")
		vidro_escuro = Color("15803d")
	if tipo == "datacenter":
		for k in int(a.size.x * 2):
			var u0 := 0.25 + k * 0.5
			alvo.draw_colored_polygon(quad_esquerda(a, u0, u0 + 0.3, 14, 52), Color("475569"))
		for k in int(a.size.y * 2):
			var s0 := 0.25 + k * 0.5
			alvo.draw_colored_polygon(quad_direita(a, s0, s0 + 0.3, 14, 52), Color("334155"))
		return
	var v := 40.0
	var andar := 0
	while v + alto < h - 14.0:
		for k in int(a.size.x * 2):
			var u1 := 0.18 + k * 0.5
			var aceso := (absi(hash(l["id"])) + k * 7 + andar * 3) % 6 != 0
			var cor_janela: Color = vidro if aceso else vidro_escuro.darkened(0.2)
			if neon:
				cor_janela = JANELAS_NEON[(absi(hash(l["id"])) + k * 3 + andar * 5) % JANELAS_NEON.size()]
			alvo.draw_colored_polygon(quad_esquerda(a, u1, u1 + 0.3, v, v + alto), cor_janela)
			alvo.draw_line(ponto_face_esquerda(a, u1 + 0.04, v + alto - 2), ponto_face_esquerda(a, u1 + 0.14, v + alto - 2), Color(1, 1, 1, 0.7), 1.0)
		for k in int(a.size.y * 2):
			var s1 := 0.18 + k * 0.5
			alvo.draw_colored_polygon(quad_direita(a, s1, s1 + 0.3, v, v + alto), JANELAS_NEON[(absi(hash(l["id"])) + k * 5 + andar * 3) % JANELAS_NEON.size()].darkened(0.3) if neon else vidro_escuro)
		v += espaco
		andar += 1
	if tipo == "bolsa":
		alvo.draw_colored_polygon(quad_esquerda(a, 0.1, a.size.x - 0.1, 34, 40), Color("0f172a"))
	if tipo == "beco":
		for k in 3:
			var u3 := 0.4 + k * 1.1
			alvo.draw_polyline(PackedVector2Array([ponto_face_esquerda(a, u3, 20), ponto_face_esquerda(a, u3 + 0.3, 28), ponto_face_esquerda(a, u3 + 0.5, 18), ponto_face_esquerda(a, u3 + 0.8, 26)]), Color("a855f7") if k % 2 == 0 else Color("22d3ee"), 2.0)


func desenhar_porta(a: Rect2i, acento: Color, tipo: String) -> void:
	var meio := a.size.x * 0.5
	var largura := 0.42 if tipo != "loja" and tipo != "sede" else 0.6
	alvo.draw_colored_polygon(quad_esquerda(a, meio - largura - 0.06, meio + largura + 0.06, 0, 32), Color("e5e7eb"))
	alvo.draw_colored_polygon(quad_esquerda(a, meio - largura, meio + largura, 0, 29), Color("1e293b"))
	alvo.draw_line(ponto_face_esquerda(a, meio, 0), ponto_face_esquerda(a, meio, 29), Color("475569"), 1.0)
	alvo.draw_colored_polygon(quad_esquerda(a, meio - largura + 0.06, meio - 0.04, 3, 26), Color(0.55, 0.8, 0.95, 0.35))
	alvo.draw_colored_polygon(quad_esquerda(a, meio + 0.04, meio + largura - 0.06, 3, 26), Color(0.55, 0.8, 0.95, 0.35))
	var saida := Vector2(-MEIO_TILE.x, MEIO_TILE.y) * 0.35 + Vector2(0, 8)
	var p0 := ponto_face_esquerda(a, meio - largura - 0.18, 40)
	var p1 := ponto_face_esquerda(a, meio + largura + 0.18, 40)
	alvo.draw_colored_polygon(PackedVector2Array([p0, p1, p1 + saida, p0 + saida]), acento)
	for k in 4:
		if k % 2 == 1:
			var q0 := p0.lerp(p1, k / 4.0)
			var q1 := p0.lerp(p1, (k + 1) / 4.0)
			alvo.draw_colored_polygon(PackedVector2Array([q0, q1, q1 + saida, q0 + saida]), Color(1, 1, 1, 0.55))
	alvo.draw_polyline(PackedVector2Array([p0, p0 + saida, p1 + saida, p1]), CONTORNO, 1.0)


func desenhar_telhado_base(a: Rect2i, h: float, tipo: String) -> void:
	match tipo:
		"datacenter":
			for k in 4:
				var base := Vector2(a.position.x + 1.0 + k * 2.4, a.position.y + 1.2)
				caixa_iso(base, 1.2, 1.2, 12.0, Color("cbd5e1"), true, h)
				elipse_em(iso(base + Vector2(0.6, 0.6)) + Vector2(0, -h - 12), Vector2(13, 6.5), Color("475569"))
		"sede":
			elipse_em(iso(Vector2(a.position.x + 6.8, a.position.y + 1.6)) + Vector2(0, -h), Vector2(22, 11), Color("475569"))
		"empresa", "startup", "lote":
			caixa_iso(Vector2(a.end.x - 1.1, a.position.y + 0.4), 0.7, 0.7, 10.0, Color("cbd5e1"), true, h)
			if h > 120.0:
				var antena := iso(Vector2(a.position.x + 0.8, a.position.y + 0.8)) + Vector2(0, -h)
				alvo.draw_line(antena, antena + Vector2(0, -30), Color("64748b"), 2.0)


func desenhar_terreno(a: Rect2i, comprado: bool) -> void:
	var cerca := Color("8b5a2b") if not comprado else Color("a78bfa")
	var cantos := [Vector2(a.position), Vector2(a.end.x, a.position.y), Vector2(a.end), Vector2(a.position.x, a.end.y)]
	for i in 4:
		var de: Vector2 = cantos[i]
		var ate: Vector2 = cantos[(i + 1) % 4]
		var passos := int(de.distance_to(ate) * 2)
		for k in passos + 1:
			var p := iso(de.lerp(ate, float(k) / passos))
			alvo.draw_line(p, p + Vector2(0, -14), cerca.darkened(0.2), 2.0)
		alvo.draw_line(iso(de) + Vector2(0, -10), iso(ate) + Vector2(0, -10), cerca, 2.0)
		alvo.draw_line(iso(de) + Vector2(0, -5), iso(ate) + Vector2(0, -5), cerca, 2.0)
	if comprado:
		caixa_iso(Vector2(a.position.x + 0.5, a.position.y + 0.5), 0.8, 0.6, 12.0, Color("f59e0b"))
		caixa_iso(Vector2(a.end.x - 1.2, a.position.y + 0.4), 0.6, 0.6, 18.0, Color("94a3b8"))
	else:
		caixa_iso(Vector2(a.position.x + 0.5, a.position.y + 0.5), 0.6, 0.6, 14.0, Color("a16207"))
		caixa_iso(Vector2(a.position.x + 1.3, a.position.y + 0.4), 0.5, 0.5, 10.0, Color("ca8a04"))
	var placa := iso(centro_area(a) + Vector2(0, 0.8))
	alvo.draw_line(placa + Vector2(-30, 0), placa + Vector2(-30, -40), Color("6b4423"), 3.0)
	alvo.draw_line(placa + Vector2(30, 0), placa + Vector2(30, -40), Color("6b4423"), 3.0)


func desenhar_placa_terreno(l: Dictionary) -> void:
	var a: Rect2i = l["area"]
	var placa := iso(centro_area(a) + Vector2(0, 0.8))
	var r := Rect2(placa + Vector2(-66, -78), Vector2(132, 44))
	if l["comprado"]:
		Visual.caixa(self, r, Color("ede9fe"), 6, Color("6d28d9"), 2)
		Visual.texto(self, r.position + Vector2(0, 18), "SEU TERRENO", 13, Color("4c1d95"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Visual.texto(self, r.position + Vector2(0, 35), "toque para construir", 11, Color("5b21b6"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	else:
		Visual.caixa(self, r, Color("fef3c7"), 6, Color("92400e"), 2)
		Visual.texto(self, r.position + Vector2(0, 18), "À VENDA", 13, Color("78350f"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Visual.texto(self, r.position + Vector2(0, 35), Visual.dinheiro(l["preco"]), 12, Color("92400e"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	if predio_hover == l["id"]:
		var contorno := silhueta(l)
		contorno.append(contorno[0])
		draw_polyline(contorno, Color("a78bfa"), 3.0)


func desenhar_arvore(item: Dictionary) -> void:
	var c := iso(item["caixa"].get_center())
	var s: float = item["escala"]
	var tons := [[Color("2f8f3a"), Color("3fae47"), Color("6fd36b")], [Color("2b7d4f"), Color("37a064"), Color("62c98a")], [Color("4d8f2a"), Color("63ad35"), Color("93d35a")]]
	var tom: Array = tons[int(item["tom"])]
	elipse_em(c + Vector2(6, 2), Vector2(18, 8) * s, Color(0, 0, 0, 0.2))
	alvo.draw_rect(Rect2(c + Vector2(-3, -20) * s, Vector2(6, 20) * s), CONTORNO)
	alvo.draw_rect(Rect2(c + Vector2(-2, -20) * s, Vector2(4, 19) * s), Color("8b5a2b"))
	var copa := c + Vector2(0, -38) * s
	alvo.draw_circle(copa, 19.0 * s, CONTORNO)
	alvo.draw_circle(copa, 18.0 * s, tom[0])
	alvo.draw_circle(copa + Vector2(-3, -4) * s, 14.0 * s, tom[1])
	alvo.draw_circle(copa + Vector2(-7, -9) * s, 6.0 * s, tom[2])


func desenhar_poste(p: Vector2) -> void:
	var c := iso(p)
	elipse_em(c, Vector2(5, 2.5), Color(0, 0, 0, 0.25))
	alvo.draw_line(c, c + Vector2(0, -50), CONTORNO, 4.0)
	alvo.draw_line(c, c + Vector2(0, -50), Color("475569"), 2.0)
	alvo.draw_line(c + Vector2(0, -50), c + Vector2(8, -54), Color("475569"), 2.0)
	alvo.draw_circle(c + Vector2(9, -52), 5.0, CONTORNO)
	alvo.draw_circle(c + Vector2(9, -52), 4.0, Color("fde68a"))


func desenhar_banco(base: Vector2) -> void:
	caixa_iso(base + Vector2(0.15, 0.3), 0.7, 0.4, 7.0, Color("a16207"))
	caixa_iso(base + Vector2(0.15, 0.2), 0.7, 0.1, 16.0, Color("854d0e"))


func desenhar_fonte() -> void:
	var c := iso(Vector2(22, 25))
	Visual.elipse(self, c + Vector2(0, 2), Vector2(62, 31), CONTORNO)
	Visual.elipse(self, c, Vector2(60, 30), Color("cbd5e1"))
	Visual.elipse(self, c + Vector2(0, -2), Vector2(50, 25), Color("38bdf8"))
	for k in 3:
		var r := fmod(tempo * 14.0 + k * 16.0, 48.0)
		Visual.elipse(self, c + Vector2(0, -2), Vector2(r, r * 0.5), Color(1, 1, 1, 0.25 * (1.0 - r / 48.0)))
	draw_rect(Rect2(c + Vector2(-5, -26), Vector2(10, 24)), Color("94a3b8"))
	for k in 6:
		var ang := tempo * 2.0 + k * TAU / 6.0
		var gota := c + Vector2(0, -28) + Vector2(cos(ang) * 14.0, -6.0 + fmod(tempo * 30.0 + k * 5.0, 22.0))
		draw_circle(gota, 2.0, Color("e0f2fe"))


func desenhar_carro(c: Dictionary, p: Vector2) -> void:
	var horizontal: bool = c["eixo"] == "x"
	var tamanho := Vector2(1.0, 0.5) if horizontal else Vector2(0.5, 1.0)
	var base := p - tamanho / 2
	var cor: Color = c["cor"]
	elipse_em(iso(p) + Vector2(4, 2), Vector2(26, 12), Color(0, 0, 0, 0.22))
	caixa_iso(base, tamanho.x, tamanho.y, 12.0, cor)
	var cabine := Vector2(0.55, 0.42) if horizontal else Vector2(0.42, 0.55)
	caixa_iso(p - cabine / 2, cabine.x, cabine.y, 22.0, Color("bae6fd"))
	var teto := p - cabine / 2
	alvo.draw_colored_polygon(PackedVector2Array([iso(teto) + Vector2(0, -22), iso(teto + Vector2(cabine.x, 0)) + Vector2(0, -22), iso(teto + cabine) + Vector2(0, -22), iso(teto + Vector2(0, cabine.y)) + Vector2(0, -22)]), cor.lightened(0.1))


func desenhar_rotulos_fixos(ci: CanvasItem) -> void:
	for l in locais:
		var a: Rect2i = l["area"]
		var h: float = l["altura"]
		if l["tipo"] == "lote" and String(l["construcao"]) == "":
			continue
		var ancora := iso(centro_area(a)) + Vector2(0, -h - 22)
		if l["tipo"] == "missoes":
			ancora.y -= 40
		var nome := nome_local(l)
		var largura := Visual.largura_texto(nome, 13) + 42
		var r := Rect2(ancora - Vector2(largura / 2, 13), Vector2(largura, 26))
		var hover: bool = predio_hover == l["id"]
		Visual.caixa(ci, r, Color(0.06, 0.09, 0.15, 0.92 if hover else 0.8), 13, cor_local(l) if hover else Color(1, 1, 1, 0.12), 1)
		var logo_c := r.position + Vector2(14, 13)
		if l["tipo"] == "empresa":
			var e: Dictionary = Dados.empresa_por_id(l["id"])
			Visual.logo(ci, logo_c, 9.0, e["logo"], e["sigla"])
		elif l["tipo"] == "startup":
			var s: Dictionary = estado().empresa_dados("startup")
			Visual.logo(ci, logo_c, 9.0, s["logo"], s["sigla"])
		else:
			ci.draw_circle(logo_c, 6.0, cor_local(l), true, -1.0, true)
		Visual.texto(ci, r.position + Vector2(28, 18), nome, 13, Visual.TEXTO)
		if l["tipo"] == "empresa":
			var e2: Dictionary = Dados.empresa_por_id(l["id"])
			var est: Dictionary = estado().perfil.get("empresas", {}).get(l["id"], {})
			var selo := "À VENDA"
			var cor_selo := Visual.DESTAQUE
			if est.get("dono", false):
				selo = "SUA"
				cor_selo = Visual.CREDITOS
			elif e2["contrato"]:
				selo = "CONTRATO"
				cor_selo = Visual.HUMANO
			elif estado().nivel() < int(e2["nivel"]):
				selo = "BLOQUEADA"
				cor_selo = Color("94a3b8")
			var ls := Visual.largura_texto(selo, 10) + 12
			var rs := Rect2(ancora.x - ls / 2, r.end.y + 3, ls, 16)
			Visual.caixa(ci, rs, cor_selo, 8)
			Visual.texto(ci, Vector2(rs.position.x, rs.position.y + 12), selo, 10, Color("0b1220"), HORIZONTAL_ALIGNMENT_CENTER, ls)
			if estado().obter_operacao(l["id"]).size() > 0:
				ci.draw_circle(Vector2(r.end.x - 2, r.position.y + 2), 5.0, Visual.HUMANO, true, -1.0, true)
		elif l["tipo"] == "lote" and not l["comprado"] and String(l["construcao"]) != "":
			var selo_imovel := "À VENDA"
			var largura_selo := Visual.largura_texto(selo_imovel, 10) + 12
			var r_selo := Rect2(ancora.x - largura_selo / 2, r.end.y + 3, largura_selo, 16)
			Visual.caixa(ci, r_selo, Visual.CREDITOS, 8)
			Visual.texto(ci, Vector2(r_selo.position.x, r_selo.position.y + 12), selo_imovel, 10, Color("0b1220"), HORIZONTAL_ALIGNMENT_CENTER, largura_selo)


func desenhar_rotulos(ci: CanvasItem) -> void:
	for l in locais:
		if l["tipo"] == "missoes" and estado().quantidade_prontas() > 0:
			var a2: Rect2i = l["area"]
			var p := iso(centro_area(a2)) + Vector2(42, -l["altura"] - 70 + sin(tempo * 4.0) * 5.0)
			ci.draw_circle(p, 13.0, CONTORNO, true, -1.0, true)
			ci.draw_circle(p, 12.0, Visual.PERIGO, true, -1.0, true)
			Visual.texto(ci, p + Vector2(-12, 6), str(estado().quantidade_prontas()), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 24)
	var pj := iso(jogador)
	var nome_j: String = estado().perfil.get("nome", "")
	var lj := Visual.largura_texto(nome_j, 12) + 16
	Visual.caixa(ci, Rect2(pj.x - lj / 2, pj.y - 92, lj, 20), Color(0, 0, 0, 0.55), 10)
	Visual.texto(ci, Vector2(pj.x - lj / 2, pj.y - 77), nome_j, 12, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, lj)
	if not balao.is_empty() and balao["indice"] < npcs.size():
		var n2: Dictionary = npcs[balao["indice"]]
		var pn := iso(n2["pos"])
		var linhas := Visual.quebrar(balao["texto"], 13, 260)
		var altura := 24 + linhas.size() * 18
		var caixa_balao := Rect2(pn + Vector2(-140, -82 - altura), Vector2(280, altura))
		Visual.caixa(ci, caixa_balao.grow(2), CONTORNO, 12)
		Visual.caixa(ci, caixa_balao, Color("f8fafc"), 11)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(pn.x - 8, caixa_balao.end.y), Vector2(pn.x + 8, caixa_balao.end.y), Vector2(pn.x, pn.y - 70)]), Color("f8fafc"))
		Visual.texto(ci, caixa_balao.position + Vector2(12, 18), n2["nome"], 11, Color("2563eb"))
		for k in linhas.size():
			Visual.texto(ci, caixa_balao.position + Vector2(12, 36 + k * 18), linhas[k], 13, Color("0f172a"))


func desenhar_hud(ci: CanvasItem) -> void:
	ci.draw_set_transform(-camera.round(), 0.0, Vector2.ONE)
	desenhar_rotulos(ci)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var p: Dictionary = estado().perfil
	var cartao := Rect2(16, 16, 380, 92)
	Visual.caixa(ci, cartao, Visual.com_alfa(Visual.CARTAO, 0.94), 16, Visual.BORDA, 1, 10)
	Visual.caixa(ci, Rect2(28, 26, 70, 72), Color("3b6fb6"), 12)
	Visual.caixa(ci, Rect2(28, 74, 70, 24), Color("5c9e3c"), 0)
	Visual.avatar(ci, Vector2(63, 96), 1.0, p.get("avatar", {}), p.get("equipados", {}), tempo, false)
	ci.draw_rect(Rect2(28, 98, 70, 12), Visual.com_alfa(Visual.CARTAO, 0.94))
	Visual.texto(ci, Vector2(110, 44), p.get("nome", ""), 17, Visual.TEXTO)
	Visual.texto(ci, Vector2(110, 64), "%s  ·  nível %d" % [estado().titulo(), estado().nivel() + 1], 12, Visual.DESTAQUE)
	var barra := Rect2(110, 74, 270, 7)
	Visual.caixa(ci, barra, Visual.LINHA, 4)
	Visual.caixa(ci, Rect2(barra.position, Vector2(maxf(7.0, barra.size.x * estado().progresso_nivel()), 7)), Visual.DESTAQUE, 4)
	Visual.texto(ci, Vector2(110, 98), Visual.dinheiro(estado().dinheiro()), 15, Visual.CREDITOS)
	var seq: Dictionary = p.get("sequencia", {})
	var chama := Vector2(300, 92)
	ci.draw_colored_polygon(PackedVector2Array([chama + Vector2(0, -12), chama + Vector2(6, -2), chama + Vector2(4, 5), chama + Vector2(-4, 5), chama + Vector2(-6, -2)]), Color("f97316"))
	ci.draw_circle(chama + Vector2(0, 1), 3.0, Color("fde047"), true, -1.0, true)
	Visual.texto(ci, Vector2(312, 98), "%d dia(s)" % int(seq.get("dias", 0)), 12, Visual.TEXTO_SUAVE)
	desenhar_minimapa(ci)
	desenhar_missao_atual(ci)
	var prontas: int = estado().quantidade_prontas()
	Visual.caixa(ci, RET_BOTAO_MISSOES, Visual.com_alfa(Visual.CARTAO, 0.94), 16, Visual.CREDITOS if prontas > 0 else (Visual.BORDA_HOVER if RET_BOTAO_MISSOES.has_point(mouse) else Visual.BORDA), 2 if prontas > 0 else 1, 10)
	ci.draw_circle(RET_BOTAO_MISSOES.position + Vector2(30, 36), 16.0, Visual.CREDITOS, true, -1.0, true)
	Visual.texto(ci, RET_BOTAO_MISSOES.position + Vector2(14, 44), "!", 20, Visual.FUNDO, HORIZONTAL_ALIGNMENT_CENTER, 32)
	Visual.texto(ci, RET_BOTAO_MISSOES.position + Vector2(56, 32), "Missões", 16, Visual.TEXTO)
	Visual.texto(ci, RET_BOTAO_MISSOES.position + Vector2(56, 52), "%d para resgatar" % prontas if prontas > 0 else "tecla M", 12, Visual.CREDITOS if prontas > 0 else Visual.TEXTO_SUAVE)
	Visual.caixa(ci, RET_BOTAO_SEDE, Visual.com_alfa(Visual.CARTAO, 0.94), 16, Visual.BORDA_HOVER if RET_BOTAO_SEDE.has_point(mouse) else Visual.BORDA, 1, 10)
	Visual.icone(ci, "servidor", RET_BOTAO_SEDE.position + Vector2(30, 36), Visual.DESTAQUE, 1.3)
	Visual.texto(ci, RET_BOTAO_SEDE.position + Vector2(56, 32), "Perfil", 16, Visual.TEXTO)
	Visual.texto(ci, RET_BOTAO_SEDE.position + Vector2(56, 52), "visual, backup, conta", 12, Visual.TEXTO_SUAVE)
	var prompt := texto_prompt()
	if prompt != "":
		var pulso := 0.85 + 0.15 * sin(tempo * 6.0)
		Visual.caixa(ci, RET_PROMPT, Visual.com_alfa(Visual.PRINCIPAL, pulso), 16, Visual.TRANSPARENTE, 0, 10)
		Visual.caixa(ci, Rect2(RET_PROMPT.position + Vector2(12, 12), Vector2(30, 30)), Color("052e1f"), 8)
		Visual.texto(ci, RET_PROMPT.position + Vector2(12, 33), "E", 15, Visual.PRINCIPAL, HORIZONTAL_ALIGNMENT_CENTER, 30)
		Visual.texto(ci, RET_PROMPT.position + Vector2(54, 34), prompt, 16, Color("052e1f"), HORIZONTAL_ALIGNMENT_LEFT, RET_PROMPT.size.x - 64)
	else:
		Visual.caixa(ci, Rect2(16, 686, 640, 26), Color(0, 0, 0, 0.45), 13)
		Visual.texto(ci, Vector2(30, 704), "WASD ou setas para andar  ·  clique no chão ou num prédio para ir até lá  ·  E para entrar", 12, Visual.TEXTO)


func deslocamento_minimapa() -> Vector2:
	return RET_MINIMAPA.position + (RET_MINIMAPA.size - TAMANHO_TELA * escala_minimapa()) / 2


func escala_minimapa() -> float:
	return minf(RET_MINIMAPA.size.x / TAMANHO_TELA.x, RET_MINIMAPA.size.y / TAMANHO_TELA.y)


func ponto_mini(p: Vector2) -> Vector2:
	return deslocamento_minimapa() + iso(p) * escala_minimapa()


func quad_mini(a: Vector2, b: Vector2) -> PackedVector2Array:
	return PackedVector2Array([ponto_mini(a), ponto_mini(Vector2(b.x, a.y)), ponto_mini(b), ponto_mini(Vector2(a.x, b.y))])


func construir_minimapa() -> void:
	alvo = Malha.new()
	alvo.draw_colored_polygon(quad_mini(Vector2.ZERO, Vector2(LARGURA, ALTURA)), Color("5fae3c"))
	alvo.draw_colored_polygon(quad_mini(Vector2(DISTRITO_NEON.position), Vector2(DISTRITO_NEON.end)), Color("2b3045"))
	for x in [13, 29, 44]:
		alvo.draw_colored_polygon(quad_mini(Vector2(x, 0), Vector2(x + 2, ALTURA)), Color("4a5061"))
	for y in [13, 29]:
		alvo.draw_colored_polygon(quad_mini(Vector2(0, y), Vector2(LARGURA, y + 2)), Color("4a5061"))
	for l in locais:
		var a: Rect2i = l["area"]
		alvo.draw_colored_polygon(quad_mini(Vector2(a.position), Vector2(a.end)), Color("b88a55") if l["tipo"] == "lote" and String(l["construcao"]) == "" else cor_local(l))
	malha_minimapa = alvo.gerar()
	alvo = self


func desenhar_minimapa(ci: CanvasItem) -> void:
	Visual.caixa(ci, RET_MINIMAPA.grow(6), Visual.com_alfa(Visual.CARTAO, 0.94), 12, Visual.BORDA, 1, 8)
	ci.draw_mesh(malha_minimapa, null)
	ci.draw_rect(Rect2(deslocamento_minimapa() + camera * escala_minimapa(), Vector2(1280, 720) * escala_minimapa()), Color(1, 1, 1, 0.6), false, 1.0)
	var pj := ponto_mini(jogador)
	ci.draw_circle(pj, 4.0, CONTORNO)
	ci.draw_circle(pj, 3.0, Color.WHITE)


func desenhar_missao_atual(ci: CanvasItem) -> void:
	var ativas: Array = estado().missoes_ativas()
	if ativas.is_empty():
		return
	var m: Dictionary = ativas[0]
	var r := Rect2(16, 118, 380, 66)
	Visual.caixa(ci, r, Visual.com_alfa(Visual.CARTAO, 0.9), 14, Visual.BORDA, 1, 8)
	Visual.texto(ci, r.position + Vector2(14, 22), "MISSÃO", 10, Visual.CREDITOS)
	Visual.texto(ci, r.position + Vector2(66, 22), m["titulo"], 13, Visual.TEXTO)
	Visual.paragrafo(ci, r.position + Vector2(14, 42), m["descricao"], 11, Visual.TEXTO_SUAVE, 290, 1.3, 2)
	var progresso := clampf(float(estado().valor(m["contador"])) / float(m["alvo"]), 0.0, 1.0)
	Visual.texto(ci, Vector2(r.end.x - 60, r.position.y + 22), "%d/%d" % [mini(estado().valor(m["contador"]), int(m["alvo"])), int(m["alvo"])], 11, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT, 48)
	Visual.caixa(ci, Rect2(r.position.x + 14, r.end.y - 8, r.size.x - 28, 3), Visual.LINHA, 2)
	Visual.botao(ci, RET_GUIA, "Resgatar" if estado().missao_concluida(m) else "Ir", Visual.PRINCIPAL, RET_GUIA.has_point(mouse), true, 12, true)
	Visual.caixa(ci, Rect2(r.position.x + 14, r.end.y - 8, (r.size.x - 28) * progresso, 3), Visual.CREDITOS, 2)


class Malha:
	var vertices := PackedVector2Array()
	var cores := PackedColorArray()

	func draw_colored_polygon(pontos: PackedVector2Array, cor: Color) -> void:
		for k in range(1, pontos.size() - 1):
			vertices.append(pontos[0])
			vertices.append(pontos[k])
			vertices.append(pontos[k + 1])
			cores.append(cor)
			cores.append(cor)
			cores.append(cor)

	func draw_line(a: Vector2, b: Vector2, cor: Color, largura := 1.0) -> void:
		if a.is_equal_approx(b):
			return
		var d := (b - a).normalized().orthogonal() * largura * 0.5
		draw_colored_polygon(PackedVector2Array([a + d, b + d, b - d, a - d]), cor)

	func draw_polyline(pontos: PackedVector2Array, cor: Color, largura := 1.0) -> void:
		for k in pontos.size() - 1:
			draw_line(pontos[k], pontos[k + 1], cor, largura)

	func draw_circle(c: Vector2, r: float, cor: Color) -> void:
		var pontos := PackedVector2Array()
		for k in 18:
			pontos.append(c + Vector2(cos(TAU * k / 18.0), sin(TAU * k / 18.0)) * r)
		draw_colored_polygon(pontos, cor)

	func draw_rect(r: Rect2, cor: Color) -> void:
		draw_colored_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), cor)

	func gerar() -> ArrayMesh:
		var malha := ArrayMesh.new()
		if vertices.is_empty():
			return malha
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_COLOR] = cores
		malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return malha
