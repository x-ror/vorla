# Privacy Compliance Audit Report — X-ROR (x-ror.fun)

**Audit Date:** March 13, 2026
**Application:** Instagram content management and analysis SaaS
**Stack:** Ruby on Rails 8.1.2, PostgreSQL (production), SQLite3 (dev)
**Auditor:** Automated GDPR/CCPA Compliance Review

---

## Part 1 — Violations & Fixes

### **[CRITICAL]** — No Account Deletion Endpoint

- **Regulation:** GDPR Art. 17 (Right to Erasure), CCPA §1798.105
- **Problem:** The Privacy Policy promises users can delete their account and data, but **no route, controller action, or UI exists** for account deletion. Users have no self-service way to delete their account. The `config/routes.rb` has no `DELETE /profile` or account destruction route.
- **Risk:** Up to €20M or 4% of annual turnover (GDPR). CCPA fines of $2,500–$7,500 per violation. The policy promises a right that cannot be exercised — this is both a legal and trust violation.
- **Fix:** Add `DELETE /account` route, controller action, confirmation UI, and ensure cascading deletion of all user data (sessions, usage_logs, bookmarks, bookmark_items, passkey_credentials, Active Storage avatars). See implementation below.
- **Effort:** 1 day

### **[CRITICAL]** — No Data Export / Portability Mechanism

- **Regulation:** GDPR Art. 20 (Right to Data Portability), CCPA §1798.100
- **Problem:** Privacy Policy Section 7.2 promises "data portability: receive your data in a structured, machine-readable format" but **no endpoint, controller, or job exists** to export user data.
- **Risk:** Same as above — documented right with no implementation.
- **Fix:** Add `GET /account/export` endpoint that generates a JSON/ZIP export of all user data (profile, bookmarks, usage history, sessions).
- **Effort:** 1 day

### **[CRITICAL]** — No Cookie Consent Banner Implementation

- **Regulation:** GDPR Art. 6(1)(a), ePrivacy Directive Art. 5(3)
- **Problem:** Cookie Policy Section 3 states "you will be presented with a cookie consent banner" but **no banner, JavaScript, or consent management code exists**. The `cookie_consent` cookie referenced in the policy is never set. The `theme` cookie (1-year persistent, functional category) is set without consent.
- **Risk:** Fines from EU DPAs. Multiple EU authorities have fined companies specifically for missing cookie consent (e.g., CNIL fined Google €150M for cookie violations).
- **Fix:** Implement cookie consent banner component with granular opt-in for functional/analytics cookies. Only set non-essential cookies after consent.
- **Effort:** 1 day

### **[CRITICAL]** — Placeholder Contact Emails in Legal Pages

- **Regulation:** GDPR Art. 13(1)(a), Art. 14(1)(a) — controller identity and contact details required
- **Problem:** Privacy Policy, Cookie Policy, and Terms of Service contain `[PRIVACY_EMAIL]`, `[SUPPORT_EMAIL]`, `[COMPANY_LEGAL_NAME]`, and `[GOVERNING_JURISDICTION]` placeholder strings. Users literally cannot exercise their rights because there is no contact email.
- **Risk:** The privacy policy is legally defective. A DPA could consider this as having no valid privacy notice at all.
- **Fix:** Replace all placeholders with actual values immediately.
- **Effort:** 1 hour

### **[HIGH]** — Usage Logs Stored Indefinitely with PII

- **Regulation:** GDPR Art. 5(1)(e) (Storage Limitation), CCPA §1798.100(b)
- **Problem:** The `usage_logs` table stores IP addresses, user agents, session tokens, and search queries (`metadata` JSON field) **with no automated retention/deletion policy**. While the `recent` scope filters to 24 hours for rate limiting, the data itself is never purged. Privacy Policy Section 6 states data is kept "as long as necessary" but defines no specific retention periods for usage logs.
- **Risk:** Retaining PII indefinitely without purpose violates storage limitation. IP addresses + timestamps + search queries constitute personal data profiles.
- **Fix:** Add a scheduled rake task or cron job to delete/anonymize usage_logs older than 90 days. Add `anonymized_at` or implement IP hashing for historical records.
- **Effort:** 1 day

