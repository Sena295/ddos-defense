extends Node2D

enum Estado { MENU, PREPARACAO, ONDA, PAUSADO, GAME_OVER }

const VELOCIDADE := 170.0
const TAMANHO_REQ := 10.0
const DELTA_MAXIMO := 0.1
const TEMPO_EFEITO := 0.45
const TEMPO_AVISO := 3.0
const ESPERA_REINICIO_MS := 800

const DURACAO_ONDA := 30.0
const TAXA_INICIAL := 2.0
const TAXA_POR_ONDA := 1.2
const TAXA_MAXIMA := 36.0
const BOTS_INICIAL := 0.3
const BOTS_POR_ONDA := 0.04
const BOTS_MAXIMO := 0.75
const SOFISTICACAO_POR_ONDA := 0.03
const SOFISTICACAO_MAXIMA := 0.45
const PESO_POR_ONDA := 0.1
const ONDA_INICIO_PESO := 6

const CAPACIDADE := 100.0
const CARGA_HUMANO := 4.0
const CARGA_BOT := 9.0
const PROCESSAMENTO_NIVEL := [6.0, 9.0, 13.0]
const TEMPO_QUEDA := 5.0
const MAX_SERVIDORES := 5
const CUSTO_SERVIDOR_BASE := 70
const CUSTO_MELHORIA_SERVIDOR := [50, 90]
const CUSTO_LB := 40
const CUSTO_MENOR_CARGA := 30
const CUSTO_HEALTH_CHECK := 30
const NIVEL_MAXIMO := 3

const CREDITOS_INICIAIS := 100
const CREDITO_HUMANO := 1
const BONUS_ONDA_BASE := 25
const BONUS_ONDA_POR_ONDA := 5
const REEMBOLSO := 0.5

const REPUTACAO_MAXIMA := 100.0
const PERDA_FALSO_POSITIVO := 0.5
const PERDA_QUEDA := 1.0
const RECUPERACAO_ONDA := 12.0

const TIPOS := {
	"cdn": {"nome": "CDN / Cache", "cor": Color("60a5fa"), "custo": 60, "resumo": "Responde usuários pelo cache", "cache": [0.3, 0.45, 0.6], "bloqueio": [0.0, 0.0, 0.0], "falso": [0.0, 0.0, 0.0]},
	"waf": {"nome": "Firewall WAF", "cor": Color("f59e0b"), "custo": 50, "resumo": "Filtra bots e quase não erra", "cache": [0.0, 0.0, 0.0], "bloqueio": [0.55, 0.7, 0.85], "falso": [0.01, 0.01, 0.01]},
	"captcha": {"nome": "CAPTCHA", "cor": Color("22d3ee"), "custo": 35, "resumo": "Barra bots, mas irrita humanos", "cache": [0.0, 0.0, 0.0], "bloqueio": [0.7, 0.8, 0.9], "falso": [0.08, 0.06, 0.04]},
	"rate": {"nome": "Rate Limit", "cor": Color("a78bfa"), "custo": 30, "resumo": "Corta excesso por IP, barato", "cache": [0.0, 0.0, 0.0], "bloqueio": [0.4, 0.55, 0.7], "falso": [0.005, 0.005, 0.005]},
}
const CATALOGO := ["cdn", "waf", "captcha", "rate"]

const Y_LINHA := 292.0
const X_INTERNET := 95.0
const XS_SLOTS := [270.0, 445.0, 620.0, 795.0]
const X_LB := 970.0
const X_SERVIDORES := 1168.0
const TAMANHO_NO := Vector2(142, 108)
const TAMANHO_SERVIDOR := Vector2(168, 58)
const ESPACO_SERVIDORES := 70.0
const RETANGULO_TOPO := Rect2(20, 14, 1240, 50)
const RETANGULO_PAINEL := Rect2(20, 528, 1240, 178)
const RETANGULO_PAUSA := Rect2(1210, 21, 40, 36)
const RETANGULO_VELOCIDADE := Rect2(1162, 21, 42, 36)
const RETANGULO_ACAO := Rect2(968, 546, 272, 62)
const X_BOTOES := 40.0
const Y_BOTOES := 580.0
const ALTURA_BOTAO := 112.0

const ARQUIVO_RECORDE := "user://recorde.cfg"

const COR_FUNDO := Color("0a0e17")
const COR_GRADE := Color(1, 1, 1, 0.035)
const COR_CARTAO := Color("111827")
const COR_CARTAO_CLARO := Color("182134")
const COR_BORDA := Color("243047")
const COR_BORDA_HOVER := Color("3b4a68")
const COR_LINHA := Color("1e293d")
const COR_TEXTO := Color("e5e7eb")
const COR_TEXTO_SUAVE := Color("8b95a8")
const COR_HUMANO := Color("34d399")
const COR_BOT := Color("f87171")
const COR_DESTAQUE := Color("38bdf8")
const COR_CREDITOS := Color("fbbf24")
const COR_LB := Color("c084fc")
const COR_SERVIDOR := Color("94a3b8")
const COR_PERIGO := Color("ef4444")
const COR_BOTAO_PRINCIPAL := Color("10b981")
const COR_SOMBRA := Color(0, 0, 0, 0.35)
const COR_SOBREPOSICAO := Color(0.02, 0.03, 0.06, 0.8)
const TRANSPARENTE := Color(0, 0, 0, 0)

static var pular_menu := false

var estado := Estado.MENU
var estado_antes_pausa := Estado.PREPARACAO
var velocidade_jogo := 1.0
var requisicoes: Array = []
var efeitos: Array = []
var avisos: Array = []
var slots: Array = [{}, {}, {}, {}]
var lb := {"instalado": false, "menor_carga": false, "health_check": false, "proximo": 0}
var servidores: Array = []
var selecao: Dictionary = {}
var creditos := CREDITOS_INICIAIS
var reputacao := REPUTACAO_MAXIMA
var onda := 1
var config: Dictionary = {}
var tempo_onda := 0.0
var acumulador_spawn := 0.0
var estatisticas: Dictionary = {}
var tem_dados := false
var recorde := 0
var novo_recorde := false
var momento_fim_ms := 0
var total_humanos_servidos := 0
var total_bots_bloqueados := 0
var mouse := Vector2.ZERO
var tempo_animacao := 0.0
var grade := PackedVector2Array()
var estilo := StyleBoxFlat.new()
var fonte: Font


func _ready() -> void:
	fonte = ThemeDB.fallback_font
	estilo.anti_aliasing = true
	for x in range(0, 1281, 40):
		grade.append(Vector2(x, 0))
		grade.append(Vector2(x, 720))
	for y in range(0, 721, 40):
		grade.append(Vector2(0, y))
		grade.append(Vector2(1280, y))
	carregar_recorde()
	adicionar_servidor()
	config = config_onda(onda)
	zerar_estatisticas()
	if pular_menu:
		pular_menu = false
		estado = Estado.PREPARACAO


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and (estado == Estado.ONDA or estado == Estado.PREPARACAO):
		pausar()


func _process(delta: float) -> void:
	mouse = get_local_mouse_position()
	tempo_animacao += delta
	for aviso in avisos:
		aviso["tempo"] -= delta
	avisos = avisos.filter(func(a): return a["tempo"] > 0.0)
	if estado == Estado.PREPARACAO or estado == Estado.ONDA:
		simular(minf(delta, DELTA_MAXIMO) * velocidade_jogo)
	queue_redraw()


