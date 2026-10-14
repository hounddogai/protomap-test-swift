@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationRuleTests {
    @Test func startsInDraft() throws {
        let item = Consent.newRevocationRule("code-193", name: "name-170")
        #expect(item.status == Consent.RevocationRuleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newRevocationRule("code-193", name: "name-170")
        try item.moveTo(Consent.RevocationRuleStatus.pending)
        #expect(item.status == Consent.RevocationRuleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newRevocationRule("code-193", name: "name-170")
        item.status = Consent.RevocationRuleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationRuleStatus.draft) }
    }
}
