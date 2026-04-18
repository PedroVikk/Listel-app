---
tela: Perfil do Usuário
modulo: sharing
prioridade: Média
status: ⏳ Planejado
last_updated: 2026-04-17
---

# TAREFA 11 — User Profile Page

**Status:** ⏳ Planejado | Depende de TAREFA 1 (auth)

**Descrição visual:**
Página de perfil do usuário com avatar (gerado ou upload), nome editável, email, estatísticas (listas criadas, itens salvos), e opções de conta.

Ref: `Telas novas Listel/perfil_do_usu_rio/screen.png`

---

## O que fazer

### **Nova entidade — UserProfile**

Já existe `AppUser` em `auth/domain/entities/`; pode ser estendido ou criar `UserProfile` separado com campos extras:

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
   - Nome editável (inline edits com Save/Cancel)

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
   - Botão "Excluir conta" (confirmação necessária)

### **Providers**

Adicionar `userProfileProvider` em `auth/presentation/providers/auth_provider.dart`:

```dart
final userProfileProvider = FutureProvider((ref) async {
  final auth = ref.watch(authStateProvider);
  return auth.whenData((user) async {
    if (user == null) return null;
    // Buscar stats do repositório
    return UserProfile(
      userId: user.id,
      email: user.email,
      displayName: user.displayName,
      createdAt: user.createdAt,
      collectionsCount: await _getCollectionsCount(),
      // ...
    );
  });
});
```

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

---

## 🔧 Notas técnicas

- **Avatar:** Usar `CircleAvatar` com `initials` ou `backgroundImage`
- **Edição de nome:** `InlineTextField` ou modal de edição
- **Estatísticas:** Contar via repositórios existentes (`collectionsRepositoryProvider`, `itemsByCollectionProvider`)
- **Deletar conta:** Chamar Edge Function Supabase (obrigatório para app stores)

---

## ✅ Checklist de Conclusão

- [ ] Avatar exibido
- [ ] Display name editável
- [ ] Estatísticas carregadas
- [ ] Email exibido
- [ ] Logout funciona
- [ ] Delete account com confirmação
- [ ] Design segue screenshot

