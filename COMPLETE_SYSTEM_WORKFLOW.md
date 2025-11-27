# Complete System Workflow Documentation

## Overview
This document outlines the complete workflow from all perspectives: Tutors, Students/Parents, and Admins, including the new pricing model and referral system.

---

## Tutor Perspective

### 1. Application & Onboarding
**Goal:** Get approved as a tutor and set up your account

1. **Submit Application**
   - Visit `/tutors` or `/quran` page
   - Complete tutor application form with REQUIRED fields:
     - Personal information (name, email, phone, country)
     - Educational background and certifications
     - Teaching experience and methods
     - **Hourly rate** ($20-$100/hour) - REQUIRED
     - **Platform fee acceptance** (15% fee) - REQUIRED
     - **Terms and conditions agreement** - REQUIRED
   - Upload relevant documents
   - Submit for admin review

2. **Admin Approval**
   - Admin reviews application in Tutor Management tab
   - Verification of all required fields:
     - ✅ Hourly rate set
     - ✅ Platform fee accepted
     - ✅ Terms agreed
   - Application status changes to "approved"
   - Automated welcome email sent with credentials

3. **Initial Setup**
   - Receive welcome email with:
     - Login credentials
     - Your submitted hourly rate (can be updated)
     - Platform fee details (85/15 split confirmed)
     - Stripe Connect onboarding link
     - Referral program information
   - Log in to tutor portal

4. **Rate Adjustment & Payment Setup** (Optional)
   - Navigate to tutor portal → Rate & Payment Settings
   - Update your hourly rate if needed
   - Platform fee already accepted during application
   - Complete Stripe Connect onboarding for payouts
   - You're now ready to receive student assignments!

### 2. Student Assignment & Scheduling
**Goal:** Receive student assignments and schedule sessions

5. **Assignment Notification**
   - Receive email when admin assigns student
   - View assignment details in portal:
     - Student name (parent email redacted initially)
     - Subject and level
     - Student's preferred schedule
   - **24-Hour Response Time Required**

8. **Propose Session Times**
   - Within 24 hours, propose 3-5 time slots
   - System sends proposals to parent for selection
   - If no response in 24 hours:
     - Alert appears in activity_alerts
     - Email sent to tutor and admin
     - Account flagged for review

8. **Parent Selects Time**
   - Parent chooses preferred time slot
   - System creates session record
   - Meeting link generated automatically
   - Calendar invites sent to both parties

### 3. Conducting Sessions
**Goal:** Deliver quality tutoring and track progress

9. **Session Preparation**
    - Receive reminder emails (24 hours before)
    - Access meeting link from portal
    - Review student notes and previous progress

11. **During Session**
    - Join virtual meeting via provided link
    - Conduct tutoring session
    - Take notes for progress tracking

12. **Post-Session**
    - Mark session as "completed" in portal
    - Add session notes and homework assigned
    - Rate student engagement (1-5)
    - System automatically processes payment

### 4. Earnings & Payouts
**Goal:** Receive payment for completed sessions

13. **Payment Processing**
    - After session marked complete:
      - Parent is charged via Stripe
      - 85% transferred to your Stripe Connect account
      - 15% retained by platform
    - View payment breakdown in portal

14. **Weekly Payouts**
    - Every Monday, system processes payouts
    - Calculates all completed sessions from past week
    - Automatic transfer to your bank account
    - Receive payout confirmation email
    - View payout history in portal

15. **Revenue Tracking**
    - Dashboard shows:
      - This week's earnings
      - Month-to-date total
      - Payout schedule
      - Session count

---

## Student/Parent Perspective

### 1. Discovery & Booking
**Goal:** Find a tutor and book trial session

1. **Discover Platform**
   - Visit website via:
     - Direct search
     - Referral link from friend
     - Social media ad
     - SEO blog content

2. **Free Trial Eligibility**
   - **Standard:** 1 free trial per family (per parent email)
   - **Referred Students:** Bypass free trial
     - If booking via referral link, no trial consumed
     - Referred family pays from first session
     - Referrer receives $50 reward after 1 month

3. **Submit Booking Request**
   - Complete booking form:
     - Student name and grade
     - Parent contact information
     - Subject and level needed
     - Preferred schedule
   - System creates demand ticket
   - Confirmation email sent

### 2. Tutor Matching
**Goal:** Get matched with qualified tutor

