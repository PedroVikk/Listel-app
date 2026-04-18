---
tela: Login (Estilo Refinado)
modulo: auth
prioridade: Média
status: ⏳ Planejado
last_updated: 2026-04-17
---

# TAREFA 3 — Login Page (Versão Refinada)

**Status:** ⏳ Planejado | Depende de TAREFA 1 completa

**Descrição visual:**
Versão polida do login com design premium. Diferenças visuais: gradiente de fundo, typography mais sofisticada, micro-animações, espaciamento refinado, card flutuante para inputs. Comportamento idêntico ao TAREFA 1.

Ref: `Telas novas Listel/login_estilo_refinado/screen.png`

---

## O que fazer

### **Estratégia de refactor**

Reusar `LoginPage` existente de TAREFA 1, mas criar variante estilizada:

**Opção A (recomendada):** Criar novo arquivo `login_refined_page.dart` que reusa mesma lógica (providers, validação) mas com UI diferente.

**Opção B:** Parametrizar `LoginPage` com enum `LoginStyle.standard | LoginStyle.refined`

Escolha: **Opção A** — mantém mudanças isoladas, facilita A/B testing.

### **Componentes novos**

**Gradiente de fundo:** 
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Theme.of(context).colorScheme.primary.withAlpha(25),
        Theme.of(context).colorScheme.surface,
      ],
    ),
  ),
)
```

**Card flutuante com shadow:**
```dart
Card(
  elevation: 8,
  shadowColor: Colors.black.withAlpha(50),
  child: Padding(
    padding: EdgeInsets.all(24),
    child: Column(...), // inputs + botão
  ),
)
```

**Animações (IfPresent):**
- FadeInDown no card ao abrir página (via `AnimationController` ou `implicit_animations`)
- Scale + fade na senha ao toggle visibilidade
- Bounce no botão ao pressioná-lo

### **Estilo de typography**

- Título "Entrar": `headline5` ou `displaySmall` com weight 600
- Labels de campo: `labelSmall` com weight 500
- Links "Criar conta" / "Esqueceu": `bodySmall` com cor primária

### **Testes**

- [ ] Manual — UI refinada visível no device/emulador
- [ ] Manual — animações suaves (não travadas)
- [ ] Manual — responsividade em diferentes tamanhos

### **Arquivos a criar/modificar**

**Criar:**
- `lib/features/auth/presentation/pages/login_refined_page.dart`

**Modificar:**
- `lib/core/router/app_router.dart` — adicionar rota opcional `/auth/login-refined` ou parametrizar rota existente

---

## 🔧 Notas técnicas

- **Reutilizar providers:** `SignInNotifier` e `authStateProvider` são compartilhados
- **Tema dinâmico:** Cores do gradiente pegam `colorScheme` do tema do app (já customizável em settings)
- **A/B testing:** Se quiser testar ambas versões, criar `LoginPageVariant` enum e route flag na query

---

## ✅ Checklist de Conclusão

- [ ] `login_refined_page.dart` criado
- [ ] Gradiente de fundo visível
- [ ] Card flutuante com shadow renderizado
- [ ] Typography refinada aplicada
- [ ] Animações suaves funcionam
- [ ] Lógica de validação reutilizada
- [ ] Links funcionam
- [ ] Tests passando
- [ ] Design segue screenshot refinado

