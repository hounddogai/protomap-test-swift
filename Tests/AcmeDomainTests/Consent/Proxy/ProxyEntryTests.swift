@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyEntryTests {
    @Test func startsInDraft() throws {
        let item = Consent.newProxyEntry("code-154", label: "label-417")
        #expect(item.status == Consent.ProxyEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newProxyEntry("code-154", label: "label-417")
        try item.moveTo(Consent.ProxyEntryStatus.pending)
        #expect(item.status == Consent.ProxyEntryStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newProxyEntry("code-154", label: "label-417")
        item.status = Consent.ProxyEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyEntryStatus.draft) }
    }
}
