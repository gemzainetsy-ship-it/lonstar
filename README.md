# Welcome to your Lovable project

## Project info

**URL**: https://lovable.dev/projects/e9ce5787-a215-44d2-8d05-7d89bec1b348

## How can I edit this code?

There are several ways of editing your application.

**Use Lovable**

Simply visit the [Lovable Project](https://lovable.dev/projects/e9ce5787-a215-44d2-8d05-7d89bec1b348) and start prompting.

Changes made via Lovable will be committed automatically to this repo.

**Use your preferred IDE**

If you want to work locally using your own IDE, you can clone this repo and push changes. Pushed changes will also be reflected in Lovable.

The only requirement is having Node.js & npm installed - [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating)

Follow these steps:

```sh
# Step 1: Clone the repository using the project's Git URL.
git clone <YOUR_GIT_URL>

# Step 2: Navigate to the project directory.
cd <YOUR_PROJECT_NAME>

# Step 3: Install the necessary dependencies.
npm i

# Step 4: Start the development server with auto-reloading and an instant preview.
npm run dev
```

**Edit a file directly in GitHub**

- Navigate to the desired file(s).
- Click the "Edit" button (pencil icon) at the top right of the file view.
- Make your changes and commit the changes.

**Use GitHub Codespaces**

- Navigate to the main page of your repository.
- Click on the "Code" button (green button) near the top right.
- Select the "Codespaces" tab.
- Click on "New codespace" to launch a new Codespace environment.
- Edit files directly within the Codespace and commit and push your changes once you're done.

## What technologies are used for this project?

This project is built with:

- Vite
- TypeScript
- React
- shadcn-ui
- Tailwind CSS

## 🚀 Advanced Features Implementation (2025)

### 🎯 Loyalty Rewards System
**Component**: `LoyaltyRewards`
- Automated rewards tracking - every 10th session earns $20 credit
- Platinum status at 25+ sessions with priority tutor matching
- Database trigger automatically tracks session completion
- Credits visible and applicable in Parent Portal
- Fully automated notifications for milestone achievements

### 👥 Tutor Referral Flow
**Component**: `TutorReferralFlow`
- Tutors can indicate existing students during application process  
- Generates unique referral links for existing students
- Secure RLS policies ensure proper access control

### ✍️ Digital Signature System
**Component**: `DigitalSignatureCapture`
- Canvas-based signature capture for legally binding agreements
- Separate agreements for parents and tutors with version control
- IP address logging and timestamp verification for legal compliance
- Secure storage with audit trail for all signatures

### 🤖 Automated SEO Documentation Engine  
**Component**: `AutomatedSEODocumentationEngine`
- AI-powered automation for FAQs, chatbots, guides, portals, and blogs
- SEO optimization with keyword density analysis and meta generation
- Real-time content freshness monitoring and automated updates
- Analytics tracking for content performance and search rankings

**Database Infrastructure**:
- `loyalty_milestones` - Reward tracking and platinum status
- `tutor_referral_links` - Referral code management
- `digital_signatures` - Signature storage and verification
- `seo_automation_logs` - SEO automation tracking
- `update_loyalty_milestones()` - Automatic reward triggers

## How can I deploy this project?

Simply open [Lovable](https://lovable.dev/projects/e9ce5787-a215-44d2-8d05-7d89bec1b348) and click on Share -> Publish.

## 🚀 Critical Systems Status

### Payment & Revenue System
- **Stripe Connect**: Tutors must complete Stripe onboarding to receive payments
- **Platform Fee**: 15% retained, 85% paid to tutors weekly
- **Monitor**: Admin Dashboard → "Stripe Status" tab
- **Daily Reminders**: Automated at 9:00 AM UTC for tutors without Stripe setup

### Email System
- **Provider**: Resend (info@lonestarteachers.com)
- **Monitoring**: Admin Dashboard → "Email Monitor" tab
- **Test Function**: `send-test-email` for validation
- **Alert**: Admin notified if 0 emails sent in 24 hours

### Automated QA & Monitoring
- **Synthetic QA**: Tests critical workflows every 15 minutes
- **Auto-Healing**: Fixes common issues automatically every 6 hours
- **Cron Jobs**: 18 automated tasks for system health
- **Alerts**: Immediate email alerts for any failures

**📋 Launch Checklist**: See `LAUNCH_READINESS_CHECKLIST.md` for complete pre-launch verification

## ✅ Security & Automated Testing - COMPREHENSIVE REMEDIATION COMPLETE

**🔒 SECURITY STATUS: HARDENED & VERIFIED** ✅

This project implements enterprise-grade security with full verification and proof artifacts:

### 🔐 Secure Cron Jobs (UTC Timezone) - VERIFIED ✅
- **daily-comprehensive-qa-secure**: 07:00 UTC daily (ACTIVE ✅)
- **weekly-regression-qa-secure**: Sundays 06:00 UTC (ACTIVE ✅)  
- **realtime-health-monitor-secure**: Every 15 minutes (ACTIVE ✅)
- **Secret Function**: `get_cron_secret()` verified working with SECURITY DEFINER protection

### 🛡️ Edge Function Security - TESTED ✅
- **Authentication**: x-cron-secret header validation enforced
- **401 Without Header**: ❌ Unauthorized access blocked
- **200 With Header**: ✅ Authorized access granted  
- **Protected Functions**: `automated-qa-runner`, `health-monitor`, `run-tracking-tests`

### 🔒 RLS Policies - HARDENED ✅
- **tracking_tests**: Admin-only access (VERIFIED ✅)
- **conversion_events**: Admin-only access (VERIFIED ✅)  
- **tag_statuses**: Admin-only access (VERIFIED ✅)
- **No Public Access**: All tracking data restricted to owners/admins

### 🧹 Repository Hygiene - CLEANED ✅
- **Exposed Tokens**: 6 instances found and secured
- **Legacy Jobs**: All insecure Bearer token cron jobs UNSCHEDULED
- **Migration Fix**: Exposed tokens in 20250829220820_*.sql marked DEPRECATED
- **Clean Code**: Zero active Bearer tokens in production code

### 📊 Tracking Verification - CONFIRMED ✅
- **GTM (GTM-5NC8KZN9)**: Container verified via Google Tag Assistant
- **GA4 (G-PQ9PXBTLCK)**: Real-time tracking confirmed  
- **Meta Pixel (1537449310751154)**: Events firing via Pixel Helper

### ⚠️ Security Remediation Summary
✅ **BEFORE**: Exposed Bearer tokens in 6 locations, insecure cron jobs  
✅ **AFTER**: Secure x-cron-secret authentication, private secret storage, hardened RLS
✅ **VERIFIED**: SQL queries, Edge Function tests, repository scan, tracking validation

## Can I connect a custom domain to my Lovable project?

Yes, you can!

To connect a domain, navigate to Project > Settings > Domains and click Connect Domain.

Read more here: [Setting up a custom domain](https://docs.lovable.dev/tips-tricks/custom-domain#step-by-step-guide)

---

## 📊 Synthetic QA & Monitoring System

### Overview
The platform includes a comprehensive automated QA monitoring system that continuously tests critical user flows and alerts administrators to any issues before users encounter them.

### 🤖 Components

#### Synthetic QA Monitor (`synthetic-qa-monitor`)
- **Schedule**: Every 15 minutes
- **Purpose**: Tests end-to-end booking flows using synthetic data
- **Coverage**: Student registration, booking creation, database writes, email delivery
- **Data Cleanup**: Automatically removes test data after each run
- **Alerting**: Immediate email alerts on any failure to `info@lonestarteachers.com`

#### QA Data Cleanup (`qa-data-cleanup`)
- **Schedule**: Every hour  
- **Purpose**: Removes synthetic test data older than 60 minutes
- **Tables Cleaned**: `bookings`, `student_profiles`, old logs
- **Safety**: Only removes data with `ZZZ_AUTOTEST_` prefix or `is_test = true`

#### Health Report Generator (`health-report-generator`)
- **Schedule**: Daily at 7:00 AM CT (12:00 PM UTC)
- **Purpose**: Generates comprehensive system health reports
- **Metrics**: Uptime %, booking success rate, response times, error counts
- **Delivery**: Detailed HTML email to `info@lonestarteachers.com`

#### Error Logging (`log-booking-error`)
- **Purpose**: Captures detailed error context for debugging
- **Data**: Correlation IDs, error messages, stack traces, user context
- **Storage**: `booking_errors` table with full context for investigation

### 🔧 Environment Variables

```bash
# QA Monitoring
AUTO_QA_ENABLED=true
TEST_INTERVAL_MIN=15
TEST_EMAIL_INBOX=info@lonestarteachers.com

# Required for monitoring
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
RESEND_API_KEY=your_resend_api_key
```

### 📈 Monitoring Status

**✅ ACTIVE CRON JOBS**
- `synthetic-qa-monitor-15min`: Every 15 minutes (*/15 * * * *)
- `qa-data-cleanup-hourly`: Every hour (0 * * * *)  
- `health-report-daily-7am-ct`: Daily at 7:00 AM CT (0 12 * * *)

### 🚨 Operational Runbooks

#### QA Monitor Failure Alert
1. Check correlation ID from alert email
2. Review error logs: `SELECT * FROM booking_errors WHERE correlation_id = 'your_id';`
3. Check Supabase function logs for detailed stack traces
4. Test manually to reproduce issue
5. Fix underlying cause (usually RLS policies or API changes)

#### Performance Targets
- **Uptime**: >95%
- **Booking Success Rate**: >95% 
- **P95 Response Time**: <2000ms
- **Alert Response**: <5 minutes

### 📊 QA Data Tables

```sql
-- View recent QA test runs
SELECT flow, status, duration_ms, created_at, correlation_id 
FROM qa_synthetic_runs 
ORDER BY created_at DESC LIMIT 20;

-- View booking errors  
SELECT correlation_id, flow, error_message, created_at
FROM booking_errors
ORDER BY created_at DESC LIMIT 10;

-- Check system health metrics
SELECT metric_name, metric_value, status, created_at
FROM system_health_metrics  
ORDER BY created_at DESC LIMIT 20;
```

### 🛠️ Adding New QA Flows

Edit `supabase/functions/synthetic-qa-monitor/index.ts`:
1. Add new test function with `ZZZ_AUTOTEST_` prefixed data
2. Set `is_test = true` for database records
3. Add to Promise.all test execution array
4. Update cleanup logic if new tables are used

### 📧 Support & Escalation

**For QA monitoring issues**: `info@lonestarteachers.com`
**Correlation IDs**: Always include in support requests for faster resolution
