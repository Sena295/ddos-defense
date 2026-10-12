extends RefCounted

const FUNDO := Color("0a0e17")
const GRADE := Color(1, 1, 1, 0.03)
const CARTAO := Color("111827")
const CARTAO_CLARO := Color("182134")
const BORDA := Color("243047")
const BORDA_HOVER := Color("3b4a68")
const LINHA := Color("1e293d")
const TEXTO := Color("e5e7eb")
const TEXTO_SUAVE := Color("8b95a8")
const HUMANO := Color("34d399")
const BOT := Color("f87171")
const DESTAQUE := Color("38bdf8")
const CREDITOS := Color("fbbf24")
const PERIGO := Color("ef4444")
const PRINCIPAL := Color("10b981")
const SOMBRA := Color(0, 0, 0, 0.35)
const SOBREPOSICAO := Color(0.02, 0.03, 0.06, 0.82)
const TRANSPARENTE := Color(0, 0, 0, 0)

static var estilo := StyleBoxFlat.new()


static func fonte() -> Font:
	return ThemeDB.fallback_font


static func caixa(ci: CanvasItem, r: Rect2, fundo: Color, raio := 12, borda := TRANSPARENTE, largura := 0, sombra := 0, detalhe := 8) -> void:
	estilo.bg_color = fundo
	estilo.set_corner_radius_all(raio)
	estilo.corner_detail = detalhe
	estilo.border_color = borda
	estilo.set_border_width_all(largura)
	estilo.shadow_size = sombra
	estilo.shadow_color = SOMBRA
	estilo.shadow_offset = Vector2(0, sombra * 0.4)
	estilo.anti_aliasing = true
	ci.draw_style_box(estilo, r)


static func texto(ci: CanvasItem, pos: Vector2, conteudo: String, tamanho: int, cor: Color, alinhamento := HORIZONTAL_ALIGNMENT_LEFT, largura := -1.0) -> void:
	ci.draw_string(fonte(), pos, conteudo, alinhamento, largura, tamanho, cor)


