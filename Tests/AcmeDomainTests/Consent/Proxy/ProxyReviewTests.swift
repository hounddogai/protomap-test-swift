@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyReviewTests {
    @Test func startsInCreated() throws {
        let item = Consent.newProxyReview("code-595", name: "name-867")
        #expect(item.status == Consent.ProxyReviewStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newProxyReview("code-595", name: "name-867")
        try item.moveTo(Consent.ProxyReviewStatus.validated)
        #expect(item.status == Consent.ProxyReviewStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newProxyReview("code-595", name: "name-867")
        item.status = Consent.ProxyReviewStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyReviewStatus.created) }
    }
}
