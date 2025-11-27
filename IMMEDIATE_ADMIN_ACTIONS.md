# Immediate Admin Actions - Tutor Onboarding Crisis (DB-ONLY REPAIR)

## 🚨 What Happened
Between Oct 9-10, a database constraint error silently broke the tutor approval workflow, causing approved tutors to not receive:
- Auth accounts (couldn't log in)
- Tutor profiles
- Tutor roles
- Welcome emails with login credentials

## ✅ What You Need to Do RIGHT NOW

### 1. Run Auto-Repair (Database RPC)

**Option A: Via Admin UI (Recommended)**
1. Go to Admin → Tutor Management → Onboarding Monitor
2. Click "Run Auto-Repair" button
3. Wait for confirmation toast with repair summary

**Option B: Via SQL (Direct)**
Run this in Supabase SQL Editor:

```sql
SELECT public.run_auto_repair_broken_tutor_approvals(
  p_dry_run := false,
  p_days_lookback := 30
);
```

This will:
- ✅ Create missing tutor profiles
- ✅ Link auth users to profiles
- ✅ Assign tutor roles
- ✅ Mark welcome emails as handled
- ✅ Create alerts for tutors without auth accounts

### 2. Send Apology Emails to Affected Tutors

**Check which tutors were affected:**

```sql
SELECT 
  ta.email,
  ta.full_name,
  ta.created_at as approved_at,
  ta.welcome_email_sent_at,
  t.id as tutor_profile_id,
  t.user_id,
  CASE 
    WHEN t.id IS NULL THEN '❌ Missing Profile'
    WHEN t.user_id IS NULL THEN '⚠️ No Auth Account'
    ELSE '✅ Fixed'
  END as status
FROM tutor_applications ta
LEFT JOIN tutors t ON LOWER(t.email) = LOWER(ta.email)
WHERE ta.status = 'approved'
  AND ta.created_at >= '2025-10-09'
ORDER BY ta.created_at DESC;
```

**For each affected tutor, send this email:**

---

**Subject:** Your Lone Star Teachers Account - Issue Resolved

Dear [Tutor Name],

We sincerely apologize for the technical issue you experienced with your Lone Star Teachers account. We discovered a system error that prevented your account from being properly set up after approval on [approval date].

**Good news:** This issue has been resolved, and your account is now fully activated.

You should now be able to:
- Log in to your account at lonestarteachers.com
- Access the Tutor Portal
- Complete your Stripe Connect setup for payments
- View and accept student assignments

**Your login credentials:**
- Email: [tutor email]
- Password: Please use the "Forgot Password" link on the login page to set your password

If you experience any issues, please reply to this email for immediate assistance.

We've implemented additional monitoring systems to prevent this from happening again. Thank you for your patience and understanding.

Best regards,  
The Lone Star Teachers Team

---

### 3. Notify Affected Parents/Students

**For parents with matched tutors who couldn't access their accounts:**

---

**Subject:** Your Tutor Match - Quick Update

Dear [Parent Name],

We wanted to update you on your tutoring request for [Student Name].

We experienced a brief technical issue that delayed the setup of your matched tutor's account. This has now been fully resolved, and your tutor is ready to begin sessions.

**Next steps:**
- Your tutor will be reaching out within 24 hours to schedule your first session
- If you don't hear from them by [date 24h from now], please contact us immediately at info@lonestarteachers.com

We apologize for any confusion or delay this may have caused. We've implemented additional safeguards to ensure smooth onboarding for all future matches.

Thank you for your patience,  
The Lone Star Teachers Team

---

## 🛡️ What's Been Fixed

### Database-Level Protection (No Edge Functions)
1. ✅ **RPC Repair Function:** `run_auto_repair_broken_tutor_approvals()` - Callable from admin UI
2. ✅ **Canary Monitoring:** `canary_tutor_approval_monitor_db()` - Runs every 5 minutes via pg_cron
3. ✅ **Unique Index:** Prevents duplicate tutor emails
4. ✅ **Activity Alerts:** Critical issues logged to `activity_alerts` table
5. ✅ **View for Tracking:** `tutor_followup_priority` shows onboarding status

### Security Improvements
1. ✅ Removed insecure welcome email trigger with hardcoded service role key
2. ✅ All repairs use SECURITY DEFINER functions with SET search_path
3. ✅ Manual email templates for copy/send (no auto-send with secrets)

## 📊 Monitor Going Forward

### Check These Daily:
1. Admin Dashboard → Tutor Management → Onboarding Monitor
2. Look for "Critical Issues" count
3. If you see any red alerts, click "Run Auto-Repair"

### Canary Monitoring (Already Enabled)
The `canary_tutor_approval_monitor_db()` function runs automatically every 5 minutes via pg_cron. It will:
- Detect broken approvals
- Auto-repair them
- Log critical alerts if repairs fail

**To check canary status:**
```sql
SELECT * FROM cron.job WHERE jobname = 'canary_tutor_approval_monitor_db';
```

**To temporarily disable:**
```sql
SELECT cron.unschedule('canary_tutor_approval_monitor_db');
```

**To re-enable:**
```sql
SELECT cron.schedule(
  'canary_tutor_approval_monitor_db',
  '*/5 * * * *',
  $$ SELECT public.canary_tutor_approval_monitor_db(); $$
);
```

## 🔍 Root Cause

The issue was caused by:
1. Adding a unique constraint to `tutors.email` without proper conflict handling
2. The constraint failing silently during high-load approvals
3. No monitoring detecting the failure
4. Old insecure trigger with hardcoded service role key

**All issues have been addressed with database-level protections.**

## 🎯 Architecture Change

**Before:** Edge Functions → Database (unreliable, deployment dependencies)

**After:** Database RPC + pg_cron → Activity Alerts (reliable, no edge function dependencies)

**Benefits:**
- ✅ No deployment delays
- ✅ No edge function failures
- ✅ Immediate repairs via SQL
- ✅ 5-minute canary monitoring
- ✅ No exposed service role keys
