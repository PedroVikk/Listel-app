# Tarefa 13 — Recuperação de conta (reset de senha)

**Status:** ❌ Não implementado  
**Prioridade:** Média — fluxo de segurança básico ausente

---

## Contexto

A `LoginPage` atual tem apenas login e cadastro — sem link de "Esqueci minha senha".  
O Supabase suporta reset de senha por e-mail via `auth.resetPasswordForEmail()`, que envia um link mágico. O usuário clica no link, o app abre via deep link e exibe uma tela para definir a nova senha.

Fluxo completo:
1. Usuário clica "Esqueci minha senha" na `LoginPage`
2. Informa o e-mail → Supabase envia o e-mail de recuperação
3. Usuário clica no link do e-mail → app abre via deep link (`/auth/reset-password`)
4. App detecta a sessão de recuperação no `onAuthStateChange` (`PASSWORD_RECOVERY`)
5. Exibe tela para definir nova senha
6. Após salvar, redireciona para home

---

## O que precisa ser feito

### 1. Adicionar método no repositório

**Arquivo:** `lib/features/auth/domain/repositories/auth_repository.dart`
- Declarar: `Future<void> sendPasswordResetEmail(String email)`

**Arquivo:** `lib/features/auth/data/repositories/supabase_auth_repository_impl.dart`
- Implementar:
```dart
@override
Future<void> sendPasswordResetEmail(String email) async {
  try {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'com.listel.app://auth/reset-password',
    );
  } on AuthException catch (e) {
    throw AuthException(_translate(e));
  }
}
```
- O `redirectTo` deve usar o scheme do deep link do app (ver passo 4)

### 2. Adicionar "Esqueci minha senha" na `LoginPage`

**Arquivo:** `lib/features/auth/presentation/pages/login_page.dart`
- Adicionar `TextButton` com texto "Esqueci minha senha" **somente quando `_isSignUp == false`**, entre o botão principal e o botão de alternar cadastro
- `onPressed` abre `_showForgotPasswordDialog(context)`

```dart
Future<void> _showForgotPasswordDialog(BuildContext context) async {
  final emailCtrl = TextEditingController(text: _emailController.text.trim());
  final confirmed = await showDialog<bool>(...);
  if (confirmed != true) return;

  setState(() => _loading = true);
  try {
    await ref.read(authRepositoryProvider).sendPasswordResetEmail(emailCtrl.text.trim());
    if (mounted) _showMessage('E-mail de recuperação enviado!', isError: false);
  } on AuthException catch (e) {
    if (mounted) _showMessage(e.message);
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
```

O `showDialog` exibe:
- `AlertDialog` com título "Recuperar senha"
- `TextFormField` para e-mail (pré-preenchido com o que o usuário já digitou, se houver)
- Botões "Cancelar" e "Enviar"

### 3. Criar `ResetPasswordPage`

**Arquivo a criar:** `lib/features/auth/presentation/pages/reset_password_page.dart`

Esta tela é exibida quando o usuário chega via deep link de recuperação.

```
Scaffold
  AppBar: "Nova senha"
  Body:
    TextFormField — Nova senha (obscureText, mínimo 6 chars)
    TextFormField — Confirmar nova senha (deve ser igual)
    FilledButton "Salvar senha"
    → chama _client.auth.updateUser(UserAttributes(password: novaSenha))
    → exibe SnackBar de sucesso
    → context.go(AppRoutes.home)
```

- Usar `Supabase.instance.client.auth.updateUser` diretamente (a sessão já está ativa via deep link)
- Tratar `AuthException` e exibir mensagem traduzida

### 4. Configurar deep link no Android

**Arquivo:** `android/app/src/main/AndroidManifest.xml`
- Adicionar `<intent-filter>` com `android:scheme="com.listel.app"` dentro da `<activity>` principal:

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="com.listel.app" android:host="auth" />
</intent-filter>
```

**Verificar** qual é o `applicationId` atual no `android/app/build.gradle` para confirmar se o scheme `com.listel.app` bate ou precisa ser ajustado.

### 5. Registrar rota e detectar evento de recuperação

**Arquivo:** `lib/core/router/app_routes.dart`
- Adicionar: `static const resetPassword = '/auth/reset-password';`

**Arquivo:** `lib/core/router/app_router.dart`
- Registrar rota:
```dart
GoRoute(
  path: AppRoutes.resetPassword,
  builder: (_, __) => const ResetPasswordPage(),
),
```

**Arquivo:** `lib/main.dart` (ou onde o `SupabaseClient` é inicializado)
- Escutar `Supabase.instance.client.auth.onAuthStateChange` para o evento `PASSWORD_RECOVERY`:
```dart
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  if (data.event == AuthChangeEvent.passwordRecovery) {
    router.go(AppRoutes.resetPassword);
  }
});
```
- Verificar se já existe algum listener global de `authStateChange`; se sim, adicionar o case lá.

---

## Arquivos envolvidos

| Arquivo | Ação |
|---|---|
| `lib/features/auth/domain/repositories/auth_repository.dart` | Declarar `sendPasswordResetEmail` |
| `lib/features/auth/data/repositories/supabase_auth_repository_impl.dart` | Implementar + traduzir erros |
| `lib/features/auth/presentation/pages/login_page.dart` | Adicionar link + dialog "Esqueci minha senha" |
| `lib/features/auth/presentation/pages/reset_password_page.dart` | **Criar** |
| `lib/core/router/app_routes.dart` | Adicionar `resetPassword` |
| `lib/core/router/app_router.dart` | Registrar rota `/auth/reset-password` |
| `lib/main.dart` | Listener `PASSWORD_RECOVERY` → redirecionar |
| `android/app/src/main/AndroidManifest.xml` | Adicionar `intent-filter` para deep link |

---

## Configuração no Supabase Dashboard

Em **Authentication → URL Configuration**:
- **Site URL:** `com.listel.app://` (ou o scheme definido)
- **Redirect URLs:** adicionar `com.listel.app://auth/reset-password`

Sem isso o Supabase bloqueia o redirect por segurança.

---

## Observações

- O e-mail enviado pelo Supabase pode ter delay de alguns segundos — exibir `SnackBar` informando que o e-mail foi enviado, sem bloquear a UI.
- Não confirmar se o e-mail existe ou não na resposta (evitar enumeração de usuários) — o Supabase já faz isso por padrão, retornando sucesso mesmo para e-mails não cadastrados.
- O evento `PASSWORD_RECOVERY` só dispara quando o app abre via deep link de recuperação; não confundir com login normal.
- Se o usuário já estiver logado e quiser trocar a senha, usar o fluxo da `ProfilePage` (task 12, seção 3d) — não este.
- Testar em dispositivo físico: emuladores às vezes não processam deep links corretamente via Android Studio.
