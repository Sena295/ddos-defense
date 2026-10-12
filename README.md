# DDoS Defense

Jogo de estratégia e simulação em que você é o CTO de uma grande empresa e precisa montar a arquitetura que mantém os sistemas no ar durante picos de tráfego e ataques. Feito em Godot 4 com GDScript.

**Jogar no navegador:** https://sena295.github.io/ddos-defense/

**Versão Windows:** baixe o zip em [Releases](https://github.com/Sena295/ddos-defense/releases/tag/ultima-versao), extraia e abra `DDoS-Defense.exe`.

## O que tem no jogo

- **8 empresas fictícias** de setores diferentes: e-commerce, marketplace, viagens, delivery, streaming, dois grandes bancos e um banco digital. Cada uma tem um perfil de tráfego, ameaças e datas de pico próprios.
- **Vários sistemas por empresa:** loja, pagamentos, app etc. Novos sistemas chegam nos dias 4 e 8 e você administra todos ao mesmo tempo, em abas.
- **Montagem livre:** posicione componentes numa grade e conecte como quiser, arrastando do círculo de saída até o próximo componente.
- **12 componentes:** CDN, Anti-DDoS, Firewall WAF, CAPTCHA (com o robô guardião que destrói os bots), Rate Limit, Login 2FA, Geo-bloqueio, Load Balancer (Round-robin, Health Check e menor carga), Fila, Cache Redis, Torres de servidor e Auto Scaling.
- **5 tipos de tráfego:** clientes reais, bots de inundação, bots imitadores (camada 7), ladrões de senha (credential stuffing) e robôs copiadores (scraping). Cada filtro é bom contra um tipo diferente.
- **Pressão de verdade:** receita e prejuízo em milhões, torre travada custando dinheiro a cada segundo, multa da LGPD por conta invadida, linha de crédito e falência.
- **Eventos:** Black Friday, Festival 11.11, dia do pagamento, final do campeonato, ataques DDoS e combos a cada 10 dias.
- **Aprendizado:** 21 lições que explicam o porquê de cada componente e conceito, relatório diário com "mandou bem" e "por que deu problema", quiz do conselho valendo dinheiro e elogios quando você toma boas decisões.
- **Perfil local:** cadastro rápido só com apelido e cor, política de privacidade e botão para apagar os dados.

## Controles

| Ação | PC | Celular |
|---|---|---|
| Instalar componente | Clique na paleta e depois numa célula livre | Toque na paleta e depois numa célula |
| Conectar | Arraste do círculo à direita até outro componente | Arraste, ou use o botão Conectar |
| Ver detalhes, melhorar, vender | Clique no componente | Toque no componente |
| Remover conexão | Clique na linha | Toque na linha |
| Mover componente | Arraste o cartão | Arraste o cartão |
| Iniciar o dia | Espaço ou botão | Botão |
| Pausar | P, Esc ou botão | Botão |
| Velocidade 1x/2x | F ou botão | Botão |
| Trocar de sistema | Teclas 1, 2 e 3 ou abas | Abas |

Dica: colocar um componente logo à direita de outro encaixa ele no fluxo automaticamente. No celular, jogue com a tela deitada.

## Privacidade

O jogo não tem servidor e não coleta dados. O apelido e o progresso ficam só no seu dispositivo (armazenamento do navegador ou pasta de dados do usuário). A política completa está dentro do jogo.

Todas as empresas, bancos e marcas do jogo são fictícias e criadas para fins educacionais. Valores e números são simulações simplificadas.

## Rodar o projeto

1. Instale o [Godot 4.7](https://godotengine.org/download).
2. Abra o Godot, clique em Importar e escolha o arquivo `project.godot`.
3. Aperte F5.

## Estrutura

| Arquivo | Conteúdo |
|---|---|
| `dados.gd` | Empresas, componentes, eventos, lições, quiz e política de privacidade |
| `site.gd` | Simulação de um sistema: grafo de componentes, roteamento, filtros, torres, fila e auto scaling |
| `visual.gd` | Desenho: cartões arredondados, ícones, torres, robô e formatação de dinheiro |
| `main.gd` | Telas, economia, dias, relatórios, entrada de mouse, toque e teclado |

## Publicação

A cada push na branch `main`, o GitHub Actions (`.github/workflows/publicar.yml`) exporta o jogo para Web e Windows, publica a versão Web na branch `gh-pages` (GitHub Pages) e atualiza o zip do Windows nas Releases.
