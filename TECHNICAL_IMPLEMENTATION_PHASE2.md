# Technical Implementation Summary - Phase 2 (Pricing & Payouts)

## ⚠️ BLOCKED: esm.sh CDN Issue
**Status:** All edge function deployments are blocked due to esm.sh CDN returning 522 errors.  
**Required Action:** Monitor https://esm.sh/ status and resume Phase 2 implementation once resolved.

---

## Database Schema Changes (Ready to Execute)

### Tutors Table Enhancements

```sql
-- Add pricing and payout columns to tutors table
ALTER TABLE tutors 
ADD COLUMN IF NOT EXISTS hourly_rate DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS platform_fee_accepted BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS platform_fee_accepted_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS stripe_connect_account_id TEXT,
ADD COLUMN IF NOT EXISTS stripe_onboarding_completed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_existing_students BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS payout_schedule TEXT DEFAULT 'weekly',
ADD COLUMN IF NOT EXISTS last_payout_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS average_response_time_hours DECIMAL(5,2);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_tutors_stripe_connect 
ON tutors(stripe_connect_account_id) 
WHERE stripe_connect_account_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_tutors_hourly_rate 
ON tutors(hourly_rate) 
WHERE hourly_rate IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_tutors_fee_accepted 
ON tutors(platform_fee_accepted) 
WHERE platform_fee_accepted = TRUE;

-- Add comments for documentation
COMMENT ON COLUMN tutors.hourly_rate IS 'Tutor-set hourly rate in dollars';
COMMENT ON COLUMN tutors.platform_fee_accepted IS 'Whether tutor accepted 90/10 split terms';
COMMENT ON COLUMN tutors.stripe_connect_account_id IS 'Stripe Express Connect account ID for payouts';
COMMENT ON COLUMN tutors.average_response_time_hours IS 'Average time to propose times after assignment (hours)';
```

### Payments Table (New)

```sql
-- Create payments tracking table
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,
  assignment_id UUID REFERENCES assignments(id) ON DELETE SET NULL,
  student_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  tutor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  tutor_profile_id UUID REFERENCES tutors(id) ON DELETE SET NULL,
  
  -- Stripe data
  stripe_payment_intent_id TEXT UNIQUE NOT NULL,
  stripe_charge_id TEXT,
  
  -- Amount breakdown (in cents)
  amount_total INTEGER NOT NULL,
  amount_tutor INTEGER NOT NULL,     -- 90% of total
  amount_platform INTEGER NOT NULL,  -- 10% of total
  
  -- Status tracking
  status TEXT NOT NULL DEFAULT 'pending',
  payment_method TEXT,
  
  -- Timestamps
  paid_at TIMESTAMPTZ,
  refunded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb,
  
  CONSTRAINT payments_status_check 
    CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded', 'canceled'))
);

-- Create indexes
CREATE INDEX idx_payments_session ON payments(session_id);
CREATE INDEX idx_payments_tutor ON payments(tutor_profile_id);
CREATE INDEX idx_payments_stripe_intent ON payments(stripe_payment_intent_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_paid_at ON payments(paid_at);

-- Enable RLS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Admins can view all payments"
ON payments FOR SELECT
USING (get_current_user_role() IN ('owner', 'admin'));

CREATE POLICY "Tutors can view their own payments"
ON payments FOR SELECT
USING (tutor_id = auth.uid());

CREATE POLICY "System can insert payments"
ON payments FOR INSERT
WITH CHECK (true);

COMMENT ON TABLE payments IS 'Tracks all payment transactions with 90/10 split details';
```

### Tutor Payouts Table (New)

