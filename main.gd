extends Node2D

enum Estado { MENU, JOGANDO, PAUSADO, GAME_OVER }

const INTERVALO_SPAWN_INICIAL := 0.4
const INTERVALO_SPAWN_MINIMO := 0.015
const CRESCIMENTO_TRAFEGO := 0.013
const PROPORCAO_BOTS_INICIAL := 0.35
const PROPORCAO_BOTS_MAXIMA := 0.75
const AUMENTO_BOTS := 0.003
const VELOCIDADE := 140.0
const TAMANHO := 14.0
const TEMPO_DESAPARECER := 0.4
const DELTA_MAXIMO := 0.1
const RAIO_CLIQUE := 26.0
const ESPERA_REINICIO_MS := 800

const X_INICIO := 60.0
const Y_FAIXA := 360.0

const X_CLOUDFLARE := 330.0
const EFICIENCIA_CLOUDFLARE := 0.7
const FALSO_POSITIVO_CLOUDFLARE := 0.02
const GANHO_CLOUDFLARE := 0.05

const X_CAPTCHA := 560.0
const EFICIENCIA_CAPTCHA := 0.6
const FALSO_POSITIVO_CAPTCHA := 0.05
const GANHO_CAPTCHA := 0.06

const X_LOAD_BALANCER := 790.0
const TAMANHO_LOAD_BALANCER := 30.0

const X_SERVIDORES := 1060.0
const Y_SERVIDORES := [200.0, 360.0, 520.0]
const NOMES_SERVIDORES := ["S1", "S2", "S3"]
const TAMANHO_SERVIDOR := 26.0
const CAPACIDADE := 100.0
const CUSTO_HUMANO := 4.0
const CUSTO_BOT := 12.0
const PROCESSAMENTO := 3.0
const GANHO_PROCESSAMENTO := 2.0
const FATOR_RESFRIAR := 0.5
const ALERTA_CARGA := 0.75

const CREDITOS_INICIAIS := 10
const CREDITOS_HUMANO := 1
const CREDITOS_BOT_CLICADO := 2
const MULTIPLICADOR_CUSTO := 1.6

const X_BOTOES := 150.0
const Y_BOTOES := 625.0
const LARGURA_BOTAO := 230.0
const ALTURA_BOTAO := 75.0
const ESPACO_BOTAO := 20.0
const RETANGULO_PAUSA := Rect2(1200, 20, 56, 44)

const ARQUIVO_RECORDE := "user://recorde.cfg"

const COR_FUNDO := Color("0b0f1a")
const COR_CAMINHO := Color("1f2633")
const COR_HUMANO := Color("4caf50")
const COR_BOT := Color("e05a47")
const COR_CLOUDFLARE := Color("f6821f")
const COR_CAPTCHA := Color("4dd0e1")
const COR_LOAD_BALANCER := Color("b48ead")
const COR_SERVIDOR := Color("5e81ac")
const COR_CARGA_BAIXA := Color("4caf50")
const COR_CARGA_ALTA := Color("e05a47")
const COR_TEXTO := Color("d8dee9")
const COR_TEXTO_APAGADO := Color("6b7385")
const COR_CREDITOS := Color("ebcb8b")
const COR_BOTAO_ATIVO := Color("2b3a55")
const COR_BOTAO_INATIVO := Color("161b26")
const COR_SOBREPOSICAO := Color(0, 0, 0, 0.78)

static var pular_menu := false

var estado := Estado.MENU
var cubos: Array = []
var servidores: Array = []
var tempo_spawn := 0.0
var tempo_jogo := 0.0
var proximo_servidor := 0
var servidor_caiu := ""
var momento_fim_ms := 0

var creditos := CREDITOS_INICIAIS
var eficiencia_cloudflare := EFICIENCIA_CLOUDFLARE
var eficiencia_captcha := EFICIENCIA_CAPTCHA
var processamento := PROCESSAMENTO
var recorde := 0.0
var novo_recorde := false

var humanos_servidos := 0
var humanos_perdidos := 0
var bots_bloqueados := 0
var bots_passaram := 0

