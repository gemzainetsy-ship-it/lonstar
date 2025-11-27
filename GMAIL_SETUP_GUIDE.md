# 📧 Gmail Integration Setup Guide

This guide walks you through setting up Gmail API integration for automated email monitoring.

---

## 🎯 What This Enables

Once configured, your system will automatically:
- Read all emails sent to `info@lonestarteachers.com`
- Classify and prioritize them
- Create support tickets in your database
- Send auto-reply emails within 2-3 minutes
- Trigger auto-healing for technical issues
- Schedule follow-ups for high-priority cases

**No more manual email monitoring required!**

---

## 📋 Prerequisites

- Google account with access to `info@lonestarteachers.com`
- Admin access to Supabase project
- 15-20 minutes of setup time
- Terminal/command line access for token generation

---

## 🚀 Step-by-Step Setup

### Part 1: Enable Gmail API in Google Cloud

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com
   - Sign in with your Google account

2. **Create or Select Project**
   - If you don't have a project: Click "Select a project" → "New Project"
   - Name it "Lone Star Teachers Email Integration"
   - Click "Create"

3. **Enable Gmail API**
   - In the search bar, type "Gmail API"
   - Click on "Gmail API" in the results
   - Click the blue "Enable" button
   - Wait for API to be enabled (takes ~30 seconds)

4. **Configure OAuth Consent Screen**
   - Go to "APIs & Services" → "OAuth consent screen"
   - Choose "Internal" (if available) or "External"
   - Fill in required fields:
     - App name: "Lone Star Teachers Email Monitor"
     - User support email: `info@lonestarteachers.com`
     - Developer contact: `info@lonestarteachers.com`
   - Click "Save and Continue"
   - On "Scopes" page, click "Add or Remove Scopes"
   - Search for and add: `https://www.googleapis.com/auth/gmail.modify`
   - Click "Update" → "Save and Continue"
   - On "Test users" page, add `info@lonestarteachers.com`
   - Click "Save and Continue"

5. **Create OAuth Credentials**
   - Go to "APIs & Services" → "Credentials"
   - Click "+ Create Credentials" → "OAuth client ID"
   - Application type: "Desktop app"
   - Name: "Email Poller Desktop"
   - Click "Create"
   - **IMPORTANT:** Copy and save:
     - Client ID (looks like: `xxxx.apps.googleusercontent.com`)
     - Client Secret (random string)
   - Click "OK"

---

### Part 2: Generate Refresh Token

This is the trickiest part, but follow these steps carefully:

1. **Install Node.js** (if not already installed)
   - Download from: https://nodejs.org
   - Choose LTS version
   - Install with default settings

2. **Create Setup Script**
   - Open Terminal/Command Prompt
   - Create a new folder:
     ```bash
     mkdir gmail-setup
     cd gmail-setup
     ```
   - Install required package:
     ```bash
     npm init -y
     npm install googleapis readline
     ```

3. **Create Auth Script**
   - Create a file named `get-refresh-token.js`:
     ```javascript
     const { google } = require('googleapis');
     const readline = require('readline');

     // REPLACE THESE WITH YOUR VALUES FROM STEP 1.5
     const CLIENT_ID = 'YOUR_CLIENT_ID_HERE';
     const CLIENT_SECRET = 'YOUR_CLIENT_SECRET_HERE';
     const REDIRECT_URI = 'urn:ietf:wg:oauth:2.0:oob';

     const oAuth2Client = new google.auth.OAuth2(
       CLIENT_ID,
       CLIENT_SECRET,
       REDIRECT_URI
     );

     const SCOPES = ['https://www.googleapis.com/auth/gmail.modify'];

     const authUrl = oAuth2Client.generateAuthUrl({
       access_type: 'offline',
       scope: SCOPES,
       prompt: 'consent'
     });

     console.log('\n==============================================');
     console.log('📧 Gmail OAuth Token Generator');
     console.log('==============================================\n');
     console.log('Step 1: Visit this URL in your browser:\n');
     console.log(authUrl);
     console.log('\n==============================================\n');

     const rl = readline.createInterface({
       input: process.stdin,
       output: process.stdout,
     });

     rl.question('Step 2: Paste the authorization code here: ', (code) => {
       rl.close();
       
       oAuth2Client.getToken(code, (err, token) => {
         if (err) {
           console.error('\n❌ Error retrieving access token:', err);
           return;
         }
         
         console.log('\n==============================================');
         console.log('✅ SUCCESS! Copy these credentials:');
         console.log('==============================================\n');
         console.log('GMAIL_CLIENT_ID:', CLIENT_ID);
         console.log('GMAIL_CLIENT_SECRET:', CLIENT_SECRET);
         console.log('GMAIL_REFRESH_TOKEN:', token.refresh_token);
         console.log('\n==============================================');
         console.log('Next: Add these to Supabase Edge Function secrets');
         console.log('==============================================\n');
       });
     });
     ```

