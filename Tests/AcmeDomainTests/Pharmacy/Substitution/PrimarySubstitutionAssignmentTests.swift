@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionAssignmentTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newPrimarySubstitutionAssignment("code-348", label: "label-651")
        #expect(item.status == Pharmacy.PrimarySubstitutionAssignmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newPrimarySubstitutionAssignment("code-348", label: "label-651")
        try item.moveTo(Pharmacy.PrimarySubstitutionAssignmentStatus.draining)
        #expect(item.status == Pharmacy.PrimarySubstitutionAssignmentStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newPrimarySubstitutionAssignment("code-348", label: "label-651")
        item.status = Pharmacy.PrimarySubstitutionAssignmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimarySubstitutionAssignmentStatus.idle) }
    }
}
