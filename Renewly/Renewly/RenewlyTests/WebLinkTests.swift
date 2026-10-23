//
// WebLinkTests.swift
// RenewlyTests
//
// Created by Md Mehedi Hasan Angkur on 2026-10-04.
// Copyright © 2026. All rights reserved.
//

import Foundation
import Testing
@testable import Renewly

@Suite("Web links")
struct WebLinkTests {
    @Test("Typed links become openable https links", arguments: [
        ("https://netflix.com/cancel", "https://netflix.com/cancel"),
        ("http://example.com", "http://example.com"),
        ("HTTPS://Example.com/Account", "HTTPS://Example.com/Account"),
        ("netflix.com/cancelplan", "https://netflix.com/cancelplan"),
        ("www.spotify.com/account", "https://www.spotify.com/account"),
        ("  disneyplus.com  ", "https://disneyplus.com"),
        ("example.com/manage?plan=1", "https://example.com/manage?plan=1"),
    ])
    func accepted(input: String, expected: String) {
        #expect(WebLink.url(from: input)?.absoluteString == expected)
    }

    @Test("Unsafe or incomplete text is rejected", arguments: [
        "",
        "   ",
        "netflix",
        "javascript:alert(1)",
        "mailto:help@example.com",
        "ftp://example.com/file",
        "file:///etc/hosts",
        "https://",
        "https://user:pass@example.com",
        "netflix .com",
        "example..com",
        ".com",
    ])
    func rejected(input: String) {
        #expect(WebLink.url(from: input) == nil)
    }

    @Test("Links longer than the limit are rejected")
    func tooLong() {
        let long = "example.com/" + String(repeating: "a", count: WebLink.maxLength)
        #expect(WebLink.url(from: long) == nil)
    }

    @Test("Display text drops the scheme and www", arguments: [
        ("https://www.netflix.com/cancelplan", "netflix.com/cancelplan"),
        ("https://help.example.com/", "help.example.com"),
        ("http://example.com", "example.com"),
        ("https://example.com/account/manage", "example.com/account/manage"),
    ])
    func displayText(link: String, expected: String) throws {
        let url = try #require(URL(string: link))
        #expect(WebLink.displayText(for: url) == expected)
    }

    @Test("Stored links without a scheme still open")
    func itemAcceptsBareStoredLink() {
        let item = TrackedItem(
            title: "Netflix", category: .subscription, cost: 15.99, currencyCode: "USD",
            startDate: .now, expirationDate: .now, cancellationURL: "netflix.com/cancel"
        )
        #expect(item.validCancellationURL?.absoluteString == "https://netflix.com/cancel")
    }
}
