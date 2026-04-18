---
tela: Adicionar Item Modernizado
modulo: items
prioridade: Alta
status: ⏳ Planejado
last_updated: 2026-04-17
---

# TAREFA 6 — Create/Edit Item Page (Modernizado)

**Status:** ⏳ Planejado | Depende de TAREFA 5

**Descrição visual:**
Redesign moderno de criação/edição de item. Formulário com campos: foto (galeria/câmera/URL), nome, preço, link, observações. Bottom action com "Salvar" e "Cancelar". Design limpo, spacing refinado, validações em tempo real.

Ref: `Telas novas Listel/adicionar_item_modernizado/screen.png`

---

## O que fazer

### **Refactor de create_item_page.dart**

**Campo de foto — melhorias:**
- Aceitar foto de galeria, câmera OU URL
- Pré-visualizar imagem selecionada
- Botão "Remover foto"
- Indicador de tamanho de arquivo

**Form fields:**
- Nome (obrigatório, máx 150 chars, contador visual)
- Preço (opcional, validação de número, máx 12 chars)
- Link (opcional, validação de URL)
- Observações (opcional, máx 500 chars, contador visual)

**Validações em tempo real:**
- Nome vazio = botão "Salvar" desabilitado
- Preço com formato válido (decimais com "," ou ".")
- Link = parse como URL válida

**Layout:**
- AppBar com "Nova item" | "Editar item" (depende se create vs edit)
- Form em SingleChildScrollView
- Foto no topo (full width, aspect ratio 1:1 ou 4:3)
- Campos empilhados
- Bottom action bar com "Salvar" e "Cancelar" (sticky ou floating)

**State machine:**
- Idle (usuário preenchendo)
- Saving (spinner no botão)
- Success (fecha página, volta ao detalhe da coleção)
- Error (SnackBar com mensagem)

### **Roteamento**

Já existe `/collection/:id/item/create`. Para edit, adicionar `/collection/:id/item/:itemId/edit` se não existir.

### **Testes**

- [ ] Widget test — renderiza todos os campos
- [ ] Widget test — contador visual funciona
- [ ] Widget test — botão desabilitado quando inválido
- [ ] Manual — foto de galeria pode ser selecionada
- [ ] Manual — foto de câmera pode ser tirada
- [ ] Manual — validação de preço funciona
- [ ] Manual — save com dados válidos cria/atualiza item

### **Arquivos a modificar**

**Modificar:**
- `lib/features/items/presentation/pages/create_item_page.dart` — refactor visual

---

## 🔧 Notas técnicas

- **Campo de preço:** Aceitar "," ou "." como separador decimal; converter para double ao salvar
- **Foto de URL:** Validar e fazer download síncrono ou assíncrono (depende de performance)
- **Edit mode:** Reusar mesma page; detectar se `itemId` na rota — se presente, carrega item e pré-preenche

---

## ✅ Checklist de Conclusão

- [ ] Campos renderizados
- [ ] Foto pode ser selecionada (galeria/câmera)
- [ ] Validações em tempo real funcionam
- [ ] Contador visual de chars
- [ ] Botão "Salvar" desabilitado quando inválido
- [ ] Save funciona
- [ ] Edit funciona
- [ ] Design segue screenshot