func simular(dt: float) -> void:
	if estado == Estado.ONDA:
		tempo_onda += dt
		estatisticas["tempo"] += dt
		if tempo_onda < config["duracao"]:
			acumulador_spawn += dt * taxa_atual()
			while acumulador_spawn >= 1.0:
				acumulador_spawn -= 1.0
				criar_requisicao()

	for requisicao in requisicoes:
		atualizar_requisicao(requisicao, dt)
	requisicoes = requisicoes.filter(func(r): return not r["remover"])

	for i in servidores.size():
		atualizar_servidor(i, dt)

	for efeito in efeitos:
		efeito["tempo"] -= dt
	efeitos = efeitos.filter(func(e): return e["tempo"] > 0.0)

	for slot in slots:
		if not slot.is_empty():
			slot["pulso"] = maxf(0.0, slot["pulso"] - dt * 3.0)
	for servidor in servidores:
		servidor["pulso"] = maxf(0.0, servidor["pulso"] - dt * 3.0)

	if estado == Estado.ONDA and tempo_onda >= config["duracao"] and requisicoes.is_empty():
		concluir_onda()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		tratar_tecla(event.keycode)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local := make_input_local(event) as InputEventMouseButton
		tratar_clique(local.position)


func tratar_tecla(tecla: Key) -> void:
	match estado:
		Estado.MENU:
			if tecla == KEY_SPACE or tecla == KEY_ENTER:
				estado = Estado.PREPARACAO
		Estado.PAUSADO:
			if tecla == KEY_P or tecla == KEY_ESCAPE or tecla == KEY_SPACE:
				estado = estado_antes_pausa
		Estado.GAME_OVER:
			if tecla == KEY_R or tecla == KEY_SPACE or tecla == KEY_ENTER:
				reiniciar()
		Estado.PREPARACAO, Estado.ONDA:
			if tecla == KEY_P:
				pausar()
			elif tecla == KEY_ESCAPE:
				if selecao.is_empty():
					pausar()
				else:
					selecao = {}
			elif tecla == KEY_F:
				alternar_velocidade()
			elif (tecla == KEY_SPACE or tecla == KEY_ENTER) and estado == Estado.PREPARACAO:
				iniciar_onda()


func tratar_clique(pos: Vector2) -> void:
	match estado:
		Estado.MENU:
			estado = Estado.PREPARACAO
		Estado.PAUSADO:
			estado = estado_antes_pausa
		Estado.GAME_OVER:
			reiniciar()
		Estado.PREPARACAO, Estado.ONDA:
			if RETANGULO_PAUSA.has_point(pos):
				pausar()
				return
			if RETANGULO_VELOCIDADE.has_point(pos):
				alternar_velocidade()
				return
			for botao in botoes_painel():
				if botao["rect"].has_point(pos):
					if botao["ativo"]:
						botao["acao"].call()
					return
			for i in XS_SLOTS.size():
				if retangulo_slot(i).has_point(pos):
					selecao = {"tipo": "slot", "indice": i}
					return
			if retangulo_lb().has_point(pos):
				selecao = {"tipo": "lb"}
				return
			for i in servidores.size():
				if retangulo_servidor(i).has_point(pos):
					selecao = {"tipo": "servidor", "indice": i}
					return
			if servidores.size() < MAX_SERVIDORES and retangulo_novo_servidor().has_point(pos):
				selecao = {"tipo": "novo_servidor"}
				return
			if not RETANGULO_PAINEL.has_point(pos):
				selecao = {}


func pausar() -> void:
	if estado == Estado.ONDA or estado == Estado.PREPARACAO:
		estado_antes_pausa = estado
		estado = Estado.PAUSADO


func alternar_velocidade() -> void:
	velocidade_jogo = 2.0 if velocidade_jogo == 1.0 else 1.0


func reiniciar() -> void:
	if Time.get_ticks_msec() - momento_fim_ms < ESPERA_REINICIO_MS:
		return
	pular_menu = true
	get_tree().reload_current_scene()


func config_onda(numero: int) -> Dictionary:
	var taxa := TAXA_INICIAL + TAXA_POR_ONDA * (numero - 1)
	var bots := minf(BOTS_MAXIMO, BOTS_INICIAL + BOTS_POR_ONDA * (numero - 1))
	var nome := "Tráfego normal"
	if numero == 1:
		nome = "Aquecimento"
	elif numero % 4 == 0:
		nome = "Ataque de botnet"
		bots = minf(0.9, bots + 0.25)
		taxa *= 1.25
	elif numero % 3 == 0:
		nome = "Pico de usuários"
		bots = maxf(0.1, bots - 0.2)
		taxa *= 1.35
	return {"nome": nome, "taxa": minf(TAXA_MAXIMA, taxa), "bots": bots, "duracao": DURACAO_ONDA}


func taxa_atual() -> float:
	return config["taxa"] * (1.0 + 0.3 * sin(tempo_onda * 1.3))


func sofisticacao() -> float:
	return minf(SOFISTICACAO_MAXIMA, SOFISTICACAO_POR_ONDA * (onda - 1))


func peso_onda() -> float:
	return 1.0 + PESO_POR_ONDA * maxf(0.0, onda - ONDA_INICIO_PESO)


func zerar_estatisticas() -> void:
	estatisticas = {
		"humanos": 0, "bots": 0, "humanos_servidos": 0, "humanos_cache": 0,
		"humanos_barrados": 0, "humanos_perdidos_queda": 0, "bots_bloqueados": 0,
		"bots_servidor": 0, "quedas": 0, "enviados_caido": 0,
		"barrados": {}, "carga_soma": [], "tempo": 0.0,
	}


func iniciar_onda() -> void:
	if estado != Estado.PREPARACAO:
		return
	config = config_onda(onda)
	zerar_estatisticas()
	tem_dados = true
	tempo_onda = 0.0
	acumulador_spawn = 0.0
	estado = Estado.ONDA


func concluir_onda() -> void:
	var bonus := BONUS_ONDA_BASE + BONUS_ONDA_POR_ONDA * onda
	creditos += bonus
	reputacao = minf(REPUTACAO_MAXIMA, reputacao + RECUPERACAO_ONDA)
	avisar("Onda %d concluída  +%d créditos" % [onda, bonus], COR_HUMANO)
	if onda > recorde:
		recorde = onda
		novo_recorde = true
		salvar_recorde()
	onda += 1
	config = config_onda(onda)
	selecao = {}
	estado = Estado.PREPARACAO


func finalizar_partida() -> void:
	estado = Estado.GAME_OVER
	momento_fim_ms = Time.get_ticks_msec()


func perder_reputacao(valor: float) -> void:
	reputacao = maxf(0.0, reputacao - valor)
	if reputacao <= 0.0 and estado == Estado.ONDA:
		finalizar_partida()


func avisar(texto_aviso: String, cor: Color) -> void:
	avisos.append({"texto": texto_aviso, "cor": cor, "tempo": TEMPO_AVISO})
	if avisos.size() > 3:
		avisos.pop_front()


func criar_requisicao() -> void:
	var bot: bool = randf() < config["bots"]
	estatisticas["bots" if bot else "humanos"] += 1
	requisicoes.append({
		"pos": Vector2(X_INTERNET + TAMANHO_NO.x / 2, Y_LINHA),
		"bot": bot,
		"slot": 0,
		"servidor": -1,
		"t": 0.0,
		"remover": false,
	})


