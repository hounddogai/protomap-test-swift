@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageAdjustmentTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLanguageAdjustment("code-229", name: "name-558")
        #expect(item.status == Consent.LanguageAdjustmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newLanguageAdjustment("code-229", name: "name-558")
        try item.moveTo(Consent.LanguageAdjustmentStatus.approved)
        #expect(item.status == Consent.LanguageAdjustmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLanguageAdjustment("code-229", name: "name-558")
        item.status = Consent.LanguageAdjustmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageAdjustmentStatus.proposed) }
    }
}
