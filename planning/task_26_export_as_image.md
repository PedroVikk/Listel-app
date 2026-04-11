# Tarefa 26 — Exportar lista como imagem (card visual)

**Status:** ❌ Não implementado  
**Prioridade:** Média  

---

## Problema

Não há forma de compartilhar a lista visualmente fora do app. Um card gerado com os itens e preços pode ser compartilhado no WhatsApp, Instagram Stories, etc., expondo o produto organicamente.

---

## O que precisa ser feito

### 1. Widget de card exportável
**Arquivo:** `lib/features/collections/presentation/widgets/collection_export_card.dart`
- Widget off-screen (fora da árvore visível) que renderiza:
  - Foto de capa da coleção (ou gradiente com cor gerada do nome)
  - Nome da coleção
  - Lista dos itens pendentes (nome + preço, máx 8 itens)
  - Se houver mais itens: "+ N itens" no final
  - Logo/watermark do Listel no rodapé

### 2. Capturar o widget como PNG
**Arquivo:** `lib/features/collections/presentation/pages/collection_detail_page.dart`
- Envolver `CollectionExportCard` com `RepaintBoundary` + chave global
- Botão "Exportar como imagem" no menu de opções da coleção (3 pontos)
- Ao tocar: `boundary.toImage(pixelRatio: 3.0)` → `ByteData` → `Uint8List`

### 3. Compartilhar a imagem
- Usar `share_plus` para abrir o seletor nativo de compartilhamento com a imagem como arquivo temporário
- Alternativa: salvar na galeria via `image_gallery_saver`

---

## Arquivos envolvidos

| Arquivo | Ação |
|---|---|
| `pubspec.yaml` | Adicionar `share_plus` (se não existir) |
| `lib/features/collections/presentation/widgets/collection_export_card.dart` | Novo widget de card |
| `lib/features/collections/presentation/pages/collection_detail_page.dart` | Botão + lógica de captura |

---

## Observações

- O card deve ter dimensão fixa (ex: 1080×1350px para Stories) independente da tela do device — usar `pixelRatio` alto
- Itens sem preço aparecem sem o valor
- Funciona para coleções locais e compartilhadas
