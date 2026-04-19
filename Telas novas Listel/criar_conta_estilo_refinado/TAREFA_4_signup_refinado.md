---
tela: Criar Conta (Estilo Refinado)
modulo: auth
prioridade: Média
status: ⏳ Planejado
---

# TAREFA 4 — Signup Page (Versão Refinada)

Versão polida de criação de conta. Diferenças: gradiente, card flutuante, animações, micro-interações. Comportamento idêntico ao TAREFA 2.

Ref: `screen.png` (nesta pasta) | Depende: TAREFA 2 + TAREFA 3

## O que fazer

Criar `signup_refined_page.dart` que reutiliza `SignUpNotifier` e validações de TAREFA 2, mas com UI polida.

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
- [ ] Manual — barra de força atualiza

### **Arquivos a criar**

**Criar:**
- `lib/features/auth/presentation/pages/signup_refined_page.dart`

## ✅ Checklist de Conclusão

- [ ] `signup_refined_page.dart` criado
- [ ] Gradiente de fundo
- [ ] Card flutuante com shadow
- [ ] Barra de força visível
- [ ] Lógica reutilizada
- [ ] Design segue screenshot
