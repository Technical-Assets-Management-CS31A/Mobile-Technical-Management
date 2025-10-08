import 'package:flutter/foundation.dart';

class CorsHelper {
  // Check if we're running on web
  static bool get isWeb => kIsWeb;

  // Get the current origin for web
  static String get currentOrigin {
    if (kIsWeb) {
      // This will be set by the web app
      return 'http://localhost:60546'; // Default Flutter web port
    }
    return 'mobile'; // For mobile/desktop apps
  }

  // CORS error message
  static String get corsErrorMessage => '''
CORS Error Detected!

This error occurs because:
• Your Flutter web app runs on: http://localhost:60546
• Your API runs on: http://localhost:5278
• Browsers block requests between different origins

Solutions:
1. Configure CORS on your API server (Recommended)
2. Run Flutter as desktop/mobile app instead of web
3. Use a proxy server for development

For ASP.NET Core, add this to your Program.cs:
```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterWeb", policy =>
    {
        policy.WithOrigins("http://localhost:60546")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

app.UseCors("AllowFlutterWeb");
```
''';

  // Check if we should show CORS warning
  static bool shouldShowCorsWarning() {
    return kIsWeb; // Only show on web platform
  }

  // Get alternative run commands
  static List<String> get alternativeRunCommands => [
    'flutter run -d windows',
    'flutter run -d macos',
    'flutter run -d android',
    'flutter run -d ios',
  ];
}
