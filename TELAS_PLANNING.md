# Listel — Planejamento de Telas Novas

> Estruturação e implementação das telas de design modernizado para a plataforma Listel.
> Última atualização: 2026-04-17

---

## 📋 Resumo Executivo

Total de **12 telas novas** em `Telas novas Listel/`, cada uma com design em HTML/CSS (Tailwind) + screenshot. Objetivo: implementar gradualmente como Flutter Dart, respeitando arquitetura Clean Architecture existente.

**Distribuição por módulo:**
- **Auth** (4): login, criar conta, login refinado, criar conta refinado
- **Collections** (1): liste soft modern (home redesenhada)
- **Items** (3): adicionar item modernizado, detalhe do item, salvar produto
- **Settings** (1): configurações
- **Sharing** (2): adicionar amigos, perfil do usuário
- **Social** (1): (tela futura)

---

## 🎯 Telas — Status e Prioridade

| # | Tela | Módulo | Status | Prioridade | Arquivos |
|---|------|--------|--------|-----------|----------|
| 1 | Login | auth | ⏳ Planejado | 🔴 Alta | login_page.dart |
| 2 | Criar Conta | auth | ⏳ Planejado | 🔴 Alta | signup_page.dart |
| 3 | Login (Refinado) | auth | ⏳ Planejado | 🟡 Média | login_refined_page.dart |
| 4 | Criar Conta (Refinado) | auth | ⏳ Planejado | 🟡 Média | signup_refined_page.dart |
| 5 | Listel — Home | collections | ✅ Completo | 🔴 Alta | home_page.dart (refactor) |
| 6 | Adicionar Item | items | ⏳ Planejado | 🔴 Alta | create_item_page.dart (refactor) |
| 7 | Detalhe do Item | items | ⏳ Planejado | 🔴 Alta | item_detail_page.dart (refactor) |
| 8 | Salvar Produto | items | ⏳ Planejado | 🟡 Média | share_received_page.dart (refactor) |
| 9 | Configurações | settings | ⏳ Planejado | 🟡 Média | settings_page.dart (refactor) |
| 10 | Adicionar Amigos | sharing | ⏳ Planejado | 🟡 Média | add_members_page.dart |
| 11 | Perfil do Usuário | sharing | ✅ Completo | 🟡 Média | user_profile_page.dart |
| 12 | (Reservado) | - | ❌ Não definido | 🟢 Baixa | - |

---

## 📁 Estrutura de Pastas

```
Telas novas Listel/
├── adicionar_amigos/              → Sharing: tela de adicionar membros
├── adicionar_item_modernizado/    → Items: criar/editar item (refactor)
├── configura_es/                  → Settings: preferências de conta/app
├── criar_conta/                   → Auth: signup básico
├── criar_conta_estilo_refinado/   → Auth: signup versão polida
├── detalhe_do_item/               → Items: detalhe completo do item
├── liste_soft_modern/             → Collections: home redesenhada
├── login/                         → Auth: login básico
├── login_estilo_refinado/         → Auth: login versão polida
├── perfil_do_usu_rio/             → Sharing: editar display_name + info conta
└── salvar_produto/                → Items: share intent → salvamento rápido
```

Cada pasta contém:
- `code.html` — implementação em Tailwind CSS (referência visual)
- `screen.png` — screenshot do design final

---

## 🔄 Fluxo de Implementação

### **Fase 1 — Foundation (Auth)** 
Implementar autenticação completa — base para todas as outras features.

1. **TAREFA 1 — Login Page**
2. **TAREFA 2 — Signup Page**
3. **TAREFA 3 — Login Refinado (opcional)**
4. **TAREFA 4 — Signup Refinado (opcional)**

### **Fase 2 — Core Features (Collections + Items)**
Refactor visual das telas existentes com novos designs.

5. **TAREFA 5 — Home Page Redesenhada (Listel)**
6. **TAREFA 6 — Create/Edit Item Modernizado**
7. **TAREFA 7 — Item Detail Completo**
8. **TAREFA 8 — Share Intent → Save Flow**

### **Fase 3 — Social + Settings**
Funcionalidades complementares.

9. **TAREFA 9 — Settings Page**
10. **TAREFA 10 — Add Members (Sharing)**
11. **TAREFA 11 — User Profile Page**

---

## 📝 Padrão de Documentação por Tela

Cada tela deve ter um **arquivo de atividade** (`TAREFA_[N]_[nome].md`) no padrão:

