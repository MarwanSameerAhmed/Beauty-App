// Web configuration for Google Sign-In
class WebConfig {
  // Google OAuth 2.0 Client ID for Web
  // This needs to be configured in Google Cloud Console
  // Go to: https://console.cloud.google.com/apis/credentials
  // Project: beauty-app-84d57
  static const String googleClientId = '677899943891-5f1r21khbvsiphlelq0vs4qj82t7jc7p.apps.googleusercontent.com';
  
  // Instructions to get the Web Client ID:
  // 1. Go to Google Cloud Console: https://console.cloud.google.com/
  // 2. Select project: beauty-app-84d57
  // 3. Go to APIs & Services > Credentials
  // 4. Click "Create Credentials" > "OAuth 2.0 Client IDs"
  // 5. Choose "Web application"
  // 6. Add authorized JavaScript origins:
  //    - http://localhost:3000 (for development)
  //    - https://beauty-app-84d57.web.app (for production)
  //    - https://beauty-app-84d57.firebaseapp.com (for production)
  // 7. Copy the Client ID and replace the value above
  
  // Firebase Web App configuration
  static const String firebaseProjectId = 'beauty-app-84d57';
  static const String firebaseAuthDomain = 'beauty-app-84d57.firebaseapp.com';
  static const String firebaseWebAppId = '1:677899943891:web:b815cbc2a327b1df34b926';
}