func atualizar_requisicao(requisicao: Dictionary, dt: float) -> void:
	if requisicao["servidor"] >= 0:
		var indice: int = requisicao["servidor"]
		requisicao["t"] = minf(1.0, requisicao["t"] + dt * VELOCIDADE / comprimento_ramo(indice))
		requisicao["pos"] = ponto_ramo(indice, requisicao["t"])
		if requisicao["t"] >= 1.0:
			entregar(requisicao)
		return

	requisicao["pos"].x += VELOCIDADE * dt
	while requisicao["slot"] < XS_SLOTS.size() and requisicao["pos"].x >= XS_SLOTS[requisicao["slot"]]:
		var indice_slot: int = requisicao["slot"]
		requisicao["slot"] += 1
		processar_slot(requisicao, indice_slot)
		if requisicao["remover"]:
			return

	if requisicao["pos"].x >= X_LB:
		requisicao["servidor"] = escolher_servidor()
		requisicao["t"] = 0.0


func processar_slot(requisicao: Dictionary, indice: int) -> void:
	var slot: Dictionary = slots[indice]
	if slot.is_empty():
		return
	var dados: Dictionary = TIPOS[slot["tipo"]]
	var nivel: int = slot["nivel"] - 1
	slot["pulso"] = 1.0
	if requisicao["bot"]:
		var chance: float = dados["bloqueio"][nivel] * (1.0 - sofisticacao())
		if randf() < chance:
			remover_com_efeito(requisicao, COR_BOT)
			slot["contagem"] += 1
			estatisticas["bots_bloqueados"] += 1
			total_bots_bloqueados += 1
		return
	var cache: float = dados["cache"][nivel]
	if cache > 0.0 and randf() < cache:
		remover_com_efeito(requisicao, dados["cor"])
		slot["contagem"] += 1
		creditos += CREDITO_HUMANO
		estatisticas["humanos_servidos"] += 1
		estatisticas["humanos_cache"] += 1
		total_humanos_servidos += 1
		return
	if randf() < dados["falso"][nivel]:
		remover_com_efeito(requisicao, COR_CREDITOS)
		estatisticas["humanos_barrados"] += 1
		var barrados: Dictionary = estatisticas["barrados"]
		barrados[slot["tipo"]] = barrados.get(slot["tipo"], 0) + 1
		perder_reputacao(PERDA_FALSO_POSITIVO)


func remover_com_efeito(requisicao: Dictionary, cor: Color) -> void:
	requisicao["remover"] = true
	efeitos.append({"pos": requisicao["pos"], "cor": cor, "tempo": TEMPO_EFEITO})


func escolher_servidor() -> int:
	if not lb["instalado"]:
		return 0
	var candidatos: Array = []
	for i in servidores.size():
		if not lb["health_check"] or servidores[i]["caido"] <= 0.0:
			candidatos.append(i)
	if candidatos.is_empty():
		candidatos = range(servidores.size())
	if lb["menor_carga"]:
		var melhor: int = candidatos[0]
		for i in candidatos:
			if servidores[i]["carga"] < servidores[melhor]["carga"]:
				melhor = i
		return melhor
	var escolhido: int = candidatos[lb["proximo"] % candidatos.size()]
	lb["proximo"] += 1
	return escolhido


func entregar(requisicao: Dictionary) -> void:
	requisicao["remover"] = true
	var servidor: Dictionary = servidores[requisicao["servidor"]]
	if servidor["caido"] > 0.0:
		estatisticas["enviados_caido"] += 1
		efeitos.append({"pos": requisicao["pos"], "cor": COR_PERIGO, "tempo": TEMPO_EFEITO})
		if not requisicao["bot"]:
			estatisticas["humanos_perdidos_queda"] += 1
			perder_reputacao(PERDA_QUEDA)
		return
	servidor["pulso"] = 1.0
	if requisicao["bot"]:
		servidor["carga"] += CARGA_BOT * peso_onda()
		estatisticas["bots_servidor"] += 1
	else:
		servidor["carga"] += CARGA_HUMANO * peso_onda()
		creditos += CREDITO_HUMANO
		estatisticas["humanos_servidos"] += 1
		total_humanos_servidos += 1


func atualizar_servidor(indice: int, dt: float) -> void:
	var servidor: Dictionary = servidores[indice]
	if servidor["caido"] > 0.0:
		servidor["caido"] = maxf(0.0, servidor["caido"] - dt)
		return
	servidor["carga"] = maxf(0.0, servidor["carga"] - PROCESSAMENTO_NIVEL[servidor["nivel"]] * dt)
	if estado == Estado.ONDA:
		var somas: Array = estatisticas["carga_soma"]
		while somas.size() < servidores.size():
			somas.append(0.0)
		somas[indice] += servidor["carga"] * dt
	if servidor["carga"] >= CAPACIDADE:
		servidor["carga"] = 0.0
		servidor["caido"] = TEMPO_QUEDA
		estatisticas["quedas"] += 1
		avisar("S%d caiu por sobrecarga" % (indice + 1), COR_PERIGO)


func adicionar_servidor() -> void:
	servidores.append({"carga": 0.0, "nivel": 0, "caido": 0.0, "pulso": 0.0})


func custo_servidor() -> int:
	return roundi(CUSTO_SERVIDOR_BASE * pow(1.5, servidores.size() - 1))


func custo_melhoria(slot: Dictionary) -> int:
	return roundi(TIPOS[slot["tipo"]]["custo"] * 0.8 * slot["nivel"])


func comprar_componente(indice: int, tipo: String) -> void:
	var custo: int = TIPOS[tipo]["custo"]
	if not slots[indice].is_empty() or creditos < custo:
		return
	creditos -= custo
	slots[indice] = {"tipo": tipo, "nivel": 1, "investido": custo, "contagem": 0, "pulso": 0.0}
	selecao = {"tipo": "slot", "indice": indice}


func melhorar_componente(indice: int) -> void:
	var slot: Dictionary = slots[indice]
	if slot.is_empty() or slot["nivel"] >= NIVEL_MAXIMO:
		return
	var custo := custo_melhoria(slot)
	if creditos < custo:
		return
	creditos -= custo
	slot["nivel"] += 1
	slot["investido"] += custo


func mover_componente(indice: int, direcao: int) -> void:
	var destino := indice + direcao
	if destino < 0 or destino >= slots.size():
		return
	var temporario: Dictionary = slots[destino]
	slots[destino] = slots[indice]
	slots[indice] = temporario
	selecao = {"tipo": "slot", "indice": destino}


func remover_componente(indice: int) -> void:
	var slot: Dictionary = slots[indice]
	if slot.is_empty():
		return
	creditos += roundi(slot["investido"] * REEMBOLSO)
	slots[indice] = {}


func instalar_lb() -> void:
	if lb["instalado"] or creditos < CUSTO_LB:
		return
	creditos -= CUSTO_LB
	lb["instalado"] = true


func comprar_menor_carga() -> void:
	if not lb["instalado"] or lb["menor_carga"] or creditos < CUSTO_MENOR_CARGA:
		return
	creditos -= CUSTO_MENOR_CARGA
	lb["menor_carga"] = true


func comprar_health_check() -> void:
	if not lb["instalado"] or lb["health_check"] or creditos < CUSTO_HEALTH_CHECK:
		return
	creditos -= CUSTO_HEALTH_CHECK
	lb["health_check"] = true


func comprar_servidor() -> void:
	if servidores.size() >= MAX_SERVIDORES or creditos < custo_servidor():
		return
	creditos -= custo_servidor()
	adicionar_servidor()
	selecao = {"tipo": "servidor", "indice": servidores.size() - 1}


func melhorar_servidor(indice: int) -> void:
	var servidor: Dictionary = servidores[indice]
	var nivel: int = servidor["nivel"]
	if nivel >= NIVEL_MAXIMO - 1 or creditos < CUSTO_MELHORIA_SERVIDOR[nivel]:
		return
	creditos -= CUSTO_MELHORIA_SERVIDOR[nivel]
	servidor["nivel"] += 1