```sql
-- Create tutor payouts tracking table
CREATE TABLE IF NOT EXISTS tutor_payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tutor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  tutor_profile_id UUID REFERENCES tutors(id) ON DELETE CASCADE,
  
  -- Payout period
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  
  -- Payout details
  sessions_count INTEGER NOT NULL DEFAULT 0,
  gross_earnings INTEGER NOT NULL DEFAULT 0,  -- Total before split (cents)
  platform_fee INTEGER NOT NULL DEFAULT 0,    -- 10% fee (cents)
  net_payout INTEGER NOT NULL DEFAULT 0,      -- 90% to tutor (cents)
  
  -- Stripe payout
  stripe_payout_id TEXT,
  stripe_transfer_id TEXT,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'pending',
  processed_at TIMESTAMPTZ,
  arrived_at TIMESTAMPTZ,
  
  -- Session IDs included in this payout
  session_ids UUID[] DEFAULT ARRAY[]::UUID[],
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT tutor_payouts_status_check
    CHECK (status IN ('pending', 'processing', 'paid', 'failed', 'canceled'))
);

-- Create indexes
CREATE INDEX idx_payouts_tutor ON tutor_payouts(tutor_profile_id);
CREATE INDEX idx_payouts_period ON tutor_payouts(period_start, period_end);
CREATE INDEX idx_payouts_status ON tutor_payouts(status);
CREATE INDEX idx_payouts_processed ON tutor_payouts(processed_at);

-- Enable RLS
ALTER TABLE tutor_payouts ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Admins can manage payouts"
ON tutor_payouts FOR ALL
USING (get_current_user_role() IN ('owner', 'admin'));

CREATE POLICY "Tutors can view own payouts"
ON tutor_payouts FOR SELECT
USING (tutor_id = auth.uid());

COMMENT ON TABLE tutor_payouts IS 'Weekly payout batches to tutors (85% of earnings)';
```

### Response Time Tracking

```sql
-- Add response time tracking to assignments
ALTER TABLE assignments
ADD COLUMN IF NOT EXISTS time_proposal_created_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS response_time_hours DECIMAL(5,2);

-- Create function to calculate response time
CREATE OR REPLACE FUNCTION calculate_response_time()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.time_proposal_created_at IS NOT NULL AND OLD.time_proposal_created_at IS NULL THEN
    NEW.response_time_hours = EXTRACT(EPOCH FROM (NEW.time_proposal_created_at - NEW.created_at)) / 3600;
    
    -- Update tutor's average response time
    UPDATE tutors
    SET average_response_time_hours = (
      SELECT AVG(response_time_hours)
      FROM assignments
      WHERE tutor_profile_id = NEW.tutor_profile_id
      AND response_time_hours IS NOT NULL
    )
    WHERE id = NEW.tutor_profile_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER update_response_time
BEFORE UPDATE ON assignments
FOR EACH ROW
EXECUTE FUNCTION calculate_response_time();
```

---

## Edge Function Updates (Ready to Deploy - Pending CDN Fix)

### 1. Enhanced Tutor Credentials Email

**File:** `supabase/functions/send-tutor-credentials/index.ts`

**Key Changes:**
- Add pricing policy section to email template
- Include Stripe Connect onboarding instructions
- Explain 90/10 split clearly
- Provide referral program details
- Add 24-hour response time requirement

**Email Template Additions:**
```html
<h2>Set Your Hourly Rate</h2>
<p>You control your pricing! Set your hourly rate in the tutor portal (typically $20-$100/hour).</p>

<h2>Platform Fee - 90/10 Split</h2>
<p><strong>You keep 90% of your earnings.</strong> The platform takes a 10% fee to cover:</p>
<ul>
  <li>Payment processing</li>
  <li>Student-tutor matching</li>
  <li>Scheduling and reminders</li>
  <li>Platform maintenance</li>
</ul>
<p>Example: If you charge $50/hour, you receive $45 per session.</p>

<h2>Set Up Stripe Connect</h2>
<p>To receive payouts, complete Stripe Express onboarding:</p>
<a href="{{stripe_onboarding_link}}">Complete Stripe Setup</a>
<p>Weekly payouts every Monday to your bank account.</p>

<h2>24-Hour Response Requirement</h2>
<p><strong>Important:</strong> When assigned a student, propose session times within 24 hours. This ensures great service and helps you build a strong reputation.</p>
```

### 2. Enhanced Payment Creation

**File:** `supabase/functions/create-payment/index.ts`

