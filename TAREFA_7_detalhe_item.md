---
tela: Detalhe do Item
modulo: items
prioridade: Alta
status: ⏳ Planejado
last_updated: 2026-04-17
---

# TAREFA 7 — Item Detail Page (Completo)

**Status:** ⏳ Planejado | Depende de TAREFA 6

**Descrição visual:**
Detalhe completo do item com design moderno. Exibe imagem grande (ou placeholder), nome, preço, loja, observações, link (clicável), toggle comprado/pendente, botões de editar e deletar. Seção de "Adicionado por" em listas compartilhadas.

Ref: `Telas novas Listel/detalhe_do_item/screen.png`

---

## O que fazer

### **Refactor de item_detail_page.dart**

**Layout:**
1. **Header com imagem:**
   - Imagem em full width (Hero animation ao voltar)
   - Sobreposição: AppBar translúcido com botões (editar, deletar, compartilhar)

2. **Content card:**
   - Nome do item (headline style)
   - Preço em destaque (título primária)
   - Loja/source (badge ou chip)
   - Status: Toggle "Pendente / Comprado" (colorido conforme status)
   - Link: Clicável, com ícone de seta externa
   - Observações: Texto descriptivo
   - Badge "Adicionado por [nome]" (se lista compartilhada)

3. **Action buttons:**
   - Editar (pencil icon)
   - Deletar com confirmação (trash icon, vermelho)
   - Buscar mais barato (existing feature)

4. **Share section:**
   - Botão "Compartilhar item" → share intent com texto formatado

**Estados:**
- Loading (skeleton)
- Carregado (conteúdo completo)
- Error (retry)
- Deleted (pop e volta ao detalhe da coleção)

### **Mudanças no domínio**

Já existentes: `addedBy`, `purchasedBy` em `SavedItem`.

### **UI Details**

- **Status toggle:** Circular button ou switch com cores (`primary` = comprado, `outlineVariant` = pendente)
- **Link clicável:** Detecta protocolo (http/https) e abre em navegador
- **Deletar:** AlertDialog de confirmação antes de deletar
- **Hero animation:** Imagem do detalhe → card na lista (smooth transition)

### **Testes**

- [ ] Widget test — renderiza conteúdo completo
- [ ] Manual — link abre navegador
- [ ] Manual — toggle status funciona
- [ ] Manual — delete com confirmação funciona
- [ ] Manual — editar navega para edit page

### **Arquivos a modificar**

**Modificar:**
- `lib/features/items/presentation/pages/item_detail_page.dart` — refactor visual

---

## 🔧 Notas técnicas

- **Hero animation:** Envolver imagem em `Hero` com tag `'item-${item.id}'`
- **Link parsing:** `Uri.parse()` e `url_launcher.launchUrl()`
- **Status toggle:** Chamar `itemsNotifier.toggleStatus(item.id)` e esperar stream atualizar
- **Share intent:** Usar `share_plus` com texto formatado

---

## ✅ Checklist de Conclusão

- [ ] Imagem renderizada com Hero
- [ ] Conteúdo completo exibido
- [ ] Status toggle funciona
- [ ] Link é clicável
- [ ] Editar navega
- [ ] Deletar com confirmação
- [ ] Compartilhar funciona
- [ ] Design segue screenshot

