//
// ServiceCatalog.swift
// Renewly
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation

nonisolated enum ServiceGroup: String, CaseIterable, Identifiable, Sendable {
    case streaming
    case music
    case cloud
    case productivity
    case ai
    case gaming
    case news
    case fitness
    case lifestyle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .streaming: "Video streaming"
        case .music: "Music & audio"
        case .cloud: "Cloud storage"
        case .productivity: "Productivity & software"
        case .ai: "AI assistants"
        case .gaming: "Gaming"
        case .news: "News & reading"
        case .fitness: "Health & fitness"
        case .lifestyle: "Shopping & lifestyle"
        }
    }

    var systemImage: String {
        switch self {
        case .streaming: "play.tv.fill"
        case .music: "music.note"
        case .cloud: "icloud.fill"
        case .productivity: "briefcase.fill"
        case .ai: "sparkles"
        case .gaming: "gamecontroller.fill"
        case .news: "newspaper.fill"
        case .fitness: "figure.run"
        case .lifestyle: "bag.fill"
        }
    }
}

/// A well-known subscription. Prices are deliberately left out: they differ by country and change often.
nonisolated struct ServiceTemplate: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let group: ServiceGroup
    /// The plan most people pick.
    let billingCycle: BillingCycle
    /// Official page for managing or cancelling; `nil` when there is no single stable page.
    let manageURL: String?
    let aliases: [String]

    init(_ name: String, _ group: ServiceGroup, _ billingCycle: BillingCycle = .monthly, manage manageURL: String? = nil, aliases: [String] = []) {
        self.id = ServiceCatalog.normalized(name)
        self.name = name
        self.group = group
        self.billingCycle = billingCycle
        self.manageURL = manageURL
        self.aliases = aliases
    }
}

