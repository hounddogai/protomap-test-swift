@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictWitnessAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newStrictWitnessAssignment("code-882", title: "title-636")
        #expect(item.status == Consent.StrictWitnessAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Consent.newStrictWitnessAssignment("code-882", title: "title-636")
        try item.moveTo(Consent.StrictWitnessAssignmentStatus.cancelled)
        #expect(item.status == Consent.StrictWitnessAssignmentStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newStrictWitnessAssignment("code-882", title: "title-636")
        item.status = Consent.StrictWitnessAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictWitnessAssignmentStatus.planned) }
    }
}