func indice_tipo(tipo: String) -> int:
	for i in slots.size():
		if not slots[i].is_empty() and slots[i]["tipo"] == tipo:
			return i
	return -1


func primeiro_filtro() -> int:
	for i in slots.size():
		if not slots[i].is_empty() and slots[i]["tipo"] != "cdn":
			return i
	return -1


func desequilibrio() -> float:
	var somas: Array = estatisticas["carga_soma"]
	var tempo: float = estatisticas["tempo"]
	if somas.size() < 2 or tempo <= 0.0:
		return 0.0
	var maior := 0.0
	var menor := INF
	for soma in somas:
		var media: float = soma / tempo
		maior = maxf(maior, media)
		menor = minf(menor, media)
	if maior < 20.0:
		return 0.0
	return (maior - menor) / maior


func recomendacoes() -> Array:
	if not tem_dados:
		return [
			"Clique em um slot vazio (+) para instalar um componente. O tráfego passa pelos slots da esquerda para a direita, então a ordem importa.",
			"Humanos atendidos dão créditos; bots só geram carga. Servidor acima de 100% cai por alguns segundos e quem chegar nele é perdido.",
			"Se a reputação chegar a 0 o site sai do ar. Um bom começo: um WAF no primeiro slot e créditos guardados para o segundo servidor.",
		]
	var dicas: Array = []
	var e := estatisticas
	if estado == Estado.PREPARACAO:
		if config["nome"] == "Ataque de botnet":
			dicas.append("Próxima onda: ataque de botnet com %d%% de bots. Reforce os filtros antes de começar." % roundi(config["bots"] * 100))
		elif config["nome"] == "Pico de usuários":
			dicas.append("Próxima onda: pico de usuários reais. CDN e mais servidores ajudam mais do que filtros.")
	if servidores.size() > 1 and not lb["instalado"]:
		dicas.append("Sem Load Balancer, todo o tráfego vai para o S1 e os outros servidores ficam parados. Clique no nó roxo para instalar um.")
	if e["quedas"] > 0:
		if servidores.size() == 1:
			dicas.append("O S1 caiu %d vez(es). Escale na horizontal: compre mais um servidor e instale um Load Balancer para dividir a carga." % e["quedas"])
		else:
			dicas.append("Servidores caíram %d vez(es). Aumente a capacidade total: mais servidores ou upgrades nos existentes." % e["quedas"])
	if e["enviados_caido"] > 0 and lb["instalado"] and not lb["health_check"]:
		dicas.append("%d requisições foram enviadas para servidor caído. O Health Check faz o Load Balancer pular quem está fora do ar." % e["enviados_caido"])
	if lb["instalado"] and not lb["menor_carga"] and desequilibrio() > 0.25:
		dicas.append("A carga ficou desigual entre os servidores. A estratégia Menor carga envia cada requisição para o servidor mais livre.")
	if e["bots"] >= 10 and float(e["bots_servidor"]) / e["bots"] > 0.25:
		dicas.append("%d%% dos bots chegaram aos servidores. Empilhe filtros (WAF, Rate Limit, CAPTCHA): camadas em sequência multiplicam a proteção." % roundi(100.0 * e["bots_servidor"] / e["bots"]))
	var barrados_captcha: int = e["barrados"].get("captcha", 0)
	if barrados_captcha >= 5:
		var cdn := indice_tipo("cdn")
		if cdn < 0 or cdn > indice_tipo("captcha"):
			dicas.append("O CAPTCHA barrou %d usuários reais. Coloque um CDN antes dele: quem é atendido pelo cache nem passa pelo desafio." % barrados_captcha)
		else:
			dicas.append("O CAPTCHA barrou %d usuários reais. Um WAF erra bem menos com humanos." % barrados_captcha)
	if indice_tipo("cdn") < 0 and e["humanos"] >= 30 and e["humanos_servidos"] * CARGA_HUMANO > e["bots_servidor"] * CARGA_BOT:
		dicas.append("A maior parte da carga vem de usuários reais. Um CDN responde pelo cache e tira até 60% dessa carga dos servidores.")
	var cdn_atual := indice_tipo("cdn")
	var filtro := primeiro_filtro()
	if cdn_atual >= 0 and filtro >= 0 and filtro < cdn_atual:
		dicas.append("Mova o CDN para antes dos filtros: o que sai do cache não precisa passar por eles nem corre o risco de ser barrado.")
	if dicas.is_empty():
		dicas.append("Arquitetura saudável. O tráfego cresce a cada onda: guarde créditos e reforce o ponto mais carregado.")
	return dicas.slice(0, 3)


func descricao_nivel(tipo: String, nivel: int, curta := false) -> String:
	var dados: Dictionary = TIPOS[tipo]
	if tipo == "cdn":
		return ("Cache %d%% humanos" if curta else "Cache: %d%% dos humanos") % roundi(dados["cache"][nivel] * 100)
	var falso: float = dados["falso"][nivel] * 100.0
	var texto_falso := "%.1f" % falso if falso < 1.0 else "%d" % roundi(falso)
	return "Bots %d%% · erro %s%%" % [roundi(dados["bloqueio"][nivel] * 100), texto_falso]


func nome_estrategia() -> String:
	var nome := "Menor carga" if lb["menor_carga"] else "Round-robin"
	if lb["health_check"]:
		nome += " + HC"
	return nome


func botao(rect: Rect2, titulo: String, linhas: Array, rodape: String, cor: Color, ativo: bool, acao: Callable, icone := "") -> Dictionary:
	return {"rect": rect, "titulo": titulo, "linhas": linhas, "rodape": rodape, "cor": cor, "ativo": ativo, "acao": acao, "icone": icone}