4. **Run the Script**
   ```bash
   node get-refresh-token.js
   ```

5. **Authorize the App**
   - The script will output a long URL
   - Copy and paste it into your browser
   - Log in with the Google account that has access to `info@lonestarteachers.com`
   - Click "Allow" to grant permissions
   - You'll see a code (like `4/0AX4XfWh...`)
   - Copy the ENTIRE code
   - Paste it back into the terminal when prompted
   - Press Enter

6. **Save Your Credentials**
   - The script will output your credentials
   - Copy all three values:
     - `GMAIL_CLIENT_ID`
     - `GMAIL_CLIENT_SECRET`
     - `GMAIL_REFRESH_TOKEN`
   - Keep these safe - you'll need them in the next step

---

### Part 3: Configure Supabase Edge Functions

1. **Go to Supabase Dashboard**
   - Visit: https://supabase.com/dashboard
   - Select your Lone Star Teachers project

2. **Add Secrets**
   - Go to: Settings → Edge Functions
   - Scroll to "Secrets"
   - Add three new secrets:

   **Secret 1:**
   - Name: `GMAIL_CLIENT_ID`
   - Value: (paste your client ID from Part 2.6)
   
   **Secret 2:**
   - Name: `GMAIL_CLIENT_SECRET`
   - Value: (paste your client secret from Part 2.6)
   
   **Secret 3:**
   - Name: `GMAIL_REFRESH_TOKEN`
   - Value: (paste your refresh token from Part 2.6)

3. **Save Each Secret**
   - Click "Add secret" for each one
   - Verify all three appear in your secrets list

---

### Part 4: Test the Integration

1. **Send Test Email**
   - From any email account, send a test message to `info@lonestarteachers.com`
   - Subject: "Test - Automated Email System"
   - Body: "Testing automated email monitoring"

2. **Wait 5 Minutes**
   - The `gmail-email-poller` runs every 5 minutes
   - Get a coffee ☕

3. **Verify in Admin Panel**
   - Go to your admin dashboard
   - Navigate to: System Admin → Email Tickets
   - You should see your test email with:
     - Auto-classification (probably "general")
     - Severity level
     - Timestamp of receipt
   
4. **Check Your Inbox**
   - Within 2-3 minutes of sending, you should receive an auto-reply
   - Check that it came from `info@lonestarteachers.com`

5. **Check Gmail**
   - Log into Gmail for `info@lonestarteachers.com`
   - Your test email should now be marked as read
   - This confirms the poller is working

---

## 🔧 Troubleshooting

### Problem: "Invalid grant" error when generating token

**Solution:**
- Make sure you selected "prompt: consent" in the auth URL
- Try regenerating credentials in Google Cloud Console
- Make sure you're using a "Desktop app" OAuth client (not "Web application")

### Problem: No emails being processed after 5 minutes

**Check:**
1. Verify secrets are correctly added in Supabase (no typos!)
2. Check Edge Function logs:
   - Supabase Dashboard → Edge Functions → `gmail-email-poller` → Logs
   - Look for errors like "Gmail credentials not configured"
3. Verify Gmail API is enabled in Google Cloud Console
4. Check quota limits: Google Cloud Console → APIs → Gmail API → Quotas

