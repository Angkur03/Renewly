//
// SplashView.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

/// Picks up exactly where the static launch screen leaves off (same colour, same centred logo),
/// then reveals the wordmark and hands over to the app.
struct SplashView: View {
    static let logoSize: CGFloat = 180

    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRevealed = false

    var body: some View {
        ZStack {
            Color(.launchBackground)

            LinearGradient(
                colors: [Color(red: 0.17, green: 0.11, blue: 0.56), Color(.launchBackground), Color(red: 0.69, green: 0.29, blue: 0.90)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(isRevealed ? 1 : 0)

            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: -110, y: -260)
                .opacity(isRevealed ? 1 : 0)

            Image(.launchLogo)
                .resizable()
                .frame(width: Self.logoSize, height: Self.logoSize)
                .scaleEffect(isRevealed && !reduceMotion ? 0.82 : 1)
                .offset(y: isRevealed ? -44 : 0)

            VStack(spacing: 6) {
                Text("Renewly")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("Never miss a renewal again")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .opacity(0.8)
            }
            .foregroundStyle(.white)
            .offset(y: isRevealed ? 100 : 130)
            .opacity(isRevealed ? 1 : 0)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Renewly")
        .task {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .spring(duration: 0.75, bounce: 0.3)) {
                isRevealed = true
            }
            do {
                try await Task.sleep(for: .milliseconds(reduceMotion ? 800 : 1400))
            } catch {
                return
            }
            onFinished()
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}

#Preview("Dark") {
    SplashView(onFinished: {})
        .preferredColorScheme(.dark)
}
