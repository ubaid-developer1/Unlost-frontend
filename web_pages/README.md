# Un-Lost App - Account Deletion & Privacy Pages

This folder contains the web pages required for Google Play Store compliance, specifically for account deletion requests and privacy policy.

## Files

- `index.html` - Main account deletion page (required by Google Play Store)
- `privacy-policy.html` - Privacy policy page
- `styles.css` - Styling for both pages
- `README.md` - This file

## How to Host

### Option 1: GitHub Pages (Recommended)
1. Create a new GitHub repository (e.g., `unstop-privacy`)
2. Upload these files to the repository
3. Enable GitHub Pages in repository settings
4. Your URL will be: `https://yourusername.github.io/unstop-privacy/`

### Option 2: Firebase Hosting
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Initialize: `firebase init hosting`
4. Deploy: `firebase deploy`

### Option 3: Netlify
1. Drag and drop the `web_pages` folder to Netlify
2. Get your instant URL

### Option 4: Any Web Hosting
Upload these files to any web hosting service.

## Google Play Store Setup

1. Host the pages using any method above
2. Copy the URL to your account deletion page (index.html)
3. In Google Play Console:
   - Go to App Content > Data Safety
   - Find "Delete account URL" field
   - Enter your URL (e.g., `https://yourusername.github.io/unstop-privacy/`)
4. Save and publish

## URLs to Use

- **Account Deletion:** `https://your-domain.com/` (points to index.html)
- **Privacy Policy:** `https://your-domain.com/privacy-policy.html`

## Customization

You can customize:
- Contact email (currently: support@worldresolutions.com)
- Company name (currently: World Resolutions)
- App name styling and colors
- Additional sections or information

## Features

✅ **Google Play Store Compliant**
✅ **Mobile Responsive Design**
✅ **Professional Styling**
✅ **Clear Instructions for Users**
✅ **Multiple Deletion Methods**
✅ **Privacy Policy Included**
✅ **GDPR Compliant Language**

## Support

If you need help setting up hosting or customizing these pages, contact your developer or refer to the hosting platform's documentation.