**Key Changes:**
```typescript
import Stripe from 'npm:stripe@14.10.0';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
});

interface PaymentRequest {
  sessionId: string;
  assignmentId?: string;
  studentEmail: string;
  successUrl: string;
  cancelUrl: string;
}

Deno.serve(async (req) => {
  const { sessionId, assignmentId, studentEmail, successUrl, cancelUrl } = 
    await req.json() as PaymentRequest;

  // 1. Fetch session details
  const { data: session } = await supabase
    .from('sessions')
    .select(`
      *,
      student_profiles:student_profile_id (parent_email),
      tutors:tutor_profile_id (
        id,
        hourly_rate,
        stripe_connect_account_id,
        platform_fee_accepted
      )
    `)
    .eq('id', sessionId)
    .single();

  if (!session) throw new Error('Session not found');

  // 2. Verify tutor has accepted platform fee
  if (!session.tutors.platform_fee_accepted) {
    throw new Error('Tutor has not accepted platform fee terms');
  }

  // 3. Verify tutor has Stripe Connect account
  if (!session.tutors.stripe_connect_account_id) {
    throw new Error('Tutor has not completed Stripe onboarding');
  }

  // 4. Check if referred student (bypass trial)
  const { data: referral } = await supabase
    .from('referrals')
    .select('id')
    .eq('referred_parent_email', session.student_profiles.parent_email)
    .maybeSingle();

  const isReferredStudent = !!referral;

  // 5. Check trial eligibility (if not referred)
  let isTrial = false;
  if (!isReferredStudent) {
    const { data: studentProfile } = await supabase
      .from('student_profiles')
      .select('trial_consumed_at')
      .eq('parent_email', session.student_profiles.parent_email)
      .single();

    isTrial = !studentProfile?.trial_consumed_at;
  }

  // 6. Calculate amounts (90/10 split)
  const tutorRate = session.tutors.hourly_rate || 50; // Default $50
  const amountTotal = Math.round(tutorRate * 100); // Convert to cents
  const platformFee = Math.round(amountTotal * 0.10); // 10%
  const tutorAmount = amountTotal - platformFee; // 90%

  // 7. Create Stripe Checkout Session
  let checkoutSession;
  
  if (isTrial) {
    // Free trial - no payment
    checkoutSession = await stripe.checkout.sessions.create({
      mode: 'payment',
      success_url: successUrl,
      cancel_url: cancelUrl,
      customer_email: studentEmail,
      line_items: [{
        price_data: {
          currency: 'usd',
          product_data: {
            name: `Tutoring Session - ${session.subject}`,
            description: 'FREE TRIAL SESSION'
          },
          unit_amount: 0
        },
        quantity: 1
      }],
      metadata: {
        session_id: sessionId,
        assignment_id: assignmentId || '',
        is_trial: 'true',
        tutor_id: session.tutors.id
      }
    });

    // Mark trial as consumed
    await supabase
      .from('student_profiles')
      .update({ trial_consumed_at: new Date().toISOString() })
      .eq('parent_email', session.student_profiles.parent_email);

  } else {
    // Paid session - create destination charge
    checkoutSession = await stripe.checkout.sessions.create({
      mode: 'payment',
      success_url: successUrl,
      cancel_url: cancelUrl,
      customer_email: studentEmail,
      payment_intent_data: {
        application_fee_amount: platformFee,
        transfer_data: {
          destination: session.tutors.stripe_connect_account_id,
        },
        metadata: {
          session_id: sessionId,
          tutor_id: session.tutors.id,
          amount_total: amountTotal.toString(),
          tutor_amount: tutorAmount.toString(),
          platform_fee: platformFee.toString()
        }
      },
      line_items: [{
        price_data: {
          currency: 'usd',
          product_data: {
            name: `Tutoring Session - ${session.subject}`,
            description: `1-hour tutoring session with ${session.tutor_name}`
          },
          unit_amount: amountTotal
        },
        quantity: 1
      }],
      metadata: {
        session_id: sessionId,
        assignment_id: assignmentId || '',
        is_trial: 'false',
        is_referred: isReferredStudent.toString(),
        tutor_id: session.tutors.id
      }
    });

    // Log payment record
    await supabase.from('payments').insert({
      session_id: sessionId,
      assignment_id: assignmentId,
      tutor_profile_id: session.tutors.id,
      stripe_payment_intent_id: checkoutSession.payment_intent,
      amount_total: amountTotal,
      amount_tutor: tutorAmount,
      amount_platform: platformFee,
      status: 'pending',
      metadata: {
        is_referred: isReferredStudent,
        tutor_rate: tutorRate
      }
    });
  }

  return new Response(JSON.stringify({ 
    url: checkoutSession.url,
    isTrial,
    isReferred: isReferredStudent 
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
});
```

