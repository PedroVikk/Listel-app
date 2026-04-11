---
sistema: Listel
versao: 1.0
criado: 2026-04-10
mantenedor: agente-mapeador
instrucoes-para-agentes: |
  Leia APENAS este arquivo primeiro.
  Identifique o domínio da sua tarefa na seção "Domínios".
  Leia somente o(s) arquivo(s) do(s) domínio(s) relevante(s).
  Se a tarefa envolver um processo específico, acesse a pasta regras/ do domínio.
---

# Base de Regras de Negócio — Listel

## O que é este sistema

App Flutter de wishlist: usuário cria coleções de desejos, adiciona itens (manual ou via URL), marca como comprado, busca preços mais baratos e compartilha listas em tempo real com outras pessoas.

## Stack técnica

- **Flutter** (Dart) — mobile Android/iOS
- **Supabase** — banco remoto, auth, Realtime
- **Riverpod** — gerenciamento de estado
- **Isar** — banco local (coleções e itens locais)
- **go_router** — navegação

## Como navegar esta base (instruções para agentes)

| Tipo de tarefa | Leia |
|---|---|
| Criar, editar ou excluir coleção | `dominios/colecoes.md` |
| Criar, editar, mover ou excluir item | `dominios/itens.md` |
| Busca de preço mais barato | `dominios/busca-de-preco.md` |
| Compartilhar lista / código de convite / Realtime | `dominios/listas-compartilhadas.md` |
| Login, perfil, avatar | `dominios/autenticacao.md` |
| Pesquisa global de itens | `dominios/pesquisa-global.md` |
| Qualquer tarefa que envolva dual-mode (local vs remoto) | `dominios/itens.md` + `dominios/listas-compartilhadas.md` |

## Domínios mapeados

| Domínio | Arquivo | Descrição resumida | Status |
|---|---|---|---|
| Coleções | `dominios/colecoes.md` | Criação, edição, exclusão e foto de capa de coleções locais | ✅ Mapeado |
| Itens | `dominios/itens.md` | Criação manual/URL, toggle status, mover entre coleções | ✅ Mapeado |
| Busca de Preço | `dominios/busca-de-preco.md` | Comparação de preços via Mercado Livre e SerpAPI/Google Shopping | ✅ Mapeado |
| Listas Compartilhadas | `dominios/listas-compartilhadas.md` | Compartilhamento em tempo real via Supabase + código de convite | ✅ Mapeado |
| Autenticação | `dominios/autenticacao.md` | Login Supabase, perfil de usuário e avatar | ✅ Mapeado |
| Pesquisa Global | `dominios/pesquisa-global.md` | Busca de itens por nome em todas as coleções | ✅ Mapeado |

## Glossário rápido
> Termos críticos para entender as regras. Definições completas em `glossario.md`.

- **Coleção**: Agrupador de itens de desejo; pode ser local (Isar) ou compartilhada (Supabase)
- **Item**: Produto ou desejo dentro de uma coleção; tem nome, preço, foto, link e status
- **Status**: `pendente` (não comprado) ou `comprado` — toggled pelo usuário
- **Dual-mode repository**: Mesma interface `ItemsRepository` roteando para Isar (local) ou Supabase (compartilhado)
- **isShared**: Flag que determina se uma coleção está no banco remoto ou local
- **Invite code**: Código alfanumérico de 8 chars que permite outro usuário entrar numa lista compartilhada
- **RLS**: Row Level Security do Supabase — políticas que controlam quem vê e modifica quais dados
- **PriceAlternative**: Modelo de resultado de busca de preço com percentual de desconto
- **Fase 1 (preço)**: Busca direta no Mercado Livre (sem chave)
- **Fase 2 (preço)**: Busca no Google Shopping via SerpAPI + Edge Function Supabase

## Dependências entre domínios

- **Itens** depende de **Listas Compartilhadas** para saber se a coleção é local ou remota (dual-mode)
- **Busca de Preço** depende de **Itens** (precisa do nome e preço do item como query)
- **Listas Compartilhadas** depende de **Autenticação** (usuário precisa estar logado para criar/entrar em lista)
- **Pesquisa Global** depende de **Itens** (usa os mesmos repositórios)

## Histórico de atualizações

| Data | Domínio | Alteração |
|---|---|---|
| 2026-04-10 | Todos | Criação inicial da base — 6 domínios mapeados, 2 folhas de regra detalhadas |
