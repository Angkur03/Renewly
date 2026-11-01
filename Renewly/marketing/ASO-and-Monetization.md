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
| Store listing text for 13 locales (name, subtitle, keywords, promo text, description, URLs) | `fastlane/metadata/<locale>/`, also copied into [section 2b](#2b-store-listing-text-for-every-language) below |
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

<!-- listings:start -->

## 2b. Store listing text for every language

Copy each block into App Store Connect: **App Information** holds the name and subtitle; the **version page** of each localization holds the promotional text, description and keywords. The source of truth is `fastlane/metadata/<locale>/`; this section mirrors it, so update both together (or upload with `fastlane deliver`).

Character counts are shown as used / Apple's limit.

| Language in App Store Connect | Folder | Who it reaches |
| --- | --- | --- |
| English (U.S.) | `en-US` | United States and the default for English |
| English (U.K.) | `en-GB` | United Kingdom, plus English speakers in Europe, India and Australia |
| English (Australia) | `en-AU` | Australia |
| English (Canada) | `en-CA` | Canada |
| German | `de-DE` | Germany, Austria, Switzerland |
| French | `fr-FR` | France, Belgium, Switzerland, and an extra index language in the US |
| French (Canada) | `fr-CA` | Canada (Québec) |
| Spanish (Spain) | `es-ES` | Spain |
| Spanish (Mexico) | `es-MX` | Mexico and Latin America, and an extra index language in the US |
| Portuguese (Brazil) | `pt-BR` | Brazil, and an extra index language in the US |
| Japanese | `ja` | Japan |
| Chinese (Simplified) | `zh-Hans` | China mainland (needs ICP filing), Singapore, Malaysia, and an extra index language in the US |
| Bangla | `bn-BD` | Bengali speakers in India and anyone browsing in Bangla |

### English (U.S.) (`en-US`)

| Field | Text | Characters |
| --- | --- | --- |
| App name | Renewly: Subscription Tracker | 29/30 |
| Subtitle | Free Trial & Warranty Reminder | 30/30 |

**Keywords** (99/100)

```text
manager,bills,budget,expense,renewal,cancel,receipt,spending,money,payment,recurring,organizer,cost
```

**Promotional text** (153/170)

```text
Never pay for a free trial you forgot to cancel. Track subscriptions and warranties in one private place: no account, no ads, nothing leaves your device.
```

<details>
<summary><b>Description</b> (2008/4000)</summary>

```text
Forgot to cancel a free trial again? Lost the receipt right when the warranty mattered?

Renewly keeps every subscription, free trial and warranty in one place and reminds you before money leaves your account or protection runs out.

NEVER MISS A RENEWAL
• Reminders 30, 7, 3 or 1 day before every charge
• Free trial countdowns, so you can cancel before the first payment
• One-tap cancel links for popular services
• See everything that renews this week at a glance

KNOW WHAT YOU SPEND
• Monthly and yearly totals in your currency
• Upcoming charges and a 12-month forecast
• Add popular services in seconds: the plan and cancel link fill in

KEEP WARRANTIES SAFE
• Purchase dates, retailers and serial numbers in one place
• Snap the receipt or warranty card and the dates are read for you
• Export a clean PDF when you need to make a claim

PRIVATE BY DESIGN
• No account, no sign-up, no ads, no tracking
• Your data stays on your device. There are no Renewly servers
• Back up and restore whenever you want

BUILT FOR IPHONE AND IPAD
• Home Screen and Lock Screen widgets
• Ask Siri: "What's coming up in Renewly?"
• Light and dark themes
• Available in English, Spanish, French, German, Portuguese, Japanese, Chinese and Bangla

RENEWLY PRO
Renewly is free to use, with 7-day reminders for your 3 soonest items. Renewly Pro unlocks unlimited reminders, extra reminder times, spending insights and PDF export. Try it free for 7 days.

Payment is charged to your Apple Account at confirmation of purchase. The subscription renews automatically unless it is cancelled at least 24 hours before the end of the current period. Your account is charged for renewal within 24 hours before the end of the current period. You can manage or cancel your subscription in your App Store account settings. Any unused portion of a free trial is forfeited when you buy a subscription.

Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://www.applab.world/privacy.html
```

</details>

### English (U.K.) (`en-GB`)

| Field | Text | Characters |
| --- | --- | --- |
| App name | Renewly: Subscription Tracker | 29/30 |
| Subtitle | Free Trial & Warranty Reminder | 30/30 |

**Keywords** (100/100)

```text
manager,bills,direct,debit,budget,expenses,renewal,cancel,receipt,guarantee,spending,money,outgoings
```

**Promotional text** (153/170)

```text
Never pay for a free trial you forgot to cancel. Track subscriptions and warranties in one private place: no account, no ads, nothing leaves your device.
```

**Description** (2008/4000): identical to `en-US` above.

### English (Australia) (`en-AU`)

| Field | Text | Characters |
| --- | --- | --- |
| App name | Renewly: Subscription Tracker | 29/30 |
| Subtitle | Free Trial & Warranty Reminder | 30/30 |

**Keywords** (97/100)

```text
planner,payment,recurring,organiser,monthly,yearly,calendar,alert,notify,due,bill,invoice,finance
```

**Promotional text** (153/170)

```text
Never pay for a free trial you forgot to cancel. Track subscriptions and warranties in one private place: no account, no ads, nothing leaves your device.
```

**Description** (2008/4000): identical to `en-US` above.

### English (Canada) (`en-CA`)

| Field | Text | Characters |
| --- | --- | --- |
| App name | Renewly: Subscription Tracker | 29/30 |
| Subtitle | Free Trial & Warranty Reminder | 30/30 |

**Keywords** (99/100)

```text
manager,bills,budget,expense,renewal,cancel,receipt,spending,money,payment,recurring,organizer,cost
```

**Promotional text** (153/170)

```text
Never pay for a free trial you forgot to cancel. Track subscriptions and warranties in one private place: no account, no ads, nothing leaves your device.
```

**Description** (2008/4000): identical to `en-US` above.

### German (`de-DE`)

| Field | Text | Characters |
| --- | --- | --- |
| App name | Renewly: Abo-Manager | 20/30 |
| Subtitle | Probeabos & Garantien im Blick | 30/30 |

**Keywords** (93/100)

```text
kündigen,vertrag,verträge,rechnung,kosten,ausgaben,haushaltsbuch,beleg,kassenbon,verlängerung
```

**Promotional text** (147/170)

```text
Nie wieder für ein vergessenes Probeabo zahlen. Abos und Garantien an einem privaten Ort – ohne Konto, ohne Werbung, alles bleibt auf deinem Gerät.
```

<details>
<summary><b>Description</b> (2166/4000)</summary>

```text
Wieder ein Probeabo vergessen zu kündigen? Den Kassenbon verloren, genau als die Garantie wichtig war?

Renewly hält alle Abos, Probeabos und Garantien an einem Ort und erinnert dich, bevor Geld abgebucht wird oder der Garantieschutz endet.

KEINE VERLÄNGERUNG VERPASSEN
• Erinnerungen 30, 7, 3 oder 1 Tag vor jeder Abbuchung
• Countdown für Probeabos – kündige vor der ersten Zahlung
• Kündigungslinks für beliebte Dienste mit einem Tipp
• Auf einen Blick sehen, was diese Woche fällig ist

KOSTEN IM GRIFF
• Monatliche und jährliche Summen in deiner Währung
• Anstehende Abbuchungen und 12-Monats-Prognose
• Beliebte Dienste in Sekunden hinzufügen – Tarif und Kündigungslink sind schon ausgefüllt

GARANTIEN SICHER AUFBEWAHREN
• Kaufdatum, Händler und Seriennummer an einem Ort
• Beleg oder Garantiekarte fotografieren – die Daten werden erkannt
• Saubere PDF für den Garantiefall exportieren

PRIVAT VON GRUND AUF
• Kein Konto, keine Anmeldung, keine Werbung, kein Tracking
• Deine Daten bleiben auf deinem Gerät. Es gibt keine Renewly-Server
• Sichern und wiederherstellen, wann immer du willst

FÜR IPHONE UND IPAD
• Widgets für Home- und Sperrbildschirm
• Frag Siri: „Was steht in Renewly an?“
• Helles und dunkles Design
• Auf Deutsch, Englisch, Spanisch, Französisch, Portugiesisch, Japanisch, Chinesisch und Bangla

RENEWLY PRO
Renewly ist kostenlos nutzbar, mit Erinnerungen 7 Tage vorher für deine 3 nächsten Einträge. Renewly Pro schaltet unbegrenzte Erinnerungen, zusätzliche Erinnerungszeiten, Ausgabenanalysen und PDF-Export frei. 7 Tage kostenlos testen.

Die Zahlung wird bei Kaufbestätigung über deinen Apple Account abgerechnet. Das Abo verlängert sich automatisch, wenn es nicht mindestens 24 Stunden vor Ende des aktuellen Zeitraums gekündigt wird. Die Verlängerung wird innerhalb von 24 Stunden vor Ende des Zeitraums berechnet. Du kannst dein Abo in den Einstellungen deines App Store-Accounts verwalten und kündigen. Ein nicht genutzter Teil des Probezeitraums verfällt mit dem Kauf eines Abos.

Nutzungsbedingungen: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Datenschutzerklärung: https://www.applab.world/privacy.html
```

</details>

### French (`fr-FR`)

| Field | Text | Characters |
| --- | --- | --- |
| App name | Renewly : Gestion abonnements | 29/30 |
| Subtitle | Essais gratuits et garanties | 28/30 |

**Keywords** (95/100)

```text
résilier,rappel,dépenses,budget,facture,ticket,reçu,renouvellement,prélèvement,finances,contrat
```

**Promotional text** (161/170)

```text
Ne payez plus un essai gratuit oublié. Abonnements et garanties au même endroit, en toute confidentialité : sans compte, sans pub, tout reste sur votre appareil.
```

<details>
<summary><b>Description</b> (2273/4000)</summary>

```text
Encore un essai gratuit oublié ? Le ticket de caisse perdu au moment où la garantie comptait ?

Renewly réunit vos abonnements, essais gratuits et garanties au même endroit et vous prévient avant d’être débité ou que la garantie expire.

NE RATEZ PLUS AUCUN RENOUVELLEMENT
• Rappels 30, 7, 3 ou 1 jour avant chaque prélèvement
• Compte à rebours des essais gratuits pour résilier avant le premier paiement
• Liens de résiliation en un geste pour les services populaires
• Tout ce qui se renouvelle cette semaine, d’un coup d’œil

MAÎTRISEZ VOS DÉPENSES
• Totaux mensuels et annuels dans votre devise
• Prochains prélèvements et prévision sur 12 mois
• Ajoutez un service populaire en quelques secondes : formule et lien de résiliation inclus

GARDEZ VOS GARANTIES EN SÉCURITÉ
• Date d’achat, magasin et numéro de série au même endroit
• Photographiez le reçu ou la carte de garantie : les dates sont lues pour vous
• Exportez un PDF propre pour toute réclamation

CONFIDENTIEL PAR NATURE
• Pas de compte, pas d’inscription, pas de pub, aucun pistage
• Vos données restent sur votre appareil. Renewly n’a pas de serveurs
• Sauvegardez et restaurez quand vous voulez

POUR IPHONE ET IPAD
• Widgets pour l’écran d’accueil et l’écran verrouillé
• Demandez à Siri : « Qu’est-ce qui arrive dans Renewly ? »
• Thèmes clair et sombre
• Disponible en français, anglais, espagnol, allemand, portugais, japonais, chinois et bengali

RENEWLY PRO
Renewly est gratuit, avec des rappels 7 jours avant pour vos 3 prochaines échéances. Renewly Pro débloque les rappels illimités, des rappels supplémentaires, l’analyse des dépenses et l’export PDF. Essai gratuit de 7 jours.

Le paiement est débité sur votre compte Apple à la confirmation de l’achat. L’abonnement se renouvelle automatiquement sauf résiliation au moins 24 heures avant la fin de la période en cours. Le renouvellement est facturé dans les 24 heures précédant la fin de la période. Vous pouvez gérer ou résilier votre abonnement dans les réglages de votre compte App Store. Toute partie inutilisée d’un essai gratuit est perdue lors de l’achat d’un abonnement.

Conditions d’utilisation : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Politique de confidentialité : https://www.applab.world/privacy.html
```

</details>

### French (Canada) (`fr-CA`)

| Field | Text | Characters |
| --- | --- | --- |
| App name | Renewly : Gestion abonnements | 29/30 |
| Subtitle | Essais gratuits et garanties | 28/30 |

**Keywords** (93/100)

```text
résilier,rappel,dépenses,budget,facture,reçu,renouvellement,paiement,finances,contrat,annuler
```

**Promotional text** (161/170)

```text
Ne payez plus un essai gratuit oublié. Abonnements et garanties au même endroit, en toute confidentialité : sans compte, sans pub, tout reste sur votre appareil.
```

**Description** (2273/4000): identical to `fr-FR` above.

### Spanish (Spain) (`es-ES`)

| Field | Text | Characters |
| --- | --- | --- |
| App name | Renewly: Control suscripciones | 30/30 |
| Subtitle | Pruebas gratis y garantías | 26/30 |

**Keywords** (98/100)

```text
cancelar,recordatorio,gastos,presupuesto,facturas,recibo,renovación,pagos,finanzas,ahorro,contrato
```

**Promotional text** (158/170)

```text
No vuelvas a pagar una prueba gratis olvidada. Suscripciones y garantías en un solo lugar privado: sin cuenta, sin anuncios y todo se queda en tu dispositivo.
```

<details>
<summary><b>Description</b> (2153/4000)</summary>

```text
¿Otra vez olvidaste cancelar una prueba gratis? ¿Perdiste el recibo justo cuando necesitabas la garantía?

Renewly reúne todas tus suscripciones, pruebas gratis y garantías en un solo lugar y te avisa antes de que te cobren o de que caduque la garantía.

NO TE PIERDAS NINGUNA RENOVACIÓN
• Avisos 30, 7, 3 o 1 día antes de cada cargo
• Cuenta atrás de las pruebas gratis para cancelar antes del primer pago
• Enlaces para cancelar servicios populares con un toque
• Todo lo que se renueva esta semana, de un vistazo

CONTROLA LO QUE GASTAS
• Totales mensuales y anuales en tu moneda
• Próximos cargos y previsión a 12 meses
• Añade servicios populares en segundos: el plan y el enlace para cancelar se rellenan solos

GUARDA TUS GARANTÍAS
• Fecha de compra, tienda y número de serie en un solo lugar
• Fotografía el recibo o la tarjeta de garantía y las fechas se leen solas
• Exporta un PDF limpio para cualquier reclamación

PRIVADO POR DISEÑO
• Sin cuenta, sin registro, sin anuncios y sin rastreo
• Tus datos se quedan en tu dispositivo. Renewly no tiene servidores
• Haz copias de seguridad y restáuralas cuando quieras

PARA IPHONE Y IPAD
• Widgets para la pantalla de inicio y la pantalla bloqueada
• Pregúntale a Siri: «Qué viene en Renewly»
• Temas claro y oscuro
• Disponible en español, inglés, francés, alemán, portugués, japonés, chino y bengalí

RENEWLY PRO
Renewly es gratis, con avisos 7 días antes para tus 3 próximos elementos. Renewly Pro desbloquea avisos ilimitados, avisos adicionales, análisis de gastos y exportación a PDF. Pruébalo gratis durante 7 días.

El pago se cargará en tu cuenta de Apple al confirmar la compra. La suscripción se renueva automáticamente salvo que se cancele al menos 24 horas antes del final del periodo actual. La renovación se cobra en las 24 horas previas al final del periodo. Puedes gestionar o cancelar la suscripción en los ajustes de tu cuenta del App Store. Cualquier parte no utilizada de la prueba gratis se pierde al comprar una suscripción.

Condiciones de uso: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Política de privacidad: https://www.applab.world/privacy.html
```

</details>

### Spanish (Mexico) (`es-MX`)

| Field | Text | Characters |
| --- | --- | --- |
| App name | Renewly: Control suscripciones | 30/30 |
| Subtitle | Pruebas gratis y garantías | 26/30 |

**Keywords** (94/100)

```text
cancelar,recordatorio,gastos,presupuesto,recibos,renovación,pagos,finanzas,cuentas,mensualidad
```

**Promotional text** (158/170)

```text
No vuelvas a pagar una prueba gratis olvidada. Suscripciones y garantías en un solo lugar privado: sin cuenta, sin anuncios y todo se queda en tu dispositivo.
```

<details>
<summary><b>Description</b> (2158/4000)</summary>

```text
¿Otra vez olvidaste cancelar una prueba gratis? ¿Perdiste el recibo justo cuando necesitabas la garantía?

Renewly reúne todas tus suscripciones, pruebas gratis y garantías en un solo lugar y te avisa antes de que te cobren o de que caduque la garantía.

NO TE PIERDAS NINGUNA RENOVACIÓN
• Avisos 30, 7, 3 o 1 día antes de cada cargo
• Cuenta regresiva de las pruebas gratis para cancelar antes del primer pago
• Enlaces para cancelar servicios populares con un toque
• Todo lo que se renueva esta semana, de un vistazo

CONTROLA LO QUE GASTAS
• Totales mensuales y anuales en tu moneda
• Próximos cargos y previsión a 12 meses
• Agrega servicios populares en segundos: el plan y el enlace para cancelar se llenan solos

GUARDA TUS GARANTÍAS
• Fecha de compra, tienda y número de serie en un solo lugar
• Fotografía el recibo o la tarjeta de garantía y las fechas se leen solas
• Exporta un PDF limpio para cualquier reclamación

PRIVADO POR DISEÑO
• Sin cuenta, sin registro, sin anuncios y sin rastreo
• Tus datos se quedan en tu dispositivo. Renewly no tiene servidores
• Haz copias de seguridad y restáuralas cuando quieras

PARA IPHONE Y IPAD
• Widgets para la pantalla de inicio y la pantalla bloqueada
• Pregúntale a Siri: “Qué viene en Renewly”
• Temas claro y oscuro
• Disponible en español, inglés, francés, alemán, portugués, japonés, chino y bengalí

RENEWLY PRO
Renewly es gratis, con avisos 7 días antes para tus 3 próximos elementos. Renewly Pro desbloquea avisos ilimitados, avisos adicionales, análisis de gastos y exportación a PDF. Pruébalo gratis durante 7 días.

El pago se cargará en tu cuenta de Apple al confirmar la compra. La suscripción se renueva automáticamente salvo que se cancele al menos 24 horas antes del final del periodo actual. La renovación se cobra en las 24 horas previas al final del periodo. Puedes administrar o cancelar la suscripción en los ajustes de tu cuenta del App Store. Cualquier parte no utilizada de la prueba gratis se pierde al comprar una suscripción.

Condiciones de uso: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Política de privacidad: https://www.applab.world/privacy.html
```

</details>

### Portuguese (Brazil) (`pt-BR`)

| Field | Text | Characters |
| --- | --- | --- |
| App name | Renewly: Gestor de Assinaturas | 30/30 |
| Subtitle | Teste grátis e garantia em dia | 30/30 |

**Keywords** (100/100)

```text
contas,lembrete,cancelar,gastos,finanças,orçamento,mensalidade,recibo,nota,fiscal,renovação,despesas
```

**Promotional text** (162/170)

```text
Nunca mais pague por um teste grátis esquecido. Assinaturas e garantias em um só lugar, com total privacidade: sem conta, sem anúncios, tudo fica no seu aparelho.
```

<details>
<summary><b>Description</b> (2101/4000)</summary>

```text
Esqueceu de cancelar um teste grátis de novo? Perdeu a nota fiscal bem na hora de usar a garantia?

O Renewly reúne todas as suas assinaturas, testes grátis e garantias em um só lugar e avisa antes da cobrança ou do fim da garantia.

NUNCA PERCA UMA RENOVAÇÃO
• Lembretes 30, 7, 3 ou 1 dia antes de cada cobrança
• Contagem regressiva dos testes grátis para cancelar antes do primeiro pagamento
• Links para cancelar serviços populares com um toque
• Tudo o que renova nesta semana, num relance

SAIBA QUANTO VOCÊ GASTA
• Totais mensais e anuais na sua moeda
• Próximas cobranças e previsão de 12 meses
• Adicione serviços populares em segundos: plano e link de cancelamento já preenchidos

GUARDE SUAS GARANTIAS
• Data da compra, loja e número de série em um só lugar
• Fotografe a nota fiscal ou o certificado de garantia e as datas são lidas para você
• Exporte um PDF limpo para acionar a garantia

PRIVADO DE VERDADE
• Sem conta, sem cadastro, sem anúncios e sem rastreamento
• Seus dados ficam no seu aparelho. O Renewly não tem servidores
• Faça backup e restaure quando quiser

PARA IPHONE E IPAD
• Widgets para a Tela de Início e a Tela Bloqueada
• Pergunte à Siri: "O que vem por aí no Renewly"
• Temas claro e escuro
• Disponível em português, inglês, espanhol, francês, alemão, japonês, chinês e bengali

RENEWLY PRO
O Renewly é grátis, com lembretes 7 dias antes para seus 3 próximos itens. O Renewly Pro libera lembretes ilimitados, horários extras de lembrete, análise de gastos e exportação em PDF. Teste grátis por 7 dias.

O pagamento será cobrado na sua Conta Apple na confirmação da compra. A assinatura é renovada automaticamente, a menos que seja cancelada pelo menos 24 horas antes do fim do período atual. A renovação é cobrada nas 24 horas anteriores ao fim do período. Você pode gerenciar ou cancelar a assinatura nos ajustes da sua conta da App Store. Qualquer parte não usada do teste grátis é perdida ao comprar uma assinatura.

Termos de Uso: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Política de Privacidade: https://www.applab.world/privacy.html
```

</details>

### Japanese (`ja`)

| Field | Text | Characters |
| --- | --- | --- |
| App name | Renewly - サブスク管理 | 16/30 |
| Subtitle | 解約忘れ防止・保証書もまとめて管理 | 17/30 |

**Keywords** (94/100)

```text
解約,家計簿,固定費,支出,無料体験,無料トライアル,リマインダー,自動更新,レシート,節約,支払い,引き落とし,通知,月額,年額,定期購入,請求,契約,保証,期限,家計,出費,動画,音楽
```

**Promotional text** (69/170)

```text
無料体験の解約忘れで、もう損しない。サブスクと保証書をひとつのアプリで管理。アカウント不要・広告なし、データはすべて端末内に保存されます。
```

<details>
<summary><b>Description</b> (1009/4000)</summary>

```text
無料体験の解約を、また忘れていませんか？保証が必要なときに限って、レシートが見つからない…。

Renewlyは、サブスク・無料体験・保証書をひとつにまとめて、請求や保証期限の前にお知らせします。

更新を見逃さない
• 請求の30日前・7日前・3日前・1日前にリマインダー
• 無料体験の残り日数を表示。初回請求の前に解約できます
• 人気サービスはワンタップで解約ページへ
• 今週更新されるものがひと目でわかる

支出を把握
• 月額・年額の合計をお使いの通貨で表示
• 次の請求と12か月の支出予測
• 人気サービスを選ぶだけで、プランと解約リンクを自動入力

保証書をなくさない
• 購入日・購入店・シリアル番号をまとめて保存
• レシートや保証書を撮影すると日付を自動で読み取り
• 修理や交換の申請に使えるPDFを書き出し

プライバシー重視
• アカウント登録なし、広告なし、トラッキングなし
• データは端末内にのみ保存。Renewlyのサーバーはありません
• いつでもバックアップと復元が可能

iPhoneとiPadに対応
• ホーム画面とロック画面のウィジェット
• Siriに「Renewlyで今後の予定」と話しかけるだけ
• ライト／ダークテーマ
• 日本語、英語、スペイン語、フランス語、ドイツ語、ポルトガル語、中国語、ベンガル語に対応

RENEWLY PRO
Renewlyは無料でお使いいただけます（直近3件の項目に7日前のリマインダー）。Renewly Proでは、リマインダー無制限、追加のリマインダー時刻、支出分析、PDF書き出しが使えます。7日間の無料体験付き。

お支払いは購入確定時にApple Accountに請求されます。サブスクリプションは、現在の期間終了の24時間前までに解約しない限り自動的に更新されます。更新料金は期間終了前の24時間以内に請求されます。サブスクリプションの管理と解約は、App Storeのアカウント設定から行えます。無料体験期間中にサブスクリプションを購入した場合、残りの無料期間は失効します。

利用規約：https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
プライバシーポリシー：https://www.applab.world/privacy.html
```

</details>

### Chinese (Simplified) (`zh-Hans`)

| Field | Text | Characters |
| --- | --- | --- |
| App name | Renewly - 订阅管理与提醒 | 17/30 |
| Subtitle | 免费试用到期提醒，保修不丢失 | 14/30 |

**Keywords** (95/100)

```text
自动续费,取消,退订,记账,记账本,账单,续订,扣费,保修卡,发票,收据,支出,开支,省钱,会员,视频会员,试用,到期,预算,财务,固定支出,月费,年费,流媒体,音乐,网盘,话费,宽带,软件
```

**Promotional text** (54/170)

```text
再也不为忘记取消的免费试用付费。订阅和保修集中管理，完全私密：无需账号、没有广告，所有数据都留在你的设备上。
```

<details>
<summary><b>Description</b> (793/4000)</summary>

```text
又忘了取消免费试用？需要保修时却找不到收据？

Renewly 把所有订阅、免费试用和保修集中在一处，在扣费或保修到期之前提醒你。

不错过任何续订
• 每次扣费前 30、7、3 或 1 天提醒
• 免费试用倒计时，在首次扣费前取消
• 热门服务一键打开取消页面
• 本周要续订的内容一目了然

清楚每一笔支出
• 以你的货币显示每月和每年总额
• 即将扣费和未来 12 个月预测
• 选择热门服务，几秒钟即可添加，方案和取消链接自动填写

妥善保存保修
• 购买日期、商家和序列号集中保存
• 拍下收据或保修卡，日期自动识别
• 导出整洁的 PDF，方便申请保修

隐私至上
• 无需账号、无需注册、没有广告、没有追踪
• 数据只保存在你的设备上，Renewly 没有服务器
• 随时备份和恢复

支持 iPhone 和 iPad
• 主屏幕和锁定屏幕小组件
• 问 Siri：“Renewly里有什么即将到来”
• 浅色和深色主题
• 支持中文、英语、西班牙语、法语、德语、葡萄牙语、日语和孟加拉语

RENEWLY PRO
Renewly 可免费使用，为最近的 3 个项目提供提前 7 天的提醒。Renewly Pro 解锁无限提醒、更多提醒时间、支出分析和 PDF 导出。可免费试用 7 天。

确认购买后，费用将从你的 Apple 账户扣除。除非在当前周期结束前至少 24 小时取消，订阅将自动续订。续订费用将在当前周期结束前 24 小时内扣除。你可以在 App Store 账户设置中管理或取消订阅。购买订阅后，免费试用期中未使用的部分将作废。

使用条款：https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
隐私政策：https://www.applab.world/privacy.html
```

</details>

### Bangla (`bn-BD`)

| Field | Text | Characters |
| --- | --- | --- |
| App name | Renewly: সাবস্ক্রিপশন হিসাব | 27/30 |
| Subtitle | ফ্রি ট্রায়াল, ওয়ারেন্টি, বিল | 30/30 |

**Keywords** (90/100)

```text
বাজেট,খরচ,বাতিল,রসিদ,নবায়ন,টাকা,পেমেন্ট,মাসিক,সঞ্চয়,রিমাইন্ডার,subscription,tracker,bill
```

**Promotional text** (152/170)

```text
ভুলে যাওয়া ফ্রি ট্রায়ালের জন্য আর টাকা নয়। সাবস্ক্রিপশন আর ওয়ারেন্টি এক জায়গায়, পুরো প্রাইভেট: অ্যাকাউন্ট বা বিজ্ঞাপন নেই, সব তথ্য আপনার ডিভাইসেই।
```

<details>
<summary><b>Description</b> (1899/4000)</summary>

```text
আবারও ফ্রি ট্রায়াল বাতিল করতে ভুলে গেছেন? ওয়ারেন্টির দরকারের সময়েই রসিদ খুঁজে পাচ্ছেন না?

Renewly আপনার সব সাবস্ক্রিপশন, ফ্রি ট্রায়াল আর ওয়ারেন্টি এক জায়গায় রাখে, আর টাকা কাটার বা ওয়ারেন্টি শেষ হওয়ার আগেই আপনাকে মনে করিয়ে দেয়।

কোনো নবায়ন মিস হবে না
• প্রতিটি চার্জের ৩০, ৭, ৩ বা ১ দিন আগে রিমাইন্ডার
• ফ্রি ট্রায়ালের কাউন্টডাউন, যাতে প্রথম পেমেন্টের আগেই বাতিল করতে পারেন
• জনপ্রিয় সার্ভিস বাতিলের লিংক এক ট্যাপে
• এই সপ্তাহে কী নবায়ন হচ্ছে, এক নজরে

খরচ জানুন
• আপনার মুদ্রায় মাসিক ও বার্ষিক মোট খরচ
• আসন্ন চার্জ আর ১২ মাসের পূর্বাভাস
• জনপ্রিয় সার্ভিস কয়েক সেকেন্ডে যোগ করুন: প্ল্যান আর বাতিলের লিংক নিজে থেকেই পূরণ হয়

ওয়ারেন্টি নিরাপদ রাখুন
• কেনার তারিখ, দোকান আর সিরিয়াল নম্বর এক জায়গায়
• রসিদ বা ওয়ারেন্টি কার্ডের ছবি তুলুন, তারিখ নিজে থেকেই পড়ে নেবে
• ক্লেইমের জন্য পরিষ্কার PDF এক্সপোর্ট করুন

পুরোপুরি প্রাইভেট
• অ্যাকাউন্ট নেই, সাইন-আপ নেই, বিজ্ঞাপন নেই, ট্র্যাকিং নেই
• আপনার তথ্য শুধু আপনার ডিভাইসে থাকে। Renewly-র কোনো সার্ভার নেই
• যখন খুশি ব্যাকআপ ও রিস্টোর করুন

iPhone ও iPad-এর জন্য
• হোম স্ক্রিন ও লক স্ক্রিন উইজেট
• লাইট ও ডার্ক থিম
• বাংলা, ইংরেজি, স্প্যানিশ, ফরাসি, জার্মান, পর্তুগিজ, জাপানি ও চীনা ভাষায়

RENEWLY PRO
Renewly ফ্রিতে ব্যবহার করা যায়, আপনার সবচেয়ে কাছের ৩টি আইটেমের জন্য ৭ দিন আগের রিমাইন্ডারসহ। Renewly Pro-তে পাবেন সীমাহীন রিমাইন্ডার, বাড়তি রিমাইন্ডারের সময়, খরচের বিশ্লেষণ আর PDF এক্সপোর্ট। ৭ দিন ফ্রিতে ব্যবহার করে দেখুন।

কেনা নিশ্চিত করার সময় আপনার Apple Account থেকে পেমেন্ট নেওয়া হবে। চলতি মেয়াদ শেষ হওয়ার অন্তত ২৪ ঘণ্টা আগে বাতিল না করলে সাবস্ক্রিপশন নিজে থেকেই নবায়ন হবে। মেয়াদ শেষের আগের ২৪ ঘণ্টার মধ্যে নবায়নের টাকা কাটা হবে। App Store অ্যাকাউন্টের সেটিংসে গিয়ে সাবস্ক্রিপশন ম্যানেজ বা বাতিল করতে পারবেন। সাবস্ক্রিপশন কিনলে ফ্রি ট্রায়ালের বাকি সময় বাতিল হয়ে যাবে।

ব্যবহারের শর্তাবলি: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
প্রাইভেসি পলিসি: https://www.applab.world/privacy.html
```

</details>

<!-- listings:end -->

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
- Sizes, and which App Store Connect slot each file goes in (a file in the wrong slot fails with "File dimensions are invalid"):

  | Slot in App Store Connect | Files | Size |
  | --- | --- | --- |
  | iPhone 6.9" Display | `iphone-01…07` | 1320 × 2868 |
  | iPhone 6.5" Display | `iphone65-01…07` | 1284 × 2778 |
  | iPhone 6.1" / 6.3" Display | `iphone63-01…07` | 1206 × 2622 |
  | iPad 13" Display | `ipad-01…06` | 2064 × 2752 |

  Upload the 6.9" set; App Store Connect scales it down for smaller iPhones. Use the 6.5" or 6.3" set only if App Store Connect asks for that slot. iPad 13" covers every iPad.
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

# 4. iPhone 6.5" and 6.3" copies of the 6.9" set
swiftc -parse-as-library -O marketing/tools/ResizeScreenshots.swift -o /tmp/resize-screenshots
/tmp/resize-screenshots fastlane/screenshots
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
- [ ] All 13 localizations added under *App Information* and the version page, text pasted from section 2b (or `fastlane/metadata`)
- [ ] Screenshots uploaded per locale from `fastlane/screenshots` (iPhone 6.9" and iPad 13")
- [ ] App preview uploaded per locale from `marketing/video/<locale>/app-preview-iphone.mp4`, poster frame set
- [ ] First social video posted, with the App Store link in the bio
- [ ] App Privacy: Data Not Collected; age rating 4+; Finance / Productivity
- [ ] Support page live and showing the support email
- [ ] China mainland unticked (unless you have an ICP filing)
- [ ] Release build tested with a Sandbox account: purchase, restore, trial, cancel
- [ ] Release build uploaded from Xcode (Archive → Distribute), with "Manually release this version" so you can pick the launch day
- [ ] After approval: first In-App Event and a small Search Ads campaign ready to switch on
