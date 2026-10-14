@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguagePlanTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newLanguagePlan("code-357", name: "name-71")
        #expect(item.status == Consent.LanguagePlanStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newLanguagePlan("code-357", name: "name-71")
        try item.moveTo(Consent.LanguagePlanStatus.completed)
        #expect(item.status == Consent.LanguagePlanStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newLanguagePlan("code-357", name: "name-71")
        item.status = Consent.LanguagePlanStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguagePlanStatus.planned) }
    }
}
