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
