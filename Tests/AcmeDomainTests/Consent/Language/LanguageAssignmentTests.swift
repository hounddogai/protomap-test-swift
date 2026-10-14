@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageAssignmentTests {
    @Test func startsInNew() throws {
        let item = Consent.newLanguageAssignment("code-554", name: "name-352")
        #expect(item.status == Consent.LanguageAssignmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newLanguageAssignment("code-554", name: "name-352")
        try item.moveTo(Consent.LanguageAssignmentStatus.queued)
        #expect(item.status == Consent.LanguageAssignmentStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newLanguageAssignment("code-554", name: "name-352")
        item.status = Consent.LanguageAssignmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageAssignmentStatus.new) }
    }
}
