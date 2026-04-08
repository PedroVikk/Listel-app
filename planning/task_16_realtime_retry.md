# Tarefa 16 — Retry automático em streams Realtime com token expirado

**Status:** 🔄 Em andamento  
**Prioridade:** Alta — `RealtimeSubscribeException: InvalidJWTToken` derruba a tela de lista compartilhada

---

## Problema

O JWT do Supabase expira (~1h). O SDK renova o token no background, mas os canais
Realtime já abertos não recebem o novo token automaticamente.
Resultado: `RealtimeSubscribeException(status: channelError, details: InvalidJWTToken: Token has expired N seconds ago)` é propagado como erro no stream, e a UI trava mostrando o erro.

---

## O que precisa ser feito

### 1. Retry em `watchByCollection`
**Arquivo:** `lib/features/items/data/repositories/remote_items_repository_impl.dart`

- Substituir o `.stream()` simples por um `StreamController` que relança a
  subscription após `RealtimeSubscribeException`.
- Antes de reconectar, chamar `auth.refreshSession()` para garantir token fresco.
- Outros erros continuam sendo propagados normalmente.

### 2. Retry em `watchMembers`
**Arquivo:** `lib/features/sharing/data/repositories/supabase_sharing_repository_impl.dart`

- Mesma lógica: `StreamController` com retry em `RealtimeSubscribeException`.
- Delay de 5s antes de reconectar (evita storm de requests em falha contínua).

---

## Comportamento esperado

| Situação | Antes | Depois |
|---|---|---|
| Token expira com app aberto | UI trava com erro vermelho | Reconecta silenciosamente em ~5s |
| Queda de rede + volta | Erro propagado | Retry até reconectar |
| Outros erros (RLS, etc.) | Propagado | Continua propagando normalmente |

---

## Arquivos alterados

- `lib/features/items/data/repositories/remote_items_repository_impl.dart`
- `lib/features/sharing/data/repositories/supabase_sharing_repository_impl.dart`

---

## Notas técnicas

- Sem dependências novas (não usa rxdart).
- Padrão: `StreamController` manual + `StreamSubscription` relançada no `onError`.
- `refreshSession()` antes do retry garante que o novo canal já usa o JWT renovado.
