@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageCycleTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newLanguageCycle("code-873", label: "label-1")
        #expect(item.status == Consent.LanguageCycleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newLanguageCycle("code-873", label: "label-1")
        try item.moveTo(Consent.LanguageCycleStatus.completed)
        #expect(item.status == Consent.LanguageCycleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newLanguageCycle("code-873", label: "label-1")
        item.status = Consent.LanguageCycleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageCycleStatus.planned) }
    }
}
