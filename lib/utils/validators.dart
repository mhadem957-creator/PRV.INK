/// Decides whether address-bar input should be treated as a URL to
/// navigate to, or a query to send to the configured SearXNG instance.
class UrlValidator {
  UrlValidator._();

  static final RegExp _domainLikePattern = RegExp(
    r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?'
    r'(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)+$',
  );

  static final RegExp _ipPattern = RegExp(r'^\d{1,3}(\.\d{1,3}){3}(:\d+)?$');

  /// Returns true when [input] looks like a navigable URL/host rather than
  /// a free-text search query.
  static bool isLikelyUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.contains(' ')) return false;

    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('about:') ||
        trimmed.startsWith('ink://') ||
        trimmed.startsWith('file://')) {
      if (trimmed.startsWith('about:') || trimmed.startsWith('ink://')) {
        return true;
      }
      final uri = Uri.tryParse(trimmed);
      return uri != null && uri.host.isNotEmpty;
    }

    if (trimmed.startsWith('localhost') || _ipPattern.hasMatch(trimmed)) {
      return true;
    }

    // Bare domain typed without a scheme, e.g. "example.com" or
    // "example.com/path". Only the host portion needs to look domain-like.
    final hostCandidate = trimmed.split('/').first.split(':').first;
    return hostCandidate.contains('.') &&
        _domainLikePattern.hasMatch(hostCandidate);
  }

  /// Ensures a URL has a scheme before being handed to the WebView.
  static String normalize(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('about:') ||
        trimmed.startsWith('ink://') ||
        trimmed.startsWith('file://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }
}