### 3. NEW: Stripe Connect Onboarding

**File:** `supabase/functions/setup-tutor-stripe-connect/index.ts`

```typescript
import Stripe from 'npm:stripe@14.10.0';
import { createClient } from 'npm:@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
});

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

interface OnboardingRequest {
  tutorId: string;
  tutorEmail: string;
  refreshUrl: string;
  returnUrl: string;
}

Deno.serve(async (req) => {
  const { tutorId, tutorEmail, refreshUrl, returnUrl } = 
    await req.json() as OnboardingRequest;

  // 1. Check if tutor already has Connect account
  const { data: tutor } = await supabase
    .from('tutors')
    .select('stripe_connect_account_id')
    .eq('id', tutorId)
    .single();

  let accountId = tutor?.stripe_connect_account_id;

  // 2. Create Stripe Connect account if doesn't exist
  if (!accountId) {
    const account = await stripe.accounts.create({
      type: 'express',
      email: tutorEmail,
      capabilities: {
        transfers: { requested: true },
      },
      business_type: 'individual',
    });

    accountId = account.id;

    // Save to database
    await supabase
      .from('tutors')
      .update({ 
        stripe_connect_account_id: accountId,
        stripe_onboarding_completed: false
      })
      .eq('id', tutorId);
  }

  // 3. Create account link for onboarding
  const accountLink = await stripe.accountLinks.create({
    account: accountId,
    refresh_url: refreshUrl,
    return_url: returnUrl,
    type: 'account_onboarding',
  });

  // 4. Send email with onboarding link
  await supabase.functions.invoke('send-notification', {
    body: {
      to: tutorEmail,
      subject: 'Complete Your Stripe Setup for Payouts',
      html: `
        <h2>Set Up Your Payout Account</h2>
        <p>To receive your tutoring earnings, complete Stripe Express onboarding:</p>
        <a href="${accountLink.url}" style="background: #635BFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">
          Complete Stripe Setup
        </a>
        <p>You'll receive weekly payouts (85% of earnings) directly to your bank account.</p>
        <p>This is a secure process managed by Stripe, our payment processor.</p>
      `
    }
  });

  return new Response(JSON.stringify({ 
    onboardingUrl: accountLink.url 
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
});
```

### 4. NEW: Weekly Payout Processor

**File:** `supabase/functions/process-tutor-payouts/index.ts`