nonisolated struct ServiceCatalog: Sendable {
    static let appleSubscriptions = "https://apps.apple.com/account/subscriptions"
    static let microsoftServices = "https://account.microsoft.com/services"
    static let googleOne = "https://one.google.com/settings"
    static let youTubeMemberships = "https://www.youtube.com/paid_memberships"

    static let shared = ServiceCatalog(services: Self.builtIn)

    let services: [ServiceTemplate]

    /// Services grouped for browsing, alphabetical within each group.
    var groups: [(group: ServiceGroup, services: [ServiceTemplate])] {
        ServiceGroup.allCases.compactMap { group in
            let members = services
                .filter { $0.group == group }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return members.isEmpty ? nil : (group, members)
        }
    }

    /// Ranked matches: name prefix, alias prefix, word prefix, then anywhere in the name or aliases.
    func search(_ query: String) -> [ServiceTemplate] {
        let needle = Self.normalized(query)
        guard !needle.isEmpty else { return [] }
        let ranked: [(service: ServiceTemplate, rank: Int)] = services.compactMap { service in
            guard let rank = rank(of: service, for: needle) else { return nil }
            return (service, rank)
        }
        let sorted = ranked.sorted { lhs, rhs in
            if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
            return lhs.service.name.localizedStandardCompare(rhs.service.name) == .orderedAscending
        }
        return sorted.map(\.service)
    }

    /// Suggestions while typing a name; empty once the name already is a catalog service.
    func suggestions(for title: String, limit: Int = 3) -> [ServiceTemplate] {
        let needle = Self.normalized(title)
        guard needle.count >= 2, exactMatch(for: title) == nil else { return [] }
        return Array(search(title).prefix(limit))
    }

    func exactMatch(for title: String) -> ServiceTemplate? {
        let needle = Self.normalized(title)
        guard !needle.isEmpty else { return nil }
        return services.first { $0.id == needle || $0.aliases.contains { Self.normalized($0) == needle } }
    }

    private func rank(of service: ServiceTemplate, for needle: String) -> Int? {
        let name = Self.normalized(service.name)
        let aliases = service.aliases.map(Self.normalized)
        if name.hasPrefix(needle) { return 0 }
        if aliases.contains(where: { $0.hasPrefix(needle) }) { return 1 }
        let words = service.name.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        if words.contains(where: { $0.hasPrefix(needle) }) { return 2 }
        if name.contains(needle) || aliases.contains(where: { $0.contains(needle) }) { return 3 }
        return nil
    }

    /// Lowercased letters and digits only, so "Disney+", "disney plus" and "DISNEY" compare sensibly.
    static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
            .replacingOccurrences(of: "+", with: "plus")
            .filter { $0.isLetter || $0.isNumber }
    }

    static let builtIn: [ServiceTemplate] = [
        // Video streaming
        .init("Netflix", .streaming, manage: "https://www.netflix.com/cancelplan"),
        .init("Disney+", .streaming, manage: "https://www.disneyplus.com/account", aliases: ["Disney Plus", "Hotstar"]),
        .init("Hulu", .streaming, manage: "https://secure.hulu.com/account"),
        .init("HBO Max", .streaming, aliases: ["Max", "HBO"]),
        .init("Prime Video", .streaming, manage: "https://www.amazon.com/mc", aliases: ["Amazon Prime Video"]),
        .init("Apple TV+", .streaming, manage: appleSubscriptions, aliases: ["Apple TV Plus"]),
        .init("YouTube Premium", .streaming, manage: youTubeMemberships, aliases: ["YouTube"]),
        .init("Paramount+", .streaming, manage: "https://www.paramountplus.com/account/", aliases: ["Paramount Plus"]),
        .init("Peacock", .streaming, manage: "https://www.peacocktv.com/account"),
        .init("Crunchyroll", .streaming, manage: "https://www.crunchyroll.com/account/membership"),
        .init("JioHotstar", .streaming, aliases: ["Jio Cinema"]),
        .init("Chorki", .streaming),
        .init("Hoichoi", .streaming, .yearly),
        .init("Bongo", .streaming, aliases: ["BongoBD"]),
        .init("Toffee", .streaming),

        // Music & audio
        .init("Spotify Premium", .music, manage: "https://www.spotify.com/account", aliases: ["Spotify"]),
        .init("Apple Music", .music, manage: appleSubscriptions),
        .init("YouTube Music", .music, manage: youTubeMemberships),
        .init("Amazon Music Unlimited", .music, aliases: ["Amazon Music"]),
        .init("Tidal", .music, manage: "https://account.tidal.com"),
        .init("Deezer", .music, manage: "https://www.deezer.com/account"),
        .init("Audible", .music, manage: "https://www.audible.com/account"),
        .init("SoundCloud Go", .music, aliases: ["SoundCloud"]),

        // Cloud storage
        .init("iCloud+", .cloud, manage: appleSubscriptions, aliases: ["iCloud", "iCloud Plus"]),
        .init("Google One", .cloud, manage: googleOne, aliases: ["Google Drive"]),
        .init("Dropbox", .cloud, .yearly, manage: "https://www.dropbox.com/account/plan"),
        .init("OneDrive", .cloud, manage: microsoftServices),
        .init("Apple One", .cloud, manage: appleSubscriptions),

        // Productivity & software
        .init("Microsoft 365", .productivity, .yearly, manage: microsoftServices, aliases: ["Office 365"]),
        .init("Adobe Creative Cloud", .productivity, manage: "https://account.adobe.com/plans", aliases: ["Adobe", "Photoshop", "Lightroom"]),
        .init("Canva Pro", .productivity, .yearly, aliases: ["Canva"]),
        .init("Notion", .productivity),
        .init("1Password", .productivity, .yearly),
        .init("GitHub Copilot", .productivity, manage: "https://github.com/settings/billing", aliases: ["GitHub"]),
        .init("Grammarly", .productivity, .yearly),
        .init("LinkedIn Premium", .productivity, aliases: ["LinkedIn"]),
        .init("Zoom", .productivity),
        .init("NordVPN", .productivity, .yearly, aliases: ["Nord VPN", "VPN"]),

        // AI assistants
        .init("ChatGPT Plus", .ai, aliases: ["ChatGPT", "OpenAI"]),
        .init("Claude Pro", .ai, aliases: ["Claude", "Anthropic"]),
        .init("Google AI Pro", .ai, manage: googleOne, aliases: ["Gemini", "Gemini Advanced"]),
        .init("Perplexity Pro", .ai, aliases: ["Perplexity"]),
        .init("Cursor Pro", .ai, aliases: ["Cursor"]),

        // Gaming
        .init("Xbox Game Pass", .gaming, manage: microsoftServices, aliases: ["Game Pass", "Xbox"]),
        .init("PlayStation Plus", .gaming, aliases: ["PS Plus", "PlayStation"]),
        .init("Nintendo Switch Online", .gaming, .yearly, aliases: ["Nintendo"]),
        .init("Apple Arcade", .gaming, manage: appleSubscriptions),
        .init("EA Play", .gaming),

        // News & reading
        .init("The New York Times", .news, manage: "https://myaccount.nytimes.com", aliases: ["NYTimes", "NYT"]),
        .init("The Washington Post", .news, aliases: ["Washington Post"]),
        .init("Medium", .news),
        .init("Kindle Unlimited", .news, aliases: ["Kindle"]),
        .init("Apple News+", .news, manage: appleSubscriptions, aliases: ["Apple News"]),
        .init("Patreon", .news, manage: "https://www.patreon.com/settings/memberships"),

        // Health & fitness
        .init("Apple Fitness+", .fitness, manage: appleSubscriptions, aliases: ["Fitness Plus"]),
        .init("Strava", .fitness, .yearly, manage: "https://www.strava.com/account"),
        .init("Headspace", .fitness, .yearly),
        .init("Calm", .fitness, .yearly),
        .init("Peloton", .fitness),
        .init("Duolingo Super", .fitness, .yearly, aliases: ["Duolingo"]),

        // Shopping & lifestyle
        .init("Amazon Prime", .lifestyle, manage: "https://www.amazon.com/mc", aliases: ["Prime"]),
        .init("Costco Membership", .lifestyle, .yearly, aliases: ["Costco"]),
        .init("Uber One", .lifestyle, aliases: ["Uber"]),
        .init("DashPass", .lifestyle, aliases: ["DoorDash"]),
        .init("foodpanda pro", .lifestyle, aliases: ["foodpanda", "pandapro"])
    ]
}
