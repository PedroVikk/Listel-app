---
tela: Listel — Home Redesenhada
modulo: collections
prioridade: Alta
status: ✅ Completo
---

# TAREFA 5 — Home Page Redesenhada (Listel Soft Modern)

Redesign moderno da home page. Exibe grid de coleções (locais) e seção de listas compartilhadas (se autenticado). FAB duplo: criar lista local ou compartilhada. Search bar no AppBar. Design soft modern com cores dinâmicas.

Ref: `screen.png` + `DESIGN.md` (nesta pasta) | Depende: TAREFA 1

## O que fazer

### **Providers**

Adicionar em `lib/features/collections/presentation/providers/collections_provider.dart`:
```dart
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
   - Card com imagem de capa / emoji fallback
   - Gradiente inferior + texto branco

2. **Seção "Compartilhadas"** (se `sharedCollections.isNotEmpty`)
   - Mesmo layout de grid
   - Badge/indicador "Compartilhada"
   - Owner/membros

3. **FAB duplo** (speed dial):
   - "Nova lista" → `CreateEditCollectionPage`
   - "Nova lista compartilhada" → `CreateSharedCollectionPage`

4. **Empty state:** Ilustração + botão CTA

### **Estados de loading/error**

- Loading → shimmer skeleton
- Erro → retry button

### **Testes**

- [ ] Widget test — renderiza grid
- [ ] Widget test — seção compartilhadas aparece/desaparece
- [ ] Manual — tap em card abre detalhe
- [ ] Manual — FAB abre menu
- [ ] Manual — search icon funciona

### **Arquivos a modificar**

**Modificar:**
- `lib/features/collections/presentation/pages/home_page.dart` — refactor visual

## ✅ Checklist de Conclusão

- [x] AppBar com search e settings (glassmorphism)
- [x] Grid de coleções renderizado (tonal layering, squircle thumbnails)
- [x] Seção compartilhadas aparece/desaparece
- [x] FAB duplo funciona (mantido o atual por decisão do produto)
- [x] Empty state tratado (editorial, com pill container)
- [x] Loading states exibidos
- [x] Design segue DESIGN.md (Digital Atelier tokens em `AppDesignTokens`)

## Notas de implementação (2026-04-18)

- Adicionado `AppDesignTokens` como `ThemeExtension` em `lib/core/theme/app_theme.dart` — expõe raios (sm/md/lg/xl), `primaryGradient` (135°) e `tintedShadow` (primary 8%, blur 32, y 12).
- Providers `localCollectionsProvider` / `sharedCollectionsProvider` sugeridos na tarefa **não foram criados**: já existem `collectionsStreamProvider` (locais) e `sharedCollectionsStreamProvider` (compartilhadas), seria duplicação.
- AppBar e NavigationBar agora usam glassmorphism (`BackdropFilter` 20px + superfície 70% opaca).
- Cards passaram de "cover com overlay preto" para "white-on-pastel" com thumbnail squircle em cima + label embaixo, seguindo a regra "objects in a tray".
- Fonte mantida (Nunito via google_fonts), conforme pedido do produto.
