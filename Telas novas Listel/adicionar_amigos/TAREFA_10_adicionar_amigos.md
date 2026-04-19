---
tela: Adicionar Amigos
modulo: sharing
prioridade: Média
status: ⏳ Planejado
---

# TAREFA 10 — Add Members Page (Sharing)

Página para convidar membros a uma lista compartilhada. Exibe membros atuais, código de convite copiável, opção de gerar novo código, botão de compartilhar via link.

Ref: `screen.png` (nesta pasta) | Depende: TAREFA 1 (auth) + shared_list_feature

## O que fazer

### **Page — add_members_page.dart**

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
   - Se sem membros: "Convide alguém para começar!"

### **Roteamento**

Rotas:
- `/collection/:id/invite` — página de convite
- Acessada via AppBar button em `collection_detail_page`

### **Testes**

- [ ] Manual — código exibido
- [ ] Manual — botão copiar funciona
- [ ] Manual — botão compartilhar abre share intent
- [ ] Manual — novo código regenera
- [ ] Manual — lista de membros exibida

### **Arquivos a criar/modificar**

**Modificar:**
- `lib/features/sharing/presentation/pages/add_members_page.dart` — refactor

## ✅ Checklist de Conclusão

- [ ] Código exibido
- [ ] Copiar funciona
- [ ] Novo código regenera
- [ ] Compartilhar funciona
- [ ] Membros listados
- [ ] Remover membro funciona
- [ ] Design segue screenshot
