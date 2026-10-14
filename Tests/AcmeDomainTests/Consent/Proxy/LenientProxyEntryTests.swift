@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyEntryTests {
    @Test func startsInDraft() throws {
        let item = Consent.newLenientProxyEntry("code-938", label: "label-789")
        #expect(item.status == Consent.LenientProxyEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newLenientProxyEntry("code-938", label: "label-789")
        try item.moveTo(Consent.LenientProxyEntryStatus.pending)
        #expect(item.status == Consent.LenientProxyEntryStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newLenientProxyEntry("code-938", label: "label-789")
        item.status = Consent.LenientProxyEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientProxyEntryStatus.draft) }
    }
}
