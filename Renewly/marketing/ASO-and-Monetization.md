<!--
 ASO-and-Monetization.md
 Renewly

 Created by Md Mehedi Hasan Angkur on 2026-10-04.
 Copyright © 2026. All rights reserved.
-->

# Renewly: App Store Launch, ASO & Monetization Playbook

Everything needed to list Renewly on the App Store and turn it into a paying product: the listing copy, screenshots, subscription setup, pricing, privacy answers and the post-launch routine.

| What | Where |
| --- | --- |
| Store listing text for 13 locales (name, subtitle, keywords, promo text, description, URLs) | `fastlane/metadata/<locale>/` |
| Category and copyright | `fastlane/metadata/*.txt` |
| Framed App Store screenshots (iPhone 6.9", iPad 13") | `fastlane/screenshots/<locale>/` |
| Subscription promo image, review screenshot, social banner | `marketing/promo/` |
| App Store app preview and social video per language | `marketing/video/<locale>/` |
| Screenshot tooling (capture + compose) | `marketing/tools/` |

The folders follow the `fastlane deliver` layout, so you can paste the text into App Store Connect by hand or upload everything with `fastlane deliver`.

---

## 1. Name, subtitle and keywords

**Name:** `Renewly: Subscription Tracker`
**Subtitle:** `Free Trial & Warranty Reminder`

Why this works:

- Apple's search ranking gives the **name** the most weight, then the **subtitle**, then the **keyword field**. "Subscription tracker", "free trial", "reminder" and "warranty" are the high-intent searches people make when they want exactly this app.
- "Renewly" alone tells a searcher nothing, so the name carries the main keyword after the brand.
- A word only needs to appear **once** across name, subtitle and keywords. Repeating it wastes characters, so the keyword field holds only *new* words (`manager`, `bills`, `budget`, `cancel`, `receipt`…). Apple combines words across fields, so "subscription manager", "cancel subscriptions" and "bill tracker" are all covered.
- No competitor or brand names in keywords (Netflix, Spotify…). Apple rejects listings for that.

### Localized names

| Locale | Name | Subtitle |
| --- | --- | --- |
| en-US, en-GB, en-AU, en-CA | Renewly: Subscription Tracker | Free Trial & Warranty Reminder |
| de-DE | Renewly: Abo-Manager | Probeabos & Garantien im Blick |
| fr-FR, fr-CA | Renewly : Gestion abonnements | Essais gratuits et garanties |
| es-ES, es-MX | Renewly: Control suscripciones | Pruebas gratis y garantías |
| pt-BR | Renewly: Gestor de Assinaturas | Teste grátis e garantia em dia |
| ja | Renewly - サブスク管理 | 解約忘れ防止・保証書もまとめて管理 |
| zh-Hans | Renewly - 订阅管理与提醒 | 免费试用到期提醒，保修不丢失 |
| bn-BD | Renewly: সাবস্ক্রিপশন হিসাব | ফ্রি ট্রায়াল, ওয়ারেন্টি, বিল |

Every field was checked against Apple's limits (name 30, subtitle 30, keywords 100, promotional text 170, description 4000). Bengali vowel signs count as separate characters, which is why the Bangla name is shorter than a literal translation.

### Hidden keyword reach: one storefront reads several languages

Each storefront indexes its primary language **plus** extra ones. Renewly's keyword fields are written to complement each other rather than repeat:

| Storefront | Locales Apple indexes | What that means for us |
| --- | --- | --- |
| United States | en-US + es-MX, zh-Hans, fr-FR, pt-BR (and others) | The es-MX keywords also rank in the US, so they target Spanish-speaking Americans |
| United Kingdom | en-GB | UK spelling and terms: *direct debit*, *outgoings*, *guarantee* |
| Germany, France, Brazil, Mexico… | Local language + en-GB | English speakers abroad hit the en-GB keywords |
| Australia | en-AU + en-GB | en-AU uses a *different* keyword set (planner, recurring, invoice…) to double coverage |
| Canada | en-CA + fr-CA | French-Canadian keywords cover Québec |
| Japan | ja + en-US | |
| India | en-GB + Hindi + **Bangla (bn-BD)** + other Indian languages | The Bangla listing reaches Bengali speakers in India |

**Correction to earlier advice:** Bangladesh is not an App Store storefront, so the Bangla listing does not reach Bangladesh directly. It reaches Bengali speakers in India (West Bengal and others) and anyone browsing in Bangla. The Bangla screenshots therefore show Indian rupees.

---

## 2. Promotional text and description

