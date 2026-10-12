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