```markdown
---
tela: [Nome da Tela]
modulo: [auth/collections/items/settings/sharing]
prioridade: [Alta/Média/Baixa]
---

# TAREFA [N] — [Nome Descritivo]

**Status:** ⏳ Planejado | ❌ Não iniciado | 🔄 Em progresso | ✅ Completo

**Descrição visual:**
[Resumo do design e comportamento esperado]

## O que fazer

**Entidades de domínio:**
- [...] — descrição + campos novos/modificados

**Camada de dados:**
- [...] — models, migrations, repos

**Camada de apresentação:**
- [...] — providers, pages, widgets

**Roteamento:**
- Rota: [path]
- Deep link: [scheme]

**Dependências novas:**
- [...] — pacotes adicionais

**Testes:**
- [ ] Unit test — [descrição]
- [ ] Widget test — [descrição]
- [ ] Manual — [casos de uso]

**Arquivos a criar/modificar:**
- `lib/features/[module]/presentation/pages/[page].dart`
- [...]

## Notas técnicas

[Decisões de arquitetura, gotchas, reusas de código existente]
```

---

## 🎯 Como Usar Este Arquivo

### Para começar uma tarefa:
1. Leia a seção da **tela específica** abaixo
2. Abra o arquivo `TAREFA_[N]_[nome].md` correspondente
3. Siga o checklist de "O que fazer"
4. Atualize o status conforme avança

### Para revisar progresso:
1. Veja a tabela de status acima
2. Procure pelos arquivos `TAREFA_*.md` com ✅ ou 🔄
3. Leia a última atualização em `last_updated`

---

## 📄 Detalhes das Tarefas — Links para Pastas

### Fase 1 — Foundation (Auth) 🔐
1. **[Telas novas Listel/login/TAREFA_1_login.md](Telas%20novas%20Listel/login/TAREFA_1_login.md)** — Login Page
   - Email/senha, validações, redirect após sucesso
   - Repositório `AuthRepository`, Provider `SignInNotifier`

2. **[Telas novas Listel/criar_conta/TAREFA_2_signup.md](Telas%20novas%20Listel/criar_conta/TAREFA_2_signup.md)** — Signup Page
   - Criar conta, força de senha, termos de serviço
   - Reutiliza `AuthRepository`, novo `SignUpNotifier`

3. **[Telas novas Listel/login_estilo_refinado/TAREFA_3_login_refinado.md](Telas%20novas%20Listel/login_estilo_refinado/TAREFA_3_login_refinado.md)** — Login Refinado (Optional)
   - Versão polida com gradiente, animações, card flutuante
   - Reutiliza lógica de TAREFA 1

4. **[Telas novas Listel/criar_conta_estilo_refinado/TAREFA_4_signup_refinado.md](Telas%20novas%20Listel/criar_conta_estilo_refinado/TAREFA_4_signup_refinado.md)** — Signup Refinado (Optional)
   - Versão polida com barra de força de senha visual
   - Reutiliza lógica de TAREFA 2

### Fase 2 — Core Features 🎨
5. **[Telas novas Listel/liste_soft_modern/TAREFA_5_home_redesenhada.md](Telas%20novas%20Listel/liste_soft_modern/TAREFA_5_home_redesenhada.md)** — Home Page
   - Grid de coleções locais + seção compartilhadas
   - FAB duplo (local / compartilhada), search bar

6. **[Telas novas Listel/adicionar_item_modernizado/TAREFA_6_adicionar_item_modernizado.md](Telas%20novas%20Listel/adicionar_item_modernizado/TAREFA_6_adicionar_item_modernizado.md)** — Add Item
   - Criar/editar item com foto, preço, link, observações
   - Validações, contadores visuais, bottom action bar

7. **[Telas novas Listel/detalhe_do_item/TAREFA_7_detalhe_item.md](Telas%20novas%20Listel/detalhe_do_item/TAREFA_7_detalhe_item.md)** — Item Detail
   - Preview completo, toggle status, editar/deletar
   - Hero animation, share intent, buscar mais barato

8. **[Telas novas Listel/salvar_produto/TAREFA_8_salvar_produto.md](Telas%20novas%20Listel/salvar_produto/TAREFA_8_salvar_produto.md)** — Share Intent Flow
   - Bottom sheet de preview ao compartilhar link
   - Seletor de coleção, observações, feedback de sucesso

