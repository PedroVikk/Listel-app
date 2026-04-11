# Tarefa 23 — Notificações push para listas compartilhadas

**Status:** ❌ Não implementado  
**Prioridade:** Alta  

---

## Problema

Quando um membro adiciona ou compra um item em uma lista compartilhada, os outros membros só percebem ao abrir o app. Não há feedback ativo da colaboração.

---

## O que precisa ser feito

### 1. Configurar FCM (Firebase Cloud Messaging)
- Adicionar `firebase_messaging` ao `pubspec.yaml`
- Criar projeto Firebase e registrar o app Android/iOS
- Adicionar `google-services.json` (Android) e `GoogleService-Info.plist` (iOS)
- Salvar o FCM token do usuário na tabela `profiles` (novo campo `fcm_token`)

### 2. Supabase Edge Function: `send-push-notification`
**Arquivo:** `supabase/functions/send-push-notification/index.ts`
- Recebe `collectionId`, `actorId`, `action` (`item_added` | `item_purchased`), `itemName`
- Busca todos os membros da coleção exceto o `actorId`
- Busca o `fcm_token` de cada membro em `profiles`
- Chama a API do FCM para enviar notificação

### 3. Trigger Supabase: disparar a Edge Function
- Criar trigger ou webhook no Supabase que chama `send-push-notification` ao:
  - INSERT em `shared_items` (item adicionado)
  - UPDATE de `status` em `shared_items` para `purchased` (item comprado)
- Alternativa: chamar a Edge Function diretamente no `RemoteItemsRepositoryImpl` após cada operação

### 4. Permissão no app
**Arquivo:** `lib/core/services/notification_service.dart`
- Solicitar permissão de notificação push na primeira entrada em lista compartilhada
- Registrar handler para notificações recebidas em foreground/background

### 5. Salvar FCM token ao logar
**Arquivo:** `lib/features/auth/data/repositories/`
- Após login bem-sucedido, capturar `FirebaseMessaging.instance.getToken()` e salvar em `profiles.fcm_token`
- Renovar token no `onTokenRefresh`

---

## Arquivos envolvidos

| Arquivo | Ação |
|---|---|
| `pubspec.yaml` | Adicionar `firebase_messaging` |
| `supabase/functions/send-push-notification/index.ts` | Nova Edge Function |
| `lib/core/services/notification_service.dart` | Handler de push + permissão |
| `lib/features/auth/data/repositories/` | Salvar FCM token ao logar |
| Supabase SQL | Novo campo `fcm_token` em `profiles` |

---

## Exemplos de notificações

- "João adicionou **Fone Sony WH-1000XM5** na lista Casamento"
- "Maria marcou **Cafeteira Nespresso** como comprado"

---

## Observações

- iOS exige configuração de APNs certificates no Firebase
- FCM token pode mudar — sempre atualizar no login e no `onTokenRefresh`
- Não notificar o próprio autor da ação
