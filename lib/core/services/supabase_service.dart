import 'package:supabase_flutter/supabase_flutter.dart';

/// Acesso global ao cliente Supabase após inicialização em main.dart.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;
}
