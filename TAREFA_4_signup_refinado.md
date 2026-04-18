---
tela: Criar Conta (Estilo Refinado)
modulo: auth
prioridade: Média
status: ⏳ Planejado
last_updated: 2026-04-17
---

# TAREFA 4 — Signup Page (Versão Refinada)

**Status:** ⏳ Planejado | Depende de TAREFA 2 + TAREFA 3

**Descrição visual:**
Versão polida de criação de conta. Diferenças: gradiente, card flutuante, animações (steps indication opcional), micro-interações. Comportamento idêntico ao TAREFA 2.

Ref: `Telas novas Listel/criar_conta_estilo_refinado/screen.png`

---

## O que fazer

### **Estratégia**

Criar `signup_refined_page.dart` que reutiliza `SignUpNotifier` e validações de TAREFA 2, mas com UI polida (gradiente, card, animações).

**Difícil em relação a TAREFA 3?** Não — mesma abordagem de refactor visual.

### **UI refinada**

- Gradiente no fundo (top: primary com alpha, bottom: surface)
- Card flutuante com elevation + shadow
- Indicador visual de força de senha (barra progressiva colorida)
- Spacing refinado (24-32px padding)
- Typography sofisticada

### **Indicador de força — barra progressiva**

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(4),
  child: LinearProgressIndicator(
    value: _passwordStrength.index / PasswordStrength.values.length,
    backgroundColor: Colors.grey[300],
    valueColor: AlwaysStoppedAnimation(
      _passwordStrength == PasswordStrength.strong ? Colors.green
          : _passwordStrength == PasswordStrength.good ? Colors.orange
          : Colors.red,
    ),
    minHeight: 4,
  ),
)
```

### **Testes**

- [ ] Manual — UI refinada renderizada
- [ ] Manual — barra de força atualiza conforme digita senha

### **Arquivos a criar**

**Criar:**
- `lib/features/auth/presentation/pages/signup_refined_page.dart`

---

## ✅ Checklist de Conclusão

- [ ] `signup_refined_page.dart` criado
- [ ] Gradiente de fundo
- [ ] Card flutuante com shadow
- [ ] Barra de força de senha visível
- [ ] Typography refinada
- [ ] Lógica de validação reutilizada
- [ ] Design segue screenshot

