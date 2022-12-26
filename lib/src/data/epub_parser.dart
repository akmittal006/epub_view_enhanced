import 'package:epub_view_enhanced/src/data/epub_cfi_reader.dart';
import 'package:html/dom.dart' as dom;

import '../../epub_view_enhanced.dart';
import '../custom_stack.dart';
import 'models/paragraph.dart';

export 'package:epub_parser/epub_parser.dart' hide Image;

List<EpubChapter> parseChapters(EpubBook epubBook) {
  CustomStack<EpubChapter> dfsStack = CustomStack();
  EpubChapter current;
  return epubBook.Chapters!.fold<List<EpubChapter>>(
    [],
    (acc, next) {
      // acc.add(next);
      dfsStack.push(next);
      while(dfsStack.isNotEmpty) {
        current = dfsStack.pop();
        acc.add(current);
        // current.Anchor ??= "NULL";
        // print("ANCHOR : " + current.Anchor!);

        if (current.SubChapters != null && current.SubChapters!.isNotEmpty) {
          current.SubChapters!.reversed.forEach((element) { dfsStack.push(element);});
        }
      }
      return acc;
    },
  );
}

List<dom.Element> convertDocumentToElements(dom.Document document) =>
    document.getElementsByTagName('body').first.children;

List<dom.Element> _removeAllDiv(List<dom.Element> elements) {
  final List<dom.Element> result = [];

  for (final node in elements) {
    if (node.localName == 'div' && node.children.length > 1) {
      result.addAll(_removeAllDiv(node.children));
    } else {
      result.add(node);
    }
  }

  return result;
}

ParseParagraphsResult parseParagraphs(
  List<EpubChapter> chapters,
  EpubContent? content,
) {
  String? filename = '';
  final List<int> chapterIndexes = [];
  List<dom.Element> prevElmList = [];
  final paragraphs = chapters.fold<List<Paragraph>>(
    [],
    (acc, next) {
      List<dom.Element> elmList = [];
      if (filename != next.ContentFileName) {
        filename = next.ContentFileName;
        final document = EpubCfiReader().chapterDocument(next);
        if (document != null) {
          final result = convertDocumentToElements(document);
          elmList = _removeAllDiv(result);
        }
        prevElmList = elmList;
      }

      if (next.Anchor == null) {
        // last element from document index as chapter index
        chapterIndexes.add(acc.length);
        acc.addAll(elmList.map((element) => Paragraph(element, chapterIndexes.length - 1)));
        return acc;
      } else {
        final index = prevElmList.indexWhere(
          (elm) => elm.outerHtml.contains(
            "${next.Anchor}",
          ),
        );

        if (index == -1) {
          chapterIndexes.add(acc.length);
          acc.addAll(elmList
              .map((element) => Paragraph(element, chapterIndexes.length - 1)));
          return acc;
        }
        if (chapterIndexes.isEmpty) {
          chapterIndexes.add(index);
        } else {
          chapterIndexes.add(chapterIndexes.last + index);
        }

        acc.addAll(elmList
            .map((element) => Paragraph(element, chapterIndexes.length - 1)));
        return acc;
      }
    },
  );
  return ParseParagraphsResult(paragraphs, chapterIndexes);
}

class ParseParagraphsResult {
  ParseParagraphsResult(this.flatParagraphs, this.chapterIndexes);

  final List<Paragraph> flatParagraphs;
  final List<int> chapterIndexes;
}