static func largura_texto(conteudo: String, tamanho: int) -> float:
	return fonte().get_string_size(conteudo, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x


static func quebrar(conteudo: String, tamanho: int, largura: float) -> PackedStringArray:
	var linhas := PackedStringArray()
	var atual := ""
	for palavra in conteudo.split(" "):
		var tentativa := palavra if atual == "" else atual + " " + palavra
		if largura_texto(tentativa, tamanho) > largura and atual != "":
			linhas.append(atual)
			atual = palavra
		else:
			atual = tentativa
	if atual != "":
		linhas.append(atual)
	return linhas


static func paragrafo(ci: CanvasItem, pos: Vector2, conteudo: String, tamanho: int, cor: Color, largura: float, entrelinha := 1.45, max_linhas := 99) -> float:
	var y := pos.y
	var linhas := quebrar(conteudo, tamanho, largura)
	for i in mini(linhas.size(), max_linhas):
		texto(ci, Vector2(pos.x, y), linhas[i], tamanho, cor)
		y += tamanho * entrelinha
	return y


static func com_alfa(cor: Color, alfa: float) -> Color:
	var c := cor
	c.a *= alfa
	return c


static func botao(ci: CanvasItem, r: Rect2, rotulo: String, cor: Color, hover: bool, ativo := true, tamanho := 16, principal := false) -> void:
	if principal:
		caixa(ci, r, (cor.lightened(0.12) if hover else cor) if ativo else CARTAO_CLARO, 12, TRANSPARENTE, 0, 8 if ativo else 0)
		texto(ci, Vector2(r.position.x, r.get_center().y + tamanho * 0.36), rotulo, tamanho, Color("052e1f") if ativo else TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		return
	caixa(ci, r, CARTAO_CLARO if ativo else CARTAO, 12, cor if hover and ativo else BORDA, 1)
	texto(ci, Vector2(r.position.x, r.get_center().y + tamanho * 0.36), rotulo, tamanho, TEXTO if ativo else TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


static func estrela(ci: CanvasItem, c: Vector2, raio: float, cor: Color) -> void:
	var pontos := PackedVector2Array()
	for k in 10:
		var a := -PI / 2 + k * PI / 5
		var r := raio if k % 2 == 0 else raio * 0.45
		pontos.append(c + Vector2(cos(a), sin(a)) * r)
	ci.draw_colored_polygon(pontos, cor)


static func robo(ci: CanvasItem, c: Vector2, cor: Color, s := 1.0, abatido := false) -> void:
	ci.draw_line(c + Vector2(0, -9) * s, c + Vector2(0, -14) * s, cor, 1.5 * s, true)
	ci.draw_circle(c + Vector2(0, -15) * s, 2.0 * s, cor, true, -1.0, true)
	caixa(ci, Rect2(c - Vector2(9, 9) * s, Vector2(18, 16) * s), cor, int(4 * s))
	var olho := Color("0a0e17")
	if abatido:
		for dx in [-4.0, 4.0]:
			var o := c + Vector2(dx, -2) * s
			ci.draw_line(o + Vector2(-2, -2) * s, o + Vector2(2, 2) * s, olho, 1.5 * s, true)
			ci.draw_line(o + Vector2(-2, 2) * s, o + Vector2(2, -2) * s, olho, 1.5 * s, true)
	else:
		ci.draw_circle(c + Vector2(-4, -2) * s, 2.0 * s, olho, true, -1.0, true)
		ci.draw_circle(c + Vector2(4, -2) * s, 2.0 * s, olho, true, -1.0, true)
	ci.draw_line(c + Vector2(-3, 3) * s, c + Vector2(3, 3) * s, olho, 1.2 * s, true)


static func cadeado(ci: CanvasItem, c: Vector2, cor: Color, s := 1.0, aberto := false) -> void:
	var desloc := -4.0 if aberto else 0.0
	ci.draw_arc(c + Vector2(desloc, -4) * s, 5.0 * s, PI, TAU, 12, cor, 2.0 * s, true)
	caixa(ci, Rect2(c + Vector2(-7, -4) * s, Vector2(14, 11) * s), cor, int(3 * s))


static func icone(ci: CanvasItem, tipo: String, c: Vector2, cor: Color, s := 1.0) -> void:
	match tipo:
		"internet":
			ci.draw_arc(c, 10 * s, 0.0, TAU, 32, cor, 2.0, true)
			ci.draw_line(c + Vector2(-10, 0) * s, c + Vector2(10, 0) * s, cor, 1.5, true)
			var elipse := PackedVector2Array()
			for k in 25:
				var a := TAU * k / 24.0
				elipse.append(c + Vector2(cos(a) * 4.5, sin(a) * 10) * s)
			ci.draw_polyline(elipse, cor, 1.5, true)
		"cdn":
			ci.draw_circle(c + Vector2(-5, 2) * s, 5 * s, cor, true, -1.0, true)
			ci.draw_circle(c + Vector2(2, -2) * s, 6.5 * s, cor, true, -1.0, true)
			ci.draw_circle(c + Vector2(8, 3) * s, 4 * s, cor, true, -1.0, true)
			ci.draw_rect(Rect2(c + Vector2(-5, 2) * s, Vector2(13, 5) * s), cor)
		"antiddos":
			ci.draw_arc(c + Vector2(0, 2) * s, 10 * s, PI, TAU, 20, cor, 2.5, true)
			ci.draw_line(c + Vector2(0, -8) * s, c + Vector2(0, 8) * s, cor, 2.0, true)
			ci.draw_arc(c + Vector2(-3, 8) * s, 3 * s, 0.0, PI, 8, cor, 2.0, true)
		"waf":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -11) * s, c + Vector2(9, -7) * s, c + Vector2(8, 3) * s,
				c + Vector2(0, 11) * s, c + Vector2(-8, 3) * s, c + Vector2(-9, -7) * s]), cor)
		"captcha":
			robo(ci, c + Vector2(0, 2) * s, cor, 0.8 * s)
		"rate":
			ci.draw_arc(c + Vector2(0, 4) * s, 10 * s, PI, TAU, 20, cor, 2.0, true)
			ci.draw_line(c + Vector2(0, 4) * s, c + Vector2(6, -4) * s, cor, 2.0, true)
			ci.draw_circle(c + Vector2(0, 4) * s, 2.5 * s, cor, true, -1.0, true)
		"mfa":
			caixa(ci, Rect2(c + Vector2(-6, -10) * s, Vector2(12, 20) * s), cor, int(3 * s))
			caixa(ci, Rect2(c + Vector2(-4, -7) * s, Vector2(8, 11) * s), Color("0a0e17"), int(2 * s))
			ci.draw_circle(c + Vector2(0, 7) * s, 1.3 * s, Color("0a0e17"), true, -1.0, true)
		"geo":
			ci.draw_arc(c, 10 * s, 0.0, TAU, 32, cor, 2.0, true)
			ci.draw_line(c + Vector2(-7, 7) * s, c + Vector2(7, -7) * s, cor, 2.5, true)
		"lb":
			var origem := c + Vector2(-8, 0) * s
			for dy in [-8.0, 0.0, 8.0]:
				var destino := c + Vector2(8, dy) * s
				ci.draw_line(origem, destino, cor, 2.0, true)
				ci.draw_circle(destino, 2.5 * s, cor, true, -1.0, true)
			ci.draw_circle(origem, 3.5 * s, cor, true, -1.0, true)
		"fila":
			for k in 3:
				caixa(ci, Rect2(c + Vector2(-10 + k * 7, -6) * s, Vector2(5, 12) * s), cor, int(2 * s))
			ci.draw_line(c + Vector2(-12, 9) * s, c + Vector2(12, 9) * s, cor, 1.5, true)
		"redis":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(2, -11) * s, c + Vector2(-6, 2) * s, c + Vector2(0, 2) * s,
				c + Vector2(-2, 11) * s, c + Vector2(7, -2) * s, c + Vector2(1, -2) * s]), cor)
		"servidor":
			for dy in [-6.0, 5.0]:
				ci.draw_rect(Rect2(c + Vector2(-9, dy - 4) * s, Vector2(18, 8) * s), cor, false, 1.5)
				ci.draw_circle(c + Vector2(5, dy) * s, 1.5 * s, cor, true, -1.0, true)
		"autoscale":
			for dx in [-6.0, 4.0]:
				ci.draw_rect(Rect2(c + Vector2(dx - 4, -6) * s, Vector2(8, 15) * s), cor, false, 1.5)
			ci.draw_line(c + Vector2(9, 0) * s, c + Vector2(9, -11) * s, cor, 2.0, true)
			ci.draw_line(c + Vector2(6, -8) * s, c + Vector2(9, -11) * s, cor, 2.0, true)
			ci.draw_line(c + Vector2(12, -8) * s, c + Vector2(9, -11) * s, cor, 2.0, true)
		"ips":
			ci.draw_arc(c, 10 * s, 0.0, TAU, 28, cor, 1.5, true)
			ci.draw_arc(c, 5 * s, 0.0, TAU, 20, cor, 1.5, true)
			ci.draw_line(c, c + Vector2(8, -6) * s, cor, 2.0, true)
			ci.draw_circle(c + Vector2(4, 3) * s, 1.8 * s, cor, true, -1.0, true)
		"backup":
			for dy in [-6.0, 0.0, 6.0]:
				caixa(ci, Rect2(c + Vector2(-9, dy - 2.5) * s, Vector2(18, 5) * s), cor, int(2 * s))
			ci.draw_arc(c + Vector2(9, 0) * s, 5 * s, -PI * 0.6, PI * 0.6, 10, cor, 1.5, true)
		"patch":
			var faixa := PackedVector2Array([c + Vector2(-11, 4) * s, c + Vector2(4, -11) * s, c + Vector2(11, -4) * s, c + Vector2(-4, 11) * s])
			ci.draw_colored_polygon(faixa, cor)
			for p in [Vector2(-2, -2), Vector2(2, 2), Vector2(2, -2), Vector2(-2, 2)]:
				ci.draw_circle(c + p * s, 1.0 * s, Color("0a0e17"), true, -1.0, true)
		"cofre":
			caixa(ci, Rect2(c - Vector2(10, 9) * s, Vector2(20, 18) * s), cor, int(3 * s))
			ci.draw_arc(c, 5 * s, 0.0, TAU, 16, Color("0a0e17"), 2.0, true)
			ci.draw_line(c, c + Vector2(3, -3) * s, Color("0a0e17"), 2.0, true)
		"treinamento":
			ci.draw_circle(c + Vector2(0, -5) * s, 4.5 * s, cor, true, -1.0, true)
			caixa(ci, Rect2(c + Vector2(-8, 1) * s, Vector2(16, 9) * s), cor, int(4 * s))
		"criptografia":
			ci.draw_arc(c + Vector2(-4, 0) * s, 5 * s, 0.0, TAU, 16, cor, 2.5, true)
			ci.draw_line(c + Vector2(1, 0) * s, c + Vector2(11, 0) * s, cor, 2.5, true)
			ci.draw_line(c + Vector2(7, 0) * s, c + Vector2(7, 4) * s, cor, 2.5, true)
			ci.draw_line(c + Vector2(10, 0) * s, c + Vector2(10, 4) * s, cor, 2.5, true)
		"siem":
			caixa(ci, Rect2(c + Vector2(-11, -8) * s, Vector2(22, 14) * s), cor, int(3 * s))
			ci.draw_line(c + Vector2(-7, 2) * s, c + Vector2(-3, -3) * s, Color("0a0e17"), 1.5, true)
			ci.draw_line(c + Vector2(-3, -3) * s, c + Vector2(1, 0) * s, Color("0a0e17"), 1.5, true)
			ci.draw_line(c + Vector2(1, 0) * s, c + Vector2(7, -5) * s, Color("0a0e17"), 1.5, true)
			ci.draw_line(c + Vector2(-4, 10) * s, c + Vector2(4, 10) * s, cor, 2.0, true)
		"edr":
			ci.draw_circle(c + Vector2(0, 1) * s, 6 * s, cor, true, -1.0, true)
			for lado in [-1.0, 1.0]:
				for dy in [-3.0, 1.0, 5.0]:
					ci.draw_line(c + Vector2(5 * lado, dy) * s, c + Vector2(10 * lado, dy - 2) * s, cor, 1.5, true)
			ci.draw_circle(c + Vector2(0, -6) * s, 3 * s, cor, true, -1.0, true)
		"honeypot":
			caixa(ci, Rect2(c + Vector2(-8, -4) * s, Vector2(16, 14) * s), cor, int(5 * s))
			caixa(ci, Rect2(c + Vector2(-6, -9) * s, Vector2(12, 4) * s), cor, int(2 * s))
			ci.draw_circle(c + Vector2(0, 3) * s, 2.5 * s, Color("0a0e17"), true, -1.0, true)
		"hacker":
			var capuz := PackedVector2Array([c + Vector2(0, -12) * s, c + Vector2(10, -2) * s, c + Vector2(10, 11) * s, c + Vector2(-10, 11) * s, c + Vector2(-10, -2) * s])
			ci.draw_colored_polygon(capuz, cor)
			ci.draw_circle(c + Vector2(0, 1) * s, 5.5 * s, Color("0a0e17"), true, -1.0, true)
			ci.draw_circle(c + Vector2(-2, 0) * s, 1.0 * s, Color("ef4444"), true, -1.0, true)
			ci.draw_circle(c + Vector2(2, 0) * s, 1.0 * s, Color("ef4444"), true, -1.0, true)


