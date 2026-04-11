# Task 23 — Multi-foto por Item + Carrossel no Modo Vitrine

## Objetivo

Permitir que cada item tenha até **3 fotos**. No modo **Vitrine**, o usuário pode deslizar horizontalmente entre as fotos do item diretamente na grade — sem precisar entrar no detalhe.

---

## Parte 1 — Modelo de dados: múltiplas fotos

### Mudança na entidade `SavedItem`

Adicionar campo para lista de fotos extra (além da foto principal já existente):

```dart
// Campos atuais (não mudar)
final String? imageUrl;        // foto remota principal
final String? localImagePath;  // foto local principal

// Campos novos
final List<String> extraImageUrls;       // fotos remotas extras (URLs Supabase)
final List<String> extraLocalImagePaths; // fotos locais extras (paths do dispositivo)
```

**Regra:** máximo de 3 fotos no total (principal + extras). `extraImageUrls.length + extraLocalImagePaths.length <= 2`.

### Persistência

| Storage | Campo | Tipo |
|---|---|---|
| Isar (local) | `extraLocalImagePaths` | `List<String>` |
| Supabase (remoto) | `extra_image_urls` | `text[]` (array PostgreSQL) |

---

## Parte 2 — UX de adição de fotos no formulário

### Tela de criar/editar item

- Substituir o atual seletor de 1 foto por um **row de slots de foto**:

```
[ Foto 1 ]  [ Foto 2 ]  [ Foto 3 ]
  (câmera)   (+ vazio)  (+ vazio)
```

- Cada slot:
  - Vazio → mostra ícone `+` cinza com borda tracejada
  - Preenchido → mostra miniatura com botão `×` para remover
  - Toque → abre seletor (câmera / galeria), mesmo fluxo atual
- Primeiro slot é sempre a **foto principal** (já usada no resto do app)
- Slots 2 e 3 são as **fotos extras**
- Reordenar não é necessário nesta fase

### Validação

- Máximo de 3 fotos — botão `+` some quando 3 fotos já foram adicionadas
- Cada foto passa pelo mesmo fluxo de crop já existente

---

## Parte 3 — Modo Vitrine: carrossel inline

### Comportamento

- Cada tile no grid Vitrine vira um **`PageView` horizontal** quando o item tem mais de 1 foto
- O usuário passa o dedo horizontalmente **dentro do tile** para ver as fotos
- Indicador de página (dots) discreto no rodapé do tile

### Layout do tile com carrossel

```
┌─────────────────┐
│                 │  ← foto 1 (swipe → foto 2)
│   [imagem]      │
│                 │
│   ● ○ ○         │  ← dots indicator (só aparece se > 1 foto)
└─────────────────┘
```

- Se o item tem apenas 1 foto (comportamento atual), **nenhum carrossel** — tile normal
- Toque no tile ainda navega para o detalhe do item
- Swipe horizontal **dentro do tile** troca a foto (não navega)
- O carrossel usa `PageController` local (não precisa persistir qual foto está visível)

### Conflito tap vs swipe

- `PageView` dentro de um `GestureDetector`: usar `HitTestBehavior.translucent` e um `Listener` para detectar intenção de swipe vs tap
- Alternativa mais simples: usar `PageView` com `physics: ClampingScrollPhysics()` e envolver em `GestureDetector` com `onTap` no stack, passando o evento apenas se não houve drag

---

## Parte 4 — Detalhe do item

- A foto hero existente vira um **`PageView` com as 3 fotos** (mesma UX de apps de e-commerce)
- Dots indicator abaixo da imagem hero
- Não é requisito desta task — pode ser feito em task separada — **mas deve ser considerado no modelo de dados**

---

## Arquivos envolvidos

| Arquivo | Alteração |
|---|---|
| `lib/features/items/domain/entities/saved_item.dart` | Adicionar `extraImageUrls`, `extraLocalImagePaths` |
| `lib/features/items/data/models/saved_item_isar.dart` | Adicionar campos Isar |
| `lib/features/items/data/models/saved_item_remote.dart` | Mapear `extra_image_urls` do Supabase |
| `lib/features/items/presentation/pages/create_item_page.dart` | Row de 3 slots de foto |
| `lib/features/items/presentation/pages/edit_item_page.dart` | Row de 3 slots de foto |
| `lib/features/collections/presentation/pages/collection_detail_page.dart` | Tile Vitrine com PageView |
| Supabase migration | Adicionar coluna `extra_image_urls text[]` na tabela `items` |

---

## Critérios de aceite

- [ ] `SavedItem` suporta até 3 fotos (1 principal + 2 extras)
- [ ] Formulário de criar item mostra row com 3 slots
- [ ] Toque em slot vazio abre seletor de foto (câmera/galeria)
- [ ] Slot preenchido mostra miniatura com botão `×` para remover
- [ ] Ao atingir 3 fotos, não é possível adicionar mais
- [ ] Formulário de editar item carrega fotos existentes nos slots corretos
- [ ] No modo Vitrine, tiles com múltiplas fotos exibem PageView horizontal
- [ ] Swipe dentro do tile troca a foto sem navegar
- [ ] Toque no tile ainda navega para o detalhe do item
- [ ] Dots indicator aparece apenas quando há mais de 1 foto
- [ ] Itens com 1 foto mantêm comportamento atual (sem regressão)

---

## Dependências

- Task 22 (modos de visualização) — **concluída**
- Supabase migration necessária antes de implementar o remote model

## Prioridade

`Alta` — melhora diretamente a experiência visual do modo Vitrine, que é o diferencial da feature.
