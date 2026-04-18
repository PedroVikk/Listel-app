---
tela: Listel — Home Redesenhada
modulo: collections
prioridade: Alta
status: ⏳ Planejado
last_updated: 2026-04-17
---

# TAREFA 5 — Home Page Redesenhada (Listel Soft Modern)

**Status:** ⏳ Planejado | Depende de TAREFA 1

**Descrição visual:**
Redesign moderno da home page. Exibe grid de coleções (locais) e seção de listas compartilhadas (se autenticado). FAB duplo: criar lista local ou compartilhada. Search bar no AppBar. Design soft modern com cores dinâmicas.

Ref: `Telas novas Listel/liste_soft_modern/screen.png`

---

## O que fazer

### **Mudanças na entidade Collection**

Já implementado em shared_list_feature — `isShared`, `remoteId`, `inviteCode`.

### **Providers**

Adicionar em `lib/features/collections/presentation/providers/collections_provider.dart`:
```dart
// Separar coleções locais vs compartilhadas
final localCollectionsProvider = StreamProvider((ref) {
  return ref.watch(collectionsStreamProvider)
      .whenData((collections) => collections.where((c) => !c.isShared).toList());
});

final sharedCollectionsProvider = StreamProvider((ref) {
  return ref.watch(collectionsStreamProvider)
      .whenData((collections) => collections.where((c) => c.isShared).toList());
});
```

### **Page — Refactor de home_page.dart**

**AppBar:**
- Logo/nome "Listel" no topo
- Search icon → navega para `/search`
- Settings icon → navega para `/settings`

**Body:**
1. **Seção "Minhas listas"** — grid de coleções locais (2 colunas)
   - Reutilizar `_CollectionCard` existente ou refatorar para match design
   - Card com imagem de capa / emoji fallback
   - Gradiente inferior + texto branco

2. **Seção "Compartilhadas"** (se `sharedCollections.isNotEmpty`)
   - Mesmo layout de grid
   - Badge/indicador "Compartilhada"
   - Mostrar owner/membros (ícones mini)

3. **FAB duplo** (speed dial ou menu):
   - Opção 1: "Nova lista" → `CreateEditCollectionPage`
   - Opção 2: "Nova lista compartilhada" → requer auth → `CreateSharedCollectionPage`

4. **Empty state:**
   - Se sem coleções: ilustração + botão CTA "Criar primeira lista"

### **Estados de loading/error**

- `localCollections.isLoading` → shimmer skeleton
- `sharedCollections.isLoading` → shimmer
- Erro de rede → retry button

### **Testes**

- [ ] Widget test — renderiza grid de coleções
- [ ] Widget test — seção compartilhadas aparece/desaparece corretamente
- [ ] Manual — tap em card abre detalhe
- [ ] Manual — FAB abre menu corretamente
- [ ] Manual — search icon navega para search page

### **Arquivos a criar/modificar**

**Modificar:**
- `lib/features/collections/presentation/pages/home_page.dart` — refactor visual

**Criar (opcional):**
- `lib/features/collections/presentation/widgets/collection_card.dart` — extrair card para reuso

---

## 🔧 Notas técnicas

- **Reutilizar `_CollectionCard`:** Já existe em home_page; extrair para componente separado se necessário
- **Shared collections:** Virão de `RemoteCollectionsRepositoryImpl` via Supabase (implementado em TAREFA 1 de shared_list)
- **Imagem de capa:** Campo `coverImagePath` já existe em Collection — mostrar `Image.file` ou emoji fallback

---

## ✅ Checklist de Conclusão

- [ ] AppBar com search e settings
- [ ] Grid de coleções locais renderizado
- [ ] Seção compartilhadas aparece/desaparece
- [ ] FAB duplo funciona
- [ ] Empty state tratado
- [ ] Loading states exibidos
- [ ] Tap em card abre detalhe
- [ ] Search icon funciona
- [ ] Design segue screenshot

