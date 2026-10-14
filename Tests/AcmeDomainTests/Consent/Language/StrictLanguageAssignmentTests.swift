@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictLanguageAssignmentTests {
    @Test func startsInDraft() throws {
        let item = Consent.newStrictLanguageAssignment("code-192", title: "title-281")
        #expect(item.status == Consent.StrictLanguageAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newStrictLanguageAssignment("code-192", title: "title-281")
        try item.moveTo(Consent.StrictLanguageAssignmentStatus.active)
        #expect(item.status == Consent.StrictLanguageAssignmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newStrictLanguageAssignment("code-192", title: "title-281")
        item.status = Consent.StrictLanguageAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictLanguageAssignmentStatus.draft) }
    }
}
