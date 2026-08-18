import '../utils/validators.dart';

class SearchService {
  SearchService(this.searxngBaseUrl, {this.safeSearch = 0});

  final String searxngBaseUrl;
  final int safeSearch;

  static const String preferredEngines =
      'google,duckduckgo,brave,wikipedia,wikidata,bing';

  String resolveInput(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) return '';
    if (UrlValidator.isLikelyUrl(input)) {
      return UrlValidator.normalize(input);
    }
    return buildSearchUrl(input);
  }

  String buildSearchUrl(String query) {
    final cleaned = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    final encoded = Uri.encodeQueryComponent(cleaned);
    final root = _searchRoot(searxngBaseUrl);
    final ss = safeSearch.clamp(0, 2);
    return '$root$encoded'
        '&categories=general'
        '&language=auto'
        '&time_range='
        '&safesearch=$ss'
        '&engines=$preferredEngines';
  }

  /// Ensures the base ends with the query parameter key so we can append
  /// the encoded query value. Accepts common forms:
  ///   https://searx.be/search?q=
  ///   https://searx.be/search?
  ///   https://searx.be/search
  String _searchRoot(String base) {
    final b = base.trim();
    if (b.isEmpty) return 'https://searx.be/search?q=';
    // Already ends with a query key (q= / query= / s= etc.)
    if (RegExp(r'[?&][a-zA-Z_]+=$').hasMatch(b)) return b;
    if (b.endsWith('?') || b.endsWith('&')) return '${b}q=';
    if (b.contains('?')) return '$b&q=';
    return '$b?q=';
  }
}
