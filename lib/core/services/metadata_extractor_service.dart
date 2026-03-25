import 'package:http/http.dart' as http;

class ProductMetadata {
  final String? title;
  final String? imageUrl;
  final double? price;
  final String? siteName;

  const ProductMetadata({
    this.title,
    this.imageUrl,
    this.price,
    this.siteName,
  });

  bool get isEmpty => title == null && imageUrl == null && price == null;
}

class MetadataExtractorService {
  static const _timeout = Duration(seconds: 10);

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml',
    'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
  };

  static const _maxBodyBytes = 3 * 1024 * 1024; // 3 MB
  static const _maxBodyChars = 500000;

  // IPs privados e localhost que não devem ser buscados
  static final _privateHostPattern = RegExp(
    r'^(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)',
  );

  Future<ProductMetadata> extractFromUrl(String rawUrl) async {
    final url = _extractUrl(rawUrl);
    if (url == null) return const ProductMetadata();
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);
      if (response.statusCode != 200) return const ProductMetadata();

      // Rejeita respostas muito grandes
      final contentLen = response.contentLength ?? response.bodyBytes.length;
      if (contentLen > _maxBodyBytes) return const ProductMetadata();

      final body = response.body;
      final trimmed = body.length > _maxBodyChars
          ? body.substring(0, _maxBodyChars)
          : body;
      return _parseHtml(trimmed);
    } catch (_) {
      return const ProductMetadata();
    }
  }

  String? _extractUrl(String raw) {
    final match = RegExp(r'https?://[^\s]+').firstMatch(raw)?.group(0);
    if (match == null) return null;
    final uri = Uri.tryParse(match);
    if (uri == null || !['http', 'https'].contains(uri.scheme)) return null;
    // Rejeita IPs privados e localhost
    if (_privateHostPattern.hasMatch(uri.host)) return null;
    return match;
  }

  ProductMetadata _parseHtml(String html) {
    return ProductMetadata(
      title: _ogTag(html, 'title') ?? _titleTag(html),
      imageUrl: _bestImage(html),
      price: _price(html),
      siteName: _ogTag(html, 'site_name'),
    );
  }

  // ── Open Graph helpers ────────────────────────────────────────────────────

  /// Testa as duas variantes de aspas (duplas e simples) nos atributos HTML.
  String? _ogTag(String html, String prop) {
    // Cada entrada é um pattern — property antes do content e vice-versa,
    // com aspas duplas e simples separadas para evitar problemas de escaping.
    final patterns = [
      // aspas duplas — property primeiro
      '<meta[^>]+property="og:$prop"[^>]+content="([^"]+)"',
      // aspas duplas — content primeiro
      '<meta[^>]+content="([^"]+)"[^>]+property="og:$prop"',
      // aspas simples — property primeiro
      "<meta[^>]+property='og:$prop'[^>]+content='([^']+)'",
      // aspas simples — content primeiro
      "<meta[^>]+content='([^']+)'[^>]+property='og:$prop'",
    ];

    for (final pattern in patterns) {
      final v = RegExp(pattern, caseSensitive: false, dotAll: true)
          .firstMatch(html)
          ?.group(1)
          ?.trim();
      if (v != null && v.isNotEmpty) return _decodeHtml(v);
    }
    return null;
  }

  String? _titleTag(String html) {
    final v = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
        .firstMatch(html)
        ?.group(1)
        ?.trim();
    return v != null ? _decodeHtml(v) : null;
  }

  String? _bestImage(String html) {
    final og = _ogTag(html, 'image');
    if (og != null) return og;

    // twitter:image como fallback
    for (final pattern in [
      r'<meta[^>]+name="twitter:image"[^>]+content="([^"]+)"',
      r"<meta[^>]+name='twitter:image'[^>]+content='([^']+)'",
    ]) {
      final v = RegExp(pattern, caseSensitive: false).firstMatch(html)?.group(1);
      if (v != null) return v;
    }
    return null;
  }

  double? _price(String html) {
    for (final prop in [
      'price:amount',
      'product:price:amount',
      'og:price:amount',
    ]) {
      for (final pattern in [
        '<meta[^>]+property="$prop"[^>]+content="([^"]+)"',
        "<meta[^>]+property='$prop'[^>]+content='([^']+)'",
      ]) {
        final v = RegExp(pattern, caseSensitive: false).firstMatch(html)?.group(1);
        final parsed = _parsePrice(v);
        if (parsed != null) return parsed;
      }
    }

    // JSON-LD schema.org (Mercado Livre, Amazon, etc.)
    return _parsePrice(
      RegExp(r'"price"\s*:\s*"?([0-9]+(?:[.,][0-9]{1,2})?)"?')
          .firstMatch(html)
          ?.group(1),
    );
  }

  double? _parsePrice(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.');
    final parts = cleaned.split('.');
    final normalized = parts.length > 2
        ? '${parts.take(parts.length - 1).join('')}.${parts.last}'
        : cleaned;
    final value = double.tryParse(normalized);
    if (value == null || value.isNaN || value.isInfinite) return null;
    if (value < 0 || value > 999999.99) return null;
    return value;
  }

  String _decodeHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAllMapped(
          RegExp(r'&#(\d+);'),
          (m) {
            final code = int.tryParse(m.group(1)!);
            if (code == null || code < 32 || code > 0x10FFFF) return '';
            return String.fromCharCode(code);
          },
        );
  }
}

final metadataExtractor = MetadataExtractorService();
