-- =====================================================
-- PHASE 2: PRICING & PAYOUT SYSTEM - DATABASE MIGRATION
-- =====================================================
-- This migration adds support for:
-- - Tutor-set hourly rates
-- - Platform fee (90/10 split)
-- - Stripe Connect integration
-- - Weekly payout processing
-- - Response time tracking
-- =====================================================

-- ==============================
-- 1. ENHANCE TUTORS TABLE
-- ==============================

-- Add pricing and payout columns
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

-- Add column comments for documentation
COMMENT ON COLUMN tutors.hourly_rate IS 'Tutor-set hourly rate in dollars (typically $20-$100)';
COMMENT ON COLUMN tutors.platform_fee_accepted IS 'Whether tutor accepted 90/10 split terms';
COMMENT ON COLUMN tutors.stripe_connect_account_id IS 'Stripe Express Connect account ID for payouts';
COMMENT ON COLUMN tutors.average_response_time_hours IS 'Average time to propose times after assignment (hours)';

-- ==============================
-- 2. CREATE PAYMENTS TABLE
-- ==============================

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
CREATE INDEX IF NOT EXISTS idx_payments_session ON payments(session_id);
CREATE INDEX IF NOT EXISTS idx_payments_tutor ON payments(tutor_profile_id);
CREATE INDEX IF NOT EXISTS idx_payments_stripe_intent ON payments(stripe_payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_paid_at ON payments(paid_at);

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

-- ==============================
-- 3. CREATE TUTOR PAYOUTS TABLE
-- ==============================

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
CREATE INDEX IF NOT EXISTS idx_payouts_tutor ON tutor_payouts(tutor_profile_id);
CREATE INDEX IF NOT EXISTS idx_payouts_period ON tutor_payouts(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON tutor_payouts(status);
CREATE INDEX IF NOT EXISTS idx_payouts_processed ON tutor_payouts(processed_at);

-- Enable RLS
ALTER TABLE tutor_payouts ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Admins can manage payouts"
ON tutor_payouts FOR ALL
USING (get_current_user_role() IN ('owner', 'admin'));

CREATE POLICY "Tutors can view own payouts"
ON tutor_payouts FOR SELECT
USING (tutor_id = auth.uid());

COMMENT ON TABLE tutor_payouts IS 'Weekly payout batches to tutors (90% of earnings)';

-- ==============================
-- 4. RESPONSE TIME TRACKING
-- ==============================

-- Add response time tracking to assignments
ALTER TABLE assignments
ADD COLUMN IF NOT EXISTS time_proposal_created_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS response_time_hours DECIMAL(5,2);

COMMENT ON COLUMN assignments.time_proposal_created_at IS 'When tutor first proposed times';
COMMENT ON COLUMN assignments.response_time_hours IS 'Hours taken to propose times after assignment';

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
DROP TRIGGER IF EXISTS update_response_time ON assignments;
CREATE TRIGGER update_response_time
BEFORE UPDATE ON assignments
FOR EACH ROW
EXECUTE FUNCTION calculate_response_time();

-- ==============================
-- 5. STUDENT PROFILES ENHANCEMENTS
-- ==============================

-- Ensure trial tracking columns exist
ALTER TABLE student_profiles
ADD COLUMN IF NOT EXISTS trial_consumed_at TIMESTAMPTZ;

COMMENT ON COLUMN student_profiles.trial_consumed_at IS 'When student consumed their one free trial';

-- ==============================
-- 6. REFERRALS TABLE ENHANCEMENTS
-- ==============================

-- Ensure referral tracking has all necessary columns
ALTER TABLE referrals
ADD COLUMN IF NOT EXISTS three_month_milestone_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS auto_verified BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN referrals.three_month_milestone_date IS 'Date when referred student reached 1 month (4+ sessions)';
COMMENT ON COLUMN referrals.auto_verified IS 'Whether verification was automatic via system';

-- ==============================
-- 7. CREATE HELPER FUNCTIONS
-- ==============================

-- Function to check if student is eligible for free trial
CREATE OR REPLACE FUNCTION is_trial_eligible(parent_email_param TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  is_referred BOOLEAN;
  has_consumed_trial BOOLEAN;
BEGIN
  -- Check if student was referred
  SELECT EXISTS (
    SELECT 1 FROM referrals 
    WHERE referred_parent_email = parent_email_param
    AND status IN ('pending', 'verified', 'reward_issued')
  ) INTO is_referred;
  
  -- If referred, no trial eligibility
  IF is_referred THEN
    RETURN FALSE;
  END IF;
  
  -- Check if trial already consumed
  SELECT EXISTS (
    SELECT 1 FROM student_profiles
    WHERE parent_email = parent_email_param
    AND trial_consumed_at IS NOT NULL
  ) INTO has_consumed_trial;
  
  -- Eligible if trial not consumed
  RETURN NOT has_consumed_trial;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION is_trial_eligible IS 'Check if parent email is eligible for free trial (not referred, trial not consumed)';

-- Function to get tutor readiness status
CREATE OR REPLACE FUNCTION get_tutor_readiness(tutor_profile_id_param UUID)
RETURNS TABLE(
  is_ready BOOLEAN,
  missing_items TEXT[]
) AS $$
DECLARE
  tutor_record RECORD;
  missing ARRAY_TEXT := ARRAY[]::TEXT[];
BEGIN
  SELECT * INTO tutor_record
  FROM tutors
  WHERE id = tutor_profile_id_param;
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, ARRAY['tutor_not_found']::TEXT[];
    RETURN;
  END IF;
  
  -- Check hourly rate
  IF tutor_record.hourly_rate IS NULL THEN
    missing := array_append(missing, 'hourly_rate_not_set');
  END IF;
  
  -- Check platform fee acceptance
  IF tutor_record.platform_fee_accepted IS NOT TRUE THEN
    missing := array_append(missing, 'platform_fee_not_accepted');
  END IF;
  
  -- Check Stripe Connect
  IF tutor_record.stripe_connect_account_id IS NULL THEN
    missing := array_append(missing, 'stripe_not_connected');
  END IF;
  
  -- Return results
  RETURN QUERY SELECT 
    (array_length(missing, 1) IS NULL OR array_length(missing, 1) = 0),
    missing;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_tutor_readiness IS 'Check if tutor is ready to receive assignments (rate, fee, Stripe)';

-- ==============================
-- 8. UPDATE EXISTING DATA (OPTIONAL)
-- ==============================

-- Set default values for existing tutors
UPDATE tutors
SET 
  payout_schedule = 'weekly',
  platform_fee_accepted = FALSE
WHERE payout_schedule IS NULL OR platform_fee_accepted IS NULL;

-- ==============================
-- 9. VALIDATION & VERIFICATION
-- ==============================

-- Verify tables exist
DO $$
BEGIN
  ASSERT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payments'), 
    'payments table not created';
  ASSERT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tutor_payouts'), 
    'tutor_payouts table not created';
  
  -- Verify columns exist
  ASSERT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tutors' AND column_name = 'hourly_rate'), 
    'hourly_rate column not added to tutors';
  ASSERT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tutors' AND column_name = 'platform_fee_accepted'), 
    'platform_fee_accepted column not added to tutors';
  ASSERT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tutors' AND column_name = 'stripe_connect_account_id'), 
    'stripe_connect_account_id column not added to tutors';
  
  RAISE NOTICE '✅ All Phase 2 database migrations completed successfully';
END $$;

-- ==============================
-- MIGRATION COMPLETE
-- ==============================

-- Log migration execution
INSERT INTO system_health_metrics (metric_name, metric_value, details, created_at)
VALUES (
  'database_migration_phase2',
  1,
  jsonb_build_object(
    'migration_name', 'Phase 2: Pricing & Payout System',
    'tables_created', ARRAY['payments', 'tutor_payouts'],
    'columns_added', ARRAY['hourly_rate', 'platform_fee_accepted', 'stripe_connect_account_id', 'response_time_hours'],
    'functions_created', ARRAY['calculate_response_time', 'is_trial_eligible', 'get_tutor_readiness']
  ),
  NOW()
);
