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

## v2 — Expansão Social e Notificações

- [ ] Compartilhar pasta com amigos (link ou QR code)
- [ ] Lembretes e notificações (ex: "você tem X itens pendentes")
- [ ] Notificação de queda de preço (requer backend)

## v3 — Backend e Sincronização

- [ ] Autenticação de usuário
- [ ] Sincronização na nuvem
- [ ] Backup e restauração
- [ ] Detecção automática de metadados de produto (scraping / OpenGraph)
