extends RefCounted

const Dados := preload("res://dados.gd")
const Textos := preload("res://textos.gd")

signal notificacao(texto: String, cor: Color, licao: String)
signal subiu_nivel(nivel: int)

const ARQUIVO := "user://ddos_defense_save.json"
const ARQUIVO_V3 := "user://perfil.cfg"
const BONUS_VETERANO := 150.0
const BONUS_VETERANO_MAXIMO := 1500.0
const VERSAO := 4
const PREFIXO_CODIGO := "DDOS4:"
const COR_OK := Color("34d399")
const COR_INFO := Color("38bdf8")
const COR_OURO := Color("fbbf24")
const RECOMPENSA_SEQUENCIA := 100.0
const MAX_RECOMPENSA_SEQUENCIA := 700.0
const XP_LICAO := 15
const XP_DIA_BASE := 15
const XP_DIA_EXTRA := 4
const PREMIO_CTF := 250.0
const XP_DESAFIO := 100
const DINHEIRO_DESAFIO := 250.0
const DESAFIOS_POR_NIVEL_CODIGO := 3
const MAX_CODIGO_SEGURO := 5

static var atual

var perfis: Dictionary = {}
var id_ativo := ""
var perfil: Dictionary = {}


func _init() -> void:
	atual = self


func padrao(nome: String) -> Dictionary:
	return {
		"nome": nome, "pin": "", "sal": "", "aceitou": true, "criado": Time.get_date_string_from_system(),
		"avatar": {"corpo": 0, "pele": 1, "cabelo": 0, "cor_cabelo": 0, "roupa": 0, "cor_roupa": 0, "olhos": 0},
		"dinheiro": Dados.DINHEIRO_INICIAL, "xp": 0, "contadores": {},
		"empresas": {}, "startup": {}, "itens": [], "equipados": {"acessorio": "", "chapeu": "", "roupa": "", "pet": ""},
		"reforcos": {}, "missoes_resgatadas": [], "licoes": [], "licoes_lidas": [], "desafios": [],
		"sequencia": {"ultimo": "", "dias": 0, "melhor": 0},
		"diarias": {"data": "", "contadores": {}, "resgatadas": []},
		"mundo": [21.5, 21.2], "operacoes": {}, "quiz_usados": [],
		"terrenos": {}, "pentests": {"data": "", "feitos": []}, "ctf": {"data": "", "feito": false}, "graficos_leves": OS.has_feature("web") or OS.has_feature("mobile"),
		"carreira": "operador", "carreiras": {"operador": 0, "hacker": 0, "empreendedor": 0}, "cursos_cafe": [],
		"auditorias": {"concluidas": [], "tentativas": {"data": "", "propostas": {}}},
	}


func normalizar(p: Dictionary) -> Dictionary:
	var base := padrao(String(p.get("nome", "Jogador")))
	for chave in base:
		if not p.has(chave):
			p[chave] = base[chave]
	for chave in base["avatar"]:
		p["avatar"][chave] = int(p["avatar"].get(chave, base["avatar"][chave]))
	for chave in base["equipados"]:
		if not p["equipados"].has(chave):
			p["equipados"][chave] = ""
	if not Dados.CARREIRAS.has(p["carreira"]):
		p["carreira"] = "operador"
	for chave in Dados.CARREIRAS:
		p["carreiras"][chave] = maxi(0, int(p["carreiras"].get(chave, 0)))
	for chave in base["auditorias"]:
		if not p["auditorias"].has(chave):
			p["auditorias"][chave] = base["auditorias"][chave]
	for chave in base["auditorias"]["tentativas"]:
		if not p["auditorias"]["tentativas"].has(chave):
			p["auditorias"]["tentativas"][chave] = base["auditorias"]["tentativas"][chave]
	p["xp"] = int(p["xp"])
	p["dinheiro"] = float(p["dinheiro"])
	if not p["startup"].is_empty() and String(p["startup"].get("lote", "")) == "":
		p["startup"]["lote"] = "lote_centro"
		p["terrenos"]["lote_centro"] = "startup"
	if not p["startup"].is_empty() and p["startup"].has("logo"):
		var logo: Dictionary = p["startup"]["logo"]
		for chave in ["cor", "cor2"]:
			logo[chave] = int(logo.get(chave, 0))
	return p


