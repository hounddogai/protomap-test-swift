@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryConsentFormSnapshotTests {
    @Test func startsInDraft() throws {
        let item = Consent.newPrimaryConsentFormSnapshot("code-23", label: "label-487")
        #expect(item.status == Consent.PrimaryConsentFormSnapshotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newPrimaryConsentFormSnapshot("code-23", label: "label-487")
        try item.moveTo(Consent.PrimaryConsentFormSnapshotStatus.active)
        #expect(item.status == Consent.PrimaryConsentFormSnapshotStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newPrimaryConsentFormSnapshot("code-23", label: "label-487")
        item.status = Consent.PrimaryConsentFormSnapshotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryConsentFormSnapshotStatus.draft) }
    }
}