var upgrades: Array = [
	{"id": "cloudflare", "nome": "Cloudflare", "custo": 15, "nivel": 0, "maximo": 5},
	{"id": "captcha", "nome": "CAPTCHA", "custo": 15, "nivel": 0, "maximo": 5},
	{"id": "servidores", "nome": "Servidores", "custo": 20, "nivel": 0, "maximo": 6},
	{"id": "resfriar", "nome": "Resfriar", "custo": 25, "nivel": 0, "maximo": -1},
]


func _ready() -> void:
	carregar_recorde()
	for i in NOMES_SERVIDORES.size():
		servidores.append({
			"nome": NOMES_SERVIDORES[i],
			"pos": Vector2(X_SERVIDORES, Y_SERVIDORES[i]),
			"carga": 0.0,
		})
	if pular_menu:
		pular_menu = false
		estado = Estado.JOGANDO
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and estado == Estado.JOGANDO:
		estado = Estado.PAUSADO
		queue_redraw()


func _process(delta: float) -> void:
	if estado != Estado.JOGANDO:
		return

	delta = minf(delta, DELTA_MAXIMO)
	tempo_jogo += delta
	tempo_spawn += delta
	var intervalo := intervalo_spawn_atual()
	while tempo_spawn >= intervalo:
		tempo_spawn -= intervalo
		criar_cubo()

	for cubo in cubos:
		atualizar_cubo(cubo, delta)
	cubos = cubos.filter(func(c): return not c["remover"])

	for servidor in servidores:
		atualizar_servidor(servidor, delta)

	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		tratar_tecla(event.keycode)
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local := make_input_local(event) as InputEventMouseButton
		tratar_clique(local.position)
		queue_redraw()


func tratar_tecla(tecla: Key) -> void:
	match estado:
		Estado.MENU:
			if tecla == KEY_SPACE or tecla == KEY_ENTER:
				estado = Estado.JOGANDO
		Estado.JOGANDO:
			if tecla == KEY_P or tecla == KEY_ESCAPE:
				estado = Estado.PAUSADO
			elif tecla >= KEY_1 and tecla <= KEY_4:
				comprar(tecla - KEY_1)
		Estado.PAUSADO:
			if tecla == KEY_P or tecla == KEY_ESCAPE or tecla == KEY_SPACE:
				estado = Estado.JOGANDO
		Estado.GAME_OVER:
			if tecla == KEY_R or tecla == KEY_SPACE or tecla == KEY_ENTER:
				reiniciar()


func tratar_clique(pos: Vector2) -> void:
	match estado:
		Estado.MENU:
			estado = Estado.JOGANDO
		Estado.PAUSADO:
			estado = Estado.JOGANDO
		Estado.GAME_OVER:
			reiniciar()
		Estado.JOGANDO:
			if RETANGULO_PAUSA.has_point(pos):
				estado = Estado.PAUSADO
				return
			for i in upgrades.size():
				if retangulo_botao(i).has_point(pos):
					comprar(i)
					return
			clicar_cubo(pos)


func reiniciar() -> void:
	if Time.get_ticks_msec() - momento_fim_ms < ESPERA_REINICIO_MS:
		return
	pular_menu = true
	get_tree().reload_current_scene()


func intervalo_spawn_atual() -> float:
	return maxf(INTERVALO_SPAWN_MINIMO, INTERVALO_SPAWN_INICIAL * exp(-tempo_jogo * CRESCIMENTO_TRAFEGO))


func proporcao_bots_atual() -> float:
	return minf(PROPORCAO_BOTS_MAXIMA, PROPORCAO_BOTS_INICIAL + tempo_jogo * AUMENTO_BOTS)


func criar_cubo() -> void:
	cubos.append({
		"pos": Vector2(X_INICIO, Y_FAIXA),
		"bot": randf() < proporcao_bots_atual(),
		"passou_cloudflare": false,
		"passou_captcha": false,
		"servidor": -1,
		"bloqueado": false,
		"fade": TEMPO_DESAPARECER,
		"remover": false,
	})


