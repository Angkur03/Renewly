//
// WebLink.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

/// Turns what people type or paste into a web link that is safe to open.
nonisolated enum WebLink {
    static let maxLength = 2048

    /// Accepts full links and bare addresses like "netflix.com/cancel", which get https://.
    /// Anything that is not a plain http(s) page with a real domain returns nil.
    static func url(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= maxLength, !trimmed.contains(where: \.isWhitespace) else {
            return nil
        }
        let candidate = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let components = URLComponents(string: candidate),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              components.user == nil, components.password == nil,
              let host = components.host, isDomain(host),
              let url = components.url else {
            return nil
        }
        return url
    }

    /// Short form for display: "netflix.com/cancelplan" instead of "https://www.netflix.com/cancelplan".
    static func displayText(for url: URL) -> String {
        guard var host = url.host(percentEncoded: false) else { return url.absoluteString }
        if host.lowercased().hasPrefix("www.") {
            host.removeFirst(4)
        }
        let path = url.path(percentEncoded: false)
        return path.count > 1 ? host + path : host
    }

    private static func isDomain(_ host: String) -> Bool {
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        return labels.count >= 2 && labels.allSatisfy { !$0.isEmpty }
    }
}
