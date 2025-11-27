# Pricing Policy Documentation

## Overview
This document outlines the complete pricing structure, payment processing, and financial policies for the tutoring platform.

---

## Tutor Pricing

### Rate Setting
- **Tutors set their own hourly rates**
- Typical range: $20-$100 per hour
- Rate displayed to students during matching
- Tutors can update rates in their portal
- Rate changes apply to future bookings only

### Platform Fee Structure
**85/15 Split Model**
- **Tutor keeps:** 85% of session earnings
- **Platform fee:** 15% of session earnings

**Example Calculations:**
```
Tutor Rate: $50/hour
Student Pays: $50
Tutor Receives: $42.50 (85%)
Platform Keeps: $7.50 (15%)

Tutor Rate: $100/hour
Student Pays: $100
Tutor Receives: $85 (85%)
Platform Keeps: $15 (15%)
```

### Fee Acceptance Required
- Tutors must explicitly accept platform fee terms
- Acceptance tracked via `platform_fee_accepted` column
- Timestamp recorded in `platform_fee_accepted_at`
- Cannot receive assignments until fee accepted
- One-time acceptance (not required per booking)

---

## Student Pricing

### All Sessions Require Payment
- **No free trials offered** (eliminated October 2025)
- Students pay tutor's set rate from first session
- Transparent pricing shown during tutor matching
- **Cancel anytime policy** provides flexibility
- **Refunds evaluated case-by-case** based on individual circumstances

### Session Pricing
- **Rate determined by assigned tutor**
- Student sees rate during tutor selection/matching
- Stripe checkout process for payment
- Payment must be completed before session scheduled
- No hidden fees (rate shown is final amount charged)

---

## Refund Policy

### Overview
**Case-by-Case Evaluation:** Refund requests are evaluated individually based on the specific circumstances of each situation. This allows us to be fair to both families and tutors while maintaining service quality.

### When to Request a Refund
Contact us at info@lonestarteachers.com if you experience:
- Service quality issues
- Technical problems preventing sessions
- Tutor no-shows or cancellations
- Billing errors or payment issues
- Other legitimate concerns

### Evaluation Factors
When reviewing refund requests, we consider:
- **Reason for Request:** Nature and validity of the concern
- **Timing:** How quickly the issue was reported
- **Session History:** Whether this is a first session or ongoing relationship
- **Documentation:** Evidence supporting the request
- **Good Faith:** Whether both parties acted reasonably
- **Tutor Performance:** Historical ratings and feedback

### Refund Process
1. **Submit Request:** Email info@lonestarteachers.com with:
   - Student name and session details
   - Date and time of session
   - Specific reason for refund request
   - Any supporting documentation
2. **Admin Review:** Our team reviews within 24-48 hours
3. **Decision:** You'll receive a response with outcome and reasoning
4. **Processing:** Approved refunds processed within 3-5 business days

**Example Request Email:**
```
Subject: Refund Request - [Student Name]

Hi Lone Star Teachers,

I'd like to request a refund for the following session:
- Student: Jane Smith
- Session Date: January 15, 2025
- Tutor: John Doe
- Subject: Algebra
- Reason: [Detailed explanation of issue]

[Any supporting details]

Thank you,
[Parent Name]
```

### Common Refund Scenarios

#### Full Refunds (Typically Approved)
- **Tutor No-Show:** Tutor fails to attend scheduled session
- **Technical Failures:** Platform or meeting link issues preventing session
- **Billing Errors:** Duplicate charges or incorrect amounts
- **Service Not Delivered:** Session didn't occur as scheduled

#### Partial Refunds (Case-by-Case)
- **Session Quality Issues:** Concerns about teaching effectiveness
- **Partial Session Completion:** Session ended early due to issues
- **Communication Problems:** Significant misunderstandings

#### No Refunds (Typically)
- **Student No-Show:** Student doesn't attend scheduled session
- **Last-Minute Cancellation:** Less than 24 hours notice without valid reason
- **Buyer's Remorse:** Change of mind after receiving service
- **Unrealistic Expectations:** Service delivered as described but didn't meet unrealistic hopes

### Financial Responsibility

**Platform's Commitment:**
- We absorb refund costs to maintain trust
- Tutors are paid for services legitimately provided
- Refunds are not used punitively against tutors
- Focus on fair resolution for all parties

**Cost Structure When Refunds Occur:**
```
Example Session: $50
Student Paid: $50
Tutor Received: $42.50 (85%)
Platform Fee: $7.50 (15%)

If Full Refund Approved:
- Student Refunded: $50 (100%)
- Platform Cost: Variable based on circumstances
- Tutor Impact: Evaluated case-by-case
```