func atualizar_cubo(cubo: Dictionary, delta: float) -> void:
	if cubo["bloqueado"]:
		cubo["fade"] -= delta
		if cubo["fade"] <= 0.0:
			cubo["remover"] = true
		return

	if cubo["servidor"] >= 0:
		var alvo: Vector2 = servidores[cubo["servidor"]]["pos"]
		cubo["pos"] = cubo["pos"].move_toward(alvo, VELOCIDADE * delta)
		if cubo["pos"] == alvo:
			entregar(cubo)
		return

	cubo["pos"].x += VELOCIDADE * delta

	if not cubo["passou_cloudflare"] and cubo["pos"].x >= X_CLOUDFLARE:
		cubo["passou_cloudflare"] = true
		verificar_barreira(cubo, eficiencia_cloudflare, FALSO_POSITIVO_CLOUDFLARE)

	if cubo["bloqueado"]:
		return

	if not cubo["passou_captcha"] and cubo["pos"].x >= X_CAPTCHA:
		cubo["passou_captcha"] = true
		verificar_barreira(cubo, eficiencia_captcha, FALSO_POSITIVO_CAPTCHA)

	if cubo["bloqueado"]:
		return

	if cubo["pos"].x >= X_LOAD_BALANCER:
		cubo["servidor"] = escolher_servidor()


func verificar_barreira(cubo: Dictionary, eficiencia: float, falso_positivo: float) -> void:
	if cubo["bot"]:
		if randf() < eficiencia:
			cubo["bloqueado"] = true
			bots_bloqueados += 1
	else:
		if randf() < falso_positivo:
			cubo["bloqueado"] = true
			humanos_perdidos += 1


func clicar_cubo(pos: Vector2) -> void:
	var escolhido: Dictionary = {}
	var menor_distancia := RAIO_CLIQUE
	for cubo in cubos:
		if cubo["bloqueado"] or cubo["servidor"] >= 0:
			continue
		var distancia: float = pos.distance_to(cubo["pos"] + Vector2(0, -TAMANHO / 2))
		if distancia < menor_distancia:
			menor_distancia = distancia
			escolhido = cubo
	if escolhido.is_empty():
		return
	escolhido["bloqueado"] = true
	if escolhido["bot"]:
		bots_bloqueados += 1
		creditos += CREDITOS_BOT_CLICADO
	else:
		humanos_perdidos += 1


func escolher_servidor() -> int:
	var escolhido := proximo_servidor
	proximo_servidor = (proximo_servidor + 1) % servidores.size()
	return escolhido


func entregar(cubo: Dictionary) -> void:
	var servidor: Dictionary = servidores[cubo["servidor"]]
	if cubo["bot"]:
		servidor["carga"] += CUSTO_BOT
		bots_passaram += 1
	else:
		servidor["carga"] += CUSTO_HUMANO
		humanos_servidos += 1
		creditos += CREDITOS_HUMANO
	cubo["remover"] = true


func atualizar_servidor(servidor: Dictionary, delta: float) -> void:
	servidor["carga"] = maxf(0.0, servidor["carga"] - processamento * delta)
	if servidor["carga"] >= CAPACIDADE and estado == Estado.JOGANDO:
		servidor["carga"] = CAPACIDADE
		servidor_caiu = servidor["nome"]
		finalizar_partida()


func finalizar_partida() -> void:
	estado = Estado.GAME_OVER
	momento_fim_ms = Time.get_ticks_msec()
	if tempo_jogo > recorde:
		recorde = tempo_jogo
		novo_recorde = true
		salvar_recorde()


func pode_comprar(upgrade: Dictionary) -> bool:
	return not no_maximo(upgrade) and creditos >= upgrade["custo"]


func no_maximo(upgrade: Dictionary) -> bool:
	return upgrade["maximo"] >= 0 and upgrade["nivel"] >= upgrade["maximo"]


