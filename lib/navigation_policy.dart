bool isWebsiteUrl(Uri uri) =>
    uri.scheme == 'https' &&
    (uri.host == 'eltahi.com' || uri.host == 'www.eltahi.com') &&
    (!uri.hasPort || uri.port == 443);

bool isExternalUrl(Uri uri) =>
    (uri.scheme == 'https' && uri.host.isNotEmpty) ||
    const ['mailto', 'tel', 'sms', 'whatsapp'].contains(uri.scheme);
