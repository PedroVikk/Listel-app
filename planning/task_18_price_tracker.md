# Task 18 — Verificador de Preços

## Objetivo

Ao abrir uma coleção, verificar silenciosamente os preços dos itens que possuem URL salva,
comparar com o preço armazenado e notificar o usuário (com percentual de variação) **antes**
de atualizar os valores no banco.

---

## Viabilidade

| Aspecto | Situação |
|---|---|
| Extração de preço | `MetadataExtractorService._price()` já extrai via OG tags + JSON-LD |
| Armazenamento atual | `SavedItem.price` existe no modelo Isar |
| URLs disponíveis | `SavedItem.url` já está salvo por item |
| Migração Isar | Apenas campos nullable — migração automática, sem `build_runner` |
| Cobertura de lojas | Shopee, Shein, Amazon bloqueiam bots → extração parcial (~50% dos casos) |
| Performance | 10s timeout por item; lote sequencial/paralelo controlado necessário |

---

## Modelo de dados — alterações

### `saved_item.dart` (entity)
Adicionar:
```dart
final double? lastCheckedPrice;  // preço na última verificação bem-sucedida
final DateTime? priceCheckedAt;  // quando foi verificado pela última vez
```

### `saved_item_model.dart` (Isar)
Adicionar os mesmos campos como `double?` e `DateTime?` — nullable = migração automática.

Atualizar `toDomain()` e `fromDomain()`.

---

## Novo serviço — `PriceCheckerService`

**Arquivo:** `lib/core/services/price_checker_service.dart`

### Responsabilidades
- Recebe lista de `SavedItem` com `url != null` e `price != null`
- Filtra itens onde `priceCheckedAt` é null **ou** tem mais de 1h
- Busca preços em paralelo com concorrência limitada (máx 3 simultâneos)
- Retorna lista de `PriceChange`

### Modelo de resultado
```dart
class PriceChange {
  final SavedItem item;
  final double oldPrice;
  final double newPrice;
  double get percentChange => ((newPrice - oldPrice) / oldPrice) * 100;
  bool get isIncrease => newPrice > oldPrice;
}
```

### Lógica de throttle
- Só re-verifica se `priceCheckedAt == null || DateTime.now().difference(priceCheckedAt!) > 1h`
- Atualiza `priceCheckedAt` mesmo quando o novo preço não é encontrado (evita re-tentativas constantes)

---

## Provider

**Arquivo:** `lib/features/items/presentation/providers/price_checker_provider.dart`

```dart
// Provider disparado manualmente (não auto-run no build)
final priceCheckerProvider = StateNotifierProvider.family<
    PriceCheckerNotifier, AsyncValue<List<PriceChange>>, String>(
  (ref, collectionId) => PriceCheckerNotifier(ref, collectionId),
);
```

Estado interno: `idle | loading | done(changes) | error`

---

## UX — fluxo completo

```
Usuário abre CollectionDetailPage
        │
        ▼
Provider inicia verificação em background (sem bloquear a UI)
        │
        ▼ (quando termina, se houver mudanças)
Bottom sheet desliza de baixo com resumo:
┌─────────────────────────────────────────────┐
│  📊 Variação de preços                       │
│                                             │
│  ↑ Tênis Nike Air Max    R$ 289 → R$ 319   │
│    +10,4%                                  │
│                                             │
│  ↓ Perfume Chanel        R$ 450 → R$ 399   │
│    -11,3%                                  │
│                                             │
│  [Ignorar]          [Atualizar preços]      │
└─────────────────────────────────────────────┘
        │
        ├── "Ignorar" → bottom sheet fecha, preços NÃO são atualizados
        └── "Atualizar" → salva novos preços no Isar, fecha sheet
```

### Regras de exibição
- Bottom sheet aparece apenas quando há **ao menos 1 mudança confirmada**
- Itens onde não foi possível extrair preço são **ignorados silenciosamente**
- Um ícone de loading discreto na AppBar durante a verificação (ex: `CircularProgressIndicator` pequeno no `actions`)
- Se a verificação falhar inteiramente (sem conexão), não mostra nada

---

## Arquivos a criar/modificar

| Arquivo | Ação |
|---|---|
| `lib/features/items/domain/entities/saved_item.dart` | Adicionar `lastCheckedPrice`, `priceCheckedAt` |
| `lib/features/items/data/models/saved_item_model.dart` | Adicionar campos + atualizar `toDomain`/`fromDomain` |
| `lib/core/services/price_checker_service.dart` | **Criar** — lógica de verificação + `PriceChange` |
| `lib/features/items/presentation/providers/price_checker_provider.dart` | **Criar** — StateNotifier + estado |
| `lib/features/collections/presentation/pages/collection_detail_page.dart` | Disparar verificação + mostrar bottom sheet |
| `lib/features/items/data/repositories/items_repository_impl.dart` | Adicionar `updatePrice(String id, double price, DateTime checkedAt)` |

---

## Considerações de implementação

### Concorrência controlada
Usar `Stream.fromIterable` + `asyncMap` com semáforo, ou processar em lotes de 3:
```dart
// Pseudo-código
for (final chunk in items.slices(3)) {
  final results = await Future.wait(chunk.map(_checkOne));
  // processa results...
}
```

### Não bloquear navegação
O provider deve iniciar **após** o primeiro frame renderizado:
```dart
// Em CollectionDetailPage.initState equivalente (ConsumerStatefulWidget)
WidgetsBinding.instance.addPostFrameCallback((_) {
  ref.read(priceCheckerProvider(collectionId).notifier).check(items);
});
```

### Lojas com melhor suporte
- ✅ Mercado Livre — JSON-LD confiável
- ✅ AliExpress — OG tags disponíveis  
- ⚠️ Amazon — bloqueia bots; slug fallback sem preço
- ❌ Shopee / Shein — JavaScript rendering; preço não disponível no HTML estático

---

## Critérios de aceitação

- [ ] Ao abrir coleção com itens que têm URL + preço, verificação inicia automaticamente
- [ ] Loading indicator discreto durante verificação
- [ ] Bottom sheet aparece com itens que tiveram preço alterado (↑ ou ↓) e percentual
- [ ] "Ignorar" fecha sem salvar; "Atualizar preços" salva e fecha
- [ ] Itens sem URL ou sem preço original são ignorados
- [ ] Verificação não re-executa dentro de 1h do último check
- [ ] Falha de rede não gera erro visível — silencia graciosamente
- [ ] Funciona para coleções locais e compartilhadas
