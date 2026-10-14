@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureDraftTests {
    @Test func startsInRequested() throws {
        let item = Consent.newDisclosureDraft("code-660", label: "label-389")
        #expect(item.status == Consent.DisclosureDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newDisclosureDraft("code-660", label: "label-389")
        try item.moveTo(Consent.DisclosureDraftStatus.granted)
        #expect(item.status == Consent.DisclosureDraftStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newDisclosureDraft("code-660", label: "label-389")
        item.status = Consent.DisclosureDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureDraftStatus.requested) }
    }
}