func carregar() -> void:
	perfis = {}
	if not FileAccess.file_exists(ARQUIVO):
		migrar_v3()
		return
	var arquivo := FileAccess.open(ARQUIVO, FileAccess.READ)
	if arquivo == null:
		return
	var dados = JSON.parse_string(arquivo.get_as_text())
	if typeof(dados) != TYPE_DICTIONARY or not dados.has("perfis"):
		return
	for id in dados["perfis"]:
		perfis[id] = normalizar(dados["perfis"][id])


func migrar_v3() -> void:
	if not FileAccess.file_exists(ARQUIVO_V3):
		return
	var antigo := ConfigFile.new()
	if antigo.load(ARQUIVO_V3) != OK:
		return
	var nome := String(antigo.get_value("perfil", "nome", "")).strip_edges()
	if nome == "":
		return
	var novo := padrao(nome.substr(0, 16))
	novo["sal"] = "%d-%d" % [randi(), int(Time.get_unix_time_from_system())]
	novo["avatar"]["cor_roupa"] = int(antigo.get_value("perfil", "cor", 0)) % Dados.CORES_ROUPA.size()
	var recordes = antigo.get_value("progresso", "recordes", {})
	var melhor := 0
	if typeof(recordes) == TYPE_DICTIONARY:
		for id in recordes:
			if not Dados.empresa_por_id(String(id)).is_empty():
				var dia := int(recordes[id])
				novo["empresas"][String(id)] = {"dono": false, "recorde": dia, "temporadas": 1, "lucro": 0.0}
				melhor = maxi(melhor, dia)
	var licoes = antigo.get_value("progresso", "licoes", [])
	if typeof(licoes) == TYPE_ARRAY:
		for id in licoes:
			if Textos.LICOES.has(String(id)) and not String(id) in novo["licoes"]:
				novo["licoes"].append(String(id))
	var partidas := int(antigo.get_value("progresso", "partidas", 0))
	novo["dinheiro"] = Dados.DINHEIRO_INICIAL + minf(BONUS_VETERANO_MAXIMO, BONUS_VETERANO * partidas)
	novo["contadores"]["maior_dia"] = melhor
	novo["veterano"] = true
	var id_novo := "p%d%03d" % [int(Time.get_unix_time_from_system()), randi() % 1000]
	perfis[id_novo] = novo
	salvar()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(ARQUIVO_V3), ProjectSettings.globalize_path(ARQUIVO_V3 + ".migrado"))


func salvar() -> void:
	if id_ativo != "" and not perfil.is_empty():
		perfis[id_ativo] = perfil
	var arquivo := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	if arquivo == null:
		return
	arquivo.store_string(JSON.stringify({"versao": VERSAO, "perfis": perfis}))
	arquivo.close()


func hash_pin(sal: String, pin: String) -> String:
	if pin == "":
		return ""
	return ("ddos-defense:" + sal + ":" + pin).sha256_text()


func criar_perfil(nome: String, pin: String, avatar: Dictionary) -> String:
	var id := "p%d%03d" % [int(Time.get_unix_time_from_system()), randi() % 1000]
	var novo := padrao(nome)
	novo["sal"] = "%d-%d" % [randi(), int(Time.get_unix_time_from_system())]
	novo["pin"] = hash_pin(novo["sal"], pin)
	for chave in avatar:
		novo["avatar"][chave] = int(avatar[chave])
	perfis[id] = novo
	id_ativo = id
	perfil = novo
	salvar()
	return id


func exige_pin(id: String) -> bool:
	return perfis.has(id) and String(perfis[id].get("pin", "")) != ""


func entrar(id: String, pin := "") -> bool:
	if not perfis.has(id):
		return false
	if exige_pin(id) and hash_pin(String(perfis[id].get("sal", "")), pin) != perfis[id]["pin"]:
		return false
	id_ativo = id
	perfil = perfis[id]
	atualizar_sequencia()
	salvar()
	return true


