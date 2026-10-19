# SANGASO — PLAY CLOSED TESTING SUBMISSION PACK
Prepared 2026-10-19 for the owner. Copy/paste the text into the Play Console.
Everything here is derived from the actual app code — no invented claims.

## Release to upload
| Item | Value |
| --- | --- |
| File | `app\artifacts\app-release.aab` (uploaded to Play Console, not shared manually) |
| Version | 1.0.3 (versionCode 7) |
| SHA-256 (verify after download) | `2a4fa610aa9dd1ff0422b6583fae819b480f21c0cb11be400b84030cdfb6b2f5` |
| Package | com.sangaso.app |
| minSdk / targetSdk | 24 / 36 |
| Signing | upload key (Play App Signing then applies on distribution) |

---

## 1. Store listing

**App name (30 max):** `Sangaso`

**Short description (80 max):**
```
Book trusted local pros near you - plumbers, electricians, cleaners, tutors.
```

**Full description:**
```
Sangaso connects you with local service providers in your area - plumbers,
electricians, cleaners, carpenters, painters, tutors and more.

HOW IT WORKS
1. Create your free account with your email address.
2. Confirm your email so we know the account is yours.
3. Search for a service, compare providers by price, rating and area, and
   open the provider's service listing.
4. Request a booking with the date, time and the address where the work is
   needed.
5. Chat with the provider in the app, follow the job status, and rate the
   service when it is done.

FOR SERVICE PROVIDERS
- Create a provider account and complete your business profile: trading
  name, service category, starting price and description.
- Publish your services with photos and prices, and manage incoming
  booking requests, active jobs and completed job history in one place.
- Every booking gives you the customer's name, phone number and service
  address, plus a direct chat channel.

FOR CUSTOMERS
- Browse services by category and see prices before you book.
- Track every booking and its status: requested, accepted, in progress,
  completed, declined or cancelled.
- Rate the provider afterwards so the next customer benefits from real
  experience.
- Your contact details are only shared with the provider you booked, for
  the purpose of delivering that service.
```

**Category:** House & Home
**Contact email (shown on the listing):** `sangosazm@gmail.com`
**Support website:** `https://www.sangaso.com`
**Privacy policy URL:** `https://www.sangaso.com/?page=privacy`  ← must be live before you publish
**Data deletion URL (account deletion):** `https://www.sangaso.com/?page=delete-account` ← must be live

**Graphics needed** (Play will reject missing ones):
| Asset | Size | Source |
| --- | --- | --- |
| App icon | 512 × 512 PNG | `app\brand\logo-source.png` |
| Feature graphic | 1024 × 500 PNG | logo + wordmark on the brand background |
| Phone screenshots | min 2, 16:9 or 9:16, ≤ 8 MB each | capture from the device (see §5) |

---

## 2. Data safety form (answers that match the code)

**Does your app collect or share any of the required user data types? → Yes**

| Data type | Collected? | Purpose | Shared? | Optional? |
| --- | --- | --- | --- | --- |
| Name | Yes | App functionality (display name, provider trading name) | No | No (needed for bookings) |
| Email address | Yes | App functionality (sign-in, verification, reset) | No | No |
| Phone number | Yes | App functionality (booking contact details) | No | Yes |
| Physical address | Yes | App functionality (service address) | No | No |
| Photos and videos | Yes | App functionality (service listing images, optional profile photo) | No | Yes |
| User generated content | Yes | App functionality (booking notes, in-app chat, reviews) | No | Yes |
| App interactions | Yes | App functionality (bookings, services, ratings) | No | No |
| Device or other IDs | Yes | App functionality (push notification token only) | No | No |

**Not collected / declare No:** precise location, health and fitness, financial info, browsing history, web browsing, advertising ID, sensor data, photos for other purposes.