static func torre(ci: CanvasItem, r: Rect2, cor: Color, nivel: int, proporcao: float, caido: bool, tempo: float, escala := 1.0) -> void:
	var unidades := 2 + nivel
	var corpo := Rect2(r.position + Vector2(14, 10), Vector2(34, 52))
	var racks := 2 if escala > 1.25 else 1
	for k in racks:
		var deslocado := corpo
		deslocado.position.x += k * 6
		deslocado.position.y -= k * 4
		var cor_corpo := Color("2a1418") if caido else Color("1b2436")
		if k < racks - 1:
			cor_corpo = com_alfa(cor_corpo, 0.6)
		caixa(ci, deslocado, cor_corpo, 6, PERIGO if caido else com_alfa(cor, 0.5), 1)
	var alto := (corpo.size.y - 8) / unidades
	for u in unidades:
		var y := corpo.position.y + 4 + u * alto
		var slot := Rect2(corpo.position.x + 4, y + 1, corpo.size.x - 8, alto - 3)
		caixa(ci, slot, Color("0d1320"), 3)
		var piscar := sin(tempo * (6.0 + proporcao * 18.0) + u * 1.7) > 0.0
		var led := HUMANO
		if caido:
			led = PERIGO if piscar else Color("4b1d1d")
		elif proporcao > 0.75:
			led = CREDITOS if piscar else Color("5c4510")
		elif not piscar:
			led = Color("1f5f47")
		ci.draw_circle(Vector2(slot.position.x + 5, slot.get_center().y), 1.8, led, true, -1.0, true)
		ci.draw_line(Vector2(slot.position.x + 10, slot.get_center().y), Vector2(slot.end.x - 3, slot.get_center().y), Color("26314a"), 1.0)
	var barra := Rect2(r.position + Vector2(r.size.x - 22, 12), Vector2(7, 48))
	caixa(ci, barra, LINHA, 3)
	if not caido and proporcao > 0.0:
		var altura := maxf(4.0, barra.size.y * clampf(proporcao, 0.0, 1.0))
		caixa(ci, Rect2(barra.position.x, barra.end.y - altura, barra.size.x, altura), HUMANO.lerp(PERIGO, clampf(proporcao, 0.0, 1.0)), 3)


