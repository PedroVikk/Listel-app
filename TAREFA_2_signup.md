---
tela: Criar Conta
modulo: auth
prioridade: Alta
status: ⏳ Planejado
last_updated: 2026-04-17
---

# TAREFA 2 — Signup Page (Criar Conta)

**Status:** ⏳ Planejado | Esperando implementação

**Descrição visual:**
Tela de criação de conta com design moderno. Campos: email, senha, confirmar senha, nome (opcional). Botão "Criar conta". Link "Já tem conta? Entrar". Validações em tempo real (força de senha, match de senhas). Termos de serviço checkbox.

Ref: `Telas novas Listel/criar_conta/screen.png`

---

## O que fazer

### **Camada de apresentação**

**Notifier** — Adicionar em `lib/features/auth/presentation/providers/auth_provider.dart`:
```dart
final signUpNotifierProvider = AsyncNotifierProvider<SignUpNotifier, void>((ref) => SignUpNotifier());

class SignUpNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() async {}
  
  Future<void> signUp(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.signUpWithEmail(email, password, displayName);
    });
  }
}
```

**Page** — `lib/features/auth/presentation/pages/signup_page.dart`:
- TextField de email com validação em tempo real
- TextField de senha com visualização/ocultamento + indicador de força
- TextField de confirmar senha (compara com senha)
- TextField de nome (opcional)
- Checkbox de "Li e concordo com os Termos de Serviço"
- Botão "Criar conta" desabilitado até validar tudo
- Estados: idle, loading (spinner), error (SnackBar), success (navega para home)
- Link "Já tem conta? Entrar" → `/auth/login`

**Validações:**
- Email: formato válido, não vazio
- Senha: mín 8 caracteres, contém letra + número
- Confirmar senha: match com senha
- Nome: opcional, máx 100 chars
- Termos: obrigatório

**Indicador de força de senha:**
```dart
enum PasswordStrength { weak, fair, good, strong }

PasswordStrength _evaluatePasswordStrength(String password) {
  if (password.length < 8) return PasswordStrength.weak;
  bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
  bool hasDigit = password.contains(RegExp(r'[0-9]'));
  bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  
  int strength = (hasLetter ? 1 : 0) + (hasDigit ? 1 : 0) + (hasSpecial ? 1 : 0);
  if (password.length >= 12) strength++;
  
  switch (strength) {
    case 1: return PasswordStrength.weak;
    case 2: return PasswordStrength.fair;
    case 3: return PasswordStrength.good;
    case 4: return PasswordStrength.strong;
    default: return PasswordStrength.weak;
  }
}
```

### **Roteamento**

Já adicionado em `TAREFA_1_login.md` — garantir que route `/auth/signup` existe.

### **Testes**

- [ ] Unit test — validação de email, senha, força
- [ ] Widget test — renderiza campos, valida, desabilita botão
- [ ] Manual — signup com dados válidos cria conta e redireciona

### **Arquivos a criar/modificar**

**Criar:**
- `lib/features/auth/presentation/pages/signup_page.dart`
- `test/features/auth/signup_page_test.dart`

**Modificar:**
- `lib/features/auth/presentation/providers/auth_provider.dart` — adicionar `SignUpNotifier`

---

## 🔧 Notas técnicas

- **Display name:** Pode ser vazio; se preenchido, salva em `public.profiles.display_name`
- **Duplicação de email:** Supabase lança `AuthException` com código `user_already_exists` — capturar e mostrar mensagem
- **Confirmação de email:** MVP não requer confirmação por email; pode ser adicionado futuramente com verificação
- **TOS link:** Pode ser hardcoded, deep link para documento, ou webview

---

## ✅ Checklist de Conclusão

- [ ] `SignUpNotifier` criado
- [ ] `SignupPage` implementada com todos os campos
- [ ] Validações em tempo real funcionam
- [ ] Indicador de força de senha exibido
- [ ] Botão desabilitado enquanto invalido
- [ ] Termos de serviço obrigatório
- [ ] Link "Entrar" funciona
- [ ] Signup bem-sucedido redireciona para home
- [ ] Erro de email duplicado exibido
- [ ] Tests passando
- [ ] Design segue screenshot