```typescript
import Stripe from 'npm:stripe@14.10.0';
import { createClient } from 'npm:@supabase/supabase-js@2';
import { subDays, startOfWeek, endOfWeek } from 'npm:date-fns@3';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
});

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

Deno.serve(async (req) => {
  const today = new Date();
  const lastWeekStart = startOfWeek(subDays(today, 7));
  const lastWeekEnd = endOfWeek(subDays(today, 7));

  console.log(`Processing payouts for ${lastWeekStart} to ${lastWeekEnd}`);

  // 1. Get all completed sessions from last week with payment data
  const { data: payments } = await supabase
    .from('payments')
    .select(`
      *,
      sessions!inner (
        id,
        status,
        tutor_profile_id,
        scheduled_start
      )
    `)
    .eq('status', 'succeeded')
    .eq('sessions.status', 'completed')
    .gte('sessions.scheduled_start', lastWeekStart.toISOString())
    .lte('sessions.scheduled_start', lastWeekEnd.toISOString());

  if (!payments || payments.length === 0) {
    console.log('No payments to process');
    return new Response(JSON.stringify({ message: 'No payouts needed' }));
  }

  // 2. Group by tutor
  const payoutsByTutor = payments.reduce((acc, payment) => {
    const tutorId = payment.sessions.tutor_profile_id;
    if (!acc[tutorId]) {
      acc[tutorId] = {
        tutorId,
        sessions: [],
        grossEarnings: 0,
        platformFee: 0,
        netPayout: 0
      };
    }
    acc[tutorId].sessions.push(payment.sessions.id);
    acc[tutorId].grossEarnings += payment.amount_total;
    acc[tutorId].platformFee += payment.amount_platform;
    acc[tutorId].netPayout += payment.amount_tutor;
    return acc;
  }, {});

  // 3. Process each tutor's payout
  const results = [];
  for (const tutorId in payoutsByTutor) {
    const payoutData = payoutsByTutor[tutorId];

    // Get tutor details
    const { data: tutor } = await supabase
      .from('tutors')
      .select('stripe_connect_account_id, user_id, email')
      .eq('id', tutorId)
      .single();

    if (!tutor?.stripe_connect_account_id) {
      console.error(`Tutor ${tutorId} has no Stripe Connect account`);
      continue;
    }

    try {
      // Create Stripe payout (already transferred via destination charges)
      // This is just for record-keeping
      const payout = await stripe.payouts.create(
        {
          amount: payoutData.netPayout,
          currency: 'usd',
          method: 'standard',
        },
        {
          stripeAccount: tutor.stripe_connect_account_id,
        }
      );

      // Record payout in database
      const { data: payoutRecord } = await supabase
        .from('tutor_payouts')
        .insert({
          tutor_id: tutor.user_id,
          tutor_profile_id: tutorId,
          period_start: lastWeekStart.toISOString().split('T')[0],
          period_end: lastWeekEnd.toISOString().split('T')[0],
          sessions_count: payoutData.sessions.length,
          gross_earnings: payoutData.grossEarnings,
          platform_fee: payoutData.platformFee,
          net_payout: payoutData.netPayout,
          stripe_payout_id: payout.id,
          status: 'paid',
          processed_at: new Date().toISOString(),
          session_ids: payoutData.sessions
        })
        .select()
        .single();

      // Update tutor last_payout_at
      await supabase
        .from('tutors')
        .update({ last_payout_at: new Date().toISOString() })
        .eq('id', tutorId);

      // Send confirmation email
      await supabase.functions.invoke('send-notification', {
        body: {
          to: tutor.email,
          subject: `Weekly Payout Processed - $${(payoutData.netPayout / 100).toFixed(2)}`,
          html: `
            <h2>Your Weekly Payout is on the Way!</h2>
            <p><strong>Payout Amount: $${(payoutData.netPayout / 100).toFixed(2)}</strong></p>
            <p>Sessions Completed: ${payoutData.sessions.length}</p>
            <p>Gross Earnings: $${(payoutData.grossEarnings / 100).toFixed(2)}</p>
            <p>Platform Fee (10%): $${(payoutData.platformFee / 100).toFixed(2)}</p>
            <p>Your payout will arrive in your bank account within 2-3 business days.</p>
            <p>View details in your tutor portal.</p>
          `
        }
      });

      results.push({
        tutorId,
        status: 'success',
        amount: payoutData.netPayout,
        sessions: payoutData.sessions.length
      });

    } catch (error) {
      console.error(`Failed to process payout for tutor ${tutorId}:`, error);
      results.push({
        tutorId,
        status: 'failed',
        error: error.message
      });
    }
  }

  return new Response(JSON.stringify({ 
    processed: results.length,
    results 
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
});
```

### 5. NEW: Response Time Monitor

**File:** `supabase/functions/monitor-tutor-response-times/index.ts`

