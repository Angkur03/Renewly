//
// ScreenshotCopy.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//
// Headlines for the App Store screenshots. Text between ** ** is highlighted.
// Order matches the capture script: dashboard, trial, add, insights, warranty, reminders, paywall.
//

struct Caption {
    let headline: String
    let subheadline: String
}

let shotNames = ["01_dashboard", "02_trial", "03_add", "04_insights", "05_warranty", "06_reminders", "07_paywall"]

private let english = [
    Caption(headline: "Never pay for a **forgotten trial**", subheadline: "Subscriptions, free trials and warranties. 100% private."),
    Caption(headline: "Cancel **before** you're charged", subheadline: "Trial countdowns and one-tap cancel links."),
    Caption(headline: "Add subscriptions **in seconds**", subheadline: "Pick a popular service and the details fill in."),
    Caption(headline: "See where your **money goes**", subheadline: "Monthly totals, upcoming charges and a 12-month forecast."),
    Caption(headline: "Every **warranty**, safe", subheadline: "Purchase dates, serial numbers and receipts, ready for any claim."),
    Caption(headline: "Reminders **before** every renewal", subheadline: "30, 7, 3 or 1 day ahead. You choose."),
    Caption(headline: "Try **Renewly Pro** free", subheadline: "Free for 7 days. Cancel anytime."),
]

private let spanishSpain = [
    Caption(headline: "No vuelvas a pagar una **prueba olvidada**", subheadline: "Suscripciones, pruebas gratis y garantías. 100 % privado."),
    Caption(headline: "Cancela **antes** de que te cobren", subheadline: "Cuenta atrás de cada prueba y enlace para cancelar al instante."),
    Caption(headline: "Añade suscripciones **en segundos**", subheadline: "Elige un servicio popular y los datos se rellenan solos."),
    Caption(headline: "Descubre **adónde va tu dinero**", subheadline: "Gasto mensual, próximos cargos y previsión a 12 meses."),
    Caption(headline: "Todas tus **garantías**, a salvo", subheadline: "Fecha de compra, número de serie y recibo para cualquier reclamación."),
    Caption(headline: "Avisos **antes** de cada renovación", subheadline: "30, 7, 3 o 1 día antes. Tú eliges."),
    Caption(headline: "Prueba **Renewly Pro** gratis", subheadline: "7 días gratis. Cancela cuando quieras."),
]

