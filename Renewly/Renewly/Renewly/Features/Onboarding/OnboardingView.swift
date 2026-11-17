//
// OnboardingView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-11-17.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

/// First-launch walkthrough that shows what Renewly is for before the dashboard.
struct OnboardingView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pageIndex = 0
    @State private var isVisible = false
    @State private var finishTrigger = 0

    private let pages = OnboardingPage.all

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                topBar
                TabView(selection: $pageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageContent(page)
                            .tag(index)
                            .accessibilityElement(children: .combine)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .snappy, value: pageIndex)

                bottomBar
            }
        }
        .ignoresSafeArea()
        .rigidHaptic(trigger: pageIndex)
        .rigidHaptic(trigger: finishTrigger)
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.25) : .spring(duration: 0.7, bounce: 0.28)) {
                isVisible = true
            }
        }
        .accessibilityAction(.escape) {
            if pageIndex < pages.count - 1 {
                pageIndex = pages.count - 1
            } else {
                finish()
            }
        }
    }

    private var background: some View {
        ZStack {
            Color(.launchBackground)

            LinearGradient(
                colors: [
                    Color(red: 0.17, green: 0.11, blue: 0.56),
                    Color(.launchBackground),
                    Color(red: 0.69, green: 0.29, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: -120, y: -280)

            Circle()
                .fill(Color(hex: 0x5EF2C4, opacity: 0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: 140, y: 260)
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            Image(.launchLogo)
                .resizable()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)

            Text("Renewly")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            if pageIndex < pages.count - 1 {
                Button("Skip") {
                    finish()
                }
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .accessibilityHint("Skip onboarding and open the app")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 64)
        .padding(.bottom, 8)
        .opacity(isVisible ? 1 : 0)
    }

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 168, height: 168)

                Image(systemName: page.systemImage)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(page.tint.gradient)
                    .symbolRenderingMode(.hierarchical)
                    .shadow(color: page.tint.opacity(0.45), radius: 18, y: 8)
                    .scaleEffect(isVisible ? 1 : 0.7)
            }
            .accessibilityHidden(true)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)

                Text(page.detail)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)

            VStack(spacing: 10) {
                ForEach(page.useCases, id: \.self) { useCase in
                    useCaseRow(useCase)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)

            Spacer(minLength: 12)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 24)
    }

    private func useCaseRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color(hex: 0x5EF2C4))
            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var bottomBar: some View {
        VStack(spacing: 18) {
            pageIndicator

            Button {
                if pageIndex < pages.count - 1 {
                    withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy) {
                        pageIndex += 1
                    }
                } else {
                    finish()
                }
            } label: {
                Text(pageIndex < pages.count - 1 ? "Continue" : "Get Started")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(Color(red: 0.22, green: 0.14, blue: 0.55))
            .controlSize(.large)
            .padding(.horizontal, 24)
            .accessibilityHint(pageIndex < pages.count - 1 ? "Go to the next onboarding screen" : "Finish onboarding and open the app")
        }
        .padding(.bottom, 44)
        .opacity(isVisible ? 1 : 0)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(index == pageIndex ? 1 : 0.35))
                    .frame(width: index == pageIndex ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .snappy, value: pageIndex)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(pageIndex + 1) of \(pages.count)")
    }

    private func finish() {
        finishTrigger += 1
        onFinished()
    }
}

/// One screen in the first-launch walkthrough.
struct OnboardingPage {
    let systemImage: String
    let tint: Color
    let title: String
    let detail: String
    let useCases: [String]

    static let all: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "gift.fill",
            tint: Color(hex: 0xFB923C),
            title: String(localized: "Never pay for a forgotten trial"),
            detail: String(localized: "See every free trial in one place and cancel before it turns into a charge."),
            useCases: [
                String(localized: "Spot a trial that ends in a few days"),
                String(localized: "Open the cancel link before you are billed"),
            ]
        ),
        OnboardingPage(
            systemImage: "checklist",
            tint: Color(hex: 0x60A5FA),
            title: String(localized: "Subscriptions and warranties, together"),
            detail: String(localized: "Track streaming, cloud, phone plans and product warranties in one private list."),
            useCases: [
                String(localized: "Add a popular service in a few taps"),
                String(localized: "Keep warranty dates next to your subscriptions"),
            ]
        ),
        OnboardingPage(
            systemImage: "bell.badge.fill",
            tint: Color(hex: 0xA855F7),
            title: String(localized: "Reminders that arrive in time"),
            detail: String(localized: "Get an alert days before a renewal, trial end or warranty expires—so you can act."),
            useCases: [
                String(localized: "Alerts at 9:00 AM before the date"),
                String(localized: "Turn reminders on per item"),
            ]
        ),
        OnboardingPage(
            systemImage: "lock.shield.fill",
            tint: Color(hex: 0x5EF2C4),
            title: String(localized: "Private by design"),
            detail: String(localized: "No account and no servers. Your items and receipt photos stay on this iPhone."),
            useCases: [
                String(localized: "Works offline, with no sign-in"),
                String(localized: "Receipt text is read on the device"),
            ]
        ),
    ]
}

/// Skips onboarding for screenshot, promo-video and other debug launch paths.
enum OnboardingGate {
    static var shouldShow: Bool {
        #if DEBUG
        if DemoTour.isEnabled { return false }
        if UserDefaults.standard.string(forKey: "seed_demo") != nil { return false }
        if UserDefaults.standard.string(forKey: "open_route") != nil { return false }
        if UserDefaults.standard.bool(forKey: "skip_onboarding") { return false }
        #endif
        return !UserDefaults.standard.bool(forKey: AppStorageKey.hasCompletedOnboarding)
    }
}

#Preview("Onboarding") {
    OnboardingView(onFinished: {})
}

#Preview("Onboarding Dark") {
    OnboardingView(onFinished: {})
        .preferredColorScheme(.dark)
}
