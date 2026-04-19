import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_orchestrator.dart';

/// Provider singleton para o SyncOrchestrator.
/// Gerencia a fila de operações offline e sincronização com Supabase.
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  return SyncOrchestrator();
});

/// Provider que monitora as estatísticas da fila de sincronização.
/// Recomputa sempre que a fila muda.
final syncQueueStatsProvider = FutureProvider<SyncQueueStats>((ref) async {
  final orchestrator = ref.watch(syncOrchestratorProvider);
  return orchestrator.getStats();
});

/// Provider que monitora se há operações pendentes.
/// Útil para mostrar indicadores de sincronização na UI.
final hasPendingSyncProvider = FutureProvider<bool>((ref) async {
  final stats = await ref.watch(syncQueueStatsProvider.future);
  return stats.pending > 0;
});
