<!--
 Renewly-Overview.md
 Renewly

 Created by Md Mehedi Hasan Angkur on 2026-10-04.
 Copyright © 2026. All rights reserved.
-->

# Renewly: Product & Technical Overview

**Renewly** is a privacy-first iPhone and iPad app that tracks **subscriptions** and **product warranties** in one place, and reminds people *before* money is charged or warranty coverage runs out.

Everything stays on the device. There are no accounts, no servers, no analytics and no tracking.

| | |
|---|---|
| **Platform** | iPhone & iPad, iOS 17 or later |
| **Built with** | Swift 6, SwiftUI, SwiftData, WidgetKit, App Intents, StoreKit 2, Vision |
| **Business model** | Free app with an optional **Renewly Pro** subscription (monthly or yearly, with optional free trial) |
| **Data collection** | None. All data is stored only on the user's device |
| **Status** | Feature-complete for version 1.0. 202 automated tests passing |

---

## Contents

1. [The problem](#1-the-problem)
2. [Who it's for](#2-who-its-for)
3. [Feature tour](#3-feature-tour)
4. [Free vs. Pro](#4-free-vs-pro)
5. [Privacy & security](#5-privacy--security)
6. [Technical architecture](#6-technical-architecture)
7. [Quality & testing](#7-quality--testing)
8. [Release checklist](#8-release-checklist)
9. [Roadmap ideas](#9-roadmap-ideas)
10. [Glossary](#10-glossary)

---

## 1. The problem

People pay for more subscriptions than they remember, and they forget warranties exist until the day something breaks.

- **Forgotten renewals.** Streaming, cloud storage, apps and memberships renew silently, often yearly, which makes them easy to miss.
- **Free trials that turn into charges.** Sign-ups start "free", and the first charge arrives because nobody remembered to cancel.
- **Lost warranties.** Receipts fade or get lost, and people don't know whether a broken device is still covered.
- **Privacy concerns.** Many tracking apps ask for bank logins or email access. A lot of people are, reasonably, unwilling to share that.

**Renewly's answer:** a simple, beautiful tracker that people fill in themselves, quickly (helped by receipt scanning and a service catalog). It warns them at the right moments, and never sends their data anywhere.

## 2. Who it's for

- **Everyday subscribers** juggling 5–20 services who want to know what they pay each month and what renews next.
- **Trial hunters** who sign up for free trials and need a nudge before the first charge.
- **Gadget owners** who want warranty dates and receipts in one place when something breaks.
- **Privacy-conscious users** who won't connect bank accounts or email to a third-party service.
- **International users:** 155 world currencies are supported, including regional services (for example Chorki, Hoichoi, Bongo and Toffee in Bangladesh).

---

## 3. Feature tour

### 3.1 Home dashboard

The home screen answers three questions at a glance: *What does this cost me? What's protected? What's next?*

- **Overview card**
  - **Monthly burn:** the total monthly cost of all subscriptions. Yearly and quarterly plans are converted to a monthly equivalent.
  - **Protected:** the total value of products under an active warranty.
  - **Next renewal** and **Next warranty expiry**, each shown on its own row with how many days are left. Items due within 3 days are highlighted in orange.
- **Filters:** All, Subscriptions, Warranties and Expiring Soon (within 14 days), each with a live count.
- **Search** by name, store or serial number.
- **Item cards** show the price, the billing cycle, a countdown badge ("4d left", "Tomorrow", "Expired"), a **Trial** badge and an **Alerts** badge.
- **Interactions:**
  - Tap a card to edit it.
  - Swipe or long-press to view details or delete.
- **Automatic rollover:** when a subscription's renewal date passes, Renewly moves it forward to the next billing date, so the dashboard never shows stale information.

### 3.2 Adding & editing items

Each item is either a **Subscription** or a **Warranty**.

| Subscriptions | Warranties |
|---|---|
| Service name, price, currency | Product name, purchase price, currency |
| Renewal cycle: monthly, quarterly or yearly | Retailer and serial number |
| Start date and next renewal date | Purchase date and coverage end date |
| **Free trial** toggle (see 3.3) | Default suggestion: 1 year of coverage |
| Cancellation / manage link | |

Shared by both: receipt photo, reminders on or off, and validation (for example, the end date can't be before the start date).

Smart defaults:

- The next renewal date is **suggested automatically** from the start date and billing cycle.
- If a user enters a renewal date that has already passed, Renewly explains it and saves the **next upcoming** renewal instead.
- An already-expired warranty can still be saved for records, and reminders are switched off automatically.

### 3.3 Free-trial tracking

Toggle **Free trial** on a subscription, and the date field becomes **"Trial ends"**.

- Every user, free or Pro, gets a reminder **the day before the trial ends**: *"Free trial ends tomorrow. Cancel before then to avoid being charged."*
- Cards, the detail page and the dashboard say **"Trial ends in N days"**, with a pink gift icon.
- After the trial converts to paid, the item automatically becomes a regular subscription. There's nothing to clean up.

### 3.4 Popular services catalog

Adding a subscription is faster with a built-in catalog of **about 65 well-known services**, grouped into Streaming, Music, Cloud, Productivity, AI, Gaming, News, Fitness and Lifestyle.

- **"Choose a popular service"** opens a searchable list.
- **While typing a name**, up to three matching services are suggested. One tap fills in everything.
- **Picking a service** fills in the name and the typical billing cycle. Where a stable official page exists, it also fills in the **manage or cancel link**:
  - Apple-billed services link to Apple's subscription settings.
  - Microsoft, Google and YouTube link to their own account pages.
- Search understands nicknames and spelling variants: "disney plus" finds Disney+, "Office 365" finds Microsoft 365, "Gemini" finds Google AI Pro.
- **Prices are intentionally not pre-filled**, because they vary by country and change often. The user enters what they actually pay.

### 3.5 Receipt scanning (on-device OCR)

Users can attach a receipt or warranty card from the **camera** or the **photo library**. Renewly then reads it **entirely on the device**, using Apple's Vision framework, and fills in what it finds:

- Store or service name
- Total price and currency
- Purchase date and renewal or expiry date
- Billing cycle ("monthly", "per year"…)
- Warranty length ("2-year warranty") → coverage end date
- Serial number
- Whether it's a **free trial**
- Whether it looks like a subscription or a warranty

It only fills fields the user hasn't already filled in, and it tells them what was found ("Filled in name, price and renewal date").

### 3.6 Smart reminders (notifications)

- Reminders are delivered at **9:00 AM** local time, before each renewal or expiry.
- **Free plan:** the 7-day reminder, on up to 3 items.
- **Pro plan:** unlimited items. A 3-day reminder is always on, and 30-day, 7-day and 1-day reminders are optional.
- **Free trials** always get an extra **1-day** reminder, on both plans.
- Messages are specific: *"Netflix renews in 7 days."* / *"Your AirPods Pro warranty ends in 3 days."*
- Notifications show the Renewly icon, are grouped by item, and **tapping one opens that item's detail page**.
- **Catch-up:** if a reminder was missed (for example, the item was added too late), Renewly shows a single catch-up alert instead of nothing.
- Reminders are re-synced automatically whenever settings, plan or items change.

### 3.7 Item detail page

- A **time-left card** with a progress bar for the current billing period, warranty or trial.
- All details: price, monthly equivalent, dates, retailer, serial number and reminder schedule.
- The **receipt image**, full size.
- **Manage or cancel:** one tap opens the service's cancellation page.
- **Export as PDF (Pro):** a clean one-page document with the item details and receipt, ready to print or share (useful for warranty claims).

### 3.8 Spending insights (Pro)

- **Subscriptions cost you…** monthly, yearly and per-day totals.
- **Next 30 days:** upcoming renewals and the amount due.
- **12-month forecast:** a bar chart of projected spend per month, with the busiest month highlighted.
- **Where your money goes:** the biggest subscriptions ranked by monthly cost.
- **Warranty coverage:** how many warranties are active, ending within 90 days, or expired.
- Totals use the user's **main currency**. Items in other currencies are listed separately rather than converted with guessed exchange rates.

### 3.9 Home screen & lock screen widgets

| Widget | Shows |
|---|---|
| **Small** | The next item, with how long is left and the date |
| **Medium** | The next 3 items |
| **Large** | The next 6 items |
| **Lock screen: rectangular** | Next item and time left |
| **Lock screen: circular** | Days left until the next item |
| **Lock screen: inline** | "Netflix · 4d" above the clock |

- Color-coded: renewals in blue, warranties in green, trials in pink. Anything urgent turns orange.
- **Tapping** a widget item opens it in the app.
- The day counts update every midnight, even if the app isn't opened.
- Widgets never open the main database. The app shares a small, read-only summary with them through a secure App Group container on the device.

### 3.10 Siri & Shortcuts

| Say | Result |
|---|---|
| "**What's coming up** in Renewly" | Siri reads out what's due in the next 7 days: *"2 things in the next 7 days: Netflix renews tomorrow and AirPods Pro warranty expires in 3 days."* |
| "**How much do I spend** in Renewly" | *"You spend about $78.62 a month on 6 subscriptions."* |
| "**Add a subscription** in Renewly" / "Add a warranty…" | Opens the new-item form, set to the right type |
| "**Open Netflix** in Renewly" | Opens that item's detail page |

In the **Shortcuts app**, the same actions can be combined into automations. For example: "Every Monday morning, tell me what's renewing this week."

### 3.11 Backup & restore

- **Export** everything, including receipt images, as a single `.json` backup file. It can be saved to Files, iCloud Drive, AirDrop, email and so on.
- **Restore** from a backup file on a new phone or after reinstalling.
- Restoring **only adds items that aren't already present**. It never overwrites or deletes existing data.
- Invalid entries are skipped and reported, and a failed restore is rolled back completely.
- Backup is **free for everyone**. People's data belongs to them.

### 3.12 Settings

- **Appearance:** System, Light or Dark theme.
- **Main currency:** chosen from 155 currencies, searchable by name, code, symbol or **country**.
- **Notifications:** turn reminders on or off and pick reminder times (Pro).
- **Backup & restore.**
- **Purchases:** Pro status, upgrade, restore purchases.
- **Help & privacy:**
  - Privacy policy: [applab.world/privacy.html](https://www.applab.world/privacy.html).
  - **Contact support:** opens an email to `support.applab.world@gmail.com`, pre-filled with app version, iOS version, device model and plan, to speed up support. Nothing is sent automatically.

### 3.13 Design & accessibility

- A modern "glass" visual style with smooth animations and light haptic feedback.
- Full **Dark Mode** support.
- **Dynamic Type:** text scales with the user's preferred size.
- **VoiceOver** labels on cards, badges, charts and controls.
- iPhone and iPad layouts, portrait and landscape.

---

## 4. Free vs. Pro

| Feature | Free | Pro |
|---|:---:|:---:|
| Track unlimited subscriptions & warranties | ✅ | ✅ |
| Receipt photos & on-device scanning | ✅ | ✅ |
| Free-trial tracking + day-before reminder | ✅ | ✅ |
| Popular services catalog | ✅ | ✅ |
| Search, filters, themes, 155 currencies | ✅ | ✅ |
| Widgets, Siri & Shortcuts | ✅ | ✅ |
| Backup & restore | ✅ | ✅ |
| Reminders | 7-day reminder, up to 3 items | Unlimited items |
| Extra reminder times (30, 3 and 1 day) | — | ✅ |
| Spending insights & 12-month forecast | — | ✅ |
| PDF export of items with receipts | — | ✅ |

**Pricing:** Pro is sold as an auto-renewing subscription through the App Store, in two plans, **monthly** and **yearly**. The yearly plan shows its saving compared with monthly. A free trial can be offered through App Store Connect, and the paywall adapts automatically.

Product IDs:

- `com.applab.Renewly.pro.monthly`
- `com.applab.Renewly.pro.yearly`

Prices are set in App Store Connect and shown in the user's local currency. Purchases, restores and refunds are handled by Apple through StoreKit 2.

**Philosophy:** the free version is genuinely useful, with no item limits and no ads. Pro is for people who want more reminders and deeper insight.

---

## 5. Privacy & security

Privacy is the core of the product, not an add-on.

- **No account, no sign-in, no server.** Renewly has no backend.
- **No analytics, no tracking, no ads, no third-party SDKs.**
- **All data stays on the device:**
  - Items are stored in Apple's SwiftData database.
  - Receipt images are stored in the app's private storage, with iOS file protection.
- **On-device intelligence:** receipt scanning (Vision) and Siri answers run entirely on the phone.
- **Widgets** read a minimal summary (item name, type and date only) from a private App Group shared only between Renewly and its own widget.
- **Backups** are files the user creates and controls. Renewly never uploads them.
- **App Store privacy label:** "Data Not Collected".
- **Apple privacy manifest** included: no tracking domains, no collected data types, and only the standard declared API usage.

---

## 6. Technical architecture

### 6.1 Stack

| Layer | Technology |
|---|---|
| Language | Swift 6 with strict concurrency checking |
| UI | SwiftUI, Observation (`@Observable`), NavigationStack |
| Persistence | SwiftData with a versioned schema and migration plan |
| Notifications | UserNotifications (with icon attachments and tap routing) |
| Purchases | StoreKit 2 |
| OCR | Vision (`VNRecognizeTextRequest`) |
| Widgets | WidgetKit extension + App Group |
| Voice | App Intents + App Shortcuts |
| PDF | UIKit PDF rendering |
| Tests | Swift Testing (`@Test`, `#expect`) |

There are no third-party dependencies.

### 6.2 Structure

The app follows **MVVM** with a protocol-based service layer and dependency injection:

```
Renewly/                 Main app target
├── App/                 App entry, root navigation, dependencies, widget sync
├── Features/            One folder per screen (View + ViewModel)
│   ├── Dashboard/       Home, item cards, detail page, time-left card
│   ├── ItemEditor/      Add/edit form, receipt picker, services picker
│   ├── Insights/        Pro spending insights & charts
│   ├── Settings/        Settings, backup, support email, themes
│   ├── Paywall/         Pro purchase screen
│   ├── CurrencyPicker/  155-currency searchable picker
│   ├── Intents/         Siri & Shortcuts (App Intents)
│   └── Developer/       Debug-only tools & demo data
├── Models/              Data model, schema versions, parsing & formatting logic
├── Services/            Notifications, purchases, storage, backup, OCR, catalog, widgets
└── DesignSystem/        Theme, typography, glass cards, badges, haptics
RenewlyShared/           Code shared by the app and the widget
RenewlyWidget/           Widget extension (home + lock screen)
RenewlyTests/            Automated tests
```

### 6.3 Key design decisions

- **Views stay simple.** Business logic lives in view models and services, which makes it testable without UI.
- **Protocols for every external system.** Notifications, purchases, storage, OCR, PDF export and widgets all sit behind protocols, so tests use fast in-memory fakes.
- **Concurrency safety:**
  - UI code runs on the main actor.
  - Heavy work (OCR, PDF rendering, backup encoding) runs in the background.
  - Data crossing threads is immutable and `Sendable`, so the Swift 6 compiler checks for data races.
- **Snapshots:** database objects are converted to small immutable `ItemSnapshot` values before being passed to reminder, insight, widget and Siri logic.
- **Versioned database:** the schema is versioned (V1 → V2 added free trials) with a migration plan, so app updates never lose user data. Migration from every earlier format is covered by tests.
- **One navigation inbox:** notification taps, widget taps and Siri requests all go through a single router, so "open this item" behaves the same no matter where it comes from, even when the app was not running.
- **Fail safe:** if the database can't open, the app starts with temporary storage, tells the user, and leaves their data untouched for a fixed update to recover.

### 6.4 Data model (summary)

**TrackedItem** has the following fields:

- `id`, `title`, `category` (subscription or warranty)
- `cost`, `currencyCode`
- `startDate`, `expirationDate`, `billingCycle`
- `trialEndDate`, which is set only for free trials
- `serialNumber`, `retailer`, `cancellationURL`
- `receiptImagePath`, `isNotificationEnabled`, `createdAt`

---

## 7. Quality & testing

- **202 automated tests** covering:
  - Reminder scheduling rules for the free and Pro plans, including catch-up alerts and free trials.
  - Receipt text parsing across many receipt formats, currencies and date styles.
  - Renewal rollover, including month-end dates (Jan 31 → Feb 28 → Mar 31).
  - Spending insights, forecasts and multi-currency handling.
  - Backup round trips, invalid files, duplicate handling and rollback.
  - Database migrations from earlier versions.
  - Widget snapshots, deep links and refresh behaviour.
  - Siri answers and wording.
  - The services catalog and search ranking.
  - The currency catalog and search.
  - Editor validation and edge cases.
- Builds with **zero compiler warnings** under Swift 6 strict concurrency.
- **Debug-only developer tools** include:
  - Demo data sets: starter, expiring soon, expired, mixed currencies, and a bulk set for testing long lists.
  - A Pro override.
  - A count of queued reminders.
- SwiftUI **previews** for empty, populated and error states.

---

## 8. Release checklist

Already done in the app:

- [x] Privacy manifest (`PrivacyInfo.xcprivacy`)
- [x] Export-compliance flag (no non-exempt encryption)
- [x] Privacy policy link in Settings and on the paywall
- [x] Required subscription disclosure text on the paywall
- [x] Versioned database with migrations
- [x] App icon, launch screen and notification icon

Remaining before submission, in App Store Connect and on the developer account:

- [ ] Confirm the bundle identifier (`com.beleiveinAllahRenewly.Renewly`). It **can't be changed after the first release**.
- [ ] Create the two Pro subscription products with the product IDs above, plus prices and an optional free trial.
- [ ] Register the App Group `group.com.beleiveinAllahRenewly.Renewly` for the app and widget. Xcode usually does this automatically on the first device build.
- [ ] Answer the App Privacy questionnaire: **Data Not Collected**.
- [ ] Add a support URL and marketing text, and write the description and keywords.
- [ ] Create App Store screenshots. The built-in demo data makes clean screenshots easy.
- [ ] Run a TestFlight pass on real devices:
  - notifications and taps,
  - widgets,
  - Siri,
  - backup and restore through Files,
  - sandbox purchases and restore.

---

## 9. Roadmap ideas

Possible next steps, ordered by expected value:

1. **Face ID / passcode lock:** an optional app lock, which fits the privacy promise.
2. **Localization:** Bangla first, then Hindi, Spanish and other major languages.
3. **iCloud sync (Pro option):** keep iPhone and iPad in sync through the user's own private iCloud. It's opt-in, and no Renewly servers are involved.
4. **Price-change history:** record when a subscription gets more expensive.
5. **Apple Watch complication:** the next renewal on the wrist.
6. **Interactive widgets:** mark a trial as cancelled right from the widget.
7. **Shared / family items:** split a subscription's cost between people.
8. **UI test suite & accessibility audit:** automated end-to-end tests of the main flows.

---

## 10. Glossary

| Term | Meaning |
|---|---|
| **Monthly burn** | What all subscriptions cost per month, with yearly and quarterly plans converted to a monthly amount |
| **Protected** | The total purchase value of products whose warranty is still active |
| **Rollover** | Moving a subscription's renewal date forward automatically after it passes |
| **Catch-up reminder** | A single alert shown when a scheduled reminder could no longer be delivered on time |
| **App Group** | A private, on-device storage area shared only between Renewly and its widget |
| **OCR** | Optical character recognition: reading text from a photo, done on the device |
| **App Intents** | Apple's system for exposing app actions to Siri, Shortcuts and Spotlight |

---

*Renewly: know what renews, before it does.*