func sair() -> void:
	salvar()
	id_ativo = ""
	perfil = {}


func excluir_conta(id: String) -> void:
	perfis.erase(id)
	if id == id_ativo:
		id_ativo = ""
		perfil = {}
	salvar()


func avisar(texto: String, cor := COR_INFO, licao := "") -> void:
	notificacao.emit(texto, cor, licao)


func dinheiro() -> float:
	return perfil.get("dinheiro", 0.0)


func escolher_carreira(id: String) -> bool:
	if perfil.is_empty() or not Dados.CARREIRAS.has(id):
		return false
	perfil["carreira"] = id
	salvar()
	return true


func progresso_carreira(id: String) -> int:
	return int(perfil.get("carreiras", {}).get(id, 0))


func nivel_carreira(id: String) -> int:
	var divisor := 2 if id == "empreendedor" else 3
	return mini(3, progresso_carreira(id) / divisor)


func registrar_atividade_carreira(id: String) -> void:
	if perfil.is_empty() or not Dados.CARREIRAS.has(id):
		return
	perfil["carreiras"][id] = progresso_carreira(id) + 1
	var divisor := 2 if id == "empreendedor" else 3
	if progresso_carreira(id) <= 3 * divisor and progresso_carreira(id) % divisor == 0:
		avisar("Especialização em %s: nível %d" % [Dados.CARREIRAS[id]["nome"], nivel_carreira(id)], COR_OK)


func concluir_curso_cafe(id: String) -> bool:
	if perfil.is_empty() or id in perfil["cursos_cafe"]:
		return false
	for curso in Dados.CURSOS_CAFE:
		if curso["id"] == id:
			perfil["cursos_cafe"].append(id)
			perfil["dinheiro"] = dinheiro() + 100.0
			ganhar_xp(int(curso["xp"]))
			desbloquear_licao(curso["licao"])
			somar("cursos_concluidos")
			avisar("Curso concluído: +R$ 100 mil e +%d XP" % int(curso["xp"]), COR_OK)
			salvar()
			return true
	return false


func gastar(valor: float) -> bool:
	if perfil.is_empty() or valor > dinheiro() + 0.001:
		return false
	perfil["dinheiro"] = dinheiro() - valor
	salvar()
	return true


func ganhar(valor: float) -> void:
	if perfil.is_empty():
		return
	perfil["dinheiro"] = dinheiro() + valor
	salvar()


func nivel() -> int:
	return Dados.nivel_por_xp(perfil.get("xp", 0))


func titulo() -> String:
	return Dados.NIVEIS[nivel()]["titulo"]


func progresso_nivel() -> float:
	var n := nivel()
	if n >= Dados.NIVEIS.size() - 1:
		return 1.0
	var inicio: int = Dados.NIVEIS[n]["xp"]
	var fim: int = Dados.NIVEIS[n + 1]["xp"]
	return clampf(float(perfil["xp"] - inicio) / float(fim - inicio), 0.0, 1.0)


func ganhar_xp(valor: int) -> void:
	if perfil.is_empty() or valor <= 0:
		return
	var antes := nivel()
	perfil["xp"] = int(perfil["xp"]) + valor
	var depois := nivel()
	if depois > antes:
		avisar("Subiu de nível! Agora você é %s" % Dados.NIVEIS[depois]["titulo"], COR_OURO)
		subiu_nivel.emit(depois)
	salvar()


func hoje() -> String:
	return Time.get_date_string_from_system()


func ontem() -> String:
	return Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 86400)


func atualizar_sequencia() -> void:
	var seq: Dictionary = perfil["sequencia"]
	var data := hoje()
	if seq["ultimo"] == data:
		return
	if seq["ultimo"] == ontem():
		seq["dias"] = int(seq["dias"]) + 1
	else:
		seq["dias"] = 1
	seq["ultimo"] = data
	seq["melhor"] = maxi(int(seq["melhor"]), int(seq["dias"]))
	var recompensa := minf(MAX_RECOMPENSA_SEQUENCIA, RECOMPENSA_SEQUENCIA * int(seq["dias"]))
	perfil["dinheiro"] = dinheiro() + recompensa
	avisar("Sequência de %d dia(s) jogando! +R$ %d mil na carteira" % [int(seq["dias"]), roundi(recompensa)], COR_OURO)


