class Env {
  static const String apiUrl = 'https://pitazoapi.globalappsuite.com.mx';
  static const String webUrl = 'https://pitazo.globalappsuite.com.mx';

  /// Convierte una URL de foto a absoluta.
  /// La API retorna URLs absolutas (https://pitazoapi...).
  /// La web retorna URLs relativas (/uploads/...) — se resuelven con webUrl.
  static String? toAbsolutePhotoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return '$webUrl$url';
  }
}
