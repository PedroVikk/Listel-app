---
tela: Salvar Produto (Share Intent Flow)
modulo: items
prioridade: Média
status: ⏳ Planejado
last_updated: 2026-04-17
---

# TAREFA 8 — Share Intent → Save Product Flow

**Status:** ⏳ Planejado | Depende de TAREFA 6

**Descrição visual:**
Quando usuário compartilha um link de produto (Amazon, Shopee, etc) para o app, exibe bottom sheet com preview e opções de salvar. Modernização do fluxo existente em `share_received_page.dart`.

Ref: `Telas novas Listel/salvar_produto/screen.png`

---

## O que fazer

### **Refactor de share_received_page.dart**

**Bottom sheet redesenhado:**

1. **Preview do produto:**
   - Imagem (lado esquerdo ou topo)
   - Nome, preço, loja em destaque
   - Meta tags (descrição curta)

2. **Seletor de coleção:**
   - RadioGroup ou DropdownButton
   - Mostra todas as coleções locais
   - Opção "Criar nova coleção" (inline form)

3. **Observações rápidas:**
   - Campo de texto opcional (tamanho, cor, nota pessoal)

4. **Botões:**
   - "Salvar" (primária)
   - "Cancelar" (secundária)

5. **Estados:**
   - Loading (skeleton enquanto extrai metadados)
   - Success (card flutuante "Produto salvo em [coleção]!")
   - Error com retry

### **Comportamento**

- Se share intent vem com URL: auto-preenche preview
- Se múltiplos items compartilhados: queue ou modal única para o primeiro
- Após salvar: feedback positivo (SnackBar ou card flutuante)

### **Roteamento**

Rotas de deep link para share intent já existem; garantir que bottom sheet abre corretamente.

### **Testes**

- [ ] Manual — compartilha link e recebe preview
- [ ] Manual — seleciona coleção e salva
- [ ] Manual — erro de metadados é tratado
- [ ] Manual — feedback positivo após salvar

### **Arquivos a modificar**

**Modificar:**
- `lib/features/share_intent/presentation/pages/share_received_page.dart` — refactor visual

---

## 🔧 Notas técnicas

- **Reuso de código:** Lógica de extração de metadados já existe em `metadata_extractor_service.dart`
- **Queue de múltiplos shares:** Implementação futura; MVP salva um por vez
- **Notificação de sucesso:** Pode ser SnackBar ou card flutuante com undo (deletar item recém-criado)

---

## ✅ Checklist de Conclusão

- [ ] Preview de produto exibido
- [ ] Seletor de coleção funciona
- [ ] Campo de observações visível
- [ ] Salvar funciona
- [ ] Feedback de sucesso exibido
- [ ] Design segue screenshot