```typescript
import { createClient } from 'npm:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

Deno.serve(async (req) => {
  const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

  // Find assignments created > 24 hours ago with no time proposals
  const { data: slowAssignments } = await supabase
    .from('assignments')
    .select(`
      id,
      created_at,
      tutor_id,
      tutor_profile_id,
      student_name,
      subject,
      tutors!inner (
        full_name,
        email
      )
    `)
    .eq('status', 'assigned')
    .lt('created_at', twentyFourHoursAgo.toISOString())
    .is('time_proposal_created_at', null);

  if (!slowAssignments || slowAssignments.length === 0) {
    return new Response(JSON.stringify({ message: 'All tutors responding on time' }));
  }

  // Create alerts for each slow response
  for (const assignment of slowAssignments) {
    const hoursElapsed = (Date.now() - new Date(assignment.created_at).getTime()) / (1000 * 60 * 60);

    // Create activity alert
    await supabase.from('activity_alerts').insert({
      type: 'tutor_slow_response',
      title: `Tutor Response Overdue - ${assignment.tutors.full_name}`,
      message: `Tutor has not proposed times for ${assignment.student_name} (${assignment.subject}) after ${Math.round(hoursElapsed)} hours`,
      severity: 'high',
      category: 'tutor_response',
      action_required: true,
      related_table: 'assignments',
      related_record_id: assignment.id,
      actions: {
        assignment_id: assignment.id,
        tutor_id: assignment.tutor_profile_id,
        hours_elapsed: Math.round(hoursElapsed)
      }
    });

    // Send email to tutor
    await supabase.functions.invoke('send-notification', {
      body: {
        to: assignment.tutors.email,
        subject: 'ACTION REQUIRED: Student Awaiting Your Response',
        html: `
          <h2 style="color: #dc2626;">Urgent: Student Waiting for Your Response</h2>
          <p>You were assigned a new student <strong>${Math.round(hoursElapsed)} hours ago</strong> but have not yet proposed session times.</p>
          <p><strong>Student:</strong> ${assignment.student_name}</p>
          <p><strong>Subject:</strong> ${assignment.subject}</p>
          <p><strong>Expected Response Time:</strong> Within 24 hours</p>
          <p style="background: #fee2e2; padding: 12px; border-left: 4px solid #dc2626;">
            <strong>Action Required:</strong> Please log in to your tutor portal and propose 3-5 available time slots immediately.
          </p>
          <a href="https://yourplatform.com/tutor-dashboard" style="background: #dc2626; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">
            Propose Times Now
          </a>
          <p><em>Consistent delays may affect your standing on the platform.</em></p>
        `
      }
    });

    // Send alert to admin
    await supabase.functions.invoke('send-notification', {
      body: {
        to: 'admin@yourplatform.com',
        subject: `ALERT: Tutor ${assignment.tutors.full_name} - Slow Response`,
        html: `
          <h2>Tutor Response Alert</h2>
          <p><strong>Tutor:</strong> ${assignment.tutors.full_name}</p>
          <p><strong>Assignment:</strong> ${assignment.student_name} - ${assignment.subject}</p>
          <p><strong>Time Elapsed:</strong> ${Math.round(hoursElapsed)} hours</p>
          <p><strong>Expected:</strong> Response within 24 hours</p>
          <p>Consider follow-up or reassignment if no response soon.</p>
        `
      }
    });
  }

  return new Response(JSON.stringify({ 
    alertsCreated: slowAssignments.length,
    assignments: slowAssignments.map(a => ({
      id: a.id,
      tutor: a.tutors.full_name,
      hoursElapsed: Math.round((Date.now() - new Date(a.created_at).getTime()) / (1000 * 60 * 60))
    }))
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
});
```

---

## Cron Job Configuration

**File:** `supabase/config.toml`

```toml
# ... existing config ...

[functions.process-tutor-payouts]
verify_jwt = false

[functions.monitor-tutor-response-times]
verify_jwt = false

# Add cron jobs
[[crons]]
name = "weekly-tutor-payouts"
schedule = "0 12 * * 1"  # Every Monday at 12:00 PM UTC
function_name = "process-tutor-payouts"

[[crons]]
name = "check-tutor-response-times"
schedule = "0 */6 * * *"  # Every 6 hours
function_name = "monitor-tutor-response-times"
```

---

## Next Steps

1. **Monitor esm.sh Status:** https://esm.sh/
2. **Once CDN Resolved:**
   - Execute database migration SQL
   - Deploy all edge functions
   - Test Stripe Connect onboarding
   - Verify payment split calculations
   - Run end-to-end payout test

3. **Manual Testing Checklist:**
   - ✓ Tutor sets hourly rate
   - ✓ Tutor accepts platform fee
   - ✓ Stripe Connect onboarding completes
   - ✓ Student books and pays
   - ✓ Payment splits correctly (90/10)
   - ✓ Weekly payout processes
   - ✓ Response time alerts trigger at 24 hours

---

*Last Updated: January 2025*  
*Status: BLOCKED - Awaiting esm.sh CDN Resolution*