### Fase 3 — Social & Settings 👥
9. **[Telas novas Listel/configura_es/TAREFA_9_configuracoes.md](Telas%20novas%20Listel/configura_es/TAREFA_9_configuracoes.md)** — Settings Page
   - Tema (cor, dark/light), conta (logout), sobre

10. **[Telas novas Listel/adicionar_amigos/TAREFA_10_adicionar_amigos.md](Telas%20novas%20Listel/adicionar_amigos/TAREFA_10_adicionar_amigos.md)** — Add Members
    - Código de convite, link compartilhável, lista de membros

11. **[Telas novas Listel/perfil_do_usu_rio/TAREFA_11_perfil_usuario.md](Telas%20novas%20Listel/perfil_do_usu_rio/TAREFA_11_perfil_usuario.md)** — User Profile
    - Avatar, display name, estatísticas, logout/delete account

---

## 🚀 Como Começar

**Recomendação de ordem:**

1. **Comece por TAREFA 1 + 2** (Auth foundation)
   - Sem essas, outras telas não funcionam
   - Use `supabase_flutter` já configurado no pubspec

2. **Depois TAREFA 5** (Home redesenhada)
   - Integra visual das listas locais
   - Facilita testes das outras telas

3. **Depois TAREFA 6 + 7 + 8** (Items core flow)
   - Criadição de itens, detalhe, compartilhamento

4. **Finalize com TAREFA 9, 10, 11** (Polish)
   - Completam a experiência social

**Versões refinadas (TAREFA 3, 4):**
- Opcional — implemente após foundation estar estável
- Pode usar A/B testing ou feature flag

---

## 📋 Status de Implementação

| Tarefa | Arquivo | Status | Dependências |
|--------|---------|--------|-------------|
| 1 | login.md | ⏳ Planejado | — |
| 2 | signup.md | ⏳ Planejado | TAREFA 1 ✅ |
| 3 | login_refinado.md | ⏳ Planejado | TAREFA 1 ✅ |
| 4 | signup_refinado.md | ⏳ Planejado | TAREFA 2 + 3 ✅ |
| 5 | home_redesenhada.md | ✅ Completo | TAREFA 1 ✅ |
| 6 | adicionar_item_modernizado.md | ⏳ Planejado | TAREFA 5 ✅ |
| 7 | detalhe_item.md | ⏳ Planejado | TAREFA 6 ✅ |
| 8 | salvar_produto.md | ⏳ Planejado | TAREFA 6 ✅ |
| 9 | configuracoes.md | ⏳ Planejado | TAREFA 5 ✅ |
| 10 | adicionar_amigos.md | ⏳ Planejado | TAREFA 1 ✅ |
| 11 | perfil_usuario.md | ⏳ Planejado | TAREFA 1 ✅ |

---

## 📚 Recursos Relacionados

- **Código de design:** `Telas novas Listel/[pasta]/code.html` (Tailwind CSS)
- **Screenshots:** `Telas novas Listel/[pasta]/screen.png` (PNG visual)
- **Planning original:** `planning/planning.md` (TAREFA 1-11 da app)
- **Shared List Feature:** `.specs/project/SHARED_LIST_FEATURE.md` (7 fases de implementação)

---

## 💡 Dicas de Implementação

### Reutilização de código
- Providers existentes: `authStateProvider`, `collectionsStreamProvider`, `itemsByCollectionProvider`
- Repositories: `CollectionsRepository`, `ItemsRepository` já implementados
- Services: `MetadataExtractorService`, `NotificationService` prontos para usar

### Testing strategy
- **Unit tests:** Validações, cálculos de força de senha, parsing de preço
- **Widget tests:** Renderização de formulários, validação de inputs
- **Manual tests:** Fluxos end-to-end, navegação, feedback visual

### Performance considerations
- Lazy load de imagens em grid (via `cached_network_image`)
- Shimmer skeleton enquanto carrega dados
- Debounce em search (500ms)
- Paginação opcional se listas ficarem muito grandes

---

## 🔄 Sincronização com Projeto

Este plano foi criado em **2026-04-17** com base em:
- Design em HTML/Tailwind + screenshots em `Telas novas Listel/`
- Arquitetura Clean existente (`lib/features/`)
- Stack: Flutter 3.38.4, Riverpod, Isar, Supabase, go_router

**Última atualização:** 2026-04-17 (inicial — planejamento completo)

