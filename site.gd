extends RefCounted

const Dados := preload("res://dados.gd")

const COLUNAS := 12
const LINHAS := 4
const CELULA := Vector2(102, 96)
const ORIGEM_GRADE := Vector2(28, 118)
const TAMANHO_NO := Vector2(86, 80)
const VELOCIDADE := 200.0
const MAX_SALTOS := 30
const CAPACIDADE := 100.0
const TEMPO_QUEDA := 5.0
const PACIENCIA := 6.0
const CUSTO_NUVEM := 4.0
const LIMITE_BLOQUEIO := 0.97
const MAX_EFEITOS := 160
const PERDA_HUMANO := 0.5
const PERDA_FALSO := 0.2
const PERDA_VAZAMENTO := 0.8
const MULTA_VAZAMENTO := 18.0
const PREJUIZO_SCRAPER := 3.0
const INTERVALO_TEXTO := 1.5

var nome := ""
var foco := ""
var multiplicador := 1.0
var nos: Dictionary = {}
var proximo_id := 1
var id_internet := 0
var pacotes: Array = []
var efeitos: Array = []
var eventos: Array = []
var estatisticas: Dictionary = {}
var ocorrencias: Dictionary = {}
var gerando := false
var tempo := 0.0
var acumulador := 0.0
var taxa_base := 0.0
var mix: Dictionary = {"humano": 1.0}
var sofisticacao := 0.0
var peso := 1.0
var receita_humano := 8.0
var custo_queda := 60.0
var falso_geo := 1.0
var receita := 0.0
var prejuizo := 0.0
var reputacao_perdida := 0.0


func _init(nome_site := "Site", foco_site := "", mult := 1.0) -> void:
	nome = nome_site
	foco = foco_site
	multiplicador = mult
	id_internet = adicionar_no("internet", Vector2i(0, 1))
	var torre := adicionar_no("servidor", Vector2i(4, 1))
	conectar(id_internet, torre)
	zerar_estatisticas()


func zerar_estatisticas() -> void:
	estatisticas = {
		"humanos": 0, "servidos": 0, "cache": 0, "perdidos": {}, "bots": {}, "bloqueados": {},
		"chegaram": {}, "bloqueio_por_componente": {}, "falsos_por_componente": {}, "quedas": 0,
		"vazamentos": 0, "receita": 0.0, "prejuizo_queda": 0.0, "custo_nuvem": 0.0, "multas": 0.0,
		"segundos_caido": 0.0, "tempo": 0.0, "enviados_caido": 0,
	}


func somar(chave: String, sub: String, valor := 1) -> void:
	var dic: Dictionary = estatisticas[chave]
	dic[sub] = dic.get(sub, 0) + valor


func total(chave: String) -> int:
	var soma := 0
	for v in estatisticas[chave].values():
		soma += v
	return soma


