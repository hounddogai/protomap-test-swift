@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyDraftTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLenientProxyDraft("code-760", name: "name-678")
        #expect(item.status == Consent.LenientProxyDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newLenientProxyDraft("code-760", name: "name-678")
        try item.moveTo(Consent.LenientProxyDraftStatus.approved)
        #expect(item.status == Consent.LenientProxyDraftStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLenientProxyDraft("code-760", name: "name-678")
        item.status = Consent.LenientProxyDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientProxyDraftStatus.proposed) }
    }
}