func comprar(indice: int) -> void:
	if indice < 0 or indice >= upgrades.size():
		return
	var upgrade: Dictionary = upgrades[indice]
	if not pode_comprar(upgrade):
		return
	creditos -= upgrade["custo"]
	upgrade["nivel"] += 1
	upgrade["custo"] = roundi(upgrade["custo"] * MULTIPLICADOR_CUSTO)
	match upgrade["id"]:
		"cloudflare":
			eficiencia_cloudflare += GANHO_CLOUDFLARE
		"captcha":
			eficiencia_captcha += GANHO_CAPTCHA
		"servidores":
			processamento += GANHO_PROCESSAMENTO
		"resfriar":
			for servidor in servidores:
				servidor["carga"] *= FATOR_RESFRIAR


func texto_efeito(upgrade: Dictionary) -> String:
	var maximo := no_maximo(upgrade)
	match upgrade["id"]:
		"cloudflare":
			return texto_porcentagem("Bloqueio", eficiencia_cloudflare, GANHO_CLOUDFLARE, maximo)
		"captcha":
			return texto_porcentagem("Bloqueio", eficiencia_captcha, GANHO_CAPTCHA, maximo)
		"servidores":
			if maximo:
				return "Processa %.1f/s" % processamento
			return "Processa %.1f > %.1f/s" % [processamento, processamento + GANHO_PROCESSAMENTO]
	return "Carga dos servidores -%d%%" % roundi((1.0 - FATOR_RESFRIAR) * 100)


func texto_porcentagem(rotulo: String, atual: float, ganho: float, maximo: bool) -> String:
	if maximo:
		return "%s %d%%" % [rotulo, roundi(atual * 100)]
	return "%s %d%% > %d%%" % [rotulo, roundi(atual * 100), roundi((atual + ganho) * 100)]


func retangulo_botao(indice: int) -> Rect2:
	return Rect2(X_BOTOES + indice * (LARGURA_BOTAO + ESPACO_BOTAO), Y_BOTOES, LARGURA_BOTAO, ALTURA_BOTAO)


func carregar_recorde() -> void:
	var arquivo := ConfigFile.new()
	if arquivo.load(ARQUIVO_RECORDE) == OK:
		recorde = arquivo.get_value("jogo", "recorde", 0.0)


func salvar_recorde() -> void:
	var arquivo := ConfigFile.new()
	arquivo.set_value("jogo", "recorde", recorde)
	arquivo.save(ARQUIVO_RECORDE)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), COR_FUNDO)
	desenhar_caminhos()
	desenhar_barreira(X_CLOUDFLARE, COR_CLOUDFLARE, "CLOUDFLARE", eficiencia_cloudflare)
	desenhar_barreira(X_CAPTCHA, COR_CAPTCHA, "CAPTCHA", eficiencia_captcha)
	desenhar_load_balancer()

	for cubo in cubos:
		var cor: Color = COR_BOT if cubo["bot"] else COR_HUMANO
		if cubo["bloqueado"]:
			cor.a = clampf(cubo["fade"] / TEMPO_DESAPARECER, 0.0, 1.0)
		desenhar_cubo(cubo["pos"], cor, TAMANHO)

	for servidor in servidores:
		desenhar_servidor(servidor)

	desenhar_hud()
	desenhar_botoes()

	match estado:
		Estado.MENU:
			desenhar_tela("DDoS DEFENSE", COR_CAPTCHA, [
				["Humanos (verde) geram créditos e carga. Bots (vermelho) sobrecarregam os servidores.", 20, COR_TEXTO],
				["Clique ou toque nos bots antes do Load Balancer para bloquear (+%d créditos)." % CREDITOS_BOT_CLICADO, 20, COR_TEXTO],
				["Cuidado: clicar em humano faz você perder o cliente.", 20, COR_TEXTO],
				["Gaste os créditos nos upgrades (botões ou teclas 1 a 4). P pausa o jogo.", 20, COR_TEXTO],
				["Se qualquer servidor chegar a 100%, acabou.", 20, COR_CARGA_ALTA],
				["Recorde: %ds" % int(recorde), 22, COR_CREDITOS],
				["Clique ou pressione Espaço para começar", 24, COR_CAPTCHA],
			])
		Estado.JOGANDO:
			desenhar_botao_pausa()
		Estado.PAUSADO:
			desenhar_tela("PAUSADO", COR_TEXTO, [
				["Clique ou pressione P para continuar", 24, COR_CAPTCHA],
			])
		Estado.GAME_OVER:
			var linha_recorde: Array = ["NOVO RECORDE!", 26, COR_CREDITOS] if novo_recorde else ["Recorde: %ds" % int(recorde), 22, COR_CREDITOS]
			desenhar_tela("GAME OVER", COR_CARGA_ALTA, [
				["%s caiu por sobrecarga" % servidor_caiu, 28, COR_TEXTO],
				["Resistiu %ds  |  Humanos servidos: %d  |  Bots bloqueados: %d" % [int(tempo_jogo), humanos_servidos, bots_bloqueados], 22, COR_TEXTO],
				linha_recorde,
				["Clique ou pressione Espaço para jogar de novo", 22, COR_CAPTCHA],
			])


