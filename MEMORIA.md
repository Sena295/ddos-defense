# Memória do projeto

## Direção

DDoS Defense é um jogo educativo de administração de sistemas e cibersegurança. O jogador deve entender por que cada decisão funciona, ganhar dinheiro ao operar serviços e usar esse dinheiro para aprender, melhorar a infraestrutura e construir negócios. Os testes de segurança acontecem em sistemas fictícios e autorizados dentro do jogo.

## Estado técnico

- Engine: Godot 4.7.2, GDScript, exportação Web e Windows.
- Projeto local: `D:\AI GAMES\ddos_game`.
- Repositório: `https://github.com/Sena295/ddos-defense`.
- Jogo Web: `https://sena295.github.io/ddos-defense/`.
- Publicação: push em `main` aciona `.github/workflows/publicar.yml` e atualiza Pages e a release Windows.
- Saves: `user://ddos_defense_save.json`, com várias contas locais e código de transferência. Novos campos entram em `padrao()` para preservar saves antigos via `normalizar()`.
- A cidade é desenhada em `mundo.gd`; `estado.gd` mantém as regras e o save; `paineis.gd` desenha e aciona os painéis; `dados.gd` contém os dados de jogo.

## Decisões de produto

- Priorizar desempenho e regras de jogo antes de refazer todos os gráficos.
- Manter empresas fictícias. Usar nomes e logos próprios.
- Permitir uma carreira ativa por vez, sem apagar o progresso das outras.
- Cursos e pentests no Café Dev e no Hub ZeroSec são simulações educativas.
- Mostrar ao iniciante para onde ir e qual recompensa obter.
- Renda de imóveis é paga a cada dia de operação concluído. A interface deve explicar isso claramente.

## Alterações desta rodada

- Filtragem de objetos estáticos da cidade reaproveitada até a câmera mover 24 pixels; margem extra evita objetos aparecendo de repente.
- Mundo para a animação de NPCs e carros enquanto há um painel aberto, mas ainda atualiza a cidade quando uma compra ou construção altera os prédios.
- Novos perfis Web e mobile começam em modo leve (30 FPS, menos NPCs e carros). O jogador pode desligar no Perfil.
- Botão de guia no cartão da missão leva automaticamente ao prédio associado; missão concluída abre a Central para resgate.
- Carreiras Operador de sistemas, Hacker ético e Empreendedor com especialização por atividade e bônus delimitados.
- Café Dev público na cidade com três cursos curtos, pergunta e recompensa única por curso. Cafés construídos pelo jogador também abrem os cursos.

## Pontos a medir

- FPS real e tempo de carregamento em navegador fraco e em celular, antes e depois desta rodada. O limite de 30 FPS por si só não prova redução suficiente de CPU e memória.
- Tamanho da exportação Web e uso de memória do mapa. Aumentar o mapa só depois de resolver a densidade dos terrenos vazios.
- Balanceamento do dinheiro com bônus de carreira, imóveis e cursos em partidas longas.
- Uso de tela de toque e navegação por teclado nos novos painéis.

## Contratos do Hub ZeroSec

- Três empresas fictícias aceitam propostas de auditoria: MercadoNet, NexoMall e VoaJá. As três faixas pagam R$ 500 mil, R$ 1,5 milhão e R$ 5 milhões. Exigem respectivamente 3, 4 e 5 códigos em 36, 25 e 16 segundos.
- O contrato é uma simulação autorizada dentro do jogo. Ao aceitar, a empresa consome a tentativa do dia. Uma vitória paga uma vez por empresa; falha libera outra tentativa apenas no dia seguinte. O estado persiste no save, e saves antigos ganham os campos novos em `normalizar()`.
- O relatório associa o risco fictício à defesa: Rate Limit, MFA, Cache e Load Balancer. A missão Consultor de segurança e a especialização Hacker ético progridem ao entregar relatórios.
- Verificação da etapa: 156 testes integrados aprovados localmente e no CI, sem erros de script; as telas de propostas, desafio crítico e relatório foram gravadas no Godot e inspecionadas em 1280 × 720.
- Código publicado no commit `225f7b8328af6db0cafd730b9fe4230b7a2211d5`. Workflow de exportação `38976891504` e implantação do Pages `38976983776` concluídos. A release Windows aponta para esse commit.
- Teste no Chrome da versão publicada: cadastro, cidade, carreira, Café Dev, Arena CTF, Hub ZeroSec, proposta básica e início da matriz. Zero erros de console. Capturas em `C:\Users\carlo\AppData\Local\Temp\claude\D--AI-GAMES\323be71e-d1f0-49d8-a408-349b76bc165f\scratchpad\e2e_auditoria_result`.

## Cidade e imóveis — trabalho em andamento

- 12 dos 24 lotes comerciais do Bairro Sul e Distrito Neon passam a começar ocupados por lojas, coworkings, escolas e pequenos data centers. Os nomes são fictícios. O mapa continua 64 × 44 até haver conteúdo e medida de desempenho para uma expansão.
- Prédios prontos custam R$ 14–42 milhões. Depois da compra, rendem 75% mais aluguel que a construção básica equivalente; a renda só entra depois de operar um dia. A interface mostra custo, aluguel e prazo aproximado de retorno. O jogador ainda pode comprar terrenos vazios e construir neles.
- `imoveis_adquiridos` identifica prédios prontos no save, mantém o bônus de localização e calcula a devolução de 50% do preço pago ao demolir. Saves antigos recebem lista vazia, preservando terrenos construídos anteriormente.
- A demolição pede confirmação e informa a devolução exata. A suíte local passou em 169 verificações, incluindo interação pela porta, compra pela interface, demolição, save e caminho até as portas. O desenho foi gravado e inspecionado em 1280 × 720; o mapa continuou legível com prédios e terrenos livres.
- Ainda é preciso publicar e verificar esta etapa no navegador; as capturas locais estão em `scratchpad/imoveis_final_*.png` no diretório temporário da conversa.

## Validação da etapa 1

- Commit de código: `7f772ff88eb95ab29c8eb605c2665e54c3563d7f`.
- Suíte versionada em `tests/testes_integracao.gd`: 141 verificações, nenhuma falha no Windows e no GitHub Actions.
- Workflow `38975277557`: exportação Web e Windows, teste e publicação concluídos. Implantação do Pages `38975372666` concluída.
- Release Windows `ultima-versao` aponta para o mesmo commit.
- Teste no Chrome da versão publicada: cadastro, guia até Central de Missões, troca para Hacker ético, curso do Café Dev e 3 perguntas da Arena CTF. Nenhum erro de console. O teste usa conta temporária em perfil isolado do navegador.
- Capturas temporárias: `C:\Users\carlo\AppData\Local\Temp\claude\D--AI-GAMES\323be71e-d1f0-49d8-a408-349b76bc165f\scratchpad\e2e_codex_result`.
- Ainda não há medida em computador fraco ou celular real. A etapa 1 reduz trabalho e liga o modo leve, mas não comprova que o desempenho alvo foi alcançado nesses aparelhos.