func botoes_painel() -> Array:
	var botoes: Array = []
	if estado == Estado.PREPARACAO:
		var principal := botao(RETANGULO_ACAO, "Iniciar onda %d" % onda, ["Espaço"], "", COR_BOTAO_PRINCIPAL, true, iniciar_onda)
		principal["principal"] = true
		botoes.append(principal)
	match selecao.get("tipo", ""):
		"slot":
			var indice: int = selecao["indice"]
			var slot: Dictionary = slots[indice]
			if slot.is_empty():
				for k in CATALOGO.size():
					var tipo: String = CATALOGO[k]
					var dados: Dictionary = TIPOS[tipo]
					botoes.append(botao(Rect2(X_BOTOES + k * 226, Y_BOTOES, 214, ALTURA_BOTAO), dados["nome"], [dados["resumo"], descricao_nivel(tipo, 0)], "Custo %d" % dados["custo"], dados["cor"], creditos >= dados["custo"], comprar_componente.bind(indice, tipo), tipo))
			else:
				var tipo_atual: String = slot["tipo"]
				var cor: Color = TIPOS[tipo_atual]["cor"]
				var nivel: int = slot["nivel"]
				var maximo := nivel >= NIVEL_MAXIMO
				var linhas_melhoria: Array = ["Agora: " + descricao_nivel(tipo_atual, nivel - 1)]
				if not maximo:
					linhas_melhoria.append("Depois: " + descricao_nivel(tipo_atual, nivel))
				botoes.append(botao(Rect2(X_BOTOES, Y_BOTOES, 250, ALTURA_BOTAO), "Melhorar", linhas_melhoria, "Nível máximo" if maximo else "Custo %d" % custo_melhoria(slot), cor, not maximo and creditos >= custo_melhoria(slot), melhorar_componente.bind(indice), tipo_atual))
				botoes.append(botao(Rect2(X_BOTOES + 262, Y_BOTOES, 180, ALTURA_BOTAO), "< Mover", ["Processa antes", "no fluxo"], "Grátis", COR_TEXTO_SUAVE, indice > 0, mover_componente.bind(indice, -1)))
				botoes.append(botao(Rect2(X_BOTOES + 454, Y_BOTOES, 180, ALTURA_BOTAO), "Mover >", ["Processa depois", "no fluxo"], "Grátis", COR_TEXTO_SUAVE, indice < slots.size() - 1, mover_componente.bind(indice, 1)))
				botoes.append(botao(Rect2(X_BOTOES + 646, Y_BOTOES, 246, ALTURA_BOTAO), "Remover", ["Libera o slot", "Devolve metade do investido"], "+%d créditos" % roundi(slot["investido"] * REEMBOLSO), COR_PERIGO, true, remover_componente.bind(indice)))
		"lb":
			if not lb["instalado"]:
				botoes.append(botao(Rect2(X_BOTOES, Y_BOTOES, 300, ALTURA_BOTAO), "Instalar Load Balancer", ["Divide o tráfego entre", "todos os servidores"], "Custo %d" % CUSTO_LB, COR_LB, creditos >= CUSTO_LB, instalar_lb, "lb"))
			else:
				botoes.append(botao(Rect2(X_BOTOES, Y_BOTOES, 300, ALTURA_BOTAO), "Estratégia Menor carga", ["Envia cada requisição para", "o servidor mais livre"], "Ativa" if lb["menor_carga"] else "Custo %d" % CUSTO_MENOR_CARGA, COR_LB, not lb["menor_carga"] and creditos >= CUSTO_MENOR_CARGA, comprar_menor_carga, "lb"))
				botoes.append(botao(Rect2(X_BOTOES + 312, Y_BOTOES, 300, ALTURA_BOTAO), "Health Check", ["Não envia tráfego para", "servidor fora do ar"], "Ativo" if lb["health_check"] else "Custo %d" % CUSTO_HEALTH_CHECK, COR_HUMANO, not lb["health_check"] and creditos >= CUSTO_HEALTH_CHECK, comprar_health_check, "servidor"))
		"servidor":
			var indice_servidor: int = selecao["indice"]
			var nivel_servidor: int = servidores[indice_servidor]["nivel"]
			var maximo_servidor := nivel_servidor >= NIVEL_MAXIMO - 1
			var linhas: Array = ["Processa %d de carga/s" % roundi(PROCESSAMENTO_NIVEL[nivel_servidor])]
			if not maximo_servidor:
				linhas.append("Depois: %d de carga/s" % roundi(PROCESSAMENTO_NIVEL[nivel_servidor + 1]))
			var custo_servidor_atual: int = 0 if maximo_servidor else CUSTO_MELHORIA_SERVIDOR[nivel_servidor]
			botoes.append(botao(Rect2(X_BOTOES, Y_BOTOES, 300, ALTURA_BOTAO), "Melhorar S%d" % (indice_servidor + 1), linhas, "Nível máximo" if maximo_servidor else "Custo %d" % custo_servidor_atual, COR_SERVIDOR, not maximo_servidor and creditos >= custo_servidor_atual, melhorar_servidor.bind(indice_servidor), "servidor"))
		"novo_servidor":
			botoes.append(botao(Rect2(X_BOTOES, Y_BOTOES, 300, ALTURA_BOTAO), "Comprar S%d" % (servidores.size() + 1), ["Mais capacidade total.", "Precisa de Load Balancer."], "Custo %d" % custo_servidor(), COR_SERVIDOR, creditos >= custo_servidor(), comprar_servidor, "servidor"))
	return botoes


func titulo_painel() -> String:
	match selecao.get("tipo", ""):
		"slot":
			var indice: int = selecao["indice"]
			var slot: Dictionary = slots[indice]
			if slot.is_empty():
				return "Slot %d  ·  escolha um componente" % (indice + 1)
			var verbo := "atendeu pelo cache" if slot["tipo"] == "cdn" else "bloqueou"
			return "%s  ·  nível %d/%d  ·  %s %d" % [TIPOS[slot["tipo"]]["nome"], slot["nivel"], NIVEL_MAXIMO, verbo, slot["contagem"]]
		"lb":
			return "Load Balancer  ·  %s" % (nome_estrategia() if lb["instalado"] else "não instalado")
		"servidor":
			var indice_servidor: int = selecao["indice"]
			return "Servidor S%d  ·  nível %d/%d" % [indice_servidor + 1, servidores[indice_servidor]["nivel"] + 1, NIVEL_MAXIMO]
		"novo_servidor":
			return "Novo servidor"
	return "Recomendações" + ("  ·  baseadas na última onda" if tem_dados and estado == Estado.PREPARACAO else "")


func retangulo_no(centro: Vector2, tamanho: Vector2) -> Rect2:
	return Rect2(centro - tamanho / 2, tamanho)


func retangulo_slot(indice: int) -> Rect2:
	return retangulo_no(Vector2(XS_SLOTS[indice], Y_LINHA), TAMANHO_NO)


func retangulo_lb() -> Rect2:
	return retangulo_no(Vector2(X_LB, Y_LINHA), TAMANHO_NO)


func quantidade_itens_servidor() -> int:
	return servidores.size() + (1 if servidores.size() < MAX_SERVIDORES else 0)


func y_servidor(indice: int) -> float:
	return Y_LINHA - (quantidade_itens_servidor() - 1) * ESPACO_SERVIDORES / 2 + indice * ESPACO_SERVIDORES


func retangulo_servidor(indice: int) -> Rect2:
	return retangulo_no(Vector2(X_SERVIDORES, y_servidor(indice)), TAMANHO_SERVIDOR)


func retangulo_novo_servidor() -> Rect2:
	return retangulo_no(Vector2(X_SERVIDORES, y_servidor(servidores.size())), TAMANHO_SERVIDOR)


func pontos_ramo(indice: int) -> Array:
	var inicio := Vector2(X_LB, Y_LINHA)
	var fim := Vector2(X_SERVIDORES - TAMANHO_SERVIDOR.x / 2, y_servidor(indice))
	return [inicio, inicio + Vector2(90, 0), fim - Vector2(70, 0), fim]


func ponto_ramo(indice: int, t: float) -> Vector2:
	var p := pontos_ramo(indice)
	var u := 1.0 - t
	return u * u * u * p[0] + 3.0 * u * u * t * p[1] + 3.0 * u * t * t * p[2] + t * t * t * p[3]


func comprimento_ramo(indice: int) -> float:
	var p := pontos_ramo(indice)
	return maxf(1.0, p[0].distance_to(p[3]) * 1.08)


func carregar_recorde() -> void:
	var arquivo := ConfigFile.new()
	if arquivo.load(ARQUIVO_RECORDE) == OK:
		recorde = int(arquivo.get_value("jogo", "recorde_ondas", 0))


func salvar_recorde() -> void:
	var arquivo := ConfigFile.new()
	arquivo.set_value("jogo", "recorde_ondas", recorde)
	arquivo.save(ARQUIVO_RECORDE)


func caixa(r: Rect2, fundo: Color, raio := 12, borda := TRANSPARENTE, largura := 0, sombra := 0, detalhe := 8) -> void:
	estilo.bg_color = fundo
	estilo.set_corner_radius_all(raio)
	estilo.corner_detail = detalhe
	estilo.border_color = borda
	estilo.set_border_width_all(largura)
	estilo.shadow_size = sombra
	estilo.shadow_color = COR_SOMBRA
	estilo.shadow_offset = Vector2(0, sombra * 0.4)
	draw_style_box(estilo, r)


