# Tarefa 25 — QR Code para convite de lista compartilhada

**Status:** ❌ Não implementado  
**Prioridade:** Média  

---

## Problema

Compartilhar o código de convite de 8 chars via texto é pouco intuitivo em contextos presenciais (ex: casal planejando lista de casamento no mesmo lugar). Um QR code resolve isso com um toque.

---

## O que precisa ser feito

### 1. Adicionar dependência
- `qr_flutter: ^4.1.0` — gera QR code como widget

### 2. UI na tela de detalhes da lista compartilhada
**Arquivo:** `lib/features/sharing/presentation/pages/shared_collection_detail_page.dart` (ou similar)
- Botão "Compartilhar QR Code" ao lado do botão de copiar código
- Ao tocar, abre bottom sheet com:
  - QR code do deep link `listel://invite?code=XXXXXXXX`
  - Código textual abaixo do QR (fallback visual)
  - Botão "Salvar imagem" para exportar o QR como PNG

### 3. Salvar QR como imagem (opcional)
- Usar `RenderRepaintBoundary` + `toImage()` para capturar o widget como PNG
- Salvar na galeria via `image_gallery_saver` ou compartilhar via `share_plus`

---

## Arquivos envolvidos

| Arquivo | Ação |
|---|---|
| `pubspec.yaml` | Adicionar `qr_flutter` |
| `lib/features/sharing/presentation/pages/` | UI do QR code no bottom sheet |

---

## Observações

- O QR deve codificar o deep link completo: `listel://invite?code=XXXXXXXX`
- O deep link já está configurado no app (scheme `wishnesita://` — atualizar para `listel://` se o scheme for renomeado)
- Nenhuma mudança de backend necessária
