---
dominio: Coleções
tags: [collection, coleção, isar, local, cover, emoji, foto-de-capa]
depende-de: []
afeta: [itens, listas-compartilhadas, pesquisa-global]
atualizado: 2026-04-10
status: mapeado
instrucao-para-agentes: |
  Leia este arquivo quando sua tarefa envolver criar, editar, excluir ou exibir coleções locais.
  Para listas compartilhadas (Supabase), leia também dominios/listas-compartilhadas.md.
---

# Domínio: Coleções

## Visão geral

Coleções são os agrupadores de itens de desejo. O usuário cria coleções locais armazenadas no Isar. Cada coleção pode ter nome, foto de capa (com crop), e um emoji legado. Coleções locais são exclusivas do dispositivo e não sincronizam com outros usuários.

## Fluxo principal

1. Usuário toca "Nova coleção" na `HomePage`
2. `CreateEditCollectionPage` exibe formulário: nome + seletor de foto de capa
3. Usuário opcionalmente seleciona foto (galeria ou câmera) → crop quadrado via UCrop
4. Foto salva em `Documents/collection_covers/` com nome único
5. `CollectionsNotifier.create()` persiste no Isar com `coverImagePath`
6. Coleção aparece na lista da `HomePage` como card com fundo da foto (ou emoji/inicial)

## Regras de negócio

### RN-COL-001: Nome obrigatório
- **Descrição**: Toda coleção deve ter um nome não vazio
- **Condição**: Ao salvar (criar ou editar)
- **Ação**: Bloquear salvamento e exibir feedback ao usuário
- **Exceções**: Nenhuma
- **Exemplo**: Campo nome em branco → botão salvar desabilitado ou mensagem de erro

### RN-COL-002: Foto de capa é opcional
- **Descrição**: A foto de capa (`coverImagePath`) é opcional. Sem foto, o card exibe emoji legado ou inicial do nome.
- **Condição**: Sempre
- **Ação**: Se `coverImagePath == null` → fallback para emoji ou inicial; se não null → `Image.file` como fundo
- **Exceções**: Nenhuma
- **Exemplo**: Coleção "Eletrônicos" sem foto → card exibe "E" ou emoji salvo

### RN-COL-003: Crop obrigatório ao selecionar foto
- **Descrição**: Toda foto de capa deve passar pelo crop quadrado via UCrop antes de ser salva
- **Condição**: Ao selecionar imagem da galeria ou câmera
- **Ação**: Abrir UCrop com aspect ratio 1:1; só salvar após crop confirmado
- **Exceções**: Usuário cancela crop → nenhuma foto selecionada (mantém estado anterior)
- **Exemplo**: Selecionar foto retangular da galeria → UCrop abre → usuário recorta → foto quadrada salva

### RN-COL-004: Exclusão apaga foto local
- **Descrição**: Ao excluir uma coleção, o arquivo de foto de capa deve ser apagado do disco
- **Condição**: `CollectionsNotifier.delete()` quando `coverImagePath != null`
- **Ação**: Deletar o arquivo no path `coverImagePath` antes de remover do Isar
- **Exceções**: Se arquivo não existir, ignorar silenciosamente
- **Exemplo**: Excluir coleção "Roupas" → arquivo `Documents/collection_covers/abc123.jpg` é deletado

### RN-COL-005: Coleções compartilhadas não aparecem na lista local
- **Descrição**: O repositório local filtra `isShared == true` para evitar que registros Isar de listas compartilhadas apareçam na seção de coleções locais
- **Condição**: `watchAll()` e `getAll()` em `CollectionsRepositoryImpl`
- **Ação**: Aplicar filtro `isShared == false` na query Isar
- **Exceções**: Nenhuma
- **Exemplo**: Usuário tem 2 coleções locais e 1 compartilhada → `HomePage` mostra apenas 2

### RN-COL-006: Gradiente de legibilidade em cards com foto
- **Descrição**: Cards com foto de capa devem ter gradiente linear na metade inferior para garantir legibilidade do título
- **Condição**: `coverImagePath != null` em `_CollectionCard`
- **Ação**: `LinearGradient` com stops 0.45→1.0, alpha 0.70, texto do título sempre branco
- **Exceções**: Sem foto → sem gradiente, cores normais do tema
- **Exemplo**: Card "Viagem" com foto de praia → título "Viagem" em branco sobre gradiente escuro

### RN-COL-007: Emoji mantido como legado
- **Descrição**: O campo emoji ainda existe na entidade `Collection` e no banco para compatibilidade, mas não é mais exposto na UI de criação/edição
- **Condição**: Sempre
- **Ação**: Não remover o campo; simplesmente não exibir na UI; usar como fallback se `coverImagePath == null` e emoji salvo
- **Exceções**: Nenhuma
- **Exemplo**: Coleção antiga com emoji "🎮" e sem foto → card exibe "🎮"

## Casos especiais e exceções globais

- A `CreateEditCollectionPage` serve tanto para criação quanto edição — identifica pelo parâmetro `collectionId` na rota
- Coleções compartilhadas têm fluxo próprio em `create_shared_collection_page.dart` (ver domínio Listas Compartilhadas)

## Limites e parâmetros

| Parâmetro | Valor | Observação |
|---|---|---|
| Aspect ratio da foto de capa | 1:1 (quadrado) | Obrigatório via UCrop |
| Diretório de fotos | `Documents/collection_covers/` | Path absoluto no dispositivo |
| Nome mínimo | 1 caractere | Campo não pode ser vazio |

## Perguntas em aberto

- [ ] Existe limite de tamanho de arquivo para foto de capa?
- [ ] Existe limite máximo de coleções por usuário?
