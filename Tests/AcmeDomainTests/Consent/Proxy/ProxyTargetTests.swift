@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyTargetTests {
    @Test func startsInDraft() throws {
        let item = Consent.newProxyTarget("code-477", name: "name-474")
        #expect(item.status == Consent.ProxyTargetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newProxyTarget("code-477", name: "name-474")
        try item.moveTo(Consent.ProxyTargetStatus.active)
        #expect(item.status == Consent.ProxyTargetStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newProxyTarget("code-477", name: "name-474")
        item.status = Consent.ProxyTargetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyTargetStatus.draft) }
    }
}
