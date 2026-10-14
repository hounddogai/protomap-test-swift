@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newDisclosureAssignment("code-120", label: "label-278")
        #expect(item.status == Consent.DisclosureAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newDisclosureAssignment("code-120", label: "label-278")
        try item.moveTo(Consent.DisclosureAssignmentStatus.inProgress)
        #expect(item.status == Consent.DisclosureAssignmentStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newDisclosureAssignment("code-120", label: "label-278")
        item.status = Consent.DisclosureAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureAssignmentStatus.planned) }
    }
}
