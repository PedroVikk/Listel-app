# WishNesita

**Vision:** App mobile Flutter que centraliza produtos desejados de diversas lojas online (Shopee, Shein, Mercado Livre etc.) em um só lugar, organizados em coleções personalizadas.
**For:** Usuários que compram em múltiplas lojas online e perdem o controle dos produtos salvos em vários carrinhos e apps.
**Solves:** Fragmentação de wishlists — produtos espalhados em múltiplas plataformas sem visibilidade unificada, preços ou status de compra.

## Goals

- Centralizar produtos desejados em um app com recebimento via compartilhamento externo (share intent Android)
- Oferecer organização por coleções/pastas com UX moderna e fluida, similar ao Pinterest
- Permitir customização de tema para aumentar engajamento e identidade pessoal do usuário

## Tech Stack

**Core:**

- Framework: Flutter 3.x
- Language: Dart 3.x
- Persistence: Hive ou Isar (local, NoSQL, offline-first)
- State Management: Riverpod (ou BLoC — decidir na fase de arquitetura)

**Key dependencies:**

- `flutter_riverpod` + `riverpod_annotation` — gerenciamento de estado
- `isar` + `isar_flutter_libs` — persistência local (offline-first)
- `supabase_flutter` — preparado para integração futura (v2), inativo no MVP
- `receive_sharing_intent` — recebimento de compartilhamento externo (share intent Android)
- `flutter_local_notifications` — notificações locais
- `cached_network_image` — cache de imagens de produtos
- `go_router` — navegação declarativa
- `image_picker` — foto manual em itens
- `uuid` — geração de IDs

## Scope

**MVP (v1) inclui:**

- Receber produto via share intent (URL, nome, imagem, preço, loja origem)
- Criar, editar e excluir coleções/pastas
- Criar item manualmente com foto
- Marcar item como comprado (status: pendente / comprado)
- Ordenar itens por preço
- Customização de tema (cor principal da interface)
- Observações opcionais por item
- Persistência local (offline-first)

**Explicitamente fora de escopo (v1):**

- Backend / sincronização na nuvem
- Compartilhar pasta com amigos (v2)
- Lembretes e notificações push (v2)
- Login / autenticação de usuário
- Detecção automática de preço via scraping
- Suporte a iOS (foco inicial: Android APK)

## Constraints

- Timeline: sem deadline definido
- Technical: Android-first, geração de APK; base preparada para backend futuro
- Resources: desenvolvedor solo