static func formatar_decimal(valor: float) -> String:
	var texto_valor := ""
	if valor >= 100.0:
		texto_valor = "%d" % roundi(valor)
	elif valor >= 10.0:
		texto_valor = "%.1f" % valor
	else:
		texto_valor = "%.2f" % valor
	return texto_valor.replace(".", ",")


static func dinheiro(mil: float) -> String:
	var negativo := mil < 0.0
	var v := absf(mil)
	var resultado := ""
	if v >= 1000000.0:
		resultado = "R$ %s bi" % formatar_decimal(v / 1000000.0)
	elif v >= 1000.0:
		resultado = "R$ %s mi" % formatar_decimal(v / 1000.0)
	else:
		resultado = "R$ %d mil" % roundi(v)
	return ("-" if negativo else "") + resultado


static func requisicoes(por_minuto: float) -> String:
	if por_minuto >= 1000000.0:
		return "%s mi" % formatar_decimal(por_minuto / 1000000.0)
	if por_minuto >= 1000.0:
		return "%d mil" % roundi(por_minuto / 1000.0)
	return "%d" % roundi(por_minuto)


static func elipse(ci: CanvasItem, c: Vector2, raio: Vector2, cor: Color) -> void:
	if raio.x < 1.0 or raio.y < 1.0 or cor.a <= 0.0:
		return
	var pontos := PackedVector2Array()
	for k in 20:
		var a := TAU * k / 20.0
		pontos.append(c + Vector2(cos(a) * raio.x, sin(a) * raio.y))
	ci.draw_colored_polygon(pontos, cor)


static func losango(ci: CanvasItem, c: Vector2, r: float, cor: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), cor)
	ci.draw_circle(c, r * 0.32, Color(0, 0, 0, 0.45), true, -1.0, true)


static func texto_mono(ci: CanvasItem, pos: Vector2, conteudo: String, tamanho: int, cor: Color, avanco := 0.0) -> void:
	var passo := avanco if avanco > 0.0 else tamanho * 0.62
	var f := fonte()
	for i in conteudo.length():
		var largura_char := f.get_char_size(conteudo.unicode_at(i), tamanho).x
		ci.draw_char(f, pos + Vector2(i * passo + (passo - largura_char) * 0.5, 0), conteudo[i], tamanho, cor)


static func forma(ci: CanvasItem, tipo: String, c: Vector2, r: float, cor: Color) -> void:
	match tipo:
		"quadrado":
			caixa(ci, Rect2(c - Vector2(r, r), Vector2(r, r) * 2), cor, int(r * 0.45), TRANSPARENTE, 0, 0, 6)
		"hexagono":
			var hex := PackedVector2Array()
			for k in 6:
				var a := PI / 6 + k * TAU / 6
				hex.append(c + Vector2(cos(a), sin(a)) * r * 1.08)
			ci.draw_colored_polygon(hex, cor)
		"losango":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 1.2), c + Vector2(r * 1.2, 0), c + Vector2(0, r * 1.2), c + Vector2(-r * 1.2, 0)]), cor)
		"escudo":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r), c + Vector2(r, r * 0.2), c + Vector2(0, r * 1.15), c + Vector2(-r, r * 0.2)]), cor)
		_:
			ci.draw_circle(c, r, cor, true, -1.0, true)


static func logo(ci: CanvasItem, c: Vector2, r: float, spec: Dictionary, sigla := "") -> void:
	forma(ci, spec.get("forma", "circulo"), c, r, spec.get("cor", DESTAQUE))
	var icone_logo: String = spec.get("icone", "")
	if icone_logo == "":
		texto(ci, Vector2(c.x - r, c.y + r * 0.35), sigla, int(r * 0.9), spec.get("cor2", Color.WHITE), HORIZONTAL_ALIGNMENT_CENTER, r * 2)
		return
	simbolo(ci, icone_logo, c, spec.get("cor2", Color.WHITE), r / 12.0)


