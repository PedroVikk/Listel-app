---
tela: Detalhe do Item
modulo: items
prioridade: Alta
status: ⏳ Planejado
---

# TAREFA 7 — Item Detail Page (Completo)

Detalhe completo do item com design moderno. Exibe imagem grande, nome, preço, loja, observações, link (clicável), toggle comprado/pendente, botões de editar e deletar. Seção "Adicionado por" em listas compartilhadas.

Ref: `screen.png` (nesta pasta) | Depende: TAREFA 6

## O que fazer

### **Refactor de item_detail_page.dart**

**Layout:**
1. **Header com imagem:**
   - Imagem em full width (Hero animation ao voltar)
   - AppBar translúcido com botões (editar, deletar, compartilhar)

2. **Content card:**
   - Nome (headline style)
   - Preço em destaque
   - Loja/source (badge)
   - Status: Toggle "Pendente / Comprado" (colorido)
   - Link: Clicável com ícone seta
   - Observações: Texto descritivo
   - Badge "Adicionado por [nome]" (se lista compartilhada)

3. **Action buttons:**
   - Editar (pencil icon)
   - Deletar (trash icon, vermelho)
   - Buscar mais barato (existing feature)

4. **Share section:**
   - Botão "Compartilhar item" → share intent

**Estados:**
- Loading (skeleton)
- Carregado
- Error (retry)
- Deleted (pop)

### **UI Details**

- **Status toggle:** Circular button ou switch com cores
- **Link clicável:** Detecta protocolo e abre navegador
- **Deletar:** AlertDialog de confirmação
- **Hero animation:** Imagem → card na lista

### **Testes**

- [ ] Widget test — renderiza conteúdo completo
- [ ] Manual — link abre navegador
- [ ] Manual — toggle status funciona
- [ ] Manual — delete funciona
- [ ] Manual — editar navega

### **Arquivos a modificar**

**Modificar:**
- `lib/features/items/presentation/pages/item_detail_page.dart` — refactor visual

## ✅ Checklist de Conclusão

- [ ] Imagem com Hero
- [ ] Conteúdo completo exibido
- [ ] Status toggle funciona
- [ ] Link é clicável
- [ ] Editar navega
- [ ] Deletar com confirmação
- [ ] Compartilhar funciona
- [ ] Design segue screenshot
