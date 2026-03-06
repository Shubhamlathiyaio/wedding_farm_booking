Perfect — this is a **two-phase split payment system**. Here's exactly what I'll build:

- **Phase 1:** Token payment (non-refundable, always in-app via Stripe) → locks the farm
- **Phase 2:** Final payment (on decided date, token auto-deducted from balance due)
- **History screen** for both customers & owners

Let me build the full implementation now.Now let me build the complete implementation across all files.Here's everything you need — 9 files, fully wired together. Here's a quick map of what was built:

---

## What's inside

### 3 Supabase Edge Functions
**`create-payment-intent`** — Called when customer taps "Pay Token". Verifies the booking belongs to them, checks no duplicate token exists, creates the Stripe PaymentIntent server-side, and saves a `pending` record to DB. Only the safe `client_secret` goes back to Flutter.

**`create-final-payment-intent`** — Same flow for final payment, but automatically fetches the already-paid token amount and calculates `remaining = total - token`. The customer can never manipulate this number.

**`stripe-webhook`** — The source of truth. Uses `STRIPE_WEBHOOK_SECRET` to verify every event is genuinely from Stripe, then updates `payments.status` and `bookings.status` atomically. Uses the service role key so RLS doesn't block it.

### Database (`schema.sql`)
- `payments` table with a `unique(booking_id, payment_type)` constraint — physically impossible to double-charge
- All amounts stored in **INR** (not paise), so your UI never needs conversion math
- RLS: customers see only their own rows, owners see only their farm's payments
- `payment_history` view joins farm name, booking date, and customer name for the history screen in one query

### Flutter (4 files)
- **`payment_service.dart`** — Single entry point for all payment logic. `payToken()` and `payFinal()` each call the right Edge Function, then hand the `client_secret` to Stripe's payment sheet. Returns a typed `PaymentResult` (success / failure / cancelled).
- **`token_payment_screen.dart`** — Shows farm image, breakdown (token now + remaining later), and the non-refundable warning. On success, opens a bottom sheet confirming the farm is locked.
- **`final_payment_screen.dart`** — Shows `Total - Token = Amount Due`, with UPI/Card/NetBanking chips. Token is deducted server-side, not in Flutter.
- **`payment_history_screen.dart`** — Tabbed view (My Payments / Received) grouped by booking, with a summary banner showing total paid/received.

### Key security rules enforced
- Stripe secret key **never touches Flutter** — lives only in Edge Function env vars
- Payment amounts **always calculated server-side** — client just passes `booking_id`
- Webhook signature **verified on every call** before any DB write



you have to merge the 
@beautifulMention 

in to owr currnt file. i don't know more about it see the code and chach in our strucre

