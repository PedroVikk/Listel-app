# Roadmap — WishNesita

## MVP — v1 (Foco atual)

### Base do Projeto
- [ ] Estrutura de pastas por features
- [ ] Arquitetura definida (Riverpod + Clean/Feature-first)
- [ ] Entidades modeladas
- [ ] Persistência local configurada (Hive/Isar)
- [ ] Roteamento com go_router
- [ ] Tema dinâmico (ThemeSettings)

### Feature: Collections (Pastas/Coleções)
- [ ] Listar coleções na Home
- [ ] Criar coleção
- [ ] Editar coleção (nome, cor/ícone)
- [ ] Excluir coleção

### Feature: Items (Produtos)
- [ ] Listar itens de uma coleção
- [ ] Detalhe do item
- [ ] Criar item manualmente (com foto)
- [ ] Editar item
- [ ] Excluir item
- [ ] Marcar como comprado / pendente
- [ ] Ordenar por preço

### Feature: Share Intent (Recebimento Externo)
- [ ] Configurar receive_sharing_intent no Android
- [ ] Fluxo de recebimento: parse URL, nome, imagem, preço, loja
- [ ] Tela de confirmação antes de salvar item recebido

### Feature: Theme Settings (Customização)
- [ ] Tela de configurações de tema
- [ ] Seletor de cor principal
- [ ] Aplicar tema em tempo real nos componentes principais

---

## v2 — Lista Compartilhada em Tempo Real (próxima feature)

_Ver guia completo: [SHARED_LIST_FEATURE.md](./SHARED_LIST_FEATURE.md)_

### Fase 1 — Supabase + Auth
- [ ] Adicionar `supabase_flutter` + `app_links` ao pubspec
- [ ] `SupabaseService` singleton + `Supabase.initialize()` em main
- [ ] Schema SQL no Supabase (profiles, shared_collections, collection_members, shared_items + RLS)
- [ ] Módulo `features/auth/` completo (LoginPage, AuthRepository, authStateProvider)
- [ ] Rota `/auth/login` + redirect no go_router

### Fase 2 — Extensão de Entidades (non-breaking)
- [ ] `Collection` + `isShared`, `remoteId`, `inviteCode`
- [ ] `SavedItem` + `addedBy`, `purchasedBy`
- [ ] Atualizar models Isar + rodar build_runner

### Fase 3 — Repositórios Remotos
- [ ] `RemoteCollectionsRepositoryImpl` (Supabase Realtime)
- [ ] `RemoteItemsRepositoryImpl` (Postgres Changes stream)
- [ ] `SharingRepository` + implementação Supabase

### Fase 4 — Provider Wiring + UI
- [ ] `collectionScopeProvider` (roteamento local vs remoto)
- [ ] `HomePage` com seção de listas compartilhadas
- [ ] Módulo `features/sharing/` (4 páginas: create, invite, join, members)
- [ ] Novas rotas no router

### Fase 5 — Fluxo de Convite por Deep Link
- [ ] Scheme `wishnesita://` no AndroidManifest
- [ ] Handler de cold/hot start com `app_links`
- [ ] `JoinCollectionPage` com auto-submit por query param

### Fase 6 — UX em Tempo Real (polish)
- [ ] Banner de offline
- [ ] Atualizações otimistas no toggleStatus
- [ ] Badge "Adicionado por X" nos itens

### Fase 7 — Configurações de Conta
- [ ] Seção de conta na SettingsPage
- [ ] Botão "Excluir conta" (Edge Function — obrigatório App Store)

---

## v2.1 — Novas Formas de Adicionar Item

### Task 17 — Escanear Print (OCR)
_Ver guia completo: [task_17_print_scanner.md](./task_17_print_scanner.md)_

- [ ] Adicionar `google_mlkit_text_recognition` ao pubspec + verificar minSdkVersion 21
- [ ] Criar `PrintScannerService` (OCR + extração de nome e preço)
- [ ] Atualizar `CreateItemPage` com opção "Escanear print" + loading + pré-preenchimento

---

## v3 — Notificações e Backend Avançado

- [ ] Compartilhar pasta com amigos (link ou QR code)
- [ ] Lembretes e notificações (ex: "você tem X itens pendentes")
- [ ] Notificação de queda de preço (requer backend)
- [ ] Backup e restauração
- [ ] Detecção automática de metadados de produto (scraping / OpenGraph)
