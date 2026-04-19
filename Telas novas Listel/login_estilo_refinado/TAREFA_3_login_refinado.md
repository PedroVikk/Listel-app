---
tela: Login (Estilo Refinado)
modulo: auth
prioridade: Média
status: ⏳ Planejado
---

# TAREFA 3 — Login Page (Versão Refinada)

Versão polida do login com design premium. Diferenças visuais: gradiente de fundo, typography mais sofisticada, micro-animações, espaciamento refinado, card flutuante para inputs. Comportamento idêntico ao TAREFA 1.

Ref: `screen.png` (nesta pasta) | Depende: TAREFA 1 completa

## O que fazer

### **Estratégia de refactor**

Criar novo arquivo `login_refined_page.dart` que reusa mesma lógica (providers, validação) mas com UI diferente.

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

**Animações:**
- FadeInDown no card ao abrir página
- Scale + fade na senha ao toggle visibilidade
- Bounce no botão ao pressioná-lo

### **Testes**

- [ ] Manual — UI refinada visível
- [ ] Manual — animações suaves
- [ ] Manual — responsividade

### **Arquivos a criar**

**Criar:**
- `lib/features/auth/presentation/pages/login_refined_page.dart`

## ✅ Checklist de Conclusão

- [ ] `login_refined_page.dart` criado
- [ ] Gradiente de fundo visível
- [ ] Card flutuante com shadow
- [ ] Typography refinada
- [ ] Animações funcionam
- [ ] Lógica reutilizada
- [ ] Design segue screenshot