func valor(chave: String) -> int:
	return int(perfil.get("contadores", {}).get(chave, 0))


func diarias_estado() -> Dictionary:
	var diarias: Dictionary = perfil["diarias"]
	if diarias["data"] != hoje():
		diarias["data"] = hoje()
		diarias["contadores"] = {}
		diarias["resgatadas"] = []
	return diarias


func diarias_hoje() -> Array:
	var semente := hash(hoje() + String(id_ativo))
	var indices: Array = range(Dados.DIARIAS.size())
	var gerador := RandomNumberGenerator.new()
	gerador.seed = semente
	for i in range(indices.size() - 1, 0, -1):
		var j := gerador.randi_range(0, i)
		var temp = indices[i]
		indices[i] = indices[j]
		indices[j] = temp
	var lista: Array = []
	for k in 3:
		lista.append(Dados.DIARIAS[indices[k]])
	return lista


func valor_diario(chave: String) -> int:
	return int(diarias_estado()["contadores"].get(chave, 0))


func somar(chave: String, quantidade := 1) -> void:
	if perfil.is_empty() or quantidade == 0:
		return
	var concluidas_antes := missoes_prontas()
	var contadores: Dictionary = perfil["contadores"]
	contadores[chave] = int(contadores.get(chave, 0)) + quantidade
	var diarias := diarias_estado()
	diarias["contadores"][chave] = int(diarias["contadores"].get(chave, 0)) + quantidade
	anunciar_novas(concluidas_antes)


func registrar_maximo(chave: String, novo_valor: int) -> void:
	if perfil.is_empty():
		return
	var concluidas_antes := missoes_prontas()
	var contadores: Dictionary = perfil["contadores"]
	contadores[chave] = maxi(int(contadores.get(chave, 0)), novo_valor)
	anunciar_novas(concluidas_antes)


func anunciar_novas(antes: Array) -> void:
	for m in missoes_prontas():
		if not m in antes:
			avisar("Missão concluída: %s. Resgate a recompensa em Missões" % Dados.MISSOES[m]["titulo"] if m is int else "Missão diária concluída! Resgate em Missões", COR_OK)


func missao_por_id(id: String) -> Dictionary:
	for m in Dados.MISSOES:
		if m["id"] == id:
			return m
	return {}


func missao_concluida(m: Dictionary) -> bool:
	return valor(m["contador"]) >= int(m["alvo"])


func missao_disponivel(m: Dictionary) -> bool:
	if m["id"] in perfil.get("missoes_resgatadas", []):
		return false
	if m.has("requer"):
		var anterior := missao_por_id(m["requer"])
		if not anterior.is_empty() and not missao_concluida(anterior):
			return false
	return true


func missoes_ativas() -> Array:
	var lista: Array = []
	for m in Dados.MISSOES:
		if missao_disponivel(m):
			lista.append(m)
	return lista


func missoes_prontas() -> Array:
	var lista: Array = []
	if perfil.is_empty():
		return lista
	for i in Dados.MISSOES.size():
		var m: Dictionary = Dados.MISSOES[i]
		if missao_disponivel(m) and missao_concluida(m):
			lista.append(i)
	var diarias := diarias_estado()
	for d in diarias_hoje():
		if not d["id"] in diarias["resgatadas"] and valor_diario(d["contador"]) >= int(d["alvo"]):
			lista.append(d["id"])
	return lista


func quantidade_prontas() -> int:
	return missoes_prontas().size()


func resgatar_missao(id: String) -> bool:
	var m := missao_por_id(id)
	if m.is_empty() or not missao_disponivel(m) or not missao_concluida(m):
		return false
	perfil["missoes_resgatadas"].append(id)
	perfil["dinheiro"] = dinheiro() + float(m["dinheiro"])
	avisar("Recompensa: +R$ %d mil e +%d XP" % [roundi(m["dinheiro"]), int(m["xp"])], COR_OURO)
	ganhar_xp(int(m["xp"]))
	salvar()
	return true