static func simbolo(ci: CanvasItem, tipo: String, c: Vector2, cor: Color, s := 1.0) -> void:
	match tipo:
		"carrinho":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-9, -6) * s, c + Vector2(-6, -6) * s, c + Vector2(-3, 4) * s, c + Vector2(7, 4) * s, c + Vector2(9, -3) * s, c + Vector2(-5, -3) * s]), cor, 2.0 * s, true)
			ci.draw_circle(c + Vector2(-2, 8) * s, 1.8 * s, cor, true, -1.0, true)
			ci.draw_circle(c + Vector2(6, 8) * s, 1.8 * s, cor, true, -1.0, true)
		"sacola":
			caixa(ci, Rect2(c + Vector2(-7, -3) * s, Vector2(14, 12) * s), cor, int(2 * s))
			ci.draw_arc(c + Vector2(0, -3) * s, 4 * s, PI, TAU, 10, cor, 2.0 * s, true)
		"aviao":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, 1) * s, c + Vector2(10, -3) * s, c + Vector2(10, 0) * s, c + Vector2(-10, 3) * s]), cor)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-1, -1) * s, c + Vector2(4, -9) * s, c + Vector2(6, -8) * s, c + Vector2(3, 0) * s]), cor)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-1, 2) * s, c + Vector2(4, 9) * s, c + Vector2(6, 8) * s, c + Vector2(3, 1) * s]), cor)
		"talher":
			ci.draw_line(c + Vector2(-4, -9) * s, c + Vector2(-4, 9) * s, cor, 2.0 * s, true)
			for dx in [-6.0, -4.0, -2.0]:
				ci.draw_line(c + Vector2(dx, -9) * s, c + Vector2(dx, -3) * s, cor, 1.2 * s, true)
			elipse(ci, c + Vector2(5, -4) * s, Vector2(2.5, 5) * s, cor)
			ci.draw_line(c + Vector2(5, 0) * s, c + Vector2(5, 9) * s, cor, 2.0 * s, true)
		"play":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -8) * s, c + Vector2(8, 0) * s, c + Vector2(-5, 8) * s]), cor)
		"banco":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -4) * s, c + Vector2(0, -10) * s, c + Vector2(10, -4) * s]), cor)
			for dx in [-7.0, -2.5, 2.5, 7.0]:
				ci.draw_rect(Rect2(c + Vector2(dx - 1.2, -3) * s, Vector2(2.4, 9) * s), cor)
			ci.draw_rect(Rect2(c + Vector2(-10, 6) * s, Vector2(20, 2.5) * s), cor)
		"moeda":
			ci.draw_arc(c, 9 * s, 0.0, TAU, 28, cor, 2.0 * s, true)
			texto(ci, c + Vector2(-9, 5) * s, "$", int(14 * s), cor, HORIZONTAL_ALIGNMENT_CENTER, 18 * s)
		"cartao":
			caixa(ci, Rect2(c + Vector2(-10, -7) * s, Vector2(20, 14) * s), cor, int(2 * s))
			ci.draw_rect(Rect2(c + Vector2(-10, -3) * s, Vector2(20, 3) * s), Color(0, 0, 0, 0.5))
		"cruz":
			ci.draw_rect(Rect2(c + Vector2(-3, -9) * s, Vector2(6, 18) * s), cor)
			ci.draw_rect(Rect2(c + Vector2(-9, -3) * s, Vector2(18, 6) * s), cor)
		"predio":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -3) * s, c + Vector2(0, -10) * s, c + Vector2(10, -3) * s]), cor)
			ci.draw_rect(Rect2(c + Vector2(-8, -2) * s, Vector2(16, 11) * s), cor)
			ci.draw_rect(Rect2(c + Vector2(-2, 3) * s, Vector2(4, 6) * s), Color(0, 0, 0, 0.5))
		"controle":
			caixa(ci, Rect2(c + Vector2(-10, -5) * s, Vector2(20, 11) * s), cor, int(5 * s))
			ci.draw_rect(Rect2(c + Vector2(-7, -1) * s, Vector2(5, 1.6) * s), Color(0, 0, 0, 0.55))
			ci.draw_rect(Rect2(c + Vector2(-5.2, -3) * s, Vector2(1.6, 5) * s), Color(0, 0, 0, 0.55))
			ci.draw_circle(c + Vector2(5, -1) * s, 1.4 * s, Color(0, 0, 0, 0.55), true, -1.0, true)
			ci.draw_circle(c + Vector2(7, 1.5) * s, 1.4 * s, Color(0, 0, 0, 0.55), true, -1.0, true)
		"antena":
			ci.draw_line(c + Vector2(0, -3) * s, c + Vector2(-5, 10) * s, cor, 2.0 * s, true)
			ci.draw_line(c + Vector2(0, -3) * s, c + Vector2(5, 10) * s, cor, 2.0 * s, true)
			ci.draw_circle(c + Vector2(0, -4) * s, 2.2 * s, cor, true, -1.0, true)
			ci.draw_arc(c + Vector2(0, -4) * s, 6 * s, -PI * 0.85, -PI * 0.15, 10, cor, 1.6 * s, true)
			ci.draw_arc(c + Vector2(0, -4) * s, 10 * s, -PI * 0.8, -PI * 0.2, 12, cor, 1.6 * s, true)
		"cerebro":
			for p in [Vector2(-4, -3), Vector2(4, -3), Vector2(-5, 3), Vector2(5, 3), Vector2(0, -6), Vector2(0, 4)]:
				ci.draw_circle(c + p * s, 4.2 * s, cor, true, -1.0, true)
			ci.draw_line(c + Vector2(0, -9) * s, c + Vector2(0, 8) * s, Color(0, 0, 0, 0.45), 1.5 * s, true)
		"balao":
			caixa(ci, Rect2(c + Vector2(-10, -8) * s, Vector2(20, 13) * s), cor, int(5 * s))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, 4) * s, c + Vector2(1, 4) * s, c + Vector2(-5, 10) * s]), cor)
		"raio":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(2, -11) * s, c + Vector2(-6, 2) * s, c + Vector2(0, 2) * s, c + Vector2(-2, 11) * s, c + Vector2(7, -2) * s, c + Vector2(1, -2) * s]), cor)
		"foguete":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -11) * s, c + Vector2(5, -2) * s, c + Vector2(5, 6) * s, c + Vector2(-5, 6) * s, c + Vector2(-5, -2) * s]), cor)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-5, 2) * s, c + Vector2(-9, 9) * s, c + Vector2(-5, 7) * s]), cor)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(5, 2) * s, c + Vector2(9, 9) * s, c + Vector2(5, 7) * s]), cor)
			ci.draw_circle(c + Vector2(0, -2) * s, 2 * s, Color(0, 0, 0, 0.5), true, -1.0, true)
		"escudo":
			icone(ci, "waf", c, cor, s)
		"codigo":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-4, -7) * s, c + Vector2(-10, 0) * s, c + Vector2(-4, 7) * s]), cor, 2.2 * s, true)
			ci.draw_polyline(PackedVector2Array([c + Vector2(4, -7) * s, c + Vector2(10, 0) * s, c + Vector2(4, 7) * s]), cor, 2.2 * s, true)
			ci.draw_line(c + Vector2(2, -8) * s, c + Vector2(-2, 8) * s, cor, 2.0 * s, true)




