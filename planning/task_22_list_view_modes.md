# Task 22 — List View Modes (Visão de Listagem)

## Objetivo

Adicionar um seletor de modo de visualização na tela de listagem de itens de uma coleção. O usuário pode alternar entre três modos de exibição com nomes criativos. Ao trocar de modo, um snackbar/toast exibe o nome do modo ativo.

---

## UX / Posicionamento do botão

- Adicionar um `IconButton` com ícone de câmera (`Icons.camera_alt_outlined` ou similar) na AppBar da tela de itens, **ao lado do botão de compartilhar (share)**.
- Cada toque nesse botão **avança ciclicamente** entre os 3 modos: `showcase` → `priceshot` → `spotlight` → `showcase` …
- Ao mudar de modo, exibir um `SnackBar` centralizado com o **nome criativo do modo** e um ícone representativo.

---

## Os 3 Modos

| # | Nome interno | Nome exibido | O que aparece |
|---|---|---|---|
| 1 | `galeria` | **Galeria** | Tudo visível: foto, nome, preço, status, botões de ação |
| 2 | `shopping` | **Shopping** | Foto + preço sobreposto em gradiente (sem nome) |
| 3 | `vitrine` | **Vitrine** | Somente foto em destaque (grid 3 colunas, zero texto) |

### Detalhes visuais por modo

#### Galeria (padrão)
- Grid 2 colunas, `childAspectRatio: 0.70`
- Foto ocupa a parte superior do card (expand)
- Chip de preço (pill rosa) sobreposto no canto superior esquerdo
- Toggle de status no canto superior direito
- Nome abaixo da foto (2 linhas max)
- Overlay escuro + ícone de check quando comprado

#### Shopping
- Grid 2 colunas, `childAspectRatio: 0.82`
- Foto ocupa todo o card
- Gradiente escuro na parte inferior com preço em branco
- Toggle de status no canto superior direito (ícone branco)
- Sem nome — foco no visual e preço

#### Vitrine
- Grid 3 colunas, `childAspectRatio: 1` (quadrado)
- Apenas imagem, zero texto
- Overlay escuro + check quando comprado
- Toque navega para detalhe do item

---

## Snackbar de confirmação

Ao trocar de modo, mostrar:

```
[ 📸 Modo Spotlight ativado ]
```

| Modo | Ícone | Mensagem |
|---|---|---|
| Galeria | `🗂️` | Modo Galeria ativado |
| Shopping | `🛍️` | Modo Shopping ativado |
| Vitrine | `✨` | Modo Vitrine ativado |

- Duração: `2 segundos`
- Posição: `SnackBar` padrão (bottom)
- Sem ação (sem botão "Desfazer")

---

## Estado

- O modo selecionado deve ser **persistido localmente** (ex: `SharedPreferences` ou provider simples) por coleção ou globalmente — a definir na implementação.
- Usar `StateProvider<ListViewMode>` no Riverpod para controlar o modo atual.

```dart
enum ListViewMode { galeria, shopping, vitrine }
```

---

## Arquivos envolvidos (estimativa)

| Arquivo | Alteração |
|---|---|
| `lib/features/items/presentation/screens/items_screen.dart` | Adicionar botão na AppBar + lógica de ciclo de modos |
| `lib/features/items/presentation/widgets/item_card.dart` | Adaptar card para `showcase` e `priceshot` |
| `lib/features/items/presentation/widgets/item_grid_tile.dart` | Criar widget novo para modo `spotlight` |
| `lib/features/items/presentation/providers/list_view_mode_provider.dart` | Novo `StateProvider<ListViewMode>` |
| `lib/core/theme/` | Ajustes de espaçamento/tipografia se necessário |

---

## Critérios de aceite

- [ ] Botão de câmera aparece ao lado do botão de share na AppBar
- [ ] Toque no botão avança para o próximo modo ciclicamente
- [ ] Snackbar com nome criativo aparece ao trocar de modo
- [ ] Modo **Showcase** exibe o layout atual sem regressão
- [ ] Modo **Priceshot** exibe foto + nome + preço de forma compacta
- [ ] Modo **Spotlight** exibe grid só com fotos
- [ ] Toque na foto no modo Spotlight navega para o detalhe do item
- [ ] Estado do modo persiste ao sair e voltar para a tela

---

## Prioridade

`Média` — melhora a experiência de exploração de listas sem impactar fluxos críticos.