func resgatar_diaria(id: String) -> bool:
	var diarias := diarias_estado()
	for d in diarias_hoje():
		if d["id"] == id and not id in diarias["resgatadas"] and valor_diario(d["contador"]) >= int(d["alvo"]):
			diarias["resgatadas"].append(id)
			perfil["dinheiro"] = dinheiro() + float(d["dinheiro"])
			avisar("Diária concluída: +R$ %d mil e +%d XP" % [roundi(d["dinheiro"]), int(d["xp"])], COR_OURO)
			ganhar_xp(int(d["xp"]))
			salvar()
			return true
	return false


func licao_desbloqueada(id: String) -> bool:
	return id in perfil.get("licoes", [])


func desbloquear_licao(id: String) -> bool:
	if perfil.is_empty() or not Textos.LICOES.has(id) or licao_desbloqueada(id):
		return false
	perfil["licoes"].append(id)
	salvar()
	return true


func ler_licao(id: String) -> void:
	desbloquear_licao(id)
	if perfil.is_empty() or id in perfil["licoes_lidas"]:
		return
	perfil["licoes_lidas"].append(id)
	somar("licoes_lidas")
	ganhar_xp(XP_LICAO)


func desafio_resolvido(id: String) -> bool:
	return id in perfil.get("desafios", [])


func resolver_desafio(id: String) -> bool:
	if perfil.is_empty() or desafio_resolvido(id):
		return false
	var antes := codigo_seguro()
	perfil["desafios"].append(id)
	perfil["dinheiro"] = dinheiro() + DINHEIRO_DESAFIO
	somar("desafios_resolvidos")
	ganhar_xp(XP_DESAFIO)
	if codigo_seguro() > antes:
		avisar("Código seguro nível %d: suas empresas resistem melhor a SQL Injection e XSS" % codigo_seguro(), COR_OK, "codigo_seguro")
	salvar()
	return true


func codigo_seguro() -> int:
	return mini(MAX_CODIGO_SEGURO, perfil.get("desafios", []).size() / DESAFIOS_POR_NIVEL_CODIGO)


func empresa_dados(id: String) -> Dictionary:
	if id == "startup":
		var s: Dictionary = perfil.get("startup", {})
		if s.is_empty():
			return {}
		var base: Dictionary = Dados.empresa_por_id(s["base"]).duplicate(true)
		var logo: Dictionary = s["logo"]
		base["id"] = "startup"
		base["nome"] = s["nome"]
		base["sigla"] = s["sigla"]
		base["setor"] = s["setor"]
		base["cor"] = Dados.CORES_LOGO[int(logo["cor"])]
		base["logo"] = {"forma": logo["forma"], "cor": Dados.CORES_LOGO[int(logo["cor"])], "cor2": Dados.CORES_LOGO[int(logo["cor2"])], "icone": logo["icone"]}
		base["descricao"] = "Sua própria empresa de %s. Começou numa garagem e agora precisa aguentar o mundo real." % String(s["setor"]).to_lower()
		base["preco"] = 0.0
		base["nivel"] = 0
		base["contrato"] = false
		base["receita"] = float(base["receita"]) * 1.1
		return base
	return Dados.empresa_por_id(id)


func estado_empresa(id: String) -> Dictionary:
	var empresas: Dictionary = perfil["empresas"]
	if not empresas.has(id):
		empresas[id] = {"dono": false, "recorde": 0, "temporadas": 0, "lucro": 0.0}
	return empresas[id]


func eh_dono(id: String) -> bool:
	if id == "startup":
		return not perfil.get("startup", {}).is_empty()
	return perfil.get("empresas", {}).get(id, {}).get("dono", false)


func pode_operar(id: String) -> bool:
	var dados := empresa_dados(id)
	if dados.is_empty():
		return false
	return eh_dono(id) or (dados["contrato"] and nivel() >= int(dados["nivel"]))


func participacao(id: String) -> float:
	if id == "startup":
		return Dados.PARTICIPACAO["propria"]
	return Dados.PARTICIPACAO["dono"] if eh_dono(id) else Dados.PARTICIPACAO["contrato"]


