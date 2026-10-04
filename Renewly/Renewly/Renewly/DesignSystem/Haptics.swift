//
// Haptics.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import SwiftUI

extension View {
    func rigidHaptic<Trigger: Equatable>(trigger: Trigger) -> some View {
        sensoryFeedback(.impact(flexibility: .rigid), trigger: trigger)
    }
}
