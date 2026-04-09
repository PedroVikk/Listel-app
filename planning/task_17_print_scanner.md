# Task 17 — Escanear Print para Adicionar Item

**Status:** pendente  
**Prioridade:** média  
**Escopo:** nova forma de criação de item via OCR em screenshot/foto de produto

---

## Problema

O app tem duas formas de adicionar itens:
1. **Manualmente** — preencher nome, preço, foto, link um a um
2. **Share intent** — compartilhar URL de um app de loja

Falta uma terceira forma: o usuário tem um **print de produto** (screenshot de uma loja, foto de catálogo, print de story) e quer salvar o item de forma rápida, sem precisar abrir o site e compartilhar.

---

## Solução

Adicionar a opção **"Escanear print"** no fluxo de criação de item. O usuário seleciona ou tira uma foto do produto; o app roda OCR on-device via ML Kit, extrai o **nome** e o **preço** automaticamente e pré-preenche o formulário. A própria imagem do print vira a foto do item.

---

## Fluxo UX

```
Collection Detail
  └─ FAB / Bottom bar "Adicionar item"
       ├─ [atual] Adicionar manualmente   → CreateItemPage
       ├─ [atual] Importar link           → (share intent já existente)
       └─ [novo]  Escanear print          → picker → OCR → CreateItemPage pré-preenchido
```

1. Usuário toca "Escanear print" (bottom sheet de opções ou novo botão na CreateItemPage)
2. Picker abre: **Galeria** (screenshots) ou **Câmera** (foto ao vivo)
3. Loading overlay enquanto OCR processa
4. `CreateItemPage` carrega com campos pré-preenchidos:
   - **Foto**: a imagem selecionada
   - **Nome**: linha detectada como mais provável nome do produto
   - **Preço**: primeiro valor monetário detectado (ou menor, se houver "de/por")
5. Usuário confirma, edita se necessário, salva

---

## Arquitetura

### Novo serviço
`lib/core/services/print_scanner_service.dart`

```dart
class PrintScannerService {
  Future<PrintScanResult> scan(String imagePath) async { ... }
}

class PrintScanResult {
  final String? name;
  final double? price;
}
```

### Lógica de extração

**Nome:**
- Roda ML Kit `TextRecognizer` na imagem
- Coleta todos os `TextLine.text` com comprimento ≥ 10 chars
- Remove linhas que:
  - São apenas preço (`R$ xxx`)
  - Contêm palavras de UI: `comprar`, `adicionar`, `frete`, `parcelar`, `entrega`, `grátis`, `ver mais`, `avaliações`, `estoque`
  - Têm caracteres suspeitos (emojis de botão, `•••`, etc.)
- Retorna a **linha mais longa restante** como nome candidato
- Fallback: retorna `null` (usuário preenche manualmente)

**Preço:**
- Regex: `R\$\s*\d{1,3}(?:\.\d{3})*,\d{2}` e variante sem `R$`: `\d{1,3}(?:\.\d{3})*,\d{2}`
- Coleta todos os matches, converte para `double`
- Se apenas 1 valor → usa ele
- Se múltiplos valores (ex: "De R$ 199,90 por R$ 89,90") → usa o **menor** (preço final de desconto)
- Fallback: retorna `null`

---

## Dependências

| Pacote | Motivo |
|---|---|
| `google_mlkit_text_recognition: ^0.13.1` | OCR on-device, sem API key, funciona offline |

**Requisito Android:** `minSdkVersion 21` (já é o padrão atual do Flutter; verificar `android/app/build.gradle`)

> **Sem custo de API.** Todo o processamento é local no dispositivo. Funciona offline.

---

## Arquivos a criar / modificar

| Arquivo | Ação |
|---|---|
| `pubspec.yaml` | + `google_mlkit_text_recognition` |
| `android/app/build.gradle` | verificar/garantir `minSdkVersion 21` |
| `lib/core/services/print_scanner_service.dart` | **criar** — serviço OCR |
| `lib/features/items/presentation/pages/create_item_page.dart` | adicionar opção "Escanear print" no bottom sheet da foto, loading state, pré-preenchimento |

---

## Critérios de aceitação

- [ ] Opção "Escanear print" visível no `CreateItemPage` (bottom sheet ao tocar na área de foto)
- [ ] Ao selecionar imagem, loading indicator aparece enquanto OCR processa
- [ ] Campo **Nome** é preenchido automaticamente se texto detectado (editável)
- [ ] Campo **Preço** é preenchido automaticamente se valor monetário detectado (editável)
- [ ] Campo **Foto** recebe a imagem do print
- [ ] Se OCR não detectar nome ou preço, campos ficam vazios (sem erro)
- [ ] Fluxo funciona 100% offline
- [ ] Não quebra os dois outros fluxos existentes (manual e share intent)

---

## Limitações conhecidas

- OCR funciona bem em prints de texto nítido; fotos borradas ou com muito ruído retornam menos texto
- Lojas que exibem preço em imagem (banner) em vez de texto HTML podem não ter o preço detectado
- O campo nome é uma heurística — não é extração semântica; prints muito poluídos podem retornar uma linha errada
- iOS requer modelo de ML Kit baixado no primeiro uso (~3 MB, silencioso)