func quantidade_empresas() -> int:
	var total := 0
	for id in perfil.get("empresas", {}):
		if perfil["empresas"][id].get("dono", false):
			total += 1
	if not perfil.get("startup", {}).is_empty():
		total += 1
	return total


func comprar_empresa(id: String) -> String:
	var dados := Dados.empresa_por_id(id)
	if dados.is_empty():
		return "Empresa inválida"
	if eh_dono(id):
		return "Você já é dono dessa empresa"
	if nivel() < int(dados["nivel"]):
		return "Precisa ser %s para comprar" % Dados.NIVEIS[int(dados["nivel"])]["titulo"]
	if not gastar(float(dados["preco"])):
		return "Dinheiro insuficiente na carteira"
	estado_empresa(id)["dono"] = true
	somar("empresas_compradas")
	registrar_maximo("empresas_proprias", quantidade_empresas())
	avisar("Agora a %s é sua! Você recebe %d%% do lucro de cada dia" % [dados["nome"], roundi(Dados.PARTICIPACAO["dono"] * 100)], COR_OURO)
	salvar()
	return ""


func criar_startup(nome: String, sigla: String, setor_indice: int, logo: Dictionary, lote := "") -> String:
	if not perfil.get("startup", {}).is_empty():
		return "Você já tem uma empresa própria"
	if lote == "" or not possui_terreno(lote) or String(perfil["terrenos"][lote]) != "":
		return "Escolha um terreno seu e vazio para fundar a startup"
	if nome.strip_edges().length() < 2:
		return "Dê um nome para a empresa"
	if not gastar(Dados.CUSTO_STARTUP):
		return "Fundar custa R$ %d mil" % roundi(Dados.CUSTO_STARTUP)
	var setor: Dictionary = Dados.SETORES_STARTUP[setor_indice]
	perfil["startup"] = {"nome": nome.strip_edges(), "sigla": sigla.strip_edges().to_upper().substr(0, 2), "setor": setor["setor"], "base": setor["base"], "lote": lote,
		"logo": {"forma": logo["forma"], "cor": int(logo["cor"]), "cor2": int(logo["cor2"]), "icone": logo["icone"]}}
	perfil["terrenos"][lote] = "startup"
	somar("empresa_criada")
	registrar_maximo("empresas_proprias", quantidade_empresas())
	avisar("%s foi fundada! A sede dela já está de pé no seu terreno" % nome, COR_OURO)
	salvar()
	return ""


func lote_por_id(id: String) -> Dictionary:
	for l in Dados.LOTES:
		if l["id"] == id:
			return l
	return {}


func possui_terreno(id: String) -> bool:
	return perfil.get("terrenos", {}).has(id)


func construcao(id: String) -> String:
	return String(perfil.get("terrenos", {}).get(id, ""))


func comprar_terreno(id: String) -> String:
	var lote := lote_por_id(id)
	if lote.is_empty():
		return "Terreno inválido"
	if possui_terreno(id):
		return "Esse terreno já é seu"
	if not gastar(float(lote["preco"])):
		return "Dinheiro insuficiente na carteira"
	perfil["terrenos"][id] = ""
	somar("terrenos_comprados")
	avisar("%s agora é seu! Escolha o que construir nele" % lote["nome"], COR_OURO)
	salvar()
	return ""


func construir(id: String, tipo: String) -> String:
	if not possui_terreno(id):
		return "Compre o terreno primeiro"
	if construcao(id) != "":
		return "Já existe uma construção aqui"
	if not Dados.CONSTRUCOES.has(tipo):
		return "Construção inválida"
	var dados: Dictionary = Dados.CONSTRUCOES[tipo]
	if nivel() < int(dados["nivel"]):
		return "Precisa ser %s" % Dados.NIVEIS[int(dados["nivel"])]["titulo"]
	if not gastar(float(dados["custo"])):
		return "Dinheiro insuficiente na carteira"
	perfil["terrenos"][id] = tipo
	somar("construcoes")
	registrar_atividade_carreira("empreendedor")
	avisar("%s inaugurado! Rende %s por dia operado" % [dados["nome"], "R$ %d mil" % roundi(dados["renda"])], COR_OURO)
	salvar()
	return ""