### **[HIGH]** — Session Data (IP + User Agent) Stored Indefinitely

- **Regulation:** GDPR Art. 5(1)(e) (Storage Limitation)
- **Problem:** The `sessions` table stores `ip_address` and `user_agent` for every login session. Old sessions from terminated/logged-out users remain in the database. While `dependent: :destroy` on the User model handles user deletion, individual sessions accumulate without cleanup.
- **Risk:** IP addresses are personal data under GDPR (Breyer v. Germany, CJEU C-582/14).
- **Fix:** Add automated cleanup of sessions older than 90 days. Consider hashing IPs after the session expires.
- **Effort:** 4 hours

### **[HIGH]** — No Data Breach Notification Procedure

- **Regulation:** GDPR Art. 33–34, CCPA §1798.150
- **Problem:** Neither the Privacy Policy nor any internal documentation describes a data breach notification procedure. GDPR requires notification to the supervisory authority within 72 hours and to affected users without undue delay.
- **Risk:** Failure to notify within 72 hours is itself a GDPR violation, separate from the breach.
- **Fix:** Add breach notification section to Privacy Policy. Implement internal incident response procedures.
- **Effort:** 4 hours

### **[HIGH]** — No Consent Recording for Data Collection

- **Regulation:** GDPR Art. 7(1) — demonstrable consent
- **Problem:** Registration collects email and password without recording explicit consent to the Privacy Policy or Terms of Service. There is no `accepted_terms_at`, `accepted_privacy_at`, or `consent_version` field on the users table. The registration form does not include a consent checkbox.
- **Risk:** Cannot demonstrate that users consented to data processing. Consent must be "freely given, specific, informed and unambiguous."
- **Fix:** Add consent checkbox to registration form. Store `terms_accepted_at` and `privacy_policy_version` on the users table.
- **Effort:** 4 hours

### **[HIGH]** — Query Parameters Logged in Usage Metadata

- **Regulation:** GDPR Art. 5(1)(c) (Data Minimization)
- **Problem:** `UsageTracking#track_usage!` stores `query` (the Instagram URL being downloaded) in the `metadata` JSON field. This creates a detailed behavioral profile of which Instagram content each user accesses, linked to their user ID and IP address.
- **Risk:** This data goes beyond what's necessary for rate limiting (which only needs a count). It constitutes behavioral tracking without explicit consent.
- **Fix:** Remove `query` from metadata storage. If analytics are needed, store anonymized/aggregated data separately with consent.
- **Effort:** 2 hours

### **[MEDIUM]** — No DPO (Data Protection Officer) Designated

- **Regulation:** GDPR Art. 37–39
- **Problem:** No DPO is mentioned in the Privacy Policy or identified anywhere. If the application processes personal data on a large scale (behavioral tracking of users), a DPO may be required.
- **Risk:** Regulatory non-compliance if DPO appointment is required based on processing scale.
- **Fix:** Evaluate whether a DPO is required. If so, appoint one and publish contact details.
- **Effort:** 1 week (organizational)

### **[MEDIUM]** — No Data Processing Agreement (DPA) References

- **Regulation:** GDPR Art. 28 (Processor obligations)
- **Problem:** The app uses Cloudinary (image storage), LiqPay (payments), and an SMTP provider (mail.adm.tools). While LiqPay is mentioned in the Privacy Policy, there is no mention of DPAs with these processors. Cloudinary is not mentioned at all in the Privacy Policy.
- **Risk:** Transferring data to processors without a DPA violates Art. 28.
- **Fix:** Ensure DPAs are signed with all processors. List Cloudinary in the Privacy Policy as a third-party processor.
- **Effort:** 1 day (legal)

### **[MEDIUM]** — Cloudinary Not Listed as Third-Party Processor