4. **Admin Review**
   - Admin reviews booking request
   - Autonomous matching engine suggests tutors
   - Admin assigns best-fit tutor

5. **Assignment Notification**
   - Email sent confirming tutor assignment
   - Tutor profile shared (name, subjects, experience)
   - Expected timeline for time proposals

6. **Time Selection**
   - Receive email with tutor's proposed times
   - Select preferred slot via secure link
   - Confirmation sent to both parties

### 3. Payment & Sessions
**Goal:** Complete payment and attend sessions

7. **Payment (Paid Sessions Only)**
   - After trial or for referred students:
     - Receive payment link
     - Pay via Stripe (credit card)
     - Amount based on tutor's hourly rate
   - Payment secured before session starts

8. **Session Attendance**
   - Receive reminder email 24 hours before
   - Join meeting via link in calendar invite
   - Student attends tutoring session

9. **Post-Session**
   - Receive session notes from tutor
   - View homework assignments in portal
   - Provide feedback if prompted

### 4. Referral Rewards
**Goal:** Earn rewards by referring friends

10. **Generate Referral Link**
    - After booking/trial, access referral portal
    - Generate unique referral link
    - Share with friends via email or social media

11. **Friend Books via Link**
    - Friend uses your referral link
    - Their trial is bypassed (they pay from session 1)
    - Referral tracked in system

12. **Earn Reward**
    - After referred student completes 1 month (4+ sessions):
      - System verifies referral
      - $50 Amazon gift card issued
      - Email sent with gift card code
    - Track all referrals in dashboard

---

## Admin Perspective

### 1. Application Management
**Goal:** Review and approve quality tutors

1. **Monitor Applications**
   - Admin Dashboard → Applications tab
   - Review submitted tutor applications
   - Check qualifications, experience, documents

2. **Approve/Reject**
   - Click approve or reject button
   - For approved tutors:
     - System triggers credential email
     - Tutor added to active tutors list
     - Onboarding process begins automatically

3. **Monitor Onboarding**
   - Track tutor completion of:
     - Rate setting ✓
     - Platform fee acceptance ✓
     - Stripe Connect completion ✓
   - Tutors appear as "Ready" when all complete

### 2. Matching & Assignment
**Goal:** Match students with appropriate tutors

4. **Review Demand Tickets**
   - Dashboard shows all booking requests
   - Filter by subject, grade, status
   - View student needs and preferences

5. **Use Matching Engine**
   - Click "Trigger Matching" button
   - Autonomous engine suggests best tutors based on:
     - Subject expertise
     - Grade level experience
     - Availability match
     - Response time history
   - Review suggestions

6. **Assign Tutor**
   - Select tutor for assignment
   - Click "Assign" button
   - System creates assignment record
   - Automatic notifications sent to:
     - Tutor (via email and portal)
     - Parent (confirmation email)

### 3. Response Time Monitoring
**Goal:** Ensure tutors respond promptly

7. **24-Hour Alert System**
   - Dashboard monitors all new assignments
   - If tutor doesn't propose times within 24 hours:
     - Alert appears in activity_alerts table
     - Red badge shown on dashboard
     - Email sent to tutor (reminder)
     - Email sent to admin (escalation)

8. **Follow-Up Actions**
   - Contact slow-responding tutors
   - Reassign if necessary
   - Track response time metrics per tutor

### 4. Financial Oversight
**Goal:** Monitor revenue and process payouts

9. **Revenue Dashboard**
   - View real-time metrics:
     - Total sessions this month
     - Platform revenue (15% of all sessions)
     - Tutor payouts (85% of all sessions)
     - Weekly breakdown chart

10. **Weekly Payout Processing**
    - Every Monday, system auto-processes:
      - Calculates completed sessions per tutor
      - Triggers Stripe payouts (90% to each tutor)
      - Logs all transactions
      - Sends confirmation emails

11. **Financial Reports**
    - Export monthly revenue reports
    - View tutor earnings breakdown
    - Track payment processing fees

### 5. Referral Management
**Goal:** Verify and process referral rewards

12. **Monitor Referrals**
    - Referral Dashboard tab
    - View all active referrals
    - Track referral status:
      - Pending: Referred student just booked
      - Verified: Student completed 1 month
      - Reward Issued: $50 gift card sent

13. **Automated Reward Processing**
    - System checks daily for referrals at 1-month mark
    - Auto-verifies eligible referrals
    - Triggers $50 Amazon gift card issuance
    - Sends reward email to referrer
    - Updates referral status