func desenhar_caminhos() -> void:
	var lb := Vector2(X_LOAD_BALANCER, Y_FAIXA)
	draw_line(Vector2(X_INICIO, Y_FAIXA), lb, COR_CAMINHO, 6)
	for servidor in servidores:
		draw_line(lb, servidor["pos"], COR_CAMINHO, 6)


func desenhar_barreira(x: float, cor: Color, nome: String, eficiencia: float) -> void:
	draw_rect(Rect2(x - 6, Y_FAIXA - 130, 12, 170), cor)
	var fonte := ThemeDB.fallback_font
	draw_string(fonte, Vector2(x - 100, Y_FAIXA - 145), "%s %d%%" % [nome, roundi(eficiencia * 100)], HORIZONTAL_ALIGNMENT_CENTER, 200, 18, cor)


func desenhar_load_balancer() -> void:
	var t := TAMANHO_LOAD_BALANCER
	desenhar_cubo(Vector2(X_LOAD_BALANCER, Y_FAIXA + t / 2), COR_LOAD_BALANCER, t)
	var fonte := ThemeDB.fallback_font
	draw_string(fonte, Vector2(X_LOAD_BALANCER - 100, Y_FAIXA - t * 1.5 - 15), "LOAD BALANCER", HORIZONTAL_ALIGNMENT_CENTER, 200, 18, COR_LOAD_BALANCER)


func desenhar_servidor(servidor: Dictionary) -> void:
	var pos: Vector2 = servidor["pos"]
	var proporcao: float = servidor["carga"] / CAPACIDADE
	var piscando := estado == Estado.JOGANDO and proporcao >= ALERTA_CARGA and int(tempo_jogo * 6) % 2 == 0
	var caiu: bool = estado == Estado.GAME_OVER and servidor["nome"] == servidor_caiu
	var cor := COR_CARGA_ALTA if caiu or piscando else COR_SERVIDOR
	var t := TAMANHO_SERVIDOR
	desenhar_cubo(pos + Vector2(0, t / 2), cor, t)

	var fonte := ThemeDB.fallback_font
	var cor_carga := COR_CARGA_BAIXA.lerp(COR_CARGA_ALTA, proporcao)
	var barra := Rect2(pos.x + 40, pos.y - 4, 120, 14)
	draw_string(fonte, Vector2(barra.position.x, barra.position.y - 8), "%s  %d%%" % [servidor["nome"], int(proporcao * 100)], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, COR_TEXTO)
	draw_rect(barra, COR_CAMINHO)
	draw_rect(Rect2(barra.position, Vector2(barra.size.x * proporcao, barra.size.y)), cor_carga)


