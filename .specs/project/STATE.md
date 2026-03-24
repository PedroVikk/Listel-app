# STATE — WishNesita

_Memória persistente: decisões, bloqueios, lições aprendidas, tarefas pendentes e ideias adiadas._

---

## Decisions

_Decisões arquiteturais tomadas e o porquê._

- **Android-first**: APK como alvo principal. iOS fora de escopo por ora.
- **Offline-first / Isar**: persistência local com Isar no MVP. Backend Supabase preparado para v2.
- **Supabase preparado, não ativo**: repository pattern abstrai a fonte de dados — trocar Isar por Supabase é só adicionar RemoteDataSource, sem tocar domain/presentation.
- **Riverpod**: gerenciamento de estado. Escolhido sobre BLoC por ser mais moderno, menos verboso e type-safe com code generation.
- **Clean Architecture prática**: layers por feature (data/domain/presentation), sem over-engineering. Use cases apenas onde a lógica de negócio é não-trivial.
- **Share Intent**: funcionalidade central do MVP — diferencial do app vs simples lista de desejos.
- **Feature-first structure**: organização por features (não por layers), facilita escalabilidade e isolamento.
- **Flutter 3.38.4 / Dart 3.10.3**: versão instalada no ambiente de desenvolvimento.

## Blockers

_Impedimentos ativos que precisam ser resolvidos._

- Nenhum no momento.

## Todos

_Tarefas que ainda precisam de decisão ou investigação._

- [ ] Decidir entre Hive e Isar para persistência local
- [ ] Decidir entre Riverpod e BLoC para gerenciamento de estado
- [ ] Validar suporte do `receive_sharing_intent` no Android 13+ (scoped storage)
- [ ] Definir paleta de cores padrão para o tema inicial

## Lessons Learned

_O que aprendemos que deve guiar decisões futuras._

- (ainda vazio — preencher conforme o projeto evolui)

## Deferred Ideas

_Ideias boas, mas fora do escopo atual._

- Detecção automática de preço via scraping/OpenGraph
- Suporte a listas colaborativas em tempo real
- Widget na tela inicial do Android com itens pendentes
- Integração com notificações de promoção de lojas parceiras
- Exportar lista como PDF ou imagem

## Preferences

_Preferências do usuário para colaboração com o agente._

- Atuar como tech lead e engenheiro Flutter sênior
- Explicar decisões arquiteturais
- Não fazer mudanças fora do escopo
- Listar sempre os arquivos criados e alterados
- Tratar estados: loading, vazio, erro e sucesso
- Começar pela base do projeto e pelo MVP
- NUNCA fazer commit como Claude