### Abuse Prevention
- One account per family email
- Pattern monitoring for refund abuse
- Right to deny requests showing bad faith
- Account termination for fraudulent requests

### Quality Assurance
Rather than blanket guarantees, we focus on:
- **Thorough Tutor Vetting:** Background checks and subject verification
- **Ongoing Quality Monitoring:** Rating systems and feedback loops
- **Responsive Support:** Quick resolution of legitimate concerns
- **Fair Conflict Resolution:** Balanced approach protecting all parties

### Communication to Stakeholders

**To Parents/Students:**
*"We're committed to your satisfaction. If you have any concerns about your tutoring experience, contact us at info@lonestarteachers.com. While we can't guarantee refunds in all cases, we carefully review each situation and work to find fair solutions."*

**To Tutors:**
*"Refund requests are handled individually and fairly. We protect your earnings when you deliver quality service as agreed. If a refund is warranted due to circumstances beyond your control, we work to minimize your financial impact while maintaining platform integrity."*

### Metrics to Track
- **Refund Request Rate:** % of sessions with refund requests
- **Approval Rate:** % of requests approved vs. denied
- **Monthly Refund Cost:** Total platform cost for refunds
- **Reason Categories:** Common reasons for refund requests
- **Resolution Time:** Average time to process requests

---

## Payment Processing

### Stripe Integration
**Platform Account:**
- Main Stripe account receives all payments
- Holds platform's 15% fee
- Manages payment processing

**Stripe Connect for Tutors:**
- Each tutor has Stripe Express Connect account
- Onboarding required before first payout
- Tutor provides bank account information
- Identity verification handled by Stripe
- Direct payouts to tutor bank accounts

### Payment Flow
**For Each Session:**
```
1. Student pays via Stripe Checkout
   └─> Amount: Tutor's hourly rate

2. Payment received in Platform Stripe Account
   └─> Full amount held temporarily

3. Session completed and marked as such
   └─> Triggers payment split calculation

4. Platform creates destination charge
   └─> 85% → Tutor's Stripe Connect account
   └─> 15% → Platform retains

5. Weekly payout process
   └─> Stripe transfers to tutor's bank account
```

### Payment Metadata
Each payment includes:
```json
{
  "session_id": "uuid",
  "tutor_id": "uuid",
  "tutor_stripe_account": "acct_xxx",
  "amount_total": 5000,  // $50.00 in cents
  "tutor_amount": 4250,  // $42.50 (85%)
  "platform_fee": 750,   // $7.50 (15%)
  "session_date": "2025-01-15T10:00:00Z"
}
```

---

## Payout Schedule

### Weekly Payouts to Tutors
**Timing:** Every Monday at 12:00 PM CST

**Process:**
1. System queries all completed sessions from past week
2. Groups sessions by tutor
3. Calculates 85% of each session amount
4. Sums total owed to each tutor
5. Triggers Stripe payout to tutor's Connect account
6. Updates `last_payout_at` timestamp
7. Sends confirmation email to tutor

**Edge Function:** `process-tutor-payouts`
```typescript
// Runs every Monday via cron job
const payoutResults = await processTutorPayouts({
  startDate: lastMonday,
  endDate: thisSunday
});

// Example result:
{
  tutor_id: "uuid",
  sessions_count: 5,
  gross_earnings: 25000,  // $250.00
  platform_fee: 3750,     // $37.50 (15%)
  net_payout: 21250,      // $212.50 (85%)
  payout_status: "pending"
}
```

### Payout History
Tutors can view in their dashboard:
- Current week accumulated earnings
- Past payouts with dates and amounts
- Breakdown by session
- Platform fee deductions

---

## Referral Rewards

### $50 Amazon Gift Card Program
**Eligibility:**
- Referrer must be existing parent/student
- Referred student must book via referral link
- Referred student must complete 1 month of sessions (typically 4 sessions)
- Both families must remain active

**Verification Process:**
```sql
-- After 30 days from referral booking
SELECT r.id, r.referred_student_name, 
       COUNT(s.id) as session_count
FROM referrals r
JOIN student_profiles sp ON sp.parent_email = r.referred_parent_email
JOIN sessions s ON s.student_id = sp.user_id
WHERE r.status = 'pending'
AND r.created_at <= NOW() - INTERVAL '30 days'
AND s.status = 'completed'
GROUP BY r.id
HAVING COUNT(s.id) >= 4;
```

**Reward Issuance:**
1. System auto-verifies at 30-day mark
2. Changes referral status to 'verified'
3. Triggers Amazon gift card API
4. Sends email with $50 gift card code
5. Updates `reward_issued_at` timestamp
6. Changes status to 'reward_issued'

