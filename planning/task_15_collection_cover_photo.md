# Tarefa 15 — Foto de Capa da Coleção (substituir emoji)

**Status:** ❌ Não implementado  
**Prioridade:** Alta — bloqueante para o redesign da tela de coleções (task_14)  
**Bloqueia:** task_14 (a nova UI depende de foto real nos cards)

---

## ⚠️ Perguntas a responder ANTES de implementar

> Estas perguntas serão enviadas ao Pedro antes de produzir qualquer código.

1. **Fonte da foto:** o usuário escolhe só da galeria, só da câmera, ou ambas?
2. **Foto obrigatória ou opcional?** Se o usuário não escolher foto, o card exibe o quê? Cor sólida? Gradiente? Placeholder com inicial do nome?
3. **O emoji é completamente removido** do domínio (`Collection` entity) ou mantido como fallback legado para coleções antigas?
4. **Coleções compartilhadas (Supabase):** a foto de capa vai para o Supabase Storage (como o avatar de perfil) ou fica apenas local? Se for para a nuvem, o dono da lista é o único que muda a capa, ou membros também podem?
5. **Editar capa de coleção existente:** haverá um botão específico no detalhe da coleção para trocar a foto, ou só é possível ao editar/criar a coleção?
6. **Formato/tamanho:** deve comprimir a imagem antes de salvar? Qual resolução máxima aceitável?
7. **Nome do campo no banco:** manter `emoji` como campo legado com deprecation, ou fazer migrate e renomear para `coverImagePath`?

---

## Contexto

Atualmente a entidade `Collection` tem um campo `emoji` (String) usado como identificador visual da coleção.  
O redesign substitui o emoji por uma **foto real** escolhida pelo usuário da câmera ou galeria.

Isso é uma mudança de **domínio** (entity + model + repositório) além de UI — por isso é uma task separada da task_14.

---

## O que precisa ser feito

### 1. Atualizar a entidade de domínio

**Arquivo:** `lib/features/collections/domain/entities/collection.dart`
- Adicionar campo `String? coverImagePath` (caminho local do arquivo)
- Adicionar campo `String? coverImageUrl` (URL remota — Supabase Storage, se aplicável)
- Manter `String? emoji` como legado ou remover (a confirmar — ver pergunta 3)

### 2. Atualizar o model Isar

**Arquivo:** `lib/features/collections/data/models/collection_model.dart`
- Adicionar `@Index() String? coverImagePath`
- Adicionar `String? coverImageUrl`
- Rodar `dart run build_runner build --delete-conflicting-outputs` após mudança
- **Atenção:** Isar não faz migrations automáticas de schema — coleções existentes terão `coverImagePath == null`, tratar no UI

### 3. Atualizar o repositório local

**Arquivo:** `lib/features/collections/data/repositories/collections_repository_impl.dart`
- Mapear os novos campos no `fromModel`/`toModel`

### 4. Atualizar o repositório remoto (se foto vai para nuvem)

**Arquivo:** `lib/features/collections/data/repositories/remote_collections_repository_impl.dart`
- Se a foto for salva no Supabase Storage: adicionar método `uploadCoverImage(File image, String collectionId)` retornando URL pública
- Atualizar `shared_collection_dto.dart` com campo `cover_image_url`

### 5. Atualizar tela de criação/edição de coleção

**Arquivo:** `lib/features/collections/presentation/pages/create_edit_collection_page.dart`
- Adicionar widget de seleção de foto (área clicável que abre `showModalBottomSheet` com opções Câmera / Galeria)
- Exibir preview da foto selecionada no lugar do seletor de emoji
- Ao salvar, copiar a imagem para o diretório de documentos do app (`path_provider`) e salvar o path
- Dependências a verificar: `image_picker` (pode já estar no projeto para task_12), `path_provider`

### 6. Atualizar os cards de coleção

**Arquivo:** `lib/features/collections/presentation/pages/home_page.dart` (e widget de card se extraído)
- Exibir `Image.file(File(collection.coverImagePath!))` se `coverImagePath != null`
- Exibir `Image.network(collection.coverImageUrl!)` via `cached_network_image` se for URL
- Exibir placeholder (cor/gradiente/inicial) se nenhuma foto disponível

### 7. Atualizar o detalhe da coleção

**Arquivo:** `lib/features/collections/presentation/pages/collection_detail_page.dart`
- Usar a foto de capa no cabeçalho da tela (se o redesign da tela de detalhe utilizar)
- Adicionar botão/opção para trocar a foto (a confirmar — ver pergunta 5)

---

## Arquivos envolvidos

| Arquivo | Ação |
|---|---|
| `lib/features/collections/domain/entities/collection.dart` | Adicionar `coverImagePath`, `coverImageUrl` |
| `lib/features/collections/data/models/collection_model.dart` | Adicionar campos + rebuild Isar |
| `lib/features/collections/data/models/collection_model.g.dart` | Regenerado automaticamente |
| `lib/features/collections/data/models/shared_collection_dto.dart` | Adicionar `cover_image_url` se foto vai para nuvem |
| `lib/features/collections/data/repositories/collections_repository_impl.dart` | Mapear novos campos |
| `lib/features/collections/data/repositories/remote_collections_repository_impl.dart` | Upload para Storage (se aplicável) |
| `lib/features/collections/presentation/pages/create_edit_collection_page.dart` | Seletor de foto |
| `lib/features/collections/presentation/pages/home_page.dart` | Exibir foto nos cards |
| `lib/features/collections/presentation/pages/collection_detail_page.dart` | Cabeçalho com foto |
| `pubspec.yaml` | Verificar/adicionar `image_picker`, `path_provider` |

---

## Supabase (se foto vai para nuvem)

| Recurso | Ação necessária |
|---|---|
| Storage bucket `collection-covers` | Criar com RLS: dono pode insert/update/delete, membros podem select |
| Coluna `cover_image_url` na tabela `collections` | `ALTER TABLE collections ADD COLUMN cover_image_url text;` |

Política RLS sugerida:
```sql
-- Upload: apenas o dono da coleção
CREATE POLICY "cover_owner" ON storage.objects
  FOR ALL USING (
    bucket_id = 'collection-covers'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Leitura: membros da coleção (ou público, se preferir simplificar)
CREATE POLICY "cover_public" ON storage.objects
  FOR SELECT USING (bucket_id = 'collection-covers');
```

---

## Observações

- `path_provider` provavelmente já está no projeto (Isar o usa internamente) — verificar antes de adicionar.
- Comprimir a imagem antes de salvar é altamente recomendado: fotos de câmera podem ter 5-10MB. Usar `image` package ou `flutter_image_compress` para reduzir para ~800x800px / 200KB antes de salvar localmente.
- Ao deletar uma coleção, deletar também o arquivo de imagem local associado para não acumular arquivos órfãos no storage do dispositivo.
- Coleções antigas (com `emoji` e sem `coverImagePath`) devem funcionar normalmente — o placeholder entra automaticamente quando `coverImagePath == null`.