func demolir(id: String) -> void:
	var tipo := construcao(id)
	if tipo == "" or tipo == "startup":
		return
	perfil["terrenos"][id] = ""
	perfil["dinheiro"] = dinheiro() + float(Dados.CONSTRUCOES[tipo]["custo"]) * 0.5
	salvar()


func renda_imoveis() -> float:
	var total := 0.0
	for id in perfil.get("terrenos", {}):
		var tipo := String(perfil["terrenos"][id])
		if Dados.CONSTRUCOES.has(tipo):
			total += float(Dados.CONSTRUCOES[tipo]["renda"])
	return total


func xp_imoveis() -> int:
	var total := 0
	for id in perfil.get("terrenos", {}):
		var tipo := String(perfil["terrenos"][id])
		if Dados.CONSTRUCOES.has(tipo):
			total += int(Dados.CONSTRUCOES[tipo]["xp"])
	return total


func pentests_hoje() -> Array:
	var registro: Dictionary = perfil["pentests"]
	if registro.get("data", "") != hoje():
		registro["data"] = hoje()
		registro["feitos"] = []
	return registro["feitos"]


func pentest_feito(id: String) -> bool:
	return id in pentests_hoje()


func registrar_pentest(id: String, recompensa: float) -> bool:
	if pentest_feito(id):
		return false
	pentests_hoje().append(id)
	var premio := recompensa * (1.0 + 0.1 * nivel_carreira("hacker")) if perfil["carreira"] == "hacker" else recompensa
	perfil["dinheiro"] = dinheiro() + premio
	somar("pentests")
	registrar_atividade_carreira("hacker")
	ganhar_xp(60)
	desbloquear_licao("iot")
	desbloquear_licao("pentest_autorizado")
	salvar()
	return true


func auditoria_disponivel(id: String) -> bool:
	if perfil.is_empty() or not Dados.AUDITORIAS.has(id):
		return false
	var registro: Dictionary = perfil["auditorias"]
	if id in registro["concluidas"]:
		return false
	if registro["tentativas"]["data"] != hoje():
		registro["tentativas"] = {"data": hoje(), "propostas": {}}
	return not registro["tentativas"]["propostas"].has(id)


func aceitar_auditoria(id: String, proposta: int) -> bool:
	if proposta < 0 or proposta >= Dados.PROPOSTAS_AUDITORIA.size() or not auditoria_disponivel(id):
		return false
	perfil["auditorias"]["tentativas"]["propostas"][id] = proposta
	salvar()
	return true


func concluir_auditoria(id: String, proposta: int) -> float:
	if perfil.is_empty() or not Dados.AUDITORIAS.has(id) or proposta < 0 or proposta >= Dados.PROPOSTAS_AUDITORIA.size():
		return 0.0
	var registro: Dictionary = perfil["auditorias"]
	if id in registro["concluidas"] or registro["tentativas"]["data"] != hoje() or int(registro["tentativas"]["propostas"].get(id, -1)) != proposta:
		return 0.0
	var oferta: Dictionary = Dados.PROPOSTAS_AUDITORIA[proposta]
	var premio: float = oferta["valor"]
	if perfil["carreira"] == "hacker":
		premio *= 1.0 + 0.1 * nivel_carreira("hacker")
	registro["concluidas"].append(id)
	perfil["dinheiro"] = dinheiro() + premio
	somar("auditorias")
	somar("pentests")
	registrar_atividade_carreira("hacker")
	ganhar_xp(int(oferta["xp"]))
	desbloquear_licao(Dados.AUDITORIAS[id]["licao"])
	avisar("Auditoria entregue: +%s mil na carteira" % roundi(premio), COR_OK)
	salvar()
	return premio


func ctf_disponivel() -> bool:
	return perfil["ctf"].get("data", "") != hoje()


func registrar_ctf(acertos: int) -> float:
	perfil["ctf"] = {"data": hoje(), "feito": true}
	var premio := acertos * PREMIO_CTF
	perfil["dinheiro"] = dinheiro() + premio
	somar("ctf_acertos", acertos)
	ganhar_xp(25 * acertos)
	salvar()
	return premio


