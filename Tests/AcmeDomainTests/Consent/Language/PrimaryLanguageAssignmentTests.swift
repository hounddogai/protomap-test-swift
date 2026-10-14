@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryLanguageAssignmentTests {
    @Test func startsInDraft() throws {
        let item = Consent.newPrimaryLanguageAssignment("code-882", name: "name-695")
        #expect(item.status == Consent.PrimaryLanguageAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newPrimaryLanguageAssignment("code-882", name: "name-695")
        try item.moveTo(Consent.PrimaryLanguageAssignmentStatus.pending)
        #expect(item.status == Consent.PrimaryLanguageAssignmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newPrimaryLanguageAssignment("code-882", name: "name-695")
        item.status = Consent.PrimaryLanguageAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryLanguageAssignmentStatus.draft) }
    }
}