func texto(pos: Vector2, conteudo: String, tamanho: int, cor: Color, alinhamento := HORIZONTAL_ALIGNMENT_LEFT, largura := -1.0) -> void:
	draw_string(fonte, pos, conteudo, alinhamento, largura, tamanho, cor)


func largura_texto(conteudo: String, tamanho: int) -> float:
	return fonte.get_string_size(conteudo, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x


func esta_selecionado(tipo: String, indice := -1) -> bool:
	return selecao.get("tipo", "") == tipo and selecao.get("indice", -1) == indice


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), COR_FUNDO)
	draw_multiline(grade, COR_GRADE, 1.0)
	desenhar_conexoes()

	for requisicao in requisicoes:
		var cor: Color = COR_BOT if requisicao["bot"] else COR_HUMANO
		var meio := TAMANHO_REQ / 2
		caixa(Rect2(requisicao["pos"] - Vector2(meio, meio), Vector2(TAMANHO_REQ, TAMANHO_REQ)), cor, 3, TRANSPARENTE, 0, 0, 2)

	for efeito in efeitos:
		var progresso: float = 1.0 - efeito["tempo"] / TEMPO_EFEITO
		var cor_efeito: Color = efeito["cor"]
		cor_efeito.a = 1.0 - progresso
		draw_arc(efeito["pos"], 5.0 + progresso * 14.0, 0.0, TAU, 24, cor_efeito, 2.0, true)

	desenhar_internet()
	for i in XS_SLOTS.size():
		desenhar_slot(i)
	desenhar_lb()
	for i in servidores.size():
		desenhar_servidor(i)
	if servidores.size() < MAX_SERVIDORES:
		desenhar_novo_servidor()

	desenhar_topo()
	desenhar_painel()
	desenhar_avisos()

	match estado:
		Estado.MENU:
			desenhar_janela("DDoS Defense", COR_DESTAQUE, [
				["Monte a arquitetura que mantém seu site no ar durante ataques DDoS.", 18, COR_TEXTO],
				["Instale CDN, WAF, CAPTCHA e Rate Limit nos slots, na ordem que quiser.", 16, COR_TEXTO_SUAVE],
				["Use Load Balancer e vários servidores para aguentar mais tráfego.", 16, COR_TEXTO_SUAVE],
				["Cada onda traz mais requisições. Leia as recomendações entre as ondas.", 16, COR_TEXTO_SUAVE],
				["Recorde: onda %d" % recorde, 18, COR_CREDITOS],
				["Clique ou pressione Espaço para começar", 20, COR_HUMANO],
			])
		Estado.PAUSADO:
			desenhar_janela("Pausado", COR_TEXTO, [
				["Clique ou pressione P para continuar", 20, COR_HUMANO],
			])
		Estado.GAME_OVER:
			desenhar_janela("Site fora do ar", COR_PERIGO, [
				["A reputação chegou a 0 durante a onda %d." % onda, 18, COR_TEXTO],
				["Ondas concluídas: %d" % (onda - 1), 22, COR_TEXTO],
				["Humanos atendidos: %d  ·  Bots bloqueados: %d" % [total_humanos_servidos, total_bots_bloqueados], 16, COR_TEXTO_SUAVE],
				["NOVO RECORDE!" if novo_recorde else "Recorde: onda %d" % recorde, 20, COR_CREDITOS],
				["Clique ou pressione Espaço para jogar de novo", 20, COR_HUMANO],
			])


func desenhar_conexoes() -> void:
	var inicio := Vector2(X_INTERNET + TAMANHO_NO.x / 2, Y_LINHA)
	draw_line(inicio, Vector2(X_LB, Y_LINHA), COR_LINHA, 4.0, true)
	for i in servidores.size():
		var cor := COR_LINHA
		if not lb["instalado"] and i > 0:
			cor.a = 0.35
		var pontos := PackedVector2Array()
		for k in 25:
			pontos.append(ponto_ramo(i, k / 24.0))
		draw_polyline(pontos, cor, 3.0, true)


func desenhar_no(r: Rect2, cor: Color, titulo: String, subtitulo: String, icone: String, selecionado: bool, pulso := 0.0, nivel := 0) -> void:
	var hover := r.has_point(mouse) and (estado == Estado.PREPARACAO or estado == Estado.ONDA)
	var borda := COR_BORDA_HOVER if hover else COR_BORDA
	if pulso > 0.0:
		borda = borda.lerp(cor, pulso)
	if selecionado:
		borda = cor
	caixa(r, COR_CARTAO, 14, borda, 2 if selecionado else 1, 10)
	var badge := Rect2(r.position + Vector2(14, 14), Vector2(36, 36))
	var fundo_badge := cor
	fundo_badge.a = 0.14
	caixa(badge, fundo_badge, 10)
	desenhar_icone(icone, badge.get_center(), cor)
	if nivel > 0:
		for k in NIVEL_MAXIMO:
			var cor_ponto := cor if k < nivel else COR_BORDA
			draw_circle(Vector2(r.end.x - 40 + k * 11, r.position.y + 20), 3.5, cor_ponto, true, -1.0, true)
	texto(r.position + Vector2(14, 72), titulo, 15, COR_TEXTO)
	texto(r.position + Vector2(14, 92), subtitulo, 12, COR_TEXTO_SUAVE)


