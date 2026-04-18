---
tela: Configurações
modulo: settings
prioridade: Média
status: ⏳ Planejado
last_updated: 2026-04-17
---

# TAREFA 9 — Settings Page (Refactor)

**Status:** ⏳ Planejado | Depende de TAREFA 5 (home search icon)

**Descrição visual:**
Tela de configurações com design moderno. Seções: tema (cor primária, modo light/dark), conta (display name, logout), sobre. Design limpo com cards/tiles.

Ref: `Telas novas Listel/configura_es/screen.png`

---

## O que fazer

### **Refactor de settings_page.dart**

**Sections:**

1. **Tema:**
   - Seletor de cor primária (palette de cores)
   - Toggle light/dark/auto
   - Preview de tema em tempo real

2. **Conta (se autenticado):**
   - Display name (editável)
   - Email (leitura apenas)
   - Botão "Logout"

3. **Sobre:**
   - Versão do app
   - Link para termos de serviço
   - Link para política de privacidade
   - Copyright

4. **Avançado (opcional):**
   - Limpeza de cache de imagens
   - Excluir account (com confirmação)
   - Dados de debug (apenas em dev)

**Layout:**
- Seções em expandable cards ou simples vstack
- Tile style com ícones
- Feedback visual imediato (toast/snackbar ao mudar)

### **Providers**

Já existem: `themeSettingsProvider`, `AuthStateProvider`.

### **Testes**

- [ ] Manual — mudança de cor atualiza tema
- [ ] Manual — toggle dark/light funciona
- [ ] Manual — logout funciona e redireciona
- [ ] Manual — display name pode ser editado

### **Arquivos a modificar**

**Modificar:**
- `lib/features/settings/presentation/pages/settings_page.dart` — refactor visual

---

## ✅ Checklist de Conclusão

- [ ] Seções renderizadas
- [ ] Seletor de cor funciona
- [ ] Toggle dark/light funciona
- [ ] Display name editável
- [ ] Logout funciona
- [ ] Design segue screenshot