14. **Manual Verification (if needed)**
    - Review edge cases
    - Manually mark as verified
    - Issue rewards manually if system fails

### 6. Trial Tracking
**Goal:** Prevent trial abuse and ensure fairness

15. **Monitor Trial Usage**
    - Dashboard shows all student profiles
    - Filter: "Trial Consumed" status
    - Group by parent_email to detect:
      - Multi-student families
      - Duplicate trial attempts

16. **Referral Bypass Tracking**
    - Separate view for referred students
    - Confirm no trial was consumed
    - Verify payment from first session

17. **Data Integrity**
    - System validates: 1 trial per parent email
    - Alerts if duplicate trial attempts detected
    - Referred students flagged to bypass trial

---

## System State Transitions

### Demand Ticket States
1. **Open** → Awaiting admin review
2. **Matched** → Tutor assigned, awaiting time proposals
3. **Assigned** → Time proposals sent to parent
4. **Scheduled** → Parent selected time, session created
5. **Completed** → Session finished successfully
6. **Cancelled** → Request cancelled by admin/parent

### Session States
1. **Draft** → Time slot proposed but not confirmed
2. **Proposed** → Awaiting parent selection
3. **Scheduled** → Confirmed by parent, awaiting session
4. **Completed** → Session conducted successfully
5. **No Show** → Student didn't attend
6. **Cancelled** → Session cancelled before start

### Booking States
1. **Pending** → Submitted, awaiting admin action
2. **Matched** → Tutor assigned
3. **Awaiting Payment** → Session scheduled, payment needed
4. **Confirmed** → Payment received, session confirmed
5. **Completed** → Session finished
6. **Cancelled** → Booking cancelled

### Referral States
1. **Pending** → Referred student booked, tracking started
2. **Verified** → Student completed 1 month of sessions
3. **Reward Issued** → $50 gift card sent to referrer

---

## Key Metrics Tracked

### Tutor Metrics
- Response time (target: < 24 hours)
- Session completion rate
- Student engagement ratings
- Monthly earnings
- Hourly rate set
- Platform fee acceptance status
- Stripe Connect status

### Student Metrics
- Trial status (consumed/not consumed)
- Referral source (direct/referred)
- Session attendance rate
- Active/inactive status

### Platform Metrics
- Total active tutors
- Total active students
- Sessions per month
- Platform revenue (10% of all sessions)
- Tutor payouts (90% of all sessions)
- Referral conversion rate
- Average tutor response time

---

## Automation Points

1. **Email Notifications**
   - Application approval → Tutor credentials
   - Assignment created → Tutor & parent notification
   - Time proposals → Parent selection email
   - Session scheduled → Calendar invites
   - Payment processed → Confirmation emails
   - 24-hour reminder → Session participants
   - Weekly payout → Tutor confirmation
   - Referral reward → $50 gift card email

2. **System Triggers**
   - New booking → Create demand ticket
   - Tutor assigned → Start 24-hour timer
   - 24 hours elapsed → Send response alerts
   - Session completed → Process payment split
   - Monday morning → Process weekly payouts
   - 1 month after referral booking → Verify & reward
   - Trial consumed → Update student profile

3. **Data Synchronization**
   - Bookings → Student profiles
   - Assignments → Session creation
   - Completed sessions → Referral verification
   - Payment processing → Revenue tracking

---

## Support & Documentation

### For Tutors
- Tutor Guide: `/tutor-guide`
- Portal: `/tutor-dashboard`
- Support: Contact admin via portal

### For Parents
- User Guide: `/user-guide`
- FAQ: `/faq`
- Support: `/contact`

### For Admins
- Admin Guide: `/admin-guide`
- System Health: Admin Dashboard → Health tab
- QA Monitoring: Admin Dashboard → QA tab

---

## Emergency Procedures

### Tutor Not Responding
1. System sends automated reminder at 24 hours
2. Admin receives escalation alert
3. Admin contacts tutor directly
4. If no response in 48 hours, reassign student

### Payment Processing Failure
1. Stripe webhook triggers error alert
2. Admin notified via email
3. Manual intervention required
4. Refund/retry process initiated

### Session No-Show
1. Tutor marks session as "no show"
2. Admin notified for review
3. Parent contacted to reschedule
4. No charge applied if student no-show
5. Tutor compensated if parent no-show

---

*Last Updated: January 2025*
*Version: 1.0 - Post-Pricing Implementation*
