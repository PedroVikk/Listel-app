# Tarefa 11 — Ícone do launcher dinâmico (trocável pelo usuário)

**Status:** ✅ Implementado (2026-04-07)
**Prioridade:** Alta — identidade visual + diferencial de personalização

---

## Objetivo

Permitir que o usuário troque o ícone do app no launcher do Android diretamente pelas configurações, escolhendo entre variantes pré-definidas por nós.

---

## Abordagem técnica

### Android: ActivityAlias + PackageManager

A única forma confiável de trocar o ícone do launcher no Android sem root é via:

1. **`<activity-alias>`** no `AndroidManifest.xml` — uma entrada por variante de ícone, cada uma apontando para um mipmap diferente.
2. **`PackageManager.setComponentEnabledSetting()`** — habilita o alias desejado e desabilita os demais.
3. O sistema Android persiste qual alias está habilitado, então não é necessário salvar no Isar.

> **Nota importante:** A `<activity>` principal NÃO deve ter o intent-filter `LAUNCHER` — ele é movido para os aliases. Isso é obrigatório para a troca funcionar.

### Flutter: MethodChannel

- Canal: `com.wishnesita/app_icon`
- Métodos: `setIcon({icon: String})` e `getActiveIcon() → String`
- Serviço Flutter: `lib/core/services/app_icon_service.dart`

---

## Variantes de ícone

| ID | Label | Mipmap | Placeholder |
|---|---|---|---|
| `default` | Padrão | `ic_launcher_default` | cópia do ic_launcher atual |
| `pink` | Rosa | `ic_launcher_pink` | cópia do ic_launcher atual |
| `dark` | Escuro | `ic_launcher_dark` | cópia do ic_launcher atual |

> **Para substituir os placeholders:** coloque PNGs 1024×1024 em `assets/icon/icon_default.png`, `icon_pink.png`, `icon_dark.png` e rode `dart run flutter_launcher_icons` com configuração por variante, ou substitua manualmente os arquivos em cada diretório `mipmap-*`.

---

## Arquivos criados/modificados

| Arquivo | Ação |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | Adicionados 3 `<activity-alias>`, LAUNCHER movido dos aliases |
| `android/app/src/main/res/mipmap-*/ic_launcher_default.png` | Criado (placeholder) |
| `android/app/src/main/res/mipmap-*/ic_launcher_pink.png` | Criado (placeholder) |
| `android/app/src/main/res/mipmap-*/ic_launcher_dark.png` | Criado (placeholder) |
| `android/app/src/main/kotlin/.../MainActivity.kt` | MethodChannel adicionado |
| `lib/core/services/app_icon_service.dart` | **Novo** — serviço Flutter |
| `lib/features/settings/presentation/providers/settings_provider.dart` | `appIconProvider` adicionado |
| `lib/features/settings/presentation/pages/settings_page.dart` | Seção "Ícone do app" adicionada |

---

## Como adicionar novas variantes no futuro

1. Adicionar PNGs em todos os diretórios `mipmap-*` com o nome `ic_launcher_NOMEDAVARIANTE.png`
2. Adicionar `<activity-alias>` no `AndroidManifest.xml`
3. Adicionar a variante na lista `AppIconVariant.all` em `app_icon_service.dart`
4. (Opcional) Adicionar preview na settings page

---

## Limitações conhecidas

- Android pode demorar alguns segundos para atualizar o ícone no launcher após a troca.
- Alguns launchers de terceiros (ex: Nova) atualizam imediatamente; o launcher padrão do Android pode exigir que o usuário volte à tela inicial.
- iOS não foi implementado (`ios: false` no projeto).
- O flag `DONT_KILL_APP` evita que o app seja fechado durante a troca, mas pode haver um breve flash de "atalho não encontrado" em alguns dispositivos.
