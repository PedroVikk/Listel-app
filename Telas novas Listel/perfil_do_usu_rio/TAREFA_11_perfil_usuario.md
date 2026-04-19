---
tela: Perfil do Usuário
modulo: sharing
prioridade: Média
status: ⏳ Planejado
---

# TAREFA 11 — User Profile Page

Página de perfil do usuário com avatar (gerado ou upload), nome editável, email, estatísticas (listas criadas, itens salvos), e opções de conta.

Ref: `screen.png` (nesta pasta) | Depende: TAREFA 1 (auth)

## O que fazer

### **Nova entidade — UserProfile**

Estender `AppUser` em `auth/domain/entities/app_user.dart` ou criar `UserProfile` separado:

```dart
class UserProfile {
  final String userId;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final int collectionsCount;
  final int itemsCount;
  final DateTime createdAt;
}
```

### **Page — user_profile_page.dart**

**Layout:**

1. **Avatar section:**
   - Avatar circular (initials ou imagem)
   - Botão "Editar avatar" (upload ou gerar)
   - Nome editável (inline edits)

2. **Estatísticas:**
   - Cards com contadores:
     - Listas criadas
     - Itens salvos
     - Listas compartilhadas

3. **Account section:**
   - Email (read-only)
   - Data de cadastro
   - Botão "Editar display name"
   - Botão "Alterar senha" (opcional)

4. **Actions:**
   - Botão "Sair da conta" (logout)
   - Botão "Excluir conta" (confirmação)

### **Providers**

Adicionar `userProfileProvider` em `auth/presentation/providers/auth_provider.dart`

### **Testes**

- [ ] Manual — avatar exibido
- [ ] Manual — display name editável
- [ ] Manual — estatísticas corretas
- [ ] Manual — logout funciona
- [ ] Manual — delete account com confirmação

### **Arquivos a criar**

**Criar:**
- `lib/features/auth/domain/entities/user_profile.dart`
- `lib/features/auth/presentation/pages/user_profile_page.dart`

**Modificar:**
- `lib/features/auth/presentation/providers/auth_provider.dart` — adicionar `userProfileProvider`

## ✅ Checklist de Conclusão

- [ ] Avatar exibido
- [ ] Display name editável
- [ ] Estatísticas carregadas
- [ ] Email exibido
- [ ] Logout funciona
- [ ] Delete account com confirmação
- [ ] Design segue screenshot