**Solution:**
- If you see "credentials not configured", re-add your secrets
- If you see "invalid_grant", regenerate your refresh token
- If you see quota exceeded, request quota increase in Google Cloud

### Problem: Emails processed but no auto-reply sent

**Check:**
- Verify `RESEND_API_KEY` is configured in Supabase secrets
- Check if auto-reply was actually sent (look in `email_tickets` table)
- Verify `email-inbox-monitor` function is not failing

**Solution:**
- Add or update `RESEND_API_KEY` if missing
- Check spam folder for auto-replies
- Review function logs for specific errors

### Problem: Token expired after 6 months

**Explanation:** Refresh tokens can expire if not used regularly or if Google's policies change.

**Solution:**
1. Re-run Part 2 (Generate Refresh Token)
2. Update the `GMAIL_REFRESH_TOKEN` secret in Supabase
3. No need to recreate OAuth client

---

## 🎯 What Happens Now?

Once configured, every 5 minutes your system will:

1. ✅ Check for new unread emails to `info@lonestarteachers.com`
2. ✅ Extract sender info, subject, and body
3. ✅ Classify the issue (technical, tutor_onboarding, parent_complaint, general)
4. ✅ Determine severity (critical, high, medium, low)
5. ✅ Create a ticket in your database
6. ✅ Send an auto-reply email within 2 minutes
7. ✅ Trigger auto-healing if it's a technical issue
8. ✅ Schedule follow-ups for high-priority cases
9. ✅ Mark the email as read in Gmail

**You'll see every processed email in:** Admin Panel → System Admin → Email Tickets

---

## 🔐 Security Best Practices

### Do's ✅
- Keep your refresh token secret (it's like a password!)
- Store it only in Supabase secrets (never commit to Git)
- Regularly review which emails are being processed
- Set up alerts for failed processing

### Don'ts ❌
- Never share your refresh token publicly
- Don't use a "Web application" OAuth client (use "Desktop app")
- Don't revoke access in Google unless regenerating credentials
- Don't delete the OAuth client in Google Cloud

### Rotating Credentials

If you need to rotate credentials (recommended annually):

1. Generate new OAuth client in Google Cloud
2. Run token generation script with new credentials
3. Update all three secrets in Supabase
4. Delete old OAuth client in Google Cloud
5. Test with a new email

---

## 📊 Monitoring Your Integration

### Daily Checks (30 seconds)
- [ ] Spot-check Email Tickets dashboard for new entries
- [ ] Verify auto-replies are being sent

### Weekly Checks (2 minutes)
- [ ] Review classification accuracy (are emails categorized correctly?)
- [ ] Check for any failed processing attempts
- [ ] Verify Gmail quota usage is normal

### Monthly Checks (10 minutes)
- [ ] Review Edge Function logs for any patterns of errors
- [ ] Test the integration with a manual email
- [ ] Check Gmail API quotas in Google Cloud Console
- [ ] Review auto-healing success rates

---

## 🆘 Getting Help

If you're stuck:

1. **Check the logs first:** Supabase Dashboard → Edge Functions → Logs
2. **Review this guide again** (you might have missed a step)
3. **Test your credentials:** Make sure you copied them correctly
4. **Check Google Cloud Console:** Verify API is enabled and quotas aren't exceeded

---

## 🎉 Success Checklist

Before considering setup complete, verify:

- [x] Gmail API is enabled in Google Cloud Console
- [x] OAuth client created with "Desktop app" type
- [x] Refresh token generated successfully
- [x] All three secrets added to Supabase
- [x] Test email was processed within 5 minutes
- [x] Auto-reply received within 2-3 minutes
- [x] Email appears in Admin → Email Tickets dashboard
- [x] Original email marked as read in Gmail

**If all boxes are checked: 🎉 CONGRATULATIONS! You're fully automated!**

---

**Setup Time:** 15-20 minutes  
**Maintenance:** Minimal (token rotation once per year)  
**ROI:** Infinite (never manually check info@ inbox again!)

*Need help? Check the Edge Function logs or review the [Automation System Documentation](./AUTOMATION_SYSTEM_DOCUMENTATION.md)*