const CONTORNO := Color("161b29")


static func pintar_partes(ci: CanvasItem, pe: Vector2, u: float, partes: Array, direcao: int) -> void:
	var espessura := maxf(1.0, roundf(u * 0.55))
	var retangulos: Array = []
	for p in partes:
		var x: float = p[0]
		var w: float = p[2]
		if direcao < 0:
			x = -(x + w)
		retangulos.append(Rect2((pe + Vector2(x, p[1]) * u).round(), (Vector2(w, p[3]) * u).round()))
	for i in partes.size():
		if partes[i][5]:
			ci.draw_rect(retangulos[i].grow(espessura), CONTORNO)
	for i in partes.size():
		ci.draw_rect(retangulos[i], partes[i][4])


static func avatar(ci: CanvasItem, pe: Vector2, escala: float, aparencia: Dictionary, equipados: Dictionary, tempo := 0.0, andando := false, direcao := 1) -> void:
	const Dados := preload("res://dados.gd")
	var u := 1.8 * escala
	var pele: Color = Dados.CORES_PELE[clampi(int(aparencia.get("pele", 0)), 0, Dados.CORES_PELE.size() - 1)]
	var cor_cabelo: Color = Dados.CORES_CABELO[clampi(int(aparencia.get("cor_cabelo", 0)), 0, Dados.CORES_CABELO.size() - 1)]
	var cor_roupa: Color = Dados.CORES_ROUPA[clampi(int(aparencia.get("cor_roupa", 0)), 0, Dados.CORES_ROUPA.size() - 1)]
	var cabelo := clampi(int(aparencia.get("cabelo", 0)), 0, 5)
	var estilo_roupa := clampi(int(aparencia.get("roupa", 0)), 0, 2)
	var olhar := clampi(int(aparencia.get("olhos", 0)), 0, 2)
	var vestimenta: String = equipados.get("roupa", "")
	var chapeu: String = equipados.get("chapeu", "")
	var acessorio: String = equipados.get("acessorio", "")
	var fase := sin(tempo * 11.0) if andando else 0.0
	var b := roundf(absf(fase)) if andando else 0.0
	var passo := roundf(fase * 1.4)
	var braco := roundf(fase)
	var piscar := fmod(tempo + pe.x * 0.01, 3.7) < 0.12
	var pele_sombra := pele.darkened(0.2)
	var calca := Color("2b3550")
	var tronco := cor_roupa
	var manga := cor_roupa
	if vestimenta == "terno":
		tronco = Color("1f2937")
		manga = tronco
		calca = Color("1f2937")
	elif vestimenta == "jaleco":
		tronco = Color("f1f5f9")
		manga = tronco
		calca = Color("475569")
	var braco_nu: bool = estilo_roupa == 2 and vestimenta == ""
	var tronco_sombra := tronco.darkened(0.22)
	var sapato := Color("1e1b2e")
	elipse(ci, pe, Vector2(7.5, 2.4) * u, Color(0, 0, 0, 0.28))
	var partes: Array = []
	if vestimenta == "capuz":
		partes.append([-6, -25 - b, 3, 8, tronco_sombra, true])
	if cabelo == 1:
		partes.append([-6, -26 - b, 4, 9, cor_cabelo.darkened(0.15), true])
	partes.append([-3 - passo, -8, 3, 6, calca.darkened(0.18), true])
	partes.append([-3 - passo, -2, 4, 2, sapato, true])
	partes.append([-6, -16 - b + braco, 2, 7, pele_sombra if braco_nu else tronco_sombra, true])
	partes.append([-6, -9 - b + braco, 2, 2, pele_sombra, true])
	partes.append([passo, -8, 3, 6, calca, true])
	partes.append([passo, -2, 4, 2, sapato, true])
	var altura_tronco := 13 if vestimenta == "jaleco" else 10
	partes.append([-4, -17 - b, 8, altura_tronco, tronco, true])
	partes.append([-4, -17 - b, 2, altura_tronco, tronco_sombra, false])
	if vestimenta == "":
		match estilo_roupa:
			1:
				partes.append([-1, -17 - b, 3, 1, Color("f8fafc"), false])
				partes.append([1, -15 - b, 1, 1, tronco.lightened(0.4), false])
				partes.append([1, -12 - b, 1, 1, tronco.lightened(0.4), false])
			2:
				partes.append([-3, -17 - b, 1, 2, pele, false])
				partes.append([2, -17 - b, 1, 2, pele, false])
			_:
				partes.append([-1, -17 - b, 3, 1, pele_sombra, false])
	elif vestimenta == "capuz":
		partes.append([-1, -11 - b, 4, 2, tronco_sombra, false])
		partes.append([1, -16 - b, 1, 3, Color("f8fafc"), false])
	elif vestimenta == "terno":
		partes.append([0, -17 - b, 2, 4, Color("f8fafc"), false])
		partes.append([0, -16 - b, 1, 4, Color("dc2626"), false])
	elif vestimenta == "jaleco":
		partes.append([0, -17 - b, 2, 6, cor_roupa, false])
		partes.append([2, -10 - b, 2, 1, Color("94a3b8"), false])
	partes.append([-1, -18 - b, 2, 1, pele_sombra, false])
	partes.append([-4, -28 - b, 8, 10, pele, true])
	partes.append([-5, -27 - b, 10, 8, pele, true])
	partes.append([5, -24 - b, 1, 2, pele, true])
	partes.append([-4, -24 - b, 2, 2, pele_sombra, false])
	var cor_olho := Color("1b1f2c")
	var boca := pele.darkened(0.45)
	var altura_olho := 1 if piscar else 2
	match olhar:
		1:
			partes.append([1, -24 - b, 1, 1, cor_olho, false])
			partes.append([3, -24 - b, 1, 1, cor_olho, false])
			partes.append([1, -22 - b, 1, 1, boca, false])
			partes.append([2, -21 - b, 2, 1, boca, false])
			partes.append([3, -22 - b, 2, 1, Color(1, 0.45, 0.45, 0.55), false])
		2:
			partes.append([1, -26 - b, 2, 1, cor_cabelo.darkened(0.2), false])
			partes.append([3, -26 - b, 2, 1, cor_cabelo.darkened(0.2), false])
			partes.append([1, -24 - b, 1, altura_olho, cor_olho, false])
			partes.append([3, -24 - b, 1, altura_olho, cor_olho, false])
			partes.append([2, -21 - b, 2, 1, boca, false])
		_:
			partes.append([1, -24 - b, 1, altura_olho, cor_olho, false])
			partes.append([3, -24 - b, 1, altura_olho, cor_olho, false])
			partes.append([2, -21 - b, 2, 1, boca, false])
	var brilho := cor_cabelo.lightened(0.28)
	match cabelo:
		0:
			partes.append([-5, -29 - b, 10, 3, cor_cabelo, true])
			partes.append([-5, -26 - b, 3, 3, cor_cabelo, true])
			partes.append([2, -26 - b, 3, 1, cor_cabelo, false])
			partes.append([-1, -29 - b, 3, 1, brilho, false])
		1:
			partes.append([-5, -29 - b, 10, 3, cor_cabelo, true])
			partes.append([-5, -26 - b, 3, 5, cor_cabelo, false])
			partes.append([3, -26 - b, 2, 2, cor_cabelo, false])
			partes.append([-1, -29 - b, 3, 1, brilho, false])
		2:
			partes.append([-2, -32 - b, 4, 4, cor_cabelo, true])
			partes.append([-5, -28 - b, 3, 3, cor_cabelo.darkened(0.35), false])
			partes.append([-1, -32 - b, 1, 2, brilho, false])
		3:
			partes.append([-6, -31 - b, 12, 4, cor_cabelo, true])
			partes.append([-7, -28 - b, 4, 6, cor_cabelo, true])
			partes.append([-4, -32 - b, 3, 1, cor_cabelo, true])
			partes.append([1, -32 - b, 3, 1, cor_cabelo, true])
			partes.append([4, -27 - b, 2, 1, cor_cabelo, false])
			partes.append([-2, -31 - b, 3, 1, brilho, false])
		4:
			partes.append([-5, -33 - b, 4, 4, cor_cabelo, true])
			partes.append([-5, -29 - b, 10, 3, cor_cabelo, true])
			partes.append([-5, -26 - b, 3, 3, cor_cabelo, true])
			partes.append([2, -26 - b, 2, 1, cor_cabelo, false])
			partes.append([0, -29 - b, 3, 1, brilho, false])
		_:
			partes.append([0, -28 - b, 2, 1, pele.lightened(0.3), false])
	match chapeu:
		"bone":
			partes.append([-5, -31 - b, 10, 4, Color("2563eb"), true])
			partes.append([4, -28 - b, 4, 1, Color("1d4ed8"), true])
			partes.append([-1, -31 - b, 3, 1, Color("60a5fa"), false])
		"gorro":
			partes.append([-1, -34 - b, 2, 2, Color("f8fafc"), true])
			partes.append([-5, -32 - b, 10, 4, Color("dc2626"), true])
			partes.append([-5, -28 - b, 10, 1, Color("f8fafc"), true])
	match acessorio:
		"oculos_hacker":
			partes.append([0, -25 - b, 5, 2, Color("0f172a"), false])
			partes.append([-2, -25 - b, 2, 1, Color("0f172a"), false])
			partes.append([3, -25 - b, 1, 1, Color("22c55e"), false])
			partes.append([1, -25 - b, 1, 1, Color("22c55e"), false])
		"headset":
			partes.append([-4, -30 - b, 8, 1, Color("111827"), true])
			partes.append([-3, -25 - b, 2, 3, Color("111827"), true])
			partes.append([-1, -21 - b, 4, 1, Color("111827"), false])
			partes.append([3, -21 - b, 1, 1, Color("ef4444"), false])
	partes.append([4, -16 - b - braco, 2, 7, pele if braco_nu else manga, true])
	if vestimenta == "" and estilo_roupa == 0:
		partes.append([4, -13 - b - braco, 2, 4, pele, false])
	partes.append([4, -9 - b - braco, 2, 2, pele, true])
	pintar_partes(ci, pe, u, partes, direcao)