let captions: [String: [Caption]] = [
    "en-US": english,
    "en-GB": english,
    "de-DE": [
        Caption(headline: "Nie wieder für ein **vergessenes Probeabo** zahlen", subheadline: "Abos, Probeabos und Garantien. 100 % privat."),
        Caption(headline: "**Rechtzeitig** kündigen", subheadline: "Countdown für jedes Probeabo und Kündigungslink mit einem Tipp."),
        Caption(headline: "Abos **in Sekunden** hinzufügen", subheadline: "Beliebten Dienst wählen – die Details sind schon ausgefüllt."),
        Caption(headline: "Sieh, **wohin dein Geld** geht", subheadline: "Monatliche Kosten, anstehende Abbuchungen und 12-Monats-Prognose."),
        Caption(headline: "Jede **Garantie** sicher", subheadline: "Kaufdatum, Seriennummer und Beleg – bereit für jeden Garantiefall."),
        Caption(headline: "Erinnerung **vor** jeder Verlängerung", subheadline: "30, 7, 3 oder 1 Tag vorher. Du entscheidest."),
        Caption(headline: "**Renewly Pro** gratis testen", subheadline: "7 Tage kostenlos. Jederzeit kündbar."),
    ],
    "fr-FR": [
        Caption(headline: "Ne payez plus un **essai oublié**", subheadline: "Abonnements, essais gratuits et garanties. 100 % privé."),
        Caption(headline: "Résiliez **avant** d’être débité", subheadline: "Compte à rebours des essais et lien de résiliation en un geste."),
        Caption(headline: "Ajoutez un abonnement **en quelques secondes**", subheadline: "Choisissez un service populaire, les détails se remplissent."),
        Caption(headline: "Voyez **où va votre argent**", subheadline: "Total mensuel, prochains prélèvements et prévision sur 12 mois."),
        Caption(headline: "Toutes vos **garanties** en sécurité", subheadline: "Date d’achat, numéro de série et reçu, prêts pour toute réclamation."),
        Caption(headline: "Un rappel **avant** chaque renouvellement", subheadline: "30, 7, 3 ou 1 jour avant. À vous de choisir."),
        Caption(headline: "Essayez **Renewly Pro** gratuitement", subheadline: "7 jours offerts. Résiliable à tout moment."),
    ],
    "es-ES": spanishSpain,
    "es-MX": [
        spanishSpain[0],
        Caption(headline: "Cancela **antes** de que te cobren", subheadline: "Cuenta regresiva de cada prueba y enlace para cancelar al instante."),
        Caption(headline: "Agrega suscripciones **en segundos**", subheadline: "Elige un servicio popular y los datos se llenan solos."),
        spanishSpain[3],
        spanishSpain[4],
        spanishSpain[5],
        spanishSpain[6],
    ],
    "pt-BR": [
        Caption(headline: "Nunca mais pague um **teste esquecido**", subheadline: "Assinaturas, testes grátis e garantias. 100% privado."),
        Caption(headline: "Cancele **antes** da cobrança", subheadline: "Contagem regressiva dos testes e link para cancelar com um toque."),
        Caption(headline: "Adicione assinaturas **em segundos**", subheadline: "Escolha um serviço popular e os dados se preenchem."),
        Caption(headline: "Veja **para onde vai seu dinheiro**", subheadline: "Gasto mensal, próximas cobranças e previsão de 12 meses."),
        Caption(headline: "Suas **garantias** sempre seguras", subheadline: "Data da compra, número de série e nota fiscal para qualquer acionamento."),
        Caption(headline: "Lembretes **antes** de cada renovação", subheadline: "30, 7, 3 ou 1 dia antes. Você escolhe."),
        Caption(headline: "Teste o **Renewly Pro** grátis", subheadline: "7 dias grátis. Cancele quando quiser."),
    ],
    "ja": [
        Caption(headline: "**無料体験の解約忘れ**をゼロに", subheadline: "サブスク・無料体験・保証書をまとめて管理。完全プライベート。"),
        Caption(headline: "課金される**前に**解約", subheadline: "無料体験の残り日数と、ワンタップで開ける解約リンク。"),
        Caption(headline: "サブスクを**数秒で**登録", subheadline: "人気サービスを選ぶだけで、詳細が自動入力。"),
        Caption(headline: "**お金の行き先**がひと目でわかる", subheadline: "月々の支出、次の請求、12か月の予測。"),
        Caption(headline: "**保証書**をなくさない", subheadline: "購入日・シリアル番号・レシートを保存して、修理や交換もスムーズ。"),
        Caption(headline: "更新の**前に**お知らせ", subheadline: "30日前・7日前・3日前・1日前から選べます。"),
        Caption(headline: "**Renewly Pro**を無料で試す", subheadline: "7日間無料。いつでも解約できます。"),
    ],
    "zh-Hans": [
        Caption(headline: "不再为**忘记取消的试用**付费", subheadline: "订阅、免费试用和保修，一处管理。100% 私密。"),
        Caption(headline: "扣费**之前**及时取消", subheadline: "试用倒计时，一键打开取消链接。"),
        Caption(headline: "**几秒钟**添加订阅", subheadline: "选择热门服务，详情自动填写。"),
        Caption(headline: "看清**钱花在哪里**", subheadline: "每月总额、即将扣费和 12 个月预测。"),
        Caption(headline: "每份**保修**都妥善保存", subheadline: "购买日期、序列号和收据，随时可用于保修。"),
        Caption(headline: "每次续订**之前**提醒你", subheadline: "提前 30、7、3 或 1 天，由你决定。"),
        Caption(headline: "免费试用 **Renewly Pro**", subheadline: "7 天免费，随时取消。"),
    ],
    "bn-BD": [
        Caption(headline: "ভুলে যাওয়া **ফ্রি ট্রায়ালের** টাকা আর নয়", subheadline: "সাবস্ক্রিপশন, ফ্রি ট্রায়াল ও ওয়ারেন্টি এক জায়গায়। ১০০% প্রাইভেট।"),
        Caption(headline: "চার্জ হওয়ার **আগেই** বাতিল করুন", subheadline: "ট্রায়ালের কাউন্টডাউন আর এক ট্যাপে বাতিলের লিংক।"),
        Caption(headline: "**কয়েক সেকেন্ডে** সাবস্ক্রিপশন যোগ করুন", subheadline: "জনপ্রিয় সার্ভিস বেছে নিন, তথ্য নিজে থেকেই পূরণ হবে।"),
        Caption(headline: "দেখুন **টাকা কোথায় যাচ্ছে**", subheadline: "মাসিক খরচ, আসন্ন চার্জ আর ১২ মাসের পূর্বাভাস।"),
        Caption(headline: "প্রতিটি **ওয়ারেন্টি** নিরাপদ", subheadline: "কেনার তারিখ, সিরিয়াল নম্বর আর রসিদ, যেকোনো ক্লেইমের জন্য প্রস্তুত।"),
        Caption(headline: "প্রতিটি নবায়নের **আগে** রিমাইন্ডার", subheadline: "৩০, ৭, ৩ বা ১ দিন আগে। আপনিই ঠিক করুন।"),
        Caption(headline: "**Renewly Pro** ফ্রিতে ব্যবহার করুন", subheadline: "৭ দিন ফ্রি। যেকোনো সময় বাতিল করুন।"),
    ],
]

/// Store locales that reuse another locale's screenshots.
let screenshotAliases: [String: String] = [
    "en-AU": "en-US",
    "en-CA": "en-US",
    "fr-CA": "fr-FR",
]
