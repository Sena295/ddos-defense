extends Node2D

const Estado := preload("res://estado.gd")
const Visual := preload("res://visual.gd")

var estado
var inicio
var mundo
var operacao
var paineis
var topo
var tela := ""


func _ready() -> void:
	randomize()
	estado = Estado.new()
	estado.carregar()
	estado.notificacao.connect(avisar)
	inicio = criar("res://inicio.gd")
	mundo = criar("res://mundo.gd")
	operacao = criar("res://operacao.gd")
	paineis = criar("res://paineis.gd")
	topo = criar("res://topo.gd")
	ir_para("inicio")


func criar(caminho: String) -> Node2D:
	var no := Node2D.new()
	no.set_script(load(caminho))
	no.principal = self
	add_child(no)
	return no


func ir_para(nome: String) -> void:
	tela = nome
	inicio.visible = nome == "inicio"
	mundo.visible = nome == "mundo"
	operacao.visible = nome == "operacao"


func entrar_jogo(novo: bool) -> void:
	mundo.preparar()
	ir_para("mundo")
	if novo:
		paineis.abrir("intro", {})
	else:
		avisar("Bem-vindo de volta, %s!" % estado.perfil["nome"], Visual.DESTAQUE)


func abrir_painel(tipo: String, dados: Dictionary) -> void:
	paineis.abrir(tipo, dados)


func operar(id: String) -> void:
	if not estado.pode_operar(id):
		avisar("Você ainda não pode operar essa empresa", Visual.CREDITOS)
		return
	operacao.iniciar(id)
	ir_para("operacao")


func voltar_mundo() -> void:
	estado.salvar()
	ir_para("mundo")


func sair_conta() -> void:
	if tela == "mundo":
		mundo.guardar_posicao()
	estado.sair()
	topo.avisos = []
	paineis.fechar()
	ir_para("inicio")
	inicio.mostrar()


func abrir_licao(id: String) -> void:
	topo.licao = id
	estado.ler_licao(id)


func licao_aberta() -> bool:
	return topo.licao != ""


func modal_aberto() -> bool:
	return licao_aberta() or paineis.aberto()


func avisar(texto: String, cor: Color, licao := "") -> void:
	topo.avisar(texto, cor, licao)


func confete(pos: Vector2, quantidade := 40) -> void:
	topo.confete(pos, quantidade)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if tela == "mundo":
			mundo.guardar_posicao()
		if estado:
			estado.salvar()