- **Promotional text** (170 characters) sits above the description and can be changed **any time without a new app version**. Use it for seasonal hooks:
  - January: "New year, fewer subscriptions. See what you really pay each month."
  - Black Friday / Prime Day: "Bought it in the sale? Save the receipt and warranty in seconds."
  - Back to school: "Track student discounts before they turn into full-price plans."
- **Description** isn't indexed for search on iOS, but it *converts*. The first three lines show before "more", so they open with the pain point ("Forgot to cancel a free trial again?").
- Every description ends with the **auto-renewal terms**, **Terms of Use** (Apple's standard EULA) and **Privacy Policy** links. App Review requires these for auto-renewable subscriptions, and the paywall shows the same links.

---

## 3. Screenshots

Seven iPhone screenshots and six iPad screenshots per language, each with a headline written as a *benefit*, not a feature name:

| # | Screen | English headline |
| --- | --- | --- |
| 1 | Dashboard | Never pay for a **forgotten trial** |
| 2 | Free trial countdown | Cancel **before** you're charged |
| 3 | Popular services picker | Add subscriptions **in seconds** |
| 4 | Spending insights | See where your **money goes** |
| 5 | Warranty details | Every **warranty**, safe |
| 6 | Reminder settings | Reminders **before** every renewal |
| 7 | Renewly Pro (iPhone only) | Try **Renewly Pro** free |

- The first **three** screenshots show up in search results, so they carry the core story: forgotten trials → cancel in time → easy setup.
- Sizes: iPhone 6.9" (1320 × 2868) and iPad 13" (2064 × 2752). App Store Connect scales these down for every smaller device.
- Prices in the demo data are **localized** (¥, R$, €, ₹…) so each market sees believable numbers.
- en-AU and en-CA reuse the en-US set; fr-CA reuses fr-FR.

### Regenerating

Run from the repo's `Renewly/` folder:

```bash
# 1. Debug build for the simulator
cd Renewly
xcodebuild -project Renewly.xcodeproj -scheme Renewly -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/RenewlyDD build
cd ..

# 2. Raw captures (iPhone 17 Pro Max + iPad Pro 13", all languages, ~20 min)
marketing/tools/capture-screenshots.sh \
  /tmp/RenewlyDD/Build/Products/Debug-iphonesimulator/Renewly.app /tmp/renewly-raw iphone ipad
#    Only some languages:  ... iphone -- en-US de-DE

# 3. Frame and caption
swiftc -parse-as-library -O marketing/tools/ComposeScreenshots.swift marketing/tools/ScreenshotCopy.swift \
  -o /tmp/compose-screenshots
/tmp/compose-screenshots /tmp/renewly-raw fastlane/screenshots marketing/promo \
  Renewly/Renewly/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

Headlines live in `marketing/tools/ScreenshotCopy.swift`; wrap words in `**…**` to highlight them in mint.

---

## 3b. Promo videos

Two videos per language in `marketing/video/<locale>/`, both made from real app footage:

| File | Size | Length | Use |
| --- | --- | --- | --- |
| `app-preview-iphone.mp4` | 886 × 1920, 30 fps | 23 s | **App Store app preview** (iPhone 6.9" slot). Plays muted and autoplays in search results and on the product page |
| `promo-vertical.mp4` | 1080 × 1920, 30 fps | 28 s | Instagram Reels, TikTok, YouTube Shorts, Apple Search Ads creative |

What they show, in order: dashboard → free-trial countdown → warranty → spending insights → reminder settings → adding a service from the popular list. Each scene carries the same headline as the matching screenshot, so the listing tells one story.

- **App preview rules:** Apple only allows footage captured from the app itself, plus text overlays. That's why the preview has no device frame, intro or "Download" card; the social video does.
- **Poster frame:** in App Store Connect, set it to around 0:01 (the dashboard with "Never pay for a forgotten trial"). The poster frame is what people see before the video plays.
- **Sound:** both videos have a silent audio track (App Store previews require an audio track). On TikTok and Instagram, add a trending sound inside the app; those tracks are licensed for the platform. Don't add copyrighted music to the App Store preview.
- **One preview per language** is uploaded in each localization. en-AU and en-CA can use en-US; fr-CA can use fr-FR.
- **Posting rhythm for social:** one post a week works better than a burst. Re-cut the same footage with different hooks: "POV: you forgot to cancel a free trial", "I was paying for 5 subscriptions I didn't use", "Where's the receipt for this TV?".

### Regenerating

```bash
# 1. Debug build (same as for screenshots), then record the in-app tour per language (~30 s each)
marketing/tools/capture-promo-video.sh \
  /tmp/RenewlyDD/Build/Products/Debug-iphonesimulator/Renewly.app /tmp/renewly-video-raw
#    Only some languages:  ... /tmp/renewly-video-raw en-US ja

# 2. Compose
cd marketing/tools
swiftc -parse-as-library -O -D PROMO_VIDEO ComposePromoVideo.swift ComposeScreenshots.swift \
  ScreenshotCopy.swift PromoVideoCopy.swift -o /tmp/compose-promo-video
cd ../..
/tmp/compose-promo-video /tmp/renewly-video-raw marketing/video \
  Renewly/Renewly/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

The tour is the debug launch option `-demo_tour YES` (`DemoTour.swift` in the app). Its timing and the caption timing in `ComposePromoVideo.swift` must change together. The composer finds where the tour starts in each recording by itself, so recordings don't need trimming.

---

## 4. Subscriptions in App Store Connect

**Group:** `Renewly Pro` (Level 1: Yearly, Level 2: Monthly, so moving from monthly to yearly counts as an upgrade).

| Product ID | Duration | US price | Intro offer |
| --- | --- | --- | --- |
| `com.applab.Renewly.pro.yearly` | 1 year | $19.99 | 1-week free trial |
| `com.applab.Renewly.pro.monthly` | 1 month | $4.99 | 1-week free trial |

The yearly plan works out to **$1.67/month, 67% cheaper** than monthly. The monthly price is mainly there to make the yearly plan look like the obvious choice; most revenue should come from yearly.

### Localized display names and descriptions

Display name ≤ 30 characters, description ≤ 45.

| Locale | Monthly name | Monthly description | Yearly name | Yearly description |
| --- | --- | --- | --- | --- |
| English | Renewly Pro Monthly | All Pro features, billed monthly | Renewly Pro Yearly | All Pro features, billed yearly |
| German | Renewly Pro monatlich | Alle Pro-Funktionen, monatlich abgerechnet | Renewly Pro jährlich | Alle Pro-Funktionen, jährlich abgerechnet |
| French | Renewly Pro mensuel | Toutes les fonctions Pro, facturé au mois | Renewly Pro annuel | Toutes les fonctions Pro, facturé à l’année |
| Spanish | Renewly Pro mensual | Todas las funciones Pro, pago mensual | Renewly Pro anual | Todas las funciones Pro, pago anual |
| Portuguese (BR) | Renewly Pro mensal | Todos os recursos Pro, cobrança mensal | Renewly Pro anual | Todos os recursos Pro, cobrança anual |
| Japanese | Renewly Pro 月額 | すべてのPro機能が使える月額プラン | Renewly Pro 年額 | すべてのPro機能が使える年額プラン |
| Chinese (Simplified) | Renewly Pro 月度 | 解锁全部 Pro 功能，按月付费 | Renewly Pro 年度 | 解锁全部 Pro 功能，按年付费 |
| Bangla | Renewly Pro মাসিক | Pro-র সব ফিচার, প্রতি মাসে বিল | Renewly Pro বার্ষিক | Pro-র সব ফিচার, প্রতি বছরে বিল |

### Assets each subscription needs

- **Review screenshot:** `marketing/promo/subscription-review-screenshot.png` (the iPhone paywall). Upload it to both products; App Review needs it to approve the subscription.
- **Promotional image (1024 × 1024):** `marketing/promo/subscription-promo-1024.png`. Optional, but lets the subscription appear on the product page and in search results as a promoted in-app purchase.
- **Review notes:** "Pro is offered on the paywall (Settings → Renewly Pro, or tap the crown on Insights). Sandbox accounts can start the 1-week free trial. No login is needed; all data stays on the device."

### Pricing per country

Apple converts the US price automatically, but the result is often too high for lower-income markets. Suggested manual prices:

| Storefront | Monthly | Yearly | Why |
| --- | --- | --- | --- |
| United States | $4.99 | $19.99 | Base |
| Euro countries | €4.99 | €19.99 | Round local price points |
| United Kingdom | £4.49 | £17.99 | UK prices include VAT and sit slightly under euro prices |
| Japan | ¥600 | ¥2,400 | Japanese subscription utilities cluster around ¥300–¥700 a month |
| Brazil | R$ 14,90 | R$ 59,90 | Auto-conversion lands near R$ 30 a month, which is too expensive there |
| Mexico | $69 MXN | $279 MXN | Same reason |
| India | ₹149 | ₹599 | Indian buyers are very price-sensitive; volume matters more than unit price |
| China mainland | ¥28 | ¥118 | Only once you have an ICP filing (see section 5) |

Start here, then let the data decide (see section 7). The paywall screenshots use these same prices (`DemoPlans.swift`), so keep the two in sync if you change them.

### Free trial

The 1-week free trial is the single biggest conversion lever for a utility like this. Keep it on both plans. An app about not getting caught by trials must run an honest one itself: the paywall states the price after the trial, and the description explains how to cancel.

---

## 5. App Privacy, age rating, categories

| Field | Answer |
| --- | --- |
| **App Privacy** | **Data Not Collected.** Renewly has no servers, analytics, ads or account. Support emails are written in the user's own mail app and sent only if they choose, which counts as optional, user-initiated disclosure. |
| **Privacy policy URL** | https://www.applab.world/privacy.html |
| **Support URL** | `https://www.applab.world/`. Make sure this page shows the support email (support.applab.world@gmail.com); App Review opens it. |
| **Age rating** | 4+ (answer "None" to every content question) |
| **Primary category** | Finance. This is where subscription and bill trackers are found, and Finance users are used to paying for tools. |
| **Secondary category** | Productivity |
| **Copyright** | `2026 Md Mehedi Hasan Angkur`. Change this to your company name if you publish as an organisation. |
| **Encryption export** | Uses only Apple's built-in encryption, so answer "No" to non-exempt encryption |

### China mainland

Apple requires an **ICP filing number** to publish in mainland China. Without one, untick "China mainland" in *Pricing and Availability*. The Simplified Chinese listing still works in Singapore, Malaysia and as an extra language in the US and other storefronts.

---

## 6. Ratings and reviews

The app asks for a rating **after the third item you add** and **at most once per app version** (`ReviewPrompt`), one second after the editor closes. That's a moment of success, never a moment of friction.

Ratings move both search rank and conversion more than anything else after launch. Reply to every review in App Store Connect, especially negative ones; people read replies.

---

## 7. After launch: the growth loop

1. **Week 1–2:** watch *App Store Connect → Analytics*: impressions → product page views → downloads (conversion rate) and trials → paid (subscription conversion).
2. **Product Page Optimization:** A/B test up to three alternative screenshot sets, e.g. "Never pay for a forgotten trial" vs. "Know what you spend each month" as screenshot 1. Run each test until Apple reports a confident result.
3. **Custom Product Pages:** create separate pages for *warranty tracker* and *cancel subscriptions* searches, each with screenshots that lead with that use case, and point Apple Search Ads keywords at them.
4. **Apple Search Ads:** start small with exact-match keywords *subscription tracker*, *cancel subscriptions*, *free trial reminder*, *warranty tracker*, *bill reminder*. Pause anything with high cost per trial after two weeks.
5. **In-App Events** (free App Store promotion): "New Year Subscription Audit" in January, "Black Friday Receipt Saver" in November, "Spring Clean Your Subscriptions" in April.
6. **Keyword refresh every 4–6 weeks:** check which keywords bring impressions and swap out the ones that don't. Keyword changes need a new app version.
7. **Subscription offers:**
   - **Offer codes** for influencers, newsletters and Reddit communities (r/personalfinance, r/frugal).
   - **Win-back offers** (iOS 18+) for people who cancelled: e.g. 50% off the first year.
   - Consider enabling **Family Sharing** on the subscriptions; it lowers the "is it worth it?" barrier.
8. **Pricing experiments:** once you have a few hundred trials, test $24.99/year in one region against $19.99. Apple lets you change prices per country without an update.

---

## 8. Launch checklist

- [ ] Subscriptions created in App Store Connect with the IDs above, prices set, localized names and descriptions added, review screenshot uploaded
- [ ] Paid Applications agreement, banking and tax forms complete (subscriptions won't load without them)
- [ ] All 13 localizations added under *App Information* and the version page, text pasted from `fastlane/metadata`
- [ ] Screenshots uploaded per locale from `fastlane/screenshots` (iPhone 6.9" and iPad 13")
- [ ] App preview uploaded per locale from `marketing/video/<locale>/app-preview-iphone.mp4`, poster frame set
- [ ] First social video posted, with the App Store link in the bio
- [ ] App Privacy: Data Not Collected; age rating 4+; Finance / Productivity
- [ ] Support page live and showing the support email
- [ ] China mainland unticked (unless you have an ICP filing)
- [ ] Release build tested with a Sandbox account: purchase, restore, trial, cancel
- [ ] Release build uploaded from Xcode (Archive → Distribute), with "Manually release this version" so you can pick the launch day
- [ ] After approval: first In-App Event and a small Search Ads campaign ready to switch on
