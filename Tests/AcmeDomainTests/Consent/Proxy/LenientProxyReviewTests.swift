@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyReviewTests {
    @Test func startsInIdle() throws {
        let item = Consent.newLenientProxyReview("code-861", label: "label-575")
        #expect(item.status == Consent.LenientProxyReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Consent.newLenientProxyReview("code-861", label: "label-575")
        try item.moveTo(Consent.LenientProxyReviewStatus.draining)
        #expect(item.status == Consent.LenientProxyReviewStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newLenientProxyReview("code-861", label: "label-575")
        item.status = Consent.LenientProxyReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientProxyReviewStatus.idle) }
    }
}
