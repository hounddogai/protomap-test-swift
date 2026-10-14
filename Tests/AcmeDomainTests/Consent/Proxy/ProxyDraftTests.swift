@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyDraftTests {
    @Test func startsInCreated() throws {
        let item = Consent.newProxyDraft("code-696", name: "name-577")
        #expect(item.status == Consent.ProxyDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newProxyDraft("code-696", name: "name-577")
        try item.moveTo(Consent.ProxyDraftStatus.validated)
        #expect(item.status == Consent.ProxyDraftStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newProxyDraft("code-696", name: "name-577")
        item.status = Consent.ProxyDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyDraftStatus.created) }
    }
}