func desenhar_hud() -> void:
	var fonte := ThemeDB.fallback_font
	var linhas := [
		["Humanos servidos: %d" % humanos_servidos, COR_HUMANO],
		["Humanos perdidos: %d" % humanos_perdidos, COR_TEXTO],
		["Bots bloqueados: %d" % bots_bloqueados, COR_CAPTCHA],
		["Bots que passaram: %d" % bots_passaram, COR_BOT],
		["Tempo: %ds   Req/s: %.1f   Bots: %d%%" % [int(tempo_jogo), 1.0 / intervalo_spawn_atual(), roundi(proporcao_bots_atual() * 100)], COR_TEXTO],
	]
	for i in linhas.size():
		draw_string(fonte, Vector2(40, 50 + i * 28), linhas[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, linhas[i][1])
	draw_string(fonte, Vector2(780, 52), "Créditos: %d" % creditos, HORIZONTAL_ALIGNMENT_RIGHT, 400, 28, COR_CREDITOS)


func desenhar_botoes() -> void:
	var fonte := ThemeDB.fallback_font
	for i in upgrades.size():
		var upgrade: Dictionary = upgrades[i]
		var retangulo := retangulo_botao(i)
		var disponivel := pode_comprar(upgrade)
		var cor_texto := COR_TEXTO if disponivel else COR_TEXTO_APAGADO
		draw_rect(retangulo, COR_BOTAO_ATIVO if disponivel else COR_BOTAO_INATIVO)
		draw_rect(retangulo, COR_CREDITOS if disponivel else COR_CAMINHO, false, 2)
		var x := retangulo.position.x
		var y := retangulo.position.y
		var largura := retangulo.size.x
		var titulo := "[%d] %s" % [i + 1, upgrade["nome"]]
		if upgrade["maximo"] >= 0:
			titulo += "  Nv %d" % upgrade["nivel"]
		var custo := "MÁXIMO" if no_maximo(upgrade) else "Custo: %d" % upgrade["custo"]
		draw_string(fonte, Vector2(x, y + 24), titulo, HORIZONTAL_ALIGNMENT_CENTER, largura, 18, cor_texto)
		draw_string(fonte, Vector2(x, y + 46), texto_efeito(upgrade), HORIZONTAL_ALIGNMENT_CENTER, largura, 14, cor_texto)
		draw_string(fonte, Vector2(x, y + 66), custo, HORIZONTAL_ALIGNMENT_CENTER, largura, 16, COR_CREDITOS if disponivel else COR_TEXTO_APAGADO)


func desenhar_botao_pausa() -> void:
	var r := RETANGULO_PAUSA
	draw_rect(r, COR_BOTAO_ATIVO)
	draw_rect(Rect2(r.position + Vector2(18, 10), Vector2(7, 24)), COR_TEXTO)
	draw_rect(Rect2(r.position + Vector2(31, 10), Vector2(7, 24)), COR_TEXTO)


func desenhar_tela(titulo: String, cor_titulo: Color, linhas: Array) -> void:
	var tela := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, tela), COR_SOBREPOSICAO)
	var fonte := ThemeDB.fallback_font
	var y := tela.y / 2 - 40.0 - linhas.size() * 18.0
	draw_string(fonte, Vector2(0, y), titulo, HORIZONTAL_ALIGNMENT_CENTER, tela.x, 64, cor_titulo)
	y += 70.0
	for linha in linhas:
		draw_string(fonte, Vector2(0, y), linha[0], HORIZONTAL_ALIGNMENT_CENTER, tela.x, linha[1], linha[2])
		y += linha[1] + 16.0


func desenhar_cubo(centro: Vector2, cor: Color, tamanho: float) -> void:
	var t := tamanho
	var h := tamanho
	var topo := PackedVector2Array([
		centro + Vector2(0, -h - t / 2), centro + Vector2(t, -h),
		centro + Vector2(0, -h + t / 2), centro + Vector2(-t, -h)])
	var esquerda := PackedVector2Array([
		centro + Vector2(-t, -h), centro + Vector2(0, -h + t / 2),
		centro + Vector2(0, t / 2), centro + Vector2(-t, 0)])
	var direita := PackedVector2Array([
		centro + Vector2(t, -h), centro + Vector2(0, -h + t / 2),
		centro + Vector2(0, t / 2), centro + Vector2(t, 0)])
	draw_colored_polygon(topo, cor.lightened(0.25))
	draw_colored_polygon(esquerda, cor.darkened(0.2))
	draw_colored_polygon(direita, cor.darkened(0.4))
