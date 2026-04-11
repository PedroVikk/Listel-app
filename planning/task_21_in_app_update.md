
# Task 21 — In-App Update via Supabase

## Objetivo

Implementar um sistema de atualização in-app que notifica os usuários quando uma nova versão do APK está disponível, usando Supabase Storage para hospedar o APK e uma tabela `app_versions` para controle de versões.

---

## Contexto

O app é distribuído via APK direto (fora da Play Store). Atualmente não há mecanismo de atualização — usuários ficam em versões antigas indefinidamente.

**Solução:** No startup do app, checar a tabela `app_versions` no Supabase. Se a versão remota for maior que a local, exibir um dialog opcional para o usuário baixar a nova versão.

---

## Decisões de design

- **Hospedagem do APK:** Supabase Storage (bucket `apk`, arquivo fixo `wishnesita-latest.apk`)
- **Tipo de update:** Opcional — usuário pode ignorar
- **Gestão de versões:** Script `publish.sh` (um comando só faz tudo)
- **Frequência de checagem:** Apenas no startup do app

---

## Estrutura da tabela `app_versions`

```sql
create table app_versions (
  id          serial primary key,
  version     text not null,          -- ex: "1.2.0"
  version_code int not null,          -- ex: 12 (comparação numérica)
  download_url text not null,         -- URL pública do APK no Storage
  release_notes text,                 -- changelog opcional
  force_update boolean default false, -- reservado para uso futuro
  created_at  timestamptz default now()
);
```

Apenas uma linha ativa — sempre a mais recente (maior `version_code`).

---

## Estrutura de arquivos

```
supabase/
  migrations/
    YYYYMMDDHHMMSS_create_app_versions.sql

lib/
  core/
    services/
      app_update_service.dart        ← checa versão no startup
  features/
    update/
      presentation/
        providers/
          update_provider.dart
        widgets/
          update_dialog.dart

scripts/
  publish.sh                         ← upload APK + atualiza tabela
```

---

## Fluxo de funcionamento

```
App startup
  └── AppUpdateService.checkForUpdate()
        └── SELECT * FROM app_versions ORDER BY version_code DESC LIMIT 1
              └── versão remota > versão local?
                    ├── SIM → exibe UpdateDialog (opcional, usuário pode fechar)
                    └── NÃO → segue normalmente
```

---

## Script publish.sh

```bash
# Uso:
./scripts/publish.sh 1.2.0 12 "Correções de bug e melhorias"

# O script:
# 1. Faz build do APK release
# 2. Upload para Supabase Storage (sobrescreve wishnesita-latest.apk)
# 3. Atualiza tabela app_versions com nova versão
```

Requer: `supabase` CLI autenticado, `flutter` no PATH.

---

## Tasks de implementação

- [ ] 1. Migration SQL — criar tabela `app_versions`
- [ ] 2. Criar bucket `apk` no Storage + política de acesso público
- [ ] 3. Criar script `scripts/publish.sh`
- [ ] 4. Criar `AppUpdateService` (checa versão, retorna info)
- [ ] 5. Criar `update_provider.dart`
- [ ] 6. Criar `UpdateDialog` (dialog opcional com changelog)
- [ ] 7. Integrar checagem no startup do app
- [ ] 8. Testar fluxo completo

---

## Dependências Flutter necessárias

```yaml
# pubspec.yaml
package_info_plus: ^8.x    # ler versão atual do app
url_launcher: ^6.x         # abrir link de download (já pode existir)
```

---

## Notas

- O campo `force_update` está na tabela mas **não será usado nesta task** — reservado para futuro
- O APK no Storage sempre tem o mesmo nome (`wishnesita-latest.apk`) — sem histórico de versões para economizar espaço
- A URL pública do Storage é estável e não muda entre versões