static func semicirculo(c: Vector2, r: float, de: float, ate: float) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	for k in 17:
		var a := lerpf(de, ate, k / 16.0)
		pontos.append(c + Vector2(cos(a), sin(a)) * r)
	return pontos


static func pet(ci: CanvasItem, pe: Vector2, tipo: String, tempo: float, direcao := 1, escala := 1.0) -> void:
	var u := 1.6 * escala
	var pulo := roundf(absf(sin(tempo * 9.0)) * 1.5)
	elipse(ci, pe, Vector2(5, 1.8) * u, Color(0, 0, 0, 0.25))
	var partes: Array = []
	if tipo == "pet_gato":
		var cor := Color("94a3b8")
		var rabo := roundf(sin(tempo * 5.0))
		partes.append([-6, -9 - pulo + rabo, 2, 4, cor.darkened(0.15), true])
		partes.append([-5, -6 - pulo, 8, 4, cor, true])
		partes.append([-4, -2 - pulo, 2, 2, cor.darkened(0.15), true])
		partes.append([1, -2 - pulo, 2, 2, cor.darkened(0.15), true])
		partes.append([1, -10 - pulo, 5, 5, cor, true])
		partes.append([1, -11 - pulo, 1, 1, cor, true])
		partes.append([5, -11 - pulo, 1, 1, cor, true])
		partes.append([-3, -6 - pulo, 3, 1, cor.darkened(0.25), false])
		partes.append([3, -8 - pulo, 1, 1, Color("22c55e"), false])
		partes.append([5, -8 - pulo, 1, 1, Color("22c55e"), false])
		partes.append([4, -6 - pulo, 1, 1, Color("f9a8d4"), false])
	else:
		var cor2 := Color("22d3ee")
		partes.append([0, -15 - pulo, 1, 3, Color("94a3b8"), false])
		partes.append([-1, -16 - pulo, 3, 1, Color("ef4444"), true])
		partes.append([-4, -12 - pulo, 8, 6, cor2, true])
		partes.append([-3, -6 - pulo, 6, 3, cor2.darkened(0.25), true])
		partes.append([-3, -2 - pulo, 2, 2, Color("334155"), true])
		partes.append([1, -2 - pulo, 2, 2, Color("334155"), true])
		partes.append([0, -10 - pulo, 1, 2, Color("0f172a"), false])
		partes.append([2, -10 - pulo, 1, 2, Color("0f172a"), false])
	pintar_partes(ci, pe, u, partes, direcao)