### Referral Tracking
**Referrer Dashboard Shows:**
- Total referrals made
- Pending referrals (awaiting 1 month)
- Verified referrals (rewards issued)
- Total rewards earned
- Referral link with copy button

---

## Financial Reporting

### Admin Revenue Dashboard
**Key Metrics:**
- **Monthly Revenue:** Total platform fees collected (15%)
- **Tutor Payouts:** Total paid to tutors (85%)
- **Session Volume:** Total sessions completed
- **Average Session Value:** Mean tutor rate across all sessions
- **Payment Success Rate:** % of successful payments

**Weekly Breakdown:**
```
Week 1: 20 sessions × $50 avg = $1000 gross
        Platform: $150 (15%)
        Tutors: $850 (85%)

Week 2: 25 sessions × $60 avg = $1500 gross
        Platform: $225 (15%)
        Tutors: $1275 (85%)

Monthly Total: $2600 gross
               Platform: $390
               Tutors: $2210
```

### Export Capabilities
- CSV download of all transactions
- Filtered by date range, tutor, student
- Tax reporting data (1099 preparation)
- Session-level detail reports

---

## Termination & Refund Policy

### Survey-Based Quality System
**Rating Scale:** 1-5 stars with post-session parent surveys
- **1-2 Stars:** Immediate admin review and notification
- **3 Stars (Multiple):** Warning system (3+ within 30 days)
- **Below 3.5 Average:** Termination consideration (minimum 10 sessions)
- **Admin Discretion:** Extreme single cases may warrant immediate action

### Admin-Initiated Termination Scenarios

#### Scenario 1: Low-Rating Tutor Termination
**Situation:** Tutor consistently receives poor ratings (< 3.5 average over 10+ sessions)

**Refund Policy:**
- **Parents Affected:** Refunds evaluated case-by-case based on circumstances
- **Evaluation Factors:** Session history, ratings, specific issues reported
- **Platform Responsibility:** Fair resolution while protecting tutor earnings
- **Rationale:** Balanced approach considering all parties involved

**Process:**
1. Admin identifies low-performing tutor via automated alerts
2. Admin reviews ratings, parent feedback, and improvement attempts
3. If termination warranted, admin sends termination notice to tutor
4. Platform issues full refunds to affected families automatically
5. Affected families offered priority matching with higher-rated tutor

**Example Calculation:**
```
Session Rate: $50
Parent Paid: $50
Tutor Received: $42.50 (85%)
Platform Kept: $7.50 (15%)

On Termination:
- Parent Refunded: $50 (full amount)
- Platform Loss: $57.50 ($50 refund + $7.50 fee = net $7.50 loss per session)
- Tutor Impact: $0 (keeps their $42.50 earnings)
```

#### Scenario 2: Problem Parent Termination
**Situation:** Parent demonstrates unreasonable behavior, unrealistic expectations, or abusive conduct

**Refund Policy:**
- **Parent Refund:** Typically none for behavior-based terminations
- **Tutor Compensation:** Tutor keeps full 85% for completed sessions
- **Platform Fee:** Platform retains 15% fee
- **Evaluation:** Case-by-case review of specific circumstances
- **Rationale:** Platform protects tutors from unreasonable clients

**Qualifying Behaviors for Parent Termination:**
- Abusive or harassing communication toward tutor
- Consistent unrealistic demands (expecting instant results, excessive work outside sessions)
- Repeated false or malicious low ratings not supported by facts
- Violation of platform terms (payment disputes, unauthorized recording, etc.)
- Pattern of no-shows or last-minute cancellations without valid reason

**Process:**
1. Tutor reports concerning parent behavior to admin with documentation
2. Admin investigates (reviews communication logs, rating patterns, session records)
3. Admin provides warning to parent if first offense
4. If behavior continues or is severe, admin terminates parent account
5. No refund issued - parent forfeits remaining session value
6. Tutor compensated for completed sessions per normal 85/15 split

### User-Initiated Termination Scenarios

#### Scenario 3: Parent-Initiated Termination (With Notice)
**Situation:** Parent decides to discontinue tutoring for legitimate reasons (schedule change, subject completed, etc.)

**Refund Policy:**
- **Evaluation:** Case-by-case based on circumstances and notice provided
- **Typical Considerations:**
  - Advance notice given (2+ weeks, 1 week, less than 1 week)
  - Reason for discontinuation
  - Number of sessions completed
  - Good faith of both parties
- **Fair Resolution:** Balanced approach considering both family needs and tutor schedule impact
- **Example:** Parent discontinuing after 4 sessions with 2 weeks notice may receive different consideration than last-minute cancellation

**Process:**
1. Parent submits termination request via portal with reason
2. System calculates refund based on notice period
3. Admin reviews and approves (checks for any disputes or issues)
4. Refund processed within 3-5 business days
5. Tutor notified of schedule opening

