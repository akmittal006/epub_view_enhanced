import 'package:epub_view_enhanced/src/data/epub_parser.dart';

export 'package:epub_parser/epub_parser.dart' hide Image;

class ParseResult {
  const ParseResult(this.epubBook, this.chapters, this.parseResult);

  final EpubBook epubBook;
  final List<EpubChapter> chapters;
  final ParseParagraphsResult parseResult;
}
