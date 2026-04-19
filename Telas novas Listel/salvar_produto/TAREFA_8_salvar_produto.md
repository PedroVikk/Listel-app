---
tela: Salvar Produto (Share Intent Flow)
modulo: items
prioridade: Média
status: ⏳ Planejado
---

# TAREFA 8 — Share Intent → Save Product Flow

Quando usuário compartilha um link de produto (Amazon, Shopee, etc) para o app, exibe bottom sheet com preview e opções de salvar. Modernização do fluxo existente.

Ref: `screen.png` (nesta pasta) | Depende: TAREFA 6

## O que fazer

### **Refactor de share_received_page.dart**

**Bottom sheet redesenhado:**

1. **Preview do produto:**
   - Imagem
   - Nome, preço, loja em destaque
   - Meta tags (descrição curta)

2. **Seletor de coleção:**
   - RadioGroup ou DropdownButton
   - Todas as coleções locais
   - Opção "Criar nova coleção" (inline form)

3. **Observações rápidas:**
   - Campo de texto opcional (tamanho, cor, nota)

4. **Botões:**
   - "Salvar" (primária)
   - "Cancelar" (secundária)

5. **Estados:**
   - Loading (skeleton)
   - Success (card flutuante "Salvo em [coleção]!")
   - Error com retry

### **Comportamento**

- Share com URL: auto-preenche preview
- Feedback positivo após salvar (SnackBar ou card)

### **Testes**

- [ ] Manual — compartilha link e recebe preview
- [ ] Manual — seleciona coleção e salva
- [ ] Manual — erro é tratado
- [ ] Manual — feedback positivo

### **Arquivos a modificar**

**Modificar:**
- `lib/features/share_intent/presentation/pages/share_received_page.dart` — refactor visual

## ✅ Checklist de Conclusão

- [ ] Preview exibido
- [ ] Seletor de coleção funciona
- [ ] Campo de observações visível
- [ ] Salvar funciona
- [ ] Feedback de sucesso
- [ ] Design segue screenshot
