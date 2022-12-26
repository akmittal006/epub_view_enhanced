part of 'ui/epub_view.dart';

class EpubController {
  EpubController({
    required this.document,
    this.epubCfi,
  });

  Future<EpubBook> document;
  final String? epubCfi;

  _EpubViewState? _epubViewState;
  List<EpubViewChapter>? _cacheTableOfContents;
  EpubBook? _document;

  EpubChapterViewValue? get currentValue => _epubViewState?._currentValue;

  final isBookLoaded = ValueNotifier<bool>(false);
  final ValueNotifier<EpubViewLoadingState> loadingState =
      ValueNotifier(EpubViewLoadingState.loading);

  final currentValueListenable = ValueNotifier<EpubChapterViewValue?>(null);

  final tableOfContentsListenable = ValueNotifier<List<EpubViewChapter>>([]);

  void jumpTo({required int index, double alignment = 0}) =>
      _epubViewState?._itemScrollController?.jumpTo(
        index: index,
        alignment: alignment,
      );

  Future<void>? scrollTo({
    required int index,
    Duration duration = const Duration(milliseconds: 250),
    double alignment = 0,
    Curve curve = Curves.linear,
  }) {
    if (_epubViewState!._itemScrollController!.isAttached) {
      _epubViewState?._itemScrollController?.scrollTo(
        index: index,
        duration: duration,
        alignment: alignment,
        curve: curve,
      );
    }
  }


  void gotoEpubCfi(
    String epubCfi, {
    double alignment = 0,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.linear,
  }) {
    _epubViewState?._gotoEpubCfi(
      epubCfi,
      alignment: alignment,
      duration: duration,
      curve: curve,
    );
  }

  ParseParagraphsResult getParagraphs() {
    if (_epubViewState != null) {
      return ParseParagraphsResult(_epubViewState!._paragraphs, _epubViewState!._chapterIndexes);
    }
    return ParseParagraphsResult([], []);
  }

  void highlightPara(int index) {
    _epubViewState?.highlightPara(index);
  }

  String? generateEpubCfi() => _epubViewState?._epubCfiReader?.generateCfi(
        book: _document,
        chapter: _epubViewState?._currentValue?.chapter,
        paragraphIndex: _epubViewState?._getAbsParagraphIndexBy(
          positionIndex: _epubViewState?._currentValue?.position.index ?? 0,
          trailingEdge:
              _epubViewState?._currentValue?.position.itemTrailingEdge,
          leadingEdge: _epubViewState?._currentValue?.position.itemLeadingEdge,
        ),
      );

  List<EpubViewChapter> tableOfContents() {
    if (_cacheTableOfContents != null) {
      return _cacheTableOfContents ?? [];
    }

    if (_document == null) {
      return [];
    }

    int index = -1;
    EpubChapter current;
    CustomStack<EpubChapter> dfsStack = CustomStack();

    return _cacheTableOfContents =
        _document!.Chapters!.fold<List<EpubViewChapter>>(
      [],
      (acc, next) {
        dfsStack.push(next);

        while (dfsStack.isNotEmpty) {
          index += 1;
          current = dfsStack.pop();
          acc.add(EpubViewSubChapter(
              current.Title, _getChapterStartIndex(index)));

          if (current.SubChapters != null && current.SubChapters!.isNotEmpty) {
            List<EpubChapter> subchaps = [];
            for (final subChap in current.SubChapters!) {
              subchaps.add(subChap);
            }
            subchaps.reversed.toList().forEach((element) {dfsStack.push(element);});
          }
        }
        return acc;
      },
    );
  }

  Future<void> loadDocument(Future<EpubBook> document) {
    this.document = document;
    return _loadDocument(document);
  }

  void dispose() {
    _epubViewState = null;
    isBookLoaded.dispose();
    currentValueListenable.dispose();
    tableOfContentsListenable.dispose();
  }

  Future<void> _loadDocument(Future<EpubBook> document) async {
    isBookLoaded.value = false;
    try {
      loadingState.value = EpubViewLoadingState.loading;
      _document = await document;
      await _epubViewState!._init();
      tableOfContentsListenable.value = tableOfContents();
      loadingState.value = EpubViewLoadingState.success;
    } catch (error) {
      _epubViewState!._loadingError = error is Exception
          ? error
          : Exception('An unexpected error occurred');
      loadingState.value = EpubViewLoadingState.error;
    }
  }

  int _getChapterStartIndex(int index) =>
      index < _epubViewState!._chapterIndexes.length
          ? _epubViewState!._chapterIndexes[index]
          : 0;

  void _attach(_EpubViewState epubReaderViewState) {
    _epubViewState = epubReaderViewState;

    _loadDocument(document);
  }

  void _detach() {
    _epubViewState = null;
  }
}