func desenhar_vazio(r: Rect2, titulo: String, subtitulo: String, cor: Color, selecionado: bool) -> void:
	var hover := r.has_point(mouse) and (estado == Estado.PREPARACAO or estado == Estado.ONDA)
	var borda := cor if selecionado else (COR_BORDA_HOVER if hover else COR_BORDA)
	caixa(r, Color(1, 1, 1, 0.02), 14, borda, 2 if selecionado else 1)
	var centro := r.get_center() + Vector2(0, -16)
	var cor_mais := cor if hover or selecionado else COR_TEXTO_SUAVE
	caixa(Rect2(centro - Vector2(9, 1.5), Vector2(18, 3)), cor_mais, 2)
	caixa(Rect2(centro - Vector2(1.5, 9), Vector2(3, 18)), cor_mais, 2)
	texto(Vector2(r.position.x, r.position.y + 76), titulo, 14, COR_TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	texto(Vector2(r.position.x, r.position.y + 94), subtitulo, 12, COR_TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func desenhar_internet() -> void:
	var sub := "%.1f req/s" % taxa_atual() if estado == Estado.ONDA and tempo_onda < config["duracao"] else "aguardando"
	desenhar_no(retangulo_no(Vector2(X_INTERNET, Y_LINHA), TAMANHO_NO), COR_DESTAQUE, "Internet", sub, "internet", false)


func desenhar_slot(indice: int) -> void:
	var r := retangulo_slot(indice)
	var slot: Dictionary = slots[indice]
	var selecionado := esta_selecionado("slot", indice)
	if slot.is_empty():
		desenhar_vazio(r, "Slot %d" % (indice + 1), "Adicionar", COR_DESTAQUE, selecionado)
		return
	var dados: Dictionary = TIPOS[slot["tipo"]]
	desenhar_no(r, dados["cor"], dados["nome"], descricao_nivel(slot["tipo"], slot["nivel"] - 1, true), slot["tipo"], selecionado, slot["pulso"], slot["nivel"])


func desenhar_lb() -> void:
	var r := retangulo_lb()
	var selecionado := esta_selecionado("lb")
	if not lb["instalado"]:
		desenhar_vazio(r, "Load Balancer", "Instalar", COR_LB, selecionado)
		return
	desenhar_no(r, COR_LB, "Load Balancer", nome_estrategia(), "lb", selecionado)


func desenhar_servidor(indice: int) -> void:
	var r := retangulo_servidor(indice)
	var servidor: Dictionary = servidores[indice]
	var caido: bool = servidor["caido"] > 0.0
	var proporcao: float = clampf(servidor["carga"] / CAPACIDADE, 0.0, 1.0)
	var selecionado := esta_selecionado("servidor", indice)
	var hover := r.has_point(mouse) and (estado == Estado.PREPARACAO or estado == Estado.ONDA)
	var borda := COR_BORDA_HOVER if hover else COR_BORDA
	if servidor["pulso"] > 0.0:
		borda = borda.lerp(COR_SERVIDOR, servidor["pulso"] * 0.6)
	if caido:
		borda = COR_PERIGO
	if selecionado:
		borda = COR_DESTAQUE
	caixa(r, Color("1f1216") if caido else COR_CARTAO, 12, borda, 2 if selecionado or caido else 1, 8)
	var cor_status := COR_PERIGO if caido else (COR_CREDITOS if proporcao > 0.75 else COR_HUMANO)
	draw_circle(r.position + Vector2(18, 20), 4.0, cor_status, true, -1.0, true)
	texto(r.position + Vector2(30, 25), "S%d" % (indice + 1), 15, COR_TEXTO)
	for k in NIVEL_MAXIMO:
		var cor_ponto := COR_SERVIDOR if k <= servidor["nivel"] else COR_BORDA
		draw_circle(Vector2(r.position.x + 60 + k * 9, r.position.y + 20), 3.0, cor_ponto, true, -1.0, true)
	if caido:
		texto(Vector2(r.position.x, r.position.y + 25), "CAIU  %ds" % ceili(servidor["caido"]), 13, COR_PERIGO, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 14)
	else:
		texto(Vector2(r.position.x, r.position.y + 25), "%d%%" % int(proporcao * 100), 13, COR_TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 14)
	var barra := Rect2(r.position + Vector2(14, 38), Vector2(r.size.x - 28, 7))
	caixa(barra, COR_LINHA, 4)
	if proporcao > 0.0 and not caido:
		caixa(Rect2(barra.position, Vector2(maxf(7.0, barra.size.x * proporcao), barra.size.y)), COR_HUMANO.lerp(COR_PERIGO, proporcao), 4)


func desenhar_novo_servidor() -> void:
	var r := retangulo_novo_servidor()
	var selecionado := esta_selecionado("novo_servidor")
	var hover := r.has_point(mouse) and (estado == Estado.PREPARACAO or estado == Estado.ONDA)
	var borda := COR_DESTAQUE if selecionado else (COR_BORDA_HOVER if hover else COR_BORDA)
	caixa(r, Color(1, 1, 1, 0.02), 12, borda, 2 if selecionado else 1)
	texto(Vector2(r.position.x, r.position.y + 25), "+ Servidor", 14, COR_TEXTO if hover or selecionado else COR_TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	texto(Vector2(r.position.x, r.position.y + 44), "%d créditos" % custo_servidor(), 12, COR_CREDITOS if creditos >= custo_servidor() else COR_TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func desenhar_topo() -> void:
	caixa(RETANGULO_TOPO, COR_CARTAO, 14, COR_BORDA, 1, 10)
	desenhar_icone("waf", Vector2(48, 39), COR_DESTAQUE)
	texto(Vector2(68, 45), "DDoS Defense", 17, COR_TEXTO)

	var fase := ""
	var progresso := -1.0
	if estado == Estado.ONDA or (estado == Estado.PAUSADO and estado_antes_pausa == Estado.ONDA) or estado == Estado.GAME_OVER:
		fase = "Onda %d  ·  %s  ·  %ds" % [onda, config["nome"], maxi(0, ceili(config["duracao"] - tempo_onda))]
		progresso = clampf(tempo_onda / config["duracao"], 0.0, 1.0)
	else:
		fase = "Preparação  ·  próxima: onda %d, %s" % [onda, config["nome"]]
	var largura := largura_texto(fase, 15) + 36
	var pilula := Rect2(640 - largura / 2, 22, largura, 34)
	caixa(pilula, COR_CARTAO_CLARO, 17)
	texto(Vector2(pilula.position.x, 45), fase, 15, COR_TEXTO, HORIZONTAL_ALIGNMENT_CENTER, pilula.size.x)
	if progresso >= 0.0:
		var trilho := Rect2(pilula.position.x + 18, 51, pilula.size.x - 36, 3)
		caixa(trilho, COR_LINHA, 2)
		caixa(Rect2(trilho.position, Vector2(trilho.size.x * progresso, 3)), COR_DESTAQUE, 2)

	texto(Vector2(780, 46), "%d créditos" % creditos, 18, COR_CREDITOS, HORIZONTAL_ALIGNMENT_RIGHT, 185)
	var cor_rep := COR_HUMANO if reputacao > 50 else (COR_CREDITOS if reputacao > 25 else COR_PERIGO)
	texto(Vector2(985, 36), "Reputação %d%%" % ceili(reputacao), 13, COR_TEXTO_SUAVE)
	var barra := Rect2(985, 43, 165, 7)
	caixa(barra, COR_LINHA, 4)
	caixa(Rect2(barra.position, Vector2(maxf(7.0, barra.size.x * reputacao / REPUTACAO_MAXIMA), 7)), cor_rep, 4)

	var hover_vel := RETANGULO_VELOCIDADE.has_point(mouse)
	caixa(RETANGULO_VELOCIDADE, COR_CARTAO_CLARO, 10, COR_BORDA_HOVER if hover_vel else TRANSPARENTE, 1)
	texto(Vector2(RETANGULO_VELOCIDADE.position.x, 45), "%dx" % int(velocidade_jogo), 14, COR_DESTAQUE if velocidade_jogo > 1.0 else COR_TEXTO, HORIZONTAL_ALIGNMENT_CENTER, RETANGULO_VELOCIDADE.size.x)
	var hover_pausa := RETANGULO_PAUSA.has_point(mouse)
	caixa(RETANGULO_PAUSA, COR_CARTAO_CLARO, 10, COR_BORDA_HOVER if hover_pausa else TRANSPARENTE, 1)
	var c := RETANGULO_PAUSA.get_center()
	caixa(Rect2(c + Vector2(-7, -8), Vector2(5, 16)), COR_TEXTO, 2)
	caixa(Rect2(c + Vector2(2, -8), Vector2(5, 16)), COR_TEXTO, 2)


func desenhar_painel() -> void:
	caixa(RETANGULO_PAINEL, COR_CARTAO, 16, COR_BORDA, 1, 12)
	draw_line(Vector2(950, 546), Vector2(950, 690), COR_BORDA, 1.0)
	texto(Vector2(40, 562), titulo_painel(), 16, COR_TEXTO)

	if selecao.is_empty():
		var dicas := recomendacoes()
		for k in dicas.size():
			var y := 578.0 + k * 40.0
			var cor_dica := COR_DESTAQUE if k == 0 else COR_TEXTO_SUAVE
			caixa(Rect2(40, y, 892, 34), COR_CARTAO_CLARO, 10)
			draw_circle(Vector2(58, y + 17), 4.0, cor_dica, true, -1.0, true)
			var uma_linha := largura_texto(dicas[k], 13) <= 850.0
			draw_multiline_string(fonte, Vector2(72, y + (22.0 if uma_linha else 14.0)), dicas[k], HORIZONTAL_ALIGNMENT_LEFT, 850, 13, 2, COR_TEXTO)

	for b in botoes_painel():
		desenhar_botao(b)

	if estado == Estado.ONDA or (estado == Estado.PAUSADO and estado_antes_pausa == Estado.ONDA):
		var e := estatisticas
		var linhas := [
			["Tráfego agora", "%.1f req/s" % taxa_atual(), COR_TEXTO],
			["Bots na onda", "%d%%" % roundi(config["bots"] * 100), COR_BOT],
			["Humanos atendidos", "%d" % e["humanos_servidos"], COR_HUMANO],
			["Bots bloqueados", "%d" % e["bots_bloqueados"], COR_DESTAQUE],
			["Bots nos servidores", "%d" % e["bots_servidor"], COR_BOT],
			["Humanos perdidos", "%d" % (e["humanos_barrados"] + e["humanos_perdidos_queda"]), COR_CREDITOS],
		]
		for k in linhas.size():
			var y := 566.0 + k * 22.0
			texto(Vector2(968, y), linhas[k][0], 13, COR_TEXTO_SUAVE)
			texto(Vector2(968, y), linhas[k][1], 14, linhas[k][2], HORIZONTAL_ALIGNMENT_RIGHT, 272)
	elif estado == Estado.PREPARACAO or (estado == Estado.PAUSADO and estado_antes_pausa == Estado.PREPARACAO):
		var proxima := [
			["Requisições", "%d/s" % roundi(config["taxa"]), COR_TEXTO],
			["Bots", "%d%%" % roundi(config["bots"] * 100), COR_BOT],
			["Bots evasivos", "%d%%" % roundi(sofisticacao() * 100), COR_CREDITOS],
		]
		for k in proxima.size():
			var y := 634.0 + k * 22.0
			texto(Vector2(968, y), proxima[k][0], 13, COR_TEXTO_SUAVE)
			texto(Vector2(968, y), proxima[k][1], 14, proxima[k][2], HORIZONTAL_ALIGNMENT_RIGHT, 272)


func desenhar_botao(b: Dictionary) -> void:
	var r: Rect2 = b["rect"]
	var ativo: bool = b["ativo"]
	var cor: Color = b["cor"]
	var hover := r.has_point(mouse) and ativo and (estado == Estado.PREPARACAO or estado == Estado.ONDA)
	if b.get("principal", false):
		caixa(r, cor.lightened(0.1) if hover else cor, 14, TRANSPARENTE, 0, 10)
		texto(Vector2(r.position.x, r.position.y + 32), b["titulo"], 20, Color("04261a"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		texto(Vector2(r.position.x, r.position.y + 51), b["linhas"][0], 12, Color("064e3b"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		return
	var borda := cor if hover else COR_BORDA
	caixa(r, COR_CARTAO_CLARO if ativo else COR_CARTAO, 12, borda, 1)
	var x := r.position.x + 14
	var icone: String = b["icone"]
	if icone != "":
		var badge := Rect2(r.position + Vector2(12, 12), Vector2(30, 30))
		var fundo_badge := cor
		fundo_badge.a = 0.14 if ativo else 0.06
		caixa(badge, fundo_badge, 8)
		desenhar_icone(icone, badge.get_center(), cor if ativo else COR_TEXTO_SUAVE, 0.8)
		x = r.position.x + 52
	var cor_titulo := COR_TEXTO if ativo else COR_TEXTO_SUAVE
	texto(Vector2(x, r.position.y + 32), b["titulo"], 15, cor_titulo)
	var linhas: Array = b["linhas"]
	for k in linhas.size():
		texto(Vector2(r.position.x + 14, r.position.y + 62 + k * 17), linhas[k], 12, COR_TEXTO_SUAVE)
	texto(Vector2(r.position.x + 14, r.position.y + r.size.y - 12), b["rodape"], 13, COR_CREDITOS if ativo else COR_TEXTO_SUAVE)


func desenhar_avisos() -> void:
	for k in avisos.size():
		var aviso: Dictionary = avisos[k]
		var alfa := clampf(aviso["tempo"] / 0.4, 0.0, 1.0)
		var largura := largura_texto(aviso["texto"], 14) + 40
		var r := Rect2(640 - largura / 2, 78 + k * 42, largura, 34)
		var fundo := COR_CARTAO_CLARO
		fundo.a = alfa
		var borda: Color = aviso["cor"]
		borda.a = alfa
		caixa(r, fundo, 17, borda, 1, 8)
		var cor_texto := COR_TEXTO
		cor_texto.a = alfa
		texto(Vector2(r.position.x, r.position.y + 22), aviso["texto"], 14, cor_texto, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func desenhar_janela(titulo: String, cor_titulo: Color, linhas: Array) -> void:
	draw_rect(Rect2(0, 0, 1280, 720), COR_SOBREPOSICAO)
	var altura := 120.0
	for linha in linhas:
		altura += linha[1] + 18.0
	var r := Rect2(640 - 380, 360 - altura / 2, 760, altura)
	caixa(r, COR_CARTAO, 22, COR_BORDA, 1, 24)
	var y := r.position.y + 70.0
	texto(Vector2(r.position.x, y), titulo, 44, cor_titulo, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	y += 46.0
	for linha in linhas:
		y += linha[1] + 18.0
		texto(Vector2(r.position.x + 30, y - 10), linha[0], linha[1], linha[2], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 60)


func desenhar_icone(tipo: String, c: Vector2, cor: Color, s := 1.0) -> void:
	match tipo:
		"internet":
			draw_arc(c, 10 * s, 0.0, TAU, 32, cor, 2.0, true)
			draw_line(c + Vector2(-10, 0) * s, c + Vector2(10, 0) * s, cor, 1.5, true)
			var elipse := PackedVector2Array()
			for k in 25:
				var a := TAU * k / 24.0
				elipse.append(c + Vector2(cos(a) * 4.5, sin(a) * 10) * s)
			draw_polyline(elipse, cor, 1.5, true)
		"cdn":
			draw_circle(c + Vector2(-5, 2) * s, 5 * s, cor, true, -1.0, true)
			draw_circle(c + Vector2(2, -2) * s, 6.5 * s, cor, true, -1.0, true)
			draw_circle(c + Vector2(8, 3) * s, 4 * s, cor, true, -1.0, true)
			draw_rect(Rect2(c + Vector2(-5, 2) * s, Vector2(13, 5) * s), cor)
		"waf":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -11) * s, c + Vector2(9, -7) * s, c + Vector2(8, 3) * s,
				c + Vector2(0, 11) * s, c + Vector2(-8, 3) * s, c + Vector2(-9, -7) * s]), cor)
		"captcha":
			draw_rect(Rect2(c - Vector2(9, 9) * s, Vector2(18, 18) * s), cor, false, 2.0)
			draw_polyline(PackedVector2Array([c + Vector2(-5, 0) * s, c + Vector2(-1, 4) * s, c + Vector2(6, -5) * s]), cor, 2.5, true)
		"rate":
			draw_arc(c + Vector2(0, 4) * s, 10 * s, PI, TAU, 20, cor, 2.0, true)
			draw_line(c + Vector2(0, 4) * s, c + Vector2(6, -4) * s, cor, 2.0, true)
			draw_circle(c + Vector2(0, 4) * s, 2.5 * s, cor, true, -1.0, true)
		"lb":
			var origem := c + Vector2(-8, 0) * s
			for dy in [-8, 0, 8]:
				var destino := c + Vector2(8, dy) * s
				draw_line(origem, destino, cor, 2.0, true)
				draw_circle(destino, 2.5 * s, cor, true, -1.0, true)
			draw_circle(origem, 3.5 * s, cor, true, -1.0, true)
		"servidor":
			for dy in [-6, 5]:
				draw_rect(Rect2(c + Vector2(-9, dy - 4) * s, Vector2(18, 8) * s), cor, false, 1.5)
				draw_circle(c + Vector2(5, dy) * s, 1.5 * s, cor, true, -1.0, true)
