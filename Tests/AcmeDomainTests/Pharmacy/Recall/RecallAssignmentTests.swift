@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallAssignmentTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newRecallAssignment("code-533", label: "label-121")
        #expect(item.status == Pharmacy.RecallAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newRecallAssignment("code-533", label: "label-121")
        try item.moveTo(Pharmacy.RecallAssignmentStatus.approved)
        #expect(item.status == Pharmacy.RecallAssignmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newRecallAssignment("code-533", label: "label-121")
        item.status = Pharmacy.RecallAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallAssignmentStatus.proposed) }
    }
}
