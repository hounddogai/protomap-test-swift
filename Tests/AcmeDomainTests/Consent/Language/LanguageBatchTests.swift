@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageBatchTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLanguageBatch("code-786", title: "title-434")
        #expect(item.status == Consent.LanguageBatchStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newLanguageBatch("code-786", title: "title-434")
        try item.moveTo(Consent.LanguageBatchStatus.approved)
        #expect(item.status == Consent.LanguageBatchStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLanguageBatch("code-786", title: "title-434")
        item.status = Consent.LanguageBatchStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageBatchStatus.proposed) }
    }
}
