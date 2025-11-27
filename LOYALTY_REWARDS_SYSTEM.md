# Loyalty Rewards System Documentation

**Status:** ✅ ACTIVE  
**Effective Date:** October 2025  
**Replaces:** Free Trial System (Deprecated)

---

## Overview

The Loyalty Rewards System incentivizes continued engagement by rewarding parents for ongoing tutoring sessions. This system replaced the free trial program to simplify the booking process and reward long-term commitment.

---

## How It Works

### 1. Automatic Tracking
- **Database:** `loyalty_milestones` table
- **Trigger:** Automatically updates when sessions are marked "completed"
- **Key:** Unique per `parent_email` + `student_name` combination

### 2. Milestone Rewards

#### Every 10th Session
- **Reward:** $20 credit
- **Application:** Can be applied to any future session
- **Notification:** Automatic notification sent to parent
- **Credits:** Tracked in `credits_remaining` column

#### 25+ Sessions (Platinum Status)
- **Unlock:** Platinum Parent badge
- **Benefits:**
  - Priority tutor matching
  - Early access to new features
  - Exclusive offers
- **Notification:** Platinum achievement notification sent
- **Status:** Permanent once earned

### 3. Credit Management
- **Earning:** Automatic upon milestone completion
- **Balance:** Visible in Parent Portal
- **Usage:** Parents can apply credits at checkout
- **Tracking:** `credits_remaining` decreases when used

---

## Database Schema

```sql
CREATE TABLE loyalty_milestones (
  id UUID PRIMARY KEY,
  parent_email TEXT NOT NULL,
  student_name TEXT NOT NULL,
  total_sessions INTEGER DEFAULT 0,
  milestone_10_claimed BOOLEAN DEFAULT false,
  milestone_25_claimed BOOLEAN DEFAULT false,
  platinum_status BOOLEAN DEFAULT false,
  platinum_status_earned_at TIMESTAMP,
  total_credits_earned NUMERIC DEFAULT 0,
  credits_remaining NUMERIC DEFAULT 0,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  UNIQUE(parent_email, student_name)
);
```

---

## Trigger Logic

**Function:** `update_loyalty_milestones()`

**Fires:** After UPDATE on `sessions` table when status changes to 'completed'

**Process:**
1. Extract parent_email and student_name from student_profiles
2. Increment total_sessions counter
3. Check for 10-session milestones (10, 20, 30, etc.)
   - Add $20 to credits_remaining
   - Send notification
4. Check for 25-session milestone
   - Set platinum_status = true
   - Send platinum achievement notification

---

## User Experience

### Parent Portal Display

**Component:** `LoyaltyRewards.tsx`

**Features:**
- Total sessions completed
- Available credits balance
- Progress bar to next reward
- Platinum status badge (if earned)
- Lifetime earnings summary

**Location:** Displayed prominently in Parent Dashboard overview tab

### Notifications

**Every 10th Session:**
- Title: "Loyalty Reward Earned! 🎉"
- Message: "Congratulations! You've completed X sessions and earned $20 in credits!"
- Type: `loyalty_milestone`

**Platinum Status:**
- Title: "Platinum Status Achieved! 👑"
- Message: "You've earned Platinum Parent status with priority tutor matching!"
- Type: `loyalty_platinum`

---

## Business Logic

### Why This System?

**Replaced:** Free trial system  
**Reasons:**
1. **Simplicity:** One booking flow vs. trial + paid
2. **No Confusion:** No eligibility checks or trial abuse prevention needed
3. **Better Incentives:** Rewards loyalty rather than just first-time bookings
4. **Cleaner Data:** Removes trial_status, is_trial flags from active workflows

### Advantages Over Trials

| Aspect | Free Trial | Loyalty Rewards |
|--------|-----------|-----------------|
| Complexity | High (eligibility, tracking, abuse prevention) | Low (automatic milestone tracking) |
| User Confusion | "Am I eligible?" | "How many until next reward?" |
| Business Risk | Trial abuse, non-conversion | Encourages continued use |
| Admin Work | Manual trial verification | Fully automated |
| Value Prop | "Try before buy" | "Stay and earn" |

---

## Marketing Messaging

### Homepage
"Earn rewards while your child learns! Every 10 sessions = $20 credit. 25+ sessions = Platinum status with priority matching."

### Booking Page
"Start earning rewards today! Your first session begins your journey to Platinum status."

### Parent Portal
"Keep learning, keep earning! You're X sessions away from your next $20 credit."

---

## Admin Features

### Monitoring
**Location:** `/admin` dashboard

**Metrics to Track:**
- Total loyalty milestones awarded
- Average sessions per family
- Platinum status holders
- Credits issued vs. redeemed

### Manual Adjustments
**Use Cases:**
- Goodwill credits
- Dispute resolution
- Special promotions

**How To:**
```sql
UPDATE loyalty_milestones
SET credits_remaining = credits_remaining + amount
WHERE parent_email = 'parent@example.com';
```

---

## Technical Implementation

### Frontend Components
- `src/components/LoyaltyRewards.tsx` - Main display
- `src/components/EnhancedParentPortal.tsx` - Integration

### Backend Logic
- **Database Function:** `update_loyalty_milestones()`
- **Trigger:** `trigger_update_loyalty_milestones`
- **Table:** `loyalty_milestones`

### No Edge Functions Required
All logic handled by PostgreSQL triggers - no additional edge functions needed.

---

## Migration from Trial System

### Historical Data
**Preserved:** All trial-related columns remain in database for historical records
**Marked:** Columns have COMMENT indicating "DEPRECATED"
**Not Used:** New bookings ignore trial fields

### Affected Tables
- `student_profiles.trial_status` → DEPRECATED
- `student_profiles.trial_consumed_at` → DEPRECATED
- `bookings.is_trial` → DEPRECATED
- `sessions.is_trial` → DEPRECATED

### Deleted Code
- `/trial` route removed
- `TrialBookingForm.tsx` removed
- All trial-specific UI components removed
- Edge functions: `enhanced-trial-booking`, `complete-trial-session` removed

---

## Future Enhancements

### Potential Additions
1. **Referral Bonuses:** Extra credits for successful referrals
2. **Seasonal Promotions:** 2x credits during holiday season
3. **Milestone Tiers:** Gold (50 sessions), Diamond (100 sessions)
4. **Family Plans:** Shared credit pool across siblings
5. **Annual Rewards:** Year-end bonus for consistent users

### Analytics to Track
- Credit redemption rate
- Average sessions before first redemption
- Platinum retention rate
- Credit expiry (if implemented)

---

## Support & Troubleshooting

### Common Issues

**Q: Parent doesn't see their credits**
A: Check loyalty_milestones table for parent_email match. Verify session was marked "completed".

**Q: Credits not applied at checkout**
A: Ensure payment system reads credits_remaining field and deducts from total.

**Q: Duplicate milestones**
A: Unique constraint on (parent_email, student_name) prevents duplicates. Check for email variations.

### Admin Tools
- View loyalty data: `SELECT * FROM loyalty_milestones ORDER BY total_sessions DESC;`
- Check for issues: Run health check on loyalty trigger
- Manual credit: Use UPDATE query with admin logging

---

## Conclusion

The Loyalty Rewards System provides a simple, automated way to incentivize continued engagement while removing the complexity of trial eligibility tracking. Parents earn tangible rewards for commitment, and the platform benefits from increased retention and lifetime value.

**Key Metric:** Track "sessions per family" before and after loyalty system implementation to measure effectiveness.
