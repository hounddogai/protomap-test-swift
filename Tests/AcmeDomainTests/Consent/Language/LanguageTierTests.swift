@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageTierTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLanguageTier("code-475", title: "title-949")
        #expect(item.status == Consent.LanguageTierStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newLanguageTier("code-475", title: "title-949")
        try item.moveTo(Consent.LanguageTierStatus.approved)
        #expect(item.status == Consent.LanguageTierStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLanguageTier("code-475", title: "title-949")
        item.status = Consent.LanguageTierStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageTierStatus.proposed) }
    }
}
