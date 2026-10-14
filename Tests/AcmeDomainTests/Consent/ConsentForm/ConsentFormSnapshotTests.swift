@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormSnapshotTests {
    @Test func startsInCreated() throws {
        let item = Consent.newConsentFormSnapshot("code-150", label: "label-455")
        #expect(item.status == Consent.ConsentFormSnapshotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Consent.newConsentFormSnapshot("code-150", label: "label-455")
        try item.moveTo(Consent.ConsentFormSnapshotStatus.retired)
        #expect(item.status == Consent.ConsentFormSnapshotStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newConsentFormSnapshot("code-150", label: "label-455")
        item.status = Consent.ConsentFormSnapshotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormSnapshotStatus.created) }
    }
}