func registrar_dia(id: String, dia: int, lucro: float) -> float:
	var est := estado_empresa(id)
	est["recorde"] = maxi(int(est["recorde"]), dia)
	est["lucro"] = float(est["lucro"]) + lucro
	registrar_maximo("maior_dia", dia)
	somar("dias_operados")
	registrar_atividade_carreira("operador")
	var parte := maxf(0.0, lucro) * participacao(id)
	if perfil["carreira"] == "operador":
		parte *= 1.0 + 0.05 * nivel_carreira("operador")
	var imoveis := renda_imoveis()
	if perfil["carreira"] == "empreendedor":
		imoveis *= 1.0 + 0.1 * nivel_carreira("empreendedor")
	var dividendo := parte + imoveis
	if dividendo > 0.0:
		perfil["dinheiro"] = dinheiro() + dividendo
	ganhar_xp(XP_DIA_BASE + XP_DIA_EXTRA * dia + xp_imoveis())
	salvar()
	return dividendo


func possui_item(id: String) -> bool:
	return id in perfil.get("itens", [])


func reforcos(id: String) -> int:
	return int(perfil.get("reforcos", {}).get(id, 0))


func comprar_item(id: String) -> String:
	if not Dados.ITENS.has(id):
		return "Item inválido"
	var item: Dictionary = Dados.ITENS[id]
	if item["tipo"] != "reforco" and possui_item(id):
		return "Você já tem esse item"
	if not gastar(float(item["preco"])):
		return "Dinheiro insuficiente"
	if item["tipo"] == "reforco":
		perfil["reforcos"][id] = reforcos(id) + 1
	else:
		perfil["itens"].append(id)
		perfil["equipados"][item["tipo"]] = id
	somar("itens_comprados")
	avisar("%s comprado!" % item["nome"], COR_OK)
	salvar()
	return ""


func equipar(id: String) -> void:
	if not possui_item(id):
		return
	var tipo: String = Dados.ITENS[id]["tipo"]
	perfil["equipados"][tipo] = "" if perfil["equipados"].get(tipo, "") == id else id
	salvar()


func usar_reforco(id: String) -> bool:
	if reforcos(id) <= 0:
		return false
	perfil["reforcos"][id] = reforcos(id) - 1
	salvar()
	return true


func salvar_operacao(id: String, dados: Dictionary) -> void:
	perfil["operacoes"][id] = dados
	salvar()


func obter_operacao(id: String) -> Dictionary:
	return perfil.get("operacoes", {}).get(id, {})


func limpar_operacao(id: String) -> void:
	perfil["operacoes"].erase(id)
	salvar()


func exportar_codigo() -> String:
	return PREFIXO_CODIGO + Marshalls.utf8_to_base64(JSON.stringify(perfil))


func importar_codigo(texto: String) -> String:
	var limpo := texto.strip_edges().replace(" ", "").replace("\n", "")
	if not limpo.begins_with(PREFIXO_CODIGO):
		return ""
	var corpo := limpo.substr(PREFIXO_CODIGO.length())
	var valido := RegEx.create_from_string("^[A-Za-z0-9+/]+={0,2}$")
	if corpo.length() < 8 or corpo.length() % 4 != 0 or valido.search(corpo) == null:
		return ""
	var json := Marshalls.base64_to_utf8(corpo)
	if json == "" or not json.begins_with("{"):
		return ""
	var teste := JSON.new()
	if teste.parse(json) != OK:
		return ""
	var dados = teste.data
	if typeof(dados) != TYPE_DICTIONARY or not dados.has("nome") or not dados.has("xp"):
		return ""
	var id := "p%d%03d" % [int(Time.get_unix_time_from_system()), randi() % 1000]
	var existente := ""
	for outro in perfis:
		if perfis[outro]["nome"] == dados["nome"] and String(perfis[outro].get("criado", "")) == String(dados.get("criado", "")):
			existente = outro
	if existente != "":
		id = existente
	perfis[id] = normalizar(dados)
	salvar()
	return id
