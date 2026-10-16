# Handoff para Claude

Leia `MEMORIA.md` e `ETAPAS.md` antes de editar. O projeto está em `D:\AI GAMES\ddos_game` e publica via push em `main` para `https://github.com/Sena295/ddos-defense`.

## Escopo atual

Esta rodada continua a etapa 2 com contratos negociados de auditoria no Hub ZeroSec, além das otimizações, guia, carreiras e cursos já publicados. Os dados e recompensas estão em `dados.gd` e `estado.gd`; a interface e o minijogo estão em `paineis.gd`; a missão e o guia estão em `dados.gd` e `mundo.gd`.

## Regras para continuar

- Preserve os saves existentes. Campos novos precisam de valor padrão em `estado.gd` e normalização quando tiverem estrutura interna.
- Não amplie o mapa sem povoá-lo e medir desempenho em aparelho fraco.
- Ataques são cenários fictícios de treinamento; não use nomes ou logos reais de empresas.
- O usuário quer que o agente implemente, teste, faça commit e publique. O repositório já tem remote e workflow de publicação.
- Prefira nomes em português, código executável, sem comentários supérfluos e explicações diretas.

## Verificação

O teste integrado está versionado em `tests/testes_integracao.gd`. Ele preserva e restaura o save local e verifica carreira, Café Dev, guia, contratos e os fluxos anteriores. No Windows, execute `godot --headless --path . --fixed-fps 60 -s res://tests/testes_integracao.gd`. Nesta etapa, 156 verificações passaram localmente. O workflow roda esse teste antes da publicação. O Windows local está sem templates Web do Godot 4.7.2; a exportação deve ser verificada no CI e o jogo no navegador após o push.

## Próxima implementação

Depois dos contratos de auditoria, transformar lotes repetidos em imóveis ocupados com compra cara e renda que dê propósito ao dinheiro. Medir desempenho em PC fraco e celular real antes de ampliar o mapa. Registre testes, ganhos e limitações em `MEMORIA.md` e atualize este handoff a cada rodada.

## Estado da publicação

O commit funcional `7f772ff88eb95ab29c8eb605c2665e54c3563d7f` está em `main` e no Pages. A release Windows aponta para ele. O teste no Chrome publicado passou pelos novos fluxos e pela Arena CTF com 0 erros de console. Consulte `MEMORIA.md` para os IDs dos workflows e as capturas. O commit desta atualização documental pode ser visto com `git log -1`.

Ainda faltam compra de edifícios caros, densidade de cidade, mapa maior e revisão visual. Não anuncie essas etapas como prontas. A medição em hardware fraco e celular real também está pendente.