static func palco(ci: CanvasItem, r: Rect2, raio := 18) -> void:
	var parede := Color("b7cbe0")
	var piso := Color("e4d2ab")
	caixa(ci, r, parede, raio)
	for k in int(r.size.x / 24.0):
		ci.draw_rect(Rect2(r.position.x + 12 + k * 24, r.position.y + raio, 2, r.size.y * 0.62 - raio), Color(1, 1, 1, 0.12))
	var y_chao := r.position.y + r.size.y * 0.62
	var janela := Rect2(r.position.x + r.size.x * 0.62, r.position.y + r.size.y * 0.12, r.size.x * 0.26, r.size.y * 0.24)
	ci.draw_rect(janela.grow(3), Color("8aa3bb"))
	ci.draw_rect(janela, Color("dbeafe"))
	ci.draw_rect(Rect2(janela.position + Vector2(janela.size.x * 0.5 - 1, 0), Vector2(3, janela.size.y)), Color("8aa3bb"))
	ci.draw_rect(Rect2(janela.position + Vector2(0, janela.size.y * 0.5 - 1), Vector2(janela.size.x, 3)), Color("8aa3bb"))
	var chao := Rect2(r.position.x, y_chao, r.size.x, r.end.y - y_chao)
	caixa(ci, chao, piso, raio)
	ci.draw_rect(Rect2(chao.position, Vector2(chao.size.x, minf(raio, chao.size.y))), piso)
	var esquerda := r.position.x
	var direita := r.end.x
	for k in range(-12, 13):
		var x0 := r.position.x + r.size.x * 0.5 + k * 44.0
		for sentido in [1.0, -1.0]:
			var a := Vector2(x0, y_chao)
			var b := Vector2(x0 + sentido * 2.0 * chao.size.y, chao.end.y)
			if b.x > direita:
				b = a.lerp(b, (direita - a.x) / (b.x - a.x))
			if b.x < esquerda:
				b = a.lerp(b, (esquerda - a.x) / (b.x - a.x))
			if a.x < esquerda or a.x > direita:
				continue
			ci.draw_line(a, b, piso.darkened(0.12), 1.0)
	ci.draw_rect(Rect2(r.position.x, y_chao - 6, r.size.x, 6), Color("8aa3bb"))