- **Regulation:** GDPR Art. 13(1)(e) — recipients of personal data
- **Problem:** User avatar images are stored on Cloudinary, but the Privacy Policy Section 4 does not list Cloudinary as a data processor. Avatar images are PII (biometric-adjacent data).
- **Risk:** Users are not informed about where their personal data (photos) are processed.
- **Fix:** Add Cloudinary to the "Data Sharing and Third-Party Services" section of the Privacy Policy.
- **Effort:** 1 hour

### **[MEDIUM]** — Session Cookie Set as Permanent Without Expiry

- **Regulation:** GDPR Art. 5(1)(e) (Storage Limitation), ePrivacy Directive
- **Problem:** In `Authentication#start_new_session_for`, the session cookie is set with `cookies.signed.permanent[:session_id]`. Rails `.permanent` sets cookies with a 20-year expiry. This is excessive for a session identifier.
- **Risk:** Permanent cookies without a reasonable expiry violate storage limitation and create unnecessary security risk.
- **Fix:** Replace `.permanent` with a reasonable expiry (e.g., 30 days): `cookies.signed[:session_id] = { value: session.id, expires: 30.days, httponly: true, same_site: :lax }`
- **Effort:** 1 hour

### **[MEDIUM]** — No Age Verification at Registration

- **Regulation:** GDPR Art. 8 (Children's consent), COPPA
- **Problem:** Terms of Service states minimum age is 16, Privacy Policy Section 8 states the service is not for children under 16, but registration (`RegistrationsController#create`) has no age verification or checkbox.
- **Risk:** Collecting data from minors without parental consent.
- **Fix:** Add a date-of-birth or age confirmation checkbox at registration.
- **Effort:** 2 hours

### **[MEDIUM]** — Content Security Policy Not Enforced

- **Regulation:** GDPR Art. 32 (Security of processing)
- **Problem:** `/home/user/vorla/config/initializers/content_security_policy.rb` exists but is entirely commented out. No CSP headers are sent.
- **Risk:** Increases XSS attack surface, which could lead to data exfiltration.
- **Fix:** Enable and configure the CSP.
- **Effort:** 4 hours

### **[LOW]** — Email Verification Disabled

- **Regulation:** GDPR Art. 5(1)(d) (Accuracy)
- **Problem:** Email verification is commented out in both `RegistrationsController` and `SessionsController`. Users can register with any email address without proving ownership.
- **Risk:** Inaccurate data, potential impersonation, and inability to contact users for breach notifications.
- **Fix:** Re-enable email verification flow.
- **Effort:** 2 hours

### **[LOW]** — No Specific Data Retention Periods Published

- **Regulation:** GDPR Art. 13(2)(a) — retention periods or criteria
- **Problem:** Privacy Policy Section 6 says data is retained "as long as necessary" with a 30-day deletion window after account deletion, but does not specify retention periods for specific data categories (usage logs, sessions, bookmarks).
- **Risk:** GDPR requires either specific periods or criteria for determining retention.
- **Fix:** Add a data retention schedule to the Privacy Policy (e.g., usage logs: 90 days, sessions: 90 days after last activity, account data: until deletion + 30 days).
- **Effort:** 2 hours

### **[LOW]** — CCPA "Do Not Sell" Link Missing from Footer/Navigation

- **Regulation:** CCPA §1798.135
- **Problem:** While the Privacy Policy states "We do not sell your personal information," CCPA requires a prominent "Do Not Sell My Personal Information" link. No such link exists in the footer or navigation.
- **Risk:** CCPA non-compliance for California users.
- **Fix:** Add a visible link in the footer, even if it just confirms the no-sale policy.
- **Effort:** 1 hour

---

## Part 2 — Compliance Checklist

### GDPR Checklist

- [x] Lawful basis for all data processing documented (Art. 6 — Privacy Policy Section 3)
- [x] Privacy Policy covers required GDPR elements (Art. 13–14 — Sections 1–11)
- [ ] **FAIL** — Users can request data export / portability (Art. 20 — NO ENDPOINT EXISTS)
- [ ] **FAIL** — Users can request account + data deletion / right to erasure (Art. 17 — NO ENDPOINT EXISTS)
- [x] Users can correct inaccurate data (Art. 16 — Profile edit page exists)
- [ ] **FAIL** — Consent recorded for non-essential cookies/tracking (Art. 6(1)(a) — NO COOKIE BANNER)
- [ ] **FAIL** — Data retention periods defined and enforced (Art. 5(1)(e) — NO AUTOMATED CLEANUP)
- [ ] **FAIL** — Consent recorded at registration with version tracking (Art. 7(1) — NO CONSENT FIELD)
- [ ] **FAIL** — Data breach notification procedure documented (Art. 33–34 — NOT MENTIONED)
- [x] Password stored securely / hashed (Art. 32 — bcrypt via `has_secure_password`)
- [x] HTTPS / TLS enforced in production (Art. 32 — `force_ssl = true`)
- [x] Sensitive params filtered from logs (Art. 32 — filter_parameter_logging.rb)
- [ ] **FAIL** — All third-party processors listed in Privacy Policy (Art. 13(1)(e) — Cloudinary missing)
- [x] International data transfer safeguards mentioned (Art. 46 — SCCs referenced)
- [ ] **FAIL** — DPO contact published if required (Art. 37 — Not evaluated)
- [x] Children's privacy addressed (Art. 8 — Section 8, minimum age 16)
- [ ] **FAIL** — Age verification at registration (Art. 8 — No checkbox/DOB field)
- [x] Right to lodge complaint with DPA mentioned (Art. 77 — Section 7.2)
- [ ] **FAIL** — Contact email for exercising rights is functional (Art. 12 — Placeholder `[PRIVACY_EMAIL]`)

### CCPA Checklist

- [x] Right to know documented (§1798.100 — Privacy Policy Section 7.3)
- [ ] **FAIL** — Right to delete implementable by user (§1798.105 — No deletion endpoint)
- [x] "We do not sell personal information" stated (§1798.120 — Section 7.3)
- [ ] **FAIL** — "Do Not Sell My Personal Information" link visible (§1798.135 — Not in footer)
- [x] Right to non-discrimination documented (§1798.125 — Section 7.3)
- [ ] **FAIL** — Data export available (§1798.100 — No export endpoint)
- [x] Categories of data collected disclosed (§1798.100 — Section 1)
- [x] Business purposes for collection disclosed (§1798.100 — Section 2)
- [x] Third-party sharing disclosed (§1798.115 — Section 4)
- [ ] **FAIL** — Verifiable consumer request process functional (§1798.130 — Placeholder email)

### Cookie / ePrivacy Checklist

- [ ] **FAIL** — Cookie consent banner displayed before non-essential cookies (ePrivacy Art. 5(3))
- [x] Cookie categories documented (Cookie Policy Sections 2.1–2.4)
- [x] Essential cookies identified and exempted from consent
- [ ] **FAIL** — Consent preference stored and respected (`cookie_consent` cookie never set)
- [ ] **FAIL** — Analytics cookies placeholder needs completion
- [x] How to manage cookies documented (Cookie Policy Section 4)

### Security Checklist (GDPR Art. 32)

- [x] Passwords hashed with bcrypt
- [x] HTTPS enforced in production
- [x] CSRF protection enabled (Rails default)
- [x] HttpOnly + SameSite cookies for session
- [x] Rate limiting on login (10 per 3 minutes)
- [x] Sensitive parameters filtered from logs
- [ ] **FAIL** — Content Security Policy not enforced (commented out)
- [x] WebAuthn / Passkey support for strong authentication
- [x] Session revocation capability (Active Sessions page)

---

## Summary

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | 4     | Must fix before launch |
| HIGH     | 5     | Fix within 2 weeks |
| MEDIUM   | 5     | Fix within 1 month |
| LOW      | 3     | Fix within 3 months |

**Overall Compliance Grade: FAILING** — The application has good foundational security and a well-written Privacy Policy, but the critical gap is that **documented user rights (deletion, export) have no working implementation**, and **cookie consent is promised but not implemented**. These must be resolved before the application can be considered GDPR/CCPA compliant.
