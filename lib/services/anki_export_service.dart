import '../models/app_models.dart';

class AnkiExportResult {
  const AnkiExportResult({
    required this.tsv,
    required this.filePath,
  });

  final String tsv;
  final String filePath;
}

class AnkiExportService {
  Future<AnkiExportResult> exportCards(List<NotebookCard> cards) async {
    final tsv = _buildTsv(cards);

    // Anki export disabled for now to unblock build
    return AnkiExportResult(
      tsv: tsv,
      filePath: 'memory://sudarshan_anki_export.tsv',
    );
  }

  String _buildTsv(List<NotebookCard> cards) {
    final lines = <String>[];
    for (final card in cards) {
      final front =
          card.question.replaceAll('\t', ' ').replaceAll('\n', ' ').trim();
      final back =
          card.answer.replaceAll('\t', ' ').replaceAll('\n', ' ').trim();
      final tags = [
        card.subject,
        card.chapter,
        card.topic,
      ]
          .map((item) => item.trim().replaceAll(' ', '_'))
          .where((item) => item.isNotEmpty)
          .join(' ');
      lines.add('$front\t$back\t$tags');
    }
    return lines.join('\n');
  }
}
