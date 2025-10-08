# Security Setup Instructions

## Firebase/Google Services Configuration

### Important Security Note
**NEVER commit the actual `GoogleService-Info.plist` or `google-services.json` files to version control.**

### Setup Instructions

1. **Copy the template file:**
   ```bash
   cp ios/Runner/GoogleService-Info.plist.template ios/Runner/GoogleService-Info.plist
   ```

2. **Replace placeholders with your actual Firebase/Google project values:**
   - `YOUR_CLIENT_ID_HERE`
   - `YOUR_REVERSED_CLIENT_ID_HERE` 
   - `YOUR_API_KEY_HERE`
   - `YOUR_GCM_SENDER_ID_HERE`
   - `YOUR_PROJECT_ID_HERE`
   - `YOUR_STORAGE_BUCKET_HERE`
   - `YOUR_GOOGLE_APP_ID_HERE`

3. **Get your actual values from:**
   - Firebase Console → Project Settings → General → Your Apps → iOS app
   - Download the `GoogleService-Info.plist` and copy the values

### If API Keys Are Compromised

1. **Immediately revoke the old API key:**
   - Go to Google Cloud Console → APIs & Services → Credentials
   - Find the compromised API key and delete it

2. **Create a new API key:**
   - Create a new API key with appropriate restrictions
   - Update your `GoogleService-Info.plist` with the new key

3. **Remove from git history if committed:**
   ```bash
   git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch ios/Runner/GoogleService-Info.plist' --prune-empty --tag-name-filter cat -- --all
   ```

### Current Status
- ✅ Template file created
- ✅ .gitignore configured to exclude sensitive files
- ⚠️  **ACTION REQUIRED:** Rotate the exposed API key immediately
- ⚠️  **ACTION REQUIRED:** Update your local file with new credentials