- **Is any of the collected data encrypted in transit?** Yes (Firebase/HTTPS).
- **Do you provide a way for users to request that their data is deleted?** Yes — in-app account deletion (Profile → Sign out → delete account; it re-authenticates, then removes the service listings, the profile document and the Firebase Auth account) and the website deletion page.
- **Is any data used for tracking or advertising?** No.
- Note: the app has **no** analytics or ads SDK, and requests only `INTERNET`, `CALL_PHONE`, `POST_NOTIFICATIONS` — no location permission, because the service area is typed in by the user.

---

## 3. Other app content declarations

| Section | Answer |
| --- | --- |
| Ads | "My app does not contain ads" |
| App access | "All functionality is available to all users without special access" (open email signup) |
| Content rating | Choose **18 and over only** — it keeps the questionnaire short. Answer honestly: the app is a service marketplace with a customer↔provider chat, no violence, no gambling, no user-shared media beyond service photos. |
| Target audience | 18 and over only (consistent with booking contracts between adults) |
| Government apps | No |
| Health apps | No |
| Financial features | No — no in-app payments, no wallet, no credit |
| News app | No |
| COVID-19 app | No |
| COVID-19 contact tracing | No |

**Honest caveats to be ready for:** the questionnaire asks whether users can interact with each other (yes — chat) and whether that content is moderated (the app has no in-app moderation tooling; reports are handled by email). Answer truthfully and use the support email as the moderation channel. Do not claim filtering you don't have.

---

## 4. Closed testing setup

- **Track:** Closed testing (default track) → *Testing* → *Manage track*
- **Testers:** create a Google Group (e.g. `sangaso-testers@googlegroups.com`), add every tester to it, then add that group as the only tester list. A group keeps the list manageable and gives you a single opt-in URL.
- **Opt-in URL:** copy it from the track page and send it to testers. They must open it in a browser while signed into the right Google account, click **Become a tester**, then accept the Play terms. Then they install from the Play Store.
- **Release:** upload `app-release.aab` (versionCode 7), set a release name like `Internal closed test 1.0.3`, add release notes, rollout **100%**, publish.
- **Release notes (honest, testers see this):**
```
First closed test of Sangaso.
- Search for services and see provider listings
- Request a booking with date, time and address
- Chat with your provider inside the app
- Track job status and rate the service afterwards
Providers: publish your services with photos and prices, and manage
requests, active jobs and history.
Known limits in this build: Google sign-in may ask you to try again
until we finish certificate setup; email and password sign-in always
works. Push notifications are not sent yet.
```

---

## 5. Before you publish — hard prerequisite

The privacy policy URL must resolve to a real privacy policy. Right now
`https://www.sangaso.com/?page=privacy` (and `?page=terms`,
`?page=delete-account`) still return the website landing page. Verify
after deploying the website's multi-page patch:

```powershell
(Invoke-WebRequest "https://www.sangaso.com/?page=privacy").Content.Length
```
The number must differ from the landing page length (170,622 bytes) and
the body must contain policy text, not the marketing homepage. Do not
publish a release that points at a non-policy page — that is a policy
violation, not just a cosmetic issue.

---

## 6. After publishing (do this next)

1. **Play Console → your app → App integrity → App signing key certificate** → copy the **SHA-1** of the Play App Signing key.
2. Give me that SHA-1. I add it to the Firebase app entry for
   `com.sangaso.app` (owner action in Firebase) and cut **1.0.3+8** so
   Google sign-in works in Play-installed builds. The current +7 artifact
   stays preserved.
3. Send the opt-in URL to testers and ask for feedback in a WhatsApp
   group (tester contacts are not collected by the app).
4. Keep the closed test running for the required window: Google requires
   **20 testers opted in continuously for 14 days** for a new personal
   developer account (12 testers for older accounts) before the app can
   apply for production. Confirm your account tier in Play Console →
   Settings → Developer account.
5. Only after the production application is approved do you promote from
   closed → open → production. Do not skip the open testing track.
