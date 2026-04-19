import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectionState {
  online,
  offline,
}

/// Monitora o estado de conexão (online/offline) usando connectivity_plus.
/// Emite ConnectionState.online quando há internet, offline caso contrário.
final connectionStateProvider = StreamProvider<ConnectionState>((ref) {
  return Connectivity().onConnectivityChanged.map((result) {
    return result == ConnectivityResult.none
        ? ConnectionState.offline
        : ConnectionState.online;
  });
});

/// Valor booleano derivado de connectionStateProvider para verificar se está online.
/// Mais conveniente para lógica de negócio que precisa apenas de um bool.
final isOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((result) {
    return result != ConnectivityResult.none;
  });
});
