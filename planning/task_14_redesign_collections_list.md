# Tarefa 14 — Redesign: Tela de Lista de Coleções ("Minhas Listas")

**Status:** ❌ Não implementado  
**Prioridade:** Alta — faz parte do redesign geral do frontend  
**Depende de:** task_15 (foto de capa da coleção) deve ser concluída antes ou em paralelo

---

## ⚠️ Perguntas a responder ANTES de implementar

> Estas perguntas serão enviadas ao Pedro antes de produzir qualquer código.

1. **Ícone de camadas (direita do bottom bar):** qual é a função dele? Opções prováveis: alternar grid/lista, acessar listas compartilhadas, ver "camadas" de categorias — confirmar.
2. **Toggle grid/lista:** o botão de alternar layout fica no bottom bar (substituindo o ícone de camadas?) ou em outro lugar (top bar, canto da tela)?
3. **Lupa (pesquisa):** ela aparece no bottom bar, no top bar, ou abre como um campo ao tocar em algum ícone? O mockup não mostra — onde ela vai ficar?
4. **Ícone de perfil e engrenagem (configurações):** sumiram do topo neste redesign — foram removidos, movidos para outra tela, ou ficam em algum menu hamburguer/drawer?
5. **Seta de voltar no topo esquerdo:** esta tela é a home principal ou há uma tela acima dela? No app atual a home não tem back.
6. **Título "MINHAS LISTAS":** é sempre fixo ou muda conforme contexto (ex: dentro de uma lista compartilhada)?
7. **Estado vazio (zero coleções):** qual o visual quando não há nenhuma coleção criada ainda?
8. **Ordem dos cards:** alguma lógica de ordenação (mais recente, alfabética, manual por drag)?
9. **Coleções compartilhadas:** aparecem misturadas com as locais ou em seção separada?
10. **Altura dos cards no modo lista:** o mockup mostra cards bem altos (~160px). Isso é fixo ou proporcional?

---

## Contexto

A tela atual (`HomePage`) exibe coleções em um **grid de 2 colunas** com emoji + nome.  
O redesign muda para **cards full-width em lista vertical** com foto de capa real, além de adicionar um toggle para voltar ao estilo grid.

**Arquivo atual:** `lib/features/collections/presentation/pages/home_page.dart`

---

## O que muda visualmente

### Layout dos cards
- **Antes:** grid 2 colunas, emoji centralizado + nome abaixo
- **Depois:** lista vertical, cards full-width com foto de capa ocupando todo o card e nome sobreposto na parte inferior esquerda (com gradiente escuro para legibilidade)
- Cantos arredondados mantidos (consistent com design system atual)

### Bottom bar
- **Antes:** `+` (add item) | `=` (?) | lupa (pesquisa)
- **Depois:** `+` (nova coleção) | logo Listel (centro, decorativo) | ícone de camadas (função a confirmar — ver perguntas)

### Top bar
- Título "MINHAS LISTAS" centralizado, fonte bold rosa
- Seta de voltar no leading (a confirmar — ver pergunta 5)
- Ícones de perfil/settings removidos ou movidos (a confirmar — ver pergunta 4)

### Toggle de layout
- Botão para alternar entre vista **lista** (novo padrão) e **grid** (estilo atual)
- Preferência salva localmente (SharedPreferences ou `settings_repository`)

---

## O que muda funcionalmente

### Pesquisa
- A lupa passa a buscar em **dois níveis**:
  1. Nome da coleção (já existia conceitualmente, mas não implementado)
  2. Nome de itens dentro das coleções
- Resultados mostram de qual coleção o item vem

### Criação de coleção
- O `+` no bottom bar abre a tela/modal de criar coleção
- A nova criação precisará de suporte a foto de capa (ver task_15)

---

## Arquivos envolvidos

| Arquivo | Ação |
|---|---|
| `lib/features/collections/presentation/pages/home_page.dart` | Refatorar layout completo |
| `lib/features/collections/presentation/providers/collections_provider.dart` | Adicionar provider de pesquisa se necessário |
| `lib/core/router/app_router.dart` | Ajustar rota se a home mudar de estrutura |
| `lib/core/services/settings_repository_impl.dart` | Salvar preferência grid/lista |
| `lib/features/settings/domain/entities/theme_settings.dart` | Adicionar campo `preferListView` se usar Isar |

---

## Comportamento do toggle grid/lista

- **Lista (padrão novo):** cards full-width, foto alta (~160px), nome sobreposto
- **Grid (estilo atual):** 2 colunas, foto quadrada, nome abaixo — mantém visual atual como opção
- Ícone do toggle muda conforme estado atual (ex: `grid_view` quando está em lista, `view_list` quando está em grid)
- Preferência persiste entre sessões

---

## Observações

- Os cards precisam de um `Hero` tag para animar a transição para o detalhe da coleção (melhoria visual desejável).
- O gradiente sobre a foto (para legibilidade do nome) deve usar a cor primária do tema para manter consistência com as cores do usuário.
- `cached_network_image` já está no projeto — usar para fotos de capa vindas de URL. Para fotos locais, usar `Image.file`.
