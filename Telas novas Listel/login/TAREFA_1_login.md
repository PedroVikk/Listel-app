---
tela: Login
modulo: auth
prioridade: Alta
status: ⏳ Planejado
last_updated: 2026-04-17
---

# TAREFA 1 — Login Page (Email/Senha)

**Status:** ⏳ Planejado | Esperando implementação

**Descrição visual:**
Tela de login com design moderno (branco/cinza com acentos em rosa/vermelho). Campo de email, campo de senha, botão "Entrar", link "Criar conta", recuperação de senha. Logo/ícone do app no topo. Consistente com Material Design 3.

Ref: `screen.png` (nesta pasta)

---

## O que fazer

### **Entidades de domínio**

Nova entidade em `lib/features/auth/domain/entities/app_user.dart`:
```dart
class AppUser {
  final String id;           // UUID do Supabase Auth
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
}
```

### **Camada de dados**

**Repository interface** — `lib/features/auth/domain/repositories/auth_repository.dart`:
```dart
abstract class AuthRepository {
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> signUpWithEmail(String email, String password, String? displayName);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  AppUser? getCurrentUser();
  Stream<AppUser?> authStateChanges();
}
```

**Repository impl** — `lib/features/auth/data/repositories/supabase_auth_repository_impl.dart`:
- Usa `supabase_flutter` (já no pubspec via shared_list_feature)
- `signInWithEmail()` → `supabase.auth.signInWithPassword()`
- `signUpWithEmail()` → `supabase.auth.signUp()` + cria row em `public.profiles`
- `signOut()` → `supabase.auth.signOut()`
- `getCurrentUser()` → `supabase.auth.currentUser` + resolve profile
- `authStateChanges()` → `supabase.auth.onAuthStateChange.map(...)`

### **Camada de apresentação**

**Provider** — `lib/features/auth/presentation/providers/auth_provider.dart`:
```dart
// Singleton
final authRepositoryProvider = Provider((ref) => SupabaseAuthRepositoryImpl());

// State notifier para login/signup
final authStateProvider = StreamProvider((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

// Sign in async notifier
final signInNotifierProvider = AsyncNotifierProvider<SignInNotifier, void>((ref) => SignInNotifier());

class SignInNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() async {}
  
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithEmail(email, password);
    });
  }
}
```

**Page** — `lib/features/auth/presentation/pages/login_page.dart`:
- `ConsumerStatefulWidget` — controla visiblidade de senha
- TextField para email (validação: `emailValidator`)
- TextField para senha com ícone toggle "olho"
- Botão "Entrar" desabilitado enquanto carrega
- SnackBar com erro se login falhar
- Link "Não tem conta? Criar conta" → navega para `/auth/signup`
- Link "Esqueceu a senha?" → modal de reset ou página `/auth/reset-password`
- Estado de carregamento: spinner + botão desabilitado
- Estado de erro: texto em vermelho ou SnackBar

### **Roteamento**

Adicionar em `lib/core/router/app_routes.dart`:
```dart
static const String login = '/auth/login';
static const String signup = '/auth/signup';
static const String resetPassword = '/auth/reset-password';
```

Adicionar rotas em `lib/core/router/app_router.dart`:
```dart
GoRoute(
  path: '/auth',
  routes: [
    GoRoute(
      name: 'login',
      path: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      name: 'signup',
      path: 'signup',
      builder: (context, state) => const SignupPage(),
    ),
  ],
),
```

**Redirect de autenticação:**
- Se não autenticado e tenta acessar home → redireciona para `/auth/login`
- Se autenticado e tenta acessar login → pula para home

### **Dependências novas**

- ✅ `supabase_flutter: ^2.8.4` — já no pubspec (shared_list_feature)
- ✅ Não precisa de novas dependências

### **Testes**

- [ ] Unit test — `auth_repository_impl_test.dart` com Mock Supabase
  - `signInWithEmail()` com credenciais válidas
  - `signInWithEmail()` com erro (usuário não existe)
  - `signInWithEmail()` com erro de rede
  
- [ ] Widget test — `login_page_test.dart`
  - Renderiza campos de email e senha
  - Validação de email vazio
  - Validação de senha vazia
  - Botão habilitado apenas com campos preenchidos
  - Tap em "Criar conta" navega para signup

- [ ] Manual
  - Login com credenciais válidas → redireciona para home
  - Login com email inválido → exibe erro
  - Login com senha errada → exibe erro
  - Link "Criar conta" leva para signup
  - Link "Esqueceu a senha" abre modal/página

### **Arquivos a criar/modificar**

**Criar:**
- `lib/features/auth/domain/entities/app_user.dart`
- `lib/features/auth/domain/repositories/auth_repository.dart`
- `lib/features/auth/data/repositories/supabase_auth_repository_impl.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`
- `lib/features/auth/presentation/pages/login_page.dart`
- `test/features/auth/auth_repository_impl_test.dart`
- `test/features/auth/login_page_test.dart`

**Modificar:**
- `lib/core/router/app_routes.dart` — adicionar constantes
- `lib/core/router/app_router.dart` — adicionar rotas + redirect
- `lib/main.dart` — garantir que `Supabase.initialize()` rodou antes

---

## 🔧 Notas técnicas

- **Validação:** Usar padrão `RegExp` ou pacote `email_validator`
- **Erro em produção vs debug:** Supabase retorna mensagens genéricas em produção — capturar `AuthException` e mostrar mensagem amigável
- **Session persistence:** `supabase_flutter` persiste sessão automaticamente via `SharedPreferences`
- **Redirect após login:** Após sucesso, usar `context.goNamed('home')` ou similar
- **Deep link para reset:** Supabase envia email com link tipo `yourdomain.com/reset?token=...` — pode ser interceptado com deep link `listel://reset?token=...` futuramente

---

## ✅ Checklist de Conclusão

- [ ] Arquivo `app_user.dart` criado
- [ ] Repository interface criada
- [ ] Repository impl criada com Supabase client
- [ ] Providers criados (repository + state notifier)
- [ ] `LoginPage` implementada com validação
- [ ] Rotas adicionadas em `app_routes.dart`
- [ ] Rotas adicionadas em `app_router.dart`
- [ ] Redirect de autenticação funciona
- [ ] Tests passando
- [ ] Login com email/senha válido → home
- [ ] Mensagens de erro amigáveis
- [ ] Toggle de visibilidade de senha
- [ ] Link "Criar conta" funciona
- [ ] Design visual segue screenshot
