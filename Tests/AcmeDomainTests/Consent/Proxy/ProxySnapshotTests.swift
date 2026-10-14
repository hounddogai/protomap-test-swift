@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxySnapshotTests {
    @Test func startsInDraft() throws {
        let item = Consent.newProxySnapshot("code-556", name: "name-876")
        #expect(item.status == Consent.ProxySnapshotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newProxySnapshot("code-556", name: "name-876")
        try item.moveTo(Consent.ProxySnapshotStatus.pending)
        #expect(item.status == Consent.ProxySnapshotStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newProxySnapshot("code-556", name: "name-876")
        item.status = Consent.ProxySnapshotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxySnapshotStatus.draft) }
    }
}
