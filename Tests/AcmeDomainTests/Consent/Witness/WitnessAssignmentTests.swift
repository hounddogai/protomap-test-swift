@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessAssignmentTests {
    @Test func startsInCreated() throws {
        let item = Consent.newWitnessAssignment("code-870", title: "title-484")
        #expect(item.status == Consent.WitnessAssignmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newWitnessAssignment("code-870", title: "title-484")
        try item.moveTo(Consent.WitnessAssignmentStatus.validated)
        #expect(item.status == Consent.WitnessAssignmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newWitnessAssignment("code-870", title: "title-484")
        item.status = Consent.WitnessAssignmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessAssignmentStatus.created) }
    }
}
