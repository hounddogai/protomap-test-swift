@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageAuditTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newLanguageAudit("code-733", name: "name-567")
        #expect(item.status == Consent.LanguageAuditStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newLanguageAudit("code-733", name: "name-567")
        try item.moveTo(Consent.LanguageAuditStatus.completed)
        #expect(item.status == Consent.LanguageAuditStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newLanguageAudit("code-733", name: "name-567")
        item.status = Consent.LanguageAuditStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageAuditStatus.planned) }
    }
}
