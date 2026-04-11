---
dominio: Autenticação
tags: [auth, supabase-auth, perfil, avatar, login, jwt, usuario]
depende-de: []
afeta: [listas-compartilhadas]
atualizado: 2026-04-10
status: mapeado
instrucao-para-agentes: |
  Leia este arquivo quando sua tarefa envolver login, logout, perfil de usuário ou avatar.
  Para regras de acesso a dados (RLS), leia dominios/listas-compartilhadas.md.
---

# Domínio: Autenticação

## Visão geral

A autenticação é feita via Supabase Auth. O usuário faz login para acessar funcionalidades de listas compartilhadas. O perfil do usuário inclui nome e avatar (foto de perfil). O JWT gerado pelo Supabase é usado para autenticar todas as chamadas ao banco remoto e Realtime.

## Fluxo principal (login)

1. Usuário acessa tela de login
2. Insere credenciais (email/senha ou provider social — ⚠️ A VALIDAR quais providers estão ativos)
3. Supabase Auth valida e retorna JWT
4. App armazena sessão; usuário redirecionado para a tela principal
5. JWT renovado automaticamente pelo SDK em background (~1h)

## Fluxo alternativo (perfil)

1. Usuário acessa tela de perfil via menu/ícone
2. `UserProfileScreen` exibe nome e avatar atuais
3. Usuário edita nome ou seleciona nova foto de avatar
4. Dados atualizados via Supabase Auth (`updateUser`) ou tabela de profiles
5. Avatar salvo localmente e/ou no Supabase Storage — ⚠️ A VALIDAR

## Regras de negócio

### RN-AUTH-001: Autenticação obrigatória para listas compartilhadas
- **Descrição**: Funcionalidades de listas compartilhadas exigem usuário autenticado
- **Condição**: Ao tentar criar ou entrar em lista compartilhada
- **Ação**: Redirecionar para tela de login
- **Exceções**: Coleções locais funcionam sem autenticação
- **Exemplo**: Usuário não logado → funcionalidades locais disponíveis; compartilhamento bloqueado

### RN-AUTH-002: JWT renovado automaticamente
- **Descrição**: O SDK do Supabase renova o JWT em background antes da expiração (~1h)
- **Condição**: Sempre que há sessão ativa
- **Ação**: SDK gerencia renovação; canais Realtime já abertos precisam de retry manual (ver RN-COMP-008)
- **Exceções**: Canais Realtime não são atualizados automaticamente com o novo JWT — tratado via retry em `remote_items_repository_impl.dart`
- **Exemplo**: Usuário fica 90min no app → JWT renovado silenciosamente → API calls continuam funcionando

### RN-AUTH-003: Perfil editável pelo usuário
- **Descrição**: Usuário pode editar nome e avatar no perfil
- **Condição**: Usuário autenticado
- **Ação**: `UserProfileScreen` permite edição; `updateUser` ou update na tabela `profiles`
- **Exceções**: Nenhuma documentada
- **Exemplo**: Usuário muda nome de "Pedro" para "Pedro Viktor" → nome atualizado no perfil e visível para outros membros de listas compartilhadas

### RN-AUTH-004: Avatar com suporte a imagem local
- **Descrição**: O avatar do usuário pode ser uma foto local do dispositivo
- **Condição**: Usuário seleciona foto da galeria ou câmera na tela de perfil
- **Ação**: Foto selecionada, opcionalmente cropada, e salva (local e/ou remoto — ⚠️ A VALIDAR)
- **Exceções**: Nenhuma documentada
- **Exemplo**: Usuário seleciona selfie → avatar atualizado na tela de perfil

## Casos especiais e exceções globais

- Funcionalidades locais (coleções, itens locais) operam sem qualquer autenticação
- O app é usável offline para coleções locais mesmo sem conta Supabase

## Limites e parâmetros

| Parâmetro | Valor | Observação |
|---|---|---|
| JWT TTL | ~1h | Renovado automaticamente pelo SDK |
| Retry JWT (Realtime) | 5s | Implementado manualmente em remote_items_repository_impl.dart |

## Perguntas em aberto

- [ ] Quais providers de login estão ativos? (email/senha, Google, Apple?)
- [ ] O avatar é salvo no Supabase Storage ou apenas localmente?
- [ ] A tabela `profiles` existe separada do Supabase Auth, ou usa apenas `auth.users`?
- [ ] Existe fluxo de recuperação de senha?
- [ ] O que acontece com as listas compartilhadas ao deletar a conta?