#### Scenario 4: Tutor-Initiated Termination
**Situation:** Tutor needs to discontinue relationship (schedule conflict, relocation, subject mismatch, etc.)

**Refund Policy:**
- **Evaluation:** Case-by-case based on circumstances
- **Typical Resolution:** Priority matching with replacement tutor at same rate
- **Refund Consideration:** Depends on notice provided and reason for termination
- **Alternative:** Seamless tutor transition when possible
- **Rationale:** Commitment to student continuity while being fair to all parties

**Process:**
1. Tutor submits termination notice with minimum 2 weeks advance notice
2. Platform immediately assigns replacement tutor if available
3. If replacement acceptable, no refund needed (sessions transfer)
4. If no suitable replacement or parent declines, full refund issued
5. Platform may charge tutor cancellation fee if termination without valid reason

### Technical Issues & Platform Errors
**Typical Refund Scenarios:**
1. **Tutor No-Show:** Usually approved with makeup session credit
2. **Technical Issues:** Platform-side failures preventing session typically approved
3. **Billing Error:** Overcharge or duplicate charge corrected immediately
4. **Meeting Link Failure:** Google Meet issues preventing session typically result in refund or rescheduling

All cases evaluated individually to ensure fair resolution.

**Refund Process:**
```typescript
// Admin initiates refund
const refund = await stripe.refunds.create({
  payment_intent: session.payment_intent_id,
  amount: refundAmount, // Full amount for technical issues
  reason: 'requested_by_customer',
  metadata: {
    refund_type: 'technical_issue',
    session_id: session.id,
    issue_description: 'Google Meet link failure'
  }
});

// Platform absorbs refund (tutor still paid if technical issue not their fault)
```

### Appeal Process
**Timeline:** 7 days from termination notification

**Tutor Appeals:**
- Submit evidence of rating manipulation or unfair assessments
- Provide context for low ratings (difficult student, parent unrealistic expectations)
- Show improvement efforts and recent performance improvements
- Admin reviews with fresh perspective and may reverse decision

**Parent Appeals:**
- Challenge "problem parent" designation with documentation
- Provide evidence that tutor was at fault for low ratings
- Demonstrate good faith efforts to resolve issues constructively
- Admin reviews communication logs and makes final determination

**Appeal Submission:**
- Email: info@lonestarteachers.com
- Subject: "Appeal - [Termination Type] - [Your Name]"
- Include: Timeline of events, supporting documentation, desired outcome
- Response Time: 3-5 business days

---

## Pricing Transparency

### Student-Facing Information
- Tutor rates clearly displayed during matching
- No hidden fees
- Free trial eligibility shown upfront
- Referral discount explained

### Tutor-Facing Information
- 85/15 split explained in onboarding
- Platform fee acceptance required before assignments
- Payout schedule clearly communicated
- No surprise deductions

### Admin Transparency
- All financial transactions logged
- Audit trail for every payment and payout
- Real-time visibility into platform revenue
- Compliance with financial regulations

---

## Tax Considerations

### For Tutors (Independent Contractors)
- Tutors are independent contractors, not employees
- Platform issues 1099-NEC if earnings > $600/year
- Tutors responsible for self-employment taxes
- Platform provides annual earnings summary

### For Platform
- Platform fee (15%) is taxable revenue
- Stripe fees are deductible expenses
- Referral rewards are marketing expenses
- Detailed record-keeping for all transactions

---

## Security & Compliance

### PCI Compliance
- All payments processed via Stripe (PCI-compliant)
- No credit card data stored on platform
- Tokenization for repeat customers

### Data Protection
- Financial data encrypted at rest and in transit
- Access restricted to admin users only
- Audit logs for all financial operations

### Fraud Prevention
- Stripe Radar monitors for suspicious activity
- Duplicate trial prevention (by parent_email)
- Referral link validation to prevent gaming
- Manual admin review for high-value transactions

---

## Policy Updates

### Rate Change Policy
**Tutors:**
- Can update rates anytime via portal
- Changes apply to new bookings only
- Existing scheduled sessions honor old rate

**Platform Fee:**
- Currently fixed at 15%
- Any changes require:
  - 30 days notice to tutors
  - Re-acceptance of terms
  - Grandfather clause for existing tutors (optional)

### Trial Policy Updates
- Changes require admin approval
- Existing students grandfathered
- Clear communication to all parents

---

## Contact for Financial Inquiries

**Tutors:** tutor-support@platform.com  
**Students/Parents:** student-support@platform.com  
**Admin Team:** admin@platform.com

---

*Last Updated: January 2025*  
*Version: 1.0 - Initial Pricing Implementation*
