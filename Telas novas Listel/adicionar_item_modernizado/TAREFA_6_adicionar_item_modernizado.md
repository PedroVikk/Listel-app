---
tela: Adicionar Item Modernizado
modulo: items
prioridade: Alta
status: ⏳ Planejado
---

# TAREFA 6 — Create/Edit Item Page (Modernizado)

Redesign moderno de criação/edição de item. Formulário com campos: foto (galeria/câmera/URL), nome, preço, link, observações. Bottom action com "Salvar" e "Cancelar". Design limpo, spacing refinado, validações em tempo real.

Ref: `screen.png` (nesta pasta) | Depende: TAREFA 5

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
- Preço com formato válido
- Link = parse como URL válida

**Layout:**
- AppBar com "Nova item" | "Editar item"
- Form em SingleChildScrollView
- Foto no topo (full width)
- Campos empilhados
- Bottom action bar sticky com "Salvar" e "Cancelar"

### **State machine:**
- Idle (preenchendo)
- Saving (spinner)
- Success (fecha página)
- Error (SnackBar)

### **Testes**

- [ ] Widget test — renderiza campos
- [ ] Widget test — contador visual funciona
- [ ] Widget test — botão desabilitado quando inválido
- [ ] Manual — foto de galeria
- [ ] Manual — foto de câmera
- [ ] Manual — validação de preço
- [ ] Manual — save com dados válidos

### **Arquivos a modificar**

**Modificar:**
- `lib/features/items/presentation/pages/create_item_page.dart` — refactor visual

## ✅ Checklist de Conclusão

- [ ] Campos renderizados
- [ ] Foto selecionável
- [ ] Validações funcionam
- [ ] Contador visual de chars
- [ ] Botão desabilitado quando inválido
- [ ] Save funciona
- [ ] Edit funciona
- [ ] Design segue screenshot
