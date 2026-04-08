# Tarefa 12 — Tela de perfil do usuário

**Status:** ❌ Não implementado  
**Prioridade:** Média — ícone na home já existe mas não faz nada quando logado

---

## Contexto

O `AppBar` da `HomePage` já tem um `IconButton` com `Icons.account_circle_outlined` (leading).
Quando o usuário **não está logado**, ele navega para `/auth/login`. Quando **está logado**, o `onPressed` não faz nada — precisa ir para a nova `ProfilePage`.

A tabela `profiles` no Supabase já existe (campos: `id`, `display_name`, `updated_at`).  
O `AppUser` atual tem: `id`, `email`, `displayName` — sem `avatarUrl`.

---

## O que precisa ser feito

### 1. Adicionar `avatarUrl` ao `AppUser` e ao mapeamento

**Arquivo:** `lib/features/auth/domain/entities/app_user.dart`
- Adicionar campo `final String? avatarUrl`

**Arquivo:** `lib/features/auth/data/repositories/supabase_auth_repository_impl.dart`
- Atualizar `_mapUser` para ler `user.userMetadata?['avatar_url']`
- Adicionar método `Future<void> updateProfile({String? displayName, String? avatarUrl})`:
  - Chama `_client.auth.updateUser(UserAttributes(data: {...}))` para o metadata
  - Chama `_client.from('profiles').upsert({'id': uid, 'display_name': ..., 'avatar_url': ..., 'updated_at': ...})`

**Arquivo:** `lib/features/auth/domain/repositories/auth_repository.dart`
- Declarar `Future<void> updateProfile({String? displayName, String? avatarUrl})`

### 2. Adicionar provider de ação de perfil

**Arquivo:** `lib/features/auth/presentation/providers/auth_provider.dart`
- Adicionar `profileUpdateProvider` (ex: `AsyncNotifier` ou simples `FutureProvider` sob demanda)
- Adicionar `Future<void> signOut()` no provider se ainda não existir acessível via provider

### 3. Criar `ProfilePage`

**Arquivo a criar:** `lib/features/auth/presentation/pages/profile_page.dart`

**Seções da tela (ScrollView):**

#### 3a. Avatar / foto de perfil
- Exibe `CircleAvatar` com a foto (se `avatarUrl != null`) ou iniciais do nome
- Botão "Alterar foto" abre `showModalBottomSheet` com opções:
  - **Câmera** → `ImagePicker().pickImage(source: ImageSource.camera)`
  - **Galeria** → `ImagePicker().pickImage(source: ImageSource.gallery)`
- Após escolher: faz upload para o Supabase Storage no bucket `avatars/{userId}.jpg`
- Obtém URL pública e chama `updateProfile(avatarUrl: url)`
- Dependência a adicionar: `image_picker` no `pubspec.yaml`

#### 3b. Editar nome de exibição
- `TextFormField` pré-preenchido com `currentUser.displayName`
- Botão "Salvar" chama `updateProfile(displayName: novoNome)`
- Validação: não pode ser vazio

#### 3c. Informação de e-mail (somente leitura)
- `ListTile` com `Icons.email_outlined` exibindo o e-mail
- Label "E-mail (não editável)"

#### 3d. Trocar senha
- `ListTile` com `Icons.lock_outline` e seta
- Abre `showDialog` com campo de nova senha
- Chama `_client.auth.updateUser(UserAttributes(password: novaSenha))`
- Exibir feedback de sucesso/erro em `SnackBar`

#### 3e. Logout
- `FilledButton.tonal` vermelho "Sair da conta"
- Confirma via `showDialog` antes de chamar `authRepository.signOut()`
- Após logout: `context.go(AppRoutes.home)`

### 4. Registrar rota

**Arquivo:** `lib/core/router/app_routes.dart`
- Adicionar: `static const profile = '/profile';`

**Arquivo:** `lib/core/router/app_router.dart`
- Registrar `GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfilePage())`

### 5. Atualizar `HomePage` — ícone de perfil

**Arquivo:** `lib/features/collections/presentation/pages/home_page.dart`
- No `onPressed` do `IconButton` leading, adicionar o branch logado:
```dart
if (isLoggedIn) {
  context.push(AppRoutes.profile);
} else {
  context.push(AppRoutes.login);
}
```
- Trocar o ícone para `Icons.account_circle` (preenchido) quando logado, mantendo `account_circle_outlined` quando deslogado — use `currentUserProvider` via `ref.watch`

### 6. Linkar perfil na `MembersPage`

**Arquivo:** `lib/features/sharing/presentation/pages/members_page.dart`
- No `_MemberTile`, verificar se `member.userId == currentUserId`
- Se for o próprio usuário: adicionar trailing `TextButton('Editar perfil', onPressed: () => context.push(AppRoutes.profile))`
- Exibir `(você)` ao lado do nome como `subtitle`

---

## Arquivos envolvidos

| Arquivo | Ação |
|---|---|
| `lib/features/auth/domain/entities/app_user.dart` | Adicionar `avatarUrl` |
| `lib/features/auth/domain/repositories/auth_repository.dart` | Declarar `updateProfile` |
| `lib/features/auth/data/repositories/supabase_auth_repository_impl.dart` | Implementar `updateProfile` + upload Storage |
| `lib/features/auth/presentation/providers/auth_provider.dart` | Expor `updateProfile` e `signOut` |
| `lib/features/auth/presentation/pages/profile_page.dart` | **Criar** |
| `lib/core/router/app_routes.dart` | Adicionar `profile` |
| `lib/core/router/app_router.dart` | Registrar rota `/profile` |
| `lib/features/collections/presentation/pages/home_page.dart` | Corrigir `onPressed` do ícone leading |
| `lib/features/sharing/presentation/pages/members_page.dart` | Destacar membro próprio + link para perfil |
| `pubspec.yaml` | Adicionar `image_picker` |

---

## Supabase — pré-requisitos

| Recurso | Ação necessária |
|---|---|
| Storage bucket `avatars` | Criar no dashboard com RLS: dono pode insert/update, todos podem select |
| Coluna `avatar_url` na tabela `profiles` | `ALTER TABLE profiles ADD COLUMN avatar_url text;` |

Política RLS sugerida para `avatars`:
```sql
-- INSERT/UPDATE: apenas o próprio usuário
CREATE POLICY "avatar_own" ON storage.objects
  FOR ALL USING (bucket_id = 'avatars' AND auth.uid()::text = name);

-- SELECT: público
CREATE POLICY "avatar_public" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');
```

---

## Observações

- Ao fazer upload, usar o caminho `${userId}.jpg` (substituir se já existir) — Supabase Storage faz upsert com `upsert: true` no `uploadBinary`.
- O `image_picker` já exige permissões no `AndroidManifest.xml`: `READ_MEDIA_IMAGES` (API 33+) e `READ_EXTERNAL_STORAGE` (API < 33). Verificar se já está declarado (pode já estar por outro motivo).
- Manter `avatarUrl` como `String?` — usuários sem foto usam `CircleAvatar` com iniciais, sem placeholder de rede.
- Não bloquear login/signup pelo `avatarUrl` — é opcional.
- O `CollectionMember` só tem `displayName`, não `avatarUrl` — a `MembersPage` exibe apenas iniciais, tudo bem.
