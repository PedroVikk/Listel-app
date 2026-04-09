import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PrintScanResult {
  final String? name;
  final double? price;
  const PrintScanResult({this.name, this.price});
}

class PrintScannerService {
  // Apenas valores com R$ explícito E separador decimal obrigatório.
  // Rejeita números sem decimal (ex: "R$ 389") que são misreads do OCR.
  // Aceita: "R$ 38,99" | "R$ 1.299,90" | "R$89.90" | "R $ 38,9"
  static final _priceRegex = RegExp(
    r'R\s*\$\s*(\d{1,3}(?:[.,]\d{3})*[.,]\d{1,2})',
    caseSensitive: false,
  );

  static final _uiNoiseWords = RegExp(
    r'\b(comprar|adicionar|frete|parcelar|entrega|grátis|gratis|ver mais|avaliações|avaliacao|estoque|carrinho|favoritar|compartilhar|seguir|loja|vendido|unidade|disponível|disponivel|selecione|escolha|tamanho|cor|quantidade)\b',
    caseSensitive: false,
  );

  static final _onlyPriceRegex = RegExp(
    r'^[\s\d.,R$%+\-x*/]+$',
  );

  Future<PrintScanResult> scan(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(inputImage);

      final price = _extractPrice(recognized);

      final allText = recognized.blocks
          .expand((b) => b.lines)
          .map((l) => l.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final name = _extractName(allText);

      return PrintScanResult(name: name, price: price);
    } finally {
      recognizer.close();
    }
  }

  /// Extrai o preço usando o tamanho do bounding box como proxy de tamanho de fonte.
  /// O preço principal numa tela de produto é sempre o texto mais destacado (maior).
  double? _extractPrice(RecognizedText recognized) {
    double? bestPrice;
    double bestHeight = 0;

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final matches = _priceRegex.allMatches(line.text);
        for (final match in matches) {
          final value = _parsePrice(match.group(1)!);
          if (value == null) continue;

          final height = line.boundingBox.height.toDouble();
          if (height > bestHeight) {
            bestHeight = height;
            bestPrice = value;
          }
        }
      }
    }

    return bestPrice;
  }

  double? _parsePrice(String raw) {
    // Detecta formato: se tem ponto antes de vírgula → ponto é milhar
    // Ex: "1.299,90" → remove ponto, troca vírgula por ponto → 1299.90
    // Ex: "89,90"    → troca vírgula por ponto → 89.90
    // Ex: "89.90"    → já está no formato correto
    String normalized;
    if (raw.contains(',') && raw.contains('.')) {
      // "1.299,90" — ponto é milhar, vírgula é decimal
      normalized = raw.replaceAll('.', '').replaceAll(',', '.');
    } else if (raw.contains(',')) {
      // "89,90" — vírgula é decimal
      normalized = raw.replaceAll(',', '.');
    } else {
      // "89.90" ou "89" — já ok
      normalized = raw;
    }
    final value = double.tryParse(normalized);
    if (value == null || value <= 0 || value >= 100000) return null;
    return value;
  }

  String? _extractName(List<String> lines) {
    final candidates = lines.where((line) {
      if (line.length < 8) return false;
      if (_onlyPriceRegex.hasMatch(line)) return false;
      if (_priceRegex.hasMatch(line) && line.length < 30) return false;
      if (_uiNoiseWords.hasMatch(line)) return false;
      return true;
    }).toList();

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.length.compareTo(a.length));
    final best = candidates.first;
    return best.length > 150 ? best.substring(0, 150) : best;
  }
}