func celula_valida(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < COLUNAS and c.y >= 0 and c.y < LINHAS


func no_na_celula(c: Vector2i) -> int:
	for id in nos:
		if nos[id]["celula"] == c:
			return id
	return -1


func celula_em(pos: Vector2) -> Vector2i:
	var relativa := (pos - ORIGEM_GRADE) / CELULA
	return Vector2i(floori(relativa.x), floori(relativa.y))


func centro_celula(c: Vector2i) -> Vector2:
	return ORIGEM_GRADE + (Vector2(c) + Vector2(0.5, 0.5)) * CELULA


func centro_no(id: int) -> Vector2:
	return centro_celula(nos[id]["celula"])


func retangulo_no(id: int) -> Rect2:
	return Rect2(centro_no(id) - TAMANHO_NO / 2, TAMANHO_NO)


func porta_saida(id: int) -> Vector2:
	return centro_no(id) + Vector2(TAMANHO_NO.x / 2, 0)


func porta_entrada(id: int) -> Vector2:
	return centro_no(id) - Vector2(TAMANHO_NO.x / 2, 0)


func no_em(pos: Vector2) -> int:
	for id in nos:
		if retangulo_no(id).grow(4).has_point(pos):
			return id
	return -1


func eh_terminal(id: int) -> bool:
	return nos.has(id) and nos[id]["tipo"] in Dados.TERMINAIS


func tem_saida(id: int) -> bool:
	return nos.has(id) and not eh_terminal(id)


func terminais() -> Array:
	var lista: Array = []
	for id in nos:
		if eh_terminal(id):
			lista.append(id)
	return lista


func ids_do_tipo(tipo: String) -> Array:
	var lista: Array = []
	for id in nos:
		if nos[id]["tipo"] == tipo:
			lista.append(id)
	return lista


func adicionar_no(tipo: String, celula: Vector2i) -> int:
	if not celula_valida(celula) or no_na_celula(celula) >= 0:
		return -1
	var id := proximo_id
	proximo_id += 1
	nos[id] = {
		"id": id, "tipo": tipo, "nivel": 1, "celula": celula, "saidas": [], "rr": 0,
		"carga": 0.0, "caido": 0.0, "escala": 1.0, "fila": [], "liberacao": 0.0,
		"contagem": 0, "pulso": 0.0, "investido": 0.0, "texto_valor": 0.0, "texto_tempo": 0.0,
	}
	return id


func remover_no(id: int) -> bool:
	if id == id_internet or not nos.has(id):
		return false
	for p in nos[id]["fila"]:
		p["pos"] = centro_no(id)
		perder(p, "sem_saida", {})
	nos.erase(id)
	for outro in nos:
		nos[outro]["saidas"].erase(id)
	for p in pacotes:
		if p["destino"] == id or p["origem"] == id:
			perder(p, "sem_saida", {})
	pacotes = pacotes.filter(func(p): return not p["remover"])
	return true


func mover_no(id: int, celula: Vector2i) -> bool:
	if not nos.has(id) or not celula_valida(celula):
		return false
	var ocupante := no_na_celula(celula)
	if ocupante >= 0 and ocupante != id:
		return false
	nos[id]["celula"] = celula
	for p in pacotes:
		if p["destino"] >= 0 and nos.has(p["origem"]) and nos.has(p["destino"]):
			p["comprimento"] = comprimento_aresta(p["origem"], p["destino"])
	return true


func alcanca(origem: int, alvo: int) -> bool:
	var visitados: Dictionary = {}
	var pilha: Array = [origem]
	while not pilha.is_empty():
		var atual: int = pilha.pop_back()
		if atual == alvo:
			return true
		if visitados.has(atual) or not nos.has(atual):
			continue
		visitados[atual] = true
		for s in nos[atual]["saidas"]:
			pilha.append(s)
	return false


func pode_conectar(a: int, b: int) -> String:
	if not nos.has(a) or not nos.has(b):
		return "Componente inválido"
	if a == b:
		return "Não dá para ligar um componente nele mesmo"
	if eh_terminal(a):
		return "Torres são o destino final: elas não têm saída"
	if nos[b]["tipo"] == "internet":
		return "A Internet é a origem do tráfego, não um destino"
	if b in nos[a]["saidas"]:
		return "Esses componentes já estão ligados"
	if alcanca(b, a):
		return "Essa ligação criaria um ciclo e o tráfego ficaria rodando em círculo"
	return ""


func conectar(a: int, b: int) -> String:
	var erro := pode_conectar(a, b)
	if erro == "":
		nos[a]["saidas"].append(b)
	return erro


func desconectar(a: int, b: int) -> void:
	if nos.has(a):
		nos[a]["saidas"].erase(b)


func pontos_aresta(a: int, b: int) -> Array:
	var inicio := porta_saida(a)
	var fim := porta_entrada(b)
	var curva := clampf(absf(fim.x - inicio.x) * 0.5, 40.0, 120.0)
	return [inicio, inicio + Vector2(curva, 0), fim - Vector2(curva, 0), fim]


func ponto_aresta(a: int, b: int, t: float) -> Vector2:
	var p := pontos_aresta(a, b)
	var u := 1.0 - t
	return u * u * u * p[0] + 3.0 * u * u * t * p[1] + 3.0 * u * t * t * p[2] + t * t * t * p[3]


func comprimento_aresta(a: int, b: int) -> float:
	var total_c := 0.0
	var anterior := ponto_aresta(a, b, 0.0)
	for k in range(1, 9):
		var atual := ponto_aresta(a, b, k / 8.0)
		total_c += anterior.distance_to(atual)
		anterior = atual
	return maxf(1.0, total_c)


func aresta_em(pos: Vector2, tolerancia := 8.0) -> Array:
	for a in nos:
		for b in nos[a]["saidas"]:
			var anterior := ponto_aresta(a, b, 0.0)
			for k in range(1, 17):
				var atual := ponto_aresta(a, b, k / 16.0)
				if Geometry2D.get_closest_point_to_segment(pos, anterior, atual).distance_to(pos) <= tolerancia:
					return [a, b]
				anterior = atual
	return []


func configurar_dia(taxa: float, mix_dia: Dictionary, sof: float, peso_dia: float, receita_h: float, custo_q: float, geo: float) -> void:
	taxa_base = taxa
	mix = mix_dia
	sofisticacao = sof
	peso = peso_dia
	receita_humano = receita_h
	custo_queda = custo_q
	falso_geo = geo
	tempo = 0.0
	acumulador = 0.0
	gerando = true
	zerar_estatisticas()


func taxa_atual() -> float:
	if not gerando:
		return 0.0
	return taxa_base * multiplicador * (1.0 + 0.3 * sin(tempo * 1.1))


func vazio() -> bool:
	if gerando or not pacotes.is_empty():
		return false
	for id in nos:
		if not nos[id]["fila"].is_empty():
			return false
	return true


func atualizar(dt: float) -> void:
	tempo += dt
	if gerando:
		estatisticas["tempo"] += dt
		acumulador += dt * taxa_atual()
		while acumulador >= 1.0:
			acumulador -= 1.0
			gerar_pacote()
	for p in pacotes:
		mover_pacote(p, dt)
	pacotes = pacotes.filter(func(p): return not p["remover"])
	for id in nos.keys():
		if nos.has(id):
			atualizar_no(nos[id], dt)
	for e in efeitos:
		e["tempo"] += dt
	efeitos = efeitos.filter(func(e): return e["tempo"] < e["duracao"])


func sortear_tipo() -> String:
	var soma := 0.0
	for v in mix.values():
		soma += v
	var sorteio := randf() * soma
	for tipo in mix:
		sorteio -= mix[tipo]
		if sorteio <= 0.0:
			return tipo
	return "humano"


func gerar_pacote() -> void:
	var tipo := sortear_tipo()
	if tipo == "humano":
		estatisticas["humanos"] += 1
	else:
		somar("bots", tipo)
	var p := {"tipo": tipo, "pos": porta_saida(id_internet), "origem": id_internet, "destino": -1, "t": 0.0, "comprimento": 1.0, "saltos": 0, "remover": false, "espera": 0.0}
	pacotes.append(p)
	encaminhar(p, nos[id_internet])


func encaminhar(p: Dictionary, no: Dictionary) -> void:
	var saidas: Array = no["saidas"]
	if saidas.is_empty() or p["saltos"] >= MAX_SALTOS:
		perder(p, "sem_saida", no)
		return
	var destino := escolher_saida(no)
	p["origem"] = no["id"]
	p["destino"] = destino
	p["t"] = 0.0
	p["comprimento"] = comprimento_aresta(no["id"], destino)
	p["saltos"] += 1


func ocupacao(id: int, profundidade := 0) -> float:
	if not nos.has(id):
		return 1.0
	var no: Dictionary = nos[id]
	if eh_terminal(id):
		return 2.0 if no["caido"] > 0.0 else no["carga"] / CAPACIDADE
	if profundidade > 4 or no["saidas"].is_empty():
		return 0.5
	var soma := 0.0
	for s in no["saidas"]:
		soma += ocupacao(s, profundidade + 1)
	return soma / no["saidas"].size()


func esta_caido(id: int) -> bool:
	return eh_terminal(id) and nos[id]["caido"] > 0.0


func escolher_saida(no: Dictionary) -> int:
	var saidas: Array = no["saidas"]
	if no["tipo"] == "lb":
		var candidatos: Array = []
		for s in saidas:
			if no["nivel"] < 2 or not esta_caido(s):
				candidatos.append(s)
		if candidatos.is_empty():
			candidatos = saidas.duplicate()
		if no["nivel"] >= 3:
			var melhor: int = candidatos[0]
			for s in candidatos:
				if ocupacao(s) < ocupacao(melhor):
					melhor = s
			return melhor
		var escolhido_lb: int = candidatos[no["rr"] % candidatos.size()]
		no["rr"] += 1
		return escolhido_lb
	var escolhido: int = saidas[no["rr"] % saidas.size()]
	no["rr"] += 1
	return escolhido


func mover_pacote(p: Dictionary, dt: float) -> void:
	if p["remover"]:
		return
	if not nos.has(p["destino"]) or not nos.has(p["origem"]):
		perder(p, "sem_saida", {})
		return
	p["t"] = minf(1.0, p["t"] + dt * VELOCIDADE / p["comprimento"])
	p["pos"] = ponto_aresta(p["origem"], p["destino"], p["t"])
	if p["t"] >= 1.0:
		chegar(p, nos[p["destino"]])


func chegar(p: Dictionary, no: Dictionary) -> void:
	no["pulso"] = 1.0
	var tipo_no: String = no["tipo"]
	if tipo_no in Dados.TERMINAIS:
		consumir(p, no)
		return
	if tipo_no == "fila":
		var fila: Array = no["fila"]
		if fila.size() >= capacidade_fila(no):
			perder(p, "fila_cheia", no)
			return
		p["espera"] = 0.0
		p["destino"] = -1
		p["remover"] = true
		fila.append(p)
		return
	if tipo_no != "lb" and processar_filtro(p, no):
		return
	encaminhar(p, no)


func processar_filtro(p: Dictionary, no: Dictionary) -> bool:
	var dados: Dictionary = Dados.COMPONENTES[no["tipo"]]
	var nivel: int = no["nivel"] - 1
	var tipo: String = p["tipo"]
	if tipo == "humano":
		if dados.has("cache") and randf() < dados["cache"][nivel]:
			servir(p, no, true)
			return true
		var falso: float = dados.get("falso", 0.0) * Dados.FALSO_NIVEL[nivel]
		if no["tipo"] == "geo":
			falso *= falso_geo
		if falso > 0.0 and randf() < falso:
			var falsos: Dictionary = estatisticas["falsos_por_componente"]
			falsos[no["tipo"]] = falsos.get(no["tipo"], 0) + 1
			perder(p, "falso_positivo", no)
			return true
		return false
	var bloqueios: Dictionary = dados.get("bloqueio", {})
	var base: float = bloqueios.get(tipo, 0.0)
	if base <= 0.0:
		return false
	var chance := minf(LIMITE_BLOQUEIO, base * Dados.MULT_NIVEL[nivel]) * (1.0 - sofisticacao)
	if randf() < chance:
		bloquear(p, no)
		return true
	return false


func adicionar_efeito(efeito: Dictionary) -> void:
	efeito["tempo"] = 0.0
	efeito["semente"] = randf() * TAU
	efeitos.append(efeito)
	if efeitos.size() > MAX_EFEITOS:
		efeitos.pop_front()


func bloquear(p: Dictionary, no: Dictionary) -> void:
	p["remover"] = true
	somar("bloqueados", p["tipo"])
	somar("bloqueio_por_componente", no["tipo"])
	no["contagem"] += 1
	var cor: Color = Dados.COMPONENTES[no["tipo"]]["cor"]
	var cor_bot: Color = Dados.TIPOS_REQ[p["tipo"]]["cor"]
	match no["tipo"]:
		"captcha":
			adicionar_efeito({"tipo": "captcha", "pos": p["pos"], "alvo": centro_no(no["id"]) + Vector2(0, -TAMANHO_NO.y / 2), "cor": cor, "cor_bot": cor_bot, "duracao": 0.9})
		"antiddos", "cdn":
			adicionar_efeito({"tipo": "absorver", "pos": p["pos"], "cor": cor, "duracao": 0.45})
		_:
			adicionar_efeito({"tipo": "bloqueio", "pos": p["pos"], "cor": cor, "cor_bot": cor_bot, "duracao": 0.55})


func servir(p: Dictionary, no: Dictionary, cache: bool) -> void:
	p["remover"] = true
	estatisticas["servidos"] += 1
	estatisticas["receita"] += receita_humano
	receita += receita_humano
	if cache:
		estatisticas["cache"] += 1
		no["contagem"] += 1
		adicionar_efeito({"tipo": "cache", "pos": p["pos"], "cor": Dados.COMPONENTES[no["tipo"]]["cor"], "duracao": 0.6})
	no["texto_valor"] += receita_humano


func perder(p: Dictionary, motivo: String, no: Dictionary) -> void:
	if p["remover"] and p["destino"] >= 0:
		return
	p["remover"] = true
	if p["tipo"] != "humano":
		return
	somar("perdidos", motivo)
	reputacao_perdida += PERDA_FALSO if motivo == "falso_positivo" else PERDA_HUMANO
	adicionar_efeito({"tipo": "perdido", "pos": p["pos"], "cor": Color("fbbf24"), "duracao": 0.6})
	registrar_ocorrencia(motivo, no.get("id", -1))


func registrar_ocorrencia(motivo: String, id := -1) -> void:
	if ocorrencias.has(motivo):
		return
	ocorrencias[motivo] = true
	eventos.append({"tipo": "primeira", "motivo": motivo, "no": id})


func consumir(p: Dictionary, no: Dictionary) -> void:
	if no["caido"] > 0.0:
		estatisticas["enviados_caido"] += 1
		p["pos"] = centro_no(no["id"])
		perder(p, "caido", no)
		return
	var dados_req: Dictionary = Dados.TIPOS_REQ[p["tipo"]]
	no["carga"] += dados_req["carga"] * peso
	if p["tipo"] == "humano":
		servir(p, no, false)
		return
	p["remover"] = true
	somar("chegaram", p["tipo"])
	if p["tipo"] == "credencial":
		var multa := MULTA_VAZAMENTO * peso
		estatisticas["vazamentos"] += 1
		estatisticas["multas"] += multa
		prejuizo += multa
		reputacao_perdida += PERDA_VAZAMENTO
		adicionar_efeito({"tipo": "vazamento", "pos": centro_no(no["id"]) + Vector2(0, -30), "cor": Color("e879f9"), "duracao": 1.2})
		registrar_ocorrencia("vazamento", no["id"])
	elif p["tipo"] == "scraper":
		prejuizo += PREJUIZO_SCRAPER
		estatisticas["multas"] += PREJUIZO_SCRAPER


func capacidade_fila(no: Dictionary) -> int:
	return Dados.COMPONENTES["fila"]["capacidade"][no["nivel"] - 1]


func vazao_fila(no: Dictionary) -> float:
	return Dados.COMPONENTES["fila"]["vazao"][no["nivel"] - 1]


func processamento(no: Dictionary) -> float:
	return Dados.COMPONENTES[no["tipo"]]["processamento"][no["nivel"] - 1] * no["escala"]


func atualizar_no(no: Dictionary, dt: float) -> void:
	no["pulso"] = maxf(0.0, no["pulso"] - dt * 3.0)
	if no["tipo"] in Dados.TERMINAIS:
		atualizar_torre(no, dt)
	elif no["tipo"] == "fila":
		atualizar_fila(no, dt)
	elif no["tipo"] == "cdn" or no["tipo"] == "redis":
		texto_dinheiro(no, dt)


func texto_dinheiro(no: Dictionary, dt: float) -> void:
	no["texto_tempo"] += dt
	if no["texto_tempo"] < INTERVALO_TEXTO:
		return
	no["texto_tempo"] = 0.0
	var valor: float = no["texto_valor"]
	no["texto_valor"] = 0.0
	if absf(valor) < 0.5:
		return
	adicionar_efeito({"tipo": "dinheiro", "pos": centro_no(no["id"]) + Vector2(0, -TAMANHO_NO.y / 2 - 6), "valor": valor, "duracao": 1.3})


func atualizar_torre(no: Dictionary, dt: float) -> void:
	texto_dinheiro(no, dt)
	if no["caido"] > 0.0:
		no["caido"] = maxf(0.0, no["caido"] - dt)
		var custo := custo_queda * dt / maxf(1.0, terminais().size())
		prejuizo += custo
		no["texto_valor"] -= custo
		if gerando:
			estatisticas["segundos_caido"] += dt
			estatisticas["prejuizo_queda"] += custo
		return
	no["carga"] = maxf(0.0, no["carga"] - processamento(no) * dt)
	if no["tipo"] == "autoscale":
		var ocup: float = no["carga"] / CAPACIDADE
		var maxima: float = Dados.COMPONENTES["autoscale"]["escala_maxima"]
		if ocup > 0.5:
			no["escala"] = minf(maxima, no["escala"] + dt * 0.6)
		elif ocup < 0.2:
			no["escala"] = maxf(1.0, no["escala"] - dt * 0.25)
		var custo_nuvem: float = (no["escala"] - 1.0) * CUSTO_NUVEM * dt
		prejuizo += custo_nuvem
		estatisticas["custo_nuvem"] += custo_nuvem
	if no["carga"] >= CAPACIDADE:
		no["carga"] = 0.0
		no["caido"] = TEMPO_QUEDA
		estatisticas["quedas"] += 1
		adicionar_efeito({"tipo": "queda", "pos": centro_no(no["id"]), "cor": Color("ef4444"), "duracao": 1.4})
		eventos.append({"tipo": "queda", "no": no["id"]})
		registrar_ocorrencia("queda", no["id"])


func saidas_sobrecarregadas(no: Dictionary) -> bool:
	var saidas: Array = no["saidas"]
	if saidas.is_empty():
		return false
	for s in saidas:
		if not eh_terminal(s):
			return false
		if not esta_caido(s) and nos[s]["carga"] / CAPACIDADE < 0.85:
			return false
	return true


func atualizar_fila(no: Dictionary, dt: float) -> void:
	var fila: Array = no["fila"]
	if fila.is_empty():
		no["liberacao"] = 0.0
		return
	var restantes: Array = []
	for p in fila:
		p["espera"] += dt
		if p["tipo"] == "humano" and p["espera"] > PACIENCIA:
			p["pos"] = centro_no(no["id"])
			p["destino"] = -1
			p["remover"] = false
			perder(p, "paciencia", no)
		else:
			restantes.append(p)
	no["fila"] = restantes
	if restantes.is_empty() or saidas_sobrecarregadas(no):
		return
	no["liberacao"] = minf(1.0 + vazao_fila(no) * dt, no["liberacao"] + vazao_fila(no) * dt)
	while no["liberacao"] >= 1.0 and not no["fila"].is_empty():
		no["liberacao"] -= 1.0
		var p: Dictionary = no["fila"].pop_front()
		p["remover"] = false
		p["pos"] = porta_saida(no["id"])
		pacotes.append(p)
		encaminhar(p, no)
