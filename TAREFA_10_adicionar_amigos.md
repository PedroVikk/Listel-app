---
tela: Adicionar Amigos
modulo: sharing
prioridade: Média
status: ⏳ Planejado
last_updated: 2026-04-17
---

# TAREFA 10 — Add Members Page (Sharing)

**Status:** ⏳ Planejado | Depende de TAREFA 1 (auth) + shared_list_feature

**Descrição visual:**
Página para convidar membros a uma lista compartilhada. Exibe membros atuais, código de convite copiável, opção de gerar novo código, botão de compartilhar via link.

Ref: `Telas novas Listel/adicionar_amigos/screen.png`

---

## O que fazer

### **Nova page — add_members_page.dart**

Já existe em `.specs` mas pode ser refatorada.

**Layout:**

1. **Header:**
   - Título "Convidar amigos"
   - Descrição "Compartilhe o código ou link"

2. **Código de convite:**
   - Display grande (monospace font)
   - Botão "Copiar" (feedback: SnackBar)
   - Botão "Novo código" com confirmação

3. **Link de convite:**
   - Display com protocolo `listel://invite?code=...`
   - Botão "Compartilhar" → share intent
   - Botão "Copiar link"

4. **Membros atuais:**
   - Lista com avatares + nomes
   - Ícone do dono
   - Botão remover (com confirmação)

5. **Empty state:**
   - Se ainda sem membros: "Convide alguém para começar!"

### **Providers**

Usar `membersProvider` da shared_list_feature.

### **Roteamento**

Rotas:
- `/collection/:id/invite` — página de convite
- Pode ser acessada via AppBar button em `collection_detail_page`

### **Testes**

- [ ] Manual — código exibido
- [ ] Manual — botão copiar funciona
- [ ] Manual — botão compartilhar abre share intent
- [ ] Manual — novo código regenera
- [ ] Manual — lista de membros exibida

### **Arquivos a criar/modificar**

**Modificar:**
- `lib/features/sharing/presentation/pages/add_members_page.dart` (já existe, refactor)

---

## 🔧 Notas técnicas

- **Copiar para clipboard:** `Clipboard.setData(ClipboardData(text: code))`
- **Share intent:** `share_plus` com URL `listel://invite?code=...`
- **Membros em tempo real:** Stream do `membersProvider`
- **Remover membro:** RPC no Supabase (apenas dono pode fazer)

---

## ✅ Checklist de Conclusão

- [ ] Código exibido
- [ ] Copiar funciona
- [ ] Novo código regenera
- [ ] Compartilhar funciona
- [ ] Membros listados
- [ ] Remover membro funciona
- [ ] Design segue screenshot

