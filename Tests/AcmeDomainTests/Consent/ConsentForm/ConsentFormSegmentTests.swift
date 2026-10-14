@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormSegmentTests {
    @Test func startsInDraft() throws {
        let item = Consent.newConsentFormSegment("code-992", label: "label-866")
        #expect(item.status == Consent.ConsentFormSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newConsentFormSegment("code-992", label: "label-866")
        try item.moveTo(Consent.ConsentFormSegmentStatus.active)
        #expect(item.status == Consent.ConsentFormSegmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newConsentFormSegment("code-992", label: "label-866")
        item.status = Consent.ConsentFormSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormSegmentStatus.draft) }
    }
}